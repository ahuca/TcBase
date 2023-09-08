[CmdletBinding()]
Param(
    [string]$ForceProgId,
    [string]$LibRepo = "System",
    [int]$MaxAttempts = 5,
    [string]$LibVersion = "*"
)

$LibName = "TcBase"

if (!$env:TWINCAT3DIR) {
    Write-Host "TwinCAT 3 is not installed, exiting normally"
    exit 0
}

Start-MessageFilter

# Create new DTE instance
$dteArgs = @{}
if ($ForceProgId) { $dteArgs.Add("-ForceProgId", $ForceProgId) }
$dte = New-DteInstance @dteArgs

if ($env:ChocolateyPackageVersion) { $LibVersion = $env:ChocolateyPackageVersion }

# Uninstall library
$uninstallArgs = @{}
if ($env:ChocolateyEnvironmentVerbose) { $uninstallArgs.Add("-Verbose", $true) }

Write-Host "Trying to uninstall $LibName with $MaxAttempts attempts"

for (($attempts = 0); $attempts -lt $MaxAttempts; $attempts++) {
    Write-Host "Attempt $($attempts + 1)"

    try {
        Uninstall-TcLibrary -LibName $LibName -LibRepo $LibRepo -LibVersion $LibVersion -DteInstace $dte @uninstallArgs
        if ($?) { $exitCode = 0 }
    }
    catch {
        Write-Error $_
        $exitCode = 1
    }

    if ($exitCode -eq 0) { break }
}

# Close DTE instace
Close-DteInstace -DteInstace $dte
Stop-MessageFilter
exit 0
