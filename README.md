# 🛡️ WinCare Pro — Suite de Manutenção Windows

**Versão:** 1.0.0 | **Requisitos:** Windows 10/11 · PowerShell 5.1+

---

## 📁 Estrutura do Projeto

```
WinCare-Pro/
├── WinCare.ps1                   ← Entry point (execute este)
├── README.md
├── core/
│   ├── Config.ps1                ← Configurações persistentes (JSON)
│   ├── Logger.ps1                ← Log centralizado (arquivo + UI)
│   └── UIBuilder.ps1             ← Interface WinForms + navegação
├── modules/
│   ├── 01_WindowsMaintenance.ps1 ← Manutenção corretiva/preventiva
│   ├── 02_WindowsUpdate.ps1      ← Windows Update recursivo
│   └── 03_to_09_modules.ps1     ← BugFixer, Office, Registry,
│                                    AppRemover, HealthCheck,
│                                    ComponentTest, WingetManager
├── ui/
│   ├── Theme.ps1                 ← Paleta de cores e fontes
│   ├── ProgressPanel.ps1         ← Log em tempo real + ProgressBar
│   ├── LogViewer.ps1             ← Visualizador de logs
│   └── Dashboard.ps1             ← Tela inicial
└── output/
    └── logs/                     ← Logs gerados automaticamente
```

---

## 🚀 Como Executar

### Opção 1 — Duplo clique (recomendado)
Crie um atalho para `WinCare.ps1` com o target:
```
powershell.exe -ExecutionPolicy Bypass -File "C:\WinCare-Pro\WinCare.ps1"
```

### Opção 2 — PowerShell direto
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\WinCare.ps1
```

> O aplicativo eleva automaticamente para Administrador via UAC se necessário.

---

## 🔧 Módulos Disponíveis

| # | Módulo | Principais Funcionalidades |
|---|--------|---------------------------|
| 01 | **Manutenção Windows** | SFC, DISM, Limpeza Temp, Reset Rede, Reparo Boot, Serviços |
| 02 | **Windows Update** | PSWindowsUpdate, loop recursivo, drivers |
| 03 | **Bug Fixer** | WMI, Store, .NET, GPO, Permissões, Cache de ícones |
| 04 | **Office Suite** | Repair Office, Teams cache, OneDrive reset, SharePoint resync |
| 05 | **Registro** | Backup automático, entradas startup inválidas, MUICache |
| 06 | **App Remover** | Lista Win32+UWP, desinstala com limpeza de resíduos |
| 07 | **Health Check** | Score 0–100, CPU/RAM/Disco/Defender, Event Log |
| 08 | **Testes** | CPU, RAM, Velocidade disco, GPU, Rede, Bateria, mdsched |
| 09 | **Winget** | Busca, instalação, atualização em lote, lista essenciais |

---

## ⚙️ Dependências Opcionais

| Dependência | Uso | Auto-instalado? |
|-------------|-----|-----------------|
| `PSWindowsUpdate` | Módulo 02 — Windows Update | ✅ Sim |
| `winget` | Módulo 09 — Winget Manager | Já incluso no Win 10/11 |

---

## 📋 Logs

Logs são salvos automaticamente em `output\logs\WinCare_YYYY-MM-DD.log`.

Backups do registro ficam em `output\logs\Registry_Backup_*.reg`.

---

## 🔒 Segurança

- Pontos de restauração são criados **automaticamente** antes de operações de risco
- Backup do registro antes de qualquer modificação
- Operações destrutivas pedem confirmação dupla

---

## 📌 Notas Técnicas

- Threading via `RunspacePool` garante que a UI nunca trava
- Compatível com PS 5.1 (nativo Win10/11) e PS 7+
- Sem dependências externas para o core (apenas WinForms nativo .NET)
