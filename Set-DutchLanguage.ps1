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
    C:\Windows\SysNative\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Bypass -File .\Set-DutchLanguage.ps1 -Install
    
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

#Start logging
Start-Transcript "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\$logfile"
Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Start]"
Add-Detection -errorlevel 55

If($Install){
    #https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/available-language-packs-for-windows
    $LPlanguage = "nl-NL"
    Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] LPlanguage: $($LPlanguage)"
    #https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/default-input-locales-for-windows-language-packs
    #$inputlocale = "nl-NL"
    #Write-Output "[Info] inputlocale: $($inputlocale)"
    #https://learn.microsoft.com/en-us/windows/win32/intl/table-of-geographical-locations?redirectedfrom=MSDN
    $geoId = "176"  #Netherlands
    Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] geoId: $($geoId)"

    #Install language pack including FODs
    Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Installing languagepack"
    Install-Language $LPlanguage -CopyToSettings

    #Set Win Home Location, sets the home location setting for the current user 
    Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Set WinHomeLocation $($geoId)"
    Set-WinHomeLocation -GeoId $geoId

    #Set System Preferred UI Language
    Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Set SystemPreferredUILanguage $($LPlanguage)"
    Set-SystemPreferredUILanguage $LPlanguage

    #Copy User Internaltional Settings from current user to new user
    Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Copy UserInternationalSettingsToSystem"
    Copy-UserInternationalSettingsToSystem -WelcomeScreen $true -NewUser $true

    #Prepare Recovery
    Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] XML started"
    #Variables Language XML
    $InputLocale="0409:00020409"
    $SystemLocale="en-US"
    $TimeZone="W. Europe Standard Time"

    If (Test-Path "C:\Recovery\AutoApply"){}Else{
        New-Item -Path "C:\Recovery\" -Name "AutoApply" -ItemType "directory"
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Directory Created"
    }

    #Create & Set The Formatting with XmlWriterSettings class
    $xmlObjectsettings = New-Object System.Xml.XmlWriterSettings
    #Indent: Sets a value indicating whether to indent elements.
    $xmlObjectsettings.Indent = $true
    #Sets the character string to use when indenting. This setting is used when the Indent property is set to true.
    $xmlObjectsettings.IndentChars = "`t"
 
    #Set the File path & Create the XML
    $XmlFilePath = "C:\Recovery\AutoApply\unattend.xml"
    $XmlObjectWriter = [System.XML.XmlWriter]::Create($XmlFilePath, $xmlObjectsettings)

    #Write the XML
    $XmlObjectWriter.WriteStartDocument()
    $XmlObjectWriter.WriteStartElement('unattend', "urn:schemas-microsoft-com:unattend")
    $XmlObjectWriter.WriteAttributeString("xmlns", "urn:schemas-microsoft-com:unattend")
        $XmlObjectWriter.WriteStartElement('settings')
        $XmlObjectWriter.WriteAttributeString("pass", "specialize")
            $XmlObjectWriter.WriteStartElement('component')
            $XmlObjectWriter.WriteAttributeString("language", "neutral")
            $XmlObjectWriter.WriteAttributeString("name", "Microsoft-Windows-International-Core")
            $XmlObjectWriter.WriteAttributeString("processorArchitecture", "amd64")
            $XmlObjectWriter.WriteAttributeString("publicKeyToken", "31bf3856ad364e35")
            $XmlObjectWriter.WriteAttributeString("versionScope", "nonSxS")
            $XmlObjectWriter.WriteAttributeString("xmlns", "wcm", "http://www.w3.org/2000/xmlns/", "http://schemas.microsoft.com/WMIConfig/2002/State")
            $XmlObjectWriter.WriteAttributeString("xmlns", "xsi", "http://www.w3.org/2000/xmlns/", "http://www.w3.org/2001/XMLSchema-instance")
                $XmlObjectWriter.WriteElementString("InputLocale",$InputLocale)
                $XmlObjectWriter.WriteElementString("SystemLocale",$SystemLocale)
                $XmlObjectWriter.WriteElementString("UILanguage",$SystemLocale)
                $XmlObjectWriter.WriteElementString("UILanguageFallback",$SystemLocale)
                $XmlObjectWriter.WriteElementString("UserLocale",$SystemLocale)
            $XmlObjectWriter.WriteEndElement()
            $XmlObjectWriter.WriteStartElement('component')
            $XmlObjectWriter.WriteAttributeString("language", "neutral")
            $XmlObjectWriter.WriteAttributeString("name", "Microsoft-Windows-Shell-Setup")
            $XmlObjectWriter.WriteAttributeString("processorArchitecture", "amd64")
            $XmlObjectWriter.WriteAttributeString("publicKeyToken", "31bf3856ad364e35")
            $XmlObjectWriter.WriteAttributeString("versionScope", "nonSxS")
            $XmlObjectWriter.WriteAttributeString("xmlns", "wcm", "http://www.w3.org/2000/xmlns/", "http://schemas.microsoft.com/WMIConfig/2002/State")
            $XmlObjectWriter.WriteAttributeString("xmlns", "xsi", "http://www.w3.org/2000/xmlns/", "http://www.w3.org/2001/XMLSchema-instance")
                $XmlObjectWriter.WriteElementString("TimeZone",$TimeZone)
            $XmlObjectWriter.WriteEndElement()
        $XmlObjectWriter.WriteEndElement()
    $XmlObjectWriter.WriteEndElement()
    $XmlObjectWriter.WriteEndDocument()
    $XmlObjectWriter.Flush()
    $XmlObjectWriter.Close()
    Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] XML Created"
}

If($Uninstall){
    try{
    Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Uninstall started"
    $Uninstallkey = $key.Replace('HKEY_LOCAL_MACHINE','HKLM:')
    Remove-Item -Path $Uninstallkey -Force
    Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Uninstall finished"
    $exitstatus=0
    }Catch{
    Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Error] Uninstall failed"
    $exitstatus=1
    }
}

Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [End]"
#Stop logging
Stop-Transcript
#Exit Status
Add-Detection -ErrorLevel $exitStatus
EXIT $exitstatus