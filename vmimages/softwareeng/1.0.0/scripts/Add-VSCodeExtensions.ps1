$ErrorActionPreference='Stop'
$code = "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
if (!(Test-Path $code)) { throw 'VS Code not found' }
$extDir = 'C:\Users\Default\.vscode\extensions'
$userData = 'C:\Build\VSCodeUserData'
New-Item -ItemType Directory -Force -Path $extDir | Out-Null
New-Item -ItemType Directory -Force -Path $userData | Out-Null
$exts = @(
  'ms-python.python',
  'ms-vscode.powershell',
  'esbenp.prettier-vscode',
  'ms-vscode-remote.remote-containers',
  'ms-azuretools.vscode-docker',
  'ms-vscode-remote.remote-wsl'
)
foreach ($e in $exts) {
  Write-Host "Installing VS Code extension $e"
  & $code --install-extension $e --force --extensions-dir $extDir --user-data-dir $userData
}
Write-Host 'VS Code extensions installed into Default profile.'
