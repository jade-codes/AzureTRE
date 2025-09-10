$ErrorActionPreference = 'Stop'

$logDir = Join-Path $env:ProgramData 'FirstLogin'

if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

$log = Join-Path $logDir 'GitConfigure.log'

function Write-Log { param([string]$Message) $ts=(Get-Date).ToString('u'); Add-Content -Path $log -Value "$ts $Message" }
Write-Log "Starting Git configure for $env:USERNAME"

if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) { Write-Host 'git not found.' -ForegroundColor Red; Write-Log 'git missing'; exit 1 }

$existingName  = git config --global user.name
$existingEmail = git config --global user.email

if ($existingName -and $existingEmail) {
  Write-Host "Git already: $existingName <$existingEmail>" -ForegroundColor Yellow
  $resp = Read-Host 'Change these values? (y/N)'
  if ($resp -notmatch '^[Yy]') { Write-Log 'User kept existing identity'; exit 0 }
}

Do { $name  = Read-Host 'Enter full name for Git' } Until ($name -match '\S')
Do { $email = Read-Host 'Enter email for Git' } Until ($email -match '^[^@\s]+@[^@\s]+\.[^@\s]+$')

Write-Host 'Writing git config...'

git config --global user.name  "$name"
git config --global user.email "$email"
git config --global http.sslVerify false

Write-Host "Configured: $name <$email>" -ForegroundColor Green
Write-Log  "Configured Git: $name <$email>"
Write-Host 'Git configuration complete.'
Write-Log 'Completed'
