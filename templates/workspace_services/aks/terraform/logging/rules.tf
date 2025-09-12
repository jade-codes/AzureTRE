# Rules found here: https://github.com/microsoft/Docker-Provider/tree/ci_prod/scripts/onboarding/aks/onboarding-msi-terraform-syslog
resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                = "MSCI-${var.location}-${var.aks_cluster_name}"
  resource_group_name = var.resource_group_name
  location            = var.location

  destinations {
    log_analytics {
      workspace_resource_id = data.azurerm_log_analytics_workspace.workspace.id
      name                  = "ciworkspace"
    }
  }

  data_flow {
    streams = [
      "Microsoft-ContainerLog",
      "Microsoft-ContainerLogV2",
      "Microsoft-KubeEvents",
      "Microsoft-KubePodInventory",
      "Microsoft-KubeNodeInventory"
    ]
    destinations = ["ciworkspace"]
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["ciworkspace"]
  }

  data_sources {
    syslog {
      streams        = ["Microsoft-Syslog"]
      facility_names = ["auth", "authpriv", "cron", "daemon", "mark", "kern", "local0", "local1", "local2", "local3", "local4", "local5", "local6", "local7", "lpr", "mail", "news", "syslog", "user", "uucp"]
      log_levels     = ["Debug", "Info", "Notice", "Warning", "Error", "Critical", "Alert", "Emergency"]
      name           = "sysLogsDataSource"
    }

    extension {
      streams = [
        "Microsoft-ContainerLog",
        "Microsoft-ContainerLogV2",
        "Microsoft-KubeEvents",
        "Microsoft-KubePodInventory",
        "Microsoft-KubeNodeInventory"
      ]
      extension_name = "ContainerInsights"
      extension_json = jsonencode({
        "dataCollectionSettings" : {
          "interval" : "1m",
          "namespaceFilteringMode" : "Off",
          "enableContainerLogV2" : true
          "enableMetrics" : false
        }
      })
      name = "ContainerInsightsExtension"
    }
  }

  description = "DCR for Azure Monitor Container Insights"
}

resource "azurerm_monitor_data_collection_rule_association" "ingestion_dcra" {
  name                    = "ContainerInsightsExtension"
  target_resource_id      = data.azurerm_kubernetes_cluster.aks.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id
  description             = "Association of container insights data collection rule. Deleting this association will break the data collection for this AKS Cluster."
}

resource "azurerm_monitor_data_collection_rule_association" "config_dcra" {
  name                        = "configurationAccessEndpoint"
  target_resource_id          = data.azurerm_kubernetes_cluster.aks.id
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce.id
  description                 = "Association of data collection rule endpoint. Deleting this association will break the data collection endpoint for this AKS Cluster."
}
