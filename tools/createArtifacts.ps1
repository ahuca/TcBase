[CmdletBinding()]
Param(
    [string]$ForceProgId
)

Start-MessageFilter

# Create new DTE instance
$dteArgs = @{}
if ($ForceProgId) { $dteArgs.Add("-ForceProgId", $ForceProgId) }
$dte = New-DteInstance @dteArgs

# Save project as library
try {
    Export-TcProject -DteInstace $dte -Solution ".\TcBase\TcBase.sln" -ProjectName "TcBase" -Path (Resolve-Path(".\tools"))
}
catch {
    Write-Error $_
}

# Close DTE instace
Close-DteInstace -DteInstace $dte

Stop-MessageFilter
exit $exitCode
