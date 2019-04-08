##################################################################################################>
#
# Parameters to this script file.
#

[CmdletBinding()]
param(
    [string] $PathToJsonFile = 'D:\\workspace\\perf\\src\\perf\\config\\azure\\script\\StartStopVM\\azurevm.json'
)
###################################################################################################
#
# PowerShell configurations
#

# NOTE: Because the $ErrorActionPreference is "Stop", this script will stop on first failure.
#       This is necessary to ensure we capture errors inside the try-catch-finally block.
#$ErrorActionPreference = "Stop"

# Ensure we set the working directory to that of the script.
Push-Location $PSScriptRoot

###################################################################################################
#
# Functions used in this script.
#

. ".\task-funcs.ps1"

###################################################################################################
#
# Handle all errors in this script.
#

trap
{
    # NOTE: This trap will handle all errors. There should be no need to use a catch below in this
    #       script, unless you want to ignore a specific error.
    foreach($err in $error){
        $message = $err.Exception.Message
        if ($message)
        {
            Write-Error "`n$message"
        }
    }
}

###################################################################################################
#
# Main execution block.
#

# Preparing variable that will hold the resource identifier of the lab virtual machine.


Write-Host "Path to json file: $PathToJsonFile"

workflow StopVMs {
    param(
        [string] $LabName,
        [string[]] $VMNames,
        [string] $ResourceGroup
    )
    ForEach -Parallel -ThrottleLimit $VMNames.Count ($VMName in $VMNames)
    {
        try
        {
            (InlineScript { Write-Host "Begin work on '$using:VMName'"})
            # Check VM is started
            $vmStatus = az lab vm show --lab-name $LabName --name $VMName --resource-group $ResourceGroup --expand '"properties($expand=ComputeVm)"' --query 'computeVm.statuses[?code != `null`]|[?starts_with(code,`PowerState`) == `true`].displayStatus' -o tsv
            (InlineScript { Write-Host "'$using:VMName' have current power state is '$using:vmStatus'"})
            if($vmStatus -ne "VM deallocated")
            {
                (InlineScript { Write-Host "'$using:VMName' started. Waiting for stop it"})
                $statusStopped = az lab vm stop --lab-name $LabName --name $VMName --resource-group $ResourceGroup
                $vmStatus = az lab vm show --lab-name $LabName --name $VMName --resource-group $ResourceGroup --expand '"properties($expand=ComputeVm)"' --query 'computeVm.statuses[?code != `null`]|[?starts_with(code,`PowerState`) == `true`].displayStatus' -o tsv
                if ($vmStatus -eq "VM deallocated" -or $vmStatus -eq "VM stopped") {
                    (InlineScript { Write-Host "'$using:VMName' stopped success with result $using:statusStopped."})
                }else{
                    (InlineScript { Write-Host "'$using:VMName' stop fail result $using:statusStopped."})
                }
            }else{
                (InlineScript { Write-Host "'$using:VMName' stopped."})
            }
        }catch
        {
            $ErrorMessage = $_.Exception.Message
            if ($ErrorMessage)
            {
                InlineScript{Write-Warning "`n '$using:VMName' $ErrorMessage"}
            }
        }

    }
}

try
{
    [string] $LabName = ""
    [string[]] $VMNames = ""
    [string] $ResourceGroup = ""
    $json = Get-Content -Raw -Path $PathToJsonFile
	$json | ConvertFrom-Json | Get-ObjectMembers | ForEach-Object {
		$_.Value | Get-ObjectMembers | ForEach-Object {
            # get resource group name
            $ResourceGroup = $_.Key
			$_.Value | Get-ObjectMembers | ForEach-Object {
				$vmid += "/providers/Microsoft.DevTestLab"
				$_.Value | Get-ObjectMembers | ForEach-Object {
					# get lab name
					$LabName = $_.Key
					$_.Value | Get-ObjectMembers | ForEach-Object {
                        $VMNames = $_.Value
						StopVMs -LabName $LabName -ResourceGroup $ResourceGroup -VMName $VMNames
					}
				}
			}
		}
    }
    Write-Host "Stop VMs successfully on all machines of Json file"
}
catch
{
    $ErrorMessage = $error[0].Exception.Message
    if ($ErrorMessage)
    {
        InlineScript{Write-Error "`n '$using:VMName' $ErrorMessage"}
    }
}
finally
{
    Pop-Location
}