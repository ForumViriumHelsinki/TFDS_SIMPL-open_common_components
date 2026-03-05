# Ticket: OpenBao (Vault) Authentication Failure
**Status:** RESOLVED
**Component:** Security Layer (OpenBao / Vault)
**Severity:** MAJOR

## Description
Security-layer authentication failures prevented several dependent services (Kafka, Redpanda, Notifications, ICMS) from retrieving credentials and secrets from the OpenBao instance. Services remained stuck in `Init:0/1` or `CrashLoopBackOff` states due to `403 Forbidden` errors during Vault Agent sidecar initialization.

### Cause
The failure was rooted in three specific misconfigurations within the Kubernetes auth engine of OpenBao:
1.  **Incorrect API Host:** The auth method was configured with a hardcoded host IP (`10.3.0.1`) which did not match the cluster's internal API service (`10.43.0.1`).
2.  **Unsupported Role Patterns:** The `example-role` utilized literal wildcard strings (e.g., `*-sa`, `*-service-account`) in `bound_service_account_names`. The OpenBao Kubernetes auth engine does not support these glob patterns; it requires either specific names or a single `*` to allow all service accounts in the permitted namespaces.
3.  **Job Immutability:** Although a previous patch existed in the repository, it was not applied to the cluster because Kubernetes Jobs are immutable. ArgoCD saw the `openbao-config` Job as "Completed" and did not trigger a replacement, leaving the cluster in a stale, broken state from the initial deployment.

### Effect
- **Kafka, Notification, ICMS:** Stuck indefinitely in `Init:0/1` as the `vault-agent-init` container could not authenticate.
- **Redpanda:** Entered `CrashLoopBackOff` because it could not connect to the stalled Kafka brokers.
- **System Stability:** Critical middleware components were unable to start, breaking the entire common component stack.

### Solution & Remediation
The fix was implemented in two stages:
1.  **Immediate Recovery:** A manual fix-job was executed to reconfigure the `auth/kubernetes/config` with the correct host (`https://kubernetes.default.svc.cluster.local`) and update `example-role` to use the supported `*` pattern.
2.  **Permanent "Redundant" Patch:** The root application manifest was updated to solve the Job immutability problem. By adding a dynamic suffix to the Job name, we ensure that every Helm/ArgoCD sync creates a **new Job instance**, forcing the configuration to be re-applied and synchronized with the repository state.

### Implementation Patch
**Location:** `charts/templates/application.yaml`
**Change:** Forced Job recreation and corrected auth parameters.

```yaml
# Source: charts/templates/application.yaml
- repoURL: "https://code.europa.eu/api/v4/projects/{{ .Values.openbao_config.projectID }}/packages/helm/stable"
  helm:
    values: |
      kubernetesHost: https://kubernetes.default.svc.cluster.local
      kubernetesRole:
        bound_service_account_names: ["*"]
        bound_service_account_namespaces: [{{ join "," (concat .Values.agentList.authorities .Values.agentList.providers .Values.agentList.consumers (list .Values.cluster.namespace) (list (printf "%s-vswh" .Values.cluster.namespace))) }}]
        policies: ["example-policy"]
      # Force job recreation on sync to overcome Kubernetes Job immutability
      job:
        name: openbao-config-{{ .Release.Revision | default "v1" }}
```
