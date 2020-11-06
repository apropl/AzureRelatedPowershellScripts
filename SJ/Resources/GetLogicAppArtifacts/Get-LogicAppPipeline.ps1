


param([string] $resourcegroup, [string] $bussinessobject, [string] $logicapp, [string] $rootFolder, [bool] $az)

Write-Host
Write-Host "Ensuring output folder."

$relativeFolderPath = Join-Path LogicApps $logicapp

$outputFolderFullPath = Join-Path $rootFolder $relativeFolderPath

$pipelineName = "$logicapp-la.pipeline.yml"
$pipelineRelativePath = Join-Path $relativeFolderPath $pipelineName
$pipelineFullPath = Join-Path $rootFolder $pipelineRelativePath
           
$loc = Get-Location
Set-Location $outputFolderFullPath

Write-Host
Write-Host "Creating Azure DevOps Pipeline yml file at $pipelineFullPath"

# Copy/duplicate the pipeline file
Copy-Item "$PSScriptRoot\LOGICAPPNAME-la.pipeline.yml" -Destination $pipelineName

$pipelineContent = (Get-Content -path $pipelineName -Raw)

# Replace the placeholders with real values
$srcStr = "<<RG-DEV-NAME>>"
$dstStr = $resourcegroup
$pipelineContent = ($pipelineContent -replace $srcStr,$dstStr)

$srcStr = "<<RG-TEST-NAME>>"
$dstStr = ($resourcegroup -replace "-dev-","-test-")
$pipelineContent = ($pipelineContent -replace $srcStr,$dstStr)

$srcStr = "<<RG-QA-NAME>>"
$dstStr = ($resourcegroup -replace "-dev-","-qa-")
$pipelineContent = ($pipelineContent -replace $srcStr,$dstStr)

$srcStr = "<<RG-PROD-NAME>>"
$dstStr = ($resourcegroup -replace "-dev-","-prod-")
$pipelineContent = ($pipelineContent -replace $srcStr,$dstStr)

$srcStr = "<<BUSINESSOBJECT-NAME>>"
$dstStr = $bussinessobject
$pipelineContent = ($pipelineContent -replace $srcStr,$dstStr)

$srcStr = "<<LOGICAPP-NAME>>"
$dstStr = $logicapp
$pipelineContent -replace $srcStr,$dstStr | Set-Content -Path $pipelineName


Set-Location $loc




if(-Not (az extension show --name azure-devops))
{
    Write-Host "Azure extension missing... Trying to install now"
    az extension add --name azure-devops
}

if(-Not (az pipelines show --name $logicapp --organization "https://dev.azure.com/SJ-ADP" --project "Integration Delivery"))
{
    Write-Host "Pipeline is missing in Azure Devops. Do you want to create a pipeline for the API?" -ForegroundColor Yellow # -BackgroundColor white
    $input = Read-Host -Prompt '[Y/N]'
    if ($input -eq 'Y')
    {
        $relativePath = ( $outputDirectory -split '\\' | select -last $pathDepthToApi ) -join '/'
        $yamlpath = "$relativePath/api-$apiName/api-$apiName.pipeline.yml".TrimStart('/').Replace('/','\')
    
        $reponame = Split-Path -Leaf (git -C $outputDirectory remote get-url origin)
        $branchname = git -C $outputDirectory rev-parse --abbrev-ref HEAD       

        if($reponame -And $branchname)
        {            		
			az pipelines create --repository $reponame --branch $branchname --name $logicapp `
			--description "Pipeline for Logic App $logicapp" `
			--yml-path $pipelineRelativePath --folder-path LogicApps `
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
            Write-Host "az pipelines create --repository YOURREPONAME --branch YOURBRANCHNAME --name $logicapp ``"
            Write-Host "--description 'Pipeline for Logic App $logicapp' ``"
            Write-Host "--yml-path $pipelineRelativePath --folder-path LogicApps ``"
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
        Write-Host "az pipelines create --repository $reponame --branch $branchname --name $logicapp ``"
        Write-Host "--description 'Pipeline for Logic App $logicapp' ``"
        Write-Host "--yml-path $pipelineRelativePath --folder-path LogicApps ``"
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