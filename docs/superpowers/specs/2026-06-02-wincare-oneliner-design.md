# WinCare Pro — One-Liner Installer (Design)

**Data:** 2026-06-02
**Autor:** José Lucas
**Status:** Aprovado para implementação
**Referência de UX:** `irm https://get.activated.win | iex`

---

## 1. Objetivo

Permitir que qualquer máquina Windows 10/11 instale e execute o WinCare Pro através de um único comando colado no PowerShell, no estilo do projeto `activated.win`. Quando o repositório receber uma nova release, a próxima execução do mesmo comando deve detectar a versão mais recente e atualizar automaticamente, preservando logs e configurações do usuário.

**Comando final (alvo):**

```powershell
irm https://raw.githubusercontent.com/joselucasdavidoliva-sudo/WinCare-PcruzTI/main/install.ps1 | iex
```

Domínio curto (ex: `get.wincare.app`) fica como passo opcional posterior — não bloqueia esta entrega.

---

## 2. Escopo

### Incluso
- Script `install.ps1` (bootstrap único) na raiz do repo
- Estratégia de versionamento via **GitHub Releases** + arquivo zip por versão
- Verificação de integridade via **SHA256**
- Modelo **híbrido com auto-update** (instala em pasta fixa, checa atualização a cada execução)
- Refatoração mínima do `WinCare.ps1` e `core/Config.ps1` para mover dados persistentes para fora da pasta de instalação
- Flags opcionais: `-Force` (reinstala), `-NoUpdate` (pula check), `-Uninstall`

### Fora de escopo (não fazer agora)
- Compra/configuração de domínio próprio
- Assinatura de código (code signing)
- Instalador MSI/MSIX
- Atualização automática agendada (Task Scheduler)
- GUI de instalação

---

## 3. Fluxo end-to-end

```
Usuário cola:
  irm https://raw.githubusercontent.com/joselucasdavidoliva-sudo/WinCare-PcruzTI/main/install.ps1 | iex
                            │
                            ▼
              install.ps1 baixado e carregado em memória
                            │
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
        Admin?         Consulta API     Hash SHA256
        (se não,       de Releases      do zip bate?
        relança          do GitHub
        com UAC)
              │             │             │
              └─────────────┼─────────────┘
                            ▼
        %LOCALAPPDATA%\WinCare-Pro\
            ├── app\              ← código (sobrescrito em update)
            │   ├── WinCare.ps1
            │   ├── core\ ui\ modules\
            ├── version.txt       ← marca v instalada
            ├── Config.json       ← preferências do usuário (preservado)
            └── output\
                ├── logs\         ← preservado
                └── Registry_Backup_*.reg
                            │
                            ▼
        Start-Process powershell.exe -File ...\app\WinCare.ps1 -Verb RunAs
```

---

## 4. Componentes

| Componente | Responsabilidade | Localização |
|---|---|---|
| `install.ps1` | Bootstrap: admin check, fetch release, verifica hash, extrai, lança | raiz do repo (servido via raw.githubusercontent.com) |
| `WinCare-Pro-v{X.Y.Z}.zip` | Empacotamento de toda a árvore do projeto por release | GitHub Releases assets |
| `SHA256SUMS` | Hash SHA256 do zip (assinatura de integridade) | GitHub Releases assets |
| `%LOCALAPPDATA%\WinCare-Pro\app\` | Cópia local executável (substituída em updates) | máquina do usuário |
| `%LOCALAPPDATA%\WinCare-Pro\version.txt` | Cache da versão instalada (`v1.0.1`) | máquina do usuário |
| `%LOCALAPPDATA%\WinCare-Pro\Config.json` | Preferências persistentes (fora de `app\` para sobreviver updates) | máquina do usuário |
| `%LOCALAPPDATA%\WinCare-Pro\output\` | Logs e backups do registro | máquina do usuário |
| `.github/workflows/release.yml` | Automação opcional: empacota zip + cria release ao dar push de tag | repo |

---

## 5. Lógica do `install.ps1` (pseudocódigo)

```
param(
    [switch]$Force,       # ignora cache de versão, reinstala
    [switch]$NoUpdate,    # se já existe, executa sem checar atualização
    [switch]$Uninstall    # remove %LOCALAPPDATA%\WinCare-Pro inteiro
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- 0. Constantes ---
$Repo       = 'joselucasdavidoliva-sudo/WinCare-PcruzTI'
$InstallDir = Join-Path $env:LOCALAPPDATA 'WinCare-Pro'
$AppDir     = Join-Path $InstallDir 'app'
$VersionFile= Join-Path $InstallDir 'version.txt'
$EntryPoint = Join-Path $AppDir 'WinCare.ps1'

# --- 1. Admin elevation ---
if (-not (IsAdmin)) {
    Start-Process powershell -Verb RunAs -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-Command', "irm https://raw.githubusercontent.com/$Repo/main/install.ps1 | iex"
    )
    exit
}

# --- 2. Uninstall short-circuit ---
if ($Uninstall) { Remove-Item $InstallDir -Recurse -Force; exit }

# --- 3. Resolve versão alvo ---
$installed = if (Test-Path $VersionFile) { Get-Content $VersionFile -Raw } else { $null }
$skipUpdate = $NoUpdate -and (Test-Path $EntryPoint)

if (-not $skipUpdate) {
    $rel    = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest"
    $latest = $rel.tag_name                                       # ex: "v1.0.1"
    $zipAsset = $rel.assets | Where-Object { $_.name -like '*.zip' }      | Select-Object -First 1
    $sumAsset = $rel.assets | Where-Object { $_.name -eq 'SHA256SUMS' }   | Select-Object -First 1

    $needsUpdate = $Force -or ($installed -ne $latest) -or (-not (Test-Path $EntryPoint))

    if ($needsUpdate) {
        # 3a. Download
        $tmpZip = Join-Path $env:TEMP "wincare-$latest.zip"
        Invoke-WebRequest $zipAsset.browser_download_url -OutFile $tmpZip

        # 3b. Verifica hash
        $expectedSums = (Invoke-WebRequest $sumAsset.browser_download_url).Content
        $actualHash   = (Get-FileHash $tmpZip -Algorithm SHA256).Hash
        if ($expectedSums -notmatch $actualHash) { throw 'SHA256 mismatch — abortando' }

        # 3c. Backup atomic swap
        if (Test-Path $AppDir) {
            $backup = "$AppDir.old"
            if (Test-Path $backup) { Remove-Item $backup -Recurse -Force }
            Rename-Item $AppDir $backup
        }
        try {
            Expand-Archive $tmpZip -DestinationPath $AppDir -Force
            Set-Content $VersionFile $latest -NoNewline
            if (Test-Path "$AppDir.old") { Remove-Item "$AppDir.old" -Recurse -Force }
        } catch {
            if (Test-Path "$AppDir.old") {
                Remove-Item $AppDir -Recurse -Force -EA SilentlyContinue
                Rename-Item "$AppDir.old" $AppDir
            }
            throw
        } finally {
            Remove-Item $tmpZip -Force -EA SilentlyContinue
        }
    }
}

# --- 4. Launch ---
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $EntryPoint
```

---

## 6. Mudanças no código existente

### 6.1 `WinCare.ps1` (linhas 9–15)

Mover `LogPath` e `ConfigPath` para fora de `$PSScriptRoot`:

```powershell
$Global:WC = @{
    Version    = '1.0.0'
    AppName    = 'WinCare Pro'
    RootPath   = $PSScriptRoot
    DataPath   = Join-Path $env:LOCALAPPDATA 'WinCare-Pro'      # NOVO
    LogPath    = Join-Path $env:LOCALAPPDATA 'WinCare-Pro\output\logs'
    ConfigPath = Join-Path $env:LOCALAPPDATA 'WinCare-Pro\Config.json'
}
```

Razão: `app\` é sobrescrito a cada update. Logs e config precisam estar fora dele.

### 6.2 `core/Config.ps1`

Em `Initialize-Config`, se `Config.json` não existe no novo `ConfigPath`, copiar o template de `$Global:WC.RootPath\core\Config.json` como semente inicial.

### 6.3 Novo: `install.ps1` (raiz)

Conforme seção 5.

### 6.4 Novo (opcional): `.github/workflows/release.yml`

Dispara em push de tag `v*`, empacota o repo em zip, gera `SHA256SUMS`, cria release.

```yaml
name: Release
on:
  push:
    tags: ['v*']
jobs:
  release:
    runs-on: windows-latest
    permissions: { contents: write }
    steps:
      - uses: actions/checkout@v4
      - shell: pwsh
        run: |
          $tag = '${{ github.ref_name }}'
          $zip = "WinCare-Pro-$tag.zip"
          Compress-Archive -Path WinCare.ps1,core,ui,modules,README.md,Abrir_WinCare_Pro.bat -DestinationPath $zip
          (Get-FileHash $zip -Algorithm SHA256).Hash + "  $zip" | Out-File SHA256SUMS -Encoding ascii
      - uses: softprops/action-gh-release@v2
        with:
          files: |
            WinCare-Pro-*.zip
            SHA256SUMS
```

---

## 7. Segurança

| Risco | Mitigação |
|---|---|
| Man-in-the-middle no download | TLS 1.2 forçado; raw.githubusercontent é HTTPS-only |
| Zip corrompido ou trocado | Verificação SHA256 obrigatória antes de extrair |
| Update parcial deixa app quebrado | Swap atômico: renomeia `app\` → `app.old\` antes; em erro, restaura |
| Execução sem privilégio | Auto-eleva via `Start-Process -Verb RunAs` re-invocando o one-liner |
| Bypass de ExecutionPolicy | `-ExecutionPolicy Bypass` somente no escopo do processo, conforme padrão Chocolatey/Scoop |
| Repo comprometido | Fora do escopo desta entrega — futuramente: code signing |

---

## 8. Critérios de aceitação

1. Em máquina Windows 10/11 limpa, colar o one-liner no PowerShell baixa, instala e abre a UI do WinCare Pro sem intervenção (exceto prompt UAC).
2. Após publicar release `v1.0.1`, rodar o mesmo one-liner em máquina já com `v1.0.0` detecta diferença, atualiza `app\` e mantém `Config.json` + `output\logs\` intactos.
3. `& ([scriptblock]::Create((irm ...))) -NoUpdate` lança a versão local sem consultar a API do GitHub.
4. `& ([scriptblock]::Create((irm ...))) -Uninstall` remove completamente `%LOCALAPPDATA%\WinCare-Pro`.
5. Se SHA256 não bate, o instalador aborta com mensagem clara e **não** sobrescreve a instalação anterior.

---

## 9. Workflow do mantenedor (você)

Para lançar uma nova versão:

```powershell
# 1. Faz alterações no código, commita normalmente
git add . ; git commit -m "v1.0.1: correção de bug X"

# 2. Cria a tag e dá push
git tag v1.0.1
git push origin main --tags

# 3a. Se o workflow GH Actions estiver ativo: pronto, release é criado sozinho
# 3b. Manualmente (sem workflow):
Compress-Archive -Path WinCare.ps1,core,ui,modules,README.md -DestinationPath WinCare-Pro-v1.0.1.zip
(Get-FileHash WinCare-Pro-v1.0.1.zip -Algorithm SHA256).Hash | Out-File SHA256SUMS -Encoding ascii
gh release create v1.0.1 WinCare-Pro-v1.0.1.zip SHA256SUMS --notes "v1.0.1"
```

---

## 10. Não-objetivos / decisões deliberadas

- **Não usar `Invoke-Expression` em conteúdo de terceiros.** Apenas o `install.ps1` do próprio repo é executado via `iex`. Tudo mais é arquivo extraído e lançado com `-File`.
- **Não empacotar bundle único.** A arquitetura WinForms + multi-arquivo do WinCare não comporta execução in-memory sem refactor profundo. Veja Opção C rejeitada.
- **Não preservar `app.old\`.** Após swap bem-sucedido, é apagado. Rollback manual é feito reinstalando a tag anterior.
- **Não há telemetria.** Nenhum dado é enviado ao mantenedor.
