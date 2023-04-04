Param(
    $LibName="TcBase",
    $LibVersion="*"
)

$AiUtilPath = "$PSScriptRoot\TcAutomationInterface.ps1"

. $AiUtilPath

Start-MessageFilter
$dte = New-DteInstance

Uninstall-TcLibrary -LibName $LibName -LibVersion $LibVersion -DteInstace $dte -Verbose

Close-DteInstace -DteInstace $dte
Stop-MessageFilter
