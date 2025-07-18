# AKS Workspace Service for Azure TRE

This workspace service template provisions an Azure Kubernetes Service (AKS) cluster as part of a TRE workspace.

## Files
- `terraform/main.tf`: Terraform resource definitions for AKS
- `terraform/variables.tf`: Input variables for AKS deployment
- `terraform/outputs.tf`: Outputs from AKS deployment
- `porter.yaml`: Porter manifest for bundle packaging
- `template_schema.json`: JSON schema for UI/API parameter validation

## Parameters
- `node_count`: Number of nodes in the default node pool
- `node_vm_size`: VM size for the default node pool

## Usage
Deploy this service using the TRE CLI or API. Update parameters as needed in the workspace creation form.
