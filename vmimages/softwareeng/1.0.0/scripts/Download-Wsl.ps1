$ErrorActionPreference='Stop'

Write-Output "Starting Wsl installation script"

# Import the SoftwareInstaller module
# Try to import from installed location first, then fallback to local
try {
    Import-Module SoftwareInstaller -ErrorAction Stop
} catch {
    Write-Warning "Wsl installation path-based local module instead of installed version"
    Import-Module -Name "$PSScriptRoot\SoftwareInstaller\SoftwareInstaller.psm1" -Force
}

$wslFileName = "wsl.2.5.10.0.x64.msi"
$StorageBlobPrefix = $env:SOFTWARE_STORAGE_PREFIX
$wslStorageBlobUrl = "${StorageBlobPrefix}softwareeng/${wslFileName}"
$SetupPath = 'C:\Setup'
$wslInstallerPath = Join-Path -Path $SetupPath -ChildPath $wslFileName


# Download WSL Installer using the module
try {

    $managedIdentityClientId = $env:MANAGED_IDENTITY_CLIENT_ID

    Write-Host "Using Managed Identity $managedIdentityClientId to download $wslStorageBlobUrl"
    $accessToken = Get-StorageAccessToken -ManagedIdentityClientId $managedIdentityClientId
    # Download software
    $downloadLocation = Download-SoftwareFromStorage -StorageBlobUrl $wslStorageBlobUrl -AccessToken $accessToken -DestinationPath $wslInstallerPath

    Write-Host "WSL Upgrade downloaded to $downloadLocation"
    Write-Host "Creating Log Directory"

    New-Item -ItemType Directory -Force -Path C:\Build\Logs | Out-Null
}
catch {
    Write-Error "Failed to install WSL: $($_.Exception.Message)"
    exit 1
}
