<#
.SYNOPSIS
    Modulo 02 - Windows Update Recursivo - WinCare Pro v1.0
#>
function Show-WindowsUpdate {
    $area = $Global:WC.ModuleArea; $area.Controls.Clear()
    $scroll = New-Object System.Windows.Forms.Panel
    $scroll.Dock='Fill'; $scroll.AutoScroll=$true; $scroll.BackColor=$Global:Theme.BG_Deep
    $area.Controls.Add($scroll)
    $Global:WC.WU = @{}
    $y = 80

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text="Windows Update - Atualizacao Recursiva"; $lbl.Font=$Global:Theme.Font_Title
    $lbl.ForeColor=$Global:Theme.Text_Primary; $lbl.Location=New-Object System.Drawing.Point(32,$y); $lbl.AutoSize=$true
    $scroll.Controls.Add($lbl); $y+=36

    $desc = New-Object System.Windows.Forms.Label
    $desc.Text="Instala TODAS as atualizacoes em multiplas rodadas ate o sistema estar completamente atualizado."
    $desc.Font=$Global:Theme.Font_Body; $desc.ForeColor=$Global:Theme.Text_Muted
    $desc.Location=New-Object System.Drawing.Point(32,$y); $desc.Size=New-Object System.Drawing.Size(700,18)
    $scroll.Controls.Add($desc); $y+=34

    # Card status
    $statusCard = New-Object System.Windows.Forms.Panel
    $statusCard.Location=New-Object System.Drawing.Point(32,$y); $statusCard.Size=New-Object System.Drawing.Size(680,54)
    $statusCard.BackColor=$Global:Theme.BG_Card; $scroll.Controls.Add($statusCard)
    $lblST = New-Object System.Windows.Forms.Label; $lblST.Text="STATUS"; $lblST.Font=$Global:Theme.Font_Badge
    $lblST.ForeColor=$Global:Theme.Text_Muted; $lblST.Location=New-Object System.Drawing.Point(12,8); $lblST.AutoSize=$true
    $statusCard.Controls.Add($lblST)
    $Global:WC.WU.lblSV = New-Object System.Windows.Forms.Label
    $Global:WC.WU.lblSV.Text="Clique em 'Verificar' para checar atualizacoes pendentes"
    $Global:WC.WU.lblSV.Font=$Global:Theme.Font_Body; $Global:WC.WU.lblSV.ForeColor=$Global:Theme.Info
    $Global:WC.WU.lblSV.Location=New-Object System.Drawing.Point(12,26); $Global:WC.WU.lblSV.AutoSize=$true
    $statusCard.Controls.Add($Global:WC.WU.lblSV); $y+=66

    # Opcoes
    $sep1=New-SectionLabel -Text "Opcoes de Atualizacao" -X 32 -Y $y; $scroll.Controls.Add($sep1); $y+=30
    $l1=New-Separator -X 32 -Y $y -Width 680; $scroll.Controls.Add($l1); $y+=14

    $Global:WC.WU.chkAll     =New-StyledCheckBox -Text "    Instalar todas as atualizacoes (Criticas, Importantes, Opcionais)" -X 32 -Y $y -Width 680; $Global:WC.WU.chkAll.Checked=$true;  $scroll.Controls.Add($Global:WC.WU.chkAll);  $y+=28
    $Global:WC.WU.chkDrivers =New-StyledCheckBox -Text "    Incluir atualizacoes de drivers via Windows Update"                -X 32 -Y $y -Width 680; $Global:WC.WU.chkDrivers.Checked=$false; $scroll.Controls.Add($Global:WC.WU.chkDrivers); $y+=28
    $Global:WC.WU.chkStore   =New-StyledCheckBox -Text "    Atualizar apps da Microsoft Store (via winget)"                    -X 32 -Y $y -Width 680; $Global:WC.WU.chkStore.Checked=$true;  $scroll.Controls.Add($Global:WC.WU.chkStore);  $y+=28
    $Global:WC.WU.chkDef     =New-StyledCheckBox -Text "    Forcar atualizacao das assinaturas do Windows Defender"            -X 32 -Y $y -Width 680; $Global:WC.WU.chkDef.Checked=$true;  $scroll.Controls.Add($Global:WC.WU.chkDef);  $y+=28
    $Global:WC.WU.chkLoop    =New-StyledCheckBox -Text "    Modo Recursivo - repete ate zero pendencias (max. 5 rodadas)"      -X 32 -Y $y -Width 680; $Global:WC.WU.chkLoop.Checked=$true;  $scroll.Controls.Add($Global:WC.WU.chkLoop);  $y+=28
    $Global:WC.WU.chkReb     =New-StyledCheckBox -Text "[!]  Reiniciar automaticamente ao concluir (se necessario)"            -X 32 -Y $y -Width 680
    $Global:WC.WU.chkReb.Checked=$false; $Global:WC.WU.chkReb.ForeColor=$Global:Theme.Warning; $scroll.Controls.Add($Global:WC.WU.chkReb); $y+=36

    # Historico
    $sep2=New-SectionLabel -Text "Historico Recente (ultimas 15 atualizacoes)" -X 32 -Y $y; $scroll.Controls.Add($sep2); $y+=30
    $l2=New-Separator -X 32 -Y $y -Width 680; $scroll.Controls.Add($l2); $y+=14

    $Global:WC.WU.histBox=New-Object System.Windows.Forms.RichTextBox
    $Global:WC.WU.histBox.Location=New-Object System.Drawing.Point(32,$y); $Global:WC.WU.histBox.Size=New-Object System.Drawing.Size(680,110)
    $Global:WC.WU.histBox.ReadOnly=$true; $Global:WC.WU.histBox.BackColor=$Global:Theme.BG_Card; $Global:WC.WU.histBox.ForeColor=$Global:Theme.Text_Primary
    $Global:WC.WU.histBox.Font=$Global:Theme.Font_Small; $Global:WC.WU.histBox.BorderStyle='None'; $Global:WC.WU.histBox.Text="Carregando historico..."
    $scroll.Controls.Add($Global:WC.WU.histBox); $y+=120

    $ht=New-Object System.Windows.Forms.Timer; $ht.Interval=400
    $ht.Add_Tick({
        $ht.Stop()
        try {
            $sess = New-Object -ComObject Microsoft.Update.Session
            $sr=$sess.CreateUpdateSearcher(); $n=$sr.GetTotalHistoryCount()
            $h=$sr.QueryHistory(0,[Math]::Min($n,15)); $lines=@()
            foreach($item in $h){
                $d=$item.Date.ToString('dd/MM/yy'); $t=if($item.Title.Length-gt65){$item.Title.Substring(0,65)+'...'}else{$item.Title}
                $ic=if($item.ResultCode-eq2){'✅'}else{'❌'}; $lines+="$ic  $d  $t"
            }
            $Global:WC.WU.histBox.Text=if($lines){$lines-join"`r`n"}else{"Nenhum historico encontrado."}
        } catch { $Global:WC.WU.histBox.Text="Historico indisponivel: $_" }
    }.GetNewClosure()); $ht.Start()

    # Botoes
    $btnV=New-StyledButton -Text 'Verificar Pendentes' -X 32 -Y $y -Width 195 -Height 40 -Style 'Secondary'
    $btnV.Add_Click({
        $Global:WC.WU.lblSV.Text="Verificando..."; $Global:WC.WU.lblSV.ForeColor=$Global:Theme.Info
        $svRef = $Global:WC.WU.lblSV
        Invoke-ModuleTask -TaskName 'Verificar Updates' `
            -Variables @{ svRef = $svRef; themeRef = $Global:Theme } `
            -Task {
                try {
                    $s=New-Object -ComObject Microsoft.Update.Session
                    $r=$s.CreateUpdateSearcher().Search("IsInstalled=0 and Type='Software'")
                    $c=$r.Updates.Count
                    Write-Log "Pendentes: $c" -Level $(if($c-eq0){'SUCCESS'}else{'WARN'})
                    if($c-gt0){foreach($u in $r.Updates){Write-Log "  • $($u.Title)" -Level INFO}}
                    if ($svRef -and $svRef.IsHandleCreated) {
                        $svRef.Invoke([Action]{
                            $svRef.Text=if($c-eq0){"✅ Sistema 100% atualizado"}else{"[!] $c atualizacao(oes) pendente(s)"}
                            $svRef.ForeColor=if($c-eq0){$themeRef.Success}else{$themeRef.Warning}
                        })
                    }
                } catch { Write-Log "Erro: $_" -Level ERROR }
                Update-Progress -Value 100
            }
    })
    $scroll.Controls.Add($btnV)

    $btnR=New-StyledButton -Text '>  INSTALAR ATUALIZACOES' -X 223 -Y $y -Width 255 -Height 40 -Style 'Primary'
    $btnR.Font=$Global:Theme.Font_Header
    $btnR.Add_Click({
        # Captura flags como valores simples antes de entrar no runspace
        $opts = @{
            DoLoop    = $Global:WC.WU.chkLoop.Checked
            DoReboot  = $Global:WC.WU.chkReb.Checked
            DoDrivers = $Global:WC.WU.chkDrivers.Checked
            DoStore   = $Global:WC.WU.chkStore.Checked
            DoDef     = $Global:WC.WU.chkDef.Checked
        }
        $this.Enabled=$false; $this.Text='Executando...'
        $Global:WC._runBtn = $this
        Invoke-ModuleTask -TaskName 'Windows Update Completo' `
            -Variables @{ opts = $opts } `
            -OnComplete {
                if ($Global:WC._runBtn) { $Global:WC._runBtn.Enabled=$true; $Global:WC._runBtn.Text='>  INSTALAR ATUALIZACOES'; $Global:WC._runBtn.BackColor=$Global:Theme.Accent }
            } `
            -Task {
            Write-Log "== WINDOWS UPDATE - INiCIO ==" -Level INFO; Update-Progress -Value 2

            # Instala PSWindowsUpdate
            if(-not(Get-Module -ListAvailable -Name PSWindowsUpdate -EA SilentlyContinue)){
                Write-Log "Instalando PSWindowsUpdate..." -Level WARN
                try{
                    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
                    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -EA Stop|Out-Null
                    Install-Module PSWindowsUpdate -Force -Scope CurrentUser -EA Stop
                    Write-Log "PSWindowsUpdate instalado" -Level SUCCESS
                } catch { Write-Log "PSWindowsUpdate indisponivel, usando API COM: $_" -Level WARN }
            }

            # Defender
            if($opts.DoDef){
                Write-Log "Atualizando Defender..." -Level INFO
                try{Update-MpSignature -EA Stop; Write-Log "Defender atualizado" -Level SUCCESS}
                catch{Write-Log "Aviso Defender: $_" -Level WARN}
                Update-Progress -Value 8
            }

            # Store
            if($opts.DoStore -and (Get-Command winget -EA SilentlyContinue)){
                Write-Log "Atualizando Microsoft Store apps..." -Level INFO
                & winget upgrade --source msstore --all --accept-source-agreements --accept-package-agreements --silent 2>&1 |
                    Where-Object{$_ -match '\S'}|ForEach-Object{Write-Log "  $_"}
                Write-Log "Store atualizada" -Level SUCCESS; Update-Progress -Value 12
            }

            # Loop principal
            $rodada=0; $total=0; $max=if($opts.DoLoop){5}else{1}
            do {
                $rodada++; Write-Log "--- RODADA $rodada/$max ---" -Level INFO
                $pendentes=0
                try {
                    $psOk=Get-Module -ListAvailable -Name PSWindowsUpdate -EA SilentlyContinue
                    if($psOk){
                        Import-Module PSWindowsUpdate -Force -EA SilentlyContinue
                        $ups=Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -EA SilentlyContinue
                        $pendentes=if($ups){$ups.Count}else{0}
                        Write-Log "  Encontradas: $pendentes" -Level INFO
                        if($pendentes-gt0){
                            $ups|ForEach-Object{Write-Log "  ⬇️  $($_.Title)" -Level INFO}
                            Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -EA SilentlyContinue 2>&1|
                                Where-Object{$_ -match '\S'}|ForEach-Object{Write-Log "  $_"}
                            $total+=$pendentes
                        }
                    } else {
                        Write-Log "  Usando Windows Update API nativa..." -Level INFO
                        $sess2=New-Object -ComObject Microsoft.Update.Session
                        $src=$sess2.CreateUpdateSearcher()
                        $qry="IsInstalled=0 and Type='Software'"
                        $res2=$src.Search($qry); $pendentes=$res2.Updates.Count
                        Write-Log "  Encontradas: $pendentes" -Level INFO
                        if($pendentes-gt0){
                            $col=New-Object -ComObject Microsoft.Update.UpdateColl
                            foreach($u2 in $res2.Updates){
                                Write-Log "  ⬇️  $($u2.Title)" -Level INFO
                                if(-not $u2.EulaAccepted){$u2.AcceptEula()}
                                $col.Add($u2)|Out-Null
                            }
                            $dlr=$sess2.CreateUpdateDownloader(); $dlr.Updates=$col
                            Write-Log "  Baixando $pendentes atualizacao(oes)..." -Level INFO; $dlr.Download()|Out-Null
                            $inst=$sess2.CreateUpdateInstaller(); $inst.Updates=$col
                            Write-Log "  Instalando..." -Level INFO
                            $ir=$inst.Install()
                            Write-Log "  Resultado: $($ir.ResultCode) | Reboot: $($ir.RebootRequired)" -Level INFO
                            $total+=$pendentes
                        }
                    }
                } catch { Write-Log "  Erro rodada $rodada`: $_" -Level ERROR; break }
                Update-Progress -Value([Math]::Min(15+($rodada*16),95))
                if($pendentes-eq0){Write-Log "✅ Nenhuma atualizacao pendente!" -Level SUCCESS; break}
            } while($rodada-lt$max -and $opts.DoLoop)

            Write-Log "== WINDOWS UPDATE - CONCLUiDO ==" -Level SUCCESS
            Write-Log " Total instalado: $total | Rodadas: $rodada" -Level SUCCESS
            Update-Progress -Value 100
            if($opts.DoReboot){Write-Log "Reiniciando em 30s..." -Level WARN; Start-Sleep 30; Restart-Computer -Force}
        }
    })
    $scroll.Controls.Add($btnR); $y+=52
    Update-Status "Modulo: Windows Update"
}
