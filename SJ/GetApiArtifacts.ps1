

# Set the name of the API Mangement instance
$apimanagementname = 'adp-apimgmt-azure-dev' # adp-apimgmt-azure-dev or adp-apimgmt-se-dev
#$apimanagementname = 'adp-apimgmt-se-dev' # adp-apimgmt-azure-dev or adp-apimgmt-se-dev

# Name of the API in API Management
$apiname = "INT-DataCache-IO-S-Trafikverket"
    
# Location to save output files to
$repoRootFolder = 'C:\Repos\Report2'

$CurrentPath = Get-Location
cd $PSScriptRoot
# Run this command to generate Azure ARM templates 
./Resources/GetApiArtifacts/Get-ApiManagementTemplateAZ.ps1 $apimanagementname $apiname $repoRootFolder

# Run this command to generate Azure DevOps Build & Deploy pipelines
# This prints an Azure CLI command you can run to create the pipeline in Azure DevOps, after you have
#   manually reviewed what's been created, adjusted parameter files, and checked-in the code
./Resources/GetApiArtifacts/Get-ApiManagementPipeline.ps1 $apimanagementname $apiname $repoRootFolder

cd $CurrentPath

# Further improvements
#   Generate base template for Namedvalues also? "base" = list of named values and if they are secrect or not (secret = should come from KeyVault) - must first create a dev template with tokens to replace
#   Generate base tempalte for ProductAndSubscriptions = named product, this API and a named subscription - must first create a dev template with tokens to replace
#   (These two things will be most valuable when first creating a new API for a new system)

