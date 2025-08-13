# Import the SoftwareInstaller module
# Try to import from installed location first, then fallback to local
try {
    Import-Module SoftwareInstaller -ErrorAction Stop
} catch {
    Import-Module -Name "$PSScriptRoot\SoftwareInstaller\SoftwareInstaller.psm1" -Force
}

# Define installation parameters
$installerName = "vscode_installer.exe"
$installArguments = "/verysilent /mergetasks=!runcode"
$softwareName = "Visual Studio Code"

# Install VS Code using the module
try {
    $exitCode = Install-SoftwareFromStorage -InstallerName $installerName -InstallArguments $installArguments -SoftwareName $softwareName

    if ($exitCode -eq 0) {
        Write-Host "VS Code installation completed successfully."
    } else {
        Write-Warning "VS Code installation completed with exit code: $exitCode"
        exit $exitCode
    }
}
catch {
    Write-Error "Failed to install VS Code: $($_.Exception.Message)"
    exit 1
}

