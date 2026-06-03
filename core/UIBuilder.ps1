<#
.SYNOPSIS
    Construtor da interface gráfica WinForms - WinCare Pro
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

function Start-WinCareUI {

    # ── Janela principal ───────────────────────────────────────────────────────
    $form = New-Object System.Windows.Forms.Form
    $form.Text            = "$($Global:WC.AppName) v$($Global:WC.Version)"
    $form.Size            = New-Object System.Drawing.Size(1200, 750)
    $form.MinimumSize     = New-Object System.Drawing.Size(920, 600)
    $form.StartPosition   = 'CenterScreen'
    $form.WindowState     = 'Maximized'
    $form.BackColor       = $Global:Theme.BG_Deep
    $form.ForeColor       = $Global:Theme.Text_Primary
    $form.Font            = $Global:Theme.Font_Body
    $form.FormBorderStyle = 'Sizable'

    # Tenta carregar ícone
    $icoPath = Join-Path $Global:WC.RootPath 'WinCare.ico'
    if (Test-Path $icoPath) { $form.Icon = New-Object System.Drawing.Icon($icoPath) }

    # ── Header ─────────────────────────────────────────────────────────────────
    $header = New-Object System.Windows.Forms.Panel
    $header.Dock      = 'Top'
    $header.Height    = $Global:Theme.HeaderHeight
    $header.BackColor = $Global:Theme.BG_Panel
    $form.Controls.Add($header)

    $btnMenu = New-Object System.Windows.Forms.Button
    $btnMenu.Text      = [char]9776
    $btnMenu.Font      = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
    $btnMenu.ForeColor = $Global:Theme.Text_Primary
    $btnMenu.BackColor = $Global:Theme.BG_Panel
    $btnMenu.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnMenu.FlatAppearance.BorderSize = 0
    $btnMenu.Size      = New-Object System.Drawing.Size(46, 46)
    $btnMenu.Location  = New-Object System.Drawing.Point(5, 5)
    $btnMenu.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $header.Controls.Add($btnMenu)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text      = "WinCare Pro"
    $lblTitle.Font      = $Global:Theme.Font_Title
    $lblTitle.ForeColor = $Global:Theme.Text_Primary
    $lblTitle.AutoSize  = $true
    $header.Controls.Add($lblTitle)

    $lblUser = New-Object System.Windows.Forms.Label
    $lblUser.Text      = "$env:USERNAME  |  $env:COMPUTERNAME  |  Admin"
    $lblUser.Font      = $Global:Theme.Font_Small
    $lblUser.ForeColor = $Global:Theme.Text_Muted
    $lblUser.AutoSize  = $true
    $lblUser.Anchor    = 'Top,Right'
    $header.Controls.Add($lblUser)

    # Posiciona lblUser dinamicamente e centraliza o titulo
    $header.Add_Resize({
        $lblUser.Location = New-Object System.Drawing.Point(
            ($header.Width - $lblUser.Width - 16), 20)
        
        $newX = [Math]::Max(0, [int][Math]::Floor(($header.Width - $lblTitle.Width) / 2))
        $newY = [Math]::Max(0, [int][Math]::Floor(($header.Height - $lblTitle.Height) / 2))
        $lblTitle.Location = New-Object System.Drawing.Point($newX, $newY)
    })

    # ── Footer ─────────────────────────────────────────────────────────────────
    $footer = New-Object System.Windows.Forms.Panel
    $footer.Dock      = 'Bottom'
    $footer.Height    = 0
    $footer.BackColor = $Global:Theme.BG_Panel
    $form.Controls.Add($footer)
    $Global:WC.FooterPanel = $footer

    $Global:WC.TargetFooterHeight = 0
    $footerTimer = New-Object System.Windows.Forms.Timer
    $footerTimer.Interval = 10
    $footerTimer.Add_Tick({
        if ($Global:WC.FooterPanel.Height -eq $Global:WC.TargetFooterHeight) {
            $Global:WC.FooterTimer.Stop()
            return
        }
        $step = 4
        if ($Global:WC.FooterPanel.Height -lt $Global:WC.TargetFooterHeight) {
            $Global:WC.FooterPanel.Height = [Math]::Min($Global:WC.FooterPanel.Height + $step, $Global:WC.TargetFooterHeight)
        } else {
            $Global:WC.FooterPanel.Height = [Math]::Max($Global:WC.FooterPanel.Height - $step, $Global:WC.TargetFooterHeight)
        }
    }.GetNewClosure())
    $Global:WC.FooterTimer = $footerTimer

    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Text      = "Pronto"
    $lblStatus.Font      = $Global:Theme.Font_Small
    $lblStatus.ForeColor = $Global:Theme.Text_Muted
    $lblStatus.Location  = New-Object System.Drawing.Point(16, 6)
    $lblStatus.AutoSize  = $true
    $footer.Controls.Add($lblStatus)
    $Global:WC.StatusLabel = $lblStatus

    $lblVersion = New-Object System.Windows.Forms.Label
    $lblVersion.Text      = "v$($Global:WC.Version)  |  PS $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
    $lblVersion.Font      = $Global:Theme.Font_Small
    $lblVersion.ForeColor = $Global:Theme.Text_Muted
    $lblVersion.AutoSize  = $true
    $lblVersion.Anchor    = 'Top,Right'
    $footer.Controls.Add($lblVersion)

    # Barra de progresso no footer
    $footerPb = New-Object System.Windows.Forms.ProgressBar
    $footerPb.Style    = 'Continuous'
    $footerPb.Minimum  = 0
    $footerPb.Maximum  = 100
    $footerPb.Value    = 0
    $footerPb.Height   = 8
    $footerPb.Location = New-Object System.Drawing.Point(16, 30)
    $footerPb.BackColor = $Global:Theme.BG_Deep
    $footerPb.ForeColor = $Global:Theme.Accent
    $footer.Controls.Add($footerPb)
    $Global:WC.ProgressBar = $footerPb

    $footerPct = New-Object System.Windows.Forms.Label
    $footerPct.Text      = "0%"
    $footerPct.Font      = $Global:Theme.Font_Small
    $footerPct.ForeColor = $Global:Theme.Text_Muted
    $footerPct.AutoSize  = $true
    $footer.Controls.Add($footerPct)
    $Global:WC.ProgressLabel = $footerPct

    $footer.Add_Resize({
        $lblVersion.Location = New-Object System.Drawing.Point(
            ($footer.Width - $lblVersion.Width - 16), 6)
        $footerPct.Location = New-Object System.Drawing.Point(
            ($footer.Width - $footerPct.Width - 16), 30)
        $footerPb.Width = $footer.Width - $footerPct.Width - 40
    })

    # ── Split Container (Nav | Conteúdo) ───────────────────────────────────────
    $split = New-Object System.Windows.Forms.SplitContainer
    $split.Dock             = 'Fill'
    $split.SplitterWidth    = 2
    $split.SplitterDistance = $Global:Theme.NavWidth
    $split.IsSplitterFixed  = $true
    $split.FixedPanel       = [System.Windows.Forms.FixedPanel]::Panel1
    $split.Panel1MinSize    = $Global:Theme.NavWidth
    $split.BackColor        = $Global:Theme.Border
    $split.Panel1Collapsed  = $true
    $form.Controls.Add($split)

    $btnMenu.Add_Click({
        $split.Panel1Collapsed = -not $split.Panel1Collapsed
    }.GetNewClosure())

    # ── Painel de Navegação (esquerda) ─────────────────────────────────────────
    $navPanel = $split.Panel1
    $navPanel.BackColor = $Global:Theme.BG_Panel

    # Logo/badge no topo da nav
    $navBadge = New-Object System.Windows.Forms.Panel
    $navBadge.Size      = New-Object System.Drawing.Size($Global:Theme.NavWidth, 50)
    $navBadge.Location  = New-Object System.Drawing.Point(0, 0)
    $navBadge.BackColor = $Global:Theme.BG_Deep
    $navPanel.Controls.Add($navBadge)

    $lblNavTitle = New-Object System.Windows.Forms.Label
    $lblNavTitle.Text      = "MODULOS"
    $lblNavTitle.Font      = $Global:Theme.Font_Badge
    $lblNavTitle.ForeColor = $Global:Theme.Text_Muted
    $lblNavTitle.Location  = New-Object System.Drawing.Point(16, 18)
    $lblNavTitle.AutoSize  = $true
    $navBadge.Controls.Add($lblNavTitle)

    # Itens de navegação
    $navItems = @(
        @{ Label='Dashboard';           Module='Dashboard'          },
        @{ Label='Manutencao Windows';  Module='WindowsMaintenance' },
        @{ Label='Windows Update';      Module='WindowsUpdate'      },
        @{ Label='Correcao de Bugs';    Module='BugFixer'           },
        @{ Label='Office / Teams';      Module='OfficeSuite'        },
        @{ Label='Registro';            Module='RegistryRepair'     },
        @{ Label='Bloatware';           Module='AppRemover'         },
        @{ Label='Saude da Maquina';    Module='HealthCheck'        },
        @{ Label='Testes';              Module='ComponentTest'      },
        @{ Label='Winget Apps';         Module='WingetManager'      },
        @{ Label='Configuracoes';       Module='Settings'           }
    )

    $Global:WC.NavButtons   = @()
    $Global:WC.ActiveModule = 'Dashboard'

    $yPos = 55
    foreach ($item in $navItems) {
        $btn = New-Object System.Windows.Forms.Button
        $btn.Text      = "  $($item.Label)"
        $btn.TextAlign = 'MiddleLeft'
        $btn.Location  = New-Object System.Drawing.Point(0, $yPos)
        $btn.Size      = New-Object System.Drawing.Size($Global:Theme.NavWidth, 42)
        $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btn.FlatAppearance.BorderSize  = 0
        $btn.FlatAppearance.BorderColor = $Global:Theme.BG_Panel
        $btn.Font      = $Global:Theme.Font_Nav
        $btn.ForeColor = $Global:Theme.Text_Muted
        $btn.BackColor = $Global:Theme.BG_Panel
        $btn.Cursor    = [System.Windows.Forms.Cursors]::Hand
        $btn.Tag       = $item.Module
        $btn.AutoEllipsis = $true

        $btn.Add_Click({
            param($s, $e)
            Set-ActiveModule -ModuleName $s.Tag
        })
        $btn.Add_MouseEnter({
            if ($this.Tag -ne $Global:WC.ActiveModule) {
                $this.BackColor = $Global:Theme.BG_Hover
                $this.ForeColor = $Global:Theme.Text_Primary
            }
        })
        $btn.Add_MouseLeave({
            if ($this.Tag -ne $Global:WC.ActiveModule) {
                $this.BackColor = $Global:Theme.BG_Panel
                $this.ForeColor = $Global:Theme.Text_Muted
            }
        })

        $navPanel.Controls.Add($btn)
        $Global:WC.NavButtons += $btn
        $yPos += 42
    }

    # Separador no fim da nav
    $navSep = New-Object System.Windows.Forms.Panel
    $navSep.Location  = New-Object System.Drawing.Point(0, $yPos)
    $navSep.Size      = New-Object System.Drawing.Size($Global:Theme.NavWidth, 1)
    $navSep.BackColor = $Global:Theme.Separator
    $navPanel.Controls.Add($navSep)

    # Botão Abrir Log
    $btnLog = New-Object System.Windows.Forms.Button
    $btnLog.Text      = "  Ver Logs"
    $btnLog.TextAlign = 'MiddleLeft'
    $btnLog.Location  = New-Object System.Drawing.Point(0, ($yPos + 8))
    $btnLog.Size      = New-Object System.Drawing.Size($Global:Theme.NavWidth, 36)
    $btnLog.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnLog.FlatAppearance.BorderSize = 0
    $btnLog.Font      = $Global:Theme.Font_Small
    $btnLog.ForeColor = $Global:Theme.Text_Muted
    $btnLog.BackColor = $Global:Theme.BG_Panel
    $btnLog.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btnLog.Add_Click({ Show-LogViewer })
    $navPanel.Controls.Add($btnLog)

    # ── Painel de Conteúdo (direita) ──────────────────────────────────────────
    $contentPanel = $split.Panel2
    $contentPanel.BackColor = $Global:Theme.BG_Deep
    $Global:WC.ContentPanel = $contentPanel

    # ── Split interno: módulo (esquerda) | console (direita) ─────────────────
    $innerSplit = New-Object System.Windows.Forms.SplitContainer
    $innerSplit.Dock             = 'Fill'
    $innerSplit.SplitterWidth    = 2
    $innerSplit.FixedPanel       = [System.Windows.Forms.FixedPanel]::Panel2
    $innerSplit.BackColor        = $Global:Theme.Border
    $contentPanel.Controls.Add($innerSplit)

    $form.Add_Load({
        try {
            $innerSplit.Panel2MinSize = 200
            $innerSplit.SplitterDistance = [Math]::Max(100, $innerSplit.Width - 200)
        } catch {}
    })

    $innerSplit.Add_SplitterMoved({
        $Global:WC.ModuleArea.Controls | ForEach-Object {
            if ($_ -is [System.Windows.Forms.Panel] -and $_.AutoScroll) {
                $_.Width = $Global:WC.ModuleArea.ClientSize.Width
            }
        }
    })

    # Área de módulo (painel esquerdo)
    $moduleArea = $innerSplit.Panel1
    $moduleArea.BackColor = $Global:Theme.BG_Deep
    $Global:WC.ModuleArea = $moduleArea

    # Painel do console (painel direito)
    $consoleHost = $innerSplit.Panel2
    $consoleHost.BackColor = $Global:Theme.BG_Panel
    $Global:WC.ProgressHost = $consoleHost

    Initialize-ProgressPanel -ParentPanel $consoleHost

    # ── Carrega dashboard inicial ──────────────────────────────────────────────
    Set-ActiveModule -ModuleName 'Dashboard'

    Write-Log "Interface iniciada" -Level SUCCESS

    [System.Windows.Forms.Application]::Run($form)
}

function Set-ActiveModule {
    param([string]$ModuleName)

    $Global:WC.ActiveModule = $ModuleName

    # Atualiza visual dos botões nav
    foreach ($btn in $Global:WC.NavButtons) {
        if ($btn.Tag -eq $ModuleName) {
            $btn.BackColor = $Global:Theme.BG_Active
            $btn.ForeColor = $Global:Theme.Text_Primary
            $btn.Font      = $Global:Theme.Font_NavSel
        } else {
            $btn.BackColor = $Global:Theme.BG_Panel
            $btn.ForeColor = $Global:Theme.Text_Muted
            $btn.Font      = $Global:Theme.Font_Nav
        }
    }

    # Limpa área de módulo
    $Global:WC.ModuleArea.Controls.Clear()

    # Carrega o módulo correspondente
    switch ($ModuleName) {
        'Dashboard'          { Show-Dashboard          }
        'WindowsMaintenance' { Show-WindowsMaintenance }
        'WindowsUpdate'      { Show-WindowsUpdate      }
        'BugFixer'           { Show-BugFixer           }
        'OfficeSuite'        { Show-OfficeSuite        }
        'RegistryRepair'     { Show-RegistryRepair     }
        'AppRemover'         { Show-AppRemover         }
        'HealthCheck'        { Show-HealthCheck        }
        'ComponentTest'      { Show-ComponentTest      }
        'WingetManager'      { Show-WingetManager      }
        'Settings'           { Show-Settings           }
        default {
            $lbl = New-Object System.Windows.Forms.Label
            $lbl.Text      = "Modulo em desenvolvimento..."
            $lbl.ForeColor = $Global:Theme.Text_Muted
            $lbl.Font      = $Global:Theme.Font_Header
            $lbl.Dock      = 'Fill'
            $lbl.TextAlign = 'MiddleCenter'
            $Global:WC.ModuleArea.Controls.Add($lbl)
        }
    }

    Update-Status "Modulo: $ModuleName"
}

function Update-Status {
    param([string]$Message)
    if ($Global:WC.StatusLabel) {
        $Global:WC.StatusLabel.Text = $Message
    }
}

function Show-Footer {
    if ($Global:WC.FooterTimer) {
        $Global:WC.TargetFooterHeight = $Global:Theme.FooterHeight
        if (-not $Global:WC.FooterTimer.Enabled) { $Global:WC.FooterTimer.Start() }
    }
}

function Hide-Footer {
    if ($Global:WC.FooterTimer) {
        $Global:WC.TargetFooterHeight = 0
        if (-not $Global:WC.FooterTimer.Enabled) { $Global:WC.FooterTimer.Start() }
    }
}
