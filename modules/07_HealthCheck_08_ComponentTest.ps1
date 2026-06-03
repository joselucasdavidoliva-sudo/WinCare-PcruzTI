<#
.SYNOPSIS
    Modulos 07-08 - HealthCheck | ComponentTest - WinCare Pro v1.0
#>

# ===============================================================================
# MoDULO 07 - Health Check
# ===============================================================================
function Show-HealthCheck {
    $area = $Global:WC.ModuleArea; $area.Controls.Clear()
    $scroll = New-Object System.Windows.Forms.Panel
    $scroll.Dock = 'Fill'; $scroll.AutoScroll = $true
    $scroll.BackColor = $Global:Theme.BG_Deep; $area.Controls.Add($scroll); $y = 80
    $Global:WC.HC = @{ Mcards = @() }

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Saude e Integridade da Maquina"
    $lbl.Font = $Global:Theme.Font_Title; $lbl.ForeColor = $Global:Theme.Text_Primary
    $lbl.Location = New-Object System.Drawing.Point(32,$y); $lbl.AutoSize = $true
    $scroll.Controls.Add($lbl); $y += 36

    # Card de score
    $scCard = New-Object System.Windows.Forms.Panel
    $scCard.Location = New-Object System.Drawing.Point(32,$y); $scCard.Size = New-Object System.Drawing.Size(204,110)
    $scCard.BackColor = $Global:Theme.BG_Card; $scroll.Controls.Add($scCard)
    $Global:WC.HC.lblScoreT = New-Object System.Windows.Forms.Label; $Global:WC.HC.lblScoreT.Text = "SCORE DE SAUDE"
    $Global:WC.HC.lblScoreT.Font = $Global:Theme.Font_Badge; $Global:WC.HC.lblScoreT.ForeColor = $Global:Theme.Text_Muted
    $Global:WC.HC.lblScoreT.Location = New-Object System.Drawing.Point(12,10); $Global:WC.HC.lblScoreT.AutoSize = $true; $scCard.Controls.Add($Global:WC.HC.lblScoreT)
    $Global:WC.HC.lblScore  = New-Object System.Windows.Forms.Label; $Global:WC.HC.lblScore.Text = "--"
    $Global:WC.HC.lblScore.Font = New-Object System.Drawing.Font('Segoe UI',38,[System.Drawing.FontStyle]::Bold)
    $Global:WC.HC.lblScore.ForeColor = $Global:Theme.Accent; $Global:WC.HC.lblScore.Location = New-Object System.Drawing.Point(12,28); $Global:WC.HC.lblScore.AutoSize = $true; $scCard.Controls.Add($Global:WC.HC.lblScore)
    $Global:WC.HC.lblStatus = New-Object System.Windows.Forms.Label; $Global:WC.HC.lblStatus.Text = "Aguardando diagnostico"
    $Global:WC.HC.lblStatus.Font = $Global:Theme.Font_Small; $Global:WC.HC.lblStatus.ForeColor = $Global:Theme.Text_Muted
    $Global:WC.HC.lblStatus.Location = New-Object System.Drawing.Point(12,90); $Global:WC.HC.lblStatus.AutoSize = $true; $scCard.Controls.Add($Global:WC.HC.lblStatus)

    # Painel de issues/ok
    $Global:WC.HC.rtbIssues = New-Object System.Windows.Forms.RichTextBox
    $Global:WC.HC.rtbIssues.Location = New-Object System.Drawing.Point(232,$y); $Global:WC.HC.rtbIssues.Size = New-Object System.Drawing.Size(468,110)
    $Global:WC.HC.rtbIssues.ReadOnly = $true; $Global:WC.HC.rtbIssues.BackColor = $Global:Theme.BG_Card; $Global:WC.HC.rtbIssues.ForeColor = $Global:Theme.Text_Primary
    $Global:WC.HC.rtbIssues.Font = $Global:Theme.Font_Small; $Global:WC.HC.rtbIssues.BorderStyle = 'None'
    $Global:WC.HC.rtbIssues.Text = "Execute o diagnostico completo para ver o relatorio detalhado de saude."
    $scroll.Controls.Add($Global:WC.HC.rtbIssues); $y += 120

    # Grid de metricas
    $slM = New-SectionLabel -Text "Metricas do Sistema" -X 32 -Y $y; $scroll.Controls.Add($slM); $y += 30
    $lnM = New-Separator -X 32 -Y $y -Width 680; $scroll.Controls.Add($lnM); $y += 14

    $mDefs = @(
        @{ L='CPU';          I='CPU'; S='nucleos / uso' },
        @{ L='RAM';          I='RAM'; S='GB livre / uso' },
        @{ L='Disco C:';     I='HDD'; S='GB livre / %'  },
        @{ L='Defender';     I='DEF'; S='status'        },
        @{ L='Uptime';       I='UP';  S='dias/horas'    },
        @{ L='Win Updates';  I='UPD'; S='pendentes'     }
    )
    $mcards = @()
    $cW = 214; $cH = 76; $gap = 6; $xc = 20
    for ($mi = 0; $mi -lt $mDefs.Count; $mi++) {
        $row = [Math]::Floor($mi/3); $col = $mi%3
        $mc = New-Object System.Windows.Forms.Panel
        $mc.Location = New-Object System.Drawing.Point(($xc+$col*($cW+$gap)),($y+$row*($cH+$gap)))
        $mc.Size = New-Object System.Drawing.Size($cW,$cH); $mc.BackColor = $Global:Theme.BG_Card
        $scroll.Controls.Add($mc); $Global:WC.HC.Mcards += $mc

        $liI = New-Object System.Windows.Forms.Label; $liI.Text = $mDefs[$mi].I
        $liI.Font = New-Object System.Drawing.Font('Segoe UI',7,[System.Drawing.FontStyle]::Bold)
        $liI.ForeColor = $Global:Theme.Accent; $liI.BackColor = $Global:Theme.BG_Deep
        $liI.Location = New-Object System.Drawing.Point(8,10); $liI.Size = New-Object System.Drawing.Size(36,16); $liI.TextAlign = 'MiddleCenter'; $mc.Controls.Add($liI)
        $liL = New-Object System.Windows.Forms.Label; $liL.Text = $mDefs[$mi].L
        $liL.Font = $Global:Theme.Font_Small; $liL.ForeColor = $Global:Theme.Text_Muted; $liL.Location = New-Object System.Drawing.Point(50,10); $liL.AutoSize = $true; $mc.Controls.Add($liL)
        $liV = New-Object System.Windows.Forms.Label; $liV.Text = "--"; $liV.Name = "MV$mi"
        $liV.Font = $Global:Theme.Font_Header; $liV.ForeColor = $Global:Theme.Text_Primary
        $liV.Location = New-Object System.Drawing.Point(50,28); $liV.Size = New-Object System.Drawing.Size(155,22); $mc.Controls.Add($liV)
        $liS = New-Object System.Windows.Forms.Label; $liS.Text = $mDefs[$mi].S
        $liS.Font = $Global:Theme.Font_Small; $liS.ForeColor = $Global:Theme.Text_Muted; $liS.Location = New-Object System.Drawing.Point(50,52); $liS.AutoSize = $true; $mc.Controls.Add($liS)
    }
    $y += [Math]::Ceiling($mDefs.Count/3)*($cH+$gap) + 16

    # Event Log recentes
    $slEv = New-SectionLabel -Text "Eventos Criticos (ultimas 24h)" -X 32 -Y $y; $scroll.Controls.Add($slEv); $y += 30
    $lnEv = New-Separator -X 32 -Y $y -Width 680; $scroll.Controls.Add($lnEv); $y += 14
    $Global:WC.HC.rtbEvents = New-Object System.Windows.Forms.RichTextBox
    $Global:WC.HC.rtbEvents.Location = New-Object System.Drawing.Point(32,$y); $Global:WC.HC.rtbEvents.Size = New-Object System.Drawing.Size(680,100)
    $Global:WC.HC.rtbEvents.ReadOnly = $true; $Global:WC.HC.rtbEvents.BackColor = $Global:Theme.BG_Card; $Global:WC.HC.rtbEvents.ForeColor = $Global:Theme.Text_Primary
    $Global:WC.HC.rtbEvents.Font = $Global:Theme.Font_Small; $Global:WC.HC.rtbEvents.BorderStyle = 'None'; $Global:WC.HC.rtbEvents.ScrollBars = 'Vertical'
    $Global:WC.HC.rtbEvents.Text = "Execute o diagnostico para ver os eventos."; $scroll.Controls.Add($Global:WC.HC.rtbEvents); $y += 112

    # Botoes
    $btnRun7 = New-StyledButton -Text 'EXECUTAR DIAGNOSTICO' -X 32 -Y $y -Width 250 -Height 44 -Style 'Primary'
    $btnRun7.Font = $Global:Theme.Font_Header
    $btnRun7.Add_Click({
        $this.Enabled = $false; $this.Text = 'Analisando...'
        $Global:WC._runBtn = $this
        Invoke-ModuleTask -TaskName 'Health Check' `
            -Variables @{ lsc = $lsc; lss = $lss; rr = $rr; re = $re; mc7 = $mc7 } `
            -OnComplete {
                if ($Global:WC._runBtn) { $Global:WC._runBtn.Enabled = $true; $Global:WC._runBtn.Text = 'EXECUTAR DIAGNOSTICO'; $Global:WC._runBtn.BackColor = $Global:Theme.Accent }
            } `
            -Task {
            Write-Log "== HEALTH CHECK - INICIO ==" -Level INFO
            $score = 100; $issues = @(); $ok = @()

            # CPU
            $cpu = Get-CimInstance Win32_Processor -EA SilentlyContinue | Select-Object -First 1
            $cpuLoad = $cpu.LoadPercentage; $cpuCores = $cpu.NumberOfCores
            Write-Log "CPU: $($cpu.Name) | $cpuCores nucleos | $cpuLoad% uso" -Level INFO
            if ($cpuLoad -gt 90) { $score -= 10; $issues += "CPU critica ($cpuLoad% uso)" }
            elseif ($cpuLoad -gt 75) { $score -= 5; $issues += "CPU alta ($cpuLoad% uso)" }
            else { $ok += "CPU OK ($cpuLoad% uso)" }
            Update-Progress -Value 12

            # RAM
            $os7 = Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue
            $ramFree  = [Math]::Round($os7.FreePhysicalMemory/1MB,1)
            $ramTotal = [Math]::Round($os7.TotalVisibleMemorySize/1MB,1)
            $ramUsed  = [Math]::Round((1 - $os7.FreePhysicalMemory/$os7.TotalVisibleMemorySize)*100)
            Write-Log "RAM: $ramTotal GB total | $ramFree GB livre | $ramUsed% uso" -Level INFO
            if ($ramUsed -gt 92) { $score -= 15; $issues += "RAM critica ($ramUsed% usada)" }
            elseif ($ramUsed -gt 80) { $score -= 5; $issues += "RAM alta ($ramUsed% usada)" }
            else { $ok += "RAM OK ($ramUsed% uso)" }
            Update-Progress -Value 24

            # Disco
            $dsk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -EA SilentlyContinue
            $dskFree = [Math]::Round($dsk.FreeSpace/1GB,1)
            $dskPct  = [Math]::Round($dsk.FreeSpace/$dsk.Size*100)
            Write-Log "Disco C: $([Math]::Round($dsk.Size/1GB,0)) GB | $dskFree GB livre ($dskPct%)" -Level INFO
            if ($dskPct -lt 5)  { $score -= 25; $issues += "Disco CRiTICO (<5% livre: $dskFree GB)" }
            elseif ($dskPct -lt 10) { $score -= 15; $issues += "Disco baixo (<10%: $dskFree GB)" }
            elseif ($dskPct -lt 20) { $score -= 5;  $issues += "Disco baixo (<20%: $dskFree GB)" }
            else { $ok += "Disco OK ($dskPct% livre)" }
            Update-Progress -Value 38

            # Defender
            $wd = Get-MpComputerStatus -EA SilentlyContinue
            $wdAge = 0; $wdStat = "N/D"
            if ($wd) {
                $wdAge  = ((Get-Date) - $wd.AntivirusSignatureLastUpdated).Days
                $wdStat = if ($wd.RealTimeProtectionEnabled) { "Ativo" } else { "INATIVO" }
                Write-Log "Defender: $wdStat | Assinaturas: $wdAge dias atras" -Level INFO
                if (-not $wd.RealTimeProtectionEnabled) { $score -= 20; $issues += "Defender DESATIVADO!" }
                elseif ($wdAge -gt 7) { $score -= 8; $issues += "Defender desatualizado ($wdAge dias)" }
                else { $ok += "Defender OK (atualizado ha $wdAge dias)" }
            }
            Update-Progress -Value 52

            # Uptime
            $up = (Get-Date) - (Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue).LastBootUpTime
            $upTxt = "$($up.Days)d $($up.Hours)h"
            Write-Log "Uptime: $upTxt" -Level INFO
            if ($up.TotalDays -gt 14) { $score -= 5; $issues += "Sistema sem reboot ha $([Math]::Round($up.TotalDays,0)) dias" }
            else { $ok += "Uptime OK ($($up.Days) dias)" }
            Update-Progress -Value 64

            # Windows Update
            $pendWU = 0
            try {
                $pendWU = ((New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher().Search("IsInstalled=0 and Type='Software'")).Updates.Count
                Write-Log "Updates pendentes: $pendWU" -Level INFO
                if ($pendWU -gt 10) { $score -= 10; $issues += "$pendWU updates Windows pendentes" }
                elseif ($pendWU -gt 0) { $score -= 3; $issues += "$pendWU updates Windows pendentes" }
                else { $ok += "Windows totalmente atualizado" }
            } catch {}
            Update-Progress -Value 76

            # Event Log
            $evSys = 0; $evApp = 0
            try {
                $evSys = (Get-EventLog -LogName System      -EntryType Error -After (Get-Date).AddHours(-24) -EA SilentlyContinue).Count
                $evApp = (Get-EventLog -LogName Application -EntryType Error -After (Get-Date).AddHours(-24) -EA SilentlyContinue).Count
                $evTot = $evSys + $evApp
                Write-Log "EventLog (24h): System=$evSys | Application=$evApp" -Level INFO
                if ($evTot -gt 50) { $score -= 10; $issues += "Muitos erros EventLog ($evTot nas ultimas 24h)" }
                elseif ($evTot -gt 20) { $score -= 5; $issues += "$evTot erros no EventLog (24h)" }
                else { $ok += "EventLog OK ($evTot erros/24h)" }
            } catch {}
            Update-Progress -Value 88

            # Resultado
            $sc7 = [Math]::Max($score, 0)
            $scC = if ($sc7 -ge 80) { $Global:Theme.Success } elseif ($sc7 -ge 60) { $Global:Theme.Warning } else { $Global:Theme.Danger }
            $scL = if ($sc7 -ge 80) { "✅ Otimo" } elseif ($sc7 -ge 60) { "[!] Regular" } else { "❌ Atencao Necessaria" }
            Write-Log "SCORE FINAL: $sc7/100 | $scL" -Level SUCCESS
            Write-Log "Problemas: $($issues.Count) | OK: $($ok.Count)" -Level INFO

            # Atualiza UI
            $WC.HC.lblScore.Invoke([Action]{ $WC.HC.lblScore.Text = "$sc7"; $WC.HC.lblScore.ForeColor = $scC })
            $WC.HC.lblStatus.Invoke([Action]{ $WC.HC.lblStatus.Text = $scL })
            $WC.HC.rtbIssues.Invoke([Action]{
                $WC.HC.rtbIssues.Clear()
                $issues | ForEach-Object { $WC.HC.rtbIssues.AppendText("[!]  $_`r`n") }
                $ok     | ForEach-Object { $WC.HC.rtbIssues.AppendText("✅  $_`r`n") }
            })

            $vals7 = @("$cpuCores nucleo / $cpuLoad%", "$ramFree/$ramTotal GB ($ramUsed%)",
                       "$dskFree GB ($dskPct%)", "$wdStat / $wdAge dias", $upTxt, "$pendWU pendente(s)")
            for ($mi7 = 0; $mi7 -lt $WC.HC.Mcards.Count; $mi7++) {
                $idx7 = $mi7; $v7 = if ($idx7 -lt $vals7.Count) { $vals7[$idx7] } else { "--" }
                $ctrl7 = $WC.HC.Mcards[$idx7].Controls | Where-Object { $_.Name -eq "MV$idx7" } | Select-Object -First 1
                if ($ctrl7) { $ctrl7.Invoke([Action]{ $ctrl7.Text = $v7 }) }
            }

            $WC.HC.rtbEvents.Invoke([Action]{
                $WC.HC.rtbEvents.Clear()
                try {
                    $allEv = @()
                    if ($evSys -gt 0) { $allEv += Get-EventLog -LogName System -EntryType Error -After (Get-Date).AddHours(-24) -Newest 5 -EA SilentlyContinue }
                    if ($evApp -gt 0) { $allEv += Get-EventLog -LogName Application -EntryType Error -After (Get-Date).AddHours(-24) -Newest 5 -EA SilentlyContinue }
                    if ($allEv) {
                        $allEv | Sort-Object TimeGenerated -Descending | Select-Object -First 10 | ForEach-Object {
                            $msg7 = $_.Message.Substring(0,[Math]::Min(80,$_.Message.Length)) -replace '\r?\n',' '
                            $WC.HC.rtbEvents.AppendText("$($_.TimeGenerated.ToString('dd/MM HH:mm'))  [$($_.Source)]  $msg7`r`n")
                        }
                    } else { $WC.HC.rtbEvents.AppendText("✅ Nenhum evento critico nas ultimas 24h.") }
                } catch { $WC.HC.rtbEvents.AppendText("Eventos indisponiveis.") }
            })
            Update-Progress -Value 100
        }
    })
    $scroll.Controls.Add($btnRun7)

    $btnRep7 = New-StyledButton -Text '📄 Exportar Relatorio HTML' -X 278 -Y $y -Width 220 -Height 44 -Style 'Secondary'
    $btnRep7.Add_Click({ Export-HealthReport }.GetNewClosure()); $scroll.Controls.Add($btnRep7)
    Update-Status "Modulo: Health Check"
}

function Export-HealthReport {
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter   = 'HTML (*.html)|*.html'
    $sfd.FileName = "WinCare_HealthReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    if ($sfd.ShowDialog() -ne 'OK') { return }
    $logC  = (Get-LogContent) -join "`n"
    $osI   = Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue
    $cpuI  = (Get-CimInstance Win32_Processor -EA SilentlyContinue | Select-Object -First 1).Name
    $ramI  = "$([Math]::Round((Get-CimInstance Win32_ComputerSystem -EA SilentlyContinue).TotalPhysicalMemory/1GB,1)) GB"
    $html = @"
<!DOCTYPE html><html lang="pt-BR"><head><meta charset="UTF-8">
<title>WinCare Pro - Relatorio de Saude - $env:COMPUTERNAME</title>
<style>
  *{box-sizing:border-box}body{background:#0a0c14;color:#dce6ff;font-family:'Segoe UI',sans-serif;margin:0;padding:32px}
  h1{color:#008cff;border-bottom:2px solid #1c2848;padding-bottom:12px;margin-top:0}
  h2{color:#5ab4ff;margin-top:28px;font-size:14px;text-transform:uppercase;letter-spacing:1px}
  .card{background:#182030;border:1px solid #283a5a;border-radius:6px;padding:16px;margin:8px 0}
  .grid{display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin:12px 0}
  .metric{background:#0d111c;border:1px solid #1c2848;border-radius:4px;padding:12px}
  .metric .val{font-size:22px;font-weight:bold;color:#008cff}
  .metric .lbl{font-size:11px;color:#6478a0;margin-top:4px}
  pre{background:#0d111c;padding:14px;border-radius:4px;overflow-x:auto;font-size:11px;color:#00dc82;white-space:pre-wrap;word-break:break-all;max-height:500px;overflow-y:auto}
  .ok{color:#00dc82}.warn{color:#ffb400}.err{color:#ff3c50}
  footer{margin-top:32px;color:#3a4a6a;font-size:11px;text-align:center}
</style></head><body>
<h1>🛡️ WinCare Pro - Relatorio de Saude</h1>
<div class="card">
  <b>Computador:</b> $env:COMPUTERNAME &nbsp;|&nbsp;
  <b>Usuario:</b> $env:USERNAME &nbsp;|&nbsp;
  <b>Data:</b> $(Get-Date -Format 'dd/MM/yyyy HH:mm') &nbsp;|&nbsp;
  <b>PS:</b> $($PSVersionTable.PSVersion)
</div>
<div class="card">
  <b>SO:</b> $($osI.Caption) (Build $($osI.BuildNumber)) &nbsp;|&nbsp;
  <b>CPU:</b> $cpuI &nbsp;|&nbsp;
  <b>RAM:</b> $ramI
</div>
<h2>📋 Log Completo da Sessao</h2>
<pre>$logC</pre>
<footer>Gerado por WinCare Pro v$($Global:WC.Version) - $env:COMPUTERNAME - $(Get-Date -Format 'dd/MM/yyyy HH:mm')</footer>
</body></html>
"@
    $html | Set-Content -Path $sfd.FileName -Encoding UTF8
    Write-Log "Relatorio HTML exportado: $($sfd.FileName)" -Level SUCCESS
    Start-Process $sfd.FileName
}

# ===============================================================================
# MoDULO 08 - Testes de Componentes
# ===============================================================================
function Show-ComponentTest {
    $area.Controls.Clear(); $scroll = New-Object System.Windows.Forms.Panel
    $scroll.Dock = 'Fill'; $scroll.AutoScroll = $true
    $scroll.BackColor = $Global:Theme.BG_Deep; $area.Controls.Add($scroll); $y = 80
    $Global:WC.CT = @{ Chks = @{} }

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Testes de Hardware e Componentes"
    $lbl.Font = $Global:Theme.Font_Title; $lbl.ForeColor = $Global:Theme.Text_Primary
    $lbl.Location = New-Object System.Drawing.Point(32,$y); $lbl.AutoSize = $true
    $scroll.Controls.Add($lbl); $y += 36

    $taskDefs8 = [ordered]@{
        'cpuInfo'   = @{ G='Processador';   T='Informacoes completas (modelo, nucleos, cache, clock)';            Def=$true  }
        'cpuBench'  = @{ G='Processador';   T='Benchmark CPU - calculo de 100.000 numeros primos';                Def=$false }
        'cpuStress' = @{ G='Processador';   T='Stress test rapido (5s) - detecta throttling';                     Def=$false }
        'ramInfo'   = @{ G='Memoria RAM';   T='Informacoes de RAM (slots, velocidade, fabricante, tipo)';          Def=$true  }
        'ramUsage'  = @{ G='Memoria RAM';   T='Processos com maior uso de RAM (Top 10)';                           Def=$true  }
        'ramTest'   = @{ G='Memoria RAM';   T='[!] Agendar diagnostico de memoria (mdsched - requer reboot)';  Def=$false }
        'diskInfo'  = @{ G='Armazenamento'; T='Informacoes de todos os discos (modelo, capacidade, tipo)';         Def=$true  }
        'diskSpeed' = @{ G='Armazenamento'; T='Teste de velocidade C: leitura/escrita sequencial (100MB)';         Def=$true  }
        'diskSmart' = @{ G='Armazenamento'; T='Status S.M.A.R.T. via WMI (detecta discos com falha)';             Def=$true  }
        'gpuInfo'   = @{ G='GPU e Video';   T='Informacoes da GPU (modelo, VRAM, resolucao, driver)';             Def=$true  }
        'dxdiag'    = @{ G='GPU e Video';   T='Exportar relatorio completo DirectX (dxdiag /t)';                   Def=$false }
        'netPing'   = @{ G='Rede';          T='Ping para 8.8.8.8, 1.1.1.1, google.com, cloudflare.com';           Def=$true  }
        'netTrace'  = @{ G='Rede';          T='Traceroute para detectar gargalos de rede (tracert)';               Def=$false }
        'netAdp'    = @{ G='Rede';          T='Listar todos os adaptadores de rede e enderecos IP';                Def=$true  }
        'netSpeed'  = @{ G='Rede';          T='Teste de velocidade de internet (via API cloudflare)';              Def=$false }
        'battery'   = @{ G='Bateria';       T='Relatorio de saude da bateria (powercfg /batteryreport)';           Def=$true  }
        'powerEff'  = @{ G='Bateria';       T='Relatorio de eficiencia energetica (powercfg /energy - 10s)';       Def=$false }
    }

    $curGroup8 = ''
    foreach ($key in $taskDefs8.Keys) {
        $def = $taskDefs8[$key]
        if ($def.G -ne $curGroup8) {
            $curGroup8 = $def.G
            $sl = New-SectionLabel -Text $curGroup8 -X 32 -Y $y; $scroll.Controls.Add($sl); $y += 30
            $ln = New-Separator -X 32 -Y $y -Width 680; $scroll.Controls.Add($ln); $y += 10
        }
        $c = New-StyledCheckBox -Text "    $($def.T)" -X 32 -Y $y -Width 680; $c.Checked = $def.Def
        if ($def.T -match '\[!\]') { $c.ForeColor = $Global:Theme.Warning }
        $scroll.Controls.Add($c); $Global:WC.CT.Chks[$key] = $c; $y += 28
    }
    $y += 12

    $btnAll8  = New-StyledButton -Text '[v] Todos'  -X 32  -Y $y -Width 100 -Height 32 -Style 'Secondary'
    $btnNone8 = New-StyledButton -Text '[ ] Nenhum' -X 128 -Y $y -Width 100 -Height 32 -Style 'Secondary'
    $btnAll8.Add_Click({  foreach ($c in $Global:WC.CT.Chks.Values) { $c.Checked = $true  } })
    $btnNone8.Add_Click({ foreach ($c in $Global:WC.CT.Chks.Values) { $c.Checked = $false } })
    $scroll.Controls.Add($btnAll8); $scroll.Controls.Add($btnNone8); $y += 44

    $btnRun8 = New-StyledButton -Text '>  EXECUTAR TESTES' -X 32 -Y $y -Width 230 -Height 44 -Style 'Primary'
    $btnRun8.Font = $Global:Theme.Font_Header
    $btnRun8.Add_Click({
        $sel = @{}
        foreach ($key in $Global:WC.CT.Chks.Keys) { $sel[$key] = $Global:WC.CT.Chks[$key].Checked }

        $this.Enabled = $false; $this.Text = 'Testando...'
        $Global:WC._runBtn = $this
        Invoke-ModuleTask -TaskName 'Component Tests' `
            -Variables @{ sel = $sel } `
            -OnComplete {
                if ($Global:WC._runBtn) { $Global:WC._runBtn.Enabled = $true; $Global:WC._runBtn.Text = '>  EXECUTAR TESTES'; $Global:WC._runBtn.BackColor = $Global:Theme.Accent }
            } `
            -Task {
            Write-Log "== TESTES DE COMPONENTES - INICIO ==" -Level INFO; $p8 = 4

            if ($sel['cpuInfo']) {
                $cpu8 = Get-CimInstance Win32_Processor -EA SilentlyContinue
                Write-Log "--- PROCESSADOR ---" -Level INFO
                Write-Log "  Modelo : $($cpu8.Name)" -Level INFO
                Write-Log "  Nucleos: $($cpu8.NumberOfCores) fisicos / $($cpu8.NumberOfLogicalProcessors) logicos" -Level INFO
                Write-Log "  Clock  : $($cpu8.MaxClockSpeed) MHz" -Level INFO
                Write-Log "  Cache  : L2=$($cpu8.L2CacheSize)KB  L3=$($cpu8.L3CacheSize)KB" -Level INFO
                Write-Log "  Carga  : $($cpu8.LoadPercentage)%" -Level INFO
                $p8 += 8; Update-Progress -Value $p8
            }
            if ($sel['cpuBench']) {
                Write-Log "--- BENCHMARK CPU ---" -Level INFO
                Write-Log "  Calculando 100.000 numeros primos..." -Level INFO
                $sw8 = [System.Diagnostics.Stopwatch]::StartNew()
                $pr8 = 0; $n8 = 2
                while ($pr8 -lt 100000) {
                    $ip = $true
                    for ($d = 2; $d -le [Math]::Sqrt($n8); $d++) { if ($n8 % $d -eq 0) { $ip = $false; break } }
                    if ($ip) { $pr8++ }; $n8++
                }
                $sw8.Stop()
                $sec8 = $sw8.Elapsed.TotalSeconds.ToString('F3')
                $perf8 = if ($sw8.Elapsed.TotalSeconds -lt 1.5) { "🏆 Excelente" } elseif ($sw8.Elapsed.TotalSeconds -lt 4) { "✅ Bom" } else { "[!] Regular" }
                Write-Log "  100k primos em ${sec8}s - $perf8" -Level SUCCESS
                $p8 += 10; Update-Progress -Value $p8
            }
            if ($sel['cpuStress']) {
                Write-Log "--- STRESS TEST CPU (5s) ---" -Level INFO
                $cStart = $cpu8.LoadPercentage
                $jobs8 = @()
                $nc = (Get-CimInstance Win32_Processor -EA SilentlyContinue).NumberOfLogicalProcessors
                for ($j = 0; $j -lt $nc; $j++) { $jobs8 += Start-Job { while ($true) { } } }
                Start-Sleep 5
                $jobs8 | Stop-Job -PassThru | Remove-Job -Force
                $cEnd = (Get-CimInstance Win32_Processor -EA SilentlyContinue).LoadPercentage
                Write-Log "  Antes: $cStart% | Depois stress 5s: $cEnd%" -Level INFO
                Write-Log "  $(if($cEnd -gt 70){'CPU respondeu ao stress - OK'}else{'CPU pode ter limitado (throttling)'})" -Level INFO
                $p8 += 8; Update-Progress -Value $p8
            }
            if ($sel['ramInfo']) {
                Write-Log "--- MEMoRIA RAM ---" -Level INFO
                $stks = Get-CimInstance Win32_PhysicalMemory -EA SilentlyContinue
                $totalRAM = ($stks | Measure-Object -Property Capacity -Sum).Sum / 1GB
                Write-Log "  Total: $([Math]::Round($totalRAM,1)) GB" -Level INFO
                foreach ($st8 in $stks) {
                    Write-Log "  $($st8.DeviceLocator): $([Math]::Round($st8.Capacity/1GB,0)) GB @ $($st8.Speed) MHz - $($st8.Manufacturer) [$($st8.MemoryType)]" -Level INFO
                }
                $os8 = Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue
                $free8 = [Math]::Round($os8.FreePhysicalMemory/1MB,1)
                Write-Log "  Disponivel agora: $free8 GB" -Level INFO
                $p8 += 8; Update-Progress -Value $p8
            }
            if ($sel['ramUsage']) {
                Write-Log "--- TOP 10 PROCESSOS (RAM) ---" -Level INFO
                Get-Process -EA SilentlyContinue | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 | ForEach-Object {
                    Write-Log "  $($_.ProcessName.PadRight(28)) $([Math]::Round($_.WorkingSet64/1MB,1)) MB" -Level INFO
                }
                $p8 += 6; Update-Progress -Value $p8
            }
            if ($sel['ramTest']) {
                Write-Log "--- DIAGNoSTICO DE MEMoRIA ---" -Level WARN
                Start-Process mdsched.exe -EA SilentlyContinue
                Write-Log "  mdsched.exe aberto - escolha a opcao de agendamento" -Level SUCCESS
                $p8 += 4; Update-Progress -Value $p8
            }
            if ($sel['diskInfo']) {
                Write-Log "--- DISCOS FiSICOS ---" -Level INFO
                Get-CimInstance Win32_DiskDrive -EA SilentlyContinue | ForEach-Object {
                    Write-Log "  $($_.Model) | $([Math]::Round($_.Size/1GB,0)) GB | Particoes: $($_.Partitions) | Interface: $($_.InterfaceType)" -Level INFO
                }
                Write-Log "--- VOLUMES LoGICOS ---" -Level INFO
                Get-CimInstance Win32_LogicalDisk -EA SilentlyContinue | Where-Object { $_.Size } | ForEach-Object {
                    $fp = [Math]::Round($_.FreeSpace/1GB,1); $tot = [Math]::Round($_.Size/1GB,0)
                    $pct = [Math]::Round($_.FreeSpace/$_.Size*100)
                    Write-Log "  $($_.DeviceID) [$($_.VolumeName)]  $fp GB livre / $tot GB ($pct%)" -Level INFO
                }
                $p8 += 8; Update-Progress -Value $p8
            }
            if ($sel['diskSpeed']) {
                Write-Log "--- VELOCIDADE DISCO ---" -Level INFO
                $tf8 = "$env:TEMP\wc_dt_$(Get-Random).tmp"
                $buf8 = New-Object byte[](1MB); [System.Random]::new().NextBytes($buf8)
                try {
                    $sw2 = [System.Diagnostics.Stopwatch]::StartNew()
                    $fs8 = [System.IO.File]::OpenWrite($tf8)
                    1..100 | ForEach-Object { $fs8.Write($buf8,0,$buf8.Length) }
                    $fs8.Flush(); $fs8.Close(); $sw2.Stop()
                    $wMBs = [Math]::Round(100/$sw2.Elapsed.TotalSeconds,1)
                    Write-Log "  Escrita sequencial : $wMBs MB/s" -Level SUCCESS
                    $sw2.Restart()
                    $fs8b = [System.IO.File]::OpenRead($tf8)
                    $rb8  = New-Object byte[](1MB)
                    while ($fs8b.Read($rb8,0,$rb8.Length) -gt 0) {}
                    $fs8b.Close(); $sw2.Stop()
                    $rMBs = [Math]::Round(100/$sw2.Elapsed.TotalSeconds,1)
                    Write-Log "  Leitura sequencial : $rMBs MB/s" -Level SUCCESS
                    $tipo8 = if ($rMBs -gt 400) { "SSD NVMe" } elseif ($rMBs -gt 150) { "SSD SATA" } elseif ($rMBs -gt 80) { "HDD rapido" } else { "HDD lento" }
                    Write-Log "  Tipo estimado: $tipo8" -Level INFO
                } catch { Write-Log "  Erro no teste: $_" -Level ERROR }
                finally   { Remove-Item $tf8 -Force -EA SilentlyContinue }
                $p8 += 12; Update-Progress -Value $p8
            }
            if ($sel['diskSmart']) {
                Write-Log "--- STATUS S.M.A.R.T. ---" -Level INFO
                Get-CimInstance -Namespace root\WMI -ClassName MSStorageDriver_FailurePredictStatus -EA SilentlyContinue | ForEach-Object {
                    $status8 = if ($_.PredictFailure) { "❌ FALHA PREVISTA" } else { "✅ OK" }
                    Write-Log "  Disco: $($_.InstanceName) - $status8" -Level $(if($_.PredictFailure){'ERROR'}else{'SUCCESS'})
                }
                $p8 += 6; Update-Progress -Value $p8
            }
            if ($sel['gpuInfo']) {
                Write-Log "--- GPU ---" -Level INFO
                Get-CimInstance Win32_VideoController -EA SilentlyContinue | ForEach-Object {
                    Write-Log "  $($_.Name)" -Level INFO
                    Write-Log "  VRAM  : $([Math]::Round($_.AdapterRAM/1MB,0)) MB" -Level INFO
                    Write-Log "  Resolucao: $($_.CurrentHorizontalResolution)x$($_.CurrentVerticalResolution) @ $($_.CurrentRefreshRate) Hz" -Level INFO
                    Write-Log "  Driver : $($_.DriverVersion)  ($($_.DriverDate))" -Level INFO
                }
                $p8 += 6; Update-Progress -Value $p8
            }
            if ($sel['dxdiag']) {
                Write-Log "--- RELAToRIO DIRECTX ---" -Level INFO
                $dxOut = "$env:TEMP\WinCare_dxdiag_$(Get-Date -Format 'yyyyMMdd').txt"
                & dxdiag /t $dxOut 2>&1 | Out-Null
                Start-Sleep 5
                if (Test-Path $dxOut) { Write-Log "  Relatorio DX: $dxOut" -Level SUCCESS; Start-Process notepad $dxOut }
                $p8 += 4; Update-Progress -Value $p8
            }
            if ($sel['netPing']) {
                Write-Log "--- CONECTIVIDADE ---" -Level INFO
                @('8.8.8.8','1.1.1.1','google.com','cloudflare.com') | ForEach-Object {
                    $r8 = Test-Connection $_ -Count 4 -EA SilentlyContinue
                    if ($r8) {
                        $avg8 = [Math]::Round(($r8 | Measure-Object ResponseTime -Average).Average,0)
                        $min8 = ($r8 | Measure-Object ResponseTime -Minimum).Minimum
                        $max8 = ($r8 | Measure-Object ResponseTime -Maximum).Maximum
                        $q8   = if ($avg8 -lt 20) { "Excelente" } elseif ($avg8 -lt 50) { "Bom" } elseif ($avg8 -lt 100) { "Regular" } else { "Ruim" }
                        Write-Log "  $_ - avg:${avg8}ms  min:${min8}ms  max:${max8}ms - $q8" -Level SUCCESS
                    } else { Write-Log "  $_ - SEM RESPOSTA" -Level WARN }
                }
                $p8 += 8; Update-Progress -Value $p8
            }
            if ($sel['netTrace']) {
                Write-Log "--- TRACEROUTE (8.8.8.8) ---" -Level INFO
                & tracert -h 10 8.8.8.8 2>&1 | Where-Object { $_ -match '\S' } | ForEach-Object { Write-Log "  $_" }
                $p8 += 6; Update-Progress -Value $p8
            }
            if ($sel['netAdp']) {
                Write-Log "--- ADAPTADORES DE REDE ---" -Level INFO
                Get-NetAdapter -EA SilentlyContinue | ForEach-Object {
                    $ip8 = (Get-NetIPAddress -InterfaceAlias $_.Name -AddressFamily IPv4 -EA SilentlyContinue | Select-Object -First 1).IPAddress
                    Write-Log "  $($_.Name.PadRight(30)) $($_.Status.PadRight(12)) $($_.LinkSpeed.PadRight(12)) IP: $ip8" -Level INFO
                }
                $p8 += 6; Update-Progress -Value $p8
            }
            if ($sel['battery']) {
                Write-Log "--- BATERIA ---" -Level INFO
                $br8 = "$env:TEMP\WinCare_battery_$(Get-Date -Format 'yyyyMMdd').html"
                & powercfg /batteryreport /output $br8 2>&1 | ForEach-Object { Write-Log "  $_" }
                if (Test-Path $br8) { Write-Log "  Relatorio: $br8" -Level SUCCESS; Start-Process $br8 }
                else { Write-Log "  Bateria nao detectada (desktop)" -Level WARN }
                $p8 += 4; Update-Progress -Value $p8
            }
            if ($sel['powerEff']) {
                Write-Log "--- EFICIeNCIA ENERGeTICA ---" -Level INFO
                $er8 = "$env:TEMP\WinCare_energy_$(Get-Date -Format 'yyyyMMdd').html"
                Write-Log "  Coletando dados por 10 segundos..." -Level INFO
                & powercfg /energy /output $er8 /duration 10 2>&1 | ForEach-Object { Write-Log "  $_" }
                if (Test-Path $er8) { Write-Log "  Relatorio: $er8" -Level SUCCESS; Start-Process $er8 }
                $p8 += 4; Update-Progress -Value $p8
            }
            Write-Log "== TESTES DE COMPONENTES - CONCLUIDO ==" -Level SUCCESS; Update-Progress -Value 100
        }
    })
    $scroll.Controls.Add($btnRun8)
    Update-Status "Modulo: Component Tests"
}
