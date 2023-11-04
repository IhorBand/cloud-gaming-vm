# Load the System.Web assembly for JavaScriptSerializer
Add-Type -AssemblyName System.Web

$tempJsonData = @"
[
	"See https://parsec.app/config for documentation and example. JSON must be valid before saving or file be will be erased.",
	{
		"encoder_bitrate": {
			"value": 50
		},
		"host_virtual_microphone": {
			"value": 1
		}
	}
]
"@

try {
    $parsecConfigPath = "C:\ProgramData\Parsec\config.json"

    # Check if the file exists
    if (-not (Test-Path -Path $parsecConfigPath)) {
        # Create the file and its parent folders
        $null = New-Item -Path $parsecConfigPath -ItemType File
        Set-Content -Path $parsecConfigPath -Value $tempJsonData
    }


    # Read the JSON configuration file
    $jsonData = Get-Content -Path $parsecConfigPath -Raw

    # Create a JavaScriptSerializer object
    $serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer

    # Deserialize the JSON data into a PowerShell object
    $configuration = $serializer.DeserializeObject($jsonData)

    # Check if the "host_virtual_microphone" property exists
    if ($configuration[1]."host_virtual_microphone") {
        # Property exists, check the "value"
        if ($configuration[1]."host_virtual_microphone".value -ne 1) {
            # Set "value" to 1
            $configuration[1]."host_virtual_microphone".value = 1
        }
    } else {
        # Property doesn't exist, add it with "value" set to 1
        $configuration[1]."host_virtual_microphone" = @{
            value = 1
        }
    }

    # Serialize the modified object back to JSON
    $jsonData = $serializer.Serialize($configuration)

    # Write the modified JSON back to the file
    Set-Content -Path $parsecConfigPath -Value $jsonData
    Write-Output "Parsec Microphone turned on."
}
catch {
    Write-Host "An error occurred: $_"
}