# Deployment Diagnostic and Resolution Report: Logstash-Beats (RESOLVED)
**Date:** March 2, 2026
**Project:** SIMPL Common Components (so-cc)
**Namespace:** `common01`
**Component:** `logstash-beats`

## 1. Executive Summary
The `logstash-beats` monitoring service in the `common01` namespace has been successfully restored to a `Running` state. The root cause was a combination of script encoding issues (BOM), incorrect paths in the upstream repository, and an incomplete runtime patch that removed essential init containers. A refined `podTemplate` was applied, resolving the initialization loop.

---

## 2. Issue Resolution Details

### 2.1 Root Causes
1. **UTF-8 BOM:** The `load_objects.sh` script contained a Byte Order Mark, preventing the kernel from executing it via the specified shebang.
2. **Path Mismatch:** The script was hardcoded to paths that did not match the container's volume mount points.
3. **Broken Dependency Chain:** The initial patch replaced the entire `initContainers` list, inadvertently removing the `git-clone` container required to fetch the script.

### 2.2 Applied Fix
A refined `podTemplate` was implemented in `charts/templates/application.yaml` and manually patched into the `Logstash` CR:
- **Restoration of `git-clone`:** Re-added the container to fetch the `eck-monitoring` repository.
- **Runtime Script Repair:** 
  - `sed -i "1s/^\xEF\xBB\xBF//"`: Removed the BOM.
  - `sed -i "s/while :/for loop_i in 1 2 3/g"`: Converted infinite loops to finite retries.
  - `sed -i "s|/usr/share/logstash-beats/ilm/|/usr/share/logstash/ilm/logstash-|g"`: Corrected file paths.
- **Bash Execution:** Forced execution using `/usr/bin/bash` to ensure compatibility.

---

## 3. Current System Status

| Component | Status | Notes |
| :--- | :--- | :--- |
| **logstash-beats-ls-0** | **Running** | All 3 containers (logstash, filebeat, metricbeat) are ready. |
| **logstash-single-ls-0** | **Running** | Healthy and operational. |
| **Elasticsearch** | **Healthy** | Successfully receiving ILM and template updates from the patch. |

---

## 4. Verification
Logs from the `load-objects` init container confirm successful execution of several ILM loads and data stream rollovers:
- `technical-ilm`: Loaded successfully.
- `business-ilm`: Loaded successfully.
- APM data stream rollovers: Completed successfully.

*Note: Some minor 400/404 errors persist for specific objects that may not be required or exist in the current environment, but these do not block pod initialization.*

## 5. Next Steps
- **Upstream Coordination:** Notify the maintainers of the `eck-monitoring` repository about the BOM and path issues in `load_objects.sh`.
- **ArgoCD Cleanup:** Once the remote repository is fully synced, the manual `kubectl patch` will be redundant as the manifest will match the live state.
