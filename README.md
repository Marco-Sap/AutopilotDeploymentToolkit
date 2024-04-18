# Autopilot Deployment Toolkit
    
    Create Win32App
    C:\IntuneApp\IntuneWinAppUtil.exe -c "C:\IntuneApp\ADTDevice" -s Invoke-ADTDevice.ps1 -o C:\IntuneApp -q

    Install Command examples: 
    C:\Windows\SysNative\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Bypass -File .\Invoke-ADTDevice.ps1 -Install -LXP -Profile -Appx -RemoveCapability -RemoveFeatures -AddFeatures -Update -Bitlocker -Files

    C:\Windows\SysNative\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Bypass -File .\Invoke-ADTDevice.ps1 -Install -Appx

    C:\Windows\SysNative\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Bypass -File .\Invoke-ADTDevice.ps1 -Install -LXP -Profile -Files
    
    Uninstall Command example:
    C:\Windows\SysNative\WindowsPowerShell\v1.0\Powershell.exe -ExecutionPolicy Bypass -File .\Invoke-ADTDevice.ps1 -Uninstall

    Detection rule:
    Manual configure detection rules
    Rule Type: Registry
    Key path: Computer\HKEY_LOCAL_MACHINE\Software\Intune\ADTDevice
    Value name: 1.0-Success
    Detection methode: Value exists
