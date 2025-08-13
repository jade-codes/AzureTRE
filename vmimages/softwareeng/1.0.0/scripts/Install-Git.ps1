# Import the SoftwareInstaller module
# Try to import from installed location first, then fallback to local
try {
    Import-Module SoftwareInstaller -ErrorAction Stop
} catch {
    Import-Module -Name "$PSScriptRoot\SoftwareInstaller\SoftwareInstaller.psm1" -Force
}

# Define installation parameters
$installerName = "git_installer.exe"
$installArguments = "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS=`"icons,ext\reg\shellhere,assoc,assoc_sh`""
$softwareName = "Git for Windows"

# Install Git using the module
try {
    $exitCode = Install-SoftwareFromStorage -InstallerName $installerName -InstallArguments $installArguments -SoftwareName $softwareName

    if ($exitCode -eq 0) {
        Write-Host "Git for Windows installation completed successfully."
    } else {
        Write-Warning "Git for Windows installation completed with exit code: $exitCode"
        exit $exitCode
    }
}
catch {
    Write-Error "Failed to install Git for Windows: $($_.Exception.Message)"
    exit 1
}
