The logstash-beats pod clones the eck-monitoring repository from the main branch.
Since the latest commit pushed to main, the logstash-beats pod remains in a Degraded state. The load-objects container shows the following error on startup:
./load_objects.sh: line 1: #!/bin/bash: No such file or directory
Previously, the script was using #!/bin/sh, but it has now been changed to #!/bin/bash. It seems the container image does not include bash, causing the script to fail immediately.
As a result, the ILMs are not loaded and multiple subsequent connection errors to Elasticsearch are observed.

```
Starting loading logstash beats ILMs objects...
Starting loading ILM: metrics-apm.app_metrics-default_policy Attempt no. 1 to load ILM curl: (7) Failed to connect to elastic-elasticsearch-es-http port 9200: Connection refused Response:
-------- 
Attempt no. 2 to load ILM curl: (7) Failed to connect to elastic-elasticsearch-es-http port 9200: Connection refused
...
```

Could you please review the latest changes to load_objects.sh? Should the base image include bash, or should the script remain compatible with /bin/sh as before?