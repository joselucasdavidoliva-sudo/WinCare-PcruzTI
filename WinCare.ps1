#Requires -Version 5.1
<#
.SYNOPSIS
    WinCare Pro - Suite completa de manutenção Windows
.VERSION 1.0.0
#>
$ErrorActionPreference = 'Continue'

$Global:WC = @{
    Version    = '1.0.0'
    AppName    = 'WinCare Pro'
    RootPath   = $PSScriptRoot
    LogPath    = Join-Path $PSScriptRoot 'output\logs'
    ConfigPath = Join-Path $PSScriptRoot 'core\Config.json'
}

function Test-AdminPrivilege {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-AdminPrivilege)) {
    Write-Host "Elevando para Administrador..." -ForegroundColor Yellow
    $argStr = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process -FilePath 'powershell.exe' -ArgumentList $argStr -Verb RunAs
    exit
}

# Core
foreach ($f in @('Logger','Config','UIBuilder')) {
    $p = Join-Path $PSScriptRoot "core\$f.ps1"
    if (Test-Path $p) { . $p } else { Write-Error "Core ausente: $f.ps1"; exit 1 }
}

# UI components
foreach ($f in @('Theme','ProgressPanel','LogViewer','Dashboard','Settings')) {
    $p = Join-Path $PSScriptRoot "ui\$f.ps1"
    if (Test-Path $p) { . $p }
}

# Módulos funcionais
foreach ($f in @(
    '01_WindowsMaintenance',
    '02_WindowsUpdate',
    '03_BugFixer_04_OfficeSuite',
    '05_RegistryRepair_06_AppRemover',
    '07_HealthCheck_08_ComponentTest',
    '09_WingetManager'
)) {
    $p = Join-Path $PSScriptRoot "modules\$f.ps1"
    if (Test-Path $p) { . $p }
}

# Inicializa e abre UI
Initialize-Logger
Initialize-Config
Write-Log "WinCare Pro v$($Global:WC.Version) iniciado em $env:COMPUTERNAME" -Level INFO
Start-WinCareUI
