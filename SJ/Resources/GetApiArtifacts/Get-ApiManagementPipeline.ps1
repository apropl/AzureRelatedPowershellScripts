


param([string] $apimanagement, [string] $apiname, [string] $rootFolder)

Write-Host
Write-Host "Ensuring output folder."

if ($apimanagement -eq "adp-apimgmt-azure-dev")
{
    $apimanagementNetworkLocation = "Internal"
}
else # adp-apimgmt-se-dev
{
    $apimanagementNetworkLocation = "External"
}

$repo = ($rootFolder | split-path -leaf)
$apiname = "api-$apiname"
$relativeFolderPath = Join-Path (Join-Path API $apimanagementNetworkLocation) $apiname

$outputFolderFullPath = Join-Path $rootFolder $relativeFolderPath

$pipelineName = "$apiname.pipeline.yml"
$pipelineRelativePath = Join-Path $relativeFolderPath $pipelineName
$pipelineFullPath = Join-Path $rootFolder $pipelineRelativePath

md -Force $outputFolderFullPath | Out-Null
           
$loc = Get-Location
Set-Location $outputFolderFullPath

Write-Host
Write-Host "Creating Azure DevOps Pipeline yml file at $pipelineFullPath"

# Copy/duplicate the pipeline file
Copy-Item "$PSScriptRoot\APINAME-api.pipeline.yml" -Destination $pipelineName

$pipelineContent = (Get-Content -path $pipelineName -Raw)

# Replace the placeholders with real values
$srcStr = "<<API-NAME>>"
$dstStr = $apiname
$pipelineContent = ($pipelineContent -replace $srcStr,$dstStr)
$srcStr = "<<APIM-LOCATION>>"
$dstStr = $apimanagementNetworkLocation
$pipelineContent -replace $srcStr,$dstStr | Set-Content -Path $pipelineName

$apiname = $apiname.Substring(4)

Set-Location $loc

if(-Not (az extension show --name azure-devops))
{
    Write-Host "Azure extension missing... Trying to install now"
    az extension add --name azure-devops
}

if(-Not (az pipelines show --name $apiName --organization "https://dev.azure.com/SJ-ADP" --project "Integration Delivery"))
{
    Write-Host "Pipeline is missing in Azure Devops. Do you want to create a pipeline for the API?" -ForegroundColor Yellow # -BackgroundColor white
    $input = Read-Host -Prompt '[Y/N]'
    if ($input -eq 'Y')
    {    
        $reponame = Split-Path -Leaf (git -C $rootFolder remote get-url origin)
		$branchname = git -C $rootFolder rev-parse --abbrev-ref HEAD  

        if($reponame -And $branchname)
        {            		
			az pipelines create --repository $reponame --branch $branchname --name $apiname `
			--description "Pipeline for Api Management api $apiname" `
			--yml-path $pipelineRelativePath --folder-path APIM `
			--repository-type tfsgit --organization 'https://dev.azure.com/SJ-ADP' --project 'Integration Delivery'
           
            Write-Host
            Write-Host "Pipeline successfully created!" -ForegroundColor Green
        }
        else
        {
            Write-Host
            Write-Host "Output directory is not in a git repo!" -ForegroundColor Yellow
            Write-Host "Run the below command to create your Azure DevOps pipline"
            Write-Host "Replace YOURREPONAME and YOURBRANCHNAME"
            Write-Host
            Write-Host "For this you need Azure CLI and the Azure DevOps extension (az extension add --name azure-devops)"
            Write-Host "This should be automatically installed using this script"
            Write-Host
            Write-Host "az pipelines create --repository YOURREPONAME --branch YOURBRANCHNAME --name $apiName ``"
            Write-Host "--description 'Pipeline for Api Management api $apiName' ``"
            Write-Host "--yml-path $pipelineRelativePath --folder-path APIM ``"
            Write-Host "--repository-type tfsgit --organization 'https://dev.azure.com/SJ-ADP' --project 'Integration Delivery'"
            Write-Host
            Write-Host "Pipeline was not created!" -ForegroundColor Yellow
        }

        #NOTE
        #Can remove the following from the above if you are in a local Git directory that has a "remote" referencing a Azure DevOps or Azure DevOps Server repository.
        # --organization $organization --project $project
    }
    else
    { 
        Write-Host
        Write-Host "Run the below command to create your Azure DevOps pipline"
        Write-Host
        Write-Host "For this you need Azure CLI and the Azure DevOps extension (az extension add --name azure-devops)"
        Write-Host "This should be automatically installed using this script"
        Write-Host
        Write-Host "az pipelines create --repository $reponame --branch $branchname --name $apiName ``"
        Write-Host "--description 'Pipeline for Api Management api $apiName' ``"
        Write-Host "--yml-path $pipelineRelativePath --folder-path APIM ``"
        Write-Host "--repository-type tfsgit --organization 'https://dev.azure.com/SJ-ADP' --project 'Integration Delivery'"
        Write-Host
        Write-Host
        Write-Host "Pipeline was not created!" -ForegroundColor Yellow
    }
}
else
{
    Write-Host "Pipeline allready exists in devops" -ForegroundColor Green
}