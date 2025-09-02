$ErrorActionPreference='Stop'
Write-Host 'Enabling Windows features for WSL/VirtualMachinePlatform'
$needReboot = $false
$r1 = Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart
$needReboot = $needReboot -or $r1.RestartNeeded
$r2 = Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart
$needReboot = $needReboot -or $r2.RestartNeeded
if ($needReboot) {
  New-Item -Type Directory -Force C:\Build | Out-Null
  'reboot required' | Out-File C:\Build\reboot.flag
  Write-Host 'Reboot flag created.'
} else {
  Write-Host 'No reboot required.'
}
