resource "azurerm_dashboard_grafana" "grafana" {
  name                  = "gra-${var.tre_id}-ws-${local.short_workspace_id}"
  resource_group_name   = var.resource_group_name
  location              = var.location
  grafana_major_version = 11

  public_network_access_enabled     = var.enable_local_debugging ? true : false
  api_key_enabled                   = false
  deterministic_outbound_ip_enabled = var.enable_local_debugging ? true : false

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.grafana.id]
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.amw.id
  }
}

resource "null_resource" "always_run" {
  triggers = {
    timestamp = "${timestamp()}"
  }
}

resource "azurerm_dashboard_grafana_managed_private_endpoint" "grafana" {
  grafana_id                   = azurerm_dashboard_grafana.grafana.id
  name                         = "grafana-prom-mpe"
  location                     = azurerm_dashboard_grafana.grafana.location
  private_link_resource_id     = azurerm_monitor_workspace.amw.id
  private_link_resource_region = azurerm_dashboard_grafana.grafana.location
  group_ids                    = ["prometheusMetrics"]

  lifecycle {
    replace_triggered_by = [
      null_resource.always_run
    ]
  }
}

resource "azapi_resource_action" "grafana_managed_private_endpoint_connection_approval" {
  type        = "Microsoft.Monitor/accounts/privateEndpointConnections@2023-04-03"
  resource_id = local.grafana_private_endpoint_connection_id
  method      = "PUT"
  body = {
    properties = {
      privateLinkServiceConnectionState = {
        actionsRequired = "None"
        description     = "Approved via Terraform"
        status          = "Approved"
      }
    }
  }
  depends_on = [azurerm_dashboard_grafana_managed_private_endpoint.grafana]
}

resource "azurerm_private_endpoint" "grafana" {
  name                = "pe-grafana-${var.tre_id}-ws-${local.short_workspace_id}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.workspace_subnet_id

  private_service_connection {
    name                           = "psc-grafana-${var.tre_id}-ws-${local.short_workspace_id}"
    private_connection_resource_id = azurerm_dashboard_grafana.grafana.id
    subresource_names              = ["grafana"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "grafana-private-dns-zone-group"
    private_dns_zone_ids = [var.grafana_dns_zone_id]
  }
}
