[CmdletBinding()]
param (
    [switch] $RunApp,
    [switch] $SwitchDependency,
    [switch] $KeepOldDependency
)

$ErrorActionPreference = 'Stop'

$projectFolder = $PSScriptRoot

function RunApp() {
    $projectFilePath = Get-Item -Path $projectFolder -Filter *.csproj
    $projectName = [System.IO.Path]::GetFileNameWithoutExtension($projectFilePath)
    & "./bin/Debug/net472/publish/$projectName.exe" Hello World!
}

function SwitchDependency() {
    $tempOutputPath = Join-Path $projectFolder 'obj/temp'
    $outputFilePath = Join-Path $tempOutputPath 'Newtonsoft.Json.13.0.3.nupkg'

    if (Test-Path $outputFilePath) {
        Write-Host 'The dependency has already been downloaded.' -ForegroundColor Yellow
    }
    else {
        Write-Host 'Downloading newer dependency...' -ForegroundColor Magenta
        New-Item -ItemType Directory -Force -Path $tempOutputPath | Out-Null
        Invoke-WebRequest -Uri 'https://www.nuget.org/api/v2/package/Newtonsoft.Json/13.0.3' -OutFile $outputFilePath
    }

    $extractPath = Join-Path $tempOutputPath 'Newtonsoft.Json.13.0.3'

    if (Test-Path $extractPath) {
        Write-Host 'The dependency has already been extracted.' -ForegroundColor Yellow
    }
    else {
        Write-Host 'Extracting the dependency...' -ForegroundColor Magenta
        Expand-Archive -Path $outputFilePath -DestinationPath $extractPath
    }

    $dependencyFileName = 'Newtonsoft.Json.dll'
    $newDependencyPath = Join-Path $extractPath "lib/net45/$dependencyFileName"
    $pathToOverwrite = Join-Path $projectFolder "bin/Debug/net472/publish/$dependencyFileName"

    if ($KeepOldDependency) {
        $maintainedDependencyFolderPath = Join-Path (Split-Path $pathToOverwrite -Parent) 'old'
        New-Item -ItemType Directory -Force -Path $maintainedDependencyFolderPath | Out-Null
        $maintainedDependencyPath = Join-Path $maintainedDependencyFolderPath $dependencyFileName
        Write-Host 'Keeping the old dependency...' -ForegroundColor Magenta
        Copy-Item -Path $pathToOverwrite -Destination $maintainedDependencyPath -Force
        return
    }

    Write-Host 'Overwriting the dependency from package version 12.0.3 with 13.0.3...' -ForegroundColor Magenta
    Copy-Item -Path $newDependencyPath -Destination $pathToOverwrite -Force
}

Push-Location $projectFolder
try {
    $publishOutputFolder = Join-Path $projectFolder 'bin/Debug/net472/publish'
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
