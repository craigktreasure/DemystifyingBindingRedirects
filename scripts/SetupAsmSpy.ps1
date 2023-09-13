[CmdletBinding()]
param (
    [switch] $Force
)

$ErrorActionPreference = 'Stop'

$repoRoot = & git rev-parse --show-toplevel
$toolsFolder = Join-Path $repoRoot '__tools'
$toolsTempFolder = Join-Path $toolsFolder 'temp'
$toolsBinFolder = Join-Path $toolsFolder 'bin'
$asmSpyDownloadEndpoint = 'https://ci.appveyor.com/api/buildjobs/yfgfk2p6bfq425c4/artifacts/asmspy.1.3.136.nupkg'
$asmSpyPath = Join-Path $toolsBinFolder 'AsmSpy.exe'

function SetupToolsPaths() {
    New-Item -ItemType Directory -Force -Path $toolsTempFolder | Out-Null
    New-Item -ItemType Directory -Force -Path $toolsBinFolder | Out-Null
}

function SetupAsmSpy() {
    if (Test-Path $asmSpyPath) {
        Write-Host 'AsmSpy has already been downloaded.' -ForegroundColor Yellow
    }
    else {
        Write-Host 'Downloading AsmSpy...' -ForegroundColor Magenta
        $asmSpyDownloadFileName = Split-Path $asmSpyDownloadEndpoint -Leaf
        $asmSpyTempDownloadPath = Join-Path $toolsTempFolder $asmSpyDownloadFileName
        Invoke-WebRequest -Uri $asmSpyDownloadEndpoint -OutFile $asmSpyTempDownloadPath

        Write-Host 'Extracting AsmSpy...' -ForegroundColor Magenta
        $asmSpyTempExtractPath = Join-Path $toolsTempFolder ([System.IO.Path]::GetFileNameWithoutExtension($asmSpyDownloadFileName))
        Expand-Archive -Path $asmSpyTempDownloadPath -DestinationPath $asmSpyTempExtractPath

        $tempExePath = Join-Path $asmSpyTempExtractPath 'tools/AsmSpy.exe'
        Copy-Item -Path $tempExePath -Destination $asmSpyPath -Force

        Write-Host 'Cleaning up...' -ForegroundColor Magenta
        Remove-Item -Path $asmSpyTempDownloadPath -Force
        Remove-Item -Path $asmSpyTempExtractPath -Recurse -Force
    }
}

function AddToolsBinToPath() {
    if ($env:Path -like "*$toolsBinFolder*") {
        Write-Host 'AsmSpy has already been added to the PATH.' -ForegroundColor Yellow
    }
    else {
        Write-Host 'Add AsmSpy to the PATH...' -ForegroundColor Magenta
        $env:Path += ";$toolsBinFolder"
    }
}

function ForceClean() {
    Write-Host 'Cleaning to force a new install...' -ForegroundColor Magenta
    Remove-Item -Path $asmSpyPath -Force -ErrorAction SilentlyContinue | Out-Null
    Remove-Item -Path $toolsTempFolder -ErrorAction SilentlyContinue -Recurse -Force | Out-Null
}

if ($Force) {
    ForceClean
}

SetupToolsPaths
SetupAsmSpy
AddToolsBinToPath

Write-Host 'Done.' -ForegroundColor Green
