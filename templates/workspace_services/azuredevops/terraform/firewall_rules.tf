resource "azurerm_ip_group" "ado_inbound" {
  name                = "ipg-${local.workspace_resource_name_suffix}-ado-inbound-ado"
  resource_group_name = data.azurerm_resource_group.ws.name
  location            = data.azurerm_resource_group.ws.location
  cidrs               = var.ado_inbound_cidrs
}

resource "azurerm_firewall_policy_rule_collection_group" "core_azdo" {
  name               = "rcg-${local.workspace_resource_name_suffix}-azure-devops"
  firewall_policy_id = data.azurerm_firewall_policy.core.id
  priority           = 501

  # Updates needed to allow updating of resources on virtual machine
  application_rule_collection {
    name     = "arc-${local.workspace_resource_name_suffix}-azure-devops"
    priority = 301
    action   = "Allow"

    rule {
      # Based on guidance from https://learn.microsoft.com/en-us/azure/devops/organizations/security/allow-list-ip-url?view=azure-devops&tabs=IP-V4#allowed-domain-urls
      name = "AzureDevOps"
      protocols {
        port = "443"
        type = "Https"
      }
      destination_fqdns = [
        "dev.azure.com",
        "*.dev.azure.com",
        "vsrm.dev.azure.com",
        "download.agent.dev.azure.com",
        "cdn.vsassets.io",
        "*.vsassets.io",
        "*.gallerycdn.vsassets.io",
        # Auth & Azure control plane commonly hit by ADO sign-in/licensing
        "login.microsoftonline.com",
        "management.azure.com",
        "management.core.windows.net",
        "static2.sharepointonline.com",
        "*.vssps.visualstudio.com",
        "*.vsblob.visualstudio.com",
        "*.vssps.visualstudio.com",
        "*.vstmr.visualstudio.com",
        "aexprodea1.vsaex.visualstudio.com",
        "*.vstmrblob.vsassets.io",
        "visualstudio.com",
        "aadcdn.msauth.net",
        "amcdn.msftauth.net",
        "azurecomcdn.azureedge.net",
        # Needed for non-Entra login
        "login.live.com",
        "logincdn.msauth.net",
        "js.monitor.azure.com",
      ]
      source_addresses = data.azurerm_subnet.services.address_prefixes
    }
  }

  network_rule_collection {
    name     = "net-allow-inbound-from-azuredevops"
    priority = 300
    action   = "Allow"

    # Example: allow ADO service hooks/audit to reach your listener(s) over HTTPS
    rule {
      name                  = "ado-callbacks-https"
      protocols             = ["TCP"]
      source_ip_groups      = [azurerm_ip_group.ado_inbound.id]
      destination_addresses = data.azurerm_subnet.services.address_prefixes
      destination_ports     = ["443"]
    }
  }
}
