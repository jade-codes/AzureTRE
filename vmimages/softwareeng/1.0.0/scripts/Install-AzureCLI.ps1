# Import the SoftwareInstaller module
# Try to import from installed location first, then fallback to local
try {
    Import-Module SoftwareInstaller -ErrorAction Stop
} catch {
    Import-Module -Name "$PSScriptRoot\SoftwareInstaller\SoftwareInstaller.psm1" -Force
}

# Define installation parameters
$installerName = "azure-cli.msi"
$setupPath = 'C:\Setup'
$installerPath = Join-Path -Path $setupPath -ChildPath $installerName
$softwareName = "Azure CLI"
$storageBlobPrefix = $env:SOFTWARE_STORAGE_PREFIX
$storageBlobUrl = "${storageBlobPrefix}softwareeng/${installerName}"


# Download Azure CLI using the module
try {
    $managedIdentityClientId = $env:MANAGED_IDENTITY_CLIENT_ID

    Write-Host "Using Managed Identity $managedIdentityClientId to download $storageBlobUrl"
    $accessToken = Get-StorageAccessToken -ManagedIdentityClientId $managedIdentityClientId
    # Download software
    $downloadLocation = Download-SoftwareFromStorage -StorageBlobUrl $storageBlobUrl -AccessToken $accessToken -DestinationPath $installerPath

    Write-Host "Azure CLI downloaded to $downloadLocation"
    Write-Host "Creating Log Directory"

    New-Item -ItemType Directory -Force -Path C:\Build\Logs | Out-Null

    Write-Host "Installing Azure CLI"

    if (-not (Test-Path $installerPath)) { throw "MSI not found at $installerPath" }

    Start-Process -FilePath 'msiexec.exe' -ArgumentList "/I $installerPath /quiet /norestart /l* C:\Build\Logs\azure-cli-installation.log" -Wait -PassThru -WindowStyle Hidden

    Write-Host "Azure CLI installation completed successfully."
}
catch {
    Write-Error "Failed to install Azure CLI: $($_.Exception.Message)"
    exit 1
}
