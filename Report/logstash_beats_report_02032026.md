# Deployment Diagnostic and Resolution Report: Logstash-Beats
**Date:** March 2, 2026
**Project:** SIMPL Common Components (so-cc)
**Namespace:** `common01`
**Component:** `logstash-beats`

## 1. Executive Summary
The `logstash-beats` monitoring service in the `common01` namespace continues to fail during initialization. While the previous report identified several issues, the implemented patch was incomplete, leading to the removal of essential init containers. This updated report details the refined solution required to restore service.

---

## 2. Issue Description: Logstash-Beats Initialization Failure (CRITICAL)

### Symptom
- Pod `logstash-beats-ls-0` remains in `Init:2/3` state.
- Init container `load-objects` logs show: `./load_objects.sh: line 1: #!/bin/bash: No such file or directory`.
- Script execution fails despite `bash` being present in the image at `/usr/bin/bash`.

### Root Cause Analysis
1. **UTF-8 BOM Encoding:** The script `load_objects.sh` in the upstream `eck-monitoring` repository contains a Byte Order Mark (`0xEF 0xBB 0xBF`). This causes the shell to fail to interpret the shebang correctly.
2. **Incorrect Directory Paths:** The script expects ILM files in `/usr/share/logstash-beats/ilm/`, but they are mounted at `/usr/share/logstash/ilm/`.
3. **Incomplete Patch:** A previous attempt to override the `podTemplate` in `charts/templates/application.yaml` replaced the entire `initContainers` list, removing the essential `git-clone` container which provides the script itself.

---

## 3. Refined Solution

### 3.1 Corrected PodTemplate Override
The root application manifest (`charts/templates/application.yaml`) has been updated with a comprehensive `podTemplate` that:
- **Restores `git-clone`:** Re-inserts the init container responsible for cloning the `eck-monitoring` repository.
- **Patches `load-objects`:** 
    - Removes the BOM: `sed -i "1s/^\xEF\xBB\xBF//"`
    - Fixes paths: `sed -i "s|/usr/share/logstash-beats/ilm/|/usr/share/logstash/ilm/logstash-|g"`
    - Implements a finite retry loop: `sed -i "s/while :/for loop_i in 1 2 3/g"`
- **Injects Dependencies:** Correctly configures `env` vars (e.g., `ELASTIC_PASSWORD`) and `volumeMounts` required for the script to interact with Elasticsearch.

### 3.2 Deployment Status
The changes are currently staged in the local repository. 

**Note:** ArgoCD is currently `OutOfSync` because the local `main` branch contains commits (up to `29ec27f`) that have not been pushed to the remote repository.

---

## 4. Current System Status

| Component | Status | Notes |
| :--- | :--- | :--- |
| **eck-operator** | Healthy | Managing namespaces `authority01` and `common01`. |
| **logstash-single** | Healthy | Fully operational. |
| **logstash-beats** | **Failing** | Awaiting Git push and ArgoCD sync of the refined patch. |

---

## 5. Recommended Actions
1. **Push Changes:** Execute `git push origin main` to allow ArgoCD to pick up the refined `podTemplate`.
2. **Sync ArgoCD:** Manually trigger a sync of the `common01` application in ArgoCD to apply the `Logstash` CR changes.
3. **Verify:** Confirm that `logstash-beats-ls-0` successfully completes its init containers and reaches `Running` state.
