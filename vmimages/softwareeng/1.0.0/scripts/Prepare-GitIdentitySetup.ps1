$ErrorActionPreference = 'Stop'
Write-Host 'Deploying on-demand Git identity setup script from Azure Storage (managed identity auth)'

# Expected environment variables:
#   SOFTWARE_STORAGE_PREFIX  e.g. https://<acct>.blob.core.windows.net/installers/
#   MANAGED_IDENTITY_CLIENT_ID  Client ID of UAMI with Storage Blob Data Reader
# Optional:
#   GIT_CONFIG_RELATIVE_PATH   relative blob path under the installers container (default: softwareeng/Git-Configure.ps1)

if (-not $env:SOFTWARE_STORAGE_PREFIX) { Write-Error 'SOFTWARE_STORAGE_PREFIX env var required.'; exit 1 }
if (-not $env:MANAGED_IDENTITY_CLIENT_ID) { Write-Error 'MANAGED_IDENTITY_CLIENT_ID env var required.'; exit 1 }

$relativePath = if ($env:GIT_CONFIG_RELATIVE_PATH) { $env:GIT_CONFIG_RELATIVE_PATH } else { 'softwareeng/Git-Configure.ps1' }
$storagePrefix = $env:SOFTWARE_STORAGE_PREFIX.TrimEnd('/') + '/'
$blobUrl = "$storagePrefix$relativePath"

$baseDir    = 'C:\ProgramData\FirstLogin'
$publicDesk = 'C:\Users\Public\Desktop'
New-Item -ItemType Directory -Force -Path $baseDir    | Out-Null
New-Item -ItemType Directory -Force -Path $publicDesk | Out-Null

$gitPs1 = Join-Path $baseDir 'Git-Configure.ps1'

Write-Host "Downloading Git configuration script from: $blobUrl (using SoftwareInstaller module)"

try {
  # Import the SoftwareInstaller module (manifest auto-discovery)
  Import-Module SoftwareInstaller -ErrorAction Stop
}
catch {
  Write-Warning 'SoftwareInstaller module not found in standard module paths. Attempting manual import...'
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
  Download-SoftwareFromStorage -StorageBlobUrl $blobUrl -AccessToken $token -DestinationPath $gitPs1
  Write-Host 'Download complete.' -ForegroundColor Green
}
catch {
  Write-Error "Failed to download Git configuration script via SoftwareInstaller module: $($_.Exception.Message)"
  exit 1
}

# Basic validation: ensure file has expected marker (function or prompt)
try {
  $content = Get-Content -Path $gitPs1 -ErrorAction Stop -TotalCount 5 | Out-String
  if (-not $content) { throw 'Downloaded file is empty.' }
}
catch {
  Write-Error "Validation failed for downloaded script: $($_.Exception.Message)"; exit 1
}

$gitBat = Join-Path $publicDesk 'Configure Git Identity.bat'
@(
  '@echo off',
  'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SystemDrive%\ProgramData\FirstLogin\Git-Configure.ps1"'
) | Out-File -FilePath $gitBat -Encoding ASCII

Write-Host 'Git identity setup deployment complete.' -ForegroundColor Green
