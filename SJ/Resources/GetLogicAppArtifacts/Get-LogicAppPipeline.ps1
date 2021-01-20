


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

. "$PSScriptRoot\..\GenerateDevopsPipeline\GenerateDevopsPipeline.ps1" -resourceName $logicapp -outputDirectory $rootFolder -pipelineRelativePath $pipelineRelativePath -pipelineFolderpath "LogicApps" -organization "https://dev.azure.com/SJ-ADP" -project "Integration Delivery"