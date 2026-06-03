<#
.SYNOPSIS
    Tela de Configurações - WinCare Pro v1.0
#>

function Show-Settings {
    $area = $Global:WC.ModuleArea; $area.Controls.Clear()
    $scroll = New-Object System.Windows.Forms.Panel
    $scroll.Dock = 'Fill'; $scroll.AutoScroll = $true
    $scroll.BackColor = $Global:Theme.BG_Deep; $area.Controls.Add($scroll); $y = 80

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Configuracoes"
    $lbl.Font = $Global:Theme.Font_Title; $lbl.ForeColor = $Global:Theme.Text_Primary
    $lbl.Location = New-Object System.Drawing.Point(32,$y); $lbl.AutoSize = $true
    $scroll.Controls.Add($lbl); $y += 40

    # ── Seção: Comportamento ─────────────────────────────────────────────────
    $sl1 = New-SectionLabel -Text 'Comportamento' -X 32 -Y $y; $scroll.Controls.Add($sl1); $y += 30
    $ln1 = New-Separator -X 32 -Y $y -Width 680; $scroll.Controls.Add($ln1); $y += 14

    $chkBackup   = New-StyledCheckBox -Text "    Criar ponto de restauração automaticamente antes de operações de risco" -X 32 -Y $y -Width 680; $chkBackup.Checked   = (Get-Config 'AutoBackup');  $scroll.Controls.Add($chkBackup);  $y += 28
    $chkScroll   = New-StyledCheckBox -Text "    Auto-scroll no painel de log (rolar automaticamente para o final)"      -X 32 -Y $y -Width 680; $chkScroll.Checked   = (Get-Config 'AutoScroll'); $scroll.Controls.Add($chkScroll);  $y += 28
    $chkDebug    = New-StyledCheckBox -Text "    Mostrar mensagens de depuração no log (modo verbose)"                   -X 32 -Y $y -Width 680; $chkDebug.Checked    = (Get-Config 'ShowDebug');  $scroll.Controls.Add($chkDebug);  $y += 36

    # ── Seção: Logs ──────────────────────────────────────────────────────────
    $sl2 = New-SectionLabel -Text 'Logs e Armazenamento' -X 32 -Y $y; $scroll.Controls.Add($sl2); $y += 30
    $ln2 = New-Separator -X 32 -Y $y -Width 680; $scroll.Controls.Add($ln2); $y += 14

    $lblRetL = New-Object System.Windows.Forms.Label; $lblRetL.Text = "    Retenção de logs (dias):"
    $lblRetL.Font = $Global:Theme.Font_Body; $lblRetL.ForeColor = $Global:Theme.Text_Primary
    $lblRetL.Location = New-Object System.Drawing.Point(32,$y); $lblRetL.AutoSize = $true; $scroll.Controls.Add($lblRetL)
    $numRet = New-Object System.Windows.Forms.NumericUpDown
    $numRet.Location = New-Object System.Drawing.Point(220,$y); $numRet.Size = New-Object System.Drawing.Size(80,26)
    $numRet.Minimum = 1; $numRet.Maximum = 365; $numRet.Value = (Get-Config 'LogRetentionDays')
    $numRet.BackColor = $Global:Theme.BG_Input; $numRet.ForeColor = $Global:Theme.Text_Primary
    $numRet.Font = $Global:Theme.Font_Body; $scroll.Controls.Add($numRet); $y += 36

    $lblLogDir = New-Object System.Windows.Forms.Label; $lblLogDir.Text = "    Diretório de logs:"
    $lblLogDir.Font = $Global:Theme.Font_Body; $lblLogDir.ForeColor = $Global:Theme.Text_Primary
    $lblLogDir.Location = New-Object System.Drawing.Point(32,$y); $lblLogDir.AutoSize = $true; $scroll.Controls.Add($lblLogDir)
    $txtLogDir = New-Object System.Windows.Forms.TextBox; $txtLogDir.Text = $Global:WC.LogPath
    $txtLogDir.Location = New-Object System.Drawing.Point(170,$y); $txtLogDir.Size = New-Object System.Drawing.Size(410,26)
    $txtLogDir.BackColor = $Global:Theme.BG_Input; $txtLogDir.ForeColor = $Global:Theme.Text_Muted
    $txtLogDir.Font = $Global:Theme.Font_Small; $txtLogDir.BorderStyle = 'FixedSingle'; $txtLogDir.ReadOnly = $true
    $scroll.Controls.Add($txtLogDir)
    $btnOpenLog = New-StyledButton -Text '...' -X 588 -Y $y -Width 40 -Height 26 -Style 'Secondary'
    $btnOpenLog.Add_Click({ if (Test-Path $Global:WC.LogPath) { Start-Process explorer $Global:WC.LogPath } })
    $scroll.Controls.Add($btnOpenLog); $y += 36

    # Limpeza de logs antigos
    $btnCleanLogs = New-StyledButton -Text 'Limpar Logs Antigos' -X 32 -Y $y -Width 200 -Height 34 -Style 'Secondary'
    $btnCleanLogs.Add_Click({
        $days = [int]$numRet.Value; $cutoff = (Get-Date).AddDays(-$days)
        $logFiles = Get-ChildItem $Global:WC.LogPath -Filter '*.log' -EA SilentlyContinue |
                    Where-Object { $_.LastWriteTime -lt $cutoff }
        if ($logFiles.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Nenhum log com mais de $days dias encontrado.", "WinCare Pro", 'OK', 'Information') | Out-Null
            return
        }
        $logFiles | Remove-Item -Force -EA SilentlyContinue
        Write-Log "Limpeza de logs: $($logFiles.Count) arquivo(s) removido(s)" -Level SUCCESS
        [System.Windows.Forms.MessageBox]::Show("$($logFiles.Count) log(s) removido(s).", "WinCare Pro", 'OK', 'Information') | Out-Null
    })
    $scroll.Controls.Add($btnCleanLogs); $y += 46

    # ── Seção: Sobre ─────────────────────────────────────────────────────────
    $sl3 = New-SectionLabel -Text 'Sobre o WinCare Pro' -X 32 -Y $y; $scroll.Controls.Add($sl3); $y += 30
    $ln3 = New-Separator -X 32 -Y $y -Width 680; $scroll.Controls.Add($ln3); $y += 14

    $aboutCard = New-Object System.Windows.Forms.Panel
    $aboutCard.Location = New-Object System.Drawing.Point(32,$y); $aboutCard.Size = New-Object System.Drawing.Size(680,100)
    $aboutCard.BackColor = $Global:Theme.BG_Card; $scroll.Controls.Add($aboutCard)

    $lines = @(
        "WinCare Pro v$($Global:WC.Version)",
        "Suite completa de manutenção, diagnóstico e otimização para Windows 10/11",
        "PowerShell $($PSVersionTable.PSVersion) | .NET $([System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription)",
        "Computador: $env:COMPUTERNAME  |  Usuário: $env:USERNAME  |  OS: $([System.Environment]::OSVersion.VersionString)"
    )
    $yA = 10
    foreach ($line in $lines) {
        $lA = New-Object System.Windows.Forms.Label; $lA.Text = $line
        $lA.Font = if ($lines.IndexOf($line) -eq 0) { $Global:Theme.Font_Header } else { $Global:Theme.Font_Small }
        $lA.ForeColor = if ($lines.IndexOf($line) -eq 0) { $Global:Theme.Accent } else { $Global:Theme.Text_Muted }
        $lA.Location = New-Object System.Drawing.Point(12,$yA); $lA.AutoSize = $true; $aboutCard.Controls.Add($lA)
        $yA += if ($lines.IndexOf($line) -eq 0) { 26 } else { 20 }
    }
    $y += 112

    # Botão salvar
    $btnSave = New-StyledButton -Text 'SALVAR CONFIGURACOES' -X 32 -Y $y -Width 250 -Height 44 -Style 'Primary'
    $btnSave.Font = $Global:Theme.Font_Header
    $btnSave.Add_Click({
        Set-Config 'AutoBackup'       $chkBackup.Checked
        Set-Config 'AutoScroll'       $chkScroll.Checked
        Set-Config 'ShowDebug'        $chkDebug.Checked
        Set-Config 'LogRetentionDays' ([int]$numRet.Value)
        Write-Log "Configurações salvas" -Level SUCCESS
        [System.Windows.Forms.MessageBox]::Show("Configurações salvas com sucesso!", "WinCare Pro", 'OK', 'Information') | Out-Null
    })
    $scroll.Controls.Add($btnSave)
    Update-Status "Módulo: Configurações"
}
