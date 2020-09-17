Remove-Variable * -ErrorAction SilentlyContinue
Stop-Transcript -ErrorAction SilentlyContinue
$dt=get-date -Format "yyyy-MM-ddTHHmmss"
Start-Transcript -Path C:\Temp\MigrateLoganalytics_$dt.log
clear

#Param ([string]$NewLogAnalyticsWSName, [string]$NewLogAnalyticsWSRG, [string]$IncludeLogicApps = "", [string]$IncludeResourceGroups = "")

#Variables - Set these to the values you want to change to.
#****************************************************************************************************************************************************************

$NewLogAnalyticsWSName = "int-logicapplogs" #testws or int-logicapplogs
$NewLogAnalyticsWSRG = "integration-common" #integration-common or NordIntegration    
$IncludeLogAnalyticsDev = 0
$IncludeLogAnalyticsTest = 0
$IncludeLogAnalyticsQa = 0
$IncludeLogAnalyticsProd = 1

<#
    SET which logic apps / resourcegroups that should change log analytics workspace
    OR comment theese line if everything in the subscription should change.
#>
#$IncludeLogicApps = "INT-Vehicle-OUT-E-AllocationDeltaConsumer-RPS", "INT-Vehicle-OUT-S-AllocationExecutor-VPBS"
#$IncludeResourceGroups = "NordIntegration-dev-adp-rg", "NordIntegration-test-adp-rg", "NordIntegration-qa-adp-rg", "NordIntegration-prod-adp-rg"
   
#DEV/Test/QA
#Connect-AzAccount -Subscription "6c0c26ce-999b-4550-b46d-8084fc33f398"

#PROD
#Connect-AzAccount -Subscription "ddcf588c-1b67-40b3-929d-1c7924ee0398"

#****************************************************************************************************************************************************************

Write-Host
Write-Host
Write-Host
Write-Host
Write-Host
Write-Host

#Writing configuration
Write-Host "Current configuration"
Write-Host "Green = Normal" -ForegroundColor Green
Write-Host "Yellow = custom" -ForegroundColor Yellow
Write-Host
Write-Host "NewLogAnalyticsWSName = $NewLogAnalyticsWSName"
Write-Host "NewLogAnalyticsWSRG = $NewLogAnalyticsWSRG"
Write-Host
if($IncludeLogAnalyticsDev -eq 1){Write-Host "IncludeLogAnalyticsDev = $IncludeLogAnalyticsDev" -ForegroundColor Green}else{Write-Host "IncludeLogAnalyticsDev = $IncludeLogAnalyticsDev" -ForegroundColor Yellow}
if($IncludeLogAnalyticsTest -eq 1){Write-Host "IncludeLogAnalyticsTest = $IncludeLogAnalyticsTest" -ForegroundColor Green}else{Write-Host "IncludeLogAnalyticsTest = $IncludeLogAnalyticsTest" -ForegroundColor Yellow}
if($IncludeLogAnalyticsQa -eq 1){Write-Host "IncludeLogAnalyticsQa = $IncludeLogAnalyticsQa" -ForegroundColor Green}else{Write-Host "IncludeLogAnalyticsQa = $IncludeLogAnalyticsQa" -ForegroundColor Yellow}
if($IncludeLogAnalyticsProd -eq 1){Write-Host "IncludeLogAnalyticsProd = $IncludeLogAnalyticsProd" -ForegroundColor Green}else{Write-Host "IncludeLogAnalyticsProd = $IncludeLogAnalyticsProd" -ForegroundColor Yellow}
Write-Host
if($IncludeLogicApps){Write-Host "IncludeLogicApps = $IncludeLogicApps" -ForegroundColor Yellow}else{Write-Host "IncludeLogicApps = All" -ForegroundColor Green}
if($IncludeResourceGroups){Write-Host "IncludeResourceGroups = $IncludeResourceGroups" -ForegroundColor Yellow}else{Write-Host "IncludeResourceGroups = All" -ForegroundColor Green}
Write-Host
$confirmation = Read-Host "Are you Sure You Want To Proceed (y/n)"
if ($confirmation -ne 'y') {
    
    Write-Host "Terminating" -ForegroundColor Red
    Stop-Transcript
    exit
}

#Get LogAnalytics resources
Write-Host
Write-Host "Getting Log Analytics Resources"
#Dev
if ($IncludeLogAnalyticsDev -eq 1)
{
    if ($logAnalyticsWorkspacedev = Get-AzOperationalInsightsWorkspace -ResourceGroupName "$NewLogAnalyticsWSRG-dev-adp-rg" -Name "$NewLogAnalyticsWSName-dev-loganalytics")
    {
        Write-Host "Dev - Done" -ForegroundColor Green
    }
    else
    {
        Write-Host
        Write-Host "Could not find the log analytics workspace: $NewLogAnalyticsWSName-dev-loganalytics in resourcegroup $NewLogAnalyticsWSRG-dev-adp-rg. Terminating." -ForegroundColor Red
        pause
        Stop-Transcript
        exit
    }
}
else
{
    Write-Host "Dev - Skipped" -ForegroundColor Green
}
#Test
if ($IncludeLogAnalyticsTest -eq 1)
{
    if ( $logAnalyticsWorkspacetest = Get-AzOperationalInsightsWorkspace -ResourceGroupName "$NewLogAnalyticsWSRG-test-adp-rg" -Name "$NewLogAnalyticsWSName-test-loganalytics")
    {
        Write-Host "Test - Done" -ForegroundColor Green
    }
    else
    {
        Write-Host
        Write-Host "Could not find the log analytics workspace: $NewLogAnalyticsWSName-test-loganalytics in resourcegroup $NewLogAnalyticsWSRG-test-adp-rg. Terminating." -ForegroundColor Red
        pause
        Stop-Transcript
        exit
    }
}
else
{
    Write-Host "Test - Skipped" -ForegroundColor Green
}
#Qa
if ($IncludeLogAnalyticsQa -eq 1)
{
    if ( $logAnalyticsWorkspaceqa = Get-AzOperationalInsightsWorkspace -ResourceGroupName "$NewLogAnalyticsWSRG-qa-adp-rg" -Name "$NewLogAnalyticsWSName-qa-loganalytics")
    {
        Write-Host "Qa - Done" -ForegroundColor Green
    }
    else
    {
        Write-Host
        Write-Host "Could not find the log analytics workspace: $NewLogAnalyticsWSName-qa-loganalytics in resourcegroup $NewLogAnalyticsWSRG-qa-adp-rg. Terminating." -ForegroundColor Red
        pause
        Stop-Transcript
        exit
    }
}
else
{
    Write-Host "Qa - Skipped" -ForegroundColor Green
}
#Prod
if ($IncludeLogAnalyticsProd -eq 1)
{
    if ( $logAnalyticsWorkspaceprod = Get-AzOperationalInsightsWorkspace -ResourceGroupName "$NewLogAnalyticsWSRG-prod-adp-rg" -Name "$NewLogAnalyticsWSName-prod-loganalytics")
    {
        Write-Host "Prod - Done" -ForegroundColor Green
    }
    else
    {
        Write-Host
        Write-Host "Could not find the log analytics workspace: $NewLogAnalyticsWSName-prod-loganalytics in resourcegroup $NewLogAnalyticsWSRG-prod-adp-rg. Terminating." -ForegroundColor Red
        pause
        Stop-Transcript
        exit
    }
}
else
{
    Write-Host "Prod - Skipped" -ForegroundColor Green
}

#Declare errorlist
$unsuccessfulLogicApps = [System.Collections.ArrayList]@()

#Get LogicApp resources
Write-Host 
Write-Host "Getting logic app resources"
$logicAppResources = Get-AzResource -ResourceType Microsoft.Logic/workflows
$totalcount = $logicAppResources.count
$i = 0
Write-Host "Found $totalcount logic apps in currently logged in subscription" -ForegroundColor Green

Write-Host 
Write-Host "Processing logic apps"
$logicAppResources | ForEach-Object {
    
    #Store variables
    $logicAppResource = $_
    $currentLogicAppName = $logicAppResource.Name
    $currentLogicRG = $logicAppResource.ResourceGroupName
    $i = $i+1
    Write-Progress -Activity "Setting log analytics ws for logic apps" -CurrentOperation "Resource group: $currentLogicRG" -Status "Progress $i/$totalcount. Now processing $currentLogicAppName" -PercentComplete ($i/$totalcount*100)
    Write-Host -NoNewline $i/$totalcount 'Processing' $logicAppResource.ResourceGroupName '-' $logicAppResource.Name'... '

        
    #Check if we should process this Logic App
    if($IncludeLogicApps -and !($logicAppResource.Name -in $IncludeLogicApps))
    {
        Write-Host "Skipped ... Logic app not included" -ForegroundColor Yellow # -BackgroundColor white
        Return
    }

    if ($IncludeResourceGroups -and !($logicAppResource.ResourceGroupName -in $IncludeResourceGroups))
    {
        Write-Host "Skipped ... resource group not included" -ForegroundColor Yellow # -BackgroundColor white
        Return
    }        
        
    #Get Log analytics ws        
    if ($logicAppResource.ResourceGroupName -like "*-dev-*")
    {
        if ($IncludeLogAnalyticsDev -eq 1)
        {
            $logAnalyticsWorkspace = $logAnalyticsWorkspacedev
        }
        else
        {
            Write-Host "Skipped ... Loganalytics Dev not included" -ForegroundColor Yellow # -BackgroundColor white
            Return
        }
    }
    elseif ($logicAppResource.ResourceGroupName -like "*-test-*")
    {
        if ($IncludeLogAnalyticsTest -eq 1)
        {
            $logAnalyticsWorkspace = $logAnalyticsWorkspacetest
        }
        else
        {
            Write-Host "Skipped ... Loganalytics Test not included" -ForegroundColor Yellow # -BackgroundColor white
            Return
        }
    }
    elseif ($logicAppResource.ResourceGroupName -like "*-qa-*")
    {
        if ($IncludeLogAnalyticsQa -eq 1)
        {
            $logAnalyticsWorkspace = $logAnalyticsWorkspaceqa
        }
        else
        {
            Write-Host "Skipped ... Loganalytics Qa not included" -ForegroundColor Yellow # -BackgroundColor white
            Return
        }
    }
    elseif ($logicAppResource.ResourceGroupName -like "*-prod-*")
    {
        if ($IncludeLogAnalyticsProd -eq 1)
        {
            $logAnalyticsWorkspace = $logAnalyticsWorkspaceprod
        }
        else
        {
            Write-Host "Skipped ... Loganalytics Prod not included" -ForegroundColor Yellow # -BackgroundColor white
            Return
        }
    }
    else
    {
        Write-Host 'Cannot find a mathing resource group environment for:' $logicAppResource.ResourceGroupName 'in Logic App:' $logicAppResource.Name 'Terminating' -ForegroundColor Red # -BackgroundColor white
        pause
        Stop-Transcript
        exit
    }

    $currentNewLogAnalyticsWSName = $logAnalyticsWorkspace.Name
        
    Write-Host -NoNewline "$currentNewLogAnalyticsWSName ... " -ForegroundColor Green

    #Set LogAnalytics ws
        if ($logAnalyticsWorkspace.ResourceId) 
        {
            if ( Set-AzDiagnosticSetting -ResourceId $logicAppResource.ResourceId -WorkspaceId $logAnalyticsWorkspace.ResourceId -Enabled $true -WarningAction SilentlyContinue)
            {
                Write-Host "Done" -ForegroundColor Green
            }
            else
            {
                Write-Host
                Write-Host "Log Analytics WS was not set for LogicApp: $currentLogicAppName to Log analytics workspace: $currentNewLogAnalyticsWSName Error message: $error" -ForegroundColor Red
                $unsuccessfulLogicApps.Add($currentLogicAppName)
                pause
            }
        }
        else 
        {   
            Write-Host
            Write-Host "Could not locate log analytics workspace with name $currentNewLogAnalyticsWSName. Verify that this exists or check inputs."  -ForegroundColor Red
            pause
        }

}

Write-Host
    
#Sum up execution
if ($unsuccessfulLogicApps)
{
    Write-Host "Some logic apps where unsuccesful when setting log analytics workspace" -ForegroundColor Red
    Write-Host "Retry by setting them in the IncludeLogicApps variable" -ForegroundColor Red
    Write-Host
    foreach ($la in $unsuccessfulLogicApps) {
        Write-Host $la -ForegroundColor Red
    }
}
else
{
    Write-Host "Migration script executed successfully."  -ForegroundColor Green
}

Stop-Transcript