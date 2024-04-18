<#
.SYNOPSIS
   Win32App for Autopilot Deployment Toolkit
.DESCRIPTION
   Autopilot Deployment Toolkit target Devices
.AUTHOR
   Marco Sap
.VERSION
   1.0.0 - 18-04-2024
.EXAMPLE

    Create Win32App
    C:\IntuneApp\IntuneWinAppUtil.exe -c "C:\IntuneApp\ADTDevice" -s Invoke-ADTDevice.ps1 -o C:\IntuneApp -q

    Install Command: 
    C:\Windows\SysNative\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Bypass -File .\Invoke-ADTDevice.ps1 -Install -LXP -Profile -Appx -RemoveCapability -RemoveFeatures -AddFeatures -Update -Bitlocker -Files

    C:\Windows\SysNative\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Bypass -File .\Invoke-ADTDevice.ps1 -Install -Appx

    C:\Windows\SysNative\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Bypass -File .\Invoke-ADTDevice.ps1 -Install -LXP -Profile -Files
    
    Uninstall Command:
    C:\Windows\SysNative\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Bypass -File .\Invoke-ADTDevice.ps1 -Uninstall

    Detection rule:
    Manual configure detection rules
    Rule Type: Registry
    Key path: Computer\HKEY_LOCAL_MACHINE\Software\Intune\ADTDevice
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
[CmdletBinding()]
 Param(
    [Parameter(
    Mandatory = $false)]
    [switch]$Install,

    [Parameter(
    Mandatory=$false)]
    [switch]$Uninstall,

    [Parameter(
    Mandatory=$false)]
    [switch]$LXP,

    [Parameter(
    Mandatory=$false)]
    [switch]$Profile,

    [Parameter(
    Mandatory=$false)]
    [switch]$Appx,

    [Parameter(
    Mandatory=$false)]
    [switch]$RemoveCapability,

    [Parameter(
    Mandatory=$false)]
    [switch]$RemoveFeatures,

    [Parameter(
    Mandatory=$false)]
    [switch]$AddFeatures,

    [Parameter(
    Mandatory=$false)]
    [switch]$Update,

    [Parameter(
    Mandatory=$false)]
    [switch]$Bitlocker,

    [Parameter(
    Mandatory=$false)]
    [switch]$Files
 )

#If the host is an appropriate PowerShell version, set reusethreading. This improves memory utilisation and prevents leakage.
if ($Host.Version.Major -gt 1) {$Host.Runspace.ThreadOptions = "ReuseThread"}

#region Helper Functions
Function Add-RegistryKey {
[CmdletBinding()]
    Param(
    [Parameter(Mandatory=$true)]
    $HKEY,

    [Parameter(Mandatory=$true)]
    $RegistryPath,

    [Parameter(Mandatory=$true)]
    $RegistryKey,

    [Parameter(Mandatory=$true)]
    $RegistryValue,

    [Parameter(Mandatory=$true)]
    $ValueType
    )

Switch ($HKEY)
    {
        "LOCAL_MACHINE" {$RegistryPath = "HKLM:\" + $RegistryPath}
        "CURRENT_USER" {$RegistryPath = "HKCU:\" + $RegistryPath}
        "DEFAULT_USER" {$RegistryPath = "HKLM:\MDU\" + $RegistryPath}
    }

    if(!(Test-Path $RegistryPath))
    {
        New-Item -Path $RegistryPath -Force 1>$null
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Create] Path $($RegistryPath)"
    }
    else
    {
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [NoChange] $($RegistryPath)"
    }

    if(!([string]::IsNullOrEmpty($RegistryKey)))
    {

        if(!([string]::IsNullOrEmpty($(Get-ItemProperty -Path $RegistryPath))))
        {
                       
            if([string]::IsNullOrEmpty($(Get-ItemProperty -Path $RegistryPath -Name $RegistryKey -ErrorAction SilentlyContinue))){

                New-ItemProperty -Path $RegistryPath -Name $RegistryKey -Value $RegistryValue -PropertyType $ValueType 1>$null
                Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Create] Key $($RegistryKey) with value $($RegistryValue) of type $($ValueType)"}

            else{

                    if($(Get-ItemPropertyValue -Path $RegistryPath -Name $RegistryKey) -eq $RegistryValue)
                    {
                        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [NoChange] $($RegistryKey) with $($RegistryValue) of type $($ValueType)"
                    }
                    else
                    {
                        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Changed] Key $RegistryKey value $(Get-ItemPropertyValue -Path $RegistryPath -Name $RegistryKey) to value $RegistryValue"
                        Set-ItemProperty -Path $RegistryPath -Name $RegistryKey -Value $RegistryValue 1>$null
                    }
                }
                    
        }
        else {
            New-ItemProperty -Path $RegistryPath -Name $RegistryKey -Value $RegistryValue -PropertyType $ValueType 1>$null
            Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Create] Key $($RegistryKey) with value $($RegistryValue) of type $($ValueType)"
        }
    }
}

Function Add-Detection() {
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [String]
    $errorlevel
)

# Write results to registry for Intune Detection
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
#endregion

#Variables
$exitstatus=0
$name="ADTDevice"
$version="1.0"
$logFile=$name + "-" + $version + ".log"
$key='HKEY_LOCAL_MACHINE\SOFTWARE\Intune\' + $name

#Start logging
Start-Transcript "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\$logfile"
Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Start]"
Add-Detection -errorlevel 55

If($Install){

    if($LXP){
        try{
        #Disable Language Pack Cleanup (do not re-enable)
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Disable Scheduled Task"
        Disable-ScheduledTask -TaskPath "\Microsoft\Windows\AppxDeploymentClient\" -TaskName "Pre-staged app cleanup" #| Out-Null

        Write-Output "[Info] $(Get-Date -Format "dd/MM HH:mm") Install-language started"
        Install-Language nl-NL
        #Write-Output "[Info] $(Get-Date -Format "dd/MM HH:mm") Set Location NL"
        #Set-WinHomeLocation -GeoId 176
        Write-Output "[Info] $(Get-Date -Format "dd/MM HH:mm") Set-SystemPreferredUILanguage"
        Set-SystemPreferredUILanguage nl-NL
        Write-Output "[Info] $(Get-Date -Format "dd/MM HH:mm") Install-language finished"

        #Prepare Recovery
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] XML started"
        #Variables Language XML
        $InputLocale="0409:00020409"
        $SystemLocale="en-US"
        $TimeZone="W. Europe Standard Time"

        If (Test-Path "C:\Recovery\AutoApply"){}Else{
            New-Item -Path "C:\Recovery\" -Name "AutoApply" -ItemType "directory"
            Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] AutoApply Directory Created"
        }

        If (Test-Path "C:\Recovery\AutoApply\OOBE"){}Else{
            New-Item -Path "C:\Recovery\AutoApply" -Name "OOBE" -ItemType "directory"
            Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] OOBE Directory Created"
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
          $XmlObjectWriter.WriteStartElement('settings')
            $XmlObjectWriter.WriteAttributeString("pass", "oobeSystem")
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
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Unattend XML Created"

        #Create & Set The Formatting with XmlWriterSettings class
        $xmlObjectsettings2 = New-Object System.Xml.XmlWriterSettings
        #Indent: Sets a value indicating whether to indent elements.
        $xmlObjectsettings2.Indent = $true
        #Sets the character string to use when indenting. This setting is used when the Indent property is set to true.
        $xmlObjectsettings2.IndentChars = "`t"
 
        #Set the File path & Create the XML
        $XmlFilePath2 = "C:\Recovery\AutoApply\OOBE\OOBE.xml"
        $XmlObjectWriter2 = [System.XML.XmlWriter]::Create($XmlFilePath2, $xmlObjectsettings2)

        #Write the XML
        $XmlObjectWriter2.WriteStartDocument()
        $XmlObjectWriter2.WriteStartElement('FirstExperience')
            $XmlObjectWriter2.WriteStartElement('oobe')
                $XmlObjectWriter2.WriteStartElement('defaults')
                    $XmlObjectWriter2.WriteElementString("language",'1033')
                    $XmlObjectWriter2.WriteElementString("location",'176')
                    $XmlObjectWriter2.WriteElementString("keyboard",'0409:00000409')
                $XmlObjectWriter2.WriteEndElement()
            $XmlObjectWriter2.WriteEndElement()
        $XmlObjectWriter2.WriteEndElement()
        $XmlObjectWriter2.WriteEndDocument()
        $XmlObjectWriter2.Flush()
        $XmlObjectWriter2.Close()
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] OOBE XML Created"

        #Load Default User Hive to change language for all Users
        Reg Load "HKEY_LOCAL_MACHINE\MDU" "C:\Users\Default\NTUser.dat"
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Registry Hive DefaultUser loaded as MDU"

        #Load JSON
        $JSONFile = "$PSScriptRoot\Language\intlnl.json"
        $RegKeys = Get-Content -Raw $JSONFile | ConvertFrom-Json

        #Write Language Settings
        Foreach($Key in $RegKeys){
            Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Processing $($Key.Name)"
            Add-RegistryKey -HKEY $Key.HKEY -RegistryPath $Key.RegistryPath -RegistryKey $Key.RegistryKey -RegistryValue $Key.RegistryValue -ValueType $Key.ValueType
        }

        #Unload Default User Hive
        [GC]::Collect()
        Start-Sleep -Seconds 3
        Reg Unload "HKEY_LOCAL_MACHINE\MDU"
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Registry Hive DefaultUser unloaded as MDU"

        #Remove unattend.xml from Panther
        If (Test-Path "C:\Windows\Panther\unattend.xml"){
            Remove-Item -Path C:\Windows\Panther\unattend.xml -Force
            Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Unattend removed"
        }Else{  
            Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Unattend not found"
        }

        #set Exit
        $exitstatus=0

        }Catch{
        Write-Output "[Error] $(Get-Date -Format "dd/MM HH:mm") Install NL failed"
        $exitstatus=1
        }
    }

    if($Profile){
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Profile Setup"
        
        #Set Default Registry
        $JSONFile = "$PSScriptRoot\Profile\Profile.json"
        $RegKeys = Get-Content -Raw $JSONFile | ConvertFrom-Json
        Reg Load "HKEY_LOCAL_MACHINE\MDU" "C:\Users\Default\NTUser.dat"

        Foreach($Key in $RegKeys){
            Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Processing $($Key.Name)"
            Add-RegistryKey -HKEY $Key.HKEY -RegistryPath $Key.RegistryPath -RegistryKey $Key.RegistryKey -RegistryValue $Key.RegistryValue -ValueType $Key.ValueType
        }

        [GC]::Collect()
        Start-Sleep -Seconds 3
        Reg Unload "HKEY_LOCAL_MACHINE\MDU"

        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [End] Profile Setup"
        $exitstatus=0
    }

    if($Appx){
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Start] Remove built-in AppxProvisioningPackage process"
        [string[]]$RemoveApps = Get-Content -Path "$PSScriptRoot\Appx\AppxProvisionedPackage.txt"
        $AppList = Get-AppxProvisionedPackage -Online | Select-Object -Property DisplayName, PackageName | Sort-Object -Property DisplayName

        foreach ($App in $AppList) {
            
            if (($App.DisplayName -in $RemoveApps)){

                    $AppProvisioningPackageName = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $App.DisplayName } | Select-Object -ExpandProperty PackageName
        
                if ($AppProvisioningPackageName -ne $null) {
                    try {
                        Remove-AppxProvisionedPackage -PackageName $AppProvisioningPackageName -Online -ErrorAction Stop | Out-Null
                        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] $($AppProvisioningPackageName)"
                    }
                    catch [System.Exception] {
                        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Warning] Removing AppxProvisioningPackage '$($AppProvisioningPackageName)' failed: $($_.Exception.Message)"
                    }
                }
                else {
                        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Error] Unable to locate AppxProvisioningPackage: $($AppProvisioningPackageName)"
                }
            }
            else{
                Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Skip] Excluded application package: $($App.DisplayName)" -InformationAction Continue
            }
        }

        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Remove built-in AppxProvisioningPackage process"
        $exitstatus=0
    }
    
    if($RemoveCapability){
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Remove Windows Capability process"
        [string[]]$RemoveCapability = Get-Content -Path "$PSScriptRoot\Capability\RemoveCapability.txt"
        $CapabilityList = Get-WindowsCapability -Online | Where-Object State -eq 'Installed' | Select-Object -Property Name | Sort-Object -Property Name

        foreach ($xCapability in $CapabilityList) {

            if (($xCapability.Name -notin $RemoveCapability)) {
                Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Skip] Excluded Windows Capability: $($xCapability.Name)"
            }
            else {
                $CapabilityName = Get-WindowsCapability -Online | Where-Object { $_.Name -like $xCapability.Name } | Select-Object -ExpandProperty Name
        
                if ($CapabilityName -ne $null) {
                    try {
                        Remove-WindowsCapability -Online -Name $CapabilityName | Out-Null
                        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Removed Windows Capability: $($CapabilityName)"
                    }
                    catch [System.Exception] {
                        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Warning] Removing Windows Capability '$($CapabilityName)' failed: $($_.Exception.Message)"
                    }
                }
                else {
                    Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Error] Unable to locate Windows Capability: $($CapabilityName)"
                }
            }
        }

        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Remove Windows Capability process"
        $exitstatus=0
    }

    if($RemoveFeatures){
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Remove Optional Features process"
        [string[]]$DisableFeature = Get-Content -Path "$PSScriptRoot\Features\RemoveOptionalFeature.txt"
        $FeatureList = Get-WindowsOptionalFeature -Online | Where-Object State -eq 'Enabled' | Select-Object -Property FeatureName | Sort-Object -Property FeatureName

        foreach ($Feature in $FeatureList) {

            if (($Feature.FeatureName -notin $DisableFeature)) {
                Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Skip] Excluded Windows Feature: $($Feature.FeatureName)"
            }
            else {
                $FeatureName = Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -like $Feature.FeatureName } | Select-Object -ExpandProperty FeatureName
        
                if ($FeatureName -ne $null) {
                    try {
                        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Removed Windows Feature: $($FeatureName)"
                        Disable-WindowsOptionalFeature -Online -FeatureName $FeatureName -NoRestart | Out-Null
                    }
                    catch [System.Exception] {
                        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Warning] Removing Windows Feature '$($FeatureName)' failed: $($_.Exception.Message)"
                    }
                }
                else {
                        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Error] Unable to locate Windows Feature: $($FeatureName)"
                }
            }
        }

        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Remove Optional Features process"
        $exitstatus=0
    }

    if($AddFeatures){
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Add Optional Features process"
        [string[]]$EnableFeatures = Get-Content -Path "$PSScriptRoot\Features\EnableOptionalFeature.txt"

        foreach($EnableFeature in $EnableFeatures){
            Enable-WindowsOptionalFeature -Online -FeatureName $EnableFeature -NoRestart 1>$null
            Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Installed Feature: $($Feature)"
        }

        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [End] Add Optional Features process"
        $exitstatus=0
    }

    if($Update){
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Updates Starting"
        $updateSession = new-object -com "Microsoft.Update.Session"
        $updates=$updateSession.CreateupdateSearcher().Search($criteria).Updates

        if ($Updates.Count -eq 0)  {Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] There are no applicable updates."}   
        else {

            $downloader = $updateSession.CreateUpdateDownloader()   
            $downloader.Updates = $Updates
            $Result= $downloader.Download()  
            if (($Result.Hresult -eq 0) –and (($result.resultCode –eq 2) -or ($result.resultCode –eq 3)) ) {

                $updatesToInstall = New-object -com "Microsoft.Update.UpdateColl"
                $Updates | where {$_.isdownloaded} | foreach-Object {$updatesToInstall.Add($_) | out-null }
                $installer = $updateSession.CreateUpdateInstaller()
                $installer.Updates = $updatesToInstall
                $installationResult = $installer.Install()
                $Global:counter=-1
                $installer.updates | Format-Table -autosize -property Title,EulaAccepted,@{label='Result'; expression={$ResultCode[$installationResult.GetUpdateResult($Global:Counter++).resultCode ] }} 
                if ($installationResult.rebootRequired) {Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Reboot needed" }
                }
            }
    }

    if($Bitlocker){
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Bitlocker"
        
        if((Get-BitLockerVolume -MountPoint C).EncryptionPercentage -eq 0){
            Get-BitLockerVolume | Enable-BitLocker -RecoveryPasswordProtector -SkipHardwareTest
            Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Start Encryption"

            Do{
            Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Encryption is at $((Get-BitLockerVolume -MountPoint C).EncryptionPercentage)%"
            Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Waiting for Encryption to finish $(Get-Date -Format HH:mm)"
            Start-Sleep -Seconds 10
            }
            Until ((Get-BitLockerVolume -MountPoint C).EncryptionPercentage -eq 100)
        }
        else {
            Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Encryption is at $((Get-BitLockerVolume -MountPoint C).EncryptionPercentage)%"
        }

        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Bitlocker"
        $exitstatus=0
    }

    if($Files){
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Files"

        #Copy CMTrace
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Copy CMTrace to $($env:windir)"
        Copy-Item $PSScriptRoot\Files\cmtrace.exe "$($env:windir)"
        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Copied CMTrace to $($env:windir)"

        Write-Output "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [Info] Files"
        $exitstatus=0
    }

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
Add-Detection -errorlevel $exitstatus
EXIT $exitstatus