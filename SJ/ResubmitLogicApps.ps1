##Config BELOW!
#################################################################################

#Logic app configuration    
    $resourceGroupName = "NordIntegration-prod-adp-rg"
    $logicAppName = "INT-Employee-OUT-S-AllocationExecutor-SPBS"
    $status = "Failed"

#DateTime
    $startDateTime = "2020-10-21T00:00:00"

#Simulate a test run before sending the real thing?
    $sendmessage = $false #$true or $false

#Decide subscription either by name or GUID
#ONE OR THE OTHER BELOW
    $subscriptionName = "Microsoft Azure Enterprise"

#prod - 6c0c26ce-999b-4550-b46d-8084fc33f398
#dev  - ddcf588c-1b67-40b3-929d-1c7924ee0398
    $subscriptionId = ""

##Config ABOVE!
#################################################################################

$CurrentPath = Get-Location
cd $PSScriptRoot
# Run this command to generate Azure ARM templates 
./Resources/ResubmitLogicApps/Resubmit.ps1 $subscriptionName $subscriptionId $resourceGroupName $logicAppName $status $startDateTime $endDateTime $sendmessage

cd $CurrentPath