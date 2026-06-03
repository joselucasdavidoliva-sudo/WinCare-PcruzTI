<#
.SYNOPSIS
    Logger centralizado do WinCare Pro
#>

function Initialize-Logger {
    $logDir = $Global:WC.LogPath
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    $date = Get-Date -Format 'yyyy-MM-dd'
    $Global:WC.CurrentLog = Join-Path $logDir "WinCare_$date.log"
    Write-Log "---------------------------------------" -Level INFO
    Write-Log " WinCare Pro v$($Global:WC.Version) - Sessao iniciada" -Level INFO
    Write-Log " Computador : $env:COMPUTERNAME" -Level INFO
    Write-Log " Usuario    : $env:USERNAME" -Level INFO
    Write-Log " Data/Hora  : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" -Level INFO
    Write-Log "---------------------------------------" -Level INFO
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR','SUCCESS','DEBUG')]
        [string]$Level = 'INFO',
        [switch]$NoFile
    )

    $timestamp = Get-Date -Format 'HH:mm:ss'
    $prefix = switch ($Level) {
        'INFO'    { '[INFO]' }
        'WARN'    { '[AVISO]' }
        'ERROR'   { '[ERRO]' }
        'SUCCESS' { '[OK]' }
        'DEBUG'   { '[DEBUG]' }
    }

    $line = "$timestamp $prefix $Message"

    # Saída no arquivo
    if (-not $NoFile -and $Global:WC.CurrentLog) {
        Add-Content -Path $Global:WC.CurrentLog -Value $line -Encoding UTF8
    }

    # Saída no console (cores)
    $color = switch ($Level) {
        'INFO'    { 'Cyan' }
        'WARN'    { 'Yellow' }
        'ERROR'   { 'Red' }
        'SUCCESS' { 'Green' }
        'DEBUG'   { 'Gray' }
    }
    Write-Host $line -ForegroundColor $color

    # Notifica painel de log da UI se estiver ativo
    if ($Global:WC.LogTextBox -and $Global:WC.LogTextBox.IsHandleCreated) {
        $Global:WC.LogTextBox.Invoke([Action]{
            $Global:WC.LogTextBox.AppendText("$line`r`n`r`n")
            $Global:WC.LogTextBox.ScrollToCaret()
        })
    }
}

function Get-LogContent {
    if ($Global:WC.CurrentLog -and (Test-Path $Global:WC.CurrentLog)) {
        return Get-Content $Global:WC.CurrentLog -Encoding UTF8
    }
    return @()
}

function Export-LogReport {
    param([string]$DestinationPath)
    if ($Global:WC.CurrentLog -and (Test-Path $Global:WC.CurrentLog)) {
        Copy-Item $Global:WC.CurrentLog -Destination $DestinationPath
        Write-Log "Log exportado para: $DestinationPath" -Level SUCCESS
    }
}
