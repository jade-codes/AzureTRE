resource "azurerm_kubernetes_cluster" "aks" {
  name                       = "aks-${local.service_resource_name_suffix}"
  location                   = data.azurerm_resource_group.ws.location
  resource_group_name        = data.azurerm_resource_group.ws.name
  dns_prefix_private_cluster = "aks-${local.service_resource_name_suffix}"

  default_node_pool {
    name                 = "default"
    vnet_subnet_id       = data.azurerm_subnet.services.id
    auto_scaling_enabled = true
    max_count            = 5
    min_count            = 1

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    admin_group_object_ids = [
      var.workspace_owners_group_id
    ]
  }

  private_dns_zone_id = data.azurerm_private_dns_zone.aks.id

  private_cluster_enabled = true

  network_profile {
    network_plugin      = "azure"
    network_policy      = "cilium"
    network_data_plane  = "cilium"
    network_plugin_mode = "overlay"
    load_balancer_sku   = "standard"
    outbound_type       = "userDefinedRouting"
    pod_cidr            = "192.168.0.0/16"
    service_cidr        = "192.169.0.0/16"
    dns_service_ip      = "192.169.0.10"
  }

  web_app_routing {
    dns_zone_ids = [data.azurerm_private_dns_zone.aks.id]
    #Linting error is wrong, this is a valid value, hashicorp extension hasn't been updated with latest
    default_nginx_controller = "Internal"
  }

  monitor_metrics {
    annotations_allowed = null
    labels_allowed      = null
  }

  microsoft_defender {
    log_analytics_workspace_id = data.azurerm_log_analytics_workspace.workspace.id
  }

  oms_agent {
    log_analytics_workspace_id      = data.azurerm_log_analytics_workspace.workspace.id
    msi_auth_for_monitoring_enabled = true
  }

  lifecycle { ignore_changes = [tags] }

  depends_on = [azurerm_role_assignment.aks_dns_contributor_role, azurerm_role_assignment.aks_network_contributor]
}


module "logging" {
  source                       = "./logging"
  aks_cluster_name             = azurerm_kubernetes_cluster.aks.name
  location                     = azurerm_kubernetes_cluster.aks.location
  resource_group_name          = azurerm_kubernetes_cluster.aks.resource_group_name
  private_link_scope_name      = local.private_link_scope_name
  log_analytics_workspace_name = data.azurerm_log_analytics_workspace.workspace.name

  depends_on = [azurerm_kubernetes_cluster.aks]
}

module "monitoring" {
  source                  = "./monitoring"
  aks_cluster_name        = azurerm_kubernetes_cluster.aks.name
  location                = azurerm_kubernetes_cluster.aks.location
  resource_group_name     = azurerm_kubernetes_cluster.aks.resource_group_name
  private_link_scope_name = local.private_link_scope_name
  monitor_workspace_name  = data.azurerm_monitor_workspace.amw.name

  depends_on = [azurerm_kubernetes_cluster.aks]
}
