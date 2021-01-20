param(
[Parameter(Mandatory = $true)][string]$resourceName,
[Parameter(Mandatory = $true)][string]$outputDirectory,
[Parameter(Mandatory = $true)][string]$pipelineRelativePath,
[Parameter(Mandatory = $true)][string]$pipelineFolderpath,
[Parameter(Mandatory = $true)][string]$organization,
[Parameter(Mandatory = $true)][string]$project
)

Write-Host
Write-Host "## TRYING TO CREATE PIPELINE IN DEVOPS ##" -ForegroundColor Yellow # -BackgroundColor white
Write-Host "Usually OK to ignore the az errors with red text since they are mostly warnings!" -ForegroundColor Yellow # -BackgroundColor white
Write-Host

if(-Not (az extension show --name azure-devops))
{
    Write-Host "Azure extension missing... Trying to install now"
    az extension add --name azure-devops
}

if(-Not (az account show))
{
    Write-Host "az is not logged in. Need to login first" -ForegroundColor Yellow
    az login
}

if(-Not (az pipelines show --name $resourceName --folder-path $pipelineFolderpath --organization $organization --project $project))
{
    $manualPipelineCreation = $false
    
    Write-Host
    Write-Host "Pipeline for $resourceName is missing in Azure Devops. Do you want to create a pipeline?" -ForegroundColor Yellow # -BackgroundColor white
    $input = Read-Host -Prompt '[Y/N]'
    if ($input -eq 'Y')
    {
    
        $reponame = Split-Path -Leaf (git -C $outputDirectory remote get-url origin)
        $branchname = git -C $outputDirectory rev-parse --abbrev-ref HEAD       

        if($reponame -And $branchname)
        {
            az pipelines create --repository $reponame --branch $branchname --name $resourceName `
            --description "Pipeline for $resourceName" `
            --yml-path $pipelineRelativePath --folder-path $pipelineFolderpath `
            --repository-type tfsgit --organization $organization --project $project
           
            Write-Host
            Write-Host "Pipeline successfully created in devops!" -ForegroundColor Green
        }
        else
        {
            
            Write-Host
            Write-Host "Output directory is not in a git repo!" -ForegroundColor Yellow

            $manualPipelineCreation = $true
        }        
    }
    else
    {
        $manualPipelineCreation = $true            
    }

    if($manualPipelineCreation)
    {
        Write-Host
        Write-Host "Run the below command later to create your Azure DevOps pipline"
        Write-Host "Replace " -NoNewline
        Write-Host "YOURREPONAME" -ForegroundColor Yellow -NoNewline
        Write-Host  " and " -NoNewline
        Write-Host "YOURBRANCHNAME" -ForegroundColor Yellow
        Write-Host
        Write-Host "az pipelines create --repository " -NoNewline
        Write-Host "YOURREPONAME" -ForegroundColor Yellow -NoNewline
        Write-Host " --branch " -NoNewline
        Write-Host "YOURBRANCHNAME" -ForegroundColor Yellow -NoNewline
        Write-Host " --name $resourceName ``"
        Write-Host "--description 'Pipeline for $resourceName' ``"
        Write-Host "--yml-path $pipelineRelativePath --folder-path $pipelineFolderpath ``"
        Write-Host "--repository-type tfsgit --organization '$organization' --project '$project'"
        Write-Host
        Write-Host "Pipeline was not created in devops!" -ForegroundColor Yellow

        #NOTE
        #Can remove the following from the above if you are in a local Git directory that has a "remote" referencing a Azure DevOps or Azure DevOps Server repository.
        # --organization $organization --project $project
    }
}
else
{
    Write-Host "Pipeline allready exists in devops" -ForegroundColor Green
}