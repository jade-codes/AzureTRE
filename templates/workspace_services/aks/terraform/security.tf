resource "azurerm_network_security_rule" "allow_azure_load_balancer_inbound" {
  name                        = "${azurerm_kubernetes_cluster.aks.name}-allow-azure-load-balancer-inbound"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = data.azurerm_subnet.services.address_prefix
  resource_group_name         = azurerm_kubernetes_cluster.aks.resource_group_name
  network_security_group_name = "nsg-ws"
}

resource "azurerm_network_security_rule" "aks_node_pod_inbound" {
  name                        = "${azurerm_kubernetes_cluster.aks.name}-node-to-pod-inbound"
  priority                    = 201
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = data.azurerm_subnet.services.address_prefix
  destination_address_prefix  = azurerm_kubernetes_cluster.aks.network_profile.0.pod_cidr
  resource_group_name         = data.azurerm_resource_group.ws.name
  network_security_group_name = "nsg-ws"
}

resource "azurerm_network_security_rule" "aks_pod_pod_inbound" {
  name                        = "${azurerm_kubernetes_cluster.aks.name}-pod-to-pod-inbound"
  priority                    = 202
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = azurerm_kubernetes_cluster.aks.network_profile.0.pod_cidr
  destination_address_prefix  = azurerm_kubernetes_cluster.aks.network_profile.0.pod_cidr
  resource_group_name         = data.azurerm_resource_group.ws.name
  network_security_group_name = "nsg-ws"
}

resource "azurerm_network_security_rule" "aks_pod_pod_outbound" {
  name                        = "${azurerm_kubernetes_cluster.aks.name}-pod-to-pod-outbound"
  priority                    = 203
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = azurerm_kubernetes_cluster.aks.network_profile.0.pod_cidr
  destination_address_prefix  = azurerm_kubernetes_cluster.aks.network_profile.0.pod_cidr
  resource_group_name         = data.azurerm_resource_group.ws.name
  network_security_group_name = "nsg-ws"
}
