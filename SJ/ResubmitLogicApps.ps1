$resourceGroupName = "NordIntegration-prod-adp-rg"
$logicAppName = "INT-Employee-OUT-S-AllocationExecutor-SPBS"
$status = "Failed"
$startDateTime = "2020-10-21T00:00:00"
$endDateTime = "2020-10-21T23:59:59"
$test = "true"

#ONE OR THE OTHER BELOW
$subscriptionName = "Microsoft Azure Enterprise"
$subscriptionId = ""# "guid"

#param(
#[Parameter(Mandatory = $false)][string]$subscriptionName,
#[Parameter(Mandatory = $false)][string]$subscriptionId,
#[Parameter(Mandatory = $true)][string]$resourceGroupName,
#[Parameter(Mandatory = $true)][string]$logicAppName,
#[Parameter(Mandatory = $true)][string]$status,
#[Parameter(Mandatory = $true)][string]$startDateTime,
#[Parameter(Mandatory = $true)][string]$endDateTime,
#[Parameter(Mandatory = $true)][string]$test
#)
$currentAzureContext = Get-AzContext
if (!$currentAzureContext)
{
Connect-AzAccount
$currentAzureContext = Get-AzContext
}

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
  $messagecount = $output.Count
  foreach ($item in $output) {

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
  while ($method.nextLink)
  {
    $nextLink = $method.nextLink; 
    Write-Host $nextLink
    $method = (Invoke-RestMethod -Uri $nextLink -Headers $headers -Method Get)
    $output = $method.value
    $messagecount = $messagecount + $output.Count
    foreach ($item in $output) {
          
        $uri = 'https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Logic/workflows/{2}/triggers/{3}/histories/{4}/resubmit?api-version=2016-06-01' -f $subscriptionId,$resourceGroupName,$logicAppName,$item.properties.Trigger.Name,$item.Name
        
        if($test -eq "false")
        {
            Write-Host "Submitting" $uri
            Write-Host
            Invoke-RestMethod -Method 'POST' -Uri $uri -Headers $headers
        }
        else
        {
            Write-Host "Test output - would submit" $uri
            Write-Host
        }
    }
  }

  if($test -eq "false")
{
    Write-Host
    Write-Host "Resubmitted $messagecount messages" -ForegroundColor Green
}
else
{
    Write-Host
    Write-Host "Would have submitted $messagecount messages" -ForegroundColor Yellow
}
  