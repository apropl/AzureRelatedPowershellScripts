param(
[Parameter(Mandatory = $false)][string]$subscriptionName,
[Parameter(Mandatory = $false)][string]$subscriptionId,
[Parameter(Mandatory = $true)][string]$resourceGroupName,
[Parameter(Mandatory = $true)][string]$logicAppName,
[Parameter(Mandatory = $true)][string]$status,
[Parameter(Mandatory = $true)]$startDateTime,
[Parameter(Mandatory = $true)]$endDateTime,
[Parameter(Mandatory = $true)][bool]$sendmessage
)

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
Write-Host
Write-Host "Subscription key: $subscriptionId" -ForegroundColor Green
Write-Host

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
      
      if($sendmessage)
      {
            Write-Host "Submitting" -ForegroundColor Green
            Write-Host $uri
            Write-Host
            Invoke-RestMethod -Method 'POST' -Uri $uri -Headers $headers
      }
      else
      {
            Write-Host "Test output - would submit" -ForegroundColor Yellow
            Write-Host $uri
            Write-Host
      }
  }
  while ($method.nextLink)
  {
    $nextLink = $method.nextLink; 
    Write-Host "Nextlink" -ForegroundColor Green
    Write-Host $nextLink
    $method = (Invoke-RestMethod -Uri $nextLink -Headers $headers -Method Get)
    $output = $method.value
    $messagecount = $messagecount + $output.Count
    foreach ($item in $output) {
          
        $uri = 'https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Logic/workflows/{2}/triggers/{3}/histories/{4}/resubmit?api-version=2016-06-01' -f $subscriptionId,$resourceGroupName,$logicAppName,$item.properties.Trigger.Name,$item.Name
        
        if($sendmessage)
        {
            Write-Host "Submitting" -ForegroundColor Green
            Write-Host $uri
            Write-Host
            Invoke-RestMethod -Method 'POST' -Uri $uri -Headers $headers
        }
        else
        {
            Write-Host "Test output - would submit" -ForegroundColor Yellow
            Write-Host $uri
            Write-Host
        }
    }
  }

  if($sendmessage)
{
    Write-Host
    
    Write-Host "Resubmit finished." -ForegroundColor Green
    Write-Host "Resubmitted $messagecount messages" -ForegroundColor Green
}
else
{
    Write-Host
    Write-Host "Test run finished." -ForegroundColor Yellow
    Write-Host "Would have submitted $messagecount messages. Change input parameter `$sendmessage to `$true and rerun the script." -ForegroundColor Yellow
    
}
  