function Handle-LastError
{
    [CmdletBinding()]
    param(
    )

    $message = $error[0].Exception.Message
    if ($message)
    {
        Write-Error "`n$message"
    }
}

function Show-InputParameters
{
    [CmdletBinding()]
    param(
    )

    Write-Host "Task called with the following parameters:"
    Write-Host "  ConnectedServiceName = $ConnectedServiceName"
    Write-Host "  ConnectedServiceNameClassic = $ConnectedServiceNameClassic"
    Write-Host "  LabVMId = $LabVMId"
}
# The function to start/stop one lab VM from DevTestLab
workflow Invoke-AzureTask
{
    [CmdletBinding()]
    param(
        [string] $vmid,
        [string[]] $VMNames,
		[string] $ActionVM
    )
    foreach -parallel -ThrottleLimit $VMNames.Count ($VMName in $VMNames) {
        inlineScript {
            $LabVMId = $using:vmid + "/virtualMachines/" + $using:VMName
            Write-Host "Id of VM: '$LabVMId'"
            Invoke-AzureRmResourceAction -ResourceId $LabVMId -Action $using:ActionVM -Force | Out-Null
            Write-Host "Finish '$using:ActionVM' on '$using:VMName'"
        }
    }
}
# The function to convert Json object to custom object
function Get-ObjectMembers {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [PSCustomObject]$obj
    )
    $obj | Get-Member -MemberType NoteProperty | ForEach-Object {
        $key = $_.Name
        [PSCustomObject]@{Key = $key; Value = $obj."$key"}
    }
}
# The function to start/stop VM from the information in Json file
function Invoke-AzureTaskFromJSON
{
	[CmdletBinding()]
    param(
        $JsonFile,
		$ActionVM
    )
	$json = Get-Content -Raw -Path $JsonFile
	$vmid = ""
	$json | ConvertFrom-Json | Get-ObjectMembers | foreach {
		# get information about subscriptions
		$vmid += "/subscriptions/" + $_.Key
		$_.Value | Get-ObjectMembers | foreach {
			# get name of resource group contain DevTestLab which is started
			$vmid += "/resourcegroups/" + $_.Key
			$_.Value | Get-ObjectMembers | foreach {
				$vmid += "/providers/Microsoft.DevTestLab"
				$_.Value | Get-ObjectMembers | foreach {
					# get lab nam
					$vmid += "/labs/" + $_.Key
					$_.Value | Get-ObjectMembers | foreach {
                        Invoke-AzureTask -vmid $vmid -VMNames $_.Value -ActionVM $ActionVM
					}
				}
			}
		}
	}
}
