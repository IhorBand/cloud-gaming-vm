param (
    [string]$admin_username = "",
    [string]$admin_password = ""
)

# Define the file path
$filePath = "C:\vm-script-parameters.txt"

# Define the content you want to write
$content = "$admin_username|$admin_password"

# Use Set-Content to create and write to the file
Set-Content -Path $filePath -Value $content

function Get-UtilsScript ($script_name) {
    $url = "https://raw.githubusercontent.com/IhorBand/cloud-gaming-vm/main/$script_name"
    Write-Host "Downloading utils script from $url"
    [Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

    $webClient = new-object System.Net.WebClient
    $webClient.DownloadFile($url, "C:\$script_name")
}

$script_name = "utils.psm1"
Get-UtilsScript $script_name
Import-Module "C:\$script_name"

Download-To "https://raw.githubusercontent.com/IhorBand/cloud-gaming-vm/main/prepareuranus.ps1" "C:\prepareuranus.ps1"

# Define the destination folder path (Startup folder)
$destinationFolderPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::CommonStartMenu), "Programs\Startup")
# Build the full destination path including the filename
$destinationFilePath = [System.IO.Path]::Combine($destinationFolderPath, 'start_prepareuranus.bat')
Download-To "https://raw.githubusercontent.com/IhorBand/cloud-gaming-vm/main/start_prepareuranus.bat" $destinationFilePath

Restart-Computer
