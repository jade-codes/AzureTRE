$ErrorActionPreference = 'Stop'
Write-Host 'Deploying on-demand Podman setup script from Azure Storage (managed identity auth)'

# Expected environment variables:
#   SOFTWARE_STORAGE_PREFIX      e.g. https://<acct>.blob.core.windows.net/installers/
#   MANAGED_IDENTITY_CLIENT_ID   Client ID of UAMI with Storage Blob Data Reader
# Optional:
#   PODMAN_SETUP_RELATIVE_PATH   relative blob path (default: softwareeng/Podman-Local-Setup.ps1)

if (-not $env:SOFTWARE_STORAGE_PREFIX) { Write-Error 'SOFTWARE_STORAGE_PREFIX env var required.'; exit 1 }
if (-not $env:MANAGED_IDENTITY_CLIENT_ID) { Write-Error 'MANAGED_IDENTITY_CLIENT_ID env var required.'; exit 1 }

$relativePath = if ($env:PODMAN_SETUP_RELATIVE_PATH) { $env:PODMAN_SETUP_RELATIVE_PATH } else { 'softwareeng/Podman-Local-Setup.ps1' }
$storagePrefix = $env:SOFTWARE_STORAGE_PREFIX.TrimEnd('/') + '/'
$blobUrl = "$storagePrefix$relativePath"

$baseDir    = 'C:\ProgramData\FirstLogin'
$publicDesk = 'C:\Users\Public\Desktop'
New-Item -ItemType Directory -Force -Path $baseDir    | Out-Null
New-Item -ItemType Directory -Force -Path $publicDesk | Out-Null

$podmanPs1 = Join-Path $baseDir 'Podman-Setup.ps1'

Write-Host "Downloading Podman setup script from: $blobUrl (using SoftwareInstaller module)"

try {
  Import-Module SoftwareInstaller -ErrorAction Stop
} catch {
  Write-Warning 'SoftwareInstaller module not found. Attempting manual import.'
  $manualPath = 'C:\Program Files\WindowsPowerShell\Modules\SoftwareInstaller'
  if (Test-Path $manualPath) {
    try { Import-Module $manualPath -Force -ErrorAction Stop } catch { Write-Error 'Failed manual import of SoftwareInstaller module.'; exit 1 }
  } else {
    Write-Error 'SoftwareInstaller module directory not found. Cannot continue.'
    exit 1
  }
}

try {
  $token = Get-StorageAccessToken -ManagedIdentityClientId $env:MANAGED_IDENTITY_CLIENT_ID
  Download-SoftwareFromStorage -StorageBlobUrl $blobUrl -AccessToken $token -DestinationPath $podmanPs1
  Write-Host 'Download complete.' -ForegroundColor Green
} catch {
  Write-Error "Failed to download Podman setup script: $($_.Exception.Message)"
  exit 1
}

# Basic validation
try {
  $head = Get-Content -Path $podmanPs1 -ErrorAction Stop -TotalCount 5 | Out-String
  if (-not $head) { throw 'Downloaded script is empty.' }
} catch { Write-Error "Validation failed: $($_.Exception.Message)"; exit 1 }

$podmanBat = Join-Path $publicDesk 'Setup Podman Machine.bat'
@(
  '@echo off',
  'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SystemDrive%\ProgramData\FirstLogin\Podman-Setup.ps1"'
) | Out-File -FilePath $podmanBat -Encoding ASCII

Write-Host 'Podman setup deployment complete.' -ForegroundColor Green
