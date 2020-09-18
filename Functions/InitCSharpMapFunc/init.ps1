##Config BELOW!

#Complete output directory
$outputDirectory = "C:\Repos\EMP-Employee\Functions"

#Function App information
$functionAppName = "INT-Employee-IN-P-MapEmployeeAllocationIVUSJOToSPBSJson"
#Default functionName = Transform. Change this if you wish
$functionName = "Transform"

#Azure Information
$businessobject = "Employee"

##Config ABOVE!

#param([string] $functionAppName, [string] $functionName, [string] $businessobject, [string] $outputDirectory = "C:\Repos\businessobject\Functions\")

$zipFileName = 'InitCSharpMapFunc.zip'
$url = "https://github.com/apropl/AzureRelatedPowershellScripts/blob/master/Functions/InitCSharpMapFunc/InitCSharpMapFunc.zip?raw=true"
$workingDirectory = "C:\Temp\InitCSharpMapFunc"
$workingfolderName = "MapFunctionAppName"
$FuncWorkingDirectory = "$workingDirectory\$workingfolderName"
$TestWorkingDirectory = "$workingDirectory\$workingfolderName.Test"

#Start by removing any leftover folders if they exist
If((test-path $FuncWorkingDirectory))
{
    Remove-Item -LiteralPath $FuncWorkingDirectory -Force -Recurse
}
If((test-path "$workingDirectory\$functionAppName"))
{
    Remove-Item -LiteralPath "$workingDirectory\$functionAppName" -Force -Recurse
}
If((test-path "$outputDirectory\$functionAppName"))
{

    Write-Host "$outputDirectory\$functionAppName allready exists, do you want to remove it? Be very careful here!" -ForegroundColor Yellow # -BackgroundColor white
    $input = Read-Host -Prompt '[Y/N]'
    if ($input -eq 'Y'){
        Write-Host "Removing $outputDirectory\$functionAppName" -ForegroundColor Green # -BackgroundColor white
        Remove-Item -LiteralPath "$outputDirectory\$functionAppName" -Force -Recurse

        If((test-path "$outputDirectory\$functionAppName.Test"))
        {
            Remove-Item -LiteralPath "$outputDirectory\$functionAppName.Test" -Force -Recurse
        }
    }
    else
    { 
        Write-Host "Terminating - Need to remove the existing API in order to continue." -ForegroundColor Red # -BackgroundColor white
        exit
    }
    
}

#Download files (if missing)
if (!(Test-Path $workingDirectory\$zipFileName)) {
    
    Write-Host "$zipFileName - Missing in working directory: $workingDirectory" -ForegroundColor Green # -BackgroundColor white
    Write-Host "Downloading $zipFileName - Start" -ForegroundColor Green # -BackgroundColor white
    
    If(!(test-path $workingDirectory))
    {
          Write-Host "WorkingDirectory missing, creating it now" -ForegroundColor Yellow # -BackgroundColor white
          New-Item -ItemType Directory -Force -Path $workingDirectory
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $workingDirectory\$zipFileName

    Write-Host "Downloading $zipFileName - End" -ForegroundColor Green # -BackgroundColor white
}
else {

    Write-Host "$zipFileName - Exists in working directory: $workingDirectory. Do you want to redownload?" -ForegroundColor Yellow # -BackgroundColor white

     $input = Read-Host -Prompt '[Y/N]'
    if ($input -eq 'Y'){
        Write-Host "Downloading $zipFileName - Start" -ForegroundColor Green # -BackgroundColor white
    
        If(!(test-path $workingDirectory))
        {
              Write-Host "WorkingDirectory missing, creating it now" -ForegroundColor Yellow # -BackgroundColor white
              New-Item -ItemType Directory -Force -Path $workingDirectory
        }

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $url -OutFile $workingDirectory\$zipFileName

        Write-Host "Downloading $zipFileName - End" -ForegroundColor Green # -BackgroundColor white
    }
    else
    { 
        Write-Host "Skipping redownloading zip file." -ForegroundColor yellow # -BackgroundColor white
    }
}

#Extract Zip-file
Write-Host "Extracting files - Start" -ForegroundColor Green # -BackgroundColor white

Expand-Archive -Path $workingDirectory\$zipFileName -DestinationPath $workingDirectory\ -Force

Write-Host "Extracting files - End" -ForegroundColor Green # -BackgroundColor white

#Rename FuncApp folder
Write-Host "Updating files and folders - Start" -ForegroundColor Green # -BackgroundColor white

Rename-Item -Path $FuncWorkingDirectory -NewName "$functionAppName"

#Replace contents
$FunctionPath = Get-ChildItem -Path $workingDirectory\$functionAppName\ -Recurse -File | Select-Object FullName

$guid1 = New-Guid
$guid2 = New-Guid
$guid3 = New-Guid

foreach($File in $FunctionPath){

    (Get-Content $File.Fullname).Replace('Function_App_Name_NS', $functionAppName.Replace('-','_')) | Set-Content $File.FullName
    (Get-Content $File.Fullname).Replace('Function_App_Name', $functionAppName) | Set-Content $File.FullName
    (Get-Content $File.Fullname).Replace('Function_Name', $functionName) | Set-Content $File.FullName
    (Get-Content $File.Fullname).Replace('Business_Object', $businessobject.ToLower()) | Set-Content $File.FullName
    (Get-Content $File.Fullname).Replace('MapFunctionSolutionGuid', $guid1.ToString().ToUpper()) | Set-Content $File.FullName
    (Get-Content $File.Fullname).Replace('MapFunctionProjectGuid', $guid2.ToString().ToUpper()) | Set-Content $File.FullName
    (Get-Content $File.Fullname).Replace('MapFunctionTestGuid', $guid3.ToString().ToUpper()) | Set-Content $File.FullName
    
    
    #Rename filenames to func app name
    if ([String]$File.FullName -like "*$workingfolderName*"){
    $newname = ([String]$File.FullName).Replace($workingfolderName, "$functionAppName")
    Rename-item -Path $File.FullName -NewName $newname
    }

    #Rename filenames to func app name
    if ([String]$File.FullName -like '*FunctionName*'){
    $newname2 = ([String]$File.FullName).Replace('FunctionName', "$functionName")
    Rename-item -Path $File.FullName -NewName $newname2
    }
    
}

#Replace contents of test project
Rename-Item -Path "$TestWorkingDirectory" -NewName "$functionAppName.Test"
Rename-Item -Path "$workingDirectory\$functionAppName.Test\FunctionAppName.csproj" -NewName "$functionAppName.Test.csproj"

$FunctionPath = Get-ChildItem -Path $workingDirectory\$functionAppName.Test\ -Recurse -File | Select-Object FullName

foreach($File in $FunctionPath){

    (Get-Content $File.Fullname).Replace('Function_App_Name_NS', $functionAppName.Replace('-','_')) | Set-Content $File.FullName
    (Get-Content $File.Fullname).Replace('Function_App_Name', $functionAppName) | Set-Content $File.FullName

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
Move-Item -Path $workingDirectory\$functionAppName -Destination $outputDirectory\$functionAppName -force
Move-Item -Path $workingDirectory\$functionAppName.Test -Destination $outputDirectory\$functionAppName.Test -force

Write-Host "Moving testfolder from working directory - End" -ForegroundColor Green # -BackgroundColor white
