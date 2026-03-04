# Ticket: Storage Provisioning Deadlock
**Status:** RESOLVED
**Component:** Infrastructure / Storage (NFS Server)
**Severity:** CRITICAL

## Description
A circular dependency in the storage provisioning layer caused multiple services to remain in a `Pending` state indefinitely.

### Cause
The `csi-cinder-high-speed` StorageClass was configured to be provisioned by the NFS server. However, the NFS server's own data volume was also configured to use the `csi-cinder-high-speed` StorageClass. This created a deadlock where the provisioner could not start without its storage, and the storage could not be provisioned without the provisioner starting first.

### Effect
- Core services requiring persistent storage (Elasticsearch, Logstash) remained in `Pending` state.
- PersistentVolumeClaims (PVCs) were stuck with the error: `pod has unbound immediate PersistentVolumeClaims`.
- The NFS server provisioner pod was unable to initialize.

### Solution
1. **Dependency Break:** The NFS server's StatefulSet configuration was updated to use the `local-path` StorageClass for its primary export volume instead of the circular `csi-cinder-high-speed`.
2. **PVC Cleanup:** The stale `Pending` PVC `data-nfs-server-nfs-server-provisioner-0` was manually deleted to trigger a fresh binding.
3. **Automated Recovery:** The StatefulSet successfully recreated the PVC using the `local-path` class, allowing the provisioner to start and subsequently fulfill the storage requests for the rest of the stack.

### Applied Patch
**Location:** Cluster-wide (Manual/ArgoCD)
**Change:** Updated `nfs-server` StatefulSet `volumeClaimTemplates` to use `local-path`.
```yaml
# Simplified patch context
spec:
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      storageClassName: local-path # Changed from csi-cinder-high-speed
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 100Gi
```
