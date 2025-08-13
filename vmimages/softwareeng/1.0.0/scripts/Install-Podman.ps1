Write-Host "Starting Podman installation script"

# Import the SoftwareInstaller module
# Try to import from installed location first, then fallback to local
try {
    Import-Module SoftwareInstaller -ErrorAction Stop
} catch {
    Write-Warning "Podman installation path-based local module instead of installed version"
    Import-Module -Name "$PSScriptRoot\SoftwareInstaller\SoftwareInstaller.psm1" -Force
}

# Define installation parameters
$installerName = "podman_installer.exe"
$installArguments = "/S"
$softwareName = "Podman"

$wslFileName = "5.3-rootfs-amd64.tar.zst"
$StorageBlobPrefix = $env:SOFTWARE_STORAGE_PREFIX
$wslStorageBlobUrl = "${StorageBlobPrefix}softwareeng/${wslFileName}"
$SetupPath = 'C:\Setup'
$wslInstallerPath = Join-Path -Path $SetupPath -ChildPath $wslFileName


# Install Podman using the module
try {

    $managedIdentityClientId = $env:MANAGED_IDENTITY_CLIENT_ID

    Write-Host "Using Managed Identity $managedIdentityClientId to download $wslStorageBlobUrl"
    $accessToken = Get-StorageAccessToken -ManagedIdentityClientId $managedIdentityClientId
    # Download software
    $downloadLocation = Download-SoftwareFromStorage -StorageBlobUrl $wslStorageBlobUrl -AccessToken $accessToken -DestinationPath $wslInstallerPath

    Write-Host "Podman WSL Distro downloaded to $downloadLocation"
    Write-Host "Installing Podman"

    $exitCode = Install-SoftwareFromStorage -InstallerName $installerName -InstallArguments $installArguments -SoftwareName $softwareName

    if ($exitCode -eq 0) {
        Write-Host "Podman installation completed successfully."
    } else {
        Write-Warning "Podman installation completed with exit code: $exitCode"
        exit $exitCode
    }
}
catch {
    Write-Error "Failed to install Podman: $($_.Exception.Message)"
    exit 1
}
