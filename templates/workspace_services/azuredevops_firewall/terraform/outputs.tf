output "services_addresses" {
  value = jsonencode(data.azurerm_subnet.services.address_prefixes)
}

output "azdo_source_addresses" {
  value = jsonencode(var.ado_inbound_cidrs)
}
