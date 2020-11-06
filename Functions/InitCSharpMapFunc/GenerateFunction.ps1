##Config BELOW!
#################################################################################

#Complete output directory
$repoRootFolder = "C:\Repos\EMP-Employee2\"

#Function App information
$functionAppName = "INT-Employee-IN-P-MapEmployeeAllocationIVUSJOToSPBSJson"
#Default functionName = Transform. Change this if you wish
$functionName = "Transform"

#Azure Information
$businessobject = "Employee"

##Config ABOVE!
#################################################################################

$CurrentPath = Get-Location
cd $PSScriptRoot
# Run this command to generate Azure ARM templates 
./Function/initFunction.ps1 $repoRootFolder $functionAppName $functionName $businessobject
cd $CurrentPath