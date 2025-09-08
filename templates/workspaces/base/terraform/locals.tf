locals {
  short_workspace_id             = substr(var.tre_resource_id, -4, -1)
  workspace_resource_name_suffix = "${var.tre_id}-ws-${local.short_workspace_id}"
  core_resource_group_name       = "rg-${var.tre_id}"
  storage_name                   = lower(replace("stg${substr(local.workspace_resource_name_suffix, -8, -1)}", "-", ""))
  keyvault_name                  = lower("kv-${substr(local.workspace_resource_name_suffix, -20, -1)}")
  redacted_senstive_value        = "REDACTED"
  tre_workspace_tags = {
    tre_id           = var.tre_id
    tre_workspace_id = var.tre_resource_id
    # For use in an Microsoft Internal Tenant only!
    "SecurityControl" = "Ignore"
    "CostControl"     = "Ignore"
  }
  kv_encryption_key_name   = "tre-encryption-${local.workspace_resource_name_suffix}"
  encryption_identity_name = "id-encryption-${var.tre_id}-${local.short_workspace_id}"
  shared_storage_name      = "vm-shared-storage"
  ui_fqdn                  = "${var.tre_id}.${var.location}.cloudapp.azure.com"
}
