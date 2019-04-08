Param(
    [Parameter()]
    [string] $envName,
	[Parameter()]
    [string] $envValue
)
 Write-Output "Environment name: " + $envName
 Write-Output "Environment value: " + $envValue

 [System.Environment]::SetEnvironmentVariable($envName, $envValue, "Machine")