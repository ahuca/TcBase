[CmdletBinding()]
Param(
    [string]$ForceProgId
)

$AiUtilPath = "$PSScriptRoot\TcAutomationInterface.ps1"

. $AiUtilPath

Start-MessageFilter

# Create new DTE instance
$dteArgs = @{}
if ($ForceProgId) { $dteArgs.Add("-ForceProgId", $ForceProgId) }
$dte = New-DteInstance @dteArgs

# Save project as library
try {
    Save-TcProjectAsLibrary -DteInstace $dte -Solution ".\TcBase\TcBase.sln" -ProjectName "TcBase" -Path ".\tools"
}
catch {}

# Close DTE instace
Close-DteInstace -DteInstace $dte

Stop-MessageFilter
exit $exitCode
