﻿#Requires -RunAsAdministrator
#Requires -Version 3.0

<#
.SYNOPSIS
Remove domain user profiles from computers

.DESCRIPTION
This script removes domain user profiles from workstations and servers.
For example it can be used to clean public workstations.
It won't remove loaded (logged in) users or non-domain users as long as DomainSID is correctly set.
No visible errors or prompts.

Powershell version 3.0 should be enough, however only tested on PS 5.0.
Local administrator privileges required.

Scheduling can be done via Task Scheduler. Recommended parameters for executing script file:
Powershell.exe -NonInteractive -ExecutionPolicy Bypass -NoProfile -Path C:\Path\to\script.ps1

Monitoring is up to you.

Note: if you're using SYSTEM account for executing script you can't access network shares.
Note: LastUseTime might be inaccurate, in some environments it updates without logging in. I've included NTUSER.DAT file timestamp check too but it's commented out for now.

.PARAMETER InactivityDays
Default 14 days. Can be set to 0 for skipping inactivity check.

.PARAMETER DomainSID
DomainSID is a forest/domain wide identifier SID for domain. Many ways to find DomainSID. For example:
PS> Get-CimInstance -ClassName Win32_UserProfile | Where {$_.LocalPath -eq "C:\Users\domain.user"} | % {$_.SID.substring(0,($_.SID.length)-5);}
#>

Param(
    [Uint16]$InactivityDays = 14,
    [String]$DomainSID = "S-1-5-21-0123456789-012345678-012345678"
)

Set-StrictMode -Version Latest

Try{
    $Profiles = Get-CimInstance -ClassName Win32_UserProfile | Where {$_.SID -Like "$DomainSID*"}
    ForEach($Profile in $Profiles){
        #$NTUSERDAT = Get-ItemProperty -Path "$($Profile.LocalPath)\NTUSER.DAT"
        #if($NTUSERDAT.LastWriteTime -gt ((Get-Date).AddDays(-$InactivityDays))){Continue}
        if($Profile.LastUseTime -gt ((Get-Date).AddDays(-$InactivityDays))){Continue}
        if($Profile.Loaded -eq "True"){Continue}
        $Profile | Remove-CimInstance
    }
}Catch{}