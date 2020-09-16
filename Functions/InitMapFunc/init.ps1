$url = 'https://github.com/apropl/AzureRelatedPowershellScripts/blob/master/Functions/InitMapFunc/template.zip?raw=true'
$output = "$PSScriptRoot\template.zip"

#Get path
Write-Host "Getting path to function" -ForegroundColor Green # -BackgroundColor white
Start-Sleep -Seconds 1.5
$FunctionPath = Get-ChildItem -Path $PSScriptRoot -Recurse -File -Include "index.js" | Select-Object FullName

#Download files
Write-Host "Downloading template.zip - Start" -ForegroundColor Green # -BackgroundColor white
Start-Sleep -Seconds 1.5

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $url -OutFile $output

Write-Host "Downloading template.zip - Done" -ForegroundColor Green # -BackgroundColor white

#Template files
Write-Host "Replacing files - Start" -ForegroundColor Green # -BackgroundColor white
Start-Sleep -Seconds 1.5

Expand-Archive -Path template.zip -DestinationPath $PSScriptRoot\ -Force
Remove-Item template.zip -Force

#Replacing test-component with jest.
$filePath = "$PSScriptRoot\package.json"
(Get-Content $filePath).Replace('echo \"No tests yet...\"','jest') | Set-Content $filePath


#Replacing build pipeline values with jest.
Write-Host "Configuring build pipeline yml file" -ForegroundColor Green # -BackgroundColor white

$filePathBuild = "$PSScriptRoot\BuildPipeline.yml"

$ResourceGroup = Read-Host -Prompt 'Input ResourceGroup (Case Sensitive)'
$BusinessObject = Read-Host -Prompt 'Input Business Object (Case Sensitive)'
$currFolderName = Split-Path $PSScriptRoot -Leaf

(Get-Content $filePathBuild).Replace('RESOURCE_GROUP_NAME', $ResourceGroup) | Set-Content $filePathBuild
(Get-Content $filePathBuild).Replace('BUSINESS_OBJECT_NAME',$BusinessObject) | Set-Content $filePathBuild
(Get-Content $filePathBuild).Replace('FUNCTION_APP_NAME', $currFolderName) | Set-Content $filePathBuild

Rename-Item -Path $filePathBuild -NewName "$currFolderName.yml"

#Replace with boiler plate files and paths
foreach($File in $FunctionPath){

    $Path = $dirName=[System.IO.Path]::GetDirectoryName($File.Fullname)
 
    Copy-Item -Path $PSScriptRoot\index.js -Destination $Path -Force
    Copy-Item -Path $PSScriptRoot\index.test.js -Destination $Path -Force
    Copy-Item -Path $PSScriptRoot\map.js -Destination $Path -Force
	mkdir $Path\SampleFiles
	
    Copy-Item -Path $PSScriptRoot\sampletestfile.xml -Destination $Path\SampleFiles\ -Force
    #Replace test-file path
    $FunctionName = Split-Path $Path -Leaf
    (Get-Content $Path\index.test.js).Replace('/Transform/', '/' + $FunctionName + '/') | Set-Content $Path\index.test.js
}
Remove-Item $PSScriptRoot\index.js -Force
Remove-Item $PSScriptRoot\index.test.js -Force
Remove-Item $PSScriptRoot\map.js -Force
Remove-Item $PSScriptRoot\sampletestfile.xml -Force
Write-Host "Replacing files - Done" -ForegroundColor Green # -BackgroundColor white

#Npm packages
Write-Host "Installing node packages - Start" -ForegroundColor Green # -BackgroundColor white
Start-Sleep -Seconds 1.5

#fast-xml-parser
Write-Host "Installing fast-xml-parser - Start" -ForegroundColor Green # -BackgroundColor white
npm install fast-xml-parser
Write-Host "Installing fast-xml-parser - Done" -ForegroundColor Green # -BackgroundColor white
Start-Sleep -Seconds 1.5

#jest
Write-Host "Installing jest - Start" -ForegroundColor Green # -BackgroundColor white
npm install jest
Write-Host "Installing jest - Done" -ForegroundColor Green # -BackgroundColor white
Start-Sleep -Seconds 1.5

#jest-junit
Write-Host "Installing jest-junit - Start" -ForegroundColor Green # -BackgroundColor white
npm install --save-dev jest-junit
Write-Host "Installing jest-junit - Done" -ForegroundColor Green # -BackgroundColor white
Start-Sleep -Seconds 1.5

#libxmljs
Write-Host "Installing libxmljs - Start" -ForegroundColor Green # -BackgroundColor white
npm install libxmljs
Write-Host "Installing libxmljs - Done" -ForegroundColor Green # -BackgroundColor white

Write-Host "Installing node packages - Done" -ForegroundColor Green # -BackgroundColor white

Write-Host "Done preparing mapping function" -ForegroundColor Green # -BackgroundColor white
