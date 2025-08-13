resource "azurerm_firewall_policy_rule_collection_group" "core_airlock_notifier" {
  name               = "rcg-${local.workspace_resource_name_suffix}-software-eng"
  firewall_policy_id = data.azurerm_firewall_policy.core.id
  priority           = 501

  # Updates needed to allow updating of resources on virtual machine
  application_rule_collection {
    name     = "arc-${local.workspace_resource_name_suffix}-software-eng"
    priority = 301
    action   = "Allow"

    rule {
      name = "microsoft-updates"
      protocols {
        port = "443"
        type = "Https"
      }
      protocols {
        port = "80"
        type = "Http"
      }
      destination_fqdns = [
        "config.edge.skype.com",
        "*.microsoft.com",
        "ecs.office.com",
        "*.guestconfiguration.azure.com",
        "ctldl.windowsupdate.com",
        "www.msftconnecttest.com",
        "www.msftncsi.com",
        "arc.msn.com",
        "www.bing.com",
        "clients2.google.com",
        "assets.msn.com",
        "g.live.com",
        "api.github.com",
        "edge-consumer-static.azureedge.net",
        "main.vscode-cdn.net",
        "*.digicert.com",
        "www.vscode-unpkg.net",
        "fp.msedge.net",
        "release-assets.githubusercontent.com",
        "ocsp.sectigo.com",
        "*.comodoca.com",
        "*.usertrust.com",
        "marketplace.visualstudio.com",
        "ms-vscode-remote.gallerycdn.vsassets.io",
        "ms-vscode-remote.gallery.vsassets.io",
        "static.edge.microsoftapp.net",
        "edgeassetservice.azureedge.net"
      ]
      source_addresses = [local.services_subnet_address_prefix]
    }

    # Allow authentication to Azure services
    rule {
      name = "microsoft-login"
      protocols {
        port = "443"
        type = "Https"
      }
      destination_fqdns = [
        "login.microsoftonline.com",
      ]
      source_addresses = [local.services_subnet_address_prefix]
    }


  }
}
