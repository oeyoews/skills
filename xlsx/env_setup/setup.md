# XLSX Skill — Environment Setup Guide

This document contains full platform-specific instructions for setting up the XLSX skill environment.
The model should read this file when first-time setup is needed.

---

## Step 1: Platform Detection

Detect the OS and set core variables:

### macOS / Linux (bash/zsh)

```bash
OS="$(uname -s)"   # Darwin = macOS, Linux = Linux
ARCH="$(uname -m)" # x86_64 or arm64

XLSX_SKILL_DIR="<skill_directory>"
export XLSX_SKILL_DIR
```

### Windows (PowerShell, Win10/Win11)

```powershell
$WinVer = [System.Environment]::OSVersion.Version
$Arch   = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture

$env:XLSX_SKILL_DIR = "<skill_directory>"
```

---

## Step 2: Dependency Check & Install

Run the platform-appropriate setup script:

| Platform | Command |
|----------|---------|
| macOS / Linux | `bash "$XLSX_SKILL_DIR/env_setup/setup_mac_linux.sh"` |
| Windows | `powershell -ExecutionPolicy Bypass -File "$env:XLSX_SKILL_DIR\env_setup\setup_windows.ps1"` |

### Required Dependencies

| Category | Package | Purpose |
|----------|---------|---------|
| Runtime | Python 3 + pip | Spreadsheet generation and processing |
| Python pkg | openpyxl | Read/write .xlsx files |
| Python pkg | XlsxWriter | High-performance .xlsx creation |
| Font | CJK fonts (pre-installed in /usr/share/fonts) | Chinese text in spreadsheets |

### Manual Install by Platform

#### macOS

```bash
brew install python3
python3 -m pip install openpyxl XlsxWriter
```

#### Linux (Debian/Ubuntu)

```bash
sudo apt install python3 python3-pip
python3 -m pip install openpyxl XlsxWriter
```

#### Windows (PowerShell)

```powershell
winget install Python.Python.3.11
python -m pip install openpyxl XlsxWriter
```

Alternative Windows package managers:
- `choco install python3`
- `scoop install python`

### What is deliberately not installed

There is no spreadsheet calculation engine and no PDF renderer in this environment, and neither can
be installed. Consequences to plan around:

- Formulas are never recalculated for you — verify numbers in Python (`audit` command in
  `xlsx.py`) and write computed values where a check needs to read them.
- `.xlsx` → PDF is unavailable: deliver the workbook and let the user print it themselves.
- CSV/TSV → `.xlsx` goes through pandas/openpyxl directly; no external converter is involved.

---

## Step 3: Font Verification

Fonts are pre-installed in the system font directory `/usr/share/fonts/`.

- **Font base**: `/usr/share/fonts/`
- **Font list**: `env_setup/font_list.txt` (79 fonts, one relative path per line)
- The setup script reads `font_list.txt` and verifies each font exists under `/usr/share/fonts/`

### Font Directory Structure (79 fonts)

| Directory | Count | Description |
|-----------|-------|-------------|
| `chinese/` | 23 | Noto Sans SC, Sarasa Mono SC, Liberation fallbacks |
| `liberation/` | 12 | Liberation Sans/Serif/Mono — MS-metric-compatible |
| `freefont/` | 12 | FreeSans/FreeSerif/FreeMono — open-source fallback |
| `noto-serif-sc/` | 9 | Noto Serif SC — Chinese serif (variable + 8 static weights) |
| `dejavu/` | 8 | DejaVu Sans/Serif/Mono — Latin/symbol fallback |
| `english/` | 8 | Tinos, Carlito, Calibri |
| `lxgw-wenkai/` | 6 | LXGW WenKai — Chinese handwriting style |
| `wqy/` | 1 | WenQuanYi Zen Hei — CJK fallback |

### Verify Fonts Manually

Check if a font exists:

```bash
ls /usr/share/fonts/truetype/chinese/NotoSansSC\[wght\].ttf
```

Verify all fonts in the list:

```bash
while read f; do
    [ -f "$f" ] && echo "OK: $f" || echo "MISSING: $f"
done < env_setup/font_list.txt
```

### Post-Setup Variable

`FONT_DIR` is set to the system font directory:

| Value | Path |
|-------|------|
| `FONT_DIR` | `/usr/share/fonts` |

---

## China Network Fallback

If default sources are unreachable, use China mirrors:

### pip (Tsinghua mirror)

```bash
python3 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple \
  --trusted-host pypi.tuna.tsinghua.edu.cn \
  openpyxl XlsxWriter
```

### Windows (PowerShell) China mirrors

```powershell
python -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --trusted-host pypi.tuna.tsinghua.edu.cn openpyxl XlsxWriter
```

### Installer downloads (China)

| Software | China Mirror |
|----------|-------------|
| Python | https://npmmirror.com/mirrors/python/ |

---
