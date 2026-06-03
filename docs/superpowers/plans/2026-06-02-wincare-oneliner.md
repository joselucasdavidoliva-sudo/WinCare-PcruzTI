# WinCare Pro — One-Liner Installer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make WinCare Pro installable via `irm https://raw.githubusercontent.com/joselucasdavidoliva-sudo/WinCare-PcruzTI/main/install.ps1 | iex`, with auto-update on each run and preservation of user data across updates.

**Architecture:** Bootstrap script (`install.ps1`) at repo root, served via raw.githubusercontent. It self-elevates, queries GitHub Releases API for the latest version, downloads the zip asset, verifies SHA256, atomically swaps `%LOCALAPPDATA%\WinCare-Pro\app\`, then launches `WinCare.ps1`. Logs and `Config.json` live outside `app\` to survive updates. Releases are produced by a GitHub Actions workflow on tag push.

**Tech Stack:** PowerShell 5.1+ (must run on Win10/11 stock), Pester 5 (built-in or PSGallery), GitHub Releases API, `softprops/action-gh-release@v2`.

**Repo:** `joselucasdavidoliva-sudo/WinCare-PcruzTI` (branch `main`)

**Spec:** `docs/superpowers/specs/2026-06-02-wincare-oneliner-design.md`

---

## File Structure

| Path | Status | Responsibility |
|---|---|---|
| `install.ps1` | **new** | Bootstrap: orchestrator + 4 pure functions (admin/release/integrity/install) |
| `tests/install.Tests.ps1` | **new** | Pester unit tests for install.ps1 functions (mocking I/O) |
| `tests/Run-Tests.ps1` | **new** | Test runner: ensures Pester ≥ 5 is loaded, invokes Invoke-Pester |
| `.github/workflows/release.yml` | **new** | On tag push: zip the project, generate SHA256SUMS, publish GitHub Release |
| `WinCare.ps1` | modify lines 9-15 | Point `LogPath`/`ConfigPath` to `%LOCALAPPDATA%\WinCare-Pro` |
| `core/Config.ps1` | modify `Initialize-Config` | Seed `Config.json` from `app\core\Config.json` template if missing |
| `docs/superpowers/plans/2026-06-02-wincare-oneliner.md` | **new** | This file |

**Why `install.ps1` is a single file with functions** — it must be loadable via `irm | iex` (one HTTP request, no relative imports). Internally we still split logic into testable functions and guard the orchestrator behind `$MyInvocation.InvocationName -ne '.'` so Pester can dot-source it cleanly.

---

## Conventions used in this plan

- All `Write` operations use absolute Windows paths.
- All PowerShell snippets target **PowerShell 5.1** unless noted (no ternary, no `?.`, no null-coalescing in shipped code; the plan's *test commands* can use 7+ syntax since you run them locally).
- `$Repo` shorthand = `joselucasdavidoliva-sudo/WinCare-PcruzTI`.
- All `git commit` steps assume `git init` + remote setup is done **before Task 1** (see "Pre-Task Setup" below).

---

## Pre-Task Setup (one-time, do this first)

- [ ] **Setup Step 1: Initialize git in the working directory**

The directory `C:\TI\WinCare-Pro\WinCare-Pro\` is not yet a git repo (verified). Initialize it and wire the remote.

Run:

```powershell
cd C:\TI\WinCare-Pro\WinCare-Pro
git init -b main
git remote add origin https://github.com/joselucasdavidoliva-sudo/WinCare-PcruzTI.git
```

Expected: no errors; `git status` shows untracked files.

- [ ] **Setup Step 2: Create `.gitignore`**

Write `C:\TI\WinCare-Pro\WinCare-Pro\.gitignore`:

```
output/
*.log
*.zip
SHA256SUMS
.vs/
.idea/
```

- [ ] **Setup Step 3: Baseline commit**

```powershell
git add .
git commit -m "chore: baseline before one-liner installer"
git push -u origin main
```

Expected: push succeeds.

---

## Task 1: Test harness — Pester runner

**Files:**
- Create: `C:\TI\WinCare-Pro\WinCare-Pro\tests\Run-Tests.ps1`

- [ ] **Step 1: Write the runner**

Create `tests\Run-Tests.ps1`:

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Carrega Pester (instalando se necessário) e executa todos os *.Tests.ps1.
#>
[CmdletBinding()]
param(
    [string]$Path = (Join-Path $PSScriptRoot '*.Tests.ps1')
)

$ErrorActionPreference = 'Stop'

# Pester 5 é o mínimo (sintaxe nova). Win10/11 vem com Pester 3 antigo no $PSHOME — ignorar.
$needed = '5.5.0'
$loaded = Get-Module Pester | Where-Object { $_.Version -ge [version]$needed }
if (-not $loaded) {
    $installed = Get-Module Pester -ListAvailable |
        Where-Object { $_.Version -ge [version]$needed } |
        Sort-Object Version -Descending | Select-Object -First 1
    if (-not $installed) {
        Write-Host "Instalando Pester $needed para CurrentUser..." -ForegroundColor Yellow
        Install-Module Pester -MinimumVersion $needed -Scope CurrentUser -Force -SkipPublisherCheck
        $installed = Get-Module Pester -ListAvailable |
            Where-Object { $_.Version -ge [version]$needed } |
            Sort-Object Version -Descending | Select-Object -First 1
    }
    Import-Module $installed.Path -Force
}

Invoke-Pester -Path $Path -Output Detailed
```

- [ ] **Step 2: Verify runner loads Pester without errors**

Run:

```powershell
cd C:\TI\WinCare-Pro\WinCare-Pro
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

Expected: Pester loads, then exits with "No test files matched..." (we have no tests yet). No exceptions.

- [ ] **Step 3: Commit**

```powershell
git add tests\Run-Tests.ps1
git commit -m "test: add Pester 5 test runner"
```

---

## Task 2: `install.ps1` skeleton + `Test-AdminPrivilege`

**Files:**
- Create: `C:\TI\WinCare-Pro\WinCare-Pro\install.ps1`
- Create: `C:\TI\WinCare-Pro\WinCare-Pro\tests\install.Tests.ps1`

- [ ] **Step 1: Write the failing test**

Create `tests\install.Tests.ps1`:

```powershell
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
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
cd C:\TI\WinCare-Pro\WinCare-Pro
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

Expected: FAIL — "install.ps1 not found" or "Test-AdminPrivilege not recognized".

- [ ] **Step 3: Write `install.ps1` skeleton**

Create `install.ps1` (repo root):

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    WinCare Pro - One-liner installer/launcher
.DESCRIPTION
    Bootstrap entry point: irm https://raw.githubusercontent.com/joselucasdavidoliva-sudo/WinCare-PcruzTI/main/install.ps1 | iex
.PARAMETER Force
    Reinstala mesmo se a versão local for a mais recente.
.PARAMETER NoUpdate
    Não consulta a API do GitHub; apenas executa a versão já instalada.
.PARAMETER Uninstall
    Remove %LOCALAPPDATA%\WinCare-Pro inteiro e sai.
#>
[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$NoUpdate,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ----- Constants -----
$script:Repo        = 'joselucasdavidoliva-sudo/WinCare-PcruzTI'
$script:InstallDir  = Join-Path $env:LOCALAPPDATA 'WinCare-Pro'
$script:AppDir      = Join-Path $script:InstallDir 'app'
$script:VersionFile = Join-Path $script:InstallDir 'version.txt'
$script:EntryPoint  = Join-Path $script:AppDir 'WinCare.ps1'

# ----- Functions -----
function Test-AdminPrivilege {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $pr = New-Object Security.Principal.WindowsPrincipal($id)
    return [bool]$pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ----- Orchestrator -----
function Start-Bootstrap {
    [CmdletBinding()]
    param([switch]$Force, [switch]$NoUpdate, [switch]$Uninstall)
    $Global:WinCareBootstrapHasRun = $true
    throw 'Start-Bootstrap not yet implemented'
}

# ----- Entry guard -----
# Only run the orchestrator when invoked directly (NOT when dot-sourced for testing or via iex).
# When piped to iex, $MyInvocation.InvocationName is empty string; we use a marker.
if ($MyInvocation.Line -match 'install\.ps1' -or $MyInvocation.InvocationName -eq '&' -or $MyInvocation.InvocationName -eq '') {
    Start-Bootstrap -Force:$Force -NoUpdate:$NoUpdate -Uninstall:$Uninstall
}
```

> **Note on the entry guard:** when `irm | iex` runs the script, `$MyInvocation.InvocationName` is `''`. When dot-sourced (`. install.ps1`), it is `'.'`. When run directly (`.\install.ps1`), it matches `install.ps1`. We deliberately exclude the `'.'` case so tests can dot-source freely.

- [ ] **Step 4: Run test to verify it passes**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

Expected: PASS — `Test-AdminPrivilege` returns a bool; `WinCareBootstrapHasRun` is not set.

- [ ] **Step 5: Commit**

```powershell
git add install.ps1 tests\install.Tests.ps1
git commit -m "feat(install): skeleton + admin check"
```

---

## Task 3: `Get-LatestRelease` — query GitHub Releases API

**Files:**
- Modify: `C:\TI\WinCare-Pro\WinCare-Pro\install.ps1` (add `Get-LatestRelease` function)
- Modify: `C:\TI\WinCare-Pro\WinCare-Pro\tests\install.Tests.ps1` (add Describe block)

- [ ] **Step 1: Write the failing tests**

Append to `tests\install.Tests.ps1`:

```powershell
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

Expected: 4 failures — "Get-LatestRelease is not recognized".

- [ ] **Step 3: Implement `Get-LatestRelease`**

Insert in `install.ps1` after `Test-AdminPrivilege`:

```powershell
function Get-LatestRelease {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Repo)

    $url = "https://api.github.com/repos/$Repo/releases/latest"
    $rel = Invoke-RestMethod -Uri $url -Headers @{ 'User-Agent' = 'WinCare-Installer' }

    $zip  = $rel.assets | Where-Object { $_.name -like '*.zip' }    | Select-Object -First 1
    $sums = $rel.assets | Where-Object { $_.name -eq 'SHA256SUMS' } | Select-Object -First 1

    if (-not $zip)  { throw "Release $($rel.tag_name) has no zip asset" }
    if (-not $sums) { throw "Release $($rel.tag_name) has no SHA256SUMS asset" }

    return [pscustomobject]@{
        Tag     = $rel.tag_name
        ZipUrl  = $zip.browser_download_url
        SumsUrl = $sums.browser_download_url
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

Expected: 4 PASS (plus the 2 from Task 2 still passing).

- [ ] **Step 5: Commit**

```powershell
git add install.ps1 tests\install.Tests.ps1
git commit -m "feat(install): Get-LatestRelease with asset validation"
```

---

## Task 4: `Test-DownloadIntegrity` — SHA256 verification

**Files:**
- Modify: `install.ps1`
- Modify: `tests\install.Tests.ps1`

- [ ] **Step 1: Write the failing tests**

Append to `tests\install.Tests.ps1`:

```powershell
Describe 'Test-DownloadIntegrity' {
    BeforeAll {
        $script:tmp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "wc-test-$([guid]::NewGuid())") -Force
        $script:zipPath = Join-Path $script:tmp 'fake.zip'
        Set-Content -Path $script:zipPath -Value 'hello' -NoNewline -Encoding ascii
        # SHA256 of "hello" (ascii) = 2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

Expected: 3 failures — "Test-DownloadIntegrity is not recognized".

- [ ] **Step 3: Implement `Test-DownloadIntegrity`**

Insert in `install.ps1` after `Get-LatestRelease`:

```powershell
function Test-DownloadIntegrity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ZipPath,
        [Parameter(Mandatory)][string]$SumsUrl
    )

    $sums   = (Invoke-WebRequest -Uri $SumsUrl -UseBasicParsing).Content
    $actual = (Get-FileHash -Path $ZipPath -Algorithm SHA256).Hash

    if ($sums -notmatch [regex]::Escape($actual)) {
        throw "SHA256 mismatch — expected one of the hashes in SHA256SUMS, got $actual"
    }
    return $true
}
```

> **Why regex-escape + `-notmatch` instead of `-notlike`**: SHA256SUMS may contain multiple lines (`<hash>  <filename>`). The actual hash from `Get-FileHash` is always uppercase hex; `-match` is case-insensitive by default, which covers both casings.

- [ ] **Step 4: Run tests to verify they pass**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

Expected: 3 PASS.

- [ ] **Step 5: Commit**

```powershell
git add install.ps1 tests\install.Tests.ps1
git commit -m "feat(install): SHA256 integrity verification"
```

---

## Task 5: `Invoke-AtomicInstall` — extract with backup/rollback

**Files:**
- Modify: `install.ps1`
- Modify: `tests\install.Tests.ps1`

- [ ] **Step 1: Write the failing tests**

Append to `tests\install.Tests.ps1`:

```powershell
Describe 'Invoke-AtomicInstall' {
    BeforeEach {
        $script:root = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "wc-inst-$([guid]::NewGuid())") -Force
        $script:appDir = Join-Path $script:root 'app'

        # Build a minimal zip containing "WinCare.ps1"
        $stage = New-Item -ItemType Directory -Path (Join-Path $script:root 'stage') -Force
        Set-Content (Join-Path $stage 'WinCare.ps1') -Value '# v-new' -NoNewline
        $script:zip = Join-Path $script:root 'new.zip'
        Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $script:zip -Force
    }
    AfterEach { Remove-Item $script:root -Recurse -Force -EA SilentlyContinue }

    It 'extracts zip to AppDir when AppDir does not exist' {
        Invoke-AtomicInstall -ZipPath $script:zip -AppDir $script:appDir
        (Join-Path $script:appDir 'WinCare.ps1') | Should -Exist
        (Get-Content (Join-Path $script:appDir 'WinCare.ps1')) | Should -Be '# v-new'
    }

    It 'replaces existing AppDir contents on success' {
        New-Item -ItemType Directory -Path $script:appDir -Force | Out-Null
        Set-Content (Join-Path $script:appDir 'WinCare.ps1') -Value '# v-old' -NoNewline
        Set-Content (Join-Path $script:appDir 'STALE.txt')   -Value 'remove me' -NoNewline

        Invoke-AtomicInstall -ZipPath $script:zip -AppDir $script:appDir
        (Get-Content (Join-Path $script:appDir 'WinCare.ps1')) | Should -Be '# v-new'
        (Join-Path $script:appDir 'STALE.txt') | Should -Not -Exist
    }

    It 'restores backup when extraction fails' {
        New-Item -ItemType Directory -Path $script:appDir -Force | Out-Null
        Set-Content (Join-Path $script:appDir 'WinCare.ps1') -Value '# v-old' -NoNewline
        $badZip = Join-Path $script:root 'bad.zip'
        Set-Content $badZip -Value 'not a zip' -NoNewline

        { Invoke-AtomicInstall -ZipPath $badZip -AppDir $script:appDir } | Should -Throw
        (Get-Content (Join-Path $script:appDir 'WinCare.ps1')) | Should -Be '# v-old'
        (Join-Path "$($script:appDir).old") | Should -Not -Exist
    }

    It 'cleans up stale .old directory from previous failed run' {
        New-Item -ItemType Directory -Path "$($script:appDir).old" -Force | Out-Null
        Set-Content (Join-Path "$($script:appDir).old" 'leftover.txt') -Value 'x' -NoNewline

        Invoke-AtomicInstall -ZipPath $script:zip -AppDir $script:appDir
        "$($script:appDir).old" | Should -Not -Exist
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

Expected: 4 failures — "Invoke-AtomicInstall is not recognized".

- [ ] **Step 3: Implement `Invoke-AtomicInstall`**

Insert in `install.ps1` after `Test-DownloadIntegrity`:

```powershell
function Invoke-AtomicInstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ZipPath,
        [Parameter(Mandatory)][string]$AppDir
    )

    $backup = "$AppDir.old"

    # Clean up any leftover from a previously crashed run.
    if (Test-Path $backup) { Remove-Item $backup -Recurse -Force }

    $hadPrevious = Test-Path $AppDir
    if ($hadPrevious) { Rename-Item -Path $AppDir -NewName (Split-Path $backup -Leaf) }

    try {
        New-Item -ItemType Directory -Path $AppDir -Force | Out-Null
        Expand-Archive -Path $ZipPath -DestinationPath $AppDir -Force
        if ($hadPrevious) { Remove-Item $backup -Recurse -Force }
    } catch {
        # Rollback: remove the half-extracted AppDir and restore backup.
        if (Test-Path $AppDir) { Remove-Item $AppDir -Recurse -Force -EA SilentlyContinue }
        if ($hadPrevious -and (Test-Path $backup)) {
            Rename-Item -Path $backup -NewName (Split-Path $AppDir -Leaf)
        }
        throw
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

Expected: 4 PASS.

- [ ] **Step 5: Commit**

```powershell
git add install.ps1 tests\install.Tests.ps1
git commit -m "feat(install): atomic install with backup/rollback"
```

---

## Task 6: `Start-Bootstrap` — orchestrator with all flags

**Files:**
- Modify: `install.ps1` (replace stub `Start-Bootstrap`)
- Modify: `tests\install.Tests.ps1`

- [ ] **Step 1: Write the failing tests**

Append to `tests\install.Tests.ps1`:

```powershell
Describe 'Start-Bootstrap' {
    BeforeEach {
        # Isolate paths used by Start-Bootstrap from %LOCALAPPDATA%
        $script:fakeRoot = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "wc-orch-$([guid]::NewGuid())") -Force
        Set-Variable -Name InstallDir  -Scope Script -Value $script:fakeRoot.FullName
        Set-Variable -Name AppDir      -Scope Script -Value (Join-Path $script:fakeRoot 'app')
        Set-Variable -Name VersionFile -Scope Script -Value (Join-Path $script:fakeRoot 'version.txt')
        Set-Variable -Name EntryPoint  -Scope Script -Value (Join-Path $script:fakeRoot 'app\WinCare.ps1')

        Mock Test-AdminPrivilege { $true }
        Mock Start-Process       { }       # don't actually launch UAC or PowerShell
        Mock Get-LatestRelease   {
            [pscustomobject]@{ Tag = 'v1.0.1'; ZipUrl = 'https://x/zip'; SumsUrl = 'https://x/sums' }
        }
        Mock Invoke-WebRequest   { [pscustomobject]@{ Content = '' } }
        Mock Test-DownloadIntegrity { $true }
        Mock Invoke-AtomicInstall   {
            New-Item -ItemType Directory -Path $AppDir -Force | Out-Null
            Set-Content (Join-Path $AppDir 'WinCare.ps1') -Value '# stub' -NoNewline
        }
    }
    AfterEach { Remove-Item $script:fakeRoot -Recurse -Force -EA SilentlyContinue }

    It '-Uninstall removes InstallDir and returns' {
        New-Item -ItemType File -Path (Join-Path $script:fakeRoot 'marker.txt') -Force | Out-Null
        Start-Bootstrap -Uninstall
        Test-Path $script:fakeRoot.FullName | Should -BeFalse
        Should -Invoke Invoke-AtomicInstall -Times 0
    }

    It 'installs when nothing is present' {
        Start-Bootstrap
        Should -Invoke Invoke-AtomicInstall -Times 1
        (Get-Content (Join-Path $script:fakeRoot 'version.txt')) | Should -Be 'v1.0.1'
        Should -Invoke Start-Process -Times 1
    }

    It 'skips update when installed version matches and -Force not set' {
        New-Item -ItemType Directory -Path (Split-Path $script:EntryPoint -Parent) -Force | Out-Null
        Set-Content $script:EntryPoint -Value '# already' -NoNewline
        Set-Content $script:VersionFile -Value 'v1.0.1' -NoNewline

        Start-Bootstrap
        Should -Invoke Invoke-AtomicInstall -Times 0
        Should -Invoke Start-Process -Times 1
    }

    It 'updates when installed version differs' {
        New-Item -ItemType Directory -Path (Split-Path $script:EntryPoint -Parent) -Force | Out-Null
        Set-Content $script:EntryPoint -Value '# old' -NoNewline
        Set-Content $script:VersionFile -Value 'v1.0.0' -NoNewline

        Start-Bootstrap
        Should -Invoke Invoke-AtomicInstall -Times 1
        (Get-Content $script:VersionFile) | Should -Be 'v1.0.1'
    }

    It '-Force triggers reinstall even when versions match' {
        New-Item -ItemType Directory -Path (Split-Path $script:EntryPoint -Parent) -Force | Out-Null
        Set-Content $script:EntryPoint -Value '# x' -NoNewline
        Set-Content $script:VersionFile -Value 'v1.0.1' -NoNewline

        Start-Bootstrap -Force
        Should -Invoke Invoke-AtomicInstall -Times 1
    }

    It '-NoUpdate skips API call and just launches' {
        New-Item -ItemType Directory -Path (Split-Path $script:EntryPoint -Parent) -Force | Out-Null
        Set-Content $script:EntryPoint -Value '# x' -NoNewline
        Set-Content $script:VersionFile -Value 'v0.9.0' -NoNewline

        Start-Bootstrap -NoUpdate
        Should -Invoke Get-LatestRelease -Times 0
        Should -Invoke Invoke-AtomicInstall -Times 0
        Should -Invoke Start-Process -Times 1
    }

    It '-NoUpdate falls back to full install when nothing is installed' {
        Start-Bootstrap -NoUpdate
        Should -Invoke Invoke-AtomicInstall -Times 1
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

Expected: 7 failures (current stub throws "Start-Bootstrap not yet implemented").

- [ ] **Step 3: Implement `Start-Bootstrap`**

Replace the stub `Start-Bootstrap` in `install.ps1` with the full implementation:

```powershell
function Start-Bootstrap {
    [CmdletBinding()]
    param([switch]$Force, [switch]$NoUpdate, [switch]$Uninstall)
    $Global:WinCareBootstrapHasRun = $true

    # 1. Admin
    if (-not (Test-AdminPrivilege)) {
        $cmd = "irm https://raw.githubusercontent.com/$script:Repo/main/install.ps1 | iex"
        $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $cmd)
        Start-Process powershell -Verb RunAs -ArgumentList $argList
        return
    }

    # 2. Uninstall short-circuit
    if ($Uninstall) {
        if (Test-Path $script:InstallDir) {
            Remove-Item $script:InstallDir -Recurse -Force
            Write-Host "WinCare Pro desinstalado de $script:InstallDir" -ForegroundColor Green
        } else {
            Write-Host "Nada a remover." -ForegroundColor Yellow
        }
        return
    }

    if (-not (Test-Path $script:InstallDir)) {
        New-Item -ItemType Directory -Path $script:InstallDir -Force | Out-Null
    }

    $entryExists = Test-Path $script:EntryPoint
    $installed   = if (Test-Path $script:VersionFile) {
        (Get-Content $script:VersionFile -Raw).Trim()
    } else { $null }

    # 3. Decide whether to update
    $shouldFetch = -not ($NoUpdate -and $entryExists)
    if ($shouldFetch) {
        Write-Host "Consultando releases em github.com/$script:Repo ..." -ForegroundColor Cyan
        $rel = Get-LatestRelease -Repo $script:Repo
        $needsInstall = $Force -or (-not $entryExists) -or ($installed -ne $rel.Tag)

        if ($needsInstall) {
            $tmpZip = Join-Path $env:TEMP "wincare-$($rel.Tag)-$([guid]::NewGuid()).zip"
            try {
                Write-Host "Baixando $($rel.Tag)..." -ForegroundColor Cyan
                Invoke-WebRequest -Uri $rel.ZipUrl -OutFile $tmpZip -UseBasicParsing
                Test-DownloadIntegrity -ZipPath $tmpZip -SumsUrl $rel.SumsUrl | Out-Null
                Invoke-AtomicInstall -ZipPath $tmpZip -AppDir $script:AppDir
                Set-Content -Path $script:VersionFile -Value $rel.Tag -NoNewline -Encoding ascii
                Write-Host "Instalado $($rel.Tag)" -ForegroundColor Green
            } finally {
                Remove-Item $tmpZip -Force -EA SilentlyContinue
            }
        } else {
            Write-Host "Versão $installed já é a mais recente." -ForegroundColor Green
        }
    }

    # 4. Launch (fallback install if NoUpdate was set but nothing was installed)
    if (-not (Test-Path $script:EntryPoint)) {
        if ($NoUpdate) {
            Write-Host "-NoUpdate especificado mas nada instalado; executando install completo..." -ForegroundColor Yellow
            Start-Bootstrap -Force
            return
        }
        throw "Instalação completou mas $script:EntryPoint não existe"
    }

    Start-Process powershell -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script:EntryPoint
    )
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

Expected: all tests pass (Tasks 2-6).

- [ ] **Step 5: Commit**

```powershell
git add install.ps1 tests\install.Tests.ps1
git commit -m "feat(install): orchestrator with -Force/-NoUpdate/-Uninstall"
```

---

## Task 7: Refactor `WinCare.ps1` — persistent data outside `app\`

**Files:**
- Modify: `C:\TI\WinCare-Pro\WinCare-Pro\WinCare.ps1` lines 9-15

- [ ] **Step 1: Apply the change**

In `WinCare.ps1`, replace the `$Global:WC = @{ ... }` block (lines 9-15) with:

```powershell
$Global:WC = @{
    Version    = '1.0.0'
    AppName    = 'WinCare Pro'
    RootPath   = $PSScriptRoot
    DataPath   = Join-Path $env:LOCALAPPDATA 'WinCare-Pro'
    LogPath    = Join-Path $env:LOCALAPPDATA 'WinCare-Pro\output\logs'
    ConfigPath = Join-Path $env:LOCALAPPDATA 'WinCare-Pro\Config.json'
}
```

> **Why:** The installer overwrites `app\` on every update. Logs and Config.json must live outside it to survive.
> When run standalone (no installer), the new paths still resolve to `%LOCALAPPDATA%\WinCare-Pro\` — that's fine, slightly tidier than dumping logs into the project folder.

- [ ] **Step 2: Smoke test**

Run:

```powershell
cd C:\TI\WinCare-Pro\WinCare-Pro
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { . .\WinCare.ps1 } # will UAC-prompt; cancel"
```

Cancel the UAC prompt. Then verify nothing else broke:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$global:WC = @{}; . .\core\Logger.ps1; Get-Command Write-Log"
```

Expected: `Write-Log` listed (Logger loaded cleanly).

- [ ] **Step 3: Commit**

```powershell
git add WinCare.ps1
git commit -m "refactor: move LogPath/ConfigPath to %LOCALAPPDATA% for update persistence"
```

---

## Task 8: Refactor `core/Config.ps1` — seed from template on first run

**Files:**
- Modify: `C:\TI\WinCare-Pro\WinCare-Pro\core\Config.ps1` (`Initialize-Config` function)

- [ ] **Step 1: Replace `Initialize-Config`**

In `core/Config.ps1`, replace the entire `Initialize-Config` function (lines 18-50) with:

```powershell
function Initialize-Config {
    $configPath = $Global:WC.ConfigPath
    $configDir  = Split-Path $configPath -Parent

    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    # First-run seed: if user config doesn't exist but a template ships in app\core\Config.json, copy it.
    if (-not (Test-Path $configPath)) {
        $template = Join-Path $Global:WC.RootPath 'core\Config.json'
        if (Test-Path $template) {
            Copy-Item -Path $template -Destination $configPath -Force
        }
    }

    if (Test-Path $configPath) {
        try {
            $json = Get-Content $configPath -Raw -Encoding UTF8
            $loaded = $json | ConvertFrom-Json
            $Global:WC.Config = @{}
            $loaded.PSObject.Properties | ForEach-Object {
                $Global:WC.Config[$_.Name] = $_.Value
            }
            # Garante que chaves novas existam
            foreach ($key in $Global:WC_DefaultConfig.Keys) {
                if (-not $Global:WC.Config.ContainsKey($key)) {
                    $Global:WC.Config[$key] = $Global:WC_DefaultConfig[$key]
                }
            }
        } catch {
            Write-Log "Config corrompido, usando padrão: $_" -Level WARN
            $Global:WC.Config = $Global:WC_DefaultConfig.Clone()
        }
    } else {
        $Global:WC.Config = $Global:WC_DefaultConfig.Clone()
        Save-Config
    }

    Write-Log "Configurações carregadas" -Level INFO
}
```

> **Why:** When the installer extracts a new version into `app\`, the template `app\core\Config.json` is fresh, but the user's tuned config in `%LOCALAPPDATA%\WinCare-Pro\Config.json` is preserved. New users (no existing Config.json) get the shipped defaults via the seed copy.

- [ ] **Step 2: Smoke test**

Run:

```powershell
cd C:\TI\WinCare-Pro\WinCare-Pro
$tmpCfg = Join-Path $env:TEMP "Config-test-$([guid]::NewGuid()).json"
$Global:WC = @{ RootPath = (Get-Location).Path; ConfigPath = $tmpCfg; LogPath = $env:TEMP }
. .\core\Logger.ps1; . .\core\Config.ps1
Initialize-Logger; Initialize-Config
Test-Path $tmpCfg
Remove-Item $tmpCfg -Force
```

Expected: `True` (Config.json was seeded from `core\Config.json` template).

- [ ] **Step 3: Commit**

```powershell
git add core\Config.ps1
git commit -m "refactor(config): seed Config.json from app template on first run"
```

---

## Task 9: GitHub Actions release workflow

**Files:**
- Create: `C:\TI\WinCare-Pro\WinCare-Pro\.github\workflows\release.yml`

- [ ] **Step 1: Write the workflow**

Create `.github\workflows\release.yml`:

```yaml
name: Release

on:
  push:
    tags: ['v*']

jobs:
  release:
    runs-on: windows-latest
    permissions:
      contents: write
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Package
        shell: pwsh
        run: |
          $tag = $env:GITHUB_REF_NAME
          $zip = "WinCare-Pro-$tag.zip"
          Compress-Archive `
            -Path WinCare.ps1, core, ui, modules, README.md, Abrir_WinCare_Pro.bat `
            -DestinationPath $zip `
            -Force
          $hash = (Get-FileHash $zip -Algorithm SHA256).Hash
          "$hash  $zip" | Out-File -FilePath SHA256SUMS -Encoding ascii -NoNewline
          Write-Host "Built $zip ($hash)"

      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          files: |
            WinCare-Pro-*.zip
            SHA256SUMS
          generate_release_notes: true
```

> **Why `softprops/action-gh-release@v2`**: stable, no Node 16 deprecation issues, supports `files` glob, uses the default `GITHUB_TOKEN` so no secrets to configure.

- [ ] **Step 2: Commit and push**

```powershell
git add .github\workflows\release.yml
git commit -m "ci: GitHub Actions release workflow on tag push"
git push
```

Expected: push succeeds; workflow is registered (visible in the repo's Actions tab — nothing runs yet because no tag).

---

## Task 10: First release + end-to-end manual test

**Files:** None (operational task)

> This task validates the entire system on a real Windows machine. It's the only thing Pester can't cover — actual UAC, actual GitHub fetch, actual extraction, actual launch of WinForms UI.

- [ ] **Step 1: Push install.ps1 to main**

```powershell
git push
```

Verify in browser: `https://raw.githubusercontent.com/joselucasdavidoliva-sudo/WinCare-PcruzTI/main/install.ps1` returns your script.

- [ ] **Step 2: Tag and push v1.0.0**

```powershell
git tag v1.0.0
git push origin v1.0.0
```

Watch the Actions tab: workflow runs, ~1 minute. Release `v1.0.0` appears under Releases with `WinCare-Pro-v1.0.0.zip` and `SHA256SUMS`.

- [ ] **Step 3: Clean install on a non-admin shell**

Open a regular (non-admin) PowerShell, run:

```powershell
irm https://raw.githubusercontent.com/joselucasdavidoliva-sudo/WinCare-PcruzTI/main/install.ps1 | iex
```

Expected sequence:
1. UAC prompt appears → accept.
2. New elevated window opens.
3. "Consultando releases..." → "Baixando v1.0.0..." → "Instalado v1.0.0".
4. WinCare UI window opens.

Verify on disk:

```powershell
ls $env:LOCALAPPDATA\WinCare-Pro
# Expected: app\, output\, version.txt, Config.json
Get-Content $env:LOCALAPPDATA\WinCare-Pro\version.txt
# Expected: v1.0.0
```

- [ ] **Step 4: Idempotency test (same version)**

Run the one-liner again. Expected: "Versão v1.0.0 já é a mais recente." — UI launches, no download.

- [ ] **Step 5: Update test**

Bump `WinCare.ps1` Version field to `1.0.1`, commit, tag `v1.0.1`, push tag:

```powershell
git tag v1.0.1
git push origin v1.0.1
```

Wait for workflow. Then rerun one-liner. Expected: "Baixando v1.0.1..." → installs → UI shows v1.0.1.

Verify `Config.json` was preserved:

```powershell
# Before update: edit a setting in the UI (e.g., change Theme).
# After update:
Get-Content $env:LOCALAPPDATA\WinCare-Pro\Config.json
# Theme value must still reflect your prior edit.
```

- [ ] **Step 6: Flag tests**

```powershell
# Force reinstall:
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/joselucasdavidoliva-sudo/WinCare-PcruzTI/main/install.ps1))) -Force

# Skip update check:
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/joselucasdavidoliva-sudo/WinCare-PcruzTI/main/install.ps1))) -NoUpdate

# Uninstall:
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/joselucasdavidoliva-sudo/WinCare-PcruzTI/main/install.ps1))) -Uninstall
ls $env:LOCALAPPDATA\WinCare-Pro
# Expected: path does not exist
```

- [ ] **Step 7: Integrity failure test**

Manually corrupt the release: replace `SHA256SUMS` in the release with a wrong hash (via GitHub web UI, edit release assets). Rerun:

```powershell
irm https://raw.githubusercontent.com/joselucasdavidoliva-sudo/WinCare-PcruzTI/main/install.ps1 | iex
```

Expected: "SHA256 mismatch — expected one of the hashes in SHA256SUMS, got ...". Installer aborts. If a previous install existed, it's still intact (no `app.old\` debris).

**Restore the correct SHA256SUMS afterward.**

- [ ] **Step 8: README update**

Append to `README.md` under "Como Executar":

```markdown
### Opção 3 — One-liner (Recomendado)

```powershell
irm https://raw.githubusercontent.com/joselucasdavidoliva-sudo/WinCare-PcruzTI/main/install.ps1 | iex
```

Instala em `%LOCALAPPDATA%\WinCare-Pro` e abre a UI. Roda novamente: atualiza automaticamente se houver versão mais recente.

Flags:
- `-Force` — força reinstalação
- `-NoUpdate` — pula checagem de atualização
- `-Uninstall` — remove completamente
```

Commit:

```powershell
git add README.md
git commit -m "docs: add one-liner install instructions"
git push
```

- [ ] **Step 9: Final sanity tag**

```powershell
git tag v1.0.2
git push origin v1.0.2
```

The first user-visible release.

---

## Self-Review (executed by plan author)

**Spec coverage check:**
- §3 Fluxo end-to-end → Tasks 2, 6, 10
- §4 Componentes → all paths used in Task 6 match spec table
- §5 Lógica do install.ps1 → Task 6 (orchestrator) matches the pseudocode 1:1
- §6.1 WinCare.ps1 refactor → Task 7
- §6.2 Config.ps1 refactor → Task 8
- §6.3 install.ps1 → Tasks 2-6
- §6.4 release.yml → Task 9
- §7 Segurança: TLS 1.2 (install.ps1 prologue, Task 2), SHA256 (Task 4), atomic swap (Task 5), UAC (Task 6 step 3) → all covered
- §8 Critérios de aceitação → Task 10 steps 3, 5, 6, 7 cover criteria 1-5

**Placeholder scan:** No TBDs, no "implement later", no vague "add error handling" — every step has concrete code or commands.

**Type consistency check:** `Test-AdminPrivilege` / `Get-LatestRelease` / `Test-DownloadIntegrity` / `Invoke-AtomicInstall` / `Start-Bootstrap` — same names used in tests, implementation, and orchestrator. Return shape of `Get-LatestRelease` (`Tag`, `ZipUrl`, `SumsUrl`) is used identically in tests (Task 3) and orchestrator (Task 6). `$script:Repo` / `$script:InstallDir` / `$script:AppDir` / `$script:VersionFile` / `$script:EntryPoint` declared in Task 2 are referenced consistently in Task 6.

No issues found.
