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

Describe 'Get-LatestRelease' {
    BeforeEach {
        Mock Invoke-RestMethod {
            return [pscustomobject]@{
                tag_name = 'v1.2.3'
                assets   = @(
                    [pscustomobject]@{ name = 'WinCare-Pro-v1.2.3.zip'; browser_download_url = 'https://example/zip' }
                    [pscustomobject]@{ name = 'SHA256SUMS';             browser_download_url = 'https://example/sums' }
                )
            }
        }
    }

    It 'returns Tag, ZipUrl and SumsUrl' {
        $r = Get-LatestRelease -Repo 'foo/bar'
        $r.Tag     | Should -Be 'v1.2.3'
        $r.ZipUrl  | Should -Be 'https://example/zip'
        $r.SumsUrl | Should -Be 'https://example/sums'
    }

    It 'calls the correct GitHub API endpoint' {
        Get-LatestRelease -Repo 'foo/bar' | Out-Null
        Should -Invoke Invoke-RestMethod -ParameterFilter {
            $Uri -eq 'https://api.github.com/repos/foo/bar/releases/latest'
        }
    }

    It 'throws when no zip asset is present' {
        Mock Invoke-RestMethod {
            return [pscustomobject]@{
                tag_name = 'v1.2.3'
                assets   = @([pscustomobject]@{ name = 'SHA256SUMS'; browser_download_url = 'https://x' })
            }
        }
        { Get-LatestRelease -Repo 'foo/bar' } | Should -Throw -ExpectedMessage '*no zip*'
    }

    It 'throws when no SHA256SUMS asset is present' {
        Mock Invoke-RestMethod {
            return [pscustomobject]@{
                tag_name = 'v1.2.3'
                assets   = @([pscustomobject]@{ name = 'WinCare.zip'; browser_download_url = 'https://x' })
            }
        }
        { Get-LatestRelease -Repo 'foo/bar' } | Should -Throw -ExpectedMessage '*no SHA256SUMS*'
    }
}

Describe 'Test-DownloadIntegrity' {
    BeforeAll {
        $script:tmp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "wc-test-$([guid]::NewGuid())") -Force
        $script:zipPath = Join-Path $script:tmp 'fake.zip'
        Set-Content -Path $script:zipPath -Value 'hello' -NoNewline -Encoding ascii
        $script:goodHash = (Get-FileHash $script:zipPath -Algorithm SHA256).Hash
    }
    AfterAll { Remove-Item $script:tmp -Recurse -Force -EA SilentlyContinue }

    It 'returns true when hash matches' {
        Mock Invoke-WebRequest { [pscustomobject]@{ Content = "$script:goodHash  fake.zip`n" } }
        Test-DownloadIntegrity -ZipPath $script:zipPath -SumsUrl 'https://x' | Should -BeTrue
    }

    It 'throws when hash does not match' {
        Mock Invoke-WebRequest { [pscustomobject]@{ Content = "0000000000000000000000000000000000000000000000000000000000000000  fake.zip" } }
        { Test-DownloadIntegrity -ZipPath $script:zipPath -SumsUrl 'https://x' } |
            Should -Throw -ExpectedMessage '*SHA256 mismatch*'
    }

    It 'is case-insensitive on the hash' {
        Mock Invoke-WebRequest { [pscustomobject]@{ Content = "$($script:goodHash.ToLower())  fake.zip" } }
        Test-DownloadIntegrity -ZipPath $script:zipPath -SumsUrl 'https://x' | Should -BeTrue
    }
}
