# OpenBao initialisation for SIMPL

## Description
This project contains the configuration files required for OpenBao initialisation using Helm.

## Pre-Requisites

Ensure you have the following tools installed before starting the deployment process:
- Git
- Helm
- Kubectl

Additionally, ensure you have access to a Kubernetes cluster where ArgoCD is installed.

The following versions of the elements will be used in the process:

| Pre-Requisites         |     Version     | Description                                                                                                                                     |
| ---------------------- |     :-----:     | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| DNS sub-domain name    |       N/A       | This domain will be used to address all services of the agent. <br/> example: `*.common.int.simpl-europe.eu`   |  
| Kubernetes Cluster     | 1.29.x or newer | Other version *might* work but tests were performed using 1.29.x version   |

## Installation

Modify the values file for your preference and deploy as an usual Helm chart. 

Mentionable values:

| Variable name                 |     Example         | Description     |
| ----------------------        |     :-----:         | --------------- |
| namespaceTag                  | common      | namespaceTag (part of fqdn) |
| cluster.namespace             | common      | namespace of deployment  |
| domainSuffix                  | int.simpl-europe.eu | domain suffix |
