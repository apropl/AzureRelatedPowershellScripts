##Config BELOW!
#################################################################################

#Location to save output files to
    $repoRootFolder = 'C:\Repos\Report'

#Set the resource group
    $resourcegroup = 'integration-common-dev-adp-rg' # Depends on where the Logic Apps is located

#Name of the Business Object the Logic App belongs to
    $bussinessobject = "common"

#Name of the logic app to extract
    $logicapp = "INT-Report-IN-P-ReportTriggerSJO-Avik"

##Config ABOVE!
#################################################################################

$CurrentPath = Get-Location
cd $PSScriptRoot

# Run this command to generate Azure ARM templates 
./Resources/GetLogicAppArtifacts/Get-LogicAppTemplateAZ.ps1 $resourcegroup $logicapp $repoRootFolder

# Run this command to generate Azure DevOps Build & Deploy pipelines
./Resources/GetLogicAppArtifacts/Get-LogicAppPipeline.ps1 $resourcegroup $bussinessobject $logicapp $repoRootFolder $true

cd $CurrentPath