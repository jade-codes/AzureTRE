variable "workspace_id" {
  type = string
}
variable "tre_id" {
  type = string
}
variable "tre_resource_id" {
  type = string
}
variable "arm_environment" {
  type = string
}
variable "azure_devops_organisation" {
  type    = string
  default = ""
}
variable "azure_devops_project" {
  type    = string
  default = ""
}

variable "azdo_client_id" {
  type = string
}
