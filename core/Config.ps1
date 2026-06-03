<#
.SYNOPSIS
    Configurações globais e preferências do WinCare Pro
#>

$Global:WC_DefaultConfig = @{
    Theme           = 'Dark'
    Language        = 'pt-BR'
    AutoBackup      = $true
    LogRetentionDays= 30
    AutoScroll      = $true
    ShowDebug       = $false
    WingetPath      = ''
    LastHealthScore = 0
    FirstRun        = $true
}

function Initialize-Config {
    $configPath = $Global:WC.ConfigPath
    $configDir  = Split-Path $configPath -Parent

    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    if (Test-Path $configPath) {
        try {
            $json = Get-Content $configPath -Raw -Encoding UTF8
            $loaded = $json | ConvertFrom-Json
            $Global:WC.Config = @{}
            $loaded.PSObject.Properties | ForEach-Object {
                $Global:WC.Config[$_.Name] = $_.Value
            }
            # Garante que chaves novas existam
            foreach ($key in $Global:WC_DefaultConfig.Keys) {
                if (-not $Global:WC.Config.ContainsKey($key)) {
                    $Global:WC.Config[$key] = $Global:WC_DefaultConfig[$key]
                }
            }
        } catch {
            Write-Log "Config corrompido, usando padrão: $_" -Level WARN
            $Global:WC.Config = $Global:WC_DefaultConfig.Clone()
        }
    } else {
        $Global:WC.Config = $Global:WC_DefaultConfig.Clone()
        Save-Config
    }

    Write-Log "Configurações carregadas" -Level INFO
}

function Save-Config {
    try {
        $Global:WC.Config | ConvertTo-Json -Depth 5 |
            Set-Content -Path $Global:WC.ConfigPath -Encoding UTF8
    } catch {
        Write-Log "Erro ao salvar config: $_" -Level ERROR
    }
}

function Get-Config {
    param([string]$Key)
    return $Global:WC.Config[$Key]
}

function Set-Config {
    param([string]$Key, $Value)
    $Global:WC.Config[$Key] = $Value
    Save-Config
}
