<#
.SYNOPSIS
    Painel de progresso e log em tempo real - WinCare Pro
#>

function Initialize-ProgressPanel {
    param([System.Windows.Forms.Panel]$ParentPanel)

    # Separador topo
    $sep = New-Object System.Windows.Forms.Panel
    $sep.Dock      = 'Top'
    $sep.Height    = 1
    $sep.BackColor = $Global:Theme.Border
    $ParentPanel.Controls.Add($sep)

    # Header do painel
    $headerBar = New-Object System.Windows.Forms.Panel
    $headerBar.Dock      = 'Top'
    $headerBar.Height    = 28
    $headerBar.BackColor = $Global:Theme.BG_Card
    $ParentPanel.Controls.Add($headerBar)

    $lblLogTitle = New-Object System.Windows.Forms.Label
    $lblLogTitle.Text      = "  LOG DE OPERACOES"
    $lblLogTitle.Font      = $Global:Theme.Font_Badge
    $lblLogTitle.ForeColor = $Global:Theme.Text_Muted
    $lblLogTitle.Location  = New-Object System.Drawing.Point(0, 7)
    $lblLogTitle.AutoSize  = $true
    $headerBar.Controls.Add($lblLogTitle)

    # Botão limpar log
    $btnClear = New-Object System.Windows.Forms.Button
    $btnClear.Text      = "Limpar"
    $btnClear.Font      = $Global:Theme.Font_Small
    $btnClear.ForeColor = $Global:Theme.Text_Muted
    $btnClear.BackColor = $Global:Theme.BG_Card
    $btnClear.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnClear.FlatAppearance.BorderSize = 0
    $btnClear.Size      = New-Object System.Drawing.Size(55, 22)
    $btnClear.Anchor    = 'Top,Right'
    $btnClear.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btnClear.Add_Click({ if ($Global:WC.LogTextBox) { $Global:WC.LogTextBox.Clear() } })
    $headerBar.Controls.Add($btnClear)
    $headerBar.Add_Resize({
        $btnClear.Location = New-Object System.Drawing.Point(
            ($headerBar.Width - $btnClear.Width - 8), 3)
    }.GetNewClosure())

    # Área de log (Container com margem)
    $logContainer = New-Object System.Windows.Forms.Panel
    $logContainer.Dock = 'Fill'
    $logContainer.Padding = New-Object System.Windows.Forms.Padding(16, 80, 16, 16)
    $logContainer.BackColor = $Global:Theme.BG_Deep
    $ParentPanel.Controls.Add($logContainer)

    # Área de log (TextBox)
    $logBox = New-Object System.Windows.Forms.RichTextBox
    $logBox.Dock      = 'Fill'
    $logBox.ReadOnly  = $true
    $logBox.BackColor = $Global:Theme.BG_Deep
    $logBox.ForeColor = $Global:Theme.Success
    $logBox.Font      = $Global:Theme.Font_Mono
    $logBox.BorderStyle = 'None'
    $logBox.ScrollBars  = 'Vertical'
    $logBox.WordWrap    = $true
    $logContainer.Controls.Add($logBox)
    $Global:WC.LogTextBox = $logBox
}

function Update-Progress {
    param(
        [int]$Value,
        [string]$Message = ''
    )
    if ($Global:WC.ProgressBar -and $Global:WC.ProgressBar.IsHandleCreated) {
        $Global:WC.ProgressBar.Invoke([Action]{
            $Global:WC.ProgressBar.Value = [Math]::Min($Value, 100)
        })
    }
    if ($Global:WC.ProgressLabel -and $Global:WC.ProgressLabel.IsHandleCreated) {
        $pct = [Math]::Min($Value, 100)
        $Global:WC.ProgressLabel.Invoke([Action]{
            $Global:WC.ProgressLabel.Text = "$pct%"
        })
    }
    if ($Message) { Write-Log $Message -Level INFO }
}

function Reset-Progress {
    Update-Progress -Value 0
    if ($Global:WC.LogTextBox -and $Global:WC.LogTextBox.IsHandleCreated) {
        $Global:WC.LogTextBox.Invoke([Action]{ $Global:WC.LogTextBox.Clear() })
    }
}

function Invoke-ModuleTask {
    <#
    .SYNOPSIS
        Executa uma tarefa em background sem travar a UI.
        Aceita ScriptBlock, variáveis extras e callback de conclusão.
    .PARAMETER Variables
        Hashtable de variáveis que serão injetadas no runspace.
        Use para passar estado (seleções, flags) sem depender de closures.
    .PARAMETER OnComplete
        ScriptBlock executado na thread da UI ao concluir (ex.: re-habilitar botão).
    #>
    param(
        [ScriptBlock]$Task,
        [string]$TaskName = 'Operação',
        [hashtable]$Variables = @{},
        [ScriptBlock]$OnComplete = $null
    )

    Reset-Progress
    try { Show-Footer } catch {}
    Write-Log "Iniciando: $TaskName" -Level INFO

    # Cria Runspace isolado para não bloquear a UI
    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = 'STA'
    $rs.ThreadOptions  = 'ReuseThread'
    $rs.Open()

    # Compartilha variáveis globais necessárias
    $rs.SessionStateProxy.SetVariable('WC',    $Global:WC)
    $rs.SessionStateProxy.SetVariable('Theme', $Global:Theme)

    # Injeta variáveis customizadas do módulo chamador
    foreach ($vKey in $Variables.Keys) {
        $rs.SessionStateProxy.SetVariable($vKey, $Variables[$vKey])
    }

    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs

    # Injeta funções de log/progress no runspace
    $initBlock = {
        function Write-Log {
            param([string]$Message, [string]$Level = 'INFO')
            $timestamp = Get-Date -Format 'HH:mm:ss'
            $prefix = switch ($Level) {
                'INFO'    { '[INFO]' } 'WARN'    { '[AVISO]' }
                'ERROR'   { '[ERRO]' } 'SUCCESS' { '[OK]' }
                default   { '[INFO]' }
            }
            $line = "$timestamp $prefix $Message"
            if ($WC.CurrentLog) {
                try { Add-Content -Path $WC.CurrentLog -Value $line -Encoding UTF8 } catch { }
            }
            if ($WC.LogTextBox -and $WC.LogTextBox.IsHandleCreated) {
                try {
                    $WC.LogTextBox.Invoke([Action]{ $WC.LogTextBox.AppendText("$line`r`n`r`n"); $WC.LogTextBox.ScrollToCaret() })
                } catch { }
            }
        }
        function Update-Progress {
            param([int]$Value, [string]$Message = '')
            if ($WC.ProgressBar -and $WC.ProgressBar.IsHandleCreated) {
                try {
                    $WC.ProgressBar.Invoke([Action]{ $WC.ProgressBar.Value = [Math]::Min($Value,100) })
                } catch { }
            }
            if ($WC.ProgressLabel -and $WC.ProgressLabel.IsHandleCreated) {
                $pct = [Math]::Min($Value, 100)
                try {
                    $WC.ProgressLabel.Invoke([Action]{ $WC.ProgressLabel.Text = "$pct%" })
                } catch { }
            }
            if ($Message) { Write-Log $Message }
        }
    }

    $ps.AddScript($initBlock) | Out-Null
    $ps.AddScript($Task)       | Out-Null

    $handle = $ps.BeginInvoke()

    # Captura referências para o closure do timer
    $taskNameRef    = $TaskName
    $onCompleteRef  = $OnComplete
    $psRef          = $ps
    $rsRef          = $rs
    $handleRef      = $handle

    # Timer para verificar conclusão sem bloquear UI
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 300
    $timer.Add_Tick({
        if ($handleRef.IsCompleted) {
            $timer.Stop()
            try {
                $psRef.EndInvoke($handleRef)
                Write-Log "$taskNameRef concluído." -Level SUCCESS
                Update-Progress -Value 100
            } catch {
                Write-Log "Erro em $taskNameRef`: $_" -Level ERROR
            } finally {
                $psRef.Dispose()
                $rsRef.Close()
                $rsRef.Dispose()
            }
            # Callback de conclusão na thread da UI
            if ($onCompleteRef) {
                try { & $onCompleteRef } catch { }
            }

            if ($Global:WC.HideTimer) { try { $Global:WC.HideTimer.Dispose() } catch {} }
            $Global:WC.HideTimer = New-Object System.Windows.Forms.Timer
            $Global:WC.HideTimer.Interval = 2500
            $Global:WC.HideTimer.Add_Tick({
                $Global:WC.HideTimer.Stop()
                try { Hide-Footer } catch {}
            })
            $Global:WC.HideTimer.Start()
        }
    }.GetNewClosure())
    $timer.Start()
}
