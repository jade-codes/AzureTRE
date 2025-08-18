variable "environment_type" {
  type = string
}

variable "node_agent_pool_label" {
  type = string
}

variable "node_count" {
  type = number
}

variable "node_size" {
  type = string
}

variable "node_autoscaling_enabled" {
  type = bool
}

variable "node_autoscaling_min_count" {
  type = number
}

variable "node_autoscaling_max_count" {
  type = number
}

variable "parent_service_id" {
  type = string
}

variable "tre_id" {
  type = string
}

variable "tre_resource_id" {
  type = string
}

variable "workspace_id" {
  type = string
}
