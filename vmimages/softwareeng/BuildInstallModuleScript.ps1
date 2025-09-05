# The following is not used but is an example of an alternative method for installing the SoftwareInstaller module using Nuget

param (
    [string] $certFingerprint = ''
)

$moduleSourcePath = "$PSScriptRoot\1.0.0\scripts\SoftwareInstaller"

Push-Location $PSScriptRoot

if (!(Test-Path '.\PowerShell\Nuget'))
{
    New-Item -Path '.\PowerShell\Nuget' -ItemType Directory | Out-Null
}

$moduleData = Import-PowerShellDataFile -Path (Join-Path $moduleSourcePath SoftwareInstaller.psd1)
if (Test-Path ".\PowerShell\Nuget\SoftwareInstaller.$($moduleData.ModuleVersion).nupkg")
{
    Remove-Item ".\PowerShell\Nuget\SoftwareInstaller.$($moduleData.ModuleVersion).nupkg"
}
Register-PSRepository -Name 'LocalPublish' -SourceLocation '.\PowerShell\Nuget\'
if ($certFingerprint -ne '')
{
    Set-AuthenticodeSignature -Certificate (Get-Item "Cert:\CurrentUser\My\$certFingerprint") -TimestampServer 'http://timestamp.digicert.com' -FilePath .\PowerShell\Modules\ASDKHelper\ASDKHelper.psm1
}
Publish-Module -Path $moduleSourcePath -Repository 'LocalPublish'
if ($certFingerprint -ne '')
{
    dotnet nuget sign .\PowerShell\Nuget\SoftwareInstaller.$($moduleData.ModuleVersion)clear.nupkg --certificate-store-name My --certificate-store-location CurrentUser --certificate-fingerprint $certFingerprint --timestamper 'http://timestamp.digicert.com'
}
Unregister-PSRepository -Name 'LocalPublish'

Compress-Archive -Path .\PowerShell\Nuget\*.nupkg -DestinationPath '.\PowerShell\psnuget.zip' -CompressionLevel Optimal -Force

$zipContent = Get-Content -Path '.\PowerShell\psnuget.zip' -AsBytestream -Raw
$moduleBase64 = [Convert]::ToBase64String($zipContent)

@"
`$moduleBase64 = '$moduleBase64'

[Convert]::FromBase64String(`$moduleBase64) | Set-Content -Path '.\nugets.zip' -AsBytestream

if (!(Test-Path '.\PSNuget'))
{
    New-Item -Path '.\PSNuget' -ItemType Directory | Out-Null
}

Expand-Archive -Path 'nugets.zip' -DestinationPath '.\PSNuget'

Register-PSRepository -Name 'Local' -SourceLocation '.\PSNuget' -InstallationPolicy Trusted
Install-Module -Name @('SoftwareInstaller') -Repository 'Local'
Unregister-PSRepository -Name 'Local'
Remove-Item -Path @('.\PSNuget') -Recurse -Force

"@ | Out-File -FilePath '.\PowerShell\InstallModule.ps1' -Encoding ASCII -Force

Pop-Location
