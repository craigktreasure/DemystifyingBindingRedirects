#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [string] $LogPath
)

$ErrorActionPreference = 'Stop'

if (-not $LogPath) {
    $LogPath = Join-Path (Get-Location) 'logs'
}

New-Item -ItemType Directory -Force -Path $LogPath | Out-Null

Write-Host "Starting Fusion log recording to $LogPath..." -ForegroundColor Magenta

Set-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name LogPath  -Value $logPath -Type String
Set-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name ForceLog -Value 1        -Type DWord

Write-Host 'Press any key to stop recording...' -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

Write-Host "Stopping Fusion log recording..." -ForegroundColor Magenta

Remove-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name ForceLog
Remove-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name LogPath

$clearLogs = Read-Host 'Would you like to clear the log output? [Y/N]'
if ($clearLogs -eq 'Y') {
    Write-Host 'Clearing the log output...' -ForegroundColor Magenta
    Remove-Item -Path $LogPath -Recurse -Force
}

Write-Host 'Done.' -ForegroundColor Green
