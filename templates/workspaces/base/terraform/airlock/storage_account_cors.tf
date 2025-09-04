resource "azapi_update_resource" "cors_import_approved" {
  type      = "Microsoft.Storage/storageAccounts/blobServices@2023-05-01"
  name      = "default"
  parent_id = azurerm_storage_account.sa_import_approved.id

  body = {
    properties = {
      cors = {
        corsRules = local.airlock_api_read_only_cors_rules
      }
    }
  }
}

resource "azapi_update_resource" "cors_export_internal" {
  type      = "Microsoft.Storage/storageAccounts/blobServices@2023-05-01"
  name      = "default"
  parent_id = azurerm_storage_account.sa_export_internal.id

  body = {
    properties = {
      cors = {
        corsRules = local.airlock_api_read_write_cors_rules
      }
    }
  }
}

resource "azapi_update_resource" "cors_export_in_progress" {
  type      = "Microsoft.Storage/storageAccounts/blobServices@2023-05-01"
  name      = "default"
  parent_id = azurerm_storage_account.sa_export_inprogress.id

  body = {
    properties = {
      cors = {
        corsRules = local.airlock_api_read_only_cors_rules
      }
    }
  }
}
