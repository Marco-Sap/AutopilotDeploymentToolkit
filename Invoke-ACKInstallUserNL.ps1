<#
.SYNOPSIS
   Win32App for Autopilot Customization Kit
.DESCRIPTION
   Autopilot Customization Kit
.AUTHOR
   Marco Sap 
.VERSION
   1.0
.EXAMPLE
   
    Create Win32App
    URL Wrapper Tool: https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool

    C:\Temp\IntuneWinAppUtil.exe -c "C:\Temp\ACKInstallUserNL" -s Invoke-ACKInstallUserNL.ps1 -o C:\Temp -q

    Install Command: 
    C:\Windows\SysNative\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Bypass -File .\Invoke-ACKInstallUserNL.ps1 -Install
    
    Uninstall Command:
    C:\Windows\SysNative\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Bypass -File .\Invoke-ACKInstallUserNL.ps1 -Uninstall

    Detection rule:
    Manual configure detection rules
    Rule Type: Registry
    Key path: Computer\HKEY_CURRENT_USER\Software\Intune\ACKInstallUserNL
    Value name: 1.0-Success
    Detection methode: Value exists

.DISCLAIMER
   This script code is provided as is with no guarantee or waranty
   concerning the usability or impact on systems and may be used,
   distributed, and modified in any way provided the parties agree
   and acknowledge that Microsoft or Microsoft Partners have neither
   accountabilty or responsibility for results produced by use of
   this script.

   Microsoft will not provide any support through any means.
#>
[CmdletBinding(DefaultParameterSetName="Install")]
 Param(
    [Parameter(
    Mandatory = $false,
    ParameterSetName = 'Install'
    )]
    [switch]$Install,

    [Parameter(
    Mandatory = $false,
    ParameterSetName = 'Uninstall'
    )]
    [switch]$Uninstall
 )

 Function Add-Detection() {
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [String]
    $errorlevel
)

#Write results to registry for Intune Detection
$key = 'HKEY_CURRENT_USER\SOFTWARE\Intune\' + $name
$installdate = Get-Date -Format "dd/MM/yyyy hh:mm:ss"

    if($errorlevel -eq "55"){
        [microsoft.win32.registry]::SetValue($key, "$version-Start", $installdate)
    }elseif($errorlevel -eq "0"){
        [microsoft.win32.registry]::SetValue($key, "$version-Success", $installdate)
    }elseif($errorlevel -eq "3010"){
        [microsoft.win32.registry]::SetValue($key, "$version-Success", $installdate)
        [microsoft.win32.registry]::SetValue($key, "$version-Reboot", $errorlevel)
    }elseif($errorlevel -eq "1641"){
        [microsoft.win32.registry]::SetValue($key, "$version-Success", $installdate)
        [microsoft.win32.registry]::SetValue($key, "$version-Reboot", $errorlevel)
    }else{
        [microsoft.win32.registry]::SetValue($key, "$version-Failure", $installdate)
        [microsoft.win32.registry]::SetValue($key, "$version-ErrorCode", $errorlevel)
    }

}

#Variables
$exitstatus=0
$name="ACKInstallUserNL"
$version="1.0"
$logFile=$name + "-" + $version + ".log"
$key='HKEY_CURRENT_USER\SOFTWARE\Intune\' + $name

Start-Transcript "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\$logFile"
Write-Output ""
Write-Output "[Start] $(Get-Date -Format "dd/MM HH:mm")"
Add-Detection -errorlevel 55

If($Install){
        try{
        Write-Output "[Info] $(Get-Date -Format "dd/MM HH:mm") Install started"
        $OldList = Get-WinUserLanguageList
        $OldList.Add("nl-NL")
        Write-Output "[Info] $(Get-Date -Format "dd/MM HH:mm") Set-WinUserLanguageList started"
        Set-WinUserLanguageList -LanguageList $OldList -Force
        
        Write-Output "[Info] $(Get-Date -Format "dd/MM HH:mm") Set-WinUILanguageOverride started"
        Set-WinUILanguageOverride -Language nl-NL

        Write-Output "[Info] $(Get-Date -Format "dd/MM HH:mm") Set-Culture started"
        Set-Culture -CultureInfo nl-NL

        Write-Output "[Info] $(Get-Date -Format "dd/MM HH:mm") Set-WinHomeLocation started"
        Set-WinHomeLocation -GeoId 176

        Write-Output "[Info] $(Get-Date -Format "dd/MM HH:mm") Install finished"
        $exitstatus=3010
        }Catch{
        Write-Output "[Error] $(Get-Date -Format "dd/MM HH:mm") Install NL failed"
        $exitstatus=1
        }
}

If($Uninstall){
    try{
    Write-Output "[Info] $(Get-Date -Format "dd/MM HH:mm") Uninstall started"
    $Uninstallkey = $key.Replace('HKEY_CURRENT_USER','HKCU:')
    Remove-Item -Path $Uninstallkey -Force
    Write-Output "[Info] $(Get-Date -Format "dd/MM HH:mm") Uninstall finished"
    $exitstatus=3010
    }Catch{
    Write-Output "[Error] $(Get-Date -Format "dd/MM HH:mm") Uninstall failed"
    $exitstatus=1
    }
}

Write-Output "[End] $(Get-Date -Format "dd/MM HH:mm")"

#Stop logging
Stop-Transcript

#Exit Status
Add-Detection -errorlevel $exitstatus
EXIT $exitstatus
