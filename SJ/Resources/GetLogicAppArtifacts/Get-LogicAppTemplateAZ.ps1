

param([string] $resourcegroup, [string] $logicapp, [string] $rootFolder)

# Install or import API Management Template Creator
$module = resolve-path "$PSScriptRoot\LogicAppARMTemplateCreator\bin\LogicAppTemplate.dll"
Import-Module $module

#if you have problem with execution policy execute this in a administrator runned powershell window.
#Set-ExecutionPolicy -ExecutionPolicy Unrestricted

#Set the subscription id
$subscriptionid = '6c0c26ce-999b-4550-b46d-8084fc33f398' # Always this for SJ Dev/Test

Write-Host "Acquiring access token."

$context = Get-AzContext

if (!$context -or [string]::IsNullOrEmpty($context.Account) -or [string]::IsNullOrEmpty($context.TokenCache)) 
{
    $rmAccount = Connect-AzAccount
    $context = $rmAccount.Context
}

if (!$context -or [string]::IsNullOrEmpty($context.Account) -or [string]::IsNullOrEmpty($context.TokenCache))
{
    Write-Host
    Write-Error "Cannot proceed without login."
}
else
{
    $tenantId = (Get-AzSubscription -SubscriptionId $subscriptionid).TenantId
    $tokenCache = $context.TokenCache
    $cachedTokens = $tokenCache.ReadItems() `
            | where { $_.TenantId -eq $tenantId } `
            | Sort-Object -Property ExpiresOn -Descending
    $accessToken = $cachedTokens[0].AccessToken

    Get-AzSubscription -SubscriptionId $subscriptionid | Select-AzSubscription | Out-Null

    Write-Host
    Write-Host "Ensuring output folder."

    $outputFolder = Join-Path (Join-Path $rootFolder LogicApps) $logicapp
    md -Force $outputFolder | Out-Null
    
    Write-Host
    Write-Host "Ensuring Logic App exists."

    if ( $la = Get-AzResource -ResourceType Microsoft.Logic/workflows -ResourceGroupName $resourcegroup -Name $logicapp) 
    {
        Write-Host
        Write-Host "Generating template."

        Get-LogicAppTemplate -LogicApp $logicapp -ResourceGroup $resourcegroup -SubscriptionId $subscriptionid -Token $accessToken -TenantName $tenantId -Verbose | out-file $outputFolder\azuredeploy.json
        Get-ParameterTemplate -TemplateFile $outputFolder\azuredeploy.json | out-file $outputFolder\azuredeploy.parameters.json

        Write-Host
        Write-Host "Template created."
    
        Write-Host
        Write-Host "Creating Visual Studio Project"

        Add-DeploymentVSProject -SourceDir $outputFolder
        
        $loc = Get-Location
        Set-Location $outputFolder


        if (!(Get-Module -ListAvailable -Name "newtonsoft.json")) {
            Install-Module -Name "newtonsoft.json" -Scope CurrentUser -Force
        }

        Import-Module "newtonsoft.json" -Scope Local


        # Remove all _Tag parameters and the workflow tags section in the template file
        $json = (Get-Content azuredeploy.json | Out-String) # read file
        $jsonObj = [Newtonsoft.Json.Linq.JObject]::Parse($json) # parse string
        
        $tags = [System.Collections.ArrayList]@()
        $jsonObj.Item("parameters").GetEnumerator() | ForEach-Object { 
            if ($_.Key.EndsWith('_Tag'))
            {
                $null = $tags.Add($_.Key)
            }
        }
        $tags | ForEach-Object { 
            $null = $jsonObj.Item("parameters").Remove($_)           
        }
        $null = $jsonObj.Item("resources")[0].Remove('tags')

        $newjson = [Newtonsoft.Json.Linq.JObject]::Parse([Newtonsoft.Json.JsonConvert]::SerializeObject($jsonObj))
        $newjson.ToString() | Out-File -Force azuredeploy.json;


        # Remove all parameters ending with _Tag in the parameter files
        $json = (Get-Content azuredeploy.parameters.json | Out-String) # read file
        $jsonObj = [Newtonsoft.Json.Linq.JObject]::Parse($json) # parse string
        
        $tags = [System.Collections.ArrayList]@()
        $jsonObj.Item("parameters").GetEnumerator() | ForEach-Object { 
            if ($_.Key.EndsWith('_Tag'))
            {
                $null = $tags.Add($_.Key)
            }
        }
        if ($tags.Count -gt 0)
        {
            $tags | ForEach-Object { 
                $null = $jsonObj.Item("parameters").Remove($_)           
            }
        }

        $newjson = [Newtonsoft.Json.Linq.JObject]::Parse([Newtonsoft.Json.JsonConvert]::SerializeObject($jsonObj))
        $newjson.ToString() | Out-File -Force azuredeploy.parameters.json;


        # Copy/duplicate the parameter file for dev, test, qa, prod
        # Rename files from azuredeploy.json and azuredeploy.parameters.json to correct names - $logicapp.template.json and $logiapp.parameters-env.json
        Copy-Item "azuredeploy.json" -Destination "$logicapp.template.json"
        Remove-Item -Force -Path "azuredeploy.json"
        Copy-Item "azuredeploy.parameters.json" -Destination "$logicapp.parameters-dev.json"
        Copy-Item "azuredeploy.parameters.json" -Destination "$logicapp.parameters-test.json"
        Copy-Item "azuredeploy.parameters.json" -Destination "$logicapp.parameters-qa.json"
        Copy-Item "azuredeploy.parameters.json" -Destination "$logicapp.parameters-prod.json"
        Remove-Item -Force -Path "azuredeploy.parameters.json"

        # Replace values in the test, qa, prod file --> dev to test/qa/prod, where possible        
		((Get-Content -path ("$logicapp.parameters-test.json") -Raw) -replace '-ise"','-test-ise"') | Set-Content -Path ("$logicapp.parameters-test.json")
        ((Get-Content -path ("$logicapp.parameters-test.json") -Raw) -replace '-dev"','-test"') | Set-Content -Path ("$logicapp.parameters-test.json")
		((Get-Content -path ("$logicapp.parameters-test.json") -Raw) -replace '-dev-','-test-') | Set-Content -Path ("$logicapp.parameters-test.json")
		
		((Get-Content -path ("$logicapp.parameters-qa.json") -Raw) -replace '-ise"','-qa-ise"') | Set-Content -Path ("$logicapp.parameters-qa.json")
        ((Get-Content -path ("$logicapp.parameters-qa.json") -Raw) -replace '-dev"','-qa"') | Set-Content -Path ("$logicapp.parameters-qa.json")
		((Get-Content -path ("$logicapp.parameters-qa.json") -Raw) -replace '-dev-','-qa-') | Set-Content -Path ("$logicapp.parameters-qa.json")
		
		((Get-Content -path ("$logicapp.parameters-prod.json") -Raw) -replace '-ise"','-prod-ise"') | Set-Content -Path ("$logicapp.parameters-prod.json")
        ((Get-Content -path ("$logicapp.parameters-prod.json") -Raw) -replace '-dev"','-prod"') | Set-Content -Path ("$logicapp.parameters-prod.json")
		((Get-Content -path ("$logicapp.parameters-prod.json") -Raw) -replace '-dev-','-prod-') | Set-Content -Path ("$logicapp.parameters-prod.json")

        # Rename and add file name references in file $logicapp.deployproj
        $srcStr = '<Content Include="azuredeploy.json" />\r\n    <Content Include="azuredeploy.parameters.json" />'
        $dstStr = '<Content Include="'+$logicapp+'.template.json" />' + "`r`n" + `
        '    <Content Include="'+$logicapp+'.parameters-dev.json" />`' + "`r`n" + `
        '    <Content Include="'+$logicapp+'.parameters-test.json" />' + "`r`n" + `
        '    <Content Include="'+$logicapp+'.parameters-qa.json" />' + "`r`n" + `
        '    <Content Include="'+$logicapp+'.parameters-prod.json" />'
        ((Get-Content -path ($logicapp + ".deployproj") -Raw) -replace $srcStr,$dstStr) | Set-Content -Path ($logicapp + ".deployproj")

        Set-Location $loc
    }
    else 
    {
        Write-Host
        Write-Error "Could not locate Logic App. Check inputs."
    }
}

