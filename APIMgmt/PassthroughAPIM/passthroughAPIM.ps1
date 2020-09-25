##Config BELOW!
#################################################################################

#Complete output directory
$outputDirectory = "C:\Repos\VEA-VehicleAllocation\API\Internal"

#API information
$Internal = $true
$apiName = "INT-Vehicle-IN-E-VehicleAllocation-IVUSJO"
#example outbound
#outbound/system/integration
#example inbound
#public/x/system/integration
$apiBasePath = "outbound/ivusjo/EmployeeAllocationConfirmation"


## SPECIFY ONE OF THE BELOW 3 Logic app, Function app or URL backend ##

###################### 1 - LOGIC APP ######################
#Specify if logic app backend
$logicAppBackend = $false

#Logic App ( Complete name/rg to DEV )
$logicAppName = "LogicAppName"
$logicAppResourceGroup = "ResourceGroupName"

###################### 2 - FUNCTION APP ###################
#Specify if function app backend
$functionAppBackend = $false

#Function App ( Complete name/rg to DEV )
$functionAppName = "int-common-messagerouter-dev-fa"
$functionAppResourceGroup = "NordIntegration-dev-adp-rg"
$functionAppPath = "/api/servicebus/topic/sendmsg"

###################### 3 - URL BACKEND ###################
#If no logic app or function app backend. Set service URL
$backendServiceURLdev = "https://backendurl.dev"
$backendServiceURLtest = "https://backendurl.test"
$backendServiceURLqa = "https://backendurl.qa"
$backendServiceURLprod = "https://backendurl.prod"

##Config ABOVE!
#################################################################################

#param(
#[string]$outputDirectory = "C:\Repos\",
#[Parameter(Mandatory = $true)]
#[bool]$Internal,
#[Parameter(Mandatory = $true)]
#[string]$apiName,
#[Parameter(Mandatory = $true)]
#[string]$apiBasePath = "public/partner/SUPERTEST",
#[Parameter(Mandatory = $false)]
#[string]$logicAppName,
#[Parameter(Mandatory = $false)]
#[string]$logicAppResourceGroup,
#[Parameter(Mandatory = $false)]
#[string]$backendServiceURL
#)

If ($Internal)
{
    $apimInstance = "adp-apimgmt-azure-dev"
    $environmentString = "Internal"
}
else
{
    $apimInstance = "adp-apimgmt-se-dev"
    $environmentString = "External"
}

#If logic app specified, use logic app template, otherwise use passthrough template
if($logicAppBackend)
{
    if($logicAppName -and $logicAppResourceGroup)
    {        
        $resourceAppName = $logicAppName
        $resourceResourceGroup = $logicAppResourceGroup

        Write-Host "Logic App backend selected"
        $zipFileName = 'api-INT-APITemplateLABackend.zip'
    }
    else
    {
        Write-Host "Terminating - Need to specify both logic app name and resource group." -ForegroundColor Red # -BackgroundColor white
        exit
    }
}
elseif ($functionAppBackend)
{
    if($functionAppName -and $functionAppResourceGroup -and $functionAppPath)
    {        
        $resourceAppName = $functionAppName
        $resourceResourceGroup = $functionAppResourceGroup
        $resourcePath = $functionAppPath

        $zipFileName = 'api-INT-APITemplateFABackend.zip'
        Write-Host "Function App backend selected"
    }
    else
    {
        Write-Host "Terminating - Need to specify both logic app name and resource group." -ForegroundColor Red # -BackgroundColor white
        exit
    }
}
elseif ($backendServiceURL)
{
    Write-Host "URL backend selected"
    $zipFileName = 'api-INT-APITemplate.zip'
}
else
{
    Write-Host "Terminating - Need backend service URL if no logic app i specified." -ForegroundColor Red # -BackgroundColor white
    exit
}


$url = "https://github.com/apropl/AzureRelatedPowershellScripts/blob/master/APIMgmt/PassthroughAPIM/$zipFileName?raw=true"
$workingDirectory = "C:\Temp\passhtroughApim"
$workingfolderName = "$zipFileName".Replace('.zip','')
$APIworkingDirectory = "$workingDirectory\$workingfolderName"

#Start by removing any leftover folders if they exist
If((test-path $APIworkingDirectory))
{
    Remove-Item -LiteralPath $APIworkingDirectory -Force -Recurse
}
If((test-path "$workingDirectory\api-$apiName"))
{
    Remove-Item -LiteralPath "$workingDirectory\api-$apiName" -Force -Recurse
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

#Download files (if missing)
if (!(Test-Path $workingDirectory\$zipFileName)) {
    
    Write-Host "$zipFileName - Missing in working directory: $workingDirectory" -ForegroundColor Green # -BackgroundColor white
    Write-Host "Downloading $zipFileName - Start" -ForegroundColor Green # -BackgroundColor white
    
    If(!(test-path $workingDirectory))
    {
          Write-Host "WorkingDirectory missing, creating it now" -ForegroundColor Yellow # -BackgroundColor white
          New-Item -ItemType Directory -Force -Path $workingDirectory
    }

add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    Invoke-WebRequest -Uri $url -OutFile $workingDirectory\$zipFileName

    Write-Host "Downloading $zipFileName - End" -ForegroundColor Green # -BackgroundColor white
}
else {

    Write-Host "$zipFileName - Exists in working directory: $workingDirectory. Do you want to redownload?" -ForegroundColor Yellow # -BackgroundColor white

     $input = Read-Host -Prompt '[Y/N]'
    if ($input -eq 'Y'){
        Write-Host "Downloading $zipFileName - Start" -ForegroundColor Green # -BackgroundColor white
    
        If(!(test-path $workingDirectory))
        {
              Write-Host "WorkingDirectory missing, creating it now" -ForegroundColor Yellow # -BackgroundColor white
              New-Item -ItemType Directory -Force -Path $workingDirectory
        }

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $url -OutFile $workingDirectory\$zipFileName

        Write-Host "Downloading $zipFileName - End" -ForegroundColor Green # -BackgroundColor white
    }
    else
    { 
        Write-Host "Skipping redownloading zip file." -ForegroundColor yellow # -BackgroundColor white
    }
}

#Extract Zip-file
Write-Host "Extracting files - Start" -ForegroundColor Green # -BackgroundColor white

Expand-Archive -Path $workingDirectory\$zipFileName -DestinationPath $workingDirectory\ -Force

Write-Host "Extracting files - End" -ForegroundColor Green # -BackgroundColor white

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

    #Replace resource parameter name (first 25 characters)
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_RESOURCE_NAME_PARTIAL', $resourceAppName[0..24] -join "")  | Set-Content $File.FullName

    #Replace resource name
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_RESOURCE_NAME_FULL', $resourceAppName)  | Set-Content $File.FullName

    #Replace resource resource group
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_RESOURCE_RG', $resourceResourceGroup)  | Set-Content $File.FullName

    #Replace resource resource group
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_RESOURCE_PATH', $resourcePath)  | Set-Content $File.FullName

    #Replace versionset guid
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_versionsetGuid', $versionsetGuid)  | Set-Content $File.FullName

    #Replace backend id guid
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_backendIdGuid', $backendIdGuid)  | Set-Content $File.FullName    

    #Replace backend service URL
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_serviceURLdev', $backendServiceURLdev)  | Set-Content $File.FullName    
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_serviceURLtest', $backendServiceURLtest)  | Set-Content $File.FullName    
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_serviceURLqa', $backendServiceURLqa)  | Set-Content $File.FullName    
    (Get-Content $File.Fullname).Replace('REPLACED_WITH_serviceURLprod', $backendServiceURLprod)  | Set-Content $File.FullName    
    
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

Write-Host "Moving testfolder from working directory - End" -ForegroundColor Green # -BackgroundColor white