# Ticket: OpenBao (Vault) Authentication Failure
**Status:** RESOLVED
**Component:** Security Layer (OpenBao / Vault)
**Severity:** MAJOR

## Description
Security-layer authentication failures prevented several dependent services from retrieving credentials and secrets from the OpenBao instance.

### Cause
Diagnostic logs from OpenBao and the Vault Agents revealed three misconfigurations in the Kubernetes auth engine:
1. **Incorrect API Host:** The Kubernetes auth method was configured with a hardcoded host IP (`10.3.0.1`) that did not match the cluster's internal API service (`10.43.0.1`).
2. **Missing Trust:** No CA certificate was provided in the OpenBao configuration, preventing it from verifying tokens against the Kubernetes API.
3. **Invalid Pattern Matching:** The `example-role` used literal wildcard strings (e.g., `*-sa`) in `bound_service_account_names`, which are not supported by the Kubernetes auth engine.

### Effect
- Dependent services (Kafka, Redpanda, Notifications) were stuck in an `Init:1/2` state indefinitely.
- Vault Agent init containers reported `403 Forbidden` and `permission denied` when attempting to login via the Kubernetes auth method.

### Solution
1. **Host & CA Refinement:** Reconfigured the Kubernetes auth method using the cluster's internal FQDN and the local service account CA.
2. **Role Simplification:** Updated `example-role` to allow `*` (all) service account names within the explicitly permitted namespaces.
3. **Persistence:** The root application manifest (`charts/templates/application.yaml`) was patched with the corrected configuration.

### Applied Patch
**Location:** `charts/templates/application.yaml`
**Change:** Overrode `kubernetesHost` and corrected `kubernetesRole` patterns.
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
```
