[CmdletBinding()]
Param(
    [string]$ForceProgId,
    [string]$LibRepo = "System",
    [int]$MaxAttempts = 5,
    [switch]$Force
)

$LibPath = "$PSScriptRoot\TcBase.library"

if (!$env:TWINCAT3DIR) {
    Write-Host "TwinCAT 3 is not installed, exiting normally"
    exit 0
}

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
$dte | Install-TcLibrary -Path $LibPath @installArgs

# Close DTE instace
Close-DteInstace -DteInstace $dte

Stop-MessageFilter
exit $exitCode
