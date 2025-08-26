# AKS Workloads Service for Azure TRE

This workloads service template provisions an Azure Kubernetes Service (AKS) cluster as part of a TRE workspace. The AKS cluster provides a container orchestration platform for running containerised workloads within the secure TRE environment.

## Architecture

The AKS workspace service creates:
- An AKS cluster with a managed control plane
- A default node pool with configurable VM size and node count
- Network integration with the TRE workspace virtual network
- Azure AD integration for cluster access control
- Container registry integration for image management

## Files

- `terraform/main.tf`: Terraform resource definitions for AKS cluster and supporting resources
- `terraform/variables.tf`: Input variables for AKS deployment configuration
- `terraform/outputs.tf`: Outputs from AKS deployment (cluster endpoint, credentials, etc.)
- `porter.yaml`: Porter manifest for bundle packaging and deployment lifecycle
- `template_schema.json`: JSON schema for UI/API parameter validation
- `user_resources/`: Directory containing user resource templates that can be deployed to this AKS cluster

## Parameters

- `node_count`: Number of nodes in the default node pool (default: 3)
- `node_vm_size`: VM size for the default node pool (e.g., Standard_D2s_v3)
- `workspace_owners_group_id`: Azure AD group granted admin access to the AKS cluster

## Outputs

The AKS workspace service provides the following outputs for use by user resources:

| Output | Description | Usage |
| ------ | ----------- | ----- |
| `aks_id` | Full resource ID of the AKS cluster | Azure resource management and RBAC |
| `aks_name` | Name of the AKS cluster | kubectl and Azure CLI operations |
| `aks_fqdn` | Fully qualified domain name of the cluster | API server endpoint access |
| `aks_node_resource_group` | Resource group for AKS-managed node resources | Node-level resource management |
| `aks_identity_principal_id` | Principal ID of the AKS managed identity | RBAC and permissions configuration |
| `workspace_address_space` | Network address space of the workspace | Network planning and configuration |

## Prerequisites

- TRE workspace must be deployed and operational
- Appropriate Azure permissions for AKS cluster creation
- Network configuration allowing AKS integration

## Usage

1. Deploy this service using the TRE CLI or API
2. Configure parameters in the workspace service creation form
3. Once deployed, use kubectl or deploy user resources to interact with the cluster
4. Access the cluster through the TRE workspace network boundaries

## User Resources

This AKS workspace service supports various user resources that can be deployed to the cluster. See the `user_resources/` directory for available templates.

## Security Considerations

- The AKS cluster is deployed within the TRE network boundaries
- All network traffic is subject to TRE firewall rules
- Azure AD integration provides identity-based access control
- Container images should be sourced from approved registries only
