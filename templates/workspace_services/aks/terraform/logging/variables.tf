variable "aks_cluster_name" {
  description = "Name of the Azure Kubernetes Service (AKS) cluster"
  type        = string
}

variable "location" {
  description = "Location to deploy the monitoring resources"
  type        = string
  default     = "uksouth"
}

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  type        = string

}

variable "private_link_scope_name" {
  description = "Name of the private link scope"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy the monitoring resources"
  type        = string
}
