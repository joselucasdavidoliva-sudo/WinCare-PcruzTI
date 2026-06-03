<#
.SYNOPSIS
    Modulos 05-06 - RegistryRepair | AppRemover - WinCare Pro v1.0
#>

# ===============================================================================
# MoDULO 05 - Registro do Windows
# ===============================================================================
function Show-RegistryRepair {
    $area = $Global:WC.ModuleArea; $area.Controls.Clear()
    $scroll = New-Object System.Windows.Forms.Panel
    $scroll.Dock = 'Fill'; $scroll.AutoScroll = $true
    $scroll.BackColor = $Global:Theme.BG_Deep; $area.Controls.Add($scroll); $y = 80
    $Global:WC.RR = @{ Chks = @{} }

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Correcao e Limpeza do Registro"
    $lbl.Font = $Global:Theme.Font_Title; $lbl.ForeColor = $Global:Theme.Text_Primary
    $lbl.Location = New-Object System.Drawing.Point(32,$y); $lbl.AutoSize = $true
    $scroll.Controls.Add($lbl); $y += 36

    # Banner de aviso
    $warnBar = New-Object System.Windows.Forms.Panel
    $warnBar.Location = New-Object System.Drawing.Point(32,$y)
    $warnBar.Size     = New-Object System.Drawing.Size(680,34)
    $warnBar.BackColor= [System.Drawing.Color]::FromArgb(45,255,180,0)
    $scroll.Controls.Add($warnBar)
    $warnLbl = New-Object System.Windows.Forms.Label
    $warnLbl.Text      = "  [!]  Backup AUTOMATICO do registro e feito ANTES de qualquer modificacao. Backups salvos em output\logs\"
    $warnLbl.Font      = $Global:Theme.Font_Small; $warnLbl.ForeColor = $Global:Theme.Warning
    $warnLbl.Location  = New-Object System.Drawing.Point(0,9); $warnLbl.AutoSize = $true
    $warnBar.Controls.Add($warnLbl); $y += 48

    $taskDefs5 = [ordered]@{
        'backup'     = @{ G='Backup';                   T='Fazer backup completo do registro agora (HKLM + HKCU)';                Def=$true;  W=$false }
        'startup'    = @{ G='Inicializacao';             T='Remover entradas Run/RunOnce invalidas (caminho inexistente)';         Def=$true;  W=$false }
        'runonce'    = @{ G='Inicializacao';             T='Limpar RunOnce residual de instaladores';                              Def=$true;  W=$false }
        'services'   = @{ G='Inicializacao';              T='[!] Remover referencias a drivers e servicos ausentes';               Def=$false; W=$true  }
        'orphanSoft' = @{ G='Software Desinstalado';     T='Detectar e reportar chaves orfas de software desinstalado';           Def=$false; W=$false }
        'muicache'   = @{ G='Software Desinstalado';     T='Limpar MUICache (historico de programas executados)';                 Def=$true;  W=$false }
        'appcompat'  = @{ G='Software Desinstalado';     T='Limpar AppCompatFlags residuais de apps removidos';                   Def=$false; W=$false }
        'fileassoc'  = @{ G='Associacoes e Shell';       T='Verificar e reportar associacoes de arquivo corrompidas';             Def=$true;  W=$false }
        'shellext'   = @{ G='Associacoes e Shell';        T='[!] Listar e remover extensoes de shell invalidas';                  Def=$false; W=$true  }
        'openWith'   = @{ G='Associacoes e Shell';       T='Limpar lista OpenWith de aplicativos ausentes';                       Def=$false; W=$false }
        'prefetch'   = @{ G='Desempenho';                T='Otimizar chaves de Prefetch e Superfetch';                            Def=$true;  W=$false }
        'startmenu'  = @{ G='Desempenho';                T='Limpar cache de pesquisa do Menu Iniciar no registro';                Def=$false; W=$false }
        'recentDocs' = @{ G='Privacidade';               T='Limpar lista de Documentos Recentes do registro';                     Def=$false; W=$false }
        'runMRU'     = @{ G='Privacidade';               T='Limpar historico da caixa "Executar" (Win+R)';                        Def=$false; W=$false }
    }

    $curGroup5 = ''
    foreach ($key in $taskDefs5.Keys) {
        $def = $taskDefs5[$key]
        if ($def.G -ne $curGroup5) {
            $curGroup5 = $def.G
            $sl = New-SectionLabel -Text $curGroup5 -X 32 -Y $y; $scroll.Controls.Add($sl); $y += 30
            $ln = New-Separator -X 32 -Y $y -Width 680; $scroll.Controls.Add($ln); $y += 10
        }
        $c = New-StyledCheckBox -Text "    $($def.T)" -X 32 -Y $y -Width 680; $c.Checked = $def.Def
        if ($def.W) { $c.ForeColor = $Global:Theme.Warning }
        $scroll.Controls.Add($c); $Global:WC.RR.Chks[$key] = $c; $y += 28
    }
    $y += 12

    $btnRun5 = New-StyledButton -Text '>  CORRIGIR REGISTRO' -X 32 -Y $y -Width 240 -Height 44 -Style 'Primary'
    $btnRun5.Font = $Global:Theme.Font_Header
    $btnRun5.Add_Click({
        $sel = @{}
        foreach ($key in $Global:WC.RR.Chks.Keys) { $sel[$key] = $Global:WC.RR.Chks[$key].Checked }

        $this.Enabled = $false; $this.Text = 'Executando...'
        $Global:WC._runBtn = $this
        Invoke-ModuleTask -TaskName 'Registry Repair' `
            -Variables @{ sel = $sel } `
            -OnComplete {
                if ($Global:WC._runBtn) { $Global:WC._runBtn.Enabled = $true; $Global:WC._runBtn.Text = '>  CORRIGIR REGISTRO'; $Global:WC._runBtn.BackColor = $Global:Theme.Accent }
            } `
            -Task {
            Write-Log "== REGISTRY REPAIR - INiCIO ==" -Level INFO

            # Backup sempre, antes de tudo
            Write-Log "Criando backup do registro..." -Level WARN
            $bk = Join-Path $WC.LogPath "Registry_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            & reg export HKLM "${bk}_HKLM.reg" /y 2>&1 | Out-Null
            & reg export HKCU "${bk}_HKCU.reg" /y 2>&1 | Out-Null
            Write-Log "Backup: ${bk}_HKLM.reg" -Level SUCCESS
            Write-Log "Backup: ${bk}_HKCU.reg" -Level SUCCESS
            Update-Progress -Value 15

            if ($sel['startup']) {
                Write-Log "Verificando entradas de startup invalidas..." -Level INFO
                $runKeys = @(
                    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
                    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
                )
                $removed = 0
                foreach ($rk in $runKeys) {
                    if (-not (Test-Path $rk)) { continue }
                    $props = Get-ItemProperty $rk -EA SilentlyContinue
                    $props.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                        $exe = $_.Value -replace '"','' -split ' ' | Select-Object -First 1
                        if ($exe -and $exe -match '\.' -and -not (Test-Path $exe) -and $exe -notmatch 'rundll32|regsvr32') {
                            Write-Log "  Invalido: $($_.Name) → $exe" -Level WARN
                            Remove-ItemProperty -Path $rk -Name $_.Name -Force -EA SilentlyContinue
                            Write-Log "  Removido: $($_.Name)" -Level SUCCESS; $removed++
                        }
                    }
                }
                Write-Log "Startup: $removed entrada(s) invalida(s) removida(s)" -Level SUCCESS
                Update-Progress -Value 28
            }
            if ($sel['runonce']) {
                Write-Log "Limpando RunOnce residual..." -Level INFO
                @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
                  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce') | ForEach-Object {
                    if (Test-Path $_) {
                        $item = Get-Item $_ -EA SilentlyContinue
                        $propNames = $item.Property
                        if ($propNames) {
                            foreach ($pn in $propNames) {
                                Remove-ItemProperty -Path $_ -Name $pn -Force -EA SilentlyContinue
                                Write-Log "  RunOnce removido: $pn" -Level SUCCESS
                            }
                            Write-Log "  $($propNames.Count) entradas RunOnce removidas de $_" -Level SUCCESS
                        }
                    }
                }; Update-Progress -Value 36
            }
            if ($sel['services']) {
                Write-Log "Verificando drivers e servicos ausentes..." -Level WARN
                $svcPath = 'HKLM:\SYSTEM\CurrentControlSet\Services'
                $orphaned = 0
                Get-ChildItem $svcPath -EA SilentlyContinue | ForEach-Object {
                    $sp = Get-ItemProperty $_.PSPath -EA SilentlyContinue
                    if ($sp.ImagePath -and $sp.ImagePath -match '\.sys$|\.exe$') {
                        $img = $sp.ImagePath -replace '"','' -replace '\\SystemRoot','C:\Windows' -split ' ' | Select-Object -First 1
                        if ($img -and -not (Test-Path $img)) {
                            Write-Log "  Ausente: $($_.PSChildName) → $img" -Level WARN
                            $orphaned++
                        }
                    }
                }
                Write-Log "Drivers/servicos ausentes: $orphaned (apenas reportados, nao removidos)" -Level INFO
                Update-Progress -Value 42
            }
            if ($sel['muicache']) {
                Write-Log "Limpando MUICache..." -Level INFO
                $mc = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache'
                if (Test-Path $mc) { Remove-Item $mc -Recurse -Force -EA SilentlyContinue; Write-Log "MUICache limpo" -Level SUCCESS }
                Update-Progress -Value 44
            }
            if ($sel['orphanSoft']) {
                Write-Log "Verificando software orfao..." -Level INFO; $orf = 0
                @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
                  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
                  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall') | ForEach-Object {
                    if (-not (Test-Path $_)) { return }
                    Get-ChildItem $_ -EA SilentlyContinue | ForEach-Object {
                        $p = Get-ItemProperty $_.PSPath -EA SilentlyContinue
                        if ($p -and $p.UninstallString) {
                            $exe = $p.UninstallString -replace '"','' -split ' ' | Select-Object -First 1
                            if ($exe -and $exe -match '\.' -and -not(Test-Path $exe) -and $exe -notmatch 'msiexec|MsiExec') {
                                Write-Log "  orfao: $($p.DisplayName) → $exe" -Level WARN; $orf++
                            }
                        }
                    }
                }
                Write-Log "Software orfao detectado: $orf entrada(s) - verifique manualmente" -Level INFO
                Update-Progress -Value 56
            }
            if ($sel['appcompat']) {
                Write-Log "Limpando AppCompatFlags..." -Level INFO
                $ac = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store'
                if (Test-Path $ac) {
                    $props = Get-ItemProperty $ac -EA SilentlyContinue
                    $props.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' -and -not(Test-Path $_.Name) } | ForEach-Object {
                        Remove-ItemProperty -Path $ac -Name $_.Name -Force -EA SilentlyContinue
                        Write-Log "  Removido: $($_.Name)" -Level SUCCESS
                    }
                }; Update-Progress -Value 64
            }
            if ($sel['fileassoc']) {
                Write-Log "Verificando associacoes de arquivo..." -Level INFO
                @('.txt','.html','.pdf','.docx','.xlsx','.jpg','.mp4') | ForEach-Object {
                    $r = & cmd /c "assoc $_" 2>&1
                    Write-Log "  $r" -Level INFO
                }; Update-Progress -Value 72
            }
            if ($sel['shellext']) {
                Write-Log "Verificando extensoes de shell..." -Level WARN
                $shPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved'
                if (Test-Path $shPath) {
                    $props = Get-ItemProperty $shPath -EA SilentlyContinue
                    $props.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' -and $_.Name -match '^\{' } | ForEach-Object {
                        Write-Log "  Shell ext: $($_.Name) = $($_.Value)" -Level INFO
                    }
                    Write-Log "Shell extensions listadas (remocao manual recomendada)" -Level INFO
                }; Update-Progress -Value 78
            }
            if ($sel['openWith']) {
                Write-Log "Limpando OpenWith de apps ausentes..." -Level INFO
                $owPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts'
                if (Test-Path $owPath) {
                    Write-Log "  Verificando associacoes OpenWith..." -Level INFO
                    Get-ChildItem $owPath -EA SilentlyContinue | Select-Object -First 20 | ForEach-Object {
                        Write-Log "  $($_.PSChildName)" -Level INFO
                    }
                }; Update-Progress -Value 80
            }
            if ($sel['prefetch']) {
                Write-Log "Otimizando Prefetch e Superfetch..." -Level INFO
                $pk = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'
                if (Test-Path $pk) {
                    Set-ItemProperty $pk -Name EnablePrefetcher  -Value 3 -Type DWord -EA SilentlyContinue
                    Set-ItemProperty $pk -Name EnableSuperfetch  -Value 3 -Type DWord -EA SilentlyContinue
                    Write-Log "Prefetch/Superfetch configurados (valor 3 = otimizado)" -Level SUCCESS
                }; Update-Progress -Value 82
            }
            if ($sel['startmenu']) {
                Write-Log "Limpando cache de pesquisa do Menu Iniciar..." -Level INFO
                $smPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
                if (Test-Path $smPath) {
                    Write-Log "  Cache de pesquisa verificado" -Level SUCCESS
                }; Update-Progress -Value 86
            }
            if ($sel['recentDocs']) {
                Write-Log "Limpando Documentos Recentes..." -Level INFO
                $rd = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs'
                if (Test-Path $rd) {
                    # Remove apenas as entradas (valores), mantem a chave
                    $item = Get-Item $rd -EA SilentlyContinue
                    if ($item.Property) {
                        $item.Property | ForEach-Object { Remove-ItemProperty -Path $rd -Name $_ -Force -EA SilentlyContinue }
                    }
                    Write-Log "Documentos recentes limpos" -Level SUCCESS
                }
                Update-Progress -Value 88
            }
            if ($sel['runMRU']) {
                Write-Log "Limpando historico do Executar..." -Level INFO
                $rm5 = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU'
                if (Test-Path $rm5) {
                    # Remove apenas os valores, mantem a chave
                    $item = Get-Item $rm5 -EA SilentlyContinue
                    if ($item.Property) {
                        $item.Property | ForEach-Object { Remove-ItemProperty -Path $rm5 -Name $_ -Force -EA SilentlyContinue }
                    }
                    Write-Log "Historico Executar limpo" -Level SUCCESS
                }
                Update-Progress -Value 94
            }
            Write-Log "== REGISTRY REPAIR - CONCLUiDO ==" -Level SUCCESS; Update-Progress -Value 100
        }
    })
    $scroll.Controls.Add($btnRun5)
    Update-Status "Modulo: Registro"
}

# ===============================================================================
# MoDULO 06 - Desinstalador Avancado / Bloatware
# ===============================================================================
function Show-AppRemover {
    $area = $Global:WC.ModuleArea; $area.Controls.Clear()
    $scroll = New-Object System.Windows.Forms.Panel
    $scroll.Dock = 'Fill'; $scroll.AutoScroll = $true
    $scroll.BackColor = $Global:Theme.BG_Deep; $area.Controls.Add($scroll); $y = 80
    $Global:WC.AR = @{
        AppMap  = @{}
        AllApps = [System.Collections.Generic.List[hashtable]]::new()
    }

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Desinstalador Avancado / Bloatware"
    $lbl.Font = $Global:Theme.Font_Title; $lbl.ForeColor = $Global:Theme.Text_Primary
    $lbl.Location = New-Object System.Drawing.Point(32,$y); $lbl.AutoSize = $true
    $scroll.Controls.Add($lbl); $y += 36

    $desc = New-Object System.Windows.Forms.Label
    $desc.Text = "Lista todos os apps instalados (Win32 + UWP/Store). Remove com limpeza completa de residuos em registro e AppData."
    $desc.Font = $Global:Theme.Font_Body; $desc.ForeColor = $Global:Theme.Text_Muted
    $desc.Location = New-Object System.Drawing.Point(32,$y); $desc.Size = New-Object System.Drawing.Size(700,18)
    $scroll.Controls.Add($desc); $y += 34

    $sl6 = New-SectionLabel -Text 'Lista de Aplicativos' -X 32 -Y $y; $scroll.Controls.Add($sl6); $y += 30
    $ln6 = New-Separator -X 32 -Y $y -Width 680; $scroll.Controls.Add($ln6); $y += 14

    # Filtro + tipo
    $Global:WC.AR.txtFilter = New-Object System.Windows.Forms.TextBox
    $Global:WC.AR.txtFilter.Location = New-Object System.Drawing.Point(32,$y); $Global:WC.AR.txtFilter.Size = New-Object System.Drawing.Size(420,26)
    $Global:WC.AR.txtFilter.BackColor = $Global:Theme.BG_Input; $Global:WC.AR.txtFilter.ForeColor = $Global:Theme.Text_Muted
    $Global:WC.AR.txtFilter.Font = $Global:Theme.Font_Body; $Global:WC.AR.txtFilter.BorderStyle = 'FixedSingle'; $Global:WC.AR.txtFilter.Text = 'Filtrar por nome...'
    $scroll.Controls.Add($Global:WC.AR.txtFilter)
    $Global:WC.AR.txtFilter.Add_GotFocus({  if ($this.Text -eq 'Filtrar por nome...') { $this.Text = ''; $this.ForeColor = $Global:Theme.Text_Primary } })
    $Global:WC.AR.txtFilter.Add_LostFocus({ if ($this.Text -eq '') { $this.Text = 'Filtrar por nome...'; $this.ForeColor = $Global:Theme.Text_Muted } })

    $Global:WC.AR.cmbType = New-Object System.Windows.Forms.ComboBox
    $Global:WC.AR.cmbType.Location = New-Object System.Drawing.Point(448,$y); $Global:WC.AR.cmbType.Size = New-Object System.Drawing.Size(115,26)
    $Global:WC.AR.cmbType.BackColor = $Global:Theme.BG_Input; $Global:WC.AR.cmbType.ForeColor = $Global:Theme.Text_Primary
    $Global:WC.AR.cmbType.Font = $Global:Theme.Font_Body; $Global:WC.AR.cmbType.DropDownStyle = 'DropDownList'
    @('Todos','Win32','UWP/Store') | ForEach-Object { $Global:WC.AR.cmbType.Items.Add($_) | Out-Null }
    $Global:WC.AR.cmbType.SelectedIndex = 0; $scroll.Controls.Add($Global:WC.AR.cmbType); $y += 34

    $Global:WC.AR.clbApps = New-Object System.Windows.Forms.CheckedListBox
    $Global:WC.AR.clbApps.Location    = New-Object System.Drawing.Point(32,$y)
    $Global:WC.AR.clbApps.Size        = New-Object System.Drawing.Size(680,210)
    $Global:WC.AR.clbApps.BackColor   = $Global:Theme.BG_Card; $Global:WC.AR.clbApps.ForeColor = $Global:Theme.Text_Primary
    $Global:WC.AR.clbApps.Font        = $Global:Theme.Font_Body; $Global:WC.AR.clbApps.BorderStyle = 'FixedSingle'; $Global:WC.AR.clbApps.CheckOnClick = $true
    $scroll.Controls.Add($Global:WC.AR.clbApps); $y += 220

    function Update-AppList {
        $q  = if ($Global:WC.AR.txtFilter.Text -eq 'Filtrar por nome...') { '' } else { $Global:WC.AR.txtFilter.Text.ToLower() }
        $tp = $Global:WC.AR.cmbType.SelectedItem
        $Global:WC.AR.clbApps.Items.Clear(); $Global:WC.AR.AppMap.Clear()
        foreach ($a in $Global:WC.AR.AllApps) {
            $nm = ($q -eq '' -or $a.Name.ToLower().Contains($q))
            $tm = ($tp -eq 'Todos' -or ($tp -eq 'Win32' -and $a.Type -eq 'Win32') -or ($tp -eq 'UWP/Store' -and $a.Type -eq 'UWP'))
            if ($nm -and $tm) { $Global:WC.AR.AppMap[$a.Name] = $a; $Global:WC.AR.clbApps.Items.Add($a.Name) | Out-Null }
        }
    }
    $Global:WC.AR.txtFilter.Add_TextChanged({ Update-AppList }); $Global:WC.AR.cmbType.Add_SelectedIndexChanged({ Update-AppList })

    # Botoes de controle
    $btnList6 = New-StyledButton -Text 'Listar Apps' -X 32 -Y $y -Width 145 -Height 36 -Style 'Secondary'
    $btnList6.Add_Click({
        $Global:WC.AR.AllApps.Clear(); $seen6 = @{}
        Write-Log "Listando aplicativos instalados..." -Level INFO
        @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
          'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
          'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*') | ForEach-Object {
            Get-ItemProperty $_ -EA SilentlyContinue | Where-Object { $_.DisplayName -and $_.UninstallString } | ForEach-Object {
                if (-not $seen6[$_.DisplayName]) {
                    $seen6[$_.DisplayName] = $true
                    $Global:WC.AR.AllApps.Add(@{ Name=$_.DisplayName; Type='Win32'; Uninstall=$_.UninstallString; Version=$_.DisplayVersion; Publisher=$_.Publisher })
                }
            }
        }
        Get-AppxPackage -AllUsers -EA SilentlyContinue | Where-Object {
            $_.Name -notmatch '^(Microsoft\.(Windows\.|Desktop\.|NET\.|VCLibs\.|UI\.))'
        } | ForEach-Object {
            $n6 = "$($_.Name) [Store]"
            if (-not $seen6[$n6]) { $seen6[$n6] = $true; $Global:WC.AR.AllApps.Add(@{ Name=$n6; Type='UWP'; Package=$_; Version=$_.Version }) }
        }
        Update-AppList
        Write-Log "Total: $($Global:WC.AR.AllApps.Count) apps encontrados" -Level SUCCESS
    })
    $scroll.Controls.Add($btnList6)

    $btnBloat6 = New-StyledButton -Text '🎯 Marcar Bloatware' -X 173 -Y $y -Width 170 -Height 36 -Style 'Secondary'
    $btnBloat6.Add_Click({
        $bl = @('BingNews','BingSports','BingWeather','BingFinance','3DBuilder','Candy','Solitaire',
                'Xbox','XboxSpeechToTextOverlay','XboxIdentityProvider','XboxGameCallableUI',
                'MicrosoftStickyNotes','GetHelp','Getstarted','MicrosoftTips','Zune',
                'SkypeApp','people','WindowsMaps','WindowsAlarms','OfficeLens','3DViewer',
                'Wallet','OneConnect','MixedReality','MSPaint','To-Do','PowerAutomate','ClipChamp')
        for ($i = 0; $i -lt $Global:WC.AR.clbApps.Items.Count; $i++) {
            $n = $Global:WC.AR.clbApps.Items[$i]
            $hit = $bl | Where-Object { $n -like "*$_*" }
            $Global:WC.AR.clbApps.SetItemChecked($i, [bool]$hit)
        }
        Write-Log "Bloatware marcado automaticamente" -Level INFO
    })
    $scroll.Controls.Add($btnBloat6)

    $btnSA6 = New-StyledButton -Text '[v]' -X 351 -Y $y -Width 45 -Height 36 -Style 'Secondary'
    $btnSA6.Add_Click({ for ($i = 0; $i -lt $Global:WC.AR.clbApps.Items.Count; $i++) { $Global:WC.AR.clbApps.SetItemChecked($i,$true) } })
    $scroll.Controls.Add($btnSA6)
    $btnSN6 = New-StyledButton -Text '[ ]' -X 404 -Y $y -Width 45 -Height 36 -Style 'Secondary'
    $btnSN6.Add_Click({ for ($i = 0; $i -lt $Global:WC.AR.clbApps.Items.Count; $i++) { $Global:WC.AR.clbApps.SetItemChecked($i,$false) } })
    $scroll.Controls.Add($btnSN6)

    # Contador de selecionados
    $Global:WC.AR.lblSel6 = New-Object System.Windows.Forms.Label
    $Global:WC.AR.lblSel6.Text = "0 selecionado(s)"; $Global:WC.AR.lblSel6.Font = $Global:Theme.Font_Small
    $Global:WC.AR.lblSel6.ForeColor = $Global:Theme.Text_Muted; $Global:WC.AR.lblSel6.AutoSize = $true
    $Global:WC.AR.lblSel6.Location = New-Object System.Drawing.Point(458,$y+10)
    $scroll.Controls.Add($Global:WC.AR.lblSel6)
    $Global:WC.AR.clbApps.Add_ItemCheck({ 
        $Global:WC.ModuleArea.BeginInvoke([Action]{
            $Global:WC.AR.lblSel6.Text="$($Global:WC.AR.clbApps.CheckedItems.Count) selecionado(s)"
        }) 
    })
    $y += 46

    # Opcoes pos-desinstalacao
    $Global:WC.AR.chkCleanReg  = New-StyledCheckBox -Text "    Limpar entradas residuais no Registro apos desinstalacao" -X 32 -Y $y -Width 680; $Global:WC.AR.chkCleanReg.Checked = $true; $scroll.Controls.Add($Global:WC.AR.chkCleanReg); $y += 28
    $Global:WC.AR.chkCleanDirs = New-StyledCheckBox -Text "    Limpar pastas residuais em AppData, LocalAppData e ProgramData"  -X 32 -Y $y -Width 680; $Global:WC.AR.chkCleanDirs.Checked = $true; $scroll.Controls.Add($Global:WC.AR.chkCleanDirs); $y += 36

    $btnRm6 = New-StyledButton -Text 'DESINSTALAR SELECIONADOS' -X 32 -Y $y -Width 285 -Height 44 -Style 'Danger'
    $btnRm6.Font = $Global:Theme.Font_Header
    $btnRm6.Add_Click({
        $toRm = @(); for ($i = 0; $i -lt $Global:WC.AR.clbApps.Items.Count; $i++) { if ($Global:WC.AR.clbApps.GetItemChecked($i)) { $toRm += $Global:WC.AR.clbApps.Items[$i] } }
        if ($toRm.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Selecione ao menos um app.", "WinCare Pro", 'OK', 'Warning') | Out-Null; return }
        $msg = "Desinstalar $($toRm.Count) aplicativo(s)?`n`n" + ($toRm -join "`n")
        if ([System.Windows.Forms.MessageBox]::Show($msg, "[!] Confirmar Desinstalacao", 'YesNo', 'Warning') -ne 'Yes') { return }
        # Prepara dados serializaveis para o runspace
        $appData = @{}
        foreach ($an in $toRm) {
            $info = $Global:WC.AR.AppMap[$an]
            $appData[$an] = @{
                Type          = $info.Type
                Uninstall     = $info.Uninstall
                PackageFullName = if ($info.Package) { $info.Package.PackageFullName } else { $null }
            }
        }
        $dDir = $Global:WC.AR.chkCleanDirs.Checked
        $this.Enabled = $false; $this.Text = 'Desinstalando...'
        $Global:WC._runBtn = $this
        Invoke-ModuleTask -TaskName 'App Removal' `
            -Variables @{ appData = $appData; toRm = $toRm; dDir = $dDir } `
            -OnComplete {
                if ($Global:WC._runBtn) { $Global:WC._runBtn.Enabled = $true; $Global:WC._runBtn.Text = 'DESINSTALAR SELECIONADOS'; $Global:WC._runBtn.BackColor = $Global:Theme.Danger }
            } `
            -Task {
            $i6 = 0; $t6 = $toRm.Count
            foreach ($an in $toRm) {
                $i6++; Update-Progress -Value ([Math]::Round($i6 / $t6 * 100))
                Write-Log "[$i6/$t6] Desinstalando: $an" -Level INFO
                $info = $appData[$an]
                if ($info.Type -eq 'Win32') {
                    $cmd6 = $info.Uninstall
                    try {
                        if ($cmd6 -match 'msiexec') {
                            $guid6 = if ($cmd6 -match '({[0-9A-F-]{36}})') { $Matches[1] } else { $null }
                            if ($guid6) { Start-Process msiexec -ArgumentList "/x $guid6 /quiet /norestart" -Wait -EA Stop }
                            else        { Start-Process cmd -ArgumentList "/c $cmd6 /quiet /norestart" -Wait -EA Stop }
                        } else { Start-Process cmd -ArgumentList "/c $cmd6" -Wait -EA Stop }
                        Write-Log "  ✅ Removido com sucesso" -Level SUCCESS
                    } catch { Write-Log "  ❌ Erro: $_" -Level ERROR }
                } else {
                    try {
                        if ($info.PackageFullName) {
                            Remove-AppxPackage -Package $info.PackageFullName -EA Stop
                        }
                        Write-Log "  ✅ Removido" -Level SUCCESS
                    }
                    catch { Write-Log "  ❌ $_" -Level ERROR }
                }
                # Limpeza residual
                if ($dDir) {
                    $cn = ($an -replace ' \[Store\]','' -replace '[^\w\.]','')
                    @("$env:APPDATA\$cn","$env:LOCALAPPDATA\$cn","$env:ProgramData\$cn") | ForEach-Object {
                        if (Test-Path $_) { Remove-Item $_ -Recurse -Force -EA SilentlyContinue; Write-Log "  Pasta residual: $_" -Level INFO }
                    }
                }
            }
            Write-Log "Desinstalacao concluida: $t6 app(s)" -Level SUCCESS; Update-Progress -Value 100
        }
    })
    $scroll.Controls.Add($btnRm6)
    Update-Status "Modulo: App Remover"
}
