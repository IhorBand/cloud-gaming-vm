try {
    # Load the System.Web assembly for JavaScriptSerializer
    Add-Type -AssemblyName System.Web

    # Read the JSON configuration file
    $jsonData = Get-Content -Path 'E:\config.json' -Raw

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
    Set-Content -Path 'E:\config.json' -Value $jsonData
    Write-Output "Parsec Microphone turned on."
}
catch {
    Write-Host "An error occurred: $_"
}