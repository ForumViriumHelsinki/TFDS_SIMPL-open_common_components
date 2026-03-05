Ocassionaly, the init-bao job might go ahead with creating secrets, despite open-bao secret engine not being available. This creates empty secrets, which might cause components to fail.

in case this happens, the secrets must be deleted and then the job has to be restarted if it has ran out of tries.
These secrets have to be deleted:
secrets-root-token
secrets-unseal-keys


Failing pod restart

If failing. these two pods need to be restarted after OpenBao is up. They rely on information from OpenBao and may be up before it is up.
Although it's rare, it might happen more than once so retry the following steps if init-bao is failing again.
