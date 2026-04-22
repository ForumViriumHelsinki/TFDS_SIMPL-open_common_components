# TFDS SIMPL-open Common Components

This repository contains the deployment manifests and configurations for the **SIMPL-Open Common Components**. The deployment is highly configurable, supporting both scalable multi-node environments and an **optional local, single-node Kubernetes (e.g., k3s) deployment mode** for development and testing.

The Common Components form the foundational infrastructure (including Kafka, PostgreSQL, OpenBao, etc.) that is required by all other SIMPL-Open data space agents (Governance Authority, Data Provider, Data Consumer).

## 🚀 Deployment Guide

This guide is designed for users who want to deploy the Common Components using **ArgoCD**.

### Prerequisites

Before deploying the Common Components, ensure your environment meets the following requirements:
1. **Running Kubernetes Cluster:** A standard multi-node cluster or a local single-node cluster (like k3s). Ensure `MetalLB` and an Ingress Controller (e.g., `nginx`) are present.
2. **ArgoCD Installed:** ArgoCD must be running in your cluster to process the application manifests.
3. **DNS Routing:** A wildcard DNS record (e.g., `*.common.yourdomain.com`) pointing to your cluster's public/ingress IP.

---

### Step 1: Configure the ArgoCD Manifest

All configuration for the deployment is managed through a single file: `ArgoCD/common_components_manifest.yaml`.

Open this file and verify or update the `values` block to match your environment:

1. **Namespace Tag & Domain:** Update the identifier for your namespace and your base domain:
   ```yaml
   namespaceTag: common                    # identifier of deployment and part of fqdn
   domainSuffix: ds.helsinki.tfds.io       # last part of fqdn
   ```

2. **Agent List:** Define the agents that will interact with these common components:
   ```yaml
   agentList:
     authorities:
       - authority
     consumers:
       - consumer
     providers:
       - dataprovider
   ```

3. **Single Node / Resource Optimizations:** To enable a lighter footprint for single-node deployments, adjust the following:
   *   `resourcePreset: low` (Disables strict resource requests/limits, allowing pods to schedule on constrained nodes).
   *   `kafka.ha: false` (Deploys 1 replica of Kafka components instead of 3).

4. **Monitoring (Elastic Stack):** Configure the centralized monitoring stack:
   ```yaml
   monitoring:
     enabled: false                        # set to true to enable monitoring features
   ```
   *   **Impact if `false`:** Skips deploying the heavy Elastic stack (`eck-operator`, Elasticsearch, Kibana), saving significant CPU and memory (Recommended for single-node).
   *   **Impact if `true`:** Installs the full observability stack for production-grade insights.

5. **External SMTP Integration (Notifications):**
   By default, the Common Components deploy a local `Mailpit` sandbox to intercept and view email notifications during development. However, for production data spaces, you should route emails through an external SMTP relay.
   
   To enable external SMTP routing, configure the following variables:
   ```yaml
   mailpit:
     enabled: false  # Must be false to trigger external SMTP logic
   smtp:
     host: "smtp.example.com"
     user: "your-smtp-username"
     defaultReceiver: "admin@example.com"
   ```
   *Note: For security, the SMTP password is never stored in Git. See the Troubleshooting & Lifecycle Management section below for instructions on how to seed the real password via OpenBao.*

---

### Step 2: Deploy the Components

Once your configuration is set, you can trigger the deployment using ArgoCD:

```bash
kubectl apply -f ArgoCD/common_components_manifest.yaml
```

ArgoCD will automatically read the configuration and begin spinning up the Common Components in the specified namespace.

#### Retrieve the OpenBao token

Once the Openbao has been initialized, the "secrets-root-token" to access it can be acquired by using kubectl:

```shell
kubectl -n common get secret secrets-root-token -o jsonpath="{.data.token}" | base64 -d && echo
```

#### Updating the SMTP Password

For security, the SMTP password is never stored in Git or Helm manifests. It is managed entirely via OpenBao (Vault).

1.  **Initial Seeding:** When the cluster is deployed with `mailpit.enabled: false`, the `openbao-config` job automatically provisions the `common-notifications` Vault secret with the necessary Spring Boot TLS and Port (587) parameters, and seeds a placeholder password: `"update-me-password"`.
2.  **Manual Update:** A cluster administrator must log into the OpenBao Web UI (`https://secrets.common...`), locate the `common-notifications` secret, and update the `SMTP_PASSWORD` value to the real password.
3.  **Applying the Password:** Because the Spring Boot application caches Vault secrets on startup, you must restart the notification pod to load the new password:
    ```bash
    kubectl rollout restart deployment simpl-notification -n <common-namespace>
    ```

Once restarted, the `simpl-notification` service will successfully route all data space emails (like onboarding approvals) through your external SMTP relay.

---

### Step 3: Next Steps

After the Common Components are successfully running, you can proceed to deploy the individual SIMPL-Open agents:
* [Governance Authority](https://github.com/ForumViriumHelsinki/TFDS_SIMPL-open_governance_authority)
* [Data Provider](https://github.com/ForumViriumHelsinki/TFDS_SIMPL-open_data_provider)
* [Data Consumer](https://github.com/ForumViriumHelsinki/TFDS_SIMPL-open_data_consumer)

---

## 🛠️ Troubleshooting & Lifecycle Management

### Handling Cluster Reboots (The OpenBao Seal)

When a Kubernetes node reboots or the `openbao-common-0` pod is restarted, you will likely notice that all other dependent SIMPL-Open agents (Governance Authority, Data Provider, Data Consumer) fail to start or hang indefinitely. You may see errors in their logs such as:
*   `tier2-gateway`: Hangs in a `404` or `503` loop waiting for credentials.
*   `identity-provider` or `authentication-provider`: CrashLoopBackOff or fail their `/actuator/health` checks.

#### The Root Cause
This is **expected behavior** resulting from the security architecture of HashiCorp Vault (OpenBao). 

When the OpenBao pod restarts, it boots into a **Sealed** state to protect its encrypted secrets. While sealed, it cannot serve any database credentials, TLS certificates, or configurations to the rest of the data space. Because ArgoCD only triggers Sync hooks on manifest changes or manual syncs, the `openbao-init` job (which contains the unseal commands) does not automatically run on a pod reboot.

#### How to Fix It
To fully recover the cluster after a hard reboot, you must manually unseal OpenBao and re-apply its configuration. This requires syncing two distinct applications in the ArgoCD UI.

**The Recommended Fix (ArgoCD Sync):**

**1. Unseal OpenBao:**
   1. Open the ArgoCD UI and locate the **`openbao-common`** application.
   2. Click **Sync**.
   3. ArgoCD will recreate the `openbao-init` job. This job reads the `secrets-unseal-keys` from Kubernetes and unseals the OpenBao pod.

**2. Reconfigure Pod Vaults:**
   1. Wait until the `openbao-common-0` pod is fully `1/1 Running`.
   2. Locate the main **`common-components`** application in ArgoCD.
   3. Click **Sync**.
   4. This sync triggers the `openbao-config` job, which is responsible for pushing the critical vault configuration and roles to the unsealed OpenBao instance.

Within seconds of the final sync completing, all hanging agent pods across the data space (e.g., `tier2-gateway`, `identity-provider`) will securely fetch their secrets and instantly resume their boot sequences.

### Fixing the "Split-Brain" Kafka Authentication Bug

If you manually delete or recreate the `kafka-users-secret` Kubernetes Secret after the initial deployment, you will cause a permanent "split-brain" authentication failure. Redpanda and other consumers will enter a `CrashLoopBackOff` state, constantly throwing `SASL_AUTHENTICATION_FAILED: Invalid username or password` errors in their logs.

#### The Root Cause
This occurs due to a synchronization mismatch between the two ArgoCD applications managing the cluster:
1.  **`openbao-common`:** Generates the random passwords and stores them in the `kafka-users-secret` Kubernetes Secret (used by Redpanda, Notification, etc.).
2.  **`common-components`:** Runs the `openbao-config` Job, which reads the Kubernetes Secret and pushes the passwords into the OpenBao KV store (used by Kafka).

The `openbao-config` Job contains safety logic (`if ! bao kv get...`) that **prevents it from ever overwriting existing credentials in Vault**. 
If you delete the Kubernetes Secret, ArgoCD generates a brand new one with fresh passwords. However, because passwords already exist in Vault from the first install, `openbao-config` refuses to update them. Kafka continues to enforce the old Vault passwords, while Redpanda attempts to use the new Kubernetes passwords.

#### How to Fix It
To resolve the split-brain state, you must manually delete the stale credentials from Vault to force the configuration job to synchronize them.

1.  **Delete the Stale Vault Credentials:**
    Log into the OpenBao Web UI (using your `secrets-root-token`) and manually delete the `common-kafka-credentials` secret from the KV engine.
2.  **Force the Configuration Sync:**
    Delete the completed configuration job so ArgoCD can recreate it:
    ```bash
    kubectl delete job openbao-config -n <common-namespace>
    ```
    Then, sync the main **`common-components`** application in ArgoCD. The job will run, see that the Vault secret is missing, and successfully push the *current* Kubernetes passwords into Vault.
3.  **Restart the Kafka Ecosystem:**
    Once the job completes, restart the affected pods so they fetch the synchronized passwords on boot:
    ```bash
    kubectl delete pod kafka-0 -n <common-namespace>
    kubectl rollout restart deployment redpanda -n <common-namespace>
    # Restart any other failing consumers (e.g., simpl-notification, icms)
    ```

### Updating the SMTP Password (Day 2 Operations)

For security, the SMTP password is never stored in Git or Helm manifests. It is managed entirely via OpenBao (Vault).

1.  **Initial Seeding:** When the cluster is deployed with `mailpit.enabled: false`, the `openbao-config` job automatically provisions the `common-notifications` Vault secret with the necessary Spring Boot TLS and Port (587) parameters, and seeds a placeholder password: `"update-me-password"`.
2.  **Manual Update:** A cluster administrator must log into the OpenBao Web UI (`https://secrets.common...`), locate the `common-notifications` secret, and update the `SMTP_PASSWORD` value to the real password.
3.  **Applying the Password:** Because the Spring Boot application caches Vault secrets on startup, you must restart the notification pod to load the new password:
    ```bash
    kubectl rollout restart deployment simpl-notification -n <common-namespace>
    ```

Once restarted, the `simpl-notification` service will successfully route all data space emails (like onboarding approvals) through your external SMTP relay.
