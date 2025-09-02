$ErrorActionPreference='Stop'
$logDir = 'C:\Build\Logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$msi = 'C:\Setup\wsl.2.5.10.0.x64.msi'
if (-not (Test-Path $msi)) { throw "MSI not found at $msi" }
$args = "/i `"$msi`" /quiet /norestart /l*v C:\Build\Logs\wsl-kernel-install.log"
Write-Host "Installing WSL kernel from $msi"
$p = Start-Process -FilePath 'msiexec.exe' -ArgumentList $args -Wait -PassThru -WindowStyle Hidden
Write-Host "MSI exit code: $($p.ExitCode)"
if ($p.ExitCode -eq 3010) { Write-Host 'WSL kernel requested reboot'; exit 3010 }
if ($p.ExitCode -ne 0) { throw "WSL kernel MSI failed with exit code $($p.ExitCode)" }
Write-Host 'WSL kernel installed successfully.'
