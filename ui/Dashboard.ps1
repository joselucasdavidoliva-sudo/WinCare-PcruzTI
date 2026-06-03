<#
.SYNOPSIS
    Dashboard principal - WinCare Pro
#>

function Show-Dashboard {
    $area = $Global:WC.ModuleArea
    $area.Controls.Clear()

    # ScrollPanel
    $scroll = New-Object System.Windows.Forms.Panel
    $scroll.Dock       = 'Fill'
    $scroll.AutoScroll = $true
    $scroll.BackColor  = $Global:Theme.BG_Deep
    $area.Controls.Add($scroll)

    $cardH  = 62
    $gap    = 8
    $margin = 32

    # ── Título ─────────────────────────────────────────────────────────────────
    $lblWelcome = New-Object System.Windows.Forms.Label
    $lblWelcome.Text      = "Bem-vindo ao WinCare Pro"
    $lblWelcome.Font      = $Global:Theme.Font_Title
    $lblWelcome.ForeColor = $Global:Theme.Text_Primary
    $lblWelcome.Location  = New-Object System.Drawing.Point($margin, 80)
    $lblWelcome.AutoSize  = $true
    $scroll.Controls.Add($lblWelcome)

    $lblSub = New-Object System.Windows.Forms.Label
    $lblSub.Text      = "Suite completa de manutencao, diagnostico e otimizacao Windows"
    $lblSub.Font      = $Global:Theme.Font_Body
    $lblSub.ForeColor = $Global:Theme.Text_Muted
    $lblSub.Location  = New-Object System.Drawing.Point($margin, 122)
    $lblSub.AutoSize  = $true
    $scroll.Controls.Add($lblSub)

    # ── Cards de info do sistema ───────────────────────────────────────────────
    $cardData = @(
        @{ Label='Sistema Operacional'; Value=$(try{(Get-CimInstance Win32_OperatingSystem).Caption}catch{'N/A'});  Icon='OS' },
        @{ Label='Versao do Windows';   Value=$(try{(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion}catch{'N/A'}); Icon='VER' },
        @{ Label='Memoria RAM Total';   Value=$(try{"$([Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,1)) GB"}catch{'N/A'}); Icon='RAM' },
        @{ Label='Disco Principal (C:)';Value=$(try{"$([Math]::Round((Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").Size/1GB,0)) GB"}catch{'N/A'}); Icon='HDD' },
        @{ Label='Processador';         Value=$(try{(Get-CimInstance Win32_Processor | Select-Object -First 1).Name -replace '\s+',' '}catch{'N/A'}); Icon='CPU' },
        @{ Label='Uptime';              Value=$(try{$up=(Get-Date)-(Get-CimInstance Win32_OperatingSystem).LastBootUpTime;"$($up.Days)d $($up.Hours)h $($up.Minutes)m"}catch{'N/A'}); Icon='UP' }
    )

    $cardsY   = 158
    $cardPanels = @()

    foreach ($i in 0..($cardData.Count - 1)) {
        $card = New-Object System.Windows.Forms.Panel
        $card.BackColor = $Global:Theme.BG_Card
        $card.Size      = New-Object System.Drawing.Size(240, $cardH)
        $card.Location  = New-Object System.Drawing.Point(0, 0)  # set by Resize

        # Badge label (short text icon)
        $lblBadge = New-Object System.Windows.Forms.Label
        $lblBadge.Text      = $cardData[$i].Icon
        $lblBadge.Font      = New-Object System.Drawing.Font('Segoe UI', 7, [System.Drawing.FontStyle]::Bold)
        $lblBadge.ForeColor = $Global:Theme.Accent
        $lblBadge.BackColor = $Global:Theme.BG_Deep
        $lblBadge.Location  = New-Object System.Drawing.Point(10, 10)
        $lblBadge.Size      = New-Object System.Drawing.Size(28, 12)
        $lblBadge.TextAlign = 'MiddleCenter'
        $card.Controls.Add($lblBadge)

        $lblName = New-Object System.Windows.Forms.Label
        $lblName.Text      = $cardData[$i].Label
        $lblName.Font      = $Global:Theme.Font_Small
        $lblName.ForeColor = $Global:Theme.Text_Muted
        $lblName.Location  = New-Object System.Drawing.Point(44, 7)
        $lblName.Size      = New-Object System.Drawing.Size(190, 14)
        $card.Controls.Add($lblName)

        $lblVal = New-Object System.Windows.Forms.Label
        $lblVal.Text      = $cardData[$i].Value
        $lblVal.Font      = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
        $lblVal.ForeColor = $Global:Theme.Text_Primary
        $lblVal.Location  = New-Object System.Drawing.Point(44, 24)
        $lblVal.Size      = New-Object System.Drawing.Size(190, 32)
        $card.Controls.Add($lblVal)

        $scroll.Controls.Add($card)
        $cardPanels += $card
    }

    # ── Separador "Acesso Rapido" ──────────────────────────────────────────────
    $lblAccess = New-Object System.Windows.Forms.Label
    $lblAccess.Text      = "Acesso Rapido"
    $lblAccess.Font      = $Global:Theme.Font_Header
    $lblAccess.ForeColor = $Global:Theme.Accent
    $lblAccess.Location  = New-Object System.Drawing.Point($margin, 0)  # set by Resize
    $lblAccess.AutoSize  = $true
    $scroll.Controls.Add($lblAccess)

    # ── Botões de acesso rápido ────────────────────────────────────────────────
    $quickActions = @(
        @{ Label='Manutencao Completa'; Module='WindowsMaintenance'; Style='Primary'   },
        @{ Label='Verificar Updates';   Module='WindowsUpdate';      Style='Secondary' },
        @{ Label='Check de Saude';      Module='HealthCheck';        Style='Secondary' },
        @{ Label='Instalar Apps';       Module='WingetManager';      Style='Secondary' }
    )

    $qBtns = @()
    foreach ($qa in $quickActions) {
        $qBtn = New-StyledButton -Text $qa.Label -X 0 -Y 0 -Width 170 -Height 38 -Style $qa.Style
        $qBtn.Tag = $qa.Module
        $qBtn.Add_Click({
            param($s, $e)
            Set-ActiveModule -ModuleName $s.Tag
        })
        $scroll.Controls.Add($qBtn)
        $qBtns += $qBtn
    }

    # ── Info de sessão ─────────────────────────────────────────────────────────
    $lblLast = New-Object System.Windows.Forms.Label
    $lblLast.Text      = "Sessao iniciada: $(Get-Date -Format 'dd/MM/yyyy HH:mm')  |  Log: $($Global:WC.CurrentLog)"
    $lblLast.Font      = $Global:Theme.Font_Small
    $lblLast.ForeColor = $Global:Theme.Text_Muted
    $lblLast.Location  = New-Object System.Drawing.Point($margin, 0)  # set by Resize
    $lblLast.AutoSize  = $true
    $scroll.Controls.Add($lblLast)

    # ── Reflow function ────────────────────────────────────────────────────────
    $reflowCards = {
        $availW = $scroll.ClientSize.Width - 2 * $margin
        if ($availW -lt 1) { return }

        # Decide columns based on available width
        $cols = if ($availW -ge 460) { 2 } else { 1 }
        $cW   = [Math]::Floor(($availW - ($cols - 1) * $gap) / $cols)

        # Reposition cards
        foreach ($ci in 0..($cardPanels.Count - 1)) {
            $row = [Math]::Floor($ci / $cols)
            $col = $ci % $cols
            $cardPanels[$ci].Location = New-Object System.Drawing.Point(
                ($margin + $col * ($cW + $gap)),
                ($cardsY + $row * ($cardH + $gap))
            )
            $cardPanels[$ci].Width = $cW
            # Resize inner labels
            $cardPanels[$ci].Controls[1].Size = New-Object System.Drawing.Size([Math]::Max(10, $cW - 58), 14)
            $cardPanels[$ci].Controls[2].Size = New-Object System.Drawing.Size([Math]::Max(10, $cW - 58), 32)
        }

        $rows      = [Math]::Ceiling($cardPanels.Count / $cols)
        $accessY   = $cardsY + $rows * ($cardH + $gap) + 4
        $lblAccess.Location = New-Object System.Drawing.Point($margin, $accessY)

        $btnsY  = $accessY + 34
        $btnW   = 170
        $btnGap = 10
        $maxBtnsPerRow = [Math]::Max(1, [Math]::Floor($availW / ($btnW + $btnGap)))
        for ($bi = 0; $bi -lt $qBtns.Count; $bi++) {
            $br = [Math]::Floor($bi / $maxBtnsPerRow)
            $bc = $bi % $maxBtnsPerRow
            $qBtns[$bi].Location = New-Object System.Drawing.Point(
                ($margin + $bc * ($btnW + $btnGap)),
                ($btnsY + $br * 48)
            )
        }
        $btnRows = [Math]::Ceiling($qBtns.Count / $maxBtnsPerRow)
        $lblLast.Location = New-Object System.Drawing.Point($margin, ($btnsY + $btnRows * 48 + 8))
    }

    $scroll.Add_Resize($reflowCards)
    # Initial layout
    & $reflowCards

    Update-Status "Dashboard carregado"
}
