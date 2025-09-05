@{
  RootModule = 'SoftwareInstaller.psm1'
  ModuleVersion = '1.0.0'
  GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  Author = 'Azure TRE Team'
  CompanyName = 'Microsoft'
  Copyright = '(c) Microsoft Corporation. All rights reserved.'
  Description = 'PowerShell module for downloading and installing software from Azure Storage Account using managed identity authentication. Designed for Azure TRE VM image provisioning.'
  PowerShellVersion = '5.1'
  FunctionsToExport = @('Get-StorageAccessToken', 'Download-SoftwareFromStorage', 'Install-Software', 'Install-SoftwareFromStorage', 'Get-ModuleVersion', 'Test-ModulePrerequisites', 'Remove-ModuleArtifacts')
  CmdletsToExport = @()
  VariablesToExport = '*'
  AliasesToExport = @()
  PrivateData = @{
      PSData = @{
          Tags = @('Azure', 'TRE', 'Storage', 'Software', 'Installation', 'ManagedIdentity', 'VM', 'Provisioning')
          LicenseUri = 'https://github.com/microsoft/AzureTRE/blob/main/LICENSE'
          ProjectUri = 'https://github.com/microsoft/AzureTRE'
          ReleaseNotes = 'Version 1.0.0: Initial release of SoftwareInstaller module'
      }
  }
}
