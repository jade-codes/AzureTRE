data "azurerm_subscription" "current" {
}

# resource "azurerm_resource_group" "build_resource_group" {
#   name     = local.software_eng_resource_group_name
#   location = var.location
#   tags     = var.tre_core_tags
# }

data "azurerm_resource_group" "software_eng" {
  name = var.resource_group_name
}

data "azurerm_shared_image_gallery" "vmi_gallery" {
  name                = local.shared_image_gallery_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_shared_image" "softwareengvmi" {
  name                = "softwareengvmi"
  gallery_name        = data.azurerm_shared_image_gallery.vmi_gallery.name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Windows"
  hyper_v_generation  = "V2"

  identifier {
    publisher = "MSTest"
    offer     = "SEE"
    sku       = "EngineeringSoftwareDevVmImage"
  }
}

data "azurerm_storage_account" "software" {
  name                = local.software_storage_account_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_definition" "software_eng" {
  name        = "AzureSoftwareEngRole-${var.tre_id}"
  scope       = data.azurerm_subscription.current.id
  description = "Defines allowed actions for Azure VM Image Builder to create resources it requires to build Images in the given subscription."
  assignable_scopes = [
    data.azurerm_subscription.current.id
  ]
  permissions {
    actions = [
      "Microsoft.Compute/galleries/read",
      "Microsoft.Compute/galleries/images/read",
      "Microsoft.Compute/galleries/images/versions/read",
      "Microsoft.Compute/galleries/images/versions/write",
      "Microsoft.Compute/images/write",
      "Microsoft.Compute/images/read",
      "Microsoft.Compute/images/delete",
      "Microsoft.Compute/virtualMachines/write",
      "Microsoft.ManagedIdentity/userAssignedIdentities/assign/action",
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/subnets/read",
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/virtualNetworks/subnets/write"
    ]
  }
}

# Identity for the Image Builder
resource "azurerm_user_assigned_identity" "software_eng" {
  name                = local.software_eng_identity_name
  location            = var.location
  resource_group_name = var.resource_group_name
  depends_on          = [azurerm_role_definition.software_eng]
}


# Assignment to allow the Image Builder to create resources in the subscription - it needs to be able to create a VM that will be generalised.
resource "azurerm_role_assignment" "software_eng" {
  scope                = data.azurerm_subscription.current.id
  principal_id         = azurerm_user_assigned_identity.software_eng.principal_id
  role_definition_name = azurerm_role_definition.software_eng.name
  depends_on           = [azurerm_role_definition.software_eng]
}

#
# Azure Image Builder Virtual Machine identity related resources
#

# Identity for the VM that gets created to run the customisation script
resource "azurerm_user_assigned_identity" "software_engvm" {
  name                = local.software_eng_vm_identity_name
  location            = var.location
  resource_group_name = var.resource_group_name
}


# Assignment to allow the VM profile customisation script to download from the 'software' storage account
resource "azurerm_role_assignment" "software" {
  scope                = data.azurerm_storage_account.software.id
  principal_id         = azurerm_user_assigned_identity.software_engvm.principal_id
  role_definition_name = "Storage Blob Data Reader"
}

data "azurerm_subnet" "vmbuilder" {
  name                 = local.builder_subnet_name
  virtual_network_name = local.builder_vnet_name
  resource_group_name  = var.resource_group_name
}

resource "null_resource" "always_run" {
  triggers = {
    timestamp = "${timestamp()}"
  }
}

resource "azapi_resource" "softwareengwin" {
  type      = "Microsoft.VirtualMachineImages/imageTemplates@2024-02-01"
  name      = local.software_eng_win_template_name
  location  = data.azurerm_resource_group.software_eng.location
  tags      = var.tre_core_tags
  parent_id = data.azurerm_resource_group.software_eng.id

  identity {
    type = "UserAssigned"
    identity_ids = [
      "${azurerm_user_assigned_identity.software_eng.id}"
    ]
  }

  body = {
    properties = {
      autoRun = {
        state = "Enabled"
      }
      buildTimeoutInMinutes = 480
      vmProfile = {
        osDiskSizeGB           = 128
        userAssignedIdentities = [azurerm_user_assigned_identity.software_engvm.id]
        vmSize                 = "Standard_D8s_v3"
        vnetConfig = {
          subnetId = data.azurerm_subnet.vmbuilder.id
        }
      }
      source = {
        type      = "PlatformImage"
        offer     = "Windows-11"
        publisher = "MicrosoftWindowsDesktop"
        sku       = "win11-24h2-pro"
        version   = "latest"
      }
      errorHandling = {
        onCustomizerError = "cleanup"
        onValidationError = "cleanup"
      }
      customize = [
        {
          type        = "PowerShell"
          name        = "Set environment variables"
          runElevated = true
          runAsSystem = true
          inline = [
            "[System.Environment]::SetEnvironmentVariable('MANAGED_IDENTITY_CLIENT_ID','${azurerm_user_assigned_identity.software_engvm.client_id}', 'Machine')",
            "[System.Environment]::SetEnvironmentVariable('SOFTWARE_STORAGE_PREFIX','${local.software_storage_url_prefix}', 'Machine')"
          ]
        },
        {
          type        = "PowerShell"
          name        = "CreateSoftwareInstallerModule"
          runElevated = true
          runAsSystem = true
          inline      = split("\n", file("${path.module}/scripts/Create-SoftwareInstallerModule.ps1"))
        },
        {
          type        = "PowerShell"
          name        = "DownloadWSL"
          runElevated = true
          runAsSystem = true
          inline      = split("\n", file("${path.module}/scripts/Download-Wsl.ps1"))
        },
        {
          type        = "PowerShell"
          name        = "EnableWSLFeatures"
          runElevated = true
          runAsSystem = true
          inline      = split("\n", file("${path.module}/scripts/Enable-WSLFeatures.ps1"))
        },
        {
          type                = "WindowsRestart"
          name                = "RebootAfterFeatures"
          restartCheckCommand = "powershell -NoProfile -Command \"exit 0\"",
          restartTimeout      = "30m"
        },
        {
          type        = "PowerShell"
          name        = "InstallWSLKernelMSI"
          runElevated = true
          runAsSystem = true
          inline      = split("\n", file("${path.module}/scripts/Install-WSLKernelMSI.ps1"))
        },
        {
          type                = "WindowsRestart"
          name                = "RebootAfterWsl"
          restartCheckCommand = "powershell -NoProfile -Command \"exit 0\"",
          restartTimeout      = "30m"
        },
        {
          type        = "PowerShell"
          name        = "InstallPodman"
          runElevated = true
          runAsSystem = true
          inline      = split("\n", file("${path.module}/scripts/Install-Podman.ps1"))
        },
        # Podman machine will be configured by the user (via a batch file on the desktop)
        {
          type        = "PowerShell"
          name        = "InstallVSCode"
          runElevated = true
          runAsSystem = true
          inline      = split("\n", file("${path.module}/scripts/Install-VSCode.ps1"))
        },
        {
          type        = "PowerShell"
          name        = "InstallGit"
          runElevated = true
          runAsSystem = true
          inline      = split("\n", file("${path.module}/scripts/Install-Git.ps1"))
        },
        {
          type        = "PowerShell"
          name        = "InstallPython"
          runElevated = true
          runAsSystem = true
          inline      = split("\n", file("${path.module}/scripts/Install-Python.ps1"))
        },
        {
          type        = "PowerShell"
          name        = "AddVSCodeExtensions"
          runElevated = true
          runAsSystem = true
          inline      = split("\n", file("${path.module}/scripts/Add-VSCodeExtensions.ps1"))
        },
        {
          type        = "PowerShell"
          name        = "PrepareGitIdentitySetup"
          runElevated = true
          runAsSystem = true
          inline      = split("\n", file("${path.module}/scripts/Prepare-GitIdentitySetup.ps1"))
        },
        {
          type        = "PowerShell"
          name        = "PreparePodmanSetup"
          runElevated = true
          runAsSystem = true
          inline      = split("\n", file("${path.module}/scripts/Prepare-PodmanSetup.ps1"))
        }
      ]

      distribute = [{
        type               = "SharedImage"
        runOutputName      = "SharedImageOutput"
        galleryImageId     = azurerm_shared_image.softwareengvmi.id
        replicationRegions = ["uksouth"]
      }]
    }
  }
  depends_on = [
    azurerm_user_assigned_identity.software_eng,
    azurerm_role_assignment.software_eng,
    azurerm_role_assignment.software
  ]

  lifecycle {
    replace_triggered_by = [
      null_resource.always_run
    ]
  }
}
