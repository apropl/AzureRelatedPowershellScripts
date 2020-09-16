##Config BELOW!

$functionApp = "INT-Employee-IN-P-MapEmployeeAllocationIVUSJOToSPBSJson"
$repoRootFolder = "C:\Repos\"

##Config ABOVE!

#param([string] $functionApp, [string] $repoRootFolder = "C:\Repos\")

if(!$functionApp)
{
    Write-Host "Terminating - You must provide a function app" -ForegroundColor Red # -BackgroundColor white
    exit
}

$url = 'https://github.com/apropl/AzureRelatedPowershellScripts/blob/master/Functions/InitUnitTestCSharpFunc/UnitTestTemplate.zip?raw=true'

$testProjectName = "$functionApp.Test"
$workingDirectory = "C:\Temp\InitUnitTest"

#Find the rootpath to the function app provided
Write-Host "Looking for function app: $functionApp in any foldername in $repoRootFolder" -ForegroundColor Green # -BackgroundColor white
$functionAppRootPath = (gci -path $repoRootFolder -filter $functionApp -Recurse)[0].FullName

if($functionAppRootPath)
{
    Write-Host "Found function app: $functionApp in $functionAppRootPath" -ForegroundColor Green # -BackgroundColor white
}
else
{
    Write-Host "Terminating - Cannot find the function app $functionApp in any foldername in $repoRootFolder" -ForegroundColor Red # -BackgroundColor white
    exit    
}


#Get the path of the directory where the function app fodler is located
$outputDirectory = [System.IO.Path]::GetDirectoryName($functionAppRootPath)

#Start by removing any leftover folders if they exist
If((test-path $workingDirectory\FunctionAppName.Test))
{
    Remove-Item -LiteralPath $workingDirectory\FunctionAppName.Test -Force -Recurse
}
If((test-path $workingDirectory\$testProjectName))
{
    Remove-Item -LiteralPath $workingDirectory\$testProjectName -Force -Recurse
}
If((test-path $outputDirectory\$testProjectName))
{

    Write-Host "$outputDirectory\$testProjectName allready exists, do you want to remove it? " -ForegroundColor Yellow # -BackgroundColor white
    $input = Read-Host -Prompt '[Y/N]'
    if ($input -eq 'Y'){
        Write-Host "Removing $outputDirectory\$testProjectName" -ForegroundColor Green # -BackgroundColor white
        Remove-Item -LiteralPath $outputDirectory\$testProjectName -Force -Recurse
    }
    else
    { 
        Write-Host "Terminating - Need to remove the existing unit test in order to continue. Be very careful here!" -ForegroundColor Red # -BackgroundColor white
        exit
    }
    
}


#Download files (if missing)
if (!(Test-Path $workingDirectory\UnitTestTemplate.zip)) {
    
    Write-Host "UnitTestTemplate.zip - Missing in working directory: $workingDirectory" -ForegroundColor Green # -BackgroundColor white
    Write-Host "Downloading UnitTestTemplate.zip - Start" -ForegroundColor Green # -BackgroundColor white
    Start-Sleep -Seconds 1.5
    
    If(!(test-path $workingDirectory))
    {
          Write-Host "WorkingDirectory missing, creating it now" -ForegroundColor Yellow # -BackgroundColor white
          New-Item -ItemType Directory -Force -Path $workingDirectory
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $workingDirectory\UnitTestTemplate.zip

    Write-Host "Downloading UnitTestTemplate.zip - End" -ForegroundColor Green # -BackgroundColor white
}
else {
    Write-Host "UnitTestTemplate.zip - Exists in working directory: $workingDirectory" -ForegroundColor Green # -BackgroundColor white
}

#Extract Zip-file
Write-Host "Extracting files - Start" -ForegroundColor Green # -BackgroundColor white
Start-Sleep -Seconds 1.5

Expand-Archive -Path $workingDirectory\UnitTestTemplate.zip -DestinationPath $workingDirectory\ -Force

Write-Host "Extracting files - End" -ForegroundColor Green # -BackgroundColor white

#Rename test folder and project file
Write-Host "Updating files and folders - Start" -ForegroundColor Green # -BackgroundColor white
Start-Sleep -Seconds 1.5

Rename-Item -Path "$workingDirectory\FunctionAppName.Test" -NewName "$testProjectName"
Rename-Item -Path "$workingDirectory\$testProjectName\FunctionAppName.csproj" -NewName "$testProjectName.csproj"

#Replace contents
$FunctionPath = Get-ChildItem -Path $workingDirectory\$testProjectName\ -Recurse -File | Select-Object FullName

foreach($File in $FunctionPath){

    (Get-Content $File.Fullname).Replace('FunctionAppNameNS', $functionApp.Replace('-','_')) | Set-Content $File.FullName
    (Get-Content $File.Fullname).Replace('FunctionAppName', $functionApp) | Set-Content $File.FullName
}

Write-Host "Updating files and folders - End" -ForegroundColor Green # -BackgroundColor white

#Move from working directory to repo
Write-Host "Moving testfolder from working directory - Start" -ForegroundColor Green # -BackgroundColor white
Start-Sleep -Seconds 1.5

If(!(test-path $outputDirectory))
{
      Write-Host "OutputDirectory missing, creating it now" -ForegroundColor Yellow # -BackgroundColor white
      New-Item -ItemType Directory -Force -Path $outputDirectory
}
Move-Item -Path $workingDirectory\$testProjectName -Destination $outputDirectory\$testProjectName -force

Write-Host "Moving testfolder from working directory - End" -ForegroundColor Green # -BackgroundColor white


#Add unit test project to function app solution

Write-Host "Adding unit test to function app solution - Start" -ForegroundColor Green # -BackgroundColor white
Start-Sleep -Seconds 1.5

#Find solution file for function app
$slnPath = Get-ChildItem -Path "$functionAppRootPath" -Recurse -File -Include "*.sln" | Select-Object FullName
#Get the path of the directory where the solution file is located
$solutionDirectory = [System.IO.Path]::GetDirectoryName($slnPath.FullName)

#Save current execution location
$executionLocation = $PSScriptRoot

#Set location to solution directory
Set-Location $solutionDirectory
#Compare the relative path to the unit test folder
$relativePath = Get-Item $outputDirectory\$testProjectName | Resolve-Path -Relative

#Reset to execution location
Set-Location $executionLocation

$guid = New-Guid

#only add to solution if solution file found and relative path found
if($slnPath -And $relativePath)
{
    #Add the Unit test project to the solution file
    #Assume the project is a C# project {FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}
    (Get-Content $slnPath.Fullname).Replace('EndProject',
    "EndProject" +
    "`r`n" +
    'Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "' + $testProjectName + '", "' + "$relativePath\$testProjectName.csproj" + '", "{' + $guid.ToString().ToUpper() + '}"' +
    "`r`n" +
    'EndProject'
    ) | Set-Content $slnPath.FullName

    Write-Host "Adding unit test to function app solution - End" -ForegroundColor Green # -BackgroundColor white
}
else
{
    Write-Host "Adding unit test to function app solution - Failed" -ForegroundColor Red # -BackgroundColor white
}

