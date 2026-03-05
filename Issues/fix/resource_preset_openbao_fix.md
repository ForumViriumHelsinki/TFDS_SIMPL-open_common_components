# Ticket: Resource Preset does not affect OpenBao
**Status:** RESOLVED
**Component:** Resource Management / OpenBao
**Severity:** MINOR

## Description
The `resourcePreset` variable was not correctly propagated to the OpenBao application, leading to a bottleneck on single-node clusters where default configurations (specifically for the injector) prevented successful pod scheduling.

### Cause
The OpenBao Helm chart defaults to 2 replicas for the **Agent Injector** with strict pod anti-affinity. On single-node clusters, this causes the second injector pod to remain `Pending`. Additionally, the server resource requests needed to be zeroed out in the `low` preset.

### Effect
On a single-node cluster, the secondary injector pod would fail to schedule, causing the application to remain in a `Progressing` state.

### Solution
Updated `charts/templates/application-openbao.yaml` with revised logic for the `low` resource preset:
1.  **Injector Scaling**: Limited `injector.replicas` to 1.
2.  **Relaxed Affinity**: Disabled `affinity` for both the `injector` and the `server` to ensure scheduling on a single node.
3.  **Standalone Server**: Reverted the server to its default Standalone mode (removing the forced HA block) to ensure compatibility with the existing `file` storage backend and 1-replica limit.
4.  **Zero Requests**: Updated resource requests to 0 (cpu/memory).

### Implementation Patch
**Location:** `charts/templates/application-openbao.yaml`
**Change:**
```yaml
# Source: charts/templates/application-openbao.yaml
values: |
  fullnameOverride: openbao-{{ .Release.Namespace }}
  {{- if eq .Values.resourcePreset "low" }}
  injector:
    replicas: 1
    affinity: {}
  server:
    affinity: {}
  {{- end }}
  ...
  {{- if eq .Values.resourcePreset "low" }}
  resources:
    requests:
      cpu: "0"
      memory: "0"
  {{- end }}
```
