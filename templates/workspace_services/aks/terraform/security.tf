resource "azurerm_network_security_rule" "aks_node_pod_inbound" {
  name                        = "aks-service-subnet-pod-inbound"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = azurerm_kubernetes_cluster.aks.default_node_pool.0.vnet_subnet_id
  destination_address_prefix  = azurerm_kubernetes_cluster.aks.network_profile.0.pod_cidr
  resource_group_name         = data.azurerm_resource_group.ws.name
  network_security_group_name = data.azurerm_subnet.services.network_security_group_id

  depends_on = [azurerm_kubernetes_cluster.aks]
}
