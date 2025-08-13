variable "tre_id" {
  type        = string
  description = "Unique TRE ID"
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "tre_core_tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
}

variable "shared_subnet" {
  type = string
}

variable "vm_image_build_software_dns_zone_id" {
  type = string
}
