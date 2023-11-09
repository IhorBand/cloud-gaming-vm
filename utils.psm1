[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$webClient = new-object System.Net.WebClient

function Disable-InternetExplorerESC {
    # From https://stackoverflow.com/questions/9368305/disable-ie-security-on-windows-server-via-powershell
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force
    Stop-Process -Name Explorer -Force
    Write-Output "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}

function Update-Windows {
    $url = "https://gallery.technet.microsoft.com/scriptcenter/Execute-Windows-Update-fc6acb16/file/144365/1/PS_WinUpdate.zip"
    $compressed_file = "PS_WinUpdate.zip"
    $update_script = "PS_WinUpdate.ps1"

    Write-Output "Downloading Windows Update Powershell Script from $url"
    $webClient.DownloadFile($url, "C:\$compressed_file")
    Unblock-File -Path "C:\$compressed_file"

    Write-Output "Extracting Windows Update Powershell Script"
    Expand-Archive "C:\$compressed_file" -DestinationPath "C:\" -Force

    Write-Output "Running Windows Update"
    Invoke-Expression C:\$update_script
}

function Update-Firewall {
    Write-Output "Enable ICMP Ping in Firewall."
    Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -Enabled True
}

function Disable-Defender {
    Write-Output "Disable Windows Defender real-time protection."
    Set-MpPreference -DisableRealtimeMonitoring $true
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord
}

function Disable-ScheduledTasks {
    Write-Output "Disable unnecessary scheduled tasks"
    Disable-ScheduledTask -TaskName 'ScheduledDefrag' -TaskPath '\Microsoft\Windows\Defrag'
    Disable-ScheduledTask -TaskName 'ProactiveScan' -TaskPath '\Microsoft\Windows\Chkdsk'
    Disable-ScheduledTask -TaskName 'Scheduled' -TaskPath '\Microsoft\Windows\Diagnosis'
    Disable-ScheduledTask -TaskName 'SilentCleanup' -TaskPath '\Microsoft\Windows\DiskCleanup'
    Disable-ScheduledTask -TaskName 'WinSAT' -TaskPath '\Microsoft\Windows\Maintenance'
    Disable-ScheduledTask -TaskName 'Windows Defender Cache Maintenance' -TaskPath '\Microsoft\Windows\Windows Defender'
    Disable-ScheduledTask -TaskName 'Windows Defender Cleanup' -TaskPath '\Microsoft\Windows\Windows Defender'
    Disable-ScheduledTask -TaskName 'Windows Defender Scheduled Scan' -TaskPath '\Microsoft\Windows\Windows Defender'
    Disable-ScheduledTask -TaskName 'Windows Defender Verification' -TaskPath '\Microsoft\Windows\Windows Defender'
}

function Edit-VisualEffectsRegistry {
    Write-Output "Adjust performance options in registry"
    New-Item -Path "Registry::\HKEY_USERS\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    Set-ItemProperty -Path "Registry::\HKEY_USERS\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2
}

function Disable-TCC {
    $nvsmi = "C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe"
    $gpu = & $nvsmi --format=csv,noheader --query-gpu=pci.bus_id
    & $nvsmi -g $gpu -fdm 0
}

function Enable-Audio {
    Write-Output "Enabling Audio Service"
    Set-Service -Name "Audiosrv" -StartupType Automatic
    Start-Service Audiosrv
}

function Install-VirtualAudio {
    $compressed_file = "VBCABLE_Driver_Pack43.zip"
    $driver_folder = "VBCABLE_Driver_Pack43"
    $driver_inf = "vbMmeCable64_win7.inf"
    $hardward_id = "VBAudioVACWDM"

    Write-Output "Downloading Virtual Audio Driver"
    $webClient.DownloadFile("https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack43.zip", "C:\$compressed_file")
    Unblock-File -Path "C:\$compressed_file"

    Write-Output "Extracting Virtual Audio Driver"
    Expand-Archive "C:\$compressed_file" -DestinationPath "C:\$driver_folder" -Force

    $wdk_installer = "wdksetup.exe"
    $devcon = "C:\Program Files (x86)\Windows Kits\10\Tools\x64\devcon.exe"

    Write-Output "Downloading Windows Development Kit installer"
    $webClient.DownloadFile("http://go.microsoft.com/fwlink/p/?LinkId=526733", "C:\$wdk_installer")

    Write-Output "Downloading and installing Windows Development Kit"
    Start-Process -FilePath "C:\$wdk_installer" -ArgumentList "/S" -Wait

    $cert = "vb_cert.cer"
    $url = "https://raw.githubusercontent.com/IhorBand/cloud-gaming-vm/main/$cert"

    # Write-Output "Downloading vb certificate from $url"
    $webClient.DownloadFile($url, "C:\$cert")

    Write-Output "Importing vb certificate"
    try {
        Import-Certificate -FilePath "C:\$cert" -CertStoreLocation "cert:\LocalMachine\TrustedPublisher"
    }
    catch {
        try {
            $CertificateFullPath = "C:\$cert"
            $CertStorePath = "cert:\LocalMachine\TrustedPublisher"
            if( Get-WMIObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 4 -and ( $_.DeviceID -eq ($CertificateFullPath).Substring(0,2) ) }){
                $CertStore = Get-Item $CertStorePath
                $CertStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]"ReadWrite")
                $CertStore.Add($CertificateFullPath)
                $CertStore.Close()
            }else{
                Import-Certificate -FilePath $CertificateFullPath -CertStoreLocation $CertStorePath
            }
        }
        catch {
            certutil -Enterprise -Addstore "TrustedPublisher" "C:\$cert"
        }
    }



    Write-Output "Installing virtual audio driver"
    Start-Process -FilePath $devcon -ArgumentList "install", "C:\$driver_folder\$driver_inf", $hardward_id -Wait
}

function Install-Chocolatey {
    Write-Output "Installing Chocolatey"
    Invoke-Expression ($webClient.DownloadString('https://chocolatey.org/install.ps1'))
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
    chocolatey feature enable -n allowGlobalConfirmation
}

function Disable-IPv6To4 {
    Set-Net6to4Configuration -State disabled
    Set-NetTeredoConfiguration -Type disabled
    Set-NetIsatapConfiguration -State disabled
}

function Install-NSSM {
    Write-Output "Installing NSSM for launching services that run apps at startup"
    choco install nssm --force
}

function Add-DisconnectShortcut {
    # From https://stackoverflow.com/questions/9701840/how-to-create-a-shortcut-using-powershell
    Write-Output "Create disconnect shortcut on the desktop"

    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\disconnect.lnk")
    $Shortcut.TargetPath = "C:\Windows\System32\tscon.exe"
    $Shortcut.Arguments = "1 /dest:console"
    $Shortcut.Save()
    $ShortcutSecond = $WshShell.CreateShortcut("C:\Users\Public\Desktop\disconnect2.lnk")
    $ShortcutSecond.TargetPath = "C:\Windows\System32\tscon.exe"
    $ShortcutSecond.Arguments = "2 /dest:console"
    $ShortcutSecond.Save()
}

function Add-AutoLogin ($admin_username, $admin_password) {
    Write-Output "Make the password and account of admin user never expire."
    Set-LocalUser -Name $admin_username -PasswordNeverExpires $true -AccountNeverExpires

    Write-Output "Make the admin login at startup."
    $registry = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    Set-ItemProperty $registry "AutoAdminLogon" -Value "1" -type String
    Set-ItemProperty $registry "DefaultDomainName" -Value "$env:computername" -type String
    Set-ItemProperty $registry "DefaultUsername" -Value $admin_username -type String
    Set-ItemProperty $registry "DefaultPassword" -Value $admin_password -type String
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Force
    Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" "NoLockScreen" -Value 1 -type DWord

    #skip privacy settings screen
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" -Name "PrivacyConsentStatus" -Value 1 -PropertyType DWORD -Force 
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" -Name "SkipMachineOOBE" -Value 1 -PropertyType DWORD -Force 
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" -Name "ProtectYourPC" -Value 3 -PropertyType DWORD -Force 
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" -Name "SkipUserOOBE" -Value 1 -PropertyType DWORD -Force 
}

# legacy approach as Parsec still see 2 Displays
function Disable-Devices {
    # $url = "https://gallery.technet.microsoft.com/PowerShell-Device-60d73bb0/file/147248/2/DeviceManagement.zip"
    # $compressed_file = "DeviceManagement.zip"
    # $extract_folder = "DeviceManagement"

    # Write-Output "Downloading Device Management Powershell Script from $url"
    # $webClient.DownloadFile($url, "C:\$compressed_file")
    # Unblock-File -Path "C:\$compressed_file"

    # Write-Output "Extracting Device Management Powershell Script"
    # Expand-Archive "C:\$compressed_file" -DestinationPath "C:\$extract_folder" -Force

    # Import-Module "C:\$extract_folder\DeviceManagement.psd1"

    # Install-PackageProvider -Name NuGet -Force -Confirm:$False
    # Register-PackageSource -provider NuGet -name nugetRepository -location https://www.nuget.org/api/v2
    # Install-Package -Name PSDisableDevice -Force -Confirm:$False 
    # Import-Module PSDisableDevice
    
    # Write-Output "Disabling Hyper-V Video"
    # Get-PnPDevice | Where-Object -Property Name -Like "Microsoft Hyper-V Video" | Disable-PnPDevice -Confirm:$false

    # Write-Output "Disabling Generic PnP Monitor"
    # Get-PnPDevice | Where-Object -Property Name -Like "Generic PnP Monitor" | Where DeviceParent -like "*BasicDisplay*" | Disable-PnPDevice  -Confirm:$false

    # # Define the device name you want to disable
    # $hyperv = "Microsoft Hyper-V Video"

    # # Get the device information for the specified name
    # $device = Get-PnpDevice | Where-Object { $_.Name -eq $hyperv }

    # # Check if the device was found
    # if ($device) {
    #     # Disable the device
    #     Disable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false
    #     Write-Host "Device '$hyperv' has been disabled."
    # } else {
    #     Write-Host "Device '$hyperv' not found."
    # }

    # $pnpgenericmonitor = "Generic PnP Monitor"

    # $device = Get-PnpDevice | Where-Object { $_.Name -eq $pnpgenericmonitor }

    # # Check if the device was found
    # if ($device) {
    #     # Disable the device
    #     Disable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false
    #     Write-Host "Device '$pnpgenericmonitor' has been disabled."
    # } else {
    #     Write-Host "Device '$pnpgenericmonitor' not found."
    # }

    $devcon = "C:\Program Files (x86)\Windows Kits\10\Tools\x64\devcon.exe"

    # Define the device name you want to disable
    $deviceName = "Microsoft Hyper-V Video"

    # Find the device with the specified name
    $device = Get-PnpDevice | Where-Object { $_.Name -eq $deviceName }

    if ($device) {
        # Run devcon to disable the device by its hardware ID
        & $devcon disable $device.HardwareID[0]
        Write-Host "Device '$deviceName' has been disabled."
    } else {
        Write-Host "Device '$deviceName' not found."
    }

#---------------------------------------------------------------------------------------------------------------------
	#uncoment to see what is happening

    # $deviceName = "Generic PnP Monitor"

    # # Find the device with the specified name
    # $device = Get-PnpDevice | Where-Object { $_.Name -eq $deviceName }

    # if ($device) {
    #     # Run devcon to disable the device by its hardware ID
    #     & $devcon disable $device.HardwareID[0]
    #     Write-Host "Device '$deviceName' has been disabled."
    # } else {
    #     Write-Host "Device '$deviceName' not found."
    # }

    #uncomment to see what is happening
#-------------------------------------------------------------------------------------------------------------------

    # Write-Output "Delete the basic display adapter's drivers (since Parsec still see 2 Display adapter)"
    # takeown /f C:\Windows\System32\drivers\BasicDisplay.sys
    # icacls C:\Windows\System32\drivers\BasicDisplay.sys /grant "$env:username`:F"
    # move C:\Windows\System32\drivers\BasicDisplay.sys C:\Windows\System32\Drivers\BasicDisplay.old

    Write-Output "Enabling NvFBC..."
    (New-Object System.Net.WebClient).DownloadFile("https://github.com/nVentiveUX/azure-gaming/raw/master/NvFBCEnable.zip", "C:\NvFBCEnable.zip")
    Expand-Archive -LiteralPath "C:\NvFBCEnable.zip" -DestinationPath "C:\"
    & "C:\NvFBCEnable.exe" -enable -noreset

    Write-Host -ForegroundColor Green "Done."
}

function Install-Steam {
  Write-Host -ForegroundColor Cyan "Starting Install-Steam function..."

  $steam_exe = "steam.exe"
  Write-Output "Downloading steam into path C:\$steam_exe"
  (New-Object System.Net.WebClient).DownloadFile("http://media.steampowered.com/client/installer/SteamSetup.exe", "C:\$steam_exe")
  Write-Output "Installing steam"
  Start-Process -FilePath "C:\$steam_exe" -ArgumentList "/S" -Wait
  Remove-Item -Path "C:\$steam_exe" -Confirm:$false

  Write-Host -ForegroundColor Green "Done."
}

function Install-Parsec {
  Write-Host -ForegroundColor Cyan "Starting Install-Parsec function..."

  $parsec_exe = "parsec-windows.exe"
  Write-Output "Downloading Parsec into path C:\$parsec_exe"
  (New-Object System.Net.WebClient).DownloadFile("https://s3.amazonaws.com/parsec-build/package/parsec-windows.exe", "C:\$parsec_exe")
  Write-Output "Installing Parsec"
  Start-Process -FilePath "C:\$parsec_exe" -ArgumentList "/S /shared" -Wait
  Remove-Item -Path "C:\$parsec_exe" -Confirm:$false

  Write-Host -ForegroundColor Green "Done."
}

function Install-EpicGameLauncher {
  Write-Host -ForegroundColor Cyan "Starting Install-EpicGameLauncher function..."

  $epic_msi = "EpicGamesLauncherInstaller.msi"
  Write-Output "Downloading Epic Games Launcher into path C:\$epic_msi"
  (New-Object System.Net.WebClient).DownloadFile("https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi", "C:\$epic_msi")
  Write-Output "Installing Epic Games Launcher"
  Start-Process -FilePath "C:\$epic_msi" -ArgumentList "/quiet" -Wait
  Remove-Item -Path "C:\$epic_msi" -Confirm:$false

  Write-Host -ForegroundColor Green "Done."
}

function Download-To ($url, $to) {
    Write-Host "Downloading from $url"
    [Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

    $webClient = new-object System.Net.WebClient
    $webClient.DownloadFile($url, $to)
}
