<#
.SYNOPSIS
    Visualizador de logs em janela separada - WinCare Pro
#>

function Show-LogViewer {
    $logForm = New-Object System.Windows.Forms.Form
    $logForm.Text          = "WinCare Pro - Visualizador de Logs"
    $logForm.Size          = New-Object System.Drawing.Size(820, 560)
    $logForm.StartPosition = 'CenterParent'
    $logForm.BackColor     = $Global:Theme.BG_Deep
    $logForm.Font          = $Global:Theme.Font_Body

    # Toolbar
    $toolbar = New-Object System.Windows.Forms.Panel
    $toolbar.Dock      = 'Top'
    $toolbar.Height    = 44
    $toolbar.BackColor = $Global:Theme.BG_Panel
    $logForm.Controls.Add($toolbar)

    $btnExport = New-StyledButton -Text 'Exportar Log' -X 8 -Y 6 -Width 140 -Height 32 -Style 'Secondary'
    $btnExport.Add_Click({
        $sfd = New-Object System.Windows.Forms.SaveFileDialog
        $sfd.Filter   = 'Log files (*.log)|*.log|Text files (*.txt)|*.txt'
        $sfd.FileName = "WinCare_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        if ($sfd.ShowDialog() -eq 'OK') {
            Export-LogReport -DestinationPath $sfd.FileName
            [System.Windows.Forms.MessageBox]::Show("Log exportado com sucesso!", "WinCare Pro", 'OK', 'Information')
        }
    })
    $toolbar.Controls.Add($btnExport)

    $btnRefresh = New-StyledButton -Text 'Atualizar' -X 156 -Y 6 -Width 110 -Height 32 -Style 'Secondary'
    $btnRefresh.Add_Click({
        $rtb.Clear()
        $lines = Get-LogContent
        foreach ($line in $lines) { $rtb.AppendText("$line`r`n") }
        $rtb.ScrollToCaret()
    })
    $toolbar.Controls.Add($btnRefresh)

    # TextBox de log
    $rtb = New-Object System.Windows.Forms.RichTextBox
    $rtb.Dock       = 'Fill'
    $rtb.ReadOnly   = $true
    $rtb.BackColor  = $Global:Theme.BG_Deep
    $rtb.ForeColor  = $Global:Theme.Success
    $rtb.Font       = $Global:Theme.Font_Mono
    $rtb.BorderStyle= 'None'
    $rtb.WordWrap   = $false
    $logForm.Controls.Add($rtb)

    # Carrega conteúdo atual
    $lines = Get-LogContent
    foreach ($line in $lines) { $rtb.AppendText("$line`r`n") }
    $rtb.ScrollToCaret()

    $logForm.ShowDialog() | Out-Null
}
