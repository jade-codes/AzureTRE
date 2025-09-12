variable "arm_environment" {
  description = "Azure environment (e.g., public, AzureCloud)"
  type        = string
  default     = "public"
}

variable "id" {
  description = "Resource ID for this installation"
  type        = string
}

variable "aad_authority_url" {
  description = "AAD authority URL"
  type        = string
  default     = "https://login.microsoftonline.com"
}

variable "workspace_id" {
  description = "The unique ID of the TRE workspace."
  type        = string
}

variable "metric_labels_allowlist" {
  description = "Allowed labels for Prometheus metrics collection"
  type        = string
  default     = null
}

variable "metric_annotations_allowlist" {
  description = "Allowed annotations for Prometheus metrics collection"
  type        = string
  default     = null
}

variable "mgmt_acr_name" {
  description = "The name of the management Azure Container Registry."
  type        = string
}

variable "mgmt_resource_group_name" {
  description = "Resource group containing the management ACR."
  type        = string
}

variable "tre_id" {
  description = "TRE instance ID."
  type        = string
}

variable "workspace_owners_group_id" {
  description = "The object ID of the Azure AD group for workspace owners."
  type        = string
}
