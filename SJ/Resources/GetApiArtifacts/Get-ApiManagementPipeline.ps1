


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

. "$PSScriptRoot\..\GenerateDevopsPipeline\GenerateDevopsPipeline.ps1" -resourceName $apiName -outputDirectory $rootFolder -pipelineRelativePath $pipelineRelativePath -pipelineFolderpath "APIM" -organization "https://dev.azure.com/SJ-ADP" -project "Integration Delivery"