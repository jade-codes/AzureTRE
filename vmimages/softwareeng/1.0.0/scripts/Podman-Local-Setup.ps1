$ErrorActionPreference = 'Stop'
$logDir = Join-Path $env:ProgramData 'FirstLogin'
if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$log = Join-Path $logDir 'PodmanSetup.log'
function Write-Log { param([string]$Message) $ts=(Get-Date).ToString('u'); Add-Content -Path $log -Value "$ts $Message" }
Write-Log "Starting Podman setup for $env:USERNAME"
Write-Host 'Configuring Podman machine...' -ForegroundColor Cyan
try {
  $initNeeded = $true
  try {
    $list = podman.exe machine list 2>$null | Out-String
    if ($list -and $list -match 'podman-machine-default') { $initNeeded = $false }
  } catch { $initNeeded = $true }
  if ($initNeeded) {
    Write-Host 'Initializing new Podman machine' -ForegroundColor Cyan
    Write-Log  'Initializing machine'
    podman.exe machine init --image "C:\\Setup\\5.3-rootfs-amd64.tar.zst" | Out-Null
  } else {
    Write-Host 'Existing machine found; updating settings' -ForegroundColor Yellow
    Write-Log  'Existing machine adjusting settings'
  }
  podman.exe machine set --user-mode-networking --rootful | Out-Null
  podman.exe machine start | Out-Null
  Write-Host 'Podman machine running.' -ForegroundColor Green
  Write-Log  'Machine running'
} catch {
  Write-Host "Podman setup failed: $($_.Exception.Message)" -ForegroundColor Red
  Write-Log  "Failure: $($_.Exception.Message)"
  exit 1
}
Write-Host 'Podman setup complete.'

Write-Host 'Configuring VS Code settings for Podman...'
$settingsPath = "$env:APPDATA\Code\User\settings.json"
$settingsDir = Split-Path $settingsPath -Parent
if (!(Test-Path $settingsDir)) { New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null }
$settings = @{
  "dev.containers.dockerPath" = "podman"
  "dev.containers.dockerComposePath" = "podman-compose"
}
if (Test-Path $settingsPath) {
  $existingSettings = Get-Content $settingsPath | ConvertFrom-Json
  foreach ($key in $settings.Keys) { $existingSettings | Add-Member -MemberType NoteProperty -Name $key -Value $settings[$key] -Force }
  $existingSettings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
} else {
  $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
}
Write-Host 'VS Code configured to use Podman.'
Write-Log 'Completed'
