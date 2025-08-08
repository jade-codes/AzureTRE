# AKS Service Bundle

This workspace service template provisions an Azure Kubernetes Service (AKS) cluster as part of a TRE workspace. The AKS cluster provides a container orchestration platform for running containerised workloads within the secure TRE environment.

See: [Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/)

## Firewall Rules

Please be aware that the following Firewall rules are opened for the workspace when this service is deployed:

Service Tags:

- AzureActiveDirectory

## Prerequisites

- [A base workspace bundle installed](../workspaces/base.md)

## Building the Bundle

The AKS workspace service container image needs building and pushing:

```bash
make workspace_service_bundle BUNDLE=aks
```

## AKS Workspace Service Configuration

When deploying an AKS service into a workspace the following properties need to be configured.

### Required Properties

| Property | Description |
| -------- | ----------- |
| `workspace_owners_group_id` | The object ID of the Azure AD group that will be granted admin access to the AKS cluster |

## User Resources

This AKS workspace service supports various user resources that can be deployed to the cluster:

- **Platform Resources**: Predefined workload configurations for DevSecOps, AI/ML, and Knowledge Graph scenarios

See the [AKS Platform Workloads documentation](../user-resources/platform-workloads.md) for more details.

## Architecture

The AKS workspace service creates:
- An AKS cluster with a managed control plane
- A default node pool
- Network integration with the TRE workspace virtual network
- Azure AD integration for cluster access control
- Container registry integration for image management

## Outputs

The AKS workspace service provides outputs that can be consumed by user resources:
- AKS cluster name and resource group
- Cluster identity and FQDN
- Node resource group for additional resources
- Workspace address space for networking
