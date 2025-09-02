# Import the SoftwareInstaller module
# Try to import from installed location first, then fallback to local
try {
    Import-Module SoftwareInstaller -ErrorAction Stop
} catch {
    Import-Module -Name "$PSScriptRoot\SoftwareInstaller\SoftwareInstaller.psm1" -Force
}

# Define installation parameters
$installerName = "python-3.13.7-amd64.exe"
$installArguments = "/quiet InstallAllUsers=1 PrependPath=1"
$softwareName = "Python 3.13.7"

# Install Python using the module
try {
    $exitCode = Install-SoftwareFromStorage -InstallerName $installerName -InstallArguments $installArguments -SoftwareName $softwareName

    if ($exitCode -eq 0) {
        Write-Host "Python installation completed successfully."
    } else {
        Write-Warning "Python installation completed with exit code: $exitCode"
        exit $exitCode
    }
}
catch {
    Write-Error "Failed to install Python: $($_.Exception.Message)"
    exit 1
}

