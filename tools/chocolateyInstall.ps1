[CmdletBinding()]
Param(
    [string]$ForceProgId,
    [string]$LibRepo = "System",
    [switch]$Force
)

$LibPath = "$PSScriptRoot\TcBase.library"
$AiUtilPath = "$PSScriptRoot\TcAutomationInterface.ps1"

. $AiUtilPath

Start-MessageFilter

# Create new DTE instance
$dteArgs = @{}
if ($ForceProgId) { $dteArgs.Add("-ForceProgId", $ForceProgId) }
$dte = New-DteInstance @dteArgs

# Install library
$installArgs = @{}
if ($env:ChocolateyForce) { $installArgs.Add("-Force", $true) }
elseif ($Force) { $installArgs.Add("-Force", $true) }
if ($env:ChocolateyEnvironmentVerbose) { $installArgs.Add("-Verbose", $true) }

if (Install-TcLibrary -LibPath $LibPath -DteInstace $dte @installArgs) {
    $exitCode = 0
}
else {
    $exitCode = 1
}

# Close DTE instace
Close-DteInstace -DteInstace $dte

Stop-MessageFilter
exit $exitCode