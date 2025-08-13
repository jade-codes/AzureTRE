# SoftwareInstaller PowerShell Module
# This module provides functions to download and install software from Azure Storage Account
# Author: Azure TRE Team
# Version: 1.0.0

#Requires -Version 5.1

# Module initialization
Write-Verbose "Loading SoftwareInstaller module..."

# Define module-level variables
$script:ModuleVersion = '1.0.0'
$script:DefaultSetupPath = 'C:\Setup'
$script:DefaultStorageApiVersion = '2017-11-09'

# Helper function for module logging
function Write-ModuleLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [SoftwareInstaller] [$Level] $Message"

    switch ($Level) {
        'Info' { Write-Host $logMessage -ForegroundColor Cyan }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
    }
}

function Get-StorageAccessToken {
    <#
    .SYNOPSIS
    Gets an access token for Azure Storage using managed identity.

    .DESCRIPTION
    Retrieves an OAuth2 access token from the Azure Instance Metadata Service (IMDS)
    using the managed identity assigned to the VM.

    .PARAMETER ManagedIdentityClientId
    The client ID of the managed identity to use for authentication.

    .EXAMPLE
    $token = Get-StorageAccessToken -ManagedIdentityClientId "12345678-1234-1234-1234-123456789012"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManagedIdentityClientId
    )

    try {
        Write-ModuleLog "Obtaining access token using managed identity: $ManagedIdentityClientId"

        $uri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&client_id=$ManagedIdentityClientId&resource=https%3A%2F%2Fstorage.azure.com%2F"
        $response = Invoke-WebRequest -Uri $uri -Method GET -Headers @{Metadata = "true" } -UseBasicParsing
        $content = $response.Content | ConvertFrom-Json

        Write-ModuleLog "Access token obtained successfully" -Level Success
        return $content.access_token
    }
    catch {
        Write-ModuleLog "Failed to obtain access token: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Download-SoftwareFromStorage {
    <#
    .SYNOPSIS
    Downloads software from Azure Storage Account.

    .DESCRIPTION
    Downloads a file from Azure Storage Account using an access token and saves it to a local path.

    .PARAMETER StorageBlobUrl
    The full URL to the blob in Azure Storage.

    .PARAMETER AccessToken
    The access token for Azure Storage authentication.

    .PARAMETER DestinationPath
    The local path where the file should be saved.

    .EXAMPLE
    Download-SoftwareFromStorage -StorageBlobUrl "https://storage.blob.core.windows.net/container/file.exe" -AccessToken $token -DestinationPath "C:\Setup\file.exe"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$StorageBlobUrl,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    try {
        # Ensure destination directory exists
        $destinationDir = Split-Path -Path $DestinationPath -Parent
        if (-not (Test-Path -Path $destinationDir)) {
            New-Item -ItemType Directory -Force -Path $destinationDir | Out-Null
            Write-ModuleLog "Created directory: $destinationDir"
        }

        Write-ModuleLog "Downloading from '$StorageBlobUrl' to '$DestinationPath' - StartTime: $(Get-Date)"

        $elapsedTime = Measure-Command {
            $wc = New-Object System.Net.WebClient
            $wc.Headers['Authorization'] = "Bearer $AccessToken"
            $wc.Headers['x-ms-version'] = $script:DefaultStorageApiVersion
            $wc.DownloadFile($StorageBlobUrl, $DestinationPath)
        }

        Write-ModuleLog "Download complete in $($elapsedTime.TotalSeconds) seconds - EndTime: $(Get-Date)" -Level Success

        # Verify file was downloaded
        if (-not (Test-Path -Path $DestinationPath)) {
            throw "File was not downloaded successfully"
        }

        $fileInfo = Get-Item -Path $DestinationPath
        Write-ModuleLog "Downloaded file size: $($fileInfo.Length) bytes"

        return $DestinationPath
    }
    catch {
        Write-ModuleLog "Failed to download software: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Install-Software {
    <#
    .SYNOPSIS
    Installs software using the specified installer and arguments.

    .DESCRIPTION
    Executes a software installer with the provided arguments and waits for completion.

    .PARAMETER InstallerPath
    The path to the software installer executable.

    .PARAMETER InstallArguments
    The command-line arguments to pass to the installer.

    .PARAMETER SoftwareName
    The name of the software being installed (for logging purposes).

    .EXAMPLE
    Install-Software -InstallerPath "C:\Setup\installer.exe" -InstallArguments "/silent" -SoftwareName "My Software"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InstallerPath,

        [Parameter(Mandatory = $true)]
        [string]$InstallArguments,

        [Parameter(Mandatory = $true)]
        [string]$SoftwareName
    )

    try {
        # Verify installer exists
        if (-not (Test-Path -Path $InstallerPath)) {
            throw "Installer not found at path: $InstallerPath"
        }

        Write-ModuleLog "Installing $SoftwareName..."
        Write-ModuleLog "Installer: $InstallerPath"
        Write-ModuleLog "Arguments: $InstallArguments"

        $startTime = Get-Date
        $process = Start-Process -FilePath $InstallerPath -ArgumentList $InstallArguments -Wait -PassThru
        $endTime = Get-Date
        $duration = $endTime - $startTime

        Write-ModuleLog "Installation process completed in $($duration.TotalSeconds) seconds"
        Write-ModuleLog "Exit code: $($process.ExitCode)"

        if ($process.ExitCode -eq 0) {
            Write-ModuleLog "$SoftwareName installation completed successfully" -Level Success
        }
        else {
            Write-ModuleLog "$SoftwareName installation completed with exit code: $($process.ExitCode)" -Level Warning
        }

        return $process.ExitCode
    }
    catch {
        Write-ModuleLog "Failed to install $SoftwareName: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Install-SoftwareFromStorage {
    <#
    .SYNOPSIS
    Downloads and installs software from Azure Storage Account.

    .DESCRIPTION
    This is a convenience function that combines downloading software from Azure Storage
    and installing it with the specified arguments.

    .PARAMETER InstallerName
    The name of the installer file in the storage account (e.g., "vscode_installer.exe").

    .PARAMETER InstallArguments
    The command-line arguments to pass to the installer.

    .PARAMETER SoftwareName
    The name of the software being installed (for logging purposes).

    .PARAMETER StorageBlobPrefix
    The prefix URL for the storage blob (e.g., "https://storage.blob.core.windows.net/container").

    .PARAMETER ManagedIdentityClientId
    The client ID of the managed identity to use for authentication.

    .PARAMETER SetupPath
    The local directory where the installer should be downloaded. Defaults to "C:\Setup".

    .EXAMPLE
    Install-SoftwareFromStorage -InstallerName "vscode_installer.exe" -InstallArguments "/verysilent /mergetasks=!runcode" -SoftwareName "Visual Studio Code" -StorageBlobPrefix $env:SOFTWARE_STORAGE_PREFIX -ManagedIdentityClientId $env:MANAGED_IDENTITY_CLIENT_ID
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InstallerName,

        [Parameter(Mandatory = $true)]
        [string]$InstallArguments,

        [Parameter(Mandatory = $true)]
        [string]$SoftwareName,

        [Parameter(Mandatory = $false)]
        [string]$StorageBlobPrefix = $env:SOFTWARE_STORAGE_PREFIX,

        [Parameter(Mandatory = $false)]
        [string]$ManagedIdentityClientId = $env:MANAGED_IDENTITY_CLIENT_ID,

        [Parameter(Mandatory = $false)]
        [string]$SetupPath = $script:DefaultSetupPath
    )

    try {
        Write-ModuleLog "=========================================="
        Write-ModuleLog "Installing $SoftwareName"
        Write-ModuleLog "=========================================="

        # Validate required parameters
        if ([string]::IsNullOrEmpty($StorageBlobPrefix)) {
            throw "StorageBlobPrefix is required. Please provide it as a parameter or set the SOFTWARE_STORAGE_PREFIX environment variable."
        }

        if ([string]::IsNullOrEmpty($ManagedIdentityClientId)) {
            throw "ManagedIdentityClientId is required. Please provide it as a parameter or set the MANAGED_IDENTITY_CLIENT_ID environment variable."
        }

        # Construct storage blob URL
        $storageBlobUrl = "$StorageBlobPrefix/softwareeng/$InstallerName"
        $installerPath = Join-Path -Path $SetupPath -ChildPath $InstallerName

        Write-ModuleLog "Storage Blob URL: $storageBlobUrl"
        Write-ModuleLog "Local Installer Path: $installerPath"

        # Get access token
        $accessToken = Get-StorageAccessToken -ManagedIdentityClientId $ManagedIdentityClientId

        # Download software
        Download-SoftwareFromStorage -StorageBlobUrl $storageBlobUrl -AccessToken $accessToken -DestinationPath $installerPath

        # Install software
        $exitCode = Install-Software -InstallerPath $installerPath -InstallArguments $InstallArguments -SoftwareName $SoftwareName

        Write-ModuleLog "=========================================="
        Write-ModuleLog "$SoftwareName installation process completed"
        Write-ModuleLog "=========================================="

        return $exitCode
    }
    catch {
        Write-ModuleLog "Failed to install $SoftwareName from storage: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Get-ModuleVersion {
    <#
    .SYNOPSIS
    Gets the version of the SoftwareInstaller module.

    .DESCRIPTION
    Returns the current version of the SoftwareInstaller module.

    .EXAMPLE
    Get-ModuleVersion
    #>
    [CmdletBinding()]
    param()

    return $script:ModuleVersion
}

function Test-ModulePrerequisites {
    <#
    .SYNOPSIS
    Tests if the module prerequisites are met.

    .DESCRIPTION
    Checks if the current environment supports the module functionality,
    including PowerShell version, network connectivity, and required cmdlets.

    .EXAMPLE
    Test-ModulePrerequisites
    #>
    [CmdletBinding()]
    param()

    $results = @{
        PowerShellVersion = $true
        NetworkConnectivity = $true
        RequiredCmdlets = $true
        OverallStatus = $true
        Issues = @()
    }

    try {
        # Check PowerShell version
        if ($PSVersionTable.PSVersion.Major -lt 5) {
            $results.PowerShellVersion = $false
            $results.OverallStatus = $false
            $results.Issues += "PowerShell version 5.1 or higher is required. Current version: $($PSVersionTable.PSVersion)"
        }

        # Check network connectivity to Azure IMDS
        try {
            $testUri = "http://169.254.169.254/metadata/instance?api-version=2021-02-01"
            $response = Invoke-WebRequest -Uri $testUri -Method GET -Headers @{Metadata = "true"} -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
            Write-ModuleLog "Network connectivity to Azure IMDS: OK"
        }
        catch {
            $results.NetworkConnectivity = $false
            $results.OverallStatus = $false
            $results.Issues += "Cannot connect to Azure Instance Metadata Service (IMDS). This module requires running on an Azure VM."
        }

        # Check required cmdlets
        $requiredCmdlets = @('Invoke-WebRequest', 'Start-Process', 'Test-Path', 'New-Item')
        foreach ($cmdlet in $requiredCmdlets) {
            if (-not (Get-Command $cmdlet -ErrorAction SilentlyContinue)) {
                $results.RequiredCmdlets = $false
                $results.OverallStatus = $false
                $results.Issues += "Required cmdlet '$cmdlet' is not available."
            }
        }

        if ($results.OverallStatus) {
            Write-ModuleLog "All module prerequisites are met" -Level Success
        } else {
            Write-ModuleLog "Some module prerequisites are not met:" -Level Warning
            foreach ($issue in $results.Issues) {
                Write-ModuleLog "  - $issue" -Level Warning
            }
        }

        return $results
    }
    catch {
        Write-ModuleLog "Error checking module prerequisites: $($_.Exception.Message)" -Level Error
        $results.OverallStatus = $false
        $results.Issues += "Error during prerequisite check: $($_.Exception.Message)"
        return $results
    }
}

# Module cleanup function
function Remove-ModuleArtifacts {
    <#
    .SYNOPSIS
    Cleans up temporary artifacts created by the module.

    .DESCRIPTION
    Removes temporary files and directories created during software installation.

    .PARAMETER SetupPath
    The setup path to clean up. Defaults to the module's default setup path.

    .PARAMETER Force
    Force removal without confirmation.

    .EXAMPLE
    Remove-ModuleArtifacts -Force
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [string]$SetupPath = $script:DefaultSetupPath,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    try {
        if (Test-Path -Path $SetupPath) {
            if ($Force -or $PSCmdlet.ShouldProcess("$SetupPath", "Remove directory and contents")) {
                Remove-Item -Path $SetupPath -Recurse -Force
                Write-ModuleLog "Cleaned up setup directory: $SetupPath" -Level Success
            }
        } else {
            Write-ModuleLog "Setup directory does not exist: $SetupPath"
        }
    }
    catch {
        Write-ModuleLog "Error cleaning up module artifacts: $($_.Exception.Message)" -Level Error
        throw
    }
}

# Export module functions
Export-ModuleMember -Function Get-StorageAccessToken, Download-SoftwareFromStorage, Install-Software, Install-SoftwareFromStorage, Get-ModuleVersion, Test-ModulePrerequisites, Remove-ModuleArtifacts

# Module initialization message
Write-ModuleLog "SoftwareInstaller module v$script:ModuleVersion loaded successfully" -Level Success
