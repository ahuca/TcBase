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
        $ForceProgId = ""
    )

    $dte = $null
    $loadedProgId = ""

    Write-Host "Trying to create a new DTE instance using known ProgIds"

    $vsProgIdList = New-Object Collections.Generic.List[string]
    if ($ForceProgId) { $vsProgIdList.Add($ForceProgId) } # Add forced ProgId to try first
    $vsProgIdList.Add("TcXaeShell.DTE.15.0"); # TcXaeShell (VS2017)
    $vsProgIdList.Add("VisualStudio.DTE.16.0"); # VS2019
    $vsProgIdList.Add("VisualStudio.DTE.15.0"); # VS2017
    $vsProgIdList.Add("VisualStudio.DTE.14.0"); # VS2015
    $vsProgIdList.Add("VisualStudio.DTE.12.0"); # VS2013

    foreach ($vsProgId in $vsProgIdList) {
        try {
            $dte = New-Object -ComObject $vsProgId
            $dte.SuppressUI = $true
            $dte.MainWindow.Visible = $false
            $dte.UserControl = $false
            # Check if TwinCAT is integrated with this visual studio version
            $ignore = $dte.GetObject("TcRemoteManager")
            $loadedProgId = $vsProgId
        }
        catch {
            Write-Verbose "Failed to create $vsProgId"
            $dte.Quit()
            $dte = $null
            $loadedProgId = ""
            continue
        }

        break
    }

    if ($dte) {
        Write-Host "Successfully created $loadedProgId"
        return $dte
    }

    Write-Error "Unable to create a DTE instace"
    return $null
}

function New-DummyTwincatSolution {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][System.__ComObject]$DteInstace,
        [Parameter(Mandatory = $true)][string]$Path = "$Env:TEMP\$([Guid]::NewGuid())",
        [string]$DummyProjectPath = (Resolve-Path "$PSScriptRoot\Dummy.tpzip").ToString()
    )

    Write-Verbose "Creating a new TwinCAT solution in $Path ..."
    
    $tcProjectTemplatePath = "C:\TwinCAT\3.1\Components\Base\PrjTemplate\TwinCAT Project.tsproj"
    
    if (!(Test-Path $tcProjectTemplatePath -PathType Leaf)) {
        Write-Error "Could not find TwinCAT project template at $tcProjectTemplatePath"
        return $null
    }

    Write-Verbose "... successful"

    $project = $DteInstace.Solution.AddFromTemplate($tcProjectTemplatePath, $Path, "TmpSolution.tsp")
    $systemManager = $project.Object
    $plc = $systemManager.LookupTreeItem("TIPC")
    
    Write-Verbose "Loading a dummy PLC project from $DummyProjectPath ..."
    $dummyProject = $plc.CreateChild("Dummy", 0, $null, $DummyProjectPath)

    if ($dummyProject) {
        Write-Verbose "... successful"
        return $dummyProject
    }
    else {
        Write-Error "... failed"
        return $null
    }
}

function Install-TcLibrary {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]$LibPath,
        [System.__ComObject]$DteInstace,
        [string]$DummyProjectPath = (Resolve-Path "$PSScriptRoot\Dummy.tpzip").ToString(),
        [string]$TmpPath = "$Env:TEMP\$([Guid]::NewGuid())",
        [string]$LibRepo = "System",
        [switch]$Force
    )

    if (!(Test-Path $LibPath -PathType Leaf)) {
        Write-Error "Provided library path $LibPath does not exist"
        return $false
    }

    if (!(Test-Path $DummyProjectPath -PathType Leaf)) {
        Write-Error "Provided (tpzip) PLC project path $DummyProjectPath does not exist"
        return $false
    }

    if (!$DteInstace) {
        Write-Verbose "No existing DTE instance provided, creating a new one"
        $DteInstace = New-DteInstance
    }

    if (!$DteInstace) {
        return $false
    }

    New-DummyTwincatSolution -DteInstace $DteInstace -Path $TmpPath -DummyProjectPath $DummyProjectPath
    $systemManager = $DteInstace.Solution.Projects.Item(1).Object

    try {
        $references = $systemManager.LookupTreeItem("TIPC^Dummy^Dummy Project^References")
    }
    catch {
        return $false
    }

    Write-Host "Installing library $LibPath to $LibRepo"

    if ($Force) { $forceInstall = $true }
    else { $forceInstall = $false }
    
    Write-Host "Forced installation set to ``$forceInstall``"

    $references.InstallLibrary($LibRepo, $LibPath, $forceInstall)
    $result = $?

    Write-Verbose "Cleaning up temporary directory $TmpPath ..."
    Remove-Item $TmpPath -Recurse
    
    if ($result) { Write-Host "Successfully installed $LibPath to $LibRepo" }
    else { Write-Error "Could not install $LibPath to $LibRepo" }

    return $result
}

function Uninstall-TcLibrary {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]$LibName,
        [string]$LibVersion = "*",
        [string]$Distributor = $LibName,
        [System.__ComObject]$DteInstace,
        [string]$DummyProjectPath = (Resolve-Path "$PSScriptRoot\Dummy.tpzip").ToString(),
        [string]$TmpPath = "$Env:TEMP\$([Guid]::NewGuid())",
        [string]$LibRepo = "System"
    )

    if (!(Test-Path $DummyProjectPath -PathType Leaf)) {
        Write-Error "Provided (tpzip) PLC project path $DummyProjectPath does not exist"
        return $false
    }

    if (!$DteInstace) {
        Write-Verbose "No existing DTE instance provided, creating a new one"
        $DteInstace = New-DteInstance
    }

    if (!$DteInstace) {
        return $false
    }

    New-DummyTwincatSolution -DteInstace $DteInstace -Path $TmpPath -DummyProjectPath $DummyProjectPath
    $systemManager = $DteInstace.Solution.Projects.Item(1).Object

    try {
        $references = $systemManager.LookupTreeItem("TIPC^Dummy^Dummy Project^References")
    }
    catch {
        return $false
    }

    Write-Host "Uninstalling library $LibName version `"$LibVersion`""

    $references.UninstallLibrary($LibRepo, $LibName, $LibVersion, $Distributor)
    $result = $?

    Write-Verbose "Cleaning up temporary directory $TmpPath ..."
    Remove-Item $TmpPath -Recurse
    
    if ($result) { Write-Host "Successfully uninstalled $LibName version `"$LibVersion`" from $LibRepo" }
    else { Write-Error "Could not uninstall $LibName version `"$LibVersion`" from $LibRepo" }
    
    return $result
}

function Close-DteInstace {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]$DteInstace
    )
    
    $DteInstace.Quit()
}
