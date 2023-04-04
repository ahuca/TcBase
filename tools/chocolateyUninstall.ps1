Param(
    $LibVersion = "*"
)

$LibName = "TcBase"
$AiUtilPath = "$PSScriptRoot\TcAutomationInterface.ps1"

. $AiUtilPath

Start-MessageFilter

# Create new DTE instance
$dte = New-DteInstance

# Uninstall library
$uninstallArgs = @{}
if ($env:ChocolateyEnvironmentVerbose) { $uninstallArgs.Add("-Verbose", $true) }

if (Uninstall-TcLibrary -LibName $LibName -LibVersion $LibVersion -DteInstace $dte @uninstallArgs) {
    $exitCode = 0
}
else {
    $exitCode = 1
}

# Close DTE instace
Close-DteInstace -DteInstace $dte
Stop-MessageFilter
exit $exitCode
