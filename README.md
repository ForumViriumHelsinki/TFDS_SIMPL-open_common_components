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

---

### Step 2: Deploy the Components

Once your configuration is set, you can trigger the deployment using ArgoCD:

```bash
kubectl apply -f ArgoCD/common_components_manifest.yaml
```

ArgoCD will automatically read the configuration and begin spinning up the Common Components in the specified namespace.

---

### Step 3: Next Steps

After the Common Components are successfully running, you can proceed to deploy the individual SIMPL-Open agents:
* [Governance Authority](https://github.com/ForumViriumHelsinki/TFDS_SIMPL-open_governance_authority)
* [Data Provider](https://github.com/ForumViriumHelsinki/TFDS_SIMPL-open_data_provider)
* [Data Consumer](https://github.com/ForumViriumHelsinki/TFDS_SIMPL-open_data_consumer)
