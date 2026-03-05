# Ticket: OpenBao (Vault) Authentication Failure
**Status:** RESOLVED
**Component:** Security Layer (OpenBao / Vault)
**Severity:** MAJOR

## Description
Security-layer authentication failures prevented several dependent services (Kafka, Redpanda, Notifications, ICMS) from retrieving credentials and secrets from OpenBao. Services remained stuck in `Init:0/1` or `CreateContainerConfigError` states.

### Root Cause
1.  **Buggy External Chart**: The external `openbao-config` chart (v1.2.3) ignored Helm value overrides, hardcoding the Kubernetes API host to `10.3.0.1` and using unsupported glob patterns (`*-sa`).
2.  **Missing Secret Automation**: The `kafka-users-secret` required by Redpanda was not being created in Kubernetes, even though the data existed in OpenBao.
3.  **Job Immutability**: ArgoCD was unable to update the configuration Job because Kubernetes Job specifications are immutable, leading to "SyncFailed" states.

### Solution & Remediation
A comprehensive, automated fix was implemented:
1.  **Local Configuration Chart**: Created `charts/local/openbao-config` to replace the faulty external chart. This allows for proper Helm templating of the OpenBao configuration script.
2.  **Automated Secret Creation**: Added an init container (`4-pull-kafka-secrets`) to the configuration Job. This container automatically creates the `kafka-users-secret` in Kubernetes using the credentials stored in OpenBao, fulfilling the requirement for a fully automated deployment.
3.  **Role & Policy Correction**: Fixed the Kubernetes auth host to use the internal DNS (`https://kubernetes.default.svc.cluster.local`) and updated the role binding to the supported `*` pattern.
4.  **ArgoCD Robustness**: Updated `charts/templates/application.yaml` with `selfHeal: true`, `prune: true`, and `Replace=true` to ensure automatic recovery and handling of immutable Jobs.

### Implementation Patch (Final)
**Location:** `charts/templates/application.yaml`
```yaml
  - repoURL: {{ .Values.values.repo_URL }}
    targetRevision: {{ .Values.values.branch }}
    path: charts/local/openbao-config
    helm:
      values: |
        kubernetesHost: https://kubernetes.default.svc.cluster.local
        kubernetesRole:
          bound_service_account_names: ["*"]
          ...
        # Force job recreation on sync
        job:
          name: openbao-config-{{ .Release.Revision | default "v4" }}
```
