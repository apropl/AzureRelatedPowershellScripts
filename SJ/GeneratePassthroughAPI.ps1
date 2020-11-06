##Config BELOW!
#################################################################################

#Complete output directory
    $repoRootFolder = "C:\Repos\Report"

#API information
    $Internal = $true
    $apiName = "INT-Train-OUT-S-StaffDeviations-AvikSJO2"
    $operation = "post" #post or get for example

#Internal APIM	[outbound/]idp[/e|s][/system]/integration
#External APIM	public/idp[/e|s][/system]/integration
    $apiBasePath = "outbound/idp/avik/StaffDeviations2"

#Sepcify which templates to use
#1 = Logic app
#2 = Function app
#3 = Backend URL
    $Template = 3

###################### 1 - LOGIC APP ######################
#Logic App ( Complete name/rg to DEV )
    $logicAppName = "LogicAppName"
    $logicAppResourceGroup = "ResourceGroupName"

###################### 2 - FUNCTION APP ###################
#Function App ( Complete name/rg to DEV )
    $functionAppName = "int-common-messagerouter-dev-fa"
    $functionAppResourceGroup = "NordIntegration-dev-adp-rg"
    $functionAppPath = "/api/servicebus/topic/sendmsg"

###################### 3 - URL BACKEND ###################
#Set service URL to each environment
    $backendServiceURLdev = "http://testing.com"
    $backendServiceURLtest = "N/A"
    $backendServiceURLqa = "N/A"
    $backendServiceURLprod = "N/A"

##Config ABOVE!
#################################################################################

$CurrentPath = Get-Location
cd $PSScriptRoot
# Run this command to generate Azure ARM templates 
./Resources/GeneratePassthroughAPI/passthroughAPI.ps1 $repoRootFolder $Internal $apiName $operation $apiBasePath $Template $logicAppName $logicAppResourceGroup $functionAppName $functionAppResourceGroup $functionAppPath $backendServiceURLdev $backendServiceURLtest $backendServiceURLqa $backendServiceURLprod
cd $CurrentPath