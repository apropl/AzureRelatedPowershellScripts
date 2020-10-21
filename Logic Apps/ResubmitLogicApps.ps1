#Original script made by Poojith Jain
# https://azureintegrations.com/2019/10/22/azure-enumerating-all-the-logic-app-runs-history-using-powershell-and-rest-api
# added parameter to test before sending

function Get-LogicAppHistory {
  param
  (
    [Parameter(Mandatory = $true)]
    $Token,
    [Parameter(Mandatory = $true)]
    $subscriptionId,
    [Parameter(Mandatory = $true)]
    $resourceGroupName,
    [Parameter(Mandatory = $true)]
    $logicAppName,
    [Parameter(Mandatory = $false)]
    $status,
    [Parameter(Mandatory = $true)]
    $startDateTime,
    [Parameter(Mandatory = $false)]
    $endDateTime,
    [Parameter(Mandatory = $true)]
    $test
  )
  $headers = @{
    'Authorization' = 'Bearer ' + $token
  }
  
  $startDateTime = Get-Date -Date $startDateTime
  $endDateTime = Get-Date -Date $endDateTime
  $startDTFormated = $startDateTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
  $endDTFormated = $endDateTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
  $uri = 'https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Logic/workflows/{2}/runs?api-version=2016-06-01&$filter={3}' -f $subscriptionId,$resourceGroupName,$logicAppName,"status eq '$status' and startTime ge $startDTFormated and startTime le $endDTFormated"
  $method = (Invoke-RestMethod -Uri $uri -Headers $headers -Method Get) 
  $output = $method.value
  foreach ($item in $output) {
    if ((($item.properties.status -eq $status) -and ($item.properties.startTime -ge $startDateTime)) -and ($item.properties.startTime -le  $endDateTime ))
    {
      $uri = 'https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Logic/workflows/{2}/triggers/{3}/histories/{4}/resubmit?api-version=2016-06-01' -f $subscriptionId,$resourceGroupName,$logicAppName,$item.properties.Trigger.Name,$item.Name
      Write-Host "Submitting" $uri
      Invoke-RestMethod -Method 'POST' -Uri $uri -Headers $headers
    }
  }
  while ($method.nextLink)
  {
    $nextLink = $method.nextLink; 
    Write-Host $nextLink
    $method = (Invoke-RestMethod -Uri $nextLink -Headers $headers -Method Get)
    $output = $method.value
    foreach ($item in $output) {
      if (($item.properties.status -eq $status) -and ([DateTime]$item.properties.startTime -ge $startDateTime) -and ([DateTime]$item.properties.startTime -le $endDateTime))
      {
        $uri = 'https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Logic/workflows/{2}/triggers/{3}/histories/{4}/resubmit?api-version=2016-06-01' -f $subscriptionId,$resourceGroupName,$logicAppName,$item.properties.Trigger.Name,$item.Name
        
        if($test -eq "false")
        {
            Write-Host "Submitting" $uri
            Invoke-RestMethod -Method 'POST' -Uri $uri -Headers $headers
        }
        else
        {
            Write-Host "Test output - would submit" $uri            
        }
      }
    }
  }
}
function ResubmitLogicApp {
  param(
    [Parameter(Mandatory = $false)]
    [string]$subscriptionName,
    [Parameter(Mandatory = $false)]
    [string]$subscriptionId,
    [Parameter(Mandatory = $true)]
    [string]$resourceGroupName,
    [Parameter(Mandatory = $true)]
    [string]$logicAppName,
    [Parameter(Mandatory = $true)]
    [string]$status,
    [Parameter(Mandatory = $true)]
    [string]$startDateTime,
    [Parameter(Mandatory = $true)]
    [string]$endDateTime,
    [Parameter(Mandatory = $true)]
    [string]$test
  )
  $currentAzureContext = Get-AzContext
  if (!$currentAzureContext)
  {
    Connect-AzAccount
    $currentAzureContext = Get-AzContext
  }
  $startDateTime = Get-Date -Date $startDateTime
  $endDateTime = Get-Date -Date $endDateTime

    if ((!$subscriptionName -And !$subscriptionId) -Or ($subscriptionName -And $subscriptionId))
    {
        Write-Error "You need to EITHER provide subscriptionName OR subscriptionId. Cannot submit both or none."
        exit
    }
    elseif ($subscriptionName)
    {
        $subscription = Get-AzSubscription -SubscriptionName $subscriptionName
    }                        
    elseif ($subscriptionId)
    {
        $subscription = Get-AzSubscription -SubscriptionId $subscriptionid
    }

  $context = $subscription | Set-AzContext
  $tokens = $context.TokenCache.ReadItems() | Where-Object { $_.TenantId -eq $context.Subscription.TenantId } | Sort-Object -Property ExpiresOn -Descending
  $token = $tokens[0].AccessToken
  $subscriptionId = $subscription.Id;
  Write-Host $subscriptionId
  Get-LogicAppHistory -Token $token -SubscriptionId $subscriptionId -resourceGroupName $resourceGroupName -logicAppName $logicAppName -Status $status -startDateTime $startDateTime -endDateTime $endDateTime -test $test
}
Write-Host "#######  Example 1 - subscriptionname / Failed #######" -BackgroundColor DarkGreen
Write-Host "ResubmitLogicApp -subscriptionName 'New ENT Subscription' -resourceGroupName 'resourceName' -logicAppName 'LogicAppName' -status 'Failed' -startDateTime '2020-06-16T00:00:00' -endDateTime '2020-06-25T08:42:00' -test true" -ForegroundColor Green
Write-Host "#######  Example 2 - subscriptionID / Succeeded  #######" -BackgroundColor DarkGreen
Write-Host "ResubmitLogicApp -subscriptionId 'guid' -resourceGroupName 'resourceName' -logicAppName 'LogicAppName' -status 'Succeeded' -startDateTime '2020-06-16T00:00:00' -endDateTime '2020-06-25T08:42:00' -test true" -ForegroundColor Green
Write-Host "#######  Set test to true/false if you just want to simulate the output or send for real  #######" -BackgroundColor DarkGreen

$input_ResourceGroup = "ResourceGroupName"
$input_logicAppName = "LogicAppName"
$input_status = "Failed"
$input_startDateTimeUTC = "2020-10-21T00:00:00"
$input_endDateTimeUTC = "2020-10-21T23:59:59"
$input_test = "true"

#ONE OR THE OTHER BELOW

#input_SubscriptionName
$input_SubscriptionName = "Microsoft Azure Enterprise"
ResubmitLogicApp -resourceGroupName $input_ResourceGroup -subscriptionName $input_SubscriptionName -logicAppName $input_logicAppName -status $input_status -startDateTime $input_startDateTimeUTC -endDateTime $input_endDateTimeUTC -test $input_test


#INPUT subscriptionId
#$input_subscriptionId = "guid"
#ResubmitLogicApp -resourceGroupName $input_ResourceGroup -subscriptionId $input_subscriptionId -logicAppName $input_logicAppName -status $input_status -startDateTime $input_startDateTimeUTC -endDateTime $input_endDateTimeUTC -test $input_test