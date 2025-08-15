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
variable "ado_inbound_cidrs" {
  type    = list(string)
  default = ["51.104.26.0/24"] # UK South (per Microsoft doc)
}
