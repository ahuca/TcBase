param(
    $ProgId = "TcXaeShell.DTE.15.0"
)

$MsgFilterSrc = @"
// https://learn.microsoft.com/en-us/previous-versions/visualstudio/visual-studio-2010/ms228772(v=vs.100)

using System;
using System.Runtime.InteropServices;

public class MessageFilter : IOleMessageFilter
{
    //
    // IOleMessageFilter functions.
    // Handle incoming thread requests.
    int IOleMessageFilter.HandleInComingCall(int dwCallType,
        IntPtr hTaskCaller, int dwTickCount, IntPtr
            lpInterfaceInfo)
    {
        //Return the flag SERVERCALL_ISHANDLED.
        return 0;
    }

    // Thread call was rejected, so try again.
    int IOleMessageFilter.RetryRejectedCall(IntPtr
        hTaskCallee, int dwTickCount, int dwRejectType)
    {
        if (dwRejectType == 2)
            // flag = SERVERCALL_RETRYLATER.
            // Retry the thread call immediately if return >=0 & 
            // <100.
            return 99;
        // Too busy; cancel call.
        return -1;
    }

    int IOleMessageFilter.MessagePending(IntPtr hTaskCallee,
        int dwTickCount, int dwPendingType)
    {
        //Return the flag PENDINGMSG_WAITDEFPROCESS.
        return 2;
    }
    // Class containing the IOleMessageFilter
    // thread error-handling functions.

    // Start the filter.
    public static void Register()
    {
        IOleMessageFilter newFilter = new MessageFilter();
        IOleMessageFilter oldFilter = null;
        CoRegisterMessageFilter(newFilter, out oldFilter);
    }

    // Done with the filter, close it.
    public static void Revoke()
    {
        IOleMessageFilter oldFilter = null;
        CoRegisterMessageFilter(null, out oldFilter);
    }

    // Implement the IOleMessageFilter interface.
    [DllImport("Ole32.dll")]
    private static extern int
        CoRegisterMessageFilter(IOleMessageFilter newFilter, out
            IOleMessageFilter oldFilter);
}

[ComImport]
[Guid("00000016-0000-0000-C000-000000000046")]
[InterfaceTypeAttribute(ComInterfaceType.InterfaceIsIUnknown)]
internal interface IOleMessageFilter
{
    [PreserveSig]
    int HandleInComingCall(
        int dwCallType,
        IntPtr hTaskCaller,
        int dwTickCount,
        IntPtr lpInterfaceInfo);

    [PreserveSig]
    int RetryRejectedCall(
        IntPtr hTaskCallee,
        int dwTickCount,
        int dwRejectType);

    [PreserveSig]
    int MessagePending(
        IntPtr hTaskCallee,
        int dwTickCount,
        int dwPendingType);
}
"@

Add-Type -TypeDefinition $MsgFilterSrc

function Start-MessageFilter {
    [CmdletBinding()]
    param ()
    [MessageFilter]::Register()
}

function Stop-MessageFilter {
    [CmdletBinding()]
    param ()
    [MessageFilter]::Revoke()
}

function New-DteInstance {
    [CmdletBinding()]
    param (
        $ProgId
    )
    
    # If a default ProgId is given, attemp to create a new DTE instance using this first
    if ($ProgId) {
        Write-Host "Loading $ProgId ..."
        $dte = New-Object -ComObject $ProgId
    }

    if ($dte) {
        Write-Host "... successful"
        $dte.SuppressUI = $false
        $dte.MainWindow.Visible = $true
        return $dte
    }

    # Try to create a new DTE instance using a list of known ProgId:s
    $vsProgIdList = New-Object Collections.Generic.List[string]
    $vsProgIdList.Add("TcXaeShell.DTE.15.0"); # TcXaeShell (VS2017)
    $vsProgIdList.Add("VisualStudio.DTE.16.0"); # VS2019
    $vsProgIdList.Add("VisualStudio.DTE.15.0"); # VS2017
    $vsProgIdList.Add("VisualStudio.DTE.14.0"); # VS2015
    $vsProgIdList.Add("VisualStudio.DTE.12.0"); # VS2013

    foreach ($vsProgId in $vsProgIdList) {
        Write-Host "Loading $vsProgId..."
        $dte = New-Object -ComObject $vsProgId
    
        if ($dte) {
            $dte.SuppressUI = $false
            $dte.MainWindow.Visible = $true
            Write-Host "... successful"
            return $dte
        }
    }

    Write-Error "Unable to create a DTE instace"
    return $null
}

function Install-TcLibrary {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]$LibPath,
        $DteInstace,
        [string]$DummyProjectPath = (Resolve-Path "$PSScriptRoot\Dummy.tpzip").ToString(),
        [string]$TmpPath = "$Env:TEMP\$(New-Guid)",
        [string]$LibRepo = "System",
        [switch]$Force
    )

    if (!(Test-Path $LibPath -PathType Leaf)) {
        Write-Error "Provided library path $LibPath does not exist"
        return
    }

    if (!(Test-Path $DummyProjectPath -PathType Leaf)) {
        Write-Error "Provided (tpzip) PLC project path $DummyProjectPath does not exist"
        return
    }

    if (!$DteInstace) {
        Write-Verbose "No existing DTE instance provided, creating a new one"
        $DteInstace = New-DteInstance
    }

    if (!$DteInstace) {
        return
    }

    Write-Verbose "Creating a new TwinCAT solution in $TmpPath ..."
    
    $tcProjectTemplatePath = "C:\TwinCAT\3.1\Components\Base\PrjTemplate\TwinCAT Project.tsproj"
    
    if (!(Test-Path $tcProjectTemplatePath -PathType Leaf)) {
        Write-Error "Could not find TwinCAT project template at $tcProjectTemplatePath"
        return
    }

    Write-Verbose "... successful"

    $project = $DteInstace.Solution.AddFromTemplate($tcProjectTemplatePath, $TmpPath, "TmpSolution.tsp")
    $systemManager = $project.Object
    $plc = $systemManager.LookupTreeItem("TIPC")
    
    Write-Verbose "Loading a dummy PLC project from $DummyProjectPath ..."
    $dummyProject = $plc.CreateChild("Dummy", 0, $null, $DummyProjectPath)

    if ($dummyProject) { Write-Verbose "... successful" }
    else { Write-Error "... failed" return }

    $references = $systemManager.LookupTreeItem("TIPC^Dummy^Dummy Project^References")

    Write-Host "Installing library $LibPath to $LibRepo"

    $forceInstall = $Force ? $true : $false
    $references.InstallLibrary($LibRepo, $LibPath, $forceInstall)

    Write-Verbose "Cleaning up temporary directory $TmpPath ..."
    Remove-Item $TmpPath -Recurse
}

function Close-DteInstace {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]$DteInstace
    )
    
    $DteInstace.Quit()
}
