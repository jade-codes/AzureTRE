# AKS User Resources

This folder contains user resources that can be deployed to the AKS workspace service cluster. These workloads provide researchers with various containerised tools and applications running on Kubernetes.

## Available User Resources

### Workload Resources (aks-azure-workloads)

The workloads template provides predefined workload configurations optimised for different research scenarios:

#### DevSecOps Workload
- **Node Size**: Standard_DS2_v2 (2 vCPU, 7 GB RAM)
- **Default Node Count**: 2
- **Autoscaling**: Enabled (1-5 nodes)
- **Use Case**: Development, security, and operations workflows including CI/CD pipelines, code repositories, and security scanning tools

#### AI Models Workload  
- **Node Size**: Standard_NC6 (6 vCPU, 56 GB RAM, GPU-enabled)
- **Default Node Count**: 3
- **Autoscaling**: Enabled (1-5 nodes)
- **Use Case**: Machine learning model training, inference, and AI research requiring GPU acceleration

#### Knowledge Graph Workload
- **Node Size**: Standard_D4_v3 (4 vCPU, 16 GB RAM)
- **Default Node Count**: 3
- **Autoscaling**: Enabled (1-5 nodes)
- **Use Case**: Graph databases, semantic analysis, and knowledge management systems

Each workload template follows the TRE Porter bundle structure and deploys as Kubernetes workloads via Helm charts.

## Template Structure

Each user resource template follows a consistent layout:

| File                   | Description                                                                                                                                                                        |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `porter.yaml`          | Porter manifest describing the template, including name, version, parameters, deployment actions, and outputs                                                                     |
| `template_schema.json` | JSON schema controlling parameter validation and UI form generation                                                                                                                |
| `terraform/`           | Terraform modules for provisioning Azure resources (if needed)                                                                                                                    |
| `templates/`           | Helm chart templates for deploying workloads to the AKS cluster (organised by workload type: dsop, ai, kg)                                                                      |

## Configuration Parameters

### Required Parameters
- `workload_category`: Select from available workload categories (DevSecOps, AI Models, Knowledge Graph)

### Optional Parameters (Auto-configured per workload)
- `display_name`: Display name for the workload (default: "My Workload")
- `description`: Description of workload usage (default: "I will use this workload for research.")
- `overview`: Long-form markdown description of the workload
- `node_size`: VM size for cluster nodes (set automatically based on workload type)
- `node_count`: Initial number of nodes (set automatically based on workload type)
- `node_autoscaling_enabled`: Whether autoscaling is enabled (default: true for all workloads)
- `node_autoscaling_min_count`: Minimum nodes when autoscaling (default: 1)
- `node_autoscaling_max_count`: Maximum nodes when autoscaling (default: 5)

## Porter Outputs

When successfully deployed, the platform resources template provides the following outputs:

| Output | Description | Usage |
| ------ | ----------- | ----- |
| `aks_private_dns_zone` | Private DNS zone for the AKS cluster | Internal DNS resolution for cluster services |
| `aks_cluster_name` | Name of the AKS cluster | Reference for kubectl and Azure CLI operations |
| `aks_resource_group_name` | Resource group containing the AKS cluster | Azure resource management and access control |
| `aks_short_node_pool_id` | Short identifier for the node pool | Kubernetes node selector and scheduling |
| `workload_endpoints` | JSON array of workload endpoints | URLs for accessing deployed applications and services |

These outputs are automatically captured during deployment and can be used by:
- Other user resources that need to deploy to the same cluster
- TRE API for status reporting and user access
- Monitoring and management tools
- Network configuration and routing

## Customising User Resources

To create or modify a user resource template:

1. **Update `porter.yaml`**:
   - Change the template name and description
   - Update the version for new deployments
   - Modify parameters as needed
   - Configure deployment actions (install, upgrade, uninstall)
   - Define outputs that other resources might need

2. **Update `template_schema.json`**:
   - Define parameter validation rules
   - Specify UI form layout and options
   - Ensure parameter names match those in `porter.yaml`
   - Add new workload types using conditional schemas (`allOf` with `if`/`then`)

3. **Create Helm chart templates**:
   - Define Helm charts in the `templates/` directory organised by workload type
   - Use Porter parameters for configuration via Helm values
   - Follow Kubernetes best practices for security and resource management
   - Include appropriate node selectors to target the correct node pools

## Security Considerations

- All user resources run within the AKS cluster network policies
- Resource limits should be configured to prevent resource exhaustion
- Container images should be from approved registries
- Persistent storage should use appropriate access modes
- Network policies control inter-pod communication

## Deployment

User resources are deployed through the TRE API or CLI, which:
1. Validates parameters against the JSON schema
2. Executes the Porter bundle to deploy Kubernetes resources via Helm
3. Captures outputs for integration with other services
4. Provides status and connection information to users
