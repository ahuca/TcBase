Param(
    $LibPath="$PSScriptRoot\TcBase.library"
)

$AiUtilPath = "$PSScriptRoot\TcAutomationInterface.ps1"

. $AiUtilPath

Start-MessageFilter
$dte = New-DteInstance

Install-TcLibrary -LibPath $LibPath -DteInstace $dte -Verbose -Force

Close-DteInstace -DteInstace $dte
Stop-MessageFilter
