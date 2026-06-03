<#
.SYNOPSIS
    Modulo 01 - Manutencao Corretiva e Preventiva do Windows
    WinCare Pro v1.0
#>

# -- Definicao das tarefas disponiveis -----------------------------------------
$Global:WM_Tasks = [ordered]@{

    # -- Integridade do Sistema ----------------------------------------------
    'SFC'         = @{
        Label    = 'SFC /scannow - Verificar e reparar arquivos de sistema'
        Group    = 'Integridade do Sistema'
        Default  = $true
        Action   = {
            Write-Log "Executando SFC /scannow (pode demorar alguns minutos)..." -Level INFO
            Update-Progress -Value 5 -Message "Iniciando SFC..."
            $result = & sfc /scannow 2>&1
            $result | ForEach-Object { Write-Log $_ -Level INFO }
            if ($LASTEXITCODE -eq 0) {
                Write-Log "SFC concluido com sucesso" -Level SUCCESS
            } else {
                Write-Log "SFC reportou problemas (verifique o log do Windows)" -Level WARN
            }
            Update-Progress -Value 20
        }
    }

    'DISM_Check'  = @{
        Label    = 'DISM - Verificar saude da imagem Windows'
        Group    = 'Integridade do Sistema'
        Default  = $true
        Action   = {
            Write-Log "DISM /Online /Cleanup-Image /CheckHealth..." -Level INFO
            Update-Progress -Value 22
            & DISM /Online /Cleanup-Image /CheckHealth 2>&1 | ForEach-Object { Write-Log $_ }
            Write-Log "DISM CheckHealth concluido" -Level SUCCESS
            Update-Progress -Value 30
        }
    }

    'DISM_Restore' = @{
        Label    = 'DISM - Restaurar saude da imagem Windows (online)'
        Group    = 'Integridade do Sistema'
        Default  = $false
        Action   = {
            Write-Log "DISM /Online /Cleanup-Image /RestoreHealth - requer internet..." -Level WARN
            Update-Progress -Value 30 -Message "Iniciando RestoreHealth (pode demorar)..."
            & DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | ForEach-Object { Write-Log $_ }
            Write-Log "DISM RestoreHealth concluido" -Level SUCCESS
            Update-Progress -Value 50
        }
    }

    # -- Rede ---------------------------------------------------------------
    'WinsockReset' = @{
        Label    = 'Reset Winsock e TCP/IP'
        Group    = 'Rede'
        Default  = $false
        Action   = {
            Write-Log "Resetando Winsock..." -Level INFO
            & netsh winsock reset 2>&1 | ForEach-Object { Write-Log $_ }
            Write-Log "Resetando TCP/IP..." -Level INFO
            & netsh int ip reset 2>&1 | ForEach-Object { Write-Log $_ }
            Write-Log "Limpando cache DNS..." -Level INFO
            & ipconfig /flushdns 2>&1 | ForEach-Object { Write-Log $_ }
            Write-Log "Rede resetada com sucesso. REINICIALIZAcaO NECESSaRIA." -Level SUCCESS
            Update-Progress -Value 55
        }
    }

    'NetAdapterReset' = @{
        Label    = 'Reset adaptadores de rede'
        Group    = 'Rede'
        Default  = $false
        Action   = {
            Write-Log "Resetando adaptadores de rede..." -Level INFO
            Get-NetAdapter | ForEach-Object {
                Write-Log "  Resetando: $($_.Name)" -Level INFO
                Disable-NetAdapter -Name $_.Name -Confirm:$false -ErrorAction SilentlyContinue
                Start-Sleep -Milliseconds 500
                Enable-NetAdapter -Name $_.Name -Confirm:$false -ErrorAction SilentlyContinue
            }
            Write-Log "Adaptadores resetados" -Level SUCCESS
            Update-Progress -Value 58
        }
    }

    # -- Limpeza ------------------------------------------------------------
    'TempFiles'    = @{
        Label    = 'Limpar arquivos temporarios (Temp, %Temp%, Prefetch)'
        Group    = 'Limpeza'
        Default  = $true
        Action   = {
            Write-Log "Limpando arquivos temporarios..." -Level INFO
            $paths = @(
                $env:TEMP,
                $env:TMP,
                'C:\Windows\Temp',
                'C:\Windows\Prefetch'
            )
            $totalRemoved = 0
            foreach ($p in $paths) {
                if (Test-Path $p) {
                    $items = Get-ChildItem $p -Recurse -Force -ErrorAction SilentlyContinue
                    $count = 0
                    foreach ($item in $items) {
                        try {
                            Remove-Item $item.FullName -Force -Recurse -ErrorAction Stop
                            $count++
                        } catch { }
                    }
                    Write-Log "  $p : $count itens removidos" -Level SUCCESS
                    $totalRemoved += $count
                }
            }
            Write-Log "Total removido: $totalRemoved itens temporarios" -Level SUCCESS
            Update-Progress -Value 62
        }
    }

    'RecycleBin'   = @{
        Label    = 'Esvaziar Lixeira'
        Group    = 'Limpeza'
        Default  = $false
        Action   = {
            Write-Log "Esvaziando Lixeira..." -Level INFO
            try {
                Clear-RecycleBin -Force -ErrorAction Stop
                Write-Log "Lixeira esvaziada" -Level SUCCESS
            } catch {
                Write-Log "Erro ao esvaziar lixeira: $_" -Level WARN
            }
            Update-Progress -Value 65
        }
    }

    'WindowsLogs'  = @{
        Label    = 'Limpar logs antigos do Windows (>30 dias)'
        Group    = 'Limpeza'
        Default  = $false
        Action   = {
            Write-Log "Limpando logs de eventos antigos..." -Level INFO
            $cutoff = (Get-Date).AddDays(-30)
            $logs = @('Application','System','Security','Setup')
            foreach ($log in $logs) {
                try {
                    $events = Get-EventLog -LogName $log -Before $cutoff -ErrorAction SilentlyContinue
                    if ($events) {
                        Write-Log "  $log`: $($events.Count) eventos antigos encontrados" -Level INFO
                    }
                } catch { }
            }
            Write-Log "Limpeza de logs concluida" -Level SUCCESS
            Update-Progress -Value 68
        }
    }

    'SoftDistrib'  = @{
        Label    = 'Limpar cache Windows Update (SoftwareDistribution)'
        Group    = 'Limpeza'
        Default  = $false
        Action   = {
            Write-Log "Parando servico Windows Update..." -Level INFO
            Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
            Stop-Service -Name bits    -Force -ErrorAction SilentlyContinue
            $sdPath = 'C:\Windows\SoftwareDistribution\Download'
            if (Test-Path $sdPath) {
                $count = (Get-ChildItem $sdPath -Recurse -Force -ErrorAction SilentlyContinue).Count
                Remove-Item "$sdPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "SoftwareDistribution limpa: $count itens removidos" -Level SUCCESS
            }
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
            Start-Service -Name bits     -ErrorAction SilentlyContinue
            Write-Log "Servicos Windows Update reiniciados" -Level SUCCESS
            Update-Progress -Value 72
        }
    }

    # -- Disco --------------------------------------------------------------
    'DiskCleanup'  = @{
        Label    = 'Limpeza de Disco (cleanmgr /sagerun)'
        Group    = 'Disco'
        Default  = $false
        Action   = {
            Write-Log "Executando Limpeza de Disco..." -Level INFO
            # Configura cleanmgr para rodar silencioso com todas as categorias
            $regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches'
            Get-ChildItem $regPath | ForEach-Object {
                Set-ItemProperty $_.PSPath -Name 'StateFlags0064' -Value 2 -Type DWord -ErrorAction SilentlyContinue
            }
            Start-Process -FilePath 'cleanmgr.exe' -ArgumentList '/sagerun:64' -Wait
            Write-Log "Limpeza de disco concluida" -Level SUCCESS
            Update-Progress -Value 78
        }
    }

    'Defrag'       = @{
        Label    = 'Otimizar/Desfragmentar disco C:'
        Group    = 'Disco'
        Default  = $false
        Action   = {
            Write-Log "Verificando tipo de disco C:..." -Level INFO
            $disk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq 0 }
            if ($disk -and $disk.MediaType -eq 'SSD') {
                Write-Log "SSD detectado - executando TRIM em vez de desfragmentacao" -Level INFO
                & defrag C: /L /U 2>&1 | ForEach-Object { Write-Log $_ }
            } else {
                Write-Log "HDD detectado - iniciando desfragmentacao (pode demorar)..." -Level WARN
                & defrag C: /U /V 2>&1 | ForEach-Object { Write-Log $_ }
            }
            Write-Log "Otimizacao de disco concluida" -Level SUCCESS
            Update-Progress -Value 84
        }
    }

    'ChkdskSched'  = @{
        Label    = 'Agendar CHKDSK na proxima reinicializacao'
        Group    = 'Disco'
        Default  = $false
        Action   = {
            Write-Log "Agendando CHKDSK para proxima reinicializacao..." -Level WARN
            & chkntfs /x C: 2>&1 | Out-Null
            Write-Output "Y" | chkdsk C: /f /r /x 2>&1 | ForEach-Object { Write-Log $_ }
            Write-Log "CHKDSK agendado. Execute com 'chkdsk C: /f /r' ou reinicie o sistema." -Level SUCCESS
            Update-Progress -Value 88
        }
    }

    # -- Boot ---------------------------------------------------------------
    'BCDRepair'    = @{
        Label    = 'Reparar dados de inicializacao (BCD)'
        Group    = 'Boot'
        Default  = $false
        Action   = {
            Write-Log "ATENcaO: Reparo do BCD - operacao critica!" -Level WARN
            Write-Log "Fazendo backup do BCD atual..." -Level INFO
            $bcdbak = Join-Path $Global:WC.LogPath "bcd_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').bak"
            & bcdedit /export $bcdbak 2>&1 | ForEach-Object { Write-Log $_ }
            Write-Log "Backup salvo em: $bcdbak" -Level SUCCESS
            Write-Log "Reconstruindo BCD..." -Level INFO
            & bootrec /fixmbr 2>&1 | ForEach-Object { Write-Log $_ }
            & bootrec /fixboot 2>&1 | ForEach-Object { Write-Log $_ }
            & bootrec /scanos 2>&1 | ForEach-Object { Write-Log $_ }
            & bootrec /rebuildbcd 2>&1 | ForEach-Object { Write-Log $_ }
            Write-Log "Reparo BCD concluido" -Level SUCCESS
            Update-Progress -Value 93
        }
    }

    # -- Servicos -----------------------------------------------------------
    'CritServices' = @{
        Label    = 'Verificar e restaurar servicos criticos do Windows'
        Group    = 'Servicos'
        Default  = $true
        Action   = {
            Write-Log "Verificando servicos criticos do Windows..." -Level INFO
            $criticalServices = @(
                @{ Name='wuauserv';   Display='Windows Update'         },
                @{ Name='bits';       Display='Background Transfer'    },
                @{ Name='cryptsvc';   Display='Cryptographic Services' },
                @{ Name='msiserver';  Display='Windows Installer'      },
                @{ Name='trustedinstaller'; Display='Trusted Installer' },
                @{ Name='winmgmt';    Display='WMI'                    },
                @{ Name='eventlog';   Display='Event Log'              },
                @{ Name='spooler';    Display='Print Spooler'          }
            )
            foreach ($svc in $criticalServices) {
                $s = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
                if ($null -eq $s) {
                    Write-Log "  $($svc.Display): NaO ENCONTRADO" -Level WARN
                } elseif ($s.Status -ne 'Running') {
                    Write-Log "  $($svc.Display): Parado - tentando iniciar..." -Level WARN
                    try {
                        Start-Service -Name $svc.Name -ErrorAction Stop
                        Write-Log "  $($svc.Display): Iniciado com sucesso" -Level SUCCESS
                    } catch {
                        Write-Log "  $($svc.Display): Falha ao iniciar - $_" -Level ERROR
                    }
                } else {
                    Write-Log "  $($svc.Display): OK (em execucao)" -Level SUCCESS
                }
            }
            Update-Progress -Value 97
        }
    }
}

# -- UI do Modulo ---------------------------------------------------------------
function Show-WindowsMaintenance {
    $area = $Global:WC.ModuleArea
    $area.Controls.Clear()

    $scroll = New-Object System.Windows.Forms.Panel
    $scroll.Dock       = 'Fill'
    $scroll.AutoScroll = $true
    $scroll.BackColor  = $Global:Theme.BG_Deep
    $area.Controls.Add($scroll)

    $y = 80

    # Titulo do modulo
    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text      = "Manutencao do Windows"
    $lblTitle.Font      = $Global:Theme.Font_Title
    $lblTitle.ForeColor = $Global:Theme.Text_Primary
    $lblTitle.Location  = New-Object System.Drawing.Point(32, $y)
    $lblTitle.AutoSize  = $true
    $scroll.Controls.Add($lblTitle)
    $y += 36

    $lblDesc = New-Object System.Windows.Forms.Label
    $lblDesc.Text      = "Selecione as operacoes desejadas e clique em Executar. Itens marcados por padrao sao seguros para uso regular."
    $lblDesc.Font      = $Global:Theme.Font_Body
    $lblDesc.ForeColor = $Global:Theme.Text_Muted
    $lblDesc.Location  = New-Object System.Drawing.Point(32, $y)
    $lblDesc.Size      = New-Object System.Drawing.Size(700, 18)
    $scroll.Controls.Add($lblDesc)
    $y += 32

    # Organiza tarefas por grupo
    $groups = $Global:WM_Tasks.Values | Group-Object { $_.Group }
    $Global:WC.WM = @{ Chks = @{} }

    foreach ($group in $groups) {
        # Cabecalho de grupo
        $sep = New-SectionLabel -Text $group.Name -X 32 -Y $y -Width 500
        $scroll.Controls.Add($sep)
        $y += 30

        $groupLine = New-Separator -X 32 -Y $y -Width 660
        $scroll.Controls.Add($groupLine)
        $y += 10

        foreach ($task in $group.Group) {
            $key = ($Global:WM_Tasks.Keys | Where-Object { $Global:WM_Tasks[$_] -eq $task })

            # Badge de aviso para tarefas criticas
            $isRisky = $key -in @('BCDRepair','ChkdskSched','DISM_Restore','NetAdapterReset')

            $text = if ($isRisky) { "[!] $($task.Label)" } else { "    $($task.Label)" }
            $chk  = New-StyledCheckBox -Text $text -X 32 -Y $y -Width 680
            $chk.Checked = $task.Default
            if ($isRisky) { $chk.ForeColor = $Global:Theme.Warning }
            $scroll.Controls.Add($chk)
            $Global:WC.WM.Chks[$key] = $chk
            $y += 28
        }
        $y += 8
    }

    $y += 8

    # -- Botoes de acao ---------------------------------------------------------
    $btnAll = New-StyledButton -Text '[v] Marcar Tudo' -X 32 -Y $y -Width 140 -Height 34 -Style 'Secondary'
    $btnAll.Add_Click({
        foreach ($chk in $Global:WC.WM.Chks.Values) { $chk.Checked = $true }
    })
    $scroll.Controls.Add($btnAll)

    $btnNone = New-StyledButton -Text '[ ] Desmarcar Tudo' -X 168 -Y $y -Width 150 -Height 34 -Style 'Secondary'
    $btnNone.Add_Click({
        foreach ($chk in $Global:WC.WM.Chks.Values) { $chk.Checked = $false }
    })
    $scroll.Controls.Add($btnNone)

    $btnDefault = New-StyledButton -Text '<- Restaurar Padrao' -X 326 -Y $y -Width 155 -Height 34 -Style 'Secondary'
    $btnDefault.Add_Click({
        foreach ($key in $Global:WC.WM.Chks.Keys) {
            $Global:WC.WM.Chks[$key].Checked = $Global:WM_Tasks[$key].Default
        }
    })
    $scroll.Controls.Add($btnDefault)

    $y += 50

    # Aviso de backup
    $lblWarn = New-Object System.Windows.Forms.Label
    $lblWarn.Text      = "  [i]  Um ponto de restauracao sera criado automaticamente antes das operacoes marcadas com [!]"
    $lblWarn.Font      = $Global:Theme.Font_Small
    $lblWarn.ForeColor = $Global:Theme.Info
    $lblWarn.Location  = New-Object System.Drawing.Point(32, $y)
    $lblWarn.Size      = New-Object System.Drawing.Size(680, 18)
    $scroll.Controls.Add($lblWarn)
    $y += 28

    # Botao EXECUTAR
    $btnRun = New-StyledButton -Text '>  EXECUTAR MANUTENCAO' -X 32 -Y $y -Width 260 -Height 44 -Style 'Primary'
    $btnRun.Font = $Global:Theme.Font_Header

    $btnRun.Add_Click({
        $selected = [ordered]@{}
        foreach ($key in $Global:WC.WM.Chks.Keys) {
            if ($Global:WC.WM.Chks[$key].Checked) { $selected[$key] = $Global:WM_Tasks[$key] }
        }

        if ($selected.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "Nenhuma operacao selecionada!",
                "WinCare Pro", 'OK', 'Warning') | Out-Null
            return
        }

        # Confirma operacoes perigosas
        $risky = $selected.Keys | Where-Object { $_ -in @('BCDRepair','ChkdskSched','DISM_Restore') }
        if ($risky) {
            $msg = "As seguintes operacoes sao de alto risco e modificam componentes criticos:`n`n"
            $risky | ForEach-Object { $msg += "  • $($selected[$_].Label)`n" }
            $msg += "`nDeseja continuar?"
            $resp = [System.Windows.Forms.MessageBox]::Show($msg, "[!] Atencao - WinCare Pro", 'YesNo', 'Warning')
            if ($resp -ne 'Yes') { return }
        }

        # Desabilita botao durante execucao
        $this.Enabled   = $false
        $this.Text      = 'Executando...'
        $this.BackColor = $Global:Theme.AccentDim
        $Global:WC._runBtn = $this

        # Prepara dados serializaveis: labels, action source strings, e flags de risco
        $taskData = [ordered]@{}
        foreach ($key in $selected.Keys) {
            $taskData[$key] = @{
                Label      = $selected[$key].Label
                ActionCode = $selected[$key].Action.ToString()
            }
        }
        $riskyKeys = @('BCDRepair','ChkdskSched','DISM_Restore','WinsockReset')

        $task = {
            Write-Log "==========================================" -Level INFO
            Write-Log " INICIANDO MANUTENcaO DO WINDOWS" -Level INFO
            Write-Log " Operacoes selecionadas: $($taskData.Count)" -Level INFO
            Write-Log "==========================================" -Level INFO

            # Cria ponto de restauracao se houver ops de risco
            $hasRisky = $taskData.Keys | Where-Object { $_ -in $riskyKeys }
            if ($hasRisky) {
                Write-Log "Criando ponto de restauracao do sistema..." -Level WARN
                try {
                    Enable-ComputerRestore -Drive 'C:\' -ErrorAction SilentlyContinue
                    Checkpoint-Computer -Description "WinCare Pro - Pre-manutencao $(Get-Date -Format 'yyyy-MM-dd HH:mm')" `
                                        -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
                    Write-Log "Ponto de restauracao criado com sucesso" -Level SUCCESS
                } catch {
                    Write-Log "Aviso: nao foi possivel criar ponto de restauracao: $_" -Level WARN
                }
            }

            $i = 0
            $total = $taskData.Count

            foreach ($key in $taskData.Keys) {
                $i++
                $pct = [Math]::Round(($i / $total) * 100)
                Write-Log "--- [$i/$total] $($taskData[$key].Label)" -Level INFO
                Update-Progress -Value ([Math]::Max($pct - 5, 1))
                try {
                    # Recria o scriptblock no contexto deste runspace
                    $action = [ScriptBlock]::Create($taskData[$key].ActionCode)
                    & $action
                } catch {
                    Write-Log "ERRO em $key`: $_" -Level ERROR
                }
            }

            Write-Log "==========================================" -Level SUCCESS
            Write-Log " MANUTENcaO CONCLUiDA" -Level SUCCESS
            Write-Log "==========================================" -Level SUCCESS
            Update-Progress -Value 100
        }

        Invoke-ModuleTask -Task $task -TaskName 'Manutencao Windows' `
            -Variables @{ taskData = $taskData; riskyKeys = $riskyKeys } `
            -OnComplete {
                if ($Global:WC._runBtn) { $Global:WC._runBtn.Enabled=$true; $Global:WC._runBtn.Text='>  EXECUTAR MANUTENCAO'; $Global:WC._runBtn.BackColor=$Global:Theme.Accent }
            }
    })

    $scroll.Controls.Add($btnRun)

    Update-Status "Modulo: Manutencao Windows"
}
