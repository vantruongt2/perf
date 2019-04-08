###################################################################################################

#
<##################################################################################################

    Description
    ===========

	Start/stop a Lab VM given its resource ID.

##################################################################################################>


[CmdletBinding()]
Param(
	$LabVMId,
	$JsonFile,
	$ActionVM
)

###################################################################################################

#
# PowerShell configurations
#

# NOTE: Because the $ErrorActionPreference is "Stop", this script will stop on first failure.
#       This is necessary to ensure we capture errors inside the try-catch-finally block.
$ErrorActionPreference = "Stop"

# Ensure we set the working directory to that of the script.
pushd $PSScriptRoot

###################################################################################################

#
# Functions used in this script.
#

.".\task-funcs.ps1"

###################################################################################################

#
# Handle all errors in this script.
#

trap
{
    # NOTE: This trap will handle all errors. There should be no need to use a catch below in this
    #       script, unless you want to ignore a specific error.
    Handle-LastError
}

###################################################################################################

#
# Main execution block.
#

try
{
    Write-Host "Starting Azure DevTest Labs '$ActionVM' VM Task"
	# If "LabVMId" parameter is exist, Start VM from this id
	if ($PSBoundParameters.ContainsKey('LabVMId')){
		Invoke-AzureTask -LabVMId "$LabVMId" -ActionVM "$ActionVM"
	}
	# If "LabVMId" parameter is not exist and "JsonFile" parameter is exist, start VM with information from Json file
	elseif ($PSBoundParameters.ContainsKey('JsonFile')){
		Invoke-AzureTaskFromJSON -JsonFile "$JsonFile" -ActionVM "$ActionVM"
	}
	# If "LabVMId" parameter is not exist and "JsonFile" parameter is not exist, print the information
	else{
		Write-Host "Please use agrument 'LabVMId' or 'JsonFile'"
	}

    Write-Host "Completing Azure DevTest Labs '$ActionVM' VM Task"
}
finally
{
    popd
}
