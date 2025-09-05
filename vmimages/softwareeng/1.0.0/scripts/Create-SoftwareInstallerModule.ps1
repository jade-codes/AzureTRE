<#
 Script to retrieve and install the SoftwareInstaller PowerShell module during VM image build.
 Instead of embedding the module contents, this script downloads the manifest (.psd1) and module (.psm1)
 from an Azure Storage account (private) using a managed identity.

 Required environment variables:
   SOFTWARE_STORAGE_PREFIX   e.g. https://stsftXXXX.blob.core.windows.net/installers/
                              (must end with a trailing / and point to the container root path used during upload)
   MANAGED_IDENTITY_CLIENT_ID  Client ID of the user-assigned managed identity with Storage Blob Data Reader access

 Optional environment variables:
   SOFTWARE_INSTALLER_VERSION  (defaults to 1.0.0)

 The upload script placed files at: softwareeng/SoftwareInstaller/<version>/SoftwareInstaller.psd1 & .psm1
 This script reconstructs a standard PowerShell module folder layout:
   C:\Program Files\WindowsPowerShell\Modules\SoftwareInstaller\<version>\SoftwareInstaller.psd1
   C:\Program Files\WindowsPowerShell\Modules\SoftwareInstaller\<version>\SoftwareInstaller.psm1
#>

Write-Host 'Preparing to download SoftwareInstaller module from Azure Storage...'

$ErrorActionPreference = 'Stop'

# Validate required environment variables
if (-not $env:SOFTWARE_STORAGE_PREFIX) {
    Write-Error 'SOFTWARE_STORAGE_PREFIX environment variable is required (e.g. https://<acct>.blob.core.windows.net/installers/).'
    exit 1
}
if (-not $env:MANAGED_IDENTITY_CLIENT_ID) {
    Write-Error 'MANAGED_IDENTITY_CLIENT_ID environment variable is required.'
    exit 1
}

$moduleVersion = if ($env:SOFTWARE_INSTALLER_VERSION) { $env:SOFTWARE_INSTALLER_VERSION } else { '1.0.0' }
$storagePrefix = $env:SOFTWARE_STORAGE_PREFIX.TrimEnd('/') + '/'
$clientId = $env:MANAGED_IDENTITY_CLIENT_ID

$relativePathRoot = "softwareeng/SoftwareInstaller/$moduleVersion"  # matches upload script
$files = @('SoftwareInstaller.psd1','SoftwareInstaller.psm1')

# Target module directory (use version subfolder to align with PS module resolution)
$moduleBase = 'C:\Program Files\WindowsPowerShell\Modules\SoftwareInstaller'
$moduleDir = Join-Path $moduleBase $moduleVersion
if (-not (Test-Path $moduleDir)) {
    Write-Host "Creating module directory: $moduleDir"
    New-Item -ItemType Directory -Path $moduleDir -Force | Out-Null
}

function Get-AccessToken {
    param([string]$ClientId)
    $imds = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&client_id=$ClientId&resource=https%3A%2F%2Fstorage.azure.com%2F"
    Write-Host "Requesting access token for managed identity $ClientId ..."
    $resp = Invoke-RestMethod -Uri $imds -Headers @{ Metadata = 'true' } -Method GET
    return $resp.access_token
}

function Download-BlobFile {
    param(
        [Parameter(Mandatory)][string]$BlobUrl,
        [Parameter(Mandatory)][string]$DestinationPath,
        [Parameter(Mandatory)][string]$AccessToken
    )
    Write-Host "Downloading $BlobUrl -> $DestinationPath"
    $headers = @{ 'Authorization' = "Bearer $AccessToken"; 'x-ms-version' = '2017-11-09' }
    Invoke-WebRequest -Uri $BlobUrl -Headers $headers -UseBasicParsing -OutFile $DestinationPath
    if (-not (Test-Path $DestinationPath)) { throw "Failed to download $BlobUrl" }
}

try {
    $token = Get-AccessToken -ClientId $clientId
    foreach ($file in $files) {
        $blobUrl = "$storagePrefix$relativePathRoot/$file"
        $dest = Join-Path $moduleDir $file
        Download-BlobFile -BlobUrl $blobUrl -DestinationPath $dest -AccessToken $token
    }
    Write-Host "Downloaded module files successfully." -ForegroundColor Green

    # Quick validation: import the module
    Import-Module (Join-Path $moduleDir 'SoftwareInstaller.psd1') -Force -ErrorAction Stop
    $mod = Get-Module SoftwareInstaller
    if ($mod -and $mod.Version.ToString() -eq $moduleVersion) {
        Write-Host "SoftwareInstaller module v$moduleVersion imported successfully." -ForegroundColor Green
    } else {
        Write-Warning 'Module imported but version mismatch or not found.'
    }
    Remove-Module SoftwareInstaller -Force -ErrorAction SilentlyContinue
    Write-Host 'Module installation completed.' -ForegroundColor Green
}
catch {
    Write-Error "Failed to download / install SoftwareInstaller module: $($_.Exception.Message)"
    throw
}
