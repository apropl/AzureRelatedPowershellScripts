param([string] $apimanagementname, [string] $apiname, [string] $repoRootFolder)

# Install or import API Management Template Creator
$module = resolve-path "$PSScriptRoot\APIManagementARMTemplateCreator\bin\APIManagementTemplate.dll"
Import-Module $module

#if you have problem with execution policy execute this in a administrator runned powershell window.
#Set-ExecutionPolicy -ExecutionPolicy Unrestricted

#Set the subscription id
$subscriptionid = '6c0c26ce-999b-4550-b46d-8084fc33f398' # Always this for SJ Dev/Test
#Set the resource group
$resourcegroup = 'apimgmt-spoke-dev-adp-rg' # Always this for SJ Dev/Test

if ($apimanagementname -eq "adp-apimgmt-azure-dev")
{
    $apimanagementNetworkLocation = "Internal"
}
else # adp-apimgmt-se-dev
{
    $apimanagementNetworkLocation = "External"
}

Write-Host "Acquiring access token."

$context = Get-AzContext

if (!$context -or [string]::IsNullOrEmpty($context.Account)) 
{
    $rmAccount = Connect-AzAccount
    $context = $rmAccount.Context
}

if (!$context -or [string]::IsNullOrEmpty($context.Account))
{
    Write-Host
    Write-Error "Cannot proceed without login."
}
else
{
    $tenantId = (Get-AzSubscription -SubscriptionId $subscriptionid).TenantId
    $tokenCache = $context.TokenCache
    $accessToken = $null
    if (![string]::IsNullOrEmpty($context.TokenCache))
    {
        $cachedTokens = $tokenCache.ReadItems() `
                | where { $_.TenantId -eq $tenantId } `
                | Sort-Object -Property ExpiresOn -Descending
        $accessToken = $cachedTokens[0].AccessToken
    }

    Get-AzSubscription -SubscriptionId $subscriptionid | Select-AzSubscription | Out-Null

    Write-Host
    Write-Host "Ensuring output folder."

    $outputFolder = Join-Path (Join-Path $repoRootFolder API) $apimanagementNetworkLocation
    md -Force $outputFolder | Out-Null

    Write-Host
    Write-Host "Ensuring Api exists."
    
    $ApiMgmtContext = New-AzApiManagementContext -resourcegroup $resourcegroup -ServiceName $apimanagementname
    
    if ($api = Get-AzApiManagementApi -Context $ApiMgmtContext -Name $apiname)
    {
        $filter = "path eq '" + $api.Path + "'"

        Write-Host
        Write-Host "Generating template."

        #Write template files
        Get-APIManagementTemplate -APIFilters $filter -APIManagement $apimanagementname -ResourceGroup $resourcegroup -SubscriptionId $subscriptionid `
            -ExportPIManagementInstance $false -ExportGroups $false -ExportProducts $false -ExportSwaggerDefinition $true -Token $accessToken `
            | Write-APIManagementTemplates -OutputDirectory $outputFolder -SeparatePolicyFile $true -SeparateSwaggerFile $true -GenerateParameterFiles $true `
                -AlwaysAddPropertiesAndBackend $true -MergeTemplates $true -MergeTemplateForLogicAppBackendAndProperties $true

        #Remove files that we are not using
        $loc = Get-Location
        Set-Location $outputFolder
        Get-ChildItem * -Include *.json | Remove-Item

        Set-Location (Join-Path $outputFolder "api-$apiname")

        # Copy/duplicate the parameter file for dev, test, qa, prod
        Copy-Item "api-$apiname.master.parameters.json" -Destination "api-$apiname.master.parameters-test.json"
        Copy-Item "api-$apiname.master.parameters.json" -Destination "api-$apiname.master.parameters-qa.json"
        Copy-Item "api-$apiname.master.parameters.json" -Destination "api-$apiname.master.parameters-prod.json"
        Copy-Item "api-$apiname.master.parameters.json" -Destination "api-$apiname.master.parameters-dev.json"
        Remove-Item -Force -Path "api-$apiname.master.parameters.json"

        # Replace values in the test, qa, prod file --> dev to test/qa/prod, where possible        
        ((Get-Content -path ("api-$apiname.master.parameters-test.json") -Raw) -replace '-dev"','-test"') | Set-Content -Path ("api-$apiname.master.parameters-test.json")
		((Get-Content -path ("api-$apiname.master.parameters-test.json") -Raw) -replace '-dev-','-test-') | Set-Content -Path ("api-$apiname.master.parameters-test.json")
		
        ((Get-Content -path ("api-$apiname.master.parameters-qa.json") -Raw) -replace '-dev"','-qa"') | Set-Content -Path ("api-$apiname.master.parameters-qa.json")
		((Get-Content -path ("api-$apiname.master.parameters-qa.json") -Raw) -replace '-dev-','-qa-') | Set-Content -Path ("api-$apiname.master.parameters-qa.json")
		
        ((Get-Content -path ("api-$apiname.master.parameters-prod.json") -Raw) -replace '-dev"','-prod"') | Set-Content -Path ("api-$apiname.master.parameters-prod.json")
		        ((Get-Content -path ("api-$apiname.master.parameters-prod.json") -Raw) -replace '-dev-','-prod-') | Set-Content -Path ("api-$apiname.master.parameters-prod.json")

        Set-Location $loc

        Write-Host
        Write-Host "Template created."
    }
    else
    {
        Write-Host
        Write-Error "Could not locate Api. Check inputs."
    }
}
