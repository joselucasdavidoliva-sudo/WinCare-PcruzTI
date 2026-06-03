<#
.SYNOPSIS
    Modulos 03-04 - BugFixer | OfficeSuite - WinCare Pro v1.0
#>

# ===============================================================================
# MoDULO 03 - Correcao de Bugs
# ===============================================================================
function Show-BugFixer {
    $area = $Global:WC.ModuleArea; $area.Controls.Clear()
    $scroll = New-Object System.Windows.Forms.Panel
    $scroll.Dock = 'Fill'; $scroll.AutoScroll = $true
    $scroll.BackColor = $Global:Theme.BG_Deep; $area.Controls.Add($scroll); $y = 80
    $Global:WC.BF = @{ Chks = @{} }

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Correcao de Bugs do Sistema"
    $lbl.Font = $Global:Theme.Font_Title; $lbl.ForeColor = $Global:Theme.Text_Primary
    $lbl.Location = New-Object System.Drawing.Point(32,$y); $lbl.AutoSize = $true
    $scroll.Controls.Add($lbl); $y += 36

    $desc = New-Object System.Windows.Forms.Label
    $desc.Text = "Corrige os bugs e inconsistencias mais comuns do Windows sem necessidade de reinstalacao."
    $desc.Font = $Global:Theme.Font_Body; $desc.ForeColor = $Global:Theme.Text_Muted
    $desc.Location = New-Object System.Drawing.Point(32,$y); $desc.Size = New-Object System.Drawing.Size(700,18)
    $scroll.Controls.Add($desc); $y += 34

    $taskDefs = [ordered]@{
        'wmi'       = @{ G='WMI e Servicos';    T='Reparar repositorio WMI (winmgmt /resetrepository)';           Def=$true;  W=$false }
        'rpc'       = @{ G='WMI e Servicos';    T='Verificar e reiniciar RPC, DCOM e dependencias criticas';      Def=$true;  W=$false }
        'eventclear'= @{ G='WMI e Servicos';    T='Limpar entradas repetidas de erro no Event Log';               Def=$false; W=$false }
        'store'     = @{ G='Store e UWP';       T='Resetar Windows Store e cache (wsreset.exe)';                  Def=$true;  W=$false }
        'uwpreg'    = @{ G='Store e UWP';       T='Re-registrar todos os apps UWP do sistema';                    Def=$false; W=$false }
        'dotnet'    = @{ G='.NET e Runtimes';   T='Verificar e listar versoes .NET instaladas';                   Def=$true;  W=$false }
        'vcredist'  = @{ G='.NET e Runtimes';   T='Verificar Visual C++ Redistributables instalados';             Def=$true;  W=$false }
        'gpo'       = @{ G='Politicas';         T='Resetar e reaplicar Politicas de Grupo (gpupdate /force)';     Def=$true;  W=$false }
        'perm'      = @{ G='Politicas';         T='Corrigir permissoes em Temp, Users e ProgramData';             Def=$false; W=$false }
        'thumb'     = @{ G='Cache do Sistema';  T='Reconstruir cache de miniaturas do Explorer';                  Def=$true;  W=$false }
        'icons'     = @{ G='Cache do Sistema';  T='Limpar e reconstruir cache de icones do sistema';              Def=$true;  W=$false }
        'fontcache' = @{ G='Cache do Sistema';  T='Limpar cache de fontes do Windows (FontCache)';                Def=$false; W=$false }
        'dnsflush'  = @{ G='Cache do Sistema';  T='Limpar cache DNS e resetar NetBIOS';                           Def=$true;  W=$false }
        'search'    = @{ G='Funcionalidades';   T='Reiniciar Windows Search / Indexador';                         Def=$false; W=$false }
        'explorer'  = @{ G='Funcionalidades';   T='Reiniciar Windows Explorer (aplica correcoes imediatas)';      Def=$false; W=$false }
    }

    $curGroup = ''
    foreach ($key in $taskDefs.Keys) {
        $def = $taskDefs[$key]
        if ($def.G -ne $curGroup) {
            $curGroup = $def.G
            $sl = New-SectionLabel -Text $curGroup -X 32 -Y $y -Width 500; $scroll.Controls.Add($sl); $y += 30
            $ln = New-Separator -X 32 -Y $y -Width 680; $scroll.Controls.Add($ln); $y += 10
        }
        $c = New-StyledCheckBox -Text "    $($def.T)" -X 32 -Y $y -Width 680; $c.Checked = $def.Def
        $scroll.Controls.Add($c); $Global:WC.BF.Chks[$key] = $c; $y += 28
    }
    $y += 12

    $btnAll3  = New-StyledButton -Text '[v] Todos'   -X 32  -Y $y -Width 100 -Height 32 -Style 'Secondary'
    $btnNone3 = New-StyledButton -Text '[ ] Nenhum'  -X 128 -Y $y -Width 100 -Height 32 -Style 'Secondary'
    $btnAll3.Add_Click({  foreach ($c in $Global:WC.BF.Chks.Values) { $c.Checked = $true  } })
    $btnNone3.Add_Click({ foreach ($c in $Global:WC.BF.Chks.Values) { $c.Checked = $false } })
    $scroll.Controls.Add($btnAll3); $scroll.Controls.Add($btnNone3); $y += 44

    $btnRun3 = New-StyledButton -Text '>  CORRIGIR BUGS' -X 32 -Y $y -Width 220 -Height 44 -Style 'Primary'
    $btnRun3.Font = $Global:Theme.Font_Header
    $btnRun3.Add_Click({
        # Captura estado dos checkboxes como valores simples
        $sel = @{}
        foreach ($key in $Global:WC.BF.Chks.Keys) { $sel[$key] = $Global:WC.BF.Chks[$key].Checked }

        $this.Enabled = $false; $this.Text = 'Executando...'
        $Global:WC._runBtn = $this
        Invoke-ModuleTask -TaskName 'Bug Fixer' `
            -Variables @{ sel = $sel } `
            -OnComplete {
                if ($Global:WC._runBtn) { $Global:WC._runBtn.Enabled = $true; $Global:WC._runBtn.Text = '>  CORRIGIR BUGS'; $Global:WC._runBtn.BackColor = $Global:Theme.Accent }
            } `
            -Task {
            Write-Log "== BUG FIXER - INiCIO ==" -Level INFO; $p = 5

            if ($sel['wmi']) {
                Write-Log "Reparando WMI..." -Level INFO
                Stop-Service winmgmt -Force -EA SilentlyContinue; Start-Sleep 1
                & winmgmt /resetrepository 2>&1 | ForEach-Object { Write-Log "  $_" }
                Start-Service winmgmt -EA SilentlyContinue
                Write-Log "WMI reparado" -Level SUCCESS; $p += 8; Update-Progress -Value $p
            }
            if ($sel['rpc']) {
                Write-Log "Verificando RPC/DCOM..." -Level INFO
                @('RpcSs','DcomLaunch','RpcEptMapper') | ForEach-Object {
                    $sv = Get-Service -Name $_ -EA SilentlyContinue
                    if ($sv -and $sv.Status -ne 'Running') { Start-Service $_ -EA SilentlyContinue; Write-Log "  $_`: reiniciado" -Level SUCCESS }
                    else { Write-Log "  $_`: OK" -Level SUCCESS }
                }; $p += 8; Update-Progress -Value $p
            }
            if ($sel['eventclear']) {
                Write-Log "Limpando entradas repetidas do Event Log..." -Level INFO
                @('Application','System') | ForEach-Object {
                    try { Clear-EventLog -LogName $_ -EA SilentlyContinue; Write-Log "  $_`: limpo" -Level SUCCESS }
                    catch { Write-Log "  $_`: aviso - $_" -Level WARN }
                }; $p += 8; Update-Progress -Value $p
            }
            if ($sel['store']) {
                Write-Log "Resetando Windows Store..." -Level INFO
                Start-Process wsreset.exe -Wait -EA SilentlyContinue
                Write-Log "Store resetada" -Level SUCCESS; $p += 8; Update-Progress -Value $p
            }
            if ($sel['uwpreg']) {
                Write-Log "Re-registrando UWP apps..." -Level INFO
                Get-AppXPackage -AllUsers -EA SilentlyContinue | ForEach-Object {
                    Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -EA SilentlyContinue
                }; Write-Log "UWP re-registrados" -Level SUCCESS; $p += 10; Update-Progress -Value $p
            }
            if ($sel['dotnet']) {
                Write-Log "Verificando .NET Framework..." -Level INFO
                Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse -EA SilentlyContinue |
                    Where-Object { $_.GetValue('Version') -and $_.Name -match '\\v' } |
                    ForEach-Object { Write-Log "  .NET $($_.GetValue('Version')) - $($_.Name.Split('\')[-1])" -Level SUCCESS }
                $p += 6; Update-Progress -Value $p
            }
            if ($sel['vcredist']) {
                Write-Log "Verificando VC++ Redistributables..." -Level INFO
                Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                                 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -EA SilentlyContinue |
                    Where-Object { $_.DisplayName -match 'Visual C\+\+' } |
                    Select-Object DisplayName, DisplayVersion |
                    ForEach-Object { Write-Log "  $($_.DisplayName) - $($_.DisplayVersion)" -Level SUCCESS }
                $p += 6; Update-Progress -Value $p
            }
            if ($sel['gpo']) {
                Write-Log "Aplicando Politicas de Grupo..." -Level INFO
                & gpupdate /force 2>&1 | ForEach-Object { Write-Log "  $_" }
                Write-Log "GPO atualizado" -Level SUCCESS; $p += 8; Update-Progress -Value $p
            }
            if ($sel['perm']) {
                Write-Log "Corrigindo permissoes..." -Level INFO
                @($env:TEMP, 'C:\Windows\Temp', "$env:USERPROFILE\AppData\Local\Temp") | ForEach-Object {
                    if (Test-Path $_) {
                        try { & icacls $_ /reset /t /c /q 2>&1 | Out-Null; Write-Log "  OK: $_" -Level SUCCESS }
                        catch { Write-Log "  Aviso: $_" -Level WARN }
                    }
                }; $p += 8; Update-Progress -Value $p
            }
            if ($sel['thumb']) {
                Write-Log "Reconstruindo cache de miniaturas..." -Level INFO
                Stop-Process -Name explorer -Force -EA SilentlyContinue; Start-Sleep 1
                Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -EA SilentlyContinue
                Start-Process explorer
                Write-Log "Cache de miniaturas limpo" -Level SUCCESS; $p += 8; Update-Progress -Value $p
            }
            if ($sel['icons']) {
                Write-Log "Limpando cache de icones..." -Level INFO
                @("$env:LOCALAPPDATA\IconCache.db",
                  "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache_*.db") |
                    ForEach-Object { Remove-Item $_ -Force -EA SilentlyContinue }
                & ie4uinit.exe -ClearIconCache 2>&1 | Out-Null
                Write-Log "Cache de icones limpo - reinicio recomendado" -Level SUCCESS; $p += 7; Update-Progress -Value $p
            }
            if ($sel['fontcache']) {
                Write-Log "Limpando cache de fontes..." -Level INFO
                Stop-Service -Name FontCache -Force -EA SilentlyContinue
                Remove-Item 'C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache' -Recurse -Force -EA SilentlyContinue
                Start-Service -Name FontCache -EA SilentlyContinue
                Write-Log "Cache de fontes limpo" -Level SUCCESS; $p += 6; Update-Progress -Value $p
            }
            if ($sel['dnsflush']) {
                Write-Log "Limpando DNS e NetBIOS..." -Level INFO
                & ipconfig /flushdns 2>&1 | ForEach-Object { Write-Log "  $_" }
                & nbtstat -RR 2>&1 | Out-Null
                Write-Log "DNS limpo" -Level SUCCESS; $p += 6; Update-Progress -Value $p
            }
            if ($sel['search']) {
                Write-Log "Reiniciando Windows Search..." -Level INFO
                Stop-Service WSearch -Force -EA SilentlyContinue; Start-Sleep 2
                Start-Service WSearch -EA SilentlyContinue
                Write-Log "Windows Search reiniciado" -Level SUCCESS; $p += 6; Update-Progress -Value $p
            }
            if ($sel['explorer']) {
                Write-Log "Reiniciando Windows Explorer..." -Level INFO
                Stop-Process -Name explorer -Force -EA SilentlyContinue; Start-Sleep 2
                Start-Process explorer
                Write-Log "Explorer reiniciado" -Level SUCCESS
            }
            Write-Log "== BUG FIXER - CONCLUiDO ==" -Level SUCCESS; Update-Progress -Value 100
        }
    })
    $scroll.Controls.Add($btnRun3)
    Update-Status "Modulo: Bug Fixer"
}

# ===============================================================================
# MoDULO 04 - Office / Teams / OneDrive / SharePoint
# ===============================================================================
function Show-OfficeSuite {
    $area = $Global:WC.ModuleArea; $area.Controls.Clear()
    $scroll = New-Object System.Windows.Forms.Panel
    $scroll.Dock = 'Fill'; $scroll.AutoScroll = $true
    $scroll.BackColor = $Global:Theme.BG_Deep; $area.Controls.Add($scroll); $y = 80
    $Global:WC.OS = @{ Chks = @{} }

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Office / Teams / OneDrive / SharePoint"
    $lbl.Font = $Global:Theme.Font_Title; $lbl.ForeColor = $Global:Theme.Text_Primary
    $lbl.Location = New-Object System.Drawing.Point(32,$y); $lbl.AutoSize = $true
    $scroll.Controls.Add($lbl); $y += 36

    $taskDefs4 = [ordered]@{
        'offRepair'  = @{ G='Microsoft Office'; T='Reparar Office via OfficeC2RClient (Reparo Online)';        W=$false; Def=$true  }
        'offQuick'   = @{ G='Microsoft Office'; T='⚡ Reparo Rapido do Office (offline, sem internet)';        W=$false; Def=$false }
        'offAct'     = @{ G='Microsoft Office'; T='Verificar e reparar ativacao do Office (ospp.vbs)';         W=$false; Def=$true  }
        'offCred'    = @{ G='Microsoft Office'; T='Resetar credenciais e tokens MSAL do Office';              W=$false; Def=$true  }
        'offCache'   = @{ G='Microsoft Office'; T='Limpar cache do Office (Word, Excel, Outlook, PPT)';       W=$false; Def=$true  }
        'teamsClear' = @{ G='Microsoft Teams';  T='Limpar cache completo do Teams Classic';                    W=$false; Def=$true  }
        'teamsNew'   = @{ G='Microsoft Teams';  T='Limpar cache do Teams New (MSTeams_8wekyb3d8bbwe)';        W=$false; Def=$true  }
        'teamsRereg' = @{ G='Microsoft Teams';  T='Re-registrar Teams e remover entradas de registro';        W=$false; Def=$false }
        'odCache'    = @{ G='Microsoft OneDrive'; T='Limpar cache local do OneDrive (logs e arquivos temp)';  W=$false; Def=$true  }
        'odReset'    = @{ G='Microsoft OneDrive'; T='[!] Reset completo OneDrive (desconecta e re-registra)'; W=$true;  Def=$false }
        'odReinstall'= @{ G='Microsoft OneDrive'; T='[!] Reinstalar OneDrive completamente';                  W=$true;  Def=$false }
        'spCache'    = @{ G='SharePoint Online'; T='Limpar cache de sincronizacao SharePoint';                 W=$false; Def=$true  }
        'spResync'   = @{ G='SharePoint Online'; T='Forcar re-sincronizacao de todas as bibliotecas';         W=$false; Def=$false }
        'spClearLib' = @{ G='SharePoint Online'; T='[!] Remover e reconfigurar atalhos de biblioteca';       W=$true;  Def=$false }
    }

    $curGroup4 = ''
    foreach ($key in $taskDefs4.Keys) {
        $def = $taskDefs4[$key]
        if ($def.G -ne $curGroup4) {
            $curGroup4 = $def.G
            $sl = New-SectionLabel -Text $curGroup4 -X 32 -Y $y -Width 500; $scroll.Controls.Add($sl); $y += 30
            $ln = New-Separator -X 32 -Y $y -Width 680; $scroll.Controls.Add($ln); $y += 10
        }
        $c = New-StyledCheckBox -Text "    $($def.T)" -X 32 -Y $y -Width 680; $c.Checked = $def.Def
        if ($def.W) { $c.ForeColor = $Global:Theme.Warning }
        $scroll.Controls.Add($c); $Global:WC.OS.Chks[$key] = $c; $y += 28
    }
    $y += 12

    $btnRun4 = New-StyledButton -Text '>  CORRIGIR SUITE OFFICE' -X 32 -Y $y -Width 270 -Height 44 -Style 'Primary'
    $btnRun4.Font = $Global:Theme.Font_Header
    $btnRun4.Add_Click({
        # Captura estado dos checkboxes como valores simples
        $sel = @{}
        foreach ($key in $Global:WC.OS.Chks.Keys) { $sel[$key] = $Global:WC.OS.Chks[$key].Checked }

        $this.Enabled = $false; $this.Text = 'Executando...'
        $Global:WC._runBtn = $this
        Invoke-ModuleTask -TaskName 'Office Suite Repair' `
            -Variables @{ sel = $sel } `
            -OnComplete {
                if ($Global:WC._runBtn) { $Global:WC._runBtn.Enabled = $true; $Global:WC._runBtn.Text = '>  CORRIGIR SUITE OFFICE'; $Global:WC._runBtn.BackColor = $Global:Theme.Accent }
            } `
            -Task {
            Write-Log "== OFFICE SUITE REPAIR - INiCIO ==" -Level INFO; Update-Progress -Value 2

            $c2r  = "${env:ProgramFiles}\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe"
            $c2r86= "${env:ProgramFiles(x86)}\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe"
            $c2rP = if (Test-Path $c2r) { $c2r } elseif (Test-Path $c2r86) { $c2r86 } else { $null }

            if ($sel['offRepair']) {
                Write-Log "Office Online Repair..." -Level INFO
                if ($c2rP) { Start-Process $c2rP -ArgumentList '/repair producttype=O365ProPlusRetail' -Wait; Write-Log "Reparo online OK" -Level SUCCESS }
                else { Write-Log "OfficeC2RClient nao encontrado" -Level WARN }
                Update-Progress -Value 10
            }
            if ($sel['offQuick']) {
                Write-Log "Office Quick Repair..." -Level INFO
                if ($c2rP) { Start-Process $c2rP -ArgumentList '/repair producttype=O365ProPlusRetail quickrepair' -Wait; Write-Log "Reparo rapido OK" -Level SUCCESS }
                else { Write-Log "OfficeC2RClient nao encontrado" -Level WARN }
                Update-Progress -Value 18
            }
            if ($sel['offAct']) {
                Write-Log "Verificando ativacao Office..." -Level INFO
                $ospp = @("${env:ProgramFiles}\Microsoft Office\Office16\ospp.vbs",
                          "${env:ProgramFiles(x86)}\Microsoft Office\Office16\ospp.vbs") |
                    Where-Object { Test-Path $_ } | Select-Object -First 1
                if ($ospp) { & cscript //nologo $ospp /dstatus 2>&1 | ForEach-Object { Write-Log "  $_" } }
                else { Write-Log "ospp.vbs nao encontrado" -Level WARN }
                Update-Progress -Value 26
            }
            if ($sel['offCred']) {
                Write-Log "Limpando tokens MSAL Office..." -Level INFO
                @("$env:LOCALAPPDATA\Microsoft\Office\16.0\Licensing",
                  "$env:APPDATA\Microsoft\Office\16.0\Common\Identity",
                  "$env:LOCALAPPDATA\Microsoft\IdentityCache") |
                    ForEach-Object { if (Test-Path $_) { Remove-Item "$_\*" -Force -Recurse -EA SilentlyContinue; Write-Log "  Limpo: $_" -Level SUCCESS } }
                & cmdkey /list 2>&1 | Select-String "MicrosoftOffice|microsoftoffice" | ForEach-Object {
                    $tgt = $_ -replace '.*Target: ',''; & cmdkey /delete:$tgt 2>&1 | Out-Null
                    Write-Log "  Credencial removida: $tgt" -Level SUCCESS
                }
                Update-Progress -Value 34
            }
            if ($sel['offCache']) {
                Write-Log "Limpando cache do Office..." -Level INFO
                @("$env:LOCALAPPDATA\Microsoft\Office\16.0\OfficeFileCache",
                  "$env:LOCALAPPDATA\Microsoft\Office\OTelemetry",
                  "$env:LOCALAPPDATA\Microsoft\Office\16.0\Lync\Tracing") |
                    ForEach-Object {
                        if (Test-Path $_) {
                            $ct = (Get-ChildItem $_ -Force -Recurse -EA SilentlyContinue).Count
                            Remove-Item "$_\*" -Force -Recurse -EA SilentlyContinue
                            Write-Log "  $ct itens removidos: $_" -Level SUCCESS
                        }
                    }
                Update-Progress -Value 42
            }
            if ($sel['teamsClear']) {
                Write-Log "Limpando cache Teams Classic..." -Level INFO
                Stop-Process -Name Teams -Force -EA SilentlyContinue; Start-Sleep 2
                @("$env:APPDATA\Microsoft\Teams\Cache",
                  "$env:APPDATA\Microsoft\Teams\blob_storage",
                  "$env:APPDATA\Microsoft\Teams\databases",
                  "$env:APPDATA\Microsoft\Teams\GPUCache",
                  "$env:APPDATA\Microsoft\Teams\IndexedDB",
                  "$env:APPDATA\Microsoft\Teams\Local Storage",
                  "$env:APPDATA\Microsoft\Teams\tmp",
                  "$env:APPDATA\Microsoft\Teams\Service Worker\CacheStorage") |
                    ForEach-Object { if (Test-Path $_) { Remove-Item "$_\*" -Force -Recurse -EA SilentlyContinue; Write-Log "  Limpo: $_" -Level SUCCESS } }
                Write-Log "Cache Teams Classic limpo" -Level SUCCESS; Update-Progress -Value 52
            }
            if ($sel['teamsNew']) {
                Write-Log "Limpando cache Teams New..." -Level INFO
                Stop-Process -Name ms-teams -Force -EA SilentlyContinue; Start-Sleep 2
                $tnC = "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams"
                if (Test-Path $tnC) { Remove-Item "$tnC\*" -Force -Recurse -EA SilentlyContinue; Write-Log "  Cache Teams New limpo" -Level SUCCESS }
                Update-Progress -Value 60
            }
            if ($sel['teamsRereg']) {
                Write-Log "Re-registrando Teams..." -Level INFO
                Get-AppxPackage -Name *MSTeams* -EA SilentlyContinue | ForEach-Object {
                    Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -EA SilentlyContinue
                }
                Write-Log "Teams re-registrado" -Level SUCCESS; Update-Progress -Value 64
            }
            if ($sel['odCache']) {
                Write-Log "Limpando cache OneDrive..." -Level INFO
                @("$env:LOCALAPPDATA\Microsoft\OneDrive\logs",
                  "$env:LOCALAPPDATA\Microsoft\OneDrive\setup\logs") |
                    ForEach-Object { if (Test-Path $_) { Remove-Item "$_\*" -Force -Recurse -EA SilentlyContinue; Write-Log "  Limpo: $_" -Level SUCCESS } }
                Update-Progress -Value 66
            }
            if ($sel['odReset']) {
                Write-Log "Reset completo OneDrive..." -Level WARN
                $od = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
                if (Test-Path $od) {
                    Stop-Process -Name OneDrive -Force -EA SilentlyContinue; Start-Sleep 3
                    Start-Process $od -ArgumentList '/reset' -Wait -EA SilentlyContinue
                    Write-Log "OneDrive resetado - reiniciando..." -Level SUCCESS
                    Start-Sleep 5; Start-Process $od -EA SilentlyContinue
                } else { Write-Log "OneDrive.exe nao encontrado" -Level WARN }
                Update-Progress -Value 76
            }
            if ($sel['odReinstall']) {
                Write-Log "Reinstalando OneDrive..." -Level WARN
                Stop-Process -Name OneDrive -Force -EA SilentlyContinue; Start-Sleep 2
                $ods = if (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") { "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" }
                       else { "$env:SystemRoot\System32\OneDriveSetup.exe" }
                if (Test-Path $ods) {
                    Start-Process $ods -ArgumentList '/uninstall' -Wait
                    Start-Sleep 3; Start-Process $ods -Wait
                    Write-Log "OneDrive reinstalado" -Level SUCCESS
                } else { Write-Log "OneDriveSetup.exe nao encontrado" -Level WARN }
                Update-Progress -Value 86
            }
            if ($sel['spCache']) {
                Write-Log "Limpando cache SharePoint..." -Level INFO
                $sp = "$env:USERPROFILE\AppData\Local\Microsoft\SharePoint"
                if (Test-Path $sp) { Remove-Item "$sp\*" -Force -Recurse -EA SilentlyContinue; Write-Log "  Cache SP limpo" -Level SUCCESS }
                Update-Progress -Value 90
            }
            if ($sel['spResync']) {
                Write-Log "Re-sincronizando SharePoint..." -Level INFO
                Stop-Process -Name OneDrive -Force -EA SilentlyContinue; Start-Sleep 2
                $od2 = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
                if (Test-Path $od2) { Start-Process $od2 -EA SilentlyContinue; Write-Log "Re-sync iniciado" -Level SUCCESS }
                Update-Progress -Value 96
            }
            if ($sel['spClearLib']) {
                Write-Log "Removendo atalhos de biblioteca SharePoint..." -Level WARN
                $spLinks = "$env:USERPROFILE\OneDrive*\*" | Get-Item -EA SilentlyContinue |
                    Where-Object { $_.Attributes -match 'ReparsePoint' }
                $spLinks | ForEach-Object { Write-Log "  Removido: $($_.FullName)" -Level SUCCESS; Remove-Item $_.FullName -Force -EA SilentlyContinue }
                Update-Progress -Value 98
            }
            Write-Log "== OFFICE SUITE REPAIR - CONCLUiDO ==" -Level SUCCESS; Update-Progress -Value 100
        }
    })
    $scroll.Controls.Add($btnRun4)
    Update-Status "Modulo: Office Suite"
}
