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

  lifecycle { ignore_changes = [tags] }

  depends_on = [azurerm_role_assignment.aks_dns_contributor_role, azurerm_role_assignment.aks_network_contributor]
}
