##Config BELOW!
#################################################################################

#Repo output directory
    $repoRootFolder = "C:\Repos\Report\"

#Function App information
    $functionAppName = "INT-Report-OUT-P-MapXODReports"

#Default functionName = Transform. Change this if you wish
    $functionName = "Transform"

#Azure Information
    $businessobject = "Common"

##Config ABOVE!
#################################################################################

#Execute script
. "$PSScriptRoot\Resources\GenerateFunction\initFunction.ps1" $repoRootFolder $functionAppName $functionName $businessobject