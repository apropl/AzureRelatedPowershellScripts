Remove-Variable * -ErrorAction SilentlyContinue
#Import-Module Az.Websites
#Taken from https://github.com/Dries-Venter/PowershellScripts/blob/master/configureAppInsightsParallelJob.ps1
#Added $includeFunctions, $appinsightsName & $appinsightsRG variables
#Examples below for each variable

#DEV/Test/QA
Connect-AzAccount -Subscription "6c0c26ce-999b-4550-b46d-8084fc33f398"

#PROD
#Connect-AzAccount -Subscription "ddcf588c-1b67-40b3-929d-1c7924ee0398"

$includeFunctions = "INT-TechnicalTimeTable-IN-P-RailMLToTrainPathPortal"
$envResourceGroupName = "NordIntegration-test-adp-rg"
$appinsightsName = "int-functionapplogs-test-appinsights" # int-functionapplogs-dev-appinsights or testai
$appinsightsRG = "integration-common-test-adp-rg" #NordIntegration-dev-adp-rg or 

<#
.SYNOPSIS
     Configures App services in ENV resource group to send telemitry to the Application Insights instance in the ENV RG
.DESCRIPTION
    The script retrieves the ENV app insights instrumentation key from the ENV application instance and then add app settings to all the 
    app service instances in the ENV (application environment) resource group.
    I have included Start-Job to allow for jobs to be executed in paralel if you have more than one webapp in the resourcegroup
    I have included a section with logic to check that jobs completed before main scripts closes down. And also a debug section to 
    receive the completed job and dump a output log that can be used for troubleshooting. The debug section and the "check jobs status"
    sections can be commemnted out.
.INPUTS
    $(custom_resourceGroupName) Pipeline variable for resource group of ENV 
.OUTPUTS
    Writes updated app settings to app service instances
.NOTES
    Script assumes that there are at least one ipplication insights resource and one webapp or function app in the specified 
    resource group.
    Because of our specific nameing convention it will calculate the names of the application insights based on the resource group name. if this is not 
    disired then you can include another parameter to feed it the name if the application insight resource
    
.EXAMPLE
    .\configureAppInsights.ps1 -envResourceGroupName <insert resource group name that you are targeting>
.AUTHOR
    Dries Vemter
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#*******************************************************
#Uncomment to use parameters instead of variables above!
#*******************************************************

#region parameters
#[CmdletBinding()]
#param (
#    $envResourceGroupName,
#    $appinsightsName,
#    $appinsightsRG,
#    $includeFunctions
#)

#regionend parameters
$ErrorActionPreference = "Stop"

#----------------------------------------------------------[Declarations]----------------------------------------------------------
#region variables
$resourceGroupName = $envResourceGroupName
if($includeFunctions)
{
    $webAppNames = $includeFunctions
}
else
{
    $webAppNames = (Get-AzWebApp -ResourceGroupName $resourceGroupName).Name
}
$appinsightsResource = $appinsightsName #($resourceGroupName.Replace("-", "")).ToLower()
$appinsightsResourceGroup = $appinsightsRG
$MaximumWaitMinutes = 10
$DelayBetweenCheckSeconds = 10
#endregion variables

#-----------------------------------------------------------[Functions]------------------------------------------------------------
#region Functions

#endregion Functions

#-----------------------------------------------------------[Execution]------------------------------------------------------------
#region script main

#Get instrumentation key from ENV application insights resource
$appInsightsInstrumentationKey = (Get-AzApplicationInsights -Name $appinsightsResource -ResourceGroupName $appinsightsResourceGroup).InstrumentationKey
#enumirate the app service instances within the specified resource group then amend the exisiting app setting with the additional settings below.
#Script Block to allow for parallel jobs to be executed.
$setWebAppConfig = {
    param (
        [string] $resourceGroupName,
        [string] $webAppName, 
        [string] $appInsightsInstrumentationKey,
        [string] $includeFunctions = ""
    )
    try {
        #Local Vars
        $resourceName = "$webAppName"
        $resourceNameString = $resourceName + "/Microsoft.ApplicationInsights.AzureWebSites"
        #Get the web app object
        $webApp = Get-AzwebApp -ResourceGroupName $resourceGroupName -Name $webAppName
        Write-host "Targeting Web APP: " $webApp.Name
        #Set the appseting to send telemetry to common applicaiton insights.
        $webAppSettings = $webApp.SiteConfig.AppSettings
        $hash = @{ }
        Write-Host "Clearing hash table" -ForegroundColor Green
        foreach ($setting in $webAppSettings) {
            $hash[$setting.Name] = $setting.Value
        }
        $hash['APPINSIGHTS_INSTRUMENTATIONKEY'] = "$appInsightsInstrumentationKey" #its important to include the syntax around the variable eg. "$($var)"" if not supplied like this it will change the hash table's object type.
        #$hash['ApplicationInsightsAgent_EXTENSION_VERSION'] = "~2"
        #$hash['XDT_MicrosoftApplicationInsights_Mode'] = "recommended"
        #$hash['APPINSIGHTS_PROFILERFEATURE_VERSION'] = "1.0.0"
        #$hash['DiagnosticServices_EXTENSION_VERSION'] = "~3"
        #$hash['APPINSIGHTS_SNAPSHOTFEATURE_VERSION'] = "1.0.0"
        #$hash['SnapshotDebugger_EXTENSION_VERSION'] = "disabled"
        #$hash['InstrumentationEngine_EXTENSION_VERSION'] = "disabled"
        #$hash['XDT_MicrosoftApplicationInsights_BaseExtensions'] = "disabled"
        #Write back app settings into web app
        Write-Host "Writing back updated appsettings to app service" $resourceName -ForegroundColor Green
        Set-AzWebApp -AppSettings $hash -Name $resourceName -ResourceGroupName $resourceGroupName -verbose -ErrorAction stop
        
        #Enable Application insight extention
        $resourceName = "$webAppName"
        $resourceNameString = $resourceName + "/Microsoft.ApplicationInsights.AzureWebSites"
        Write-host "Enabling Application Insights Extension on" $resourceName -ForegroundColor	DarkYellow
        Write-host "'$resourceNameString'" #debug
        Write-host "'$resourceGroupName'" #debug
        New-AzResource -ResourceType "Microsoft.Web/sites/siteextensions" -ResourceGroupName $resourceGroupName -Name $resourceNameString -ApiVersion "2018-02-01" -Force -ErrorAction Stop
        Write-host "Completed enabling app insights extention" \

        #Restart Web App
        Write-host "Restarting WebApp" -ForegroundColor Green
        Write-Host $resourceName -ForegroundColor Green
        Restart-AzWebApp -ResourceGroupName $resourceGroupName -Name $resourceName   
    }
    catch {
        Write-Host "Configuration did not complete on " $resourceName
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Write-host $ErrorMessage
        Write-host $FailedItem
    } 
}

#Initiating parallel run
ForEach ($webAppName in $webAppNames) {
    Start-Job -ScriptBlock $setWebAppConfig -ArgumentList $resourceGroupName, $webAppName, $appInsightsInstrumentationKey
}
#logic to check that jobs completed before main scripts closes down. 
$Timeout = new-timespan -Minutes $MaximumWaitMinutes
$Stopwatch = [diagnostics.stopwatch]::StartNew()    
Write-Host "Waiting for all jobs to complete - ($($DelayBetweenCheckSeconds) second(s) check / $($MaximumWaitMinutes) minute(s) max wait)";
while ($Stopwatch.elapsed -lt $Timeout) { 
    # Get job status
    $Status = Get-Job | Where-object { $_.State -eq "Running" }
    $status
    $status.count    #to be used for debugging
    Write-host "Waiting for app services configuration to complete"

    # break if all completed
    if ($status.count -eq 0) { break }
    #if (!($Status)) { break; }
    # Wait until next check
    Start-Sleep -seconds $DelayBetweenCheckSeconds
}

#debug step (not required for normal running but helps you see what is going on inside the job)
Write-host "About to get status of Jobs" -ForegroundColor green
$jobs = Get-Job
foreach ($job in $jobs) {
    Receive-job -id $job.id
}
Write-host "Done"
#endregion script main