Remove-Variable * -ErrorAction SilentlyContinue

#Param ([string]$NewLogAnalyticsWSName, [string]$NewLogAnalyticsWSRG, [string]$IncludeLogicApps = "", [string]$IncludeResourceGroups = "")

#Variables - Set these to the values you want to change to.

$NewLogAnalyticsWSName = "testws" #testws or int-logicapplogs
$NewLogAnalyticsWSRG = "integration-common" #integration-common or NordIntegration    
$IncludeLogAnalyticsDev = true
$IncludeLogAnalyticsTest = true
$IncludeLogAnalyticsQa = true
$IncludeLogAnalyticsProd = true

#Set which logic apps / resourcegroups that should change log analytics workspace
#or comment theese line if everything in the subscription should change.
$IncludeLogicApps = "tmpFilterArray"
$IncludeResourceGroups = "NordIntegration-dev-adp-rg", "NordIntegration-test-adp-rg", "NordIntegration-qa-adp-rg", "NordIntegration-prod-adp-rg"
    
#Connect-AzAccount -Subscription "6c0c26ce-999b-4550-b46d-8084fc33f398" #dev 6c0c26ce-999b-4550-b46d-8084fc33f398 prod ddcf588c-1b67-40b3-929d-1c7924ee0398


clear
Write-Host
Write-Host
Write-Host

#Get LogAnalytics resources
Write-Host "Getting Log Analytics Resources"
$logAnalyticsWorkspacedev = Get-AzOperationalInsightsWorkspace -ResourceGroupName "$NewLogAnalyticsWSRG-dev-adp-rg" -Name "$NewLogAnalyticsWSName"
#Dev
if ($IncludeLogAnalyticsDev -and ($logAnalyticsWorkspacedev = Get-AzOperationalInsightsWorkspace -ResourceGroupName "$NewLogAnalyticsWSRG-dev-adp-rg" -Name "$NewLogAnalyticsWSName-dev-loganalytics"))
{
    Write-Host "Dev - Done" -ForegroundColor Green
}
else
{
    Write-Host
    Write-Host "Could not find the log analytics workspace: $NewLogAnalyticsWSName-dev-loganalytics in resourcegroup $NewLogAnalyticsWSRG-dev-adp-rg. Terminating." -ForegroundColor Red
    pause
    exit
}
#Test
if ($IncludeLogAnalyticsTest -and ( $logAnalyticsWorkspacetest = Get-AzOperationalInsightsWorkspace -ResourceGroupName "$NewLogAnalyticsWSRG-test-adp-rg" -Name "$NewLogAnalyticsWSName-test-loganalytics"))
{
    Write-Host "Test - Done" -ForegroundColor Green
}
else
{
    Write-Host
    Write-Host "Could not find the log analytics workspace: $NewLogAnalyticsWSName-test-loganalytics in resourcegroup $NewLogAnalyticsWSRG-test-adp-rg. Terminating." -ForegroundColor Red
    pause
    exit
}
#Qa
if ($IncludeLogAnalyticsQa -and ( $logAnalyticsWorkspaceqa = Get-AzOperationalInsightsWorkspace -ResourceGroupName "$NewLogAnalyticsWSRG-qa-adp-rg" -Name "$NewLogAnalyticsWSName-qa-loganalytics"))
{
    Write-Host "Qa - Done" -ForegroundColor Green
}
else
{
    Write-Host
    Write-Host "Could not find the log analytics workspace: $NewLogAnalyticsWSName-qa-loganalytics in resourcegroup $NewLogAnalyticsWSRG-qa-adp-rg. Terminating." -ForegroundColor Red
    pause
    exit
}
#Prod
if ($IncludeLogAnalyticsProd -and ( $logAnalyticsWorkspaceprod = Get-AzOperationalInsightsWorkspace -ResourceGroupName "$NewLogAnalyticsWSRG-prod-adp-rg" -Name "$NewLogAnalyticsWSName-prod-loganalytics"))
{
    Write-Host "Prod - Done" -ForegroundColor Green
}
else
{
    Write-Host
    Write-Host "Could not find the log analytics workspace: $NewLogAnalyticsWSName-prod-loganalytics in resourcegroup $NewLogAnalyticsWSRG-prod-adp-rg. Terminating." -ForegroundColor Red
    pause
    exit
}


#Get LogicApp resources
    Write-Host "Getting logic app resources"
    $logicAppResources = Get-AzResource -ResourceType Microsoft.Logic/workflows
    $totalcount = $logicAppResources.count
    $i = 0

    $logicAppResources | ForEach-Object {
    
        $logicAppResource = $_
        $currentLogicAppName = $logicAppResource.Name
        $i = $i+1
        Write-Progress -Activity "Setting log analytics ws for logic apps" -Status "Progress $i/$totalcount. Now processing $currentLogicAppName" -PercentComplete ($i/$totalcount*100)


        if($IncludeLogicApps -and !($logicAppResource.Name -in $IncludeLogicApps))
        {
            Return
        }

        #Check if we should process this Logic App
        if ($IncludeResourceGroups -and !($logicAppResource.ResourceGroupName -in $IncludeResourceGroups))
        {
            Write-Host 'Skipping LogicApp:' $logicAppResource.Name 'in' $logicAppResource.ResourceGroupName -ForegroundColor Yellow # -BackgroundColor white
            Return
        }

        $currentLogicAppName = $logicAppResource.Name        

        Write-Host -NoNewline 'Processing LogicApp:' $logicAppResource.Name 'in' $logicAppResource.ResourceGroupName '... '
        if ($logicAppResource.ResourceGroupName -like "*-dev-*")
        {
            $logAnalyticsWorkspace = $logAnalyticsWorkspacedev
        }
        elseif ($logicAppResource.ResourceGroupName -like "*-test-*")
        {
            $logAnalyticsWorkspace = $logAnalyticsWorkspacetest
        }
        elseif ($logicAppResource.ResourceGroupName -like "*-qa-*")
        {
            $logAnalyticsWorkspace = $logAnalyticsWorkspaceqa
        }
        elseif ($logicAppResource.ResourceGroupName -like "*-prod-*")
        {
            $logAnalyticsWorkspace = $logAnalyticsWorkspaceprod
        }
        else
        {
            Write-Host 'Cannot find a mathing resource group environment for:' $logicAppResource.ResourceGroupName 'in Logic App:' $logicAppResource.Name 'Terminating' -ForegroundColor Red # -BackgroundColor white
            pause
            exit
        }        

        $currentNewLogAnalyticsWSName = $logAnalyticsWorkspace.Name

        #Set LogAnalytics

            if ($logAnalyticsWorkspace.ResourceId) 
            {
                if ( Set-AzDiagnosticSetting -ResourceId $logicAppResource.ResourceId -WorkspaceId $logAnalyticsWorkspace.ResourceId -Enabled $true -)
                {
                    Write-Host "Done" -ForegroundColor Green
                }
                else
                {
                    Write-Host
                    Write-Host "Log Analytics WS was not set for LogicApp: $currentLogicAppName to Log analytics workspace: $currentNewLogAnalyticsWSName Error message: $error" -ForegroundColor Red
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




