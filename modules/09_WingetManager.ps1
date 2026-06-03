<#
.SYNOPSIS
    Modulo 09 - Winget Manager - WinCare Pro v1.0
#>

function Show-WingetManager {
    $area = $Global:WC.ModuleArea; $area.Controls.Clear()
    $scroll = New-Object System.Windows.Forms.Panel
    $scroll.Dock = 'Fill'; $scroll.AutoScroll = $true
    $scroll.BackColor = $Global:Theme.BG_Deep; $area.Controls.Add($scroll)
    $Global:WC.WMG = @{
        RlvApps = $null
        LblSel  = $null
        EChks   = @{}
    }
    $y = 80

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Winget - Gerenciador de Aplicativos"
    $lbl.Font = $Global:Theme.Font_Title; $lbl.ForeColor = $Global:Theme.Text_Primary
    $lbl.Location = New-Object System.Drawing.Point(32,$y); $lbl.AutoSize = $true
    $scroll.Controls.Add($lbl); $y += 36

    # Aviso se winget nao disponivel
    $wgOk = Get-Command winget -EA SilentlyContinue
    if (-not $wgOk) {
        $wBar = New-Object System.Windows.Forms.Panel; $wBar.Location = New-Object System.Drawing.Point(32,$y)
        $wBar.Size = New-Object System.Drawing.Size(680,36); $wBar.BackColor = [System.Drawing.Color]::FromArgb(45,255,60,80); $scroll.Controls.Add($wBar)
        $wLbl = New-Object System.Windows.Forms.Label
        $wLbl.Text = "  [!]  winget nao detectado. Instale o App Installer pela Microsoft Store ou atualize o Windows."
        $wLbl.Font = $Global:Theme.Font_Small; $wLbl.ForeColor = $Global:Theme.Danger
        $wLbl.Location = New-Object System.Drawing.Point(0,10); $wLbl.AutoSize = $true; $wBar.Controls.Add($wLbl); $y += 50
    }

    # ==========================================================================
    # SECAO 1 - Buscar e Instalar
    # ==========================================================================
    $sl9a = New-SectionLabel -Text 'Buscar e Instalar Aplicativo' -X 32 -Y $y; $scroll.Controls.Add($sl9a); $y += 30
    $ln9a = New-Separator -X 32 -Y $y -Width 680; $scroll.Controls.Add($ln9a); $y += 14

    $Global:WC.WMG.txtS9 = New-Object System.Windows.Forms.TextBox
    $Global:WC.WMG.txtS9.Location = New-Object System.Drawing.Point(32,$y); $Global:WC.WMG.txtS9.Size = New-Object System.Drawing.Size(462,28)
    $Global:WC.WMG.txtS9.BackColor = $Global:Theme.BG_Input; $Global:WC.WMG.txtS9.ForeColor = $Global:Theme.Text_Primary
    $Global:WC.WMG.txtS9.Font = $Global:Theme.Font_Body; $Global:WC.WMG.txtS9.BorderStyle = 'FixedSingle'
    $scroll.Controls.Add($Global:WC.WMG.txtS9)

    $Global:WC.WMG.RlvApps = New-Object System.Windows.Forms.ListView
    $Global:WC.WMG.RlvApps.Location = New-Object System.Drawing.Point(32,$y); $Global:WC.WMG.RlvApps.Size = New-Object System.Drawing.Size(680,160)
    $Global:WC.WMG.RlvApps.BackColor = $Global:Theme.BG_Card; $Global:WC.WMG.RlvApps.ForeColor = $Global:Theme.Text_Primary
    $Global:WC.WMG.RlvApps.Font = $Global:Theme.Font_Small; $Global:WC.WMG.RlvApps.BorderStyle = 'FixedSingle'
    $Global:WC.WMG.RlvApps.View = 'Details'; $Global:WC.WMG.RlvApps.FullRowSelect = $true; $Global:WC.WMG.RlvApps.HeaderStyle = 'Nonclickable'
    @(@{T='Nome';W=220},@{T='ID do Pacote';W=230},@{T='Versao';W=90},@{T='Fonte';W=110}) | ForEach-Object {
        $col9 = New-Object System.Windows.Forms.ColumnHeader; $col9.Text = $_.T; $col9.Width = $_.W
        $Global:WC.WMG.RlvApps.Columns.Add($col9) | Out-Null
    }
    $scroll.Controls.Add($Global:WC.WMG.RlvApps); $y += 168

    $btnI9  = New-StyledButton -Text 'Instalar'           -X 32  -Y $y -Width 140 -Height 36 -Style 'Primary'
    $btnIS9 = New-StyledButton -Text 'Instalar Silencioso' -X 168 -Y $y -Width 190 -Height 36 -Style 'Secondary'
    $Global:WC.WMG.LblSel = New-Object System.Windows.Forms.Label
    $Global:WC.WMG.LblSel.Text = "Clique em uma linha para selecionar"
    $Global:WC.WMG.LblSel.Font = $Global:Theme.Font_Small; $Global:WC.WMG.LblSel.ForeColor = $Global:Theme.Text_Muted
    $Global:WC.WMG.LblSel.Location = New-Object System.Drawing.Point(366,$y+10); $Global:WC.WMG.LblSel.AutoSize = $true
    $scroll.Controls.Add($btnI9); $scroll.Controls.Add($btnIS9); $scroll.Controls.Add($Global:WC.WMG.LblSel); $y += 46

    $Global:WC.WMG.RlvApps.Add_SelectedIndexChanged({
        $sel9t = $this.SelectedItems | Select-Object -First 1
        if ($sel9t) { $Global:WC.WMG.LblSel.Text = "✅ $($sel9t.Text)"; $Global:WC.WMG.LblSel.ForeColor = $Global:Theme.Success }
        else        { $Global:WC.WMG.LblSel.Text = "Clique em uma linha"; $Global:WC.WMG.LblSel.ForeColor = $Global:Theme.Text_Muted }
    })

    $btnSrc9.Add_Click({
        $q9 = $Global:WC.WMG.txtS9.Text.Trim()
        if ($q9.Length -lt 2) { [System.Windows.Forms.MessageBox]::Show("Digite ao menos 2 caracteres.", "WinCare Pro", 'OK', 'Warning') | Out-Null; return }
        if (-not (Get-Command winget -EA SilentlyContinue)) {
            [System.Windows.Forms.MessageBox]::Show("winget nao encontrado. Instale o App Installer.", "WinCare Pro", 'OK', 'Warning') | Out-Null; return
        }
        $Global:WC.WMG.RlvApps.Items.Clear()
        Write-Log "Buscando no winget: $q9" -Level INFO
        $raw9 = & winget search $q9 --accept-source-agreements 2>&1
        $raw9 | Where-Object { $_ -match '\S' } | Select-Object -Skip 2 | ForEach-Object {
            $p9 = $_ -split '\s{2,}'
            if ($p9.Count -ge 2) {
                $it9 = New-Object System.Windows.Forms.ListViewItem($p9[0])
                $it9.SubItems.Add($(if($p9.Count -gt 1){$p9[1]}else{''})) | Out-Null
                $it9.SubItems.Add($(if($p9.Count -gt 2){$p9[2]}else{''})) | Out-Null
                $it9.SubItems.Add($(if($p9.Count -gt 3){$p9[3]}else{''})) | Out-Null
                $Global:WC.WMG.RlvApps.Items.Add($it9) | Out-Null
            }
        }
        Write-Log "$($Global:WC.WMG.RlvApps.Items.Count) resultado(s) encontrado(s)" -Level SUCCESS
    })

    # Enter na caixa de busca = buscar
    $Global:WC.WMG.txtS9.Add_KeyDown({ if ($_.KeyCode -eq 'Return') { $btnSrc9.PerformClick() } })

    $btnI9.Add_Click({
        $sel9 = $Global:WC.WMG.RlvApps.SelectedItems | Select-Object -First 1
        if (-not $sel9) { [System.Windows.Forms.MessageBox]::Show("Selecione um app.", "WinCare Pro", 'OK', 'Warning') | Out-Null; return }
        $pkgId = $sel9.SubItems[1].Text
        Invoke-ModuleTask -TaskName "Instalar $pkgId" -Variables @{ pkgId = $pkgId } -Task {
            Write-Log "Instalando: $pkgId" -Level INFO
            & winget install $pkgId --accept-source-agreements --accept-package-agreements 2>&1 | ForEach-Object { Write-Log "  $_" }
            Write-Log "✅ Instalacao concluida: $pkgId" -Level SUCCESS; Update-Progress -Value 100
        }
    })
    $btnIS9.Add_Click({
        $sel9b = $Global:WC.WMG.RlvApps.SelectedItems | Select-Object -First 1
        if (-not $sel9b) { [System.Windows.Forms.MessageBox]::Show("Selecione um app.", "WinCare Pro", 'OK', 'Warning') | Out-Null; return }
        $pkgId = $sel9b.SubItems[1].Text
        Invoke-ModuleTask -TaskName "Instalar (silencioso) $pkgId" -Variables @{ pkgId = $pkgId } -Task {
            Write-Log "Instalando silenciosamente: $pkgId" -Level INFO
            & winget install $pkgId --accept-source-agreements --accept-package-agreements --silent 2>&1 | ForEach-Object { Write-Log "  $_" }
            Write-Log "✅ Instalacao concluida: $pkgId" -Level SUCCESS; Update-Progress -Value 100
        }
    })

    # ==========================================================================
    # SECAO 2 - Atualizacao Global
    # ==========================================================================
    $sl9b = New-SectionLabel -Text 'Atualizacao em Massa' -X 32 -Y $y; $scroll.Controls.Add($sl9b); $y += 30
    $ln9b = New-Separator -X 32 -Y $y -Width 680; $scroll.Controls.Add($ln9b); $y += 14

    $btnLU9  = New-StyledButton -Text 'Listar Desatualizados' -X 32  -Y $y -Width 205 -Height 36 -Style 'Secondary'
    $btnUA9  = New-StyledButton -Text 'Atualizar TODOS'       -X 233 -Y $y -Width 175 -Height 36 -Style 'Primary'
    $Global:WC.WMG.chkUAEx = New-StyledCheckBox -Text "  Excluir pacotes fixos (pinned)" -X 416 -Y $y -Width 240; $Global:WC.WMG.chkUAEx.Checked = $true
    $scroll.Controls.Add($btnLU9); $scroll.Controls.Add($btnUA9); $scroll.Controls.Add($Global:WC.WMG.chkUAEx); $y += 46

    $btnLU9.Add_Click({
        Invoke-ModuleTask -TaskName 'Listar Updates Winget' -Task {
            Write-Log "Verificando atualizacoes disponiveis via winget..." -Level INFO
            & winget upgrade --accept-source-agreements 2>&1 | ForEach-Object { Write-Log "  $_" }
            Update-Progress -Value 100
        }
    })
    $btnUA9.Add_Click({
        $doPin = $Global:WC.WMG.chkUAEx.Checked
        Invoke-ModuleTask -TaskName 'Winget Upgrade All' -Variables @{ doPin = $doPin } -Task {
            Write-Log "Atualizando todos os apps via winget..." -Level INFO; Update-Progress -Value 5
            $wgParams = @('upgrade','--all','--accept-source-agreements','--accept-package-agreements')
            if ($doPin) { $wgParams += '--include-unknown' }
            & winget @wgParams 2>&1 | Where-Object { $_ -match '\S' } | ForEach-Object { Write-Log "  $_" }
            Write-Log "✅ Upgrade de todos os apps concluido" -Level SUCCESS; Update-Progress -Value 100
        }
    })

    # ==========================================================================
    # SECAO 3 - Apps Essenciais em Lote
    # ==========================================================================
    $sl9c = New-SectionLabel -Text 'Apps Essenciais (Instalacao em Lote)' -X 32 -Y $y; $scroll.Controls.Add($sl9c); $y += 30
    $ln9c = New-Separator -X 32 -Y $y -Width 680; $scroll.Controls.Add($ln9c); $y += 14

    $eGrps9 = @(
        @{ T='Navegadores';      A=@(@{Id='Google.Chrome';N='Chrome'},@{Id='Mozilla.Firefox';N='Firefox'},@{Id='Brave.Brave';N='Brave'},@{Id='Waterfox.Waterfox';N='Waterfox'}) },
        @{ T='Utilitarios';      A=@(@{Id='7zip.7zip';N='7-Zip'},@{Id='Notepad++.Notepad++';N='Notepad++'},@{Id='VideoLAN.VLC';N='VLC'},@{Id='BleachBit.BleachBit';N='BleachBit'}) },
        @{ T='Desenvolvimento';  A=@(@{Id='Git.Git';N='Git'},@{Id='Microsoft.PowerShell';N='PS 7'},@{Id='Microsoft.VisualStudioCode';N='VS Code'},@{Id='Python.Python.3';N='Python 3'}) },
        @{ T='Comunicacao';      A=@(@{Id='Zoom.Zoom';N='Zoom'},@{Id='Discord.Discord';N='Discord'},@{Id='SlackTechnologies.Slack';N='Slack'},@{Id='Telegram.TelegramDesktop';N='Telegram'}) },
        @{ T='Admin e Seguranca';A=@(@{Id='WinSCP.WinSCP';N='WinSCP'},@{Id='PuTTY.PuTTY';N='PuTTY'},@{Id='Malwarebytes.Malwarebytes';N='Malwarebytes'},@{Id='Bitwarden.Bitwarden';N='Bitwarden'}) },
        @{ T='Multimidia';       A=@(@{Id='Spotify.Spotify';N='Spotify'},@{Id='HandBrake.HandBrake';N='HandBrake'},@{Id='OBSProject.OBSStudio';N='OBS Studio'},@{Id='GIMP.GIMP';N='GIMP'}) }
    )

    $eChks9 = @{}
    foreach ($eg in $eGrps9) {
        $egLbl = New-Object System.Windows.Forms.Label; $egLbl.Text = $eg.T
        $egLbl.Font = $Global:Theme.Font_Small; $egLbl.ForeColor = $Global:Theme.Accent
        $egLbl.Location = New-Object System.Drawing.Point(32,$y); $egLbl.AutoSize = $true; $scroll.Controls.Add($egLbl); $y += 22
        $xA9 = 20
        foreach ($app9 in $eg.A) {
            $c9 = New-StyledCheckBox -Text $app9.N -X $xA9 -Y $y -Width 158; $c9.Checked = $false
            $scroll.Controls.Add($c9); $Global:WC.WMG.EChks[$app9.Id] = $c9; $xA9 += 165
        }; $y += 34
    }
    $y += 8

    $btnSelAll9  = New-StyledButton -Text '[v] Todos'  -X 32  -Y $y -Width 95 -Height 32 -Style 'Secondary'
    $btnSelNone9 = New-StyledButton -Text '[ ] Nenhum' -X 123 -Y $y -Width 95 -Height 32 -Style 'Secondary'
    $btnSelAll9.Add_Click({  foreach ($c in $Global:WC.WMG.EChks.Values) { $c.Checked = $true  } })
    $btnSelNone9.Add_Click({ foreach ($c in $Global:WC.WMG.EChks.Values) { $c.Checked = $false } })
    $scroll.Controls.Add($btnSelAll9); $scroll.Controls.Add($btnSelNone9); $y += 44

    $btnBat9 = New-StyledButton -Text 'INSTALAR SELECIONADOS' -X 32 -Y $y -Width 250 -Height 44 -Style 'Primary'
    $btnBat9.Font = $Global:Theme.Font_Header
    $btnBat9.Add_Click({
        $toIns9 = @()
        foreach ($k9 in $Global:WC.WMG.EChks.Keys) { 
            if ($Global:WC.WMG.EChks[$k9].Checked) { $toIns9 += $k9 }
        }
        if ($toIns9.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Selecione ao menos um app.", "WinCare Pro", 'OK', 'Warning') | Out-Null; return }
        $this.Enabled = $false; $this.Text = 'Instalando...'
        $Global:WC._runBtn = $this
        Invoke-ModuleTask -TaskName 'Batch Install' `
            -Variables @{ list9 = $toIns9 } `
            -OnComplete {
                if ($Global:WC._runBtn) { $Global:WC._runBtn.Enabled = $true; $Global:WC._runBtn.Text = 'INSTALAR SELECIONADOS'; $Global:WC._runBtn.BackColor = $Global:Theme.Accent }
            } `
            -Task {
            Write-Log "== INSTALACAO EM LOTE - $($list9.Count) app(s) ==" -Level INFO
            $i9 = 0; $tot9 = $list9.Count
            foreach ($id9c in $list9) {
                $i9++; Update-Progress -Value ([Math]::Round($i9/$tot9*100))
                Write-Log "[$i9/$tot9] Instalando: $id9c" -Level INFO
                & winget install $id9c --accept-source-agreements --accept-package-agreements --silent 2>&1 |
                    Where-Object { $_ -match '\S' } | ForEach-Object { Write-Log "  $_" }
                Write-Log "  ✅ $id9c concluido" -Level SUCCESS
            }
            Write-Log "== INSTALACAO EM LOTE - CONCLUIDA ==" -Level SUCCESS; Update-Progress -Value 100
        }
    })
    $scroll.Controls.Add($btnBat9)

    # ==========================================================================
    # SECAO 4 - Export / Import Lista
    # ==========================================================================
    $y += 54
    $sl9d = New-SectionLabel -Text 'Export / Import Lista de Apps' -X 32 -Y $y; $scroll.Controls.Add($sl9d); $y += 30
    $ln9d = New-Separator -X 32 -Y $y -Width 680; $scroll.Controls.Add($ln9d); $y += 14

    $btnEx9 = New-StyledButton -Text 'Exportar Lista JSON' -X 32  -Y $y -Width 190 -Height 36 -Style 'Secondary'
    $btnIm9 = New-StyledButton -Text '📂 Importar e Instalar' -X 218 -Y $y -Width 190 -Height 36 -Style 'Secondary'
    $scroll.Controls.Add($btnEx9); $scroll.Controls.Add($btnIm9)

    $btnEx9.Add_Click({
        $sfd = New-Object System.Windows.Forms.SaveFileDialog
        $sfd.Filter = 'JSON (*.json)|*.json'; $sfd.FileName = "winget_apps_$(Get-Date -Format 'yyyyMMdd').json"
        if ($sfd.ShowDialog() -eq 'OK') {
            $exportPath = $sfd.FileName
            Invoke-ModuleTask -TaskName 'Winget Export' -Variables @{ exportPath = $exportPath } -Task {
                Write-Log "Exportando lista de apps para: $exportPath" -Level INFO
                & winget export -o $exportPath --accept-source-agreements 2>&1 | ForEach-Object { Write-Log "  $_" }
                Write-Log "✅ Lista exportada: $exportPath" -Level SUCCESS; Update-Progress -Value 100
            }
        }
    })
    $btnIm9.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog; $ofd.Filter = 'JSON (*.json)|*.json'
        if ($ofd.ShowDialog() -eq 'OK') {
            $importPath = $ofd.FileName
            Invoke-ModuleTask -TaskName 'Winget Import' -Variables @{ importPath = $importPath } -Task {
                Write-Log "Importando e instalando apps de: $importPath" -Level INFO
                & winget import -i $importPath --accept-source-agreements --accept-package-agreements 2>&1 | ForEach-Object { Write-Log "  $_" }
                Write-Log "✅ Importacao concluida" -Level SUCCESS; Update-Progress -Value 100
            }
        }
    })

    Update-Status "Modulo: Winget Manager"
}
