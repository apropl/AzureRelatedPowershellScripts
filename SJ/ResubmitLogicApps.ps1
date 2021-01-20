##Config BELOW!
#################################################################################

#Logic app configuration    
    $resourceGroupName = "integration-common-prod-adp-rg"
    $logicAppName = "INT-Report-IN-P-ReportsSjo-Stratiteq"
    $status = "Failed" # Succeeded | Failed | Cancelled | Skipped

#DateTime (UTC)
    $startDateTime = "2020-11-09T00:00:00"
    $endDateTime = "2020-11-09T13:00:00"

#Simulate a test run before sending the real thing?
    $sendmessage = $false #$true | $false

#Decide subscription either by name or GUID
#ONE OR THE OTHER BELOW. Send empty string for one the one not used...
#Prod - Microsoft Azure Enterprise | 6c0c26ce-999b-4550-b46d-8084fc33f398
#Dev  - Enterprise Dev/Test | ddcf588c-1b67-40b3-929d-1c7924ee0398

#Either name
    $subscriptionName = "Microsoft Azure Enterprise"

#Or guid
    $subscriptionId = ""

##Config ABOVE!
#################################################################################

#Execute script
. "$PSScriptRoot\Resources\ResubmitLogicApps\Resubmit.ps1" $subscriptionName $subscriptionId $resourceGroupName $logicAppName $status $startDateTime $endDateTime $sendmessage