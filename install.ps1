#Requires -Version 5.1
<#
.SYNOPSIS
    WinCare Pro - One-liner installer/launcher
.DESCRIPTION
    Bootstrap entry point: irm https://raw.githubusercontent.com/joselucasdavidoliva-sudo/WinCare-PcruzTI/main/install.ps1 | iex
.PARAMETER Force
    Reinstala mesmo se a versão local for a mais recente.
.PARAMETER NoUpdate
    Não consulta a API do GitHub; apenas executa a versão já instalada.
.PARAMETER Uninstall
    Remove %LOCALAPPDATA%\WinCare-Pro inteiro e sai.
#>
[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$NoUpdate,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ----- Constants -----
$script:Repo        = 'joselucasdavidoliva-sudo/WinCare-PcruzTI'
$script:InstallDir  = Join-Path $env:LOCALAPPDATA 'WinCare-Pro'
$script:AppDir      = Join-Path $script:InstallDir 'app'
$script:VersionFile = Join-Path $script:InstallDir 'version.txt'
$script:EntryPoint  = Join-Path $script:AppDir 'WinCare.ps1'

# ----- Functions -----
function Test-AdminPrivilege {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $pr = New-Object Security.Principal.WindowsPrincipal($id)
    return [bool]$pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ----- Orchestrator -----
function Start-Bootstrap {
    [CmdletBinding()]
    param([switch]$Force, [switch]$NoUpdate, [switch]$Uninstall)
    $Global:WinCareBootstrapHasRun = $true
    throw 'Start-Bootstrap not yet implemented'
}

# ----- Entry guard -----
# Only run the orchestrator when invoked directly (NOT when dot-sourced for testing or via iex).
# When piped to iex, $MyInvocation.InvocationName is empty string; we use a marker.
if ($MyInvocation.Line -match 'install\.ps1' -or $MyInvocation.InvocationName -eq '&' -or $MyInvocation.InvocationName -eq '') {
    Start-Bootstrap -Force:$Force -NoUpdate:$NoUpdate -Uninstall:$Uninstall
}
