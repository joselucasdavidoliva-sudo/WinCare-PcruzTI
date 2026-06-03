#Requires -Version 5.1
BeforeAll {
    $script:InstallScript = Join-Path $PSScriptRoot '..\install.ps1' | Resolve-Path
    . $script:InstallScript
}

Describe 'Test-AdminPrivilege' {
    It 'returns a boolean' {
        $result = Test-AdminPrivilege
        $result | Should -BeOfType [bool]
    }
}

Describe 'install.ps1 dot-source safety' {
    It 'does not run the bootstrap when dot-sourced' {
        # If dot-sourcing had triggered the orchestrator, BeforeAll would have errored or installed something.
        # Sanity check: the marker variable that orchestrator would set must not exist.
        Get-Variable -Name 'WinCareBootstrapHasRun' -Scope Global -ErrorAction SilentlyContinue |
            Should -BeNullOrEmpty
    }
}
