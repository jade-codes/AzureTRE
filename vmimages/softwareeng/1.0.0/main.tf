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
  type      = "Microsoft.VirtualMachineImages/imageTemplates@2022-07-01"
  name      = local.software_eng_win_template_name
  location  = data.azurerm_resource_group.software_eng.location
  tags      = var.tre_core_tags
  parent_id = data.azurerm_resource_group.software_eng.id

  body = jsonencode({
    identity = {
      type = "UserAssigned"
      userAssignedIdentities = {
        "${azurerm_user_assigned_identity.software_eng.id}" = {}
      }
    }
    properties = {
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
      customize = [
        {
          type        = "PowerShell"
          name        = "Set environment variables"
          runElevated = true
          runAsSystem = true
          inline = [
            "[System.Environment]::SetEnvironmentVariable('MANAGED_IDENTITY_CLIENT_ID','${azurerm_user_assigned_identity.software_engvm.client_id}', 'Machine')",
          "[System.Environment]::SetEnvironmentVariable('SOFTWARE_STORAGE_PREFIX','${local.software_storage_url_prefix}', 'Machine')", ]
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
          name        = "EnableWSLFeatures"
          runElevated = true
          runAsSystem = true
          inline = [
            "Write-Host 'Enabling WSL and Virtual Machine Platform features...'",
            "Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart",
            "Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart",
            "Write-Host 'WSL features enabled. A restart will be required to complete the installation.'"
          ]
        },
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
          type   = "PowerShell"
          name   = "InstallPodman"
          inline = split("\n", file("${path.module}/scripts/Install-Podman.ps1"))
        },
        {
          type           = "WindowsRestart"
          restartTimeout = "5m"
        },
        {
          type        = "PowerShell"
          name        = "PrepareVSCodeForUsers"
          runElevated = true
          runAsSystem = true
          inline = [
            "Write-Host 'Creating install script for users...'",
            "$scriptContent = @'",
            "# VS Code Extensions Auto-Install Script",
            "Write-Host \"Preparing VS Code...\"",
            "try {",
            "    Write-Host \"Install Extensions for DevContainers successfully!\"",
            "    code --install-extension ms-vscode-remote.remote-containers",
            "    code --install-extension ms-azuretools.vscode-docker",
            "    code --install-extension ms-vscode-remote.remote-wsl",
            "    Write-Host \"Extensions installed successfully!\"",
            "    ",
            "    Write-Host \"Configuring VS Code settings for Podman...\"",
            "    $settingsPath = \"$env:APPDATA\\Code\\User\\settings.json\"",
            "    $settingsDir = Split-Path $settingsPath -Parent",
            "    if (!(Test-Path $settingsDir)) { New-Item -ItemType Directory -Path $settingsDir -Force }",
            "    ",
            "    $settings = @{",
            "        \"dev.containers.dockerPath\" = \"podman\"",
            "        \"dev.containers.dockerComposePath\" = \"podman-compose\"",
            "    }",
            "    ",
            "    if (Test-Path $settingsPath) {",
            "        $existingSettings = Get-Content $settingsPath | ConvertFrom-Json",
            "        foreach ($key in $settings.Keys) {",
            "            $existingSettings | Add-Member -MemberType NoteProperty -Name $key -Value $settings[$key] -Force",
            "        }",
            "        $existingSettings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath",
            "    } else {",
            "        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath",
            "    }",
            "    Write-Host \"VS Code configured to use Podman\"",
            "    ",
            "    Write-Host \"Configure WSL!\"",
            "    wsl --update",
            "    Write-Host \"Installing default WSL bits\"",
            "    wsl --install --no-distribution",
            "    Write-Host \"WSL Configured!\"",
            "    Write-Host \"Initialise Podman!\"",
            "    podman machine init --image \"C:\\Setup\\5.3-rootfs-amd64.tar.zst\"",
            "    podman machine set --user-mode-networking --rootful",
            "    podman machine start",
            "    Write-Host \"Podman Configured!\"",
            "    # Remove this script from startup after successful execution",
            "    Remove-Item -Path \"$env:APPDATA\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\Install-VSCode-Extensions.bat\" -ErrorAction SilentlyContinue",
            "} catch {",
            "    Write-Warning \"Extension installation failed: $_\"",
            "}",
            "Read-Host \"Press Enter to close this window\"",
            "'@",
            "$scriptContent | Out-File -FilePath 'C:\\Users\\Public\\Desktop\\Install-VSCode-Extensions.ps1' -Encoding UTF8",
            "Write-Host 'Extension install script created at C:\\Users\\Public\\Desktop\\Install-VSCode-Extensions.ps1'",
            "# Create a batch file that will run the PowerShell script",
            "$batchContent = @'",
            "@echo off",
            "powershell.exe -ExecutionPolicy Bypass -File \"C:\\Users\\Public\\Desktop\\Install-VSCode-Extensions.ps1\"",
            "'@",
            "$batchContent | Out-File -FilePath 'C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\StartUp\\Install-VSCode-Extensions.bat' -Encoding ASCII",
            "Write-Host 'Startup batch file created for automatic execution on first login'"
          ]
        },
        {
          type           = "WindowsRestart"
          restartTimeout = "5m"
        }
      ]

      distribute = [{
        type               = "SharedImage"
        runOutputName      = "SharedImageOutput"
        galleryImageId     = azurerm_shared_image.softwareengvmi.id
        replicationRegions = ["uksouth"]
      }]
    }
  })
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
