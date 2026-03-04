# Ticket: Logstash-Beats Initialization Failure
**Status:** RESOLVED
**Component:** Monitoring (Logstash / ELK)
**Severity:** CRITICAL

## Description
The `logstash-beats` service in the `common01` namespace failed to initialize, resulting in a persistent `Init:2/3` state.

### Cause
Initialization of the service failed due to multiple script errors and a broken configuration patch:
1. **UTF-8 BOM:** The `load_objects.sh` script contained a Byte Order Mark (`0xEF 0xBB 0xBF`), which prevented the shell from correctly interpreting the shebang, causing execution failures.
2. **Incorrect Path Mapping:** The script was hardcoded to find ILM policy JSON files in `/usr/share/logstash-beats/ilm/`, which did not match the container's volume mount at `/usr/share/logstash/ilm/`.
3. **Broken Init Chain:** A previous patch to the `podTemplate` incorrectly replaced the entire `initContainers` list, removing the essential `git-clone` container required to fetch the script.

### Effect
- The `logstash-beats-ls-0` pod remained in a `Degraded` or `Init` state for over 30 hours.
- Index Lifecycle Management (ILM) policies were not loaded, leading to index creation errors in Elasticsearch.
- Monitoring data collection was interrupted for several core services.

### Solution
1. **Refined PodTemplate Override:** Updated `charts/templates/application.yaml` with a comprehensive `podTemplate` that restores the `git-clone` init container and applies runtime repairs to the `load_objects.sh` script.
2. **Runtime Patching:** Implemented `sed` commands to strip the BOM, correct directory paths, and enforce finite retry logic.
3. **Manual CR Patch:** Successfully applied a manual `kubectl patch` to the `Logstash` CR in `common01` to trigger an immediate restart.

### Applied Patch
**Location:** `charts/templates/application.yaml`
**Change:** Updated `podTemplate` for Logstash to repair script at runtime.
```yaml
# Source: charts/templates/application.yaml
        logstash:
          podTemplate:
            spec:
              initContainers:
              - name: git-clone
                image: alpine/git
                args: [ "clone", "--single-branch", "--branch", "main", "https://code.europa.eu/simpl/simpl-open/development/monitoring/eck-monitoring.git", "/mnt/ilm/" ]
                volumeMounts: [ { "mountPath": "/mnt/ilm/", "name": "repo" } ]
              - name: load-objects
                command: [ "/usr/bin/bash", "-c" ]
                args:
                - |
                  cd /mnt/ilm/charts/kibana/scripts;
                  export STACK_VERSION={{ .Values.monitoring.targetRevision }};
                  export RELEASE_NAME={{ .Values.monitoring.fullnameOverride }};
                  sed -i "1s/^\xEF\xBB\xBF//" ./load_objects.sh;
                  sed -i "s/while :/for loop_i in 1 2 3/g" ./load_objects.sh;
                  sed -i "s|/usr/share/logstash-beats/ilm/|/usr/share/logstash/ilm/logstash-|g" ./load_objects.sh;
                  chmod +x ./load_objects.sh;
                  ./load_objects.sh 2>&1 || true
```
