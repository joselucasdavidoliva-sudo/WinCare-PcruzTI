#Requires -Version 5.1
<#
.SYNOPSIS
    Carrega Pester (instalando se necessário) e executa todos os *.Tests.ps1.
#>
[CmdletBinding()]
param(
    [string]$Path
)

$ErrorActionPreference = 'Stop'

if (-not $Path) { $Path = Join-Path $PSScriptRoot '*.Tests.ps1' }

if (-not (Get-Item -Path $Path -ErrorAction SilentlyContinue)) {
    Write-Host "Nenhum arquivo *.Tests.ps1 em $Path — nada a executar." -ForegroundColor Yellow
    exit 0
}

# Pester 5 é o mínimo (sintaxe nova). Win10/11 vem com Pester 3 antigo no $PSHOME — ignorar.
$needed = '5.5.0'
$loaded = Get-Module Pester | Where-Object { $_.Version -ge [version]$needed }
if (-not $loaded) {
    $installed = Get-Module Pester -ListAvailable |
        Where-Object { $_.Version -ge [version]$needed } |
        Sort-Object Version -Descending | Select-Object -First 1
    if (-not $installed) {
        Write-Host "Instalando Pester $needed para CurrentUser..." -ForegroundColor Yellow
        Install-Module Pester -MinimumVersion $needed -Scope CurrentUser -Force -SkipPublisherCheck
        $installed = Get-Module Pester -ListAvailable |
            Where-Object { $_.Version -ge [version]$needed } |
            Sort-Object Version -Descending | Select-Object -First 1
    }
    Import-Module $installed.Path -Force
}

Invoke-Pester -Path $Path -Output Detailed
