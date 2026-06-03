<#
.SYNOPSIS
    Definições de tema, cores e estilos visuais do WinCare Pro
#>

Add-Type -AssemblyName System.Drawing

$Global:Theme = @{

    # ── Cores principais ──────────────────────────────────────────────────────
    BG_Deep      = [System.Drawing.Color]::FromArgb(10,  12,  20 )   # fundo profundo
    BG_Panel     = [System.Drawing.Color]::FromArgb(18,  22,  36 )   # painéis
    BG_Card      = [System.Drawing.Color]::FromArgb(24,  30,  48 )   # cards
    BG_Hover     = [System.Drawing.Color]::FromArgb(32,  40,  64 )   # hover
    BG_Active    = [System.Drawing.Color]::FromArgb(30,  60, 120 )   # item ativo
    BG_Input     = [System.Drawing.Color]::FromArgb(20,  26,  42 )   # inputs

    Accent       = [System.Drawing.Color]::FromArgb(0,  140, 255 )   # azul elétrico
    AccentGlow   = [System.Drawing.Color]::FromArgb(0,  100, 200 )
    AccentDim    = [System.Drawing.Color]::FromArgb(0,   70, 140 )
    Success      = [System.Drawing.Color]::FromArgb(0,  220, 130 )
    Warning      = [System.Drawing.Color]::FromArgb(255, 180,  0 )
    Danger       = [System.Drawing.Color]::FromArgb(255,  60,  80 )
    Info         = [System.Drawing.Color]::FromArgb(80,  180, 255 )

    Text_Primary = [System.Drawing.Color]::FromArgb(220, 230, 255 )
    Text_Muted   = [System.Drawing.Color]::FromArgb(100, 120, 160 )
    Text_Accent  = [System.Drawing.Color]::FromArgb(0,  140, 255 )
    Border       = [System.Drawing.Color]::FromArgb(40,  55,  90 )
    Separator    = [System.Drawing.Color]::FromArgb(30,  40,  70 )

    # ── Fontes ─────────────────────────────────────────────────────────────────
    Font_Title   = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold)
    Font_Header  = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
    Font_Body    = New-Object System.Drawing.Font('Segoe UI', 9,  [System.Drawing.FontStyle]::Regular)
    Font_Small   = New-Object System.Drawing.Font('Segoe UI', 8,  [System.Drawing.FontStyle]::Regular)
    Font_Mono    = New-Object System.Drawing.Font('Cascadia Mono', 8, [System.Drawing.FontStyle]::Regular)
    Font_Nav     = New-Object System.Drawing.Font('Segoe UI', 9,  [System.Drawing.FontStyle]::Regular)
    Font_NavSel  = New-Object System.Drawing.Font('Segoe UI', 9,  [System.Drawing.FontStyle]::Bold)
    Font_Badge   = New-Object System.Drawing.Font('Segoe UI', 7,  [System.Drawing.FontStyle]::Bold)

    # ── Dimensões ──────────────────────────────────────────────────────────────
    NavWidth     = 280
    HeaderHeight = 56
    FooterHeight = 48
    Padding      = 16
    Radius       = 6
}

function New-StyledButton {
    param(
        [string]$Text,
        [int]$X, [int]$Y,
        [int]$Width = 180, [int]$Height = 36,
        [string]$Style = 'Primary'  # Primary, Secondary, Danger, Success
    )

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text     = $Text
    $btn.Location = New-Object System.Drawing.Point($X, $Y)
    $btn.Size     = New-Object System.Drawing.Size($Width, $Height)
    $btn.FlatStyle= [System.Windows.Forms.FlatStyle]::Flat
    $btn.Cursor   = [System.Windows.Forms.Cursors]::Hand
    $btn.Font     = $Global:Theme.Font_Body
    $btn.AutoEllipsis = $true

    switch ($Style) {
        'Primary' {
            $btn.BackColor = $Global:Theme.Accent
            $btn.ForeColor = [System.Drawing.Color]::White
            $btn.FlatAppearance.BorderColor = $Global:Theme.AccentGlow
            $btn.FlatAppearance.BorderSize  = 1
        }
        'Secondary' {
            $btn.BackColor = $Global:Theme.BG_Card
            $btn.ForeColor = $Global:Theme.Text_Primary
            $btn.FlatAppearance.BorderColor = $Global:Theme.Border
            $btn.FlatAppearance.BorderSize  = 1
        }
        'Danger' {
            $btn.BackColor = $Global:Theme.Danger
            $btn.ForeColor = [System.Drawing.Color]::White
            $btn.FlatAppearance.BorderColor = $Global:Theme.Danger
            $btn.FlatAppearance.BorderSize  = 0
        }
        'Success' {
            $btn.BackColor = $Global:Theme.Success
            $btn.ForeColor = [System.Drawing.Color]::Black
            $btn.FlatAppearance.BorderColor = $Global:Theme.Success
            $btn.FlatAppearance.BorderSize  = 0
        }
    }

    # Hover effect
    $btn.Add_MouseEnter({
        if ($this.BackColor -eq $Global:Theme.Accent) {
            $this.BackColor = $Global:Theme.AccentGlow
        }
    })
    $btn.Add_MouseLeave({
        if ($this.BackColor -eq $Global:Theme.AccentGlow) {
            $this.BackColor = $Global:Theme.Accent
        }
    })

    return $btn
}

function New-StyledCheckBox {
    param([string]$Text, [int]$X, [int]$Y, [int]$Width = 280)
    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text      = $Text
    $chk.Location  = New-Object System.Drawing.Point($X, $Y)
    $chk.Size      = New-Object System.Drawing.Size($Width, 22)
    $chk.ForeColor = $Global:Theme.Text_Primary
    $chk.BackColor = [System.Drawing.Color]::Transparent
    $chk.Font      = $Global:Theme.Font_Body
    $chk.Cursor    = [System.Windows.Forms.Cursors]::Hand
    return $chk
}

function New-SectionLabel {
    param([string]$Text, [int]$X, [int]$Y, [int]$Width = 400)
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text      = $Text
    $lbl.Location  = New-Object System.Drawing.Point($X, $Y)
    $lbl.Size      = New-Object System.Drawing.Size($Width, 24)
    $lbl.ForeColor = $Global:Theme.Accent
    $lbl.BackColor = [System.Drawing.Color]::Transparent
    $lbl.Font      = $Global:Theme.Font_Header
    return $lbl
}

function New-Separator {
    param([int]$X, [int]$Y, [int]$Width = 560)
    $sep = New-Object System.Windows.Forms.Panel
    $sep.Location  = New-Object System.Drawing.Point($X, $Y)
    $sep.Size      = New-Object System.Drawing.Size($Width, 1)
    $sep.BackColor = $Global:Theme.Separator
    return $sep
}
