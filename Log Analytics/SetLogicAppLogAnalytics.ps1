Param ([string]$logAnalyticsWSName, [string]$logicAppName, [string]$logicAppResourcegroupname)

#Variables - not used anymore, using input parameters instead
    #$logAnalyticsWSName = "int-logicapplogs-dev-loganalytics"

    #$logicAppName = '$(logicappname)'    
    #$logicAppName = "INT-TrainComposition-IN-E-RotationDispatch-DSB"

    #$logicAppResourcegroupname = '$(resourcegroup-dev)'
    #$logicAppResourcegroupname = "NordIntegration-dev-adp-rg"

    Write-Host "Input for powershell script, loganalyticsWS: $logAnalyticsWSName, logicAppName: $logicAppName, logicAppResourcegroupname: $logicAppResourcegroupname"

#Get LogicApp resource

    Write-Host "Get logic app resource"
    $logicAppResource = Get-AzResource -ResourceType Microsoft.Logic/workflows -Name $logicAppName -ResourceGroupName $logicAppResourcegroupname

#Get LogAnalytics resource

    Write-Host "Get LogAnalytics resource"             
    foreach ($ws in Get-AzOperationalInsightsWorkspace)
    {
        if ($ws.Name -eq "$logAnalyticsWSName")
        {
            #found match, stopping loop.
            $logAnalyticsWorkspace = $ws
            break;
        }
    }

#Set LogAnalytics

    if ( $logicAppResource.ResourceId -And $logAnalyticsWorkspace.ResourceId) 
    {
        Write-Host
        Write-Host "Found Logic app resource" $logicAppResource.Name "and log analytics resource" $logAnalyticsWorkspace.Name ". Setting Log analytics workspace of logic app."        
        if ( Set-AzDiagnosticSetting -ResourceId $logicAppResource.ResourceId -WorkspaceId $logAnalyticsWorkspace.ResourceId -Enabled $true)
        {
            Write-Host "Log Analytics WS set"
        }
        else
        {
            Write-Error "Log Analytics WS was not set for LogicApp: $logicAppName to Log analytics workspace: $logAnalyticsWSName Error message: $error" 
        }
    }
    else 
    {
        if ( !$logicAppResource.ResourceId -And !$logAnalyticsWorkspace.ResourceId)
        {
            Write-Host
            Write-Error "Could not locate Logic App: $logicAppName in Resourcegroup $logicAppResourcegroupname or log analytics workspace $logAnalyticsWSName. Verify that theese exist or check inputs."
        }
        elseif ( !$logicAppResource.ResourceId)
        {
            Write-Host
            Write-Error "Could not locate Logic App: $logicAppName in Resourcegroup $logicAppResourcegroupname. Verify that this exists or check inputs."
        }                        
        elseif ( !$logAnalyticsWorkspace.ResourceId)
        {
            Write-Host
            Write-Error "Could not locate log analytics workspace $logAnalyticsWSName. Verify that this exists or check inputs."
        }
    }




