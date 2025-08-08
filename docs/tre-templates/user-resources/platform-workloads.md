# AKS Platforms User Resource Service Bundle

This is a User Resource Service template that deploys containerised platform workloads to an Azure Kubernetes Service (AKS) cluster within a TRE workspace. It provides predefined workload configurations optimised for different research scenarios including DevSecOps, AI/ML, and Knowledge Graph workloads.

## Prerequisites

- [A base workspace bundle installed](../workspaces/base.md)
- [An AKS workspace service bundle installed](../workspace-services/aks.md)

## Building the Bundle

The AKS platform resources user resource container image needs building and pushing:

```bash
make user_resource_bundle WORKSPACE_SERVICE=aks BUNDLE=aks-azure-platform-resources 
```

## Available Workload Types

### DevSecOps Workload
- **Node Size**: Standard_DS2_v2 (2 vCPU, 7 GB RAM)
- **Default Node Count**: 2
- **Autoscaling**: Enabled (1-5 nodes)
- **Use Case**: Development, security, and operations workflows including CI/CD pipelines, code repositories, and security scanning tools

### AI Model Workload  
- **Node Size**: Standard_NC6 (6 vCPU, 56 GB RAM, GPU-enabled)
- **Default Node Count**: 3
- **Autoscaling**: Enabled (1-5 nodes)
- **Use Case**: Machine learning model training, inference, and AI research requiring GPU acceleration

### Knowledge Graph Workload
- **Node Size**: Standard_D4_v3 (4 vCPU, 16 GB RAM)
- **Default Node Count**: 3
- **Autoscaling**: Enabled (1-5 nodes)
- **Use Case**: Graph databases, semantic analysis, and knowledge management systems

## Deployment Process

The platform resources template:
1. Provisions additional node pools in the existing AKS cluster with workload-specific configurations
2. Deploys Helm charts containing the required platform components
3. Configures ingress and networking for service access
4. Provides workload endpoints for accessing deployed applications

## Configuration

When deploying AKS platform resources, the following parameters are configured:

### Required Parameters
- `workload_name`: Select from DevSecOps, AI Model, or Knowledge Graph

### Auto-configured Parameters
- Node sizing and scaling parameters are automatically set based on the selected workload type
- Kubernetes node selectors ensure workloads run on appropriate node pools
- DNS configuration for private cluster access

## Security Considerations

- All workloads run within the AKS cluster's network policies
- Container images are sourced from approved registries only
- Network traffic is restricted by TRE firewall rules
- Resource limits prevent resource exhaustion
- RBAC controls access to cluster resources

## Service Access

Once deployed, platform resources are accessible through:
- Workload endpoints provided in the deployment outputs
- Private DNS resolution within the TRE network
- Kubernetes ingress controllers for web-based services

## Notes

- The AKS cluster must be deployed and operational before installing platform resources
- Each workload type creates dedicated node pools with appropriate sizing
- Autoscaling is enabled by default to handle varying workload demands
- Workload endpoints are dynamically generated and captured as deployment outputs
