#################################################################################
param(
[Parameter(Mandatory = $true)][string]$repoRootFolder,
[Parameter(Mandatory = $true)][bool]$Internal,
[Parameter(Mandatory = $true)][string]$apiName,
[Parameter(Mandatory = $true)][string]$operation,
[Parameter(Mandatory = $true)][string]$apiBasePath,
[Parameter(Mandatory = $true)][int]$Template,
[Parameter(Mandatory = $true)][string]$logicAppName,
[Parameter(Mandatory = $true)][string]$logicAppResourceGroup,
[Parameter(Mandatory = $true)][string]$functionAppName, 
[Parameter(Mandatory = $true)][string]$functionAppResourceGroup, 
[Parameter(Mandatory = $true)][string]$functionAppPath, 
[Parameter(Mandatory = $true)][string]$backendServiceURLdev,
[Parameter(Mandatory = $true)][string]$backendServiceURLtest,
[Parameter(Mandatory = $true)][string]$backendServiceURLqa,
[Parameter(Mandatory = $true)][string]$backendServiceURLprod
)

#Static Parameter Configuration Below
#################################################################################

#LocalFolderStructure config
#Specify the depth to the API output folder in the repo. Bottom up from the $outputDirectory
#Eg C:\Repos\CurrentRepo\[API\Internal\] eq 2.
$pathDepthToApi = 2

#apim config
$apimInstanceInternalName = "adp-apimgmt-azure-dev"
$apimInstanceExternalName = "adp-apimgmt-se-dev"

#devops config
$organization = "https://dev.azure.com/SJ-ADP"
$project = "Integration Delivery"

#################################################################################
#Static Parameter Configuration Above

#Init values
$logicAppBackend = $false
$functionAppBackend = $false

If ($Internal)
{
    $apimInstance = $apimInstanceInternalName
    $environmentString = "Internal"
    $outputDirectory = "$repoRootFolder\API\Internal"    
}
else
{
    $apimInstance = $apimInstanceExternalName
    $environmentString = "External"
    $outputDirectory = "$repoRootFolder\API\External"
}



#If logic app specified, use logic app template, otherwise use passthrough template
if($Template -eq 1)
{
    $logicAppBackend = $true

    if($logicAppName -and $logicAppResourceGroup)
    {        
        $resourceAppName = $logicAppName
        $resourceResourceGroup = $logicAppResourceGroup

        Write-Host "Logic App backend selected"
        $apiFolderName = 'api-INT-APITemplateLABackend'
    }
    else
    {
        Write-Host "Terminating - Need to specify both logic app name and resource group." -ForegroundColor Red # -BackgroundColor white
        exit
    }
}
elseif ($Template -eq 2)
{
    $functionAppBackend = $true

    if($functionAppName -and $functionAppResourceGroup -and $functionAppPath)
    {        
        $resourceAppName = $functionAppName
        $resourceResourceGroup = $functionAppResourceGroup
        $resourcePath = $functionAppPath

        $apiFolderName = 'api-INT-APITemplateFABackend'
        Write-Host "Function App backend selected"
    }
    else
    {
        Write-Host "Terminating - Need to specify both logic app name and resource group." -ForegroundColor Red # -BackgroundColor white
        exit
    }
}
elseif ($Template -eq 3)
{
    if ($backendServiceURLdev -and $backendServiceURLtest -and $backendServiceURLqa -and $backendServiceURLprod)
    {
        Write-Host "URL backend selected"
        $apiFolderName = 'api-INT-APITemplate'
    }
    else
    {
        Write-Host "Terminating - Need backend service URL if no logic app i specified." -ForegroundColor Red # -BackgroundColor white
        exit
    }
}
else
{
    Write-Host "Terminating - Invalid template number selected." -ForegroundColor Red # -BackgroundColor white
    exit
}

$workingDirectory = "$PSScriptRoot\_tmpWorkingDir\"
$workingfolderName = $apiFolderName
$APIworkingDirectory = "$workingDirectory\$workingfolderName"

#Start by removing any leftover folders if they exist
If((test-path $workingDirectory))
{
    Remove-Item -LiteralPath $workingDirectory -Force -Recurse
}
If((test-path "$outputDirectory\api-$apiName"))
{

    Write-Host "$outputDirectory\api-$apiName allready exists, do you want to remove it? Be very careful here!" -ForegroundColor Yellow # -BackgroundColor white
    $input = Read-Host -Prompt '[Y/N]'
    if ($input -eq 'Y'){
        Write-Host "Removing $outputDirectory\api-$apiName" -ForegroundColor Green # -BackgroundColor white
        Remove-Item -LiteralPath "$outputDirectory\api-$apiName" -Force -Recurse
    }
    else
    { 
        Write-Host "Terminating - Need to remove the existing API in order to continue." -ForegroundColor Red # -BackgroundColor white
        exit
    }
    
}

#Create Working Dir (if missing)
If(!(test-path $workingDirectory))
{
        Write-Host "WorkingDirectory missing, creating it now" -ForegroundColor Yellow # -BackgroundColor white
        New-Item -ItemType Directory -Force -Path $workingDirectory
}

#Copy Template folder
Write-Host "Copying template folder - Start" -ForegroundColor Green # -BackgroundColor white

Copy-Item -Path "$PSScriptRoot\$apiFolderName" -Destination $workingDirectory\$apiFolderName -recurse -force

Write-Host "Copying template folder - End" -ForegroundColor Green # -BackgroundColor white

#Rename api folder
Write-Host "Updating files and folders - Start" -ForegroundColor Green # -BackgroundColor white

Rename-Item -Path $APIworkingDirectory -NewName "api-$apiName"

#Rename files and Replace contents
$APIPath = Get-ChildItem -Path "$workingDirectory\api-$apiName" -Recurse -File | Select-Object FullName

$versionsetGuid = New-Guid
$versionsetGuid = $versionsetGuid.ToString()

$backendIdGuid = New-Guid
$backendIdGuid = $backendIdGuid.ToString().Replace('-','')

foreach($File in $APIPath){

    #Replace parameter settings
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_apimNameLowerCase', $apiName.ToLower()) | Set-Content $File.FullName
    
    #Replace references to files
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_apimNameUpperCaseSHORT', $apiName[0..33] -join "") | Set-Content $File.FullName    

    #Replace references to files
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_apimNameUpperCase', $apiName) | Set-Content $File.FullName

    #Replace APIM Instance
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_APIM_INSTANCE', $apimInstance) | Set-Content $File.FullName

    #Replace path APIin swagger and template
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_API_PATH', $apiBasePath) | Set-Content $File.FullName

    if($logicAppBackend -or $functionAppBackend)
    {
        #Replace resource parameter name (first 25 characters)
        (Get-Content $File.Fullname).Replace('REPLACED_WITH_RESOURCE_NAME_PARTIAL', $resourceAppName[0..24] -join "")  | Set-Content $File.FullName

        #Replace resource name
        (Get-Content $File.Fullname).Replace('REPLACED_WITH_RESOURCE_NAME_FULL', $resourceAppName)  | Set-Content $File.FullName

        #Replace resource resource group
        (Get-Content $File.Fullname).Replace('REPLACED_WITH_RESOURCE_RG', $resourceResourceGroup)  | Set-Content $File.FullName

    }
    if($functionAppBackend)
    {
        #Replace resource resource group
        (Get-Content $File.Fullname).Replace('REPLACED_WITH_RESOURCE_PATH', $resourcePath)  | Set-Content $File.FullName
    }

    #Replace versionset guid
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_versionsetGuid', $versionsetGuid)  | Set-Content $File.FullName

    #Replace backend id guid
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_backendIdGuid', $backendIdGuid)  | Set-Content $File.FullName    

    #Replace backend service URL
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_serviceURLdev', $backendServiceURLdev)  | Set-Content $File.FullName
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_serviceURLtest', $backendServiceURLtest)  | Set-Content $File.FullName
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_serviceURLqa', $backendServiceURLqa)  | Set-Content $File.FullName
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_serviceURLprod', $backendServiceURLprod)  | Set-Content $File.FullName

    #Replace Operation
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_OperationLowerCase', $operation.ToLower())  | Set-Content $File.FullName
        
    #Rename filenames to api name
    $newname = ([String]$File.FullName).Replace($workingfolderName, "api-$apiName")
    Rename-item -Path $File.FullName -NewName $newname

}

#Replace yaml environment path
((Get-Content -path ("$workingDirectory\api-$apiName\api-$apiName.pipeline.yml") -Raw) -replace 'REPLACED_WITH_ENVIRONMENT', $environmentString) | Set-Content -Path ("$workingDirectory\api-$apiName\api-$apiName.pipeline.yml")

#Replace values in the test, qa, prod file --> dev to test/qa/prod, where possible
$parameterFileName = "$workingDirectory\api-$apiName\api-$apiName.master.parameters"
((Get-Content -path ("$parameterFileName-test.json") -Raw) -replace '-dev"','-test"') | Set-Content -Path ("$parameterFileName-test.json")
((Get-Content -path ("$parameterFileName-test.json") -Raw) -replace '-dev-','-test-') | Set-Content -Path ("$parameterFileName-test.json")
		
((Get-Content -path ("$parameterFileName-qa.json") -Raw) -replace '-dev"','-qa"') | Set-Content -Path ("$parameterFileName-qa.json")
((Get-Content -path ("$parameterFileName-qa.json") -Raw) -replace '-dev-','-qa-') | Set-Content -Path ("$parameterFileName-qa.json")
		
((Get-Content -path ("$parameterFileName-prod.json") -Raw) -replace '-dev"','-prod"') | Set-Content -Path ("$parameterFileName-prod.json")
((Get-Content -path ("$parameterFileName-prod.json") -Raw) -replace '-dev-','-prod-') | Set-Content -Path ("$parameterFileName-prod.json")

Write-Host "Updating files and folders - End" -ForegroundColor Green # -BackgroundColor white

#Move from working directory to repo
Write-Host "Moving testfolder from working directory - Start" -ForegroundColor Green # -BackgroundColor white

If(!(test-path $outputDirectory))
{
      Write-Host "OutputDirectory missing, creating it now" -ForegroundColor Yellow # -BackgroundColor white
      New-Item -ItemType Directory -Force -Path $outputDirectory
}
Move-Item -Path "$workingDirectory\api-$apiName" -Destination "$outputDirectory\api-$apiName" -force

#Finish by removing the tmp working directory
If((test-path $workingDirectory))
{
    Remove-Item -LiteralPath $workingDirectory -Force -Recurse
}

Write-Host "Moving testfolder from working directory - End" -ForegroundColor Green # -BackgroundColor white

Write-Host
Write-Host "## TRYING TO CREATE PIPELINE IN DEVOPS ##" -ForegroundColor Yellow # -BackgroundColor white
Write-Host "Ignore the red text!" -ForegroundColor Yellow # -BackgroundColor white
Write-Host "Creating Pipeline in devops - Start" -ForegroundColor Green # -BackgroundColor white

if(-Not (az extension show --name azure-devops))
{
    Write-Host "Azure extension missing... Trying to install now"
    az extension add --name azure-devops
}

if(-Not (az pipelines show --name $apiName --organization $organization --project $project))
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
            az pipelines create --repository $reponame --branch $branchname --name $apiName `
            --description "Pipeline for Api Management api $apiName" `
            --yml-path $yamlpath --folder-path APIM `
            --repository-type tfsgit --organization $organization --project $project
           
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
            Write-Host "--yml-path $yamlpath --folder-path APIM ``"
            Write-Host "--repository-type tfsgit --organization '$organization' --project '$project'"
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
        Write-Host "--yml-path $yamlpath --folder-path APIM ``"
        Write-Host "--repository-type tfsgit --organization '$organization' --project '$project'"
        Write-Host
        Write-Host
        Write-Host "Pipeline was not created!" -ForegroundColor Yellow
    }
}
else
{
    Write-Host "Pipeline allready exists in devops" -ForegroundColor Green
}
Write-Host "Creating Pipeline in devops - End" -ForegroundColor Green # -BackgroundColor white


Write-Host
Write-Host "API Created successfully" -ForegroundColor Green # -BackgroundColor white
