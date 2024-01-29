[CmdletBinding()]
param (
    [switch] $RunApp,
    [switch] $SwitchDependency,
    [string] $SwitchDependencyPackageVersion = '13.0.3',
    [string] $SwitchDependencyTfm = 'net6.0'
)

$ErrorActionPreference = 'Stop'

$projectFolder = $PSScriptRoot

function RunApp() {
    $projectFilePath = Get-Item -Path $projectFolder -Filter *.csproj
    $projectName = [System.IO.Path]::GetFileNameWithoutExtension($projectFilePath)
    & "./bin/Debug/net8.0/publish/$projectName.exe" Hello World!
}

function SwitchDependency() {
    $tempOutputPath = Join-Path $projectFolder 'obj/temp'
    $outputFilePath = Join-Path $tempOutputPath "Newtonsoft.Json.$SwitchDependencyPackageVersion.nupkg"

    if (Test-Path $outputFilePath) {
        Write-Host 'The dependency has already been downloaded.' -ForegroundColor Yellow
    }
    else {
        Write-Host 'Downloading newer dependency...' -ForegroundColor Magenta
        New-Item -ItemType Directory -Force -Path $tempOutputPath | Out-Null
        Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/Newtonsoft.Json/$SwitchDependencyPackageVersion" -OutFile $outputFilePath
    }

    $extractPath = Join-Path $tempOutputPath "Newtonsoft.Json.$SwitchDependencyPackageVersion"

    if (Test-Path $extractPath) {
        Write-Host 'The dependency has already been extracted.' -ForegroundColor Yellow
    }
    else {
        Write-Host 'Extracting the dependency...' -ForegroundColor Magenta
        Expand-Archive -Path $outputFilePath -DestinationPath $extractPath
    }

    $newDependencyPath = Join-Path $extractPath "lib/$SwitchDependencyTfm/Newtonsoft.Json.dll"
    $pathToOverwrite = Join-Path $projectFolder 'bin/Debug/net8.0/publish/Newtonsoft.Json.dll'

    Write-Host "Overwriting the dependency from package version 12.0.3 with $SwitchDependencyPackageVersion..." -ForegroundColor Magenta
    Copy-Item -Path $newDependencyPath -Destination $pathToOverwrite -Force
}

Push-Location $projectFolder
try {
    $publishOutputFolder = Join-Path $projectFolder 'bin/Debug/net8.0/publish'
    if (Test-Path $publishOutputFolder) {
        Write-Host 'Cleaning the publish output folder...' -ForegroundColor Magenta
        Remove-Item -Path $publishOutputFolder -Recurse -Force
    }

    Write-Host 'Publishing the application...' -ForegroundColor Magenta
    & dotnet publish -c Debug

    if ($SwitchDependency) {
        Write-Host 'Switching the dependency...' -ForegroundColor Magenta
        SwitchDependency
    }

    if ($RunApp) {
        Write-Host 'Running the application...' -ForegroundColor Magenta
        RunApp
    }
}
finally {
    Pop-Location
}
