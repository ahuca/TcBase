[CmdletBinding()]
Param(
    [string]$ForceProgId,
    [string]$LibRepo = "System",
    [int]$MaxAttempts = 5,
    [switch]$Force
)

$LibPath = "$PSScriptRoot\TcBase.library"
$AiUtilPath = "$PSScriptRoot\TcAutomationInterface.ps1"

if (!$env:TWINCAT3DIR) {
    Write-Host "TwinCAT 3 is not installed, exiting normally"
    exit 0
}

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

Write-Host "Trying to install $LibPath with $MaxAttempts attempts"

for (($attempts = 0); $attempts -lt $MaxAttempts; $attempts++) {
    Write-Host "Attempt $($attempts + 1)"

    try {
        Install-TcLibrary -LibPath $LibPath -DteInstace $dte @installArgs
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
exit $exitCode
