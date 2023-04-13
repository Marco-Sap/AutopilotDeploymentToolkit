<#
.SYNOPSIS
   Win32App for Autopilot Dutch Language
.DESCRIPTION
   Autopilot Target Devices to set Dutch
.AUTHOR
   Marco Sap
.VERSION
   0.5.0
.EXAMPLE

    Create Win32App
    C:\Temp\IntuneWinAppUtil.exe -c "C:\Temp\Lxp" -s Set-DutchLanguage.ps1 -o C:\IntuneApp -q

    Install Command: 
    C:\Windows\SysNative\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Bypass -File .\Set-DutchLanguage.ps1 -Install -NL
    
    Uninstall Command:
    C:\Windows\SysNative\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Bypass -File .\Set-DutchLanguage.ps1 -Uninstall

    Detection rule:
    Manual configure detection rules
    Rule Type: Registry
    Key path: Computer\HKEY_LOCAL_MACHINE\Software\Intune\LXP
    Value name: 1.0-Success
    Detection methode: Key exists

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
    [switch]$Uninstall,

    [Parameter(
    Mandatory = $false)]
    [switch]$NL
 )

 Function Add-Detection() {
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [String]
    $errorlevel
)

#Write results to registry for Intune Detection
$key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Intune\' + $name
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
$name="LXP"
$version="1.0"
$logFile=$name + "-" + $version + ".log"
$key='HKEY_LOCAL_MACHINE\SOFTWARE\Intune\' + $name

#Sart logging
Start-Transcript "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\$logFile" -Append
Write-Output ""
Write-Output "[START] $(Get-Date -Format "dd/MM HH:mm")"
Add-Detection -errorlevel 55

If($Install){

    If($NL){
        #https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/available-language-packs-for-windows
        $LPlanguage = "nl-NL"
        Write-Output "[INFO]LPlanguage = $LPlanguage"
        #https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/default-input-locales-for-windows-language-packs
        $inputlocale = "nl-NL"
        Write-Output "[INFO]inputlocale = $inputlocale"
        #https://learn.microsoft.com/en-us/windows/win32/intl/table-of-geographical-locations?redirectedfrom=MSDN
        $geoId = "176"  #Netherlands
        Write-Output "[INFO]geoId = $geoId"

        #Install language pack including FODs
        Write-Output "[INFO]Installing languagepack"
        Install-Language $LPlanguage

        #Check language pack
        Write-Output "[INFO]Checking installed languagepack status"
        $installedLanguage = (Get-InstalledLanguage).LanguageId

        if ($installedLanguage -like $LPlanguage){
	        Write-Output "[INFO]Language $LPlanguage installed"
	        }
	        else {
	        Write-Output "[ERROR]Language $LPlanguage NOT installed"
            Exit 1
        }

        #Set Win User Language List, sets the current user language settings
        Write-Output "[INFO]Set WinUserLanguageList"
        $OldList = Get-WinUserLanguageList
        $UserLanguageList = New-WinUserLanguageList -Language $inputlocale
        $UserLanguageList += $OldList | where { $_.LanguageTag -ne $inputlocale }
        $UserLanguageList | select LanguageTag
        Set-WinUserLanguageList -LanguageList $UserLanguageList -Force

        #Set Culture, sets the user culture for the current user account.
        Write-Output "[INFO]Set culture $inputlocale"
        Set-Culture -CultureInfo $inputlocale

        #Set Win Home Location, sets the home location setting for the current user 
        Write-Output "[INFO]Set WinHomeLocation $geoId"
        Set-WinHomeLocation -GeoId $geoId

        #Copy User Internaltional Settings from current user to new user
        Write-Output "[INFO]Copy UserInternationalSettingsToSystem"
        Copy-UserInternationalSettingsToSystem -WelcomeScreen $false -NewUser $true

        #Set System Preferred UI Language
        Write-Output "[INFO]Set SystemPreferredUILanguage $inputlocale"
        Set-SystemPreferredUILanguage $inputlocale

        #Revert SystemAccount to US
        Write-Output "[INFO]Revert SystemAccount back to US"
        Set-WinHomeLocation -GeoId 244
        Set-Culture en-US
    }
}

If($Uninstall){
    try{
    Write-Output "[Info] $(Get-Date -Format "dd/MM HH:mm") Uninstall started"
    $Uninstallkey = $key.Replace('HKEY_LOCAL_MACHINE','HKLM:')
    Remove-Item -Path $Uninstallkey -Force
    Write-Output "[Info] $(Get-Date -Format "dd/MM HH:mm") Uninstall finished"
    $exitstatus=0
    }Catch{
    Write-Output "[Error] $(Get-Date -Format "dd/MM HH:mm") Uninstall failed"
    $exitstatus=1
    }
}

Write-Output "[END] $(Get-Date -Format "dd/MM HH:mm")"

#Stop logging
Stop-Transcript

#Exit Status
Add-Detection -errorlevel $exitstatus
EXIT $exitstatus