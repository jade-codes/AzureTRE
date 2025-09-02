resource "azurerm_firewall_policy_rule_collection_group" "core" {
  name               = "rcg-core"
  firewall_policy_id = azurerm_firewall_policy.root.id
  priority           = 500

  network_rule_collection {
    name     = "nrc-general"
    priority = 201
    action   = "Allow"

    rule {
      name = "time"
      protocols = [
        "UDP"
      ]
      destination_addresses = [
        "*"
      ]
      destination_ports = [
        "123"
      ]
      source_addresses = [
        "*"
      ]
    }
  }

  network_rule_collection {
    name     = "nrc-resource-processor-subnet"
    priority = 202
    action   = "Allow"

    rule {
      name = "azure-services"
      protocols = [
        "TCP"
      ]
      destination_addresses = [
        "AzureActiveDirectory",
        "AzureResourceManager",

        // Needed when a workspace key vault is created before its private endpoint
        "AzureKeyVault.${var.location}"
      ]
      destination_ports = [
        "443"
      ]
      source_ip_groups = [var.resource_processor_ip_group_id]
    }
  }

  network_rule_collection {
    name     = "nrc-web-app-subnet"
    priority = 203
    action   = "Allow"

    rule {
      name = "azure-services"
      protocols = [
        "TCP"
      ]
      destination_addresses = [
        "AzureActiveDirectory",
        "AzureResourceManager"
      ]
      destination_ports = [
        "443"
      ]
      source_ip_groups = [var.web_app_ip_group_id]
    }
  }

  application_rule_collection {
    name     = "arc-resource-processor-subnet"
    priority = 301
    action   = "Allow"

    rule {
      name = "os-package-sources"
      protocols {
        port = "443"
        type = "Https"
      }
      protocols {
        port = "80"
        type = "Http"
      }
      destination_fqdns = [
        "packages.microsoft.com",
        "keyserver.ubuntu.com",
        "api.snapcraft.io",
        "azure.archive.ubuntu.com",
        "security.ubuntu.com",
        "entropy.ubuntu.com",
      ]
      source_ip_groups = [var.resource_processor_ip_group_id]
    }

    rule {
      name = "docker-sources"
      protocols {
        port = "443"
        type = "Https"
      }
      protocols {
        port = "80"
        type = "Http"
      }
      destination_fqdns = [
        "download.docker.com",
        "registry-1.docker.io",
        "auth.docker.io",
      ]
      source_ip_groups = [var.resource_processor_ip_group_id]
    }
    # This rule is needed to support Gov Cloud.
    # The az cli uses msal lib which requires access to this fqdn for authentication.
    rule {
      name = "microsoft-login"
      protocols {
        port = "443"
        type = "Https"
      }
      destination_fqdns = [
        "login.microsoftonline.com",
      ]
      source_ip_groups = [var.resource_processor_ip_group_id]
    }


  }

  application_rule_collection {
    name     = "arc-shared-subnet"
    priority = 302
    action   = "Allow"

    rule {
      name = "nexus-bootstrap"
      protocols {
        port = "443"
        type = "Https"
      }
      protocols {
        port = "80"
        type = "Http"
      }
      destination_fqdns = [
        "keyserver.ubuntu.com",
        "packages.microsoft.com",
        "download.docker.com",
        "azure.archive.ubuntu.com"
      ]
      source_ip_groups = [var.shared_services_ip_group_id]
    }
  }

  application_rule_collection {
    name     = "arc-web-app-subnet"
    priority = 303
    action   = "Allow"

    rule {
      name = "microsoft-graph"
      protocols {
        port = "443"
        type = "Https"
      }
      destination_fqdns = [
        var.microsoft_graph_fqdn
      ]
      source_ip_groups = [var.web_app_ip_group_id]
    }
  }

  application_rule_collection {
    name     = "arc-airlock-processor-subnet"
    priority = 304
    action   = "Allow"

    rule {
      name = "functions-runtime"
      protocols {
        port = "443"
        type = "Https"
      }
      destination_fqdns = [
        "functionscdn.azureedge.net"
      ]
      source_ip_groups = [var.airlock_processor_ip_group_id]
    }
  }

  # AKS workspace service subnet application rules (see https://learn.microsoft.com/en-us/azure/aks/outbound-rules-control-egress)
  # Remove/reduce this rule collection once management ACR has the required images
  application_rule_collection {
    name     = "arc-aks-services-subnet"
    priority = 305
    action   = "Allow"

    # Required AKS FQDNs for control plane, registry, updates, monitoring, etc.
    rule {
      name = "aks-required-fqdns"
      protocols {
        port = "443"
        type = "Https"
      }
      destination_fqdns = [
        # Node <-> API server communication
        "*.hcp.${var.location}.azmk8s.io",
        # Microsoft Container Registry
        "mcr.microsoft.com",
        "*.data.mcr.microsoft.com",
        # Azure API operations
        "management.azure.com",
        # Microsoft Entra authentication
        "login.microsoftonline.com",
        # OS package sources
        "packages.microsoft.com",
        # Required binaries
        "acs-mirror.azureedge.net",
        "packages.aks.azure.com",
        # Monitoring endpoints
        "*.ods.opinsights.azure.com",
        "*.oms.opinsights.azure.com",
        "dc.services.visualstudio.com",
        "*.in.applicationinsights.azure.com",
        "*.monitoring.azure.com",
        "global.handler.control.monitor.azure.com",
        "*.ingest.monitor.azure.com",
        "*.metrics.ingest.monitor.azure.com",
        # Policy endpoints
        "data.policy.core.windows.net",
        "store.policy.core.windows.net",
        # Docker
        "registry-1.docker.io",
        "auth.docker.io",
        "production.cloudflare.docker.com",
        "sonatype.github.io",
        "dl.gitea.io",
        "docker.gitea.com",
        "gitea-pull-through-cache.4d3e0f26919f429c2b0092fb846c818a.r2.cloudflarestorage.com",
        "repo1.maven.org",
        "registry.npmjs.org",
        "pypi.org",
        "files.pythonhosted.org",
        "*.ubuntu.com",
        "*.jenkins.io",
        "contracts.canonical.com",
        "api.nuget.org",
        "raw.githubusercontent.com",
        "clm.sonatype.com",
        "checkpoint-api.hashicorp.com",
        # AI Enablement - Hugging Face
        "public.ecr.aws",
        "d2glxqk2uabbnd.cloudfront.net",
        "huggingface.co",
        "cas-server.xethub.hf.co",
        "transfer.xethub.hf.co"
      ]
      source_addresses = ["*"]
    }

    # Optional recommended FQDNs for OS updates
    rule {
      name = "aks-optional-os-updates"
      protocols {
        port = "443"
        type = "Https"
      }
      protocols {
        port = "80"
        type = "Http"
      }
      destination_fqdns = [
        "security.ubuntu.com",
        "azure.archive.ubuntu.com",
        "changelogs.ubuntu.com",
        "snapshot.ubuntu.com"
      ]
      source_addresses = ["*"]
    }


  }

  application_rule_collection {
    name     = "arc-vm-image-build-subnet"
    priority = 310
    action   = "Allow"

    # Required FQDNs for building images.
    rule {
      name = "vm-image-build-required-fqdns"
      protocols {
        port = "443"
        type = "Https"
      }
      destination_fqdns = [
        "msedge.api.cdp.microsoft.com",
        "config.edge.skype.com",
        "www.msftconnecttest.com",
        "ecs.office.com",
        "www.msftncsi.com",
        "mobile.events.data.microsoft.com",
        "ctldl.windowsupdate.com",
        "wdcp.microsoft.com",
        "wdcpalt.microsoft.com",

        "login.live.com",
        "settings-win.data.microsoft.com",
        "fs.microsoft.com",
        "slscr.update.microsoft.com",
        "*.blob.core.windows.net",
        "agentserviceapi.guestconfiguration.azure.com",
        "marketplace.visualstudio.com",
        "licensing.mp.microsoft.com",
        "geo.prod.do.dsp.mp.microsoft.com",
        "watson.events.data.microsoft.com",
        "uksouth-gas.guestconfiguration.azure.com",
        "www.vscode-unpkg.net",
        "api.github.com",
        "*.vsassets.io"
      ]
      source_addresses = [var.vm_image_build_subnet_address_range]
    }
  }

  depends_on = [
    azurerm_firewall.fw
  ]
}
