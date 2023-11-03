# Checking if 7zip or WinRAR are installed
# Check 7zip install path on registry
$7zipinstalled = $false 
if ((Test-path HKLM:\SOFTWARE\7-Zip\) -eq $true) {
    $7zpath = Get-ItemProperty -path  HKLM:\SOFTWARE\7-Zip\ -Name Path
    $7zpath = $7zpath.Path
    $7zpathexe = $7zpath + "7z.exe"
    if ((Test-Path $7zpathexe) -eq $true) {
        $archiverProgram = $7zpathexe
        $7zipinstalled = $true 
    }    
    
    Write-Host "So, 7z ? "
    Write-Host $7zpath
}
elseif ($7zipinstalled -eq $false) {
    if ((Test-path HKLM:\SOFTWARE\WinRAR) -eq $true) {
        $winrarpath = Get-ItemProperty -Path HKLM:\SOFTWARE\WinRAR -Name exe64 
        $winrarpath = $winrarpath.exe64
        if ((Test-Path $winrarpath) -eq $true) {
            $archiverProgram = $winrarpath
        }
        
        Write-Host "So, winrar ? "
        Write-Host $winrarpath
    }
    else {
        Write-Host "Sorry, but it looks like you don't have a supported archiver."
        Write-Host ""
        # Download and silently install 7-zip if the user presses y
        $7zip = "https://www.7-zip.org/a/7z1900-x64.exe"
        $output = "$PSScriptRoot\7Zip.exe"
        (New-Object System.Net.WebClient).DownloadFile($7zip, $output)
    
        Start-Process "7Zip.exe" -Wait -ArgumentList "/S"
        # Delete the installer once it completes
        Remove-Item "$PSScriptRoot\7Zip.exe"
        
        $7zpath = Get-ItemProperty -path  HKLM:\SOFTWARE\7-Zip\ -Name Path
        $7zpath = $7zpath.Path
        $7zpathexe = $7zpath + "7z.exe"
        if ((Test-Path $7zpathexe) -eq $true) {
            $archiverProgram = $7zpathexe
            $7zipinstalled = $true 
        }

        Write-Host "So, 7z ? "
        Write-Host $7zpath
    }
}
else {
    Write-Host "Sorry, but it looks like you don't have a supported archiver."
    Write-Host ""
    # Download and silently install 7-zip if the user presses y
    $7zip = "https://www.7-zip.org/a/7z1900-x64.exe"
    $output = "$PSScriptRoot\7Zip.exe"
    (New-Object System.Net.WebClient).DownloadFile($7zip, $output)
    
    Start-Process "7Zip.exe" -Wait -ArgumentList "/S"
    # Delete the installer once it completes
    Remove-Item "$PSScriptRoot\7Zip.exe"
    
    $7zpath = Get-ItemProperty -path  HKLM:\SOFTWARE\7-Zip\ -Name Path
    $7zpath = $7zpath.Path
    $7zpathexe = $7zpath + "7z.exe"
    if ((Test-Path $7zpathexe) -eq $true) {
        $archiverProgram = $7zpathexe
        $7zipinstalled = $true 
    }

    Write-Host "So, 7z ? "
    Write-Host $7zpath
}

# Downloading the installer
$nvidiaTempFolder = "C:\NVIDIA"
New-Item -Path $nvidiaTempFolder -ItemType Directory 2>&1 | Out-Null

$url = "https://us.download.nvidia.com/tesla/537.70/537.70-data-center-tesla-desktop-win10-win11-64bit-dch-international.exe"

$dlFile = "$nvidiaTempFolder\nvidiaDriver.exe"
Write-Host "Downloading the latest version to $dlFile"
Start-BitsTransfer -Source $url -Destination $dlFile

if ($?) {
    Write-Host "Proceed..."
}
else {
    Write-Host "Download failed"
    #ping api about error
}


# Extracting setup files
$extractFolder = "$nvidiaTempFolder\nvidiaDriver"
$filesToExtract = "Display.Driver HDAudio NVI2 PhysX EULA.txt ListDevices.txt setup.cfg setup.exe"
Write-Host "Download finished, extracting the files now..."

if ($7zipinstalled) {
    Start-Process -FilePath $archiverProgram -NoNewWindow -ArgumentList "x -bso0 -bsp1 -bse1 -aoa $dlFile $filesToExtract -o""$extractFolder""" -wait
}
elseif ($archiverProgram -eq $winrarpath) {
    Start-Process -FilePath $archiverProgram -NoNewWindow -ArgumentList 'x $dlFile $extractFolder -IBCK $filesToExtract' -wait
}
else {
    Write-Host "Something went wrong. No archive program detected. This should not happen."
    Write-Host "Press any key to exit..."
    # ping api about error
    exit
}


# Remove unneeded dependencies from setup.cfg
(Get-Content "$extractFolder\setup.cfg") | Where-Object { $_ -notmatch 'name="\${{(EulaHtmlFile|FunctionalConsentFile|PrivacyPolicyFile)}}' } | Set-Content "$extractFolder\setup.cfg" -Encoding UTF8 -Force

Write-Host "Installing Nvidia drivers now..."
$install_args = "-passive -noreboot -noeula -nofinish -s"
if ($clean) {
    $install_args = $install_args + " -clean"
}
Start-Process -FilePath "$extractFolder\setup.exe" -ArgumentList $install_args -wait

# ping api about success

Write-Host "Nvidia Drivers Installed."

# Nvidia Grid
Write-Host "Installing GRID Drivers"

# Downloading the installer
$nvidiaTempFolder = "C:\NVIDIA"
New-Item -Path $nvidiaTempFolder -ItemType Directory 2>&1 | Out-Null

$url = "https://go.microsoft.com/fwlink/?linkid=874181"

$dlFile = "$nvidiaTempFolder\nvidiaGridDriver.exe"
Write-Host "Downloading the latest version to $dlFile"
Start-BitsTransfer -Source $url -Destination $dlFile

if ($?) {
    Write-Host "Proceed..."
}
else {
    Write-Host "Download failed"
    #ping api about error
}


# Extracting setup files
$extractFolder = "$nvidiaTempFolder\nvidiaGridDriver"
$filesToExtract = "Display.Driver Display.Nview MSVCRT NVI2 EULA.txt setup.cfg setup.exe"
Write-Host "Download finished, extracting the files now..."

if ($7zipinstalled) {
    Start-Process -FilePath $archiverProgram -NoNewWindow -ArgumentList "x -bso0 -bsp1 -bse1 -aoa $dlFile $filesToExtract -o""$extractFolder""" -wait
}
elseif ($archiverProgram -eq $winrarpath) {
    Start-Process -FilePath $archiverProgram -NoNewWindow -ArgumentList 'x $dlFile $extractFolder -IBCK $filesToExtract' -wait
}
else {
    Write-Host "Something went wrong. No archive program detected. This should not happen."
    Write-Host "Press any key to exit..."
    # ping api about error
    exit
}


# Remove unneeded dependencies from setup.cfg
#(Get-Content "$extractFolder\setup.cfg") | Where-Object { $_ -notmatch 'name="\${{(EulaHtmlFile|FunctionalConsentFile|PrivacyPolicyFile)}}' } | Set-Content "$extractFolder\setup.cfg" -Encoding UTF8 -Force

Write-Host "Installing GRID Nvidia drivers now..."
$install_args = "-passive -noreboot -noeula -nofinish -s"
if ($clean) {
    $install_args = $install_args + " -clean"
}
Start-Process -FilePath "$extractFolder\setup.exe" -ArgumentList $install_args -wait

# ping api about success

Write-Host "NVidia Grid Installed."
