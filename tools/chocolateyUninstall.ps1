[CmdletBinding()]
Param(
    [string]$ForceProgId,
    [string]$LibRepo = "System",
    [string]$LibVersion = "*"
)

$LibName = "TcBase"
$AiUtilPath = "$PSScriptRoot\TcAutomationInterface.ps1"

. $AiUtilPath

Start-MessageFilter

# Create new DTE instance
$dteArgs = @{}
if ($ForceProgId) { $dteArgs.Add("-ForceProgId", $ForceProgId) }
$dte = New-DteInstance @dteArgs

# Uninstall library
$uninstallArgs = @{}
if ($env:ChocolateyEnvironmentVerbose) { $uninstallArgs.Add("-Verbose", $true) }

try {
    Uninstall-TcLibrary -LibName $LibName -LibRepo $LibRepo -LibVersion $LibVersion -DteInstace $dte @uninstallArgs
    if ($?) { $exitCode = 0 }
}
catch {
    Write-Error "Could not uninstall $LibName from $LibRepo, maybe it has been uninstalled manually?"
    $exitCode = 0
}

# Close DTE instace
Close-DteInstace -DteInstace $dte
Stop-MessageFilter
exit 0
