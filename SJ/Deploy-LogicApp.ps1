
# An example of how to use the Deploy-AzureResourceGroup.ps1 to deploy a Logic App from your local dev machine 

Set-Location C:\code\TRC-TrainComposition\LogicApps\INT-TrainComposition-IN-E-OperaRPS\
C:\code\TRC-TrainComposition\LogicApps\INT-TrainComposition-IN-E-OperaRPS\Deploy-AzureResourceGroup.ps1 -ResourceGroupLocation "West Europe" -ResourceGroupName "NordIntegration-dev-adp-rg" `
    -StorageAccountName "sjidpdevopsartifactssa" -StorageContainerName "LocalDev-stageartifacts" `
    -TemplateFile "INT-TrainComposition-IN-E-OperaRPS.template.json" -TemplateParametersFile "INT-TrainComposition-IN-E-OperaRPS.parameters-dev.json" `
    -ArtifactStagingDirectory "." -DSCSourceFolder "DSC"
Set-Location C:\code\Common\Development\Scripts\



