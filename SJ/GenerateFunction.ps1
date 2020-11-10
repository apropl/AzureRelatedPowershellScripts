##Config BELOW!
#################################################################################

#Repo output directory
    $repoRootFolder = "C:\Repos\Report\"

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

#Execute script
./Resources/GenerateFunction/initFunction.ps1 $repoRootFolder $functionAppName $functionName $businessobject

cd $CurrentPath