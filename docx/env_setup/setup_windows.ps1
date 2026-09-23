#Requires -Version 5.1
<#
.SYNOPSIS
    DOCX Skill — Environment Setup for Windows (Win10/Win11)
.DESCRIPTION
    Detects the platform and verifies that all dependencies for the DOCX skill are present.
    The npm package docx is pre-installed and only verified, never installed.
    Fonts are downloaded from the CDN; pip supports a China mirror fallback.
#>

param(
    [switch]$UseChinaMirror
)

$ErrorActionPreference = "Continue"

function Write-Ok    { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Fail  { param($msg) Write-Host "  [FAIL] $msg" -ForegroundColor Red }
function Write-Warn  { param($msg) Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Info  { param($msg) Write-Host "  [->] $msg" -ForegroundColor Cyan }

# ── Resolve DOCX_SKILL_DIR ──
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DOCX_SKILL_DIR = Split-Path -Parent $ScriptDir
$env:DOCX_SKILL_DIR = $DOCX_SKILL_DIR

Write-Host "============================================"
Write-Host "  DOCX Skill - Environment Setup"
Write-Host "  (Windows)"
Write-Host "============================================"
Write-Host ""

# ── Step 1: Platform Detection ──
$WinVer = [System.Environment]::OSVersion.Version
$WinName = if ($WinVer.Build -ge 22000) { "Windows 11" } elseif ($WinVer.Build -ge 10240) { "Windows 10" } else { "Windows (older)" }
Write-Host "Platform: $WinName (Build $($WinVer.Build)), $([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture)"
Write-Host "DOCX_SKILL_DIR=$DOCX_SKILL_DIR"
Write-Host ""

# ── China mirror detection ──
$PipMirrorArgs = @()

if ($UseChinaMirror) {
    $global:UseCN = $true
} else {
    try {
        $null = Invoke-WebRequest -Uri "https://pypi.org" -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
        $global:UseCN = $false
    } catch {
        Write-Warn "pypi.org unreachable - enabling China mirror"
        $global:UseCN = $true
    }
}

if ($global:UseCN) {
    $PipMirrorArgs = @("-i", "https://pypi.tuna.tsinghua.edu.cn/simple", "--trusted-host", "pypi.tuna.tsinghua.edu.cn")
    Write-Info "China mirror enabled (pip: tuna)"
    Write-Host ""
}

$Errors = 0

# ── Step 2a: Node.js + npm ──
Write-Host "--- [1/6] Node.js + npm ---"
try {
    $nodeVer = & node --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "node ($nodeVer)"
    } else { throw "no node" }
} catch {
    Write-Fail "node not found (required - docx generation uses docx-js on Node)"
    Write-Info "Install option 1: winget install OpenJS.NodeJS.LTS"
    Write-Info "Install option 2: https://nodejs.org/"
    Write-Info "Install option 3: choco install nodejs-lts"
    if ($global:UseCN) {
        Write-Info "China alt: https://npmmirror.com/mirrors/node/"
    }
    $Errors++
}

try {
    $npmVer = & npm --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "npm ($npmVer)"
    } else { throw "no npm" }
} catch {
    Write-Fail "npm not found (installed with Node.js)"
    $Errors++
}
Write-Host ""

# ── Step 2b: npm package: docx (pre-installed — verify only, never install) ──
Write-Host "--- [2/6] npm package: docx ---"
$docxRoot = $null
try { $docxRoot = & npm root -g 2>$null | Select-Object -First 1 } catch { $docxRoot = $null }
$docxPkg = if ($docxRoot) { Join-Path $docxRoot "docx\package.json" } else { $null }
if ($docxPkg -and (Test-Path $docxPkg)) {
    $docxVer = (Get-Content $docxPkg -Raw | ConvertFrom-Json).version
    Write-Ok "docx ($docxVer)"
} else {
    Write-Fail "docx not found in $docxRoot (expected pre-installed)"
    Write-Info "Report the missing dependency - never run npm install in the working directory."
    $Errors++
}
Write-Host ""

# ── Step 2c: Python 3 + pip ──
Write-Host "--- [3/6] Python 3 + pip (post-processing) ---"
$PyCmd = $null
foreach ($cmd in @("python3", "python", "py")) {
    try {
        $ver = & $cmd --version 2>&1
        if ($ver -match "Python 3") {
            $PyCmd = $cmd
            Write-Ok "$cmd ($ver)"
            break
        }
    } catch {}
}
if (-not $PyCmd) {
    Write-Fail "Python 3 not found"
    Write-Info "Install option 1: winget install Python.Python.3.11"
    Write-Info "Install option 2: https://www.python.org/downloads/"
    Write-Info "Install option 3: choco install python3"
    if ($global:UseCN) {
        Write-Info "China alt: https://npmmirror.com/mirrors/python/"
    }
    $Errors++
}

if ($PyCmd) {
    try {
        $pipVer = & $PyCmd -m pip --version 2>&1
        if ($pipVer -match "pip") {
            Write-Ok "pip ($pipVer)"
        } else { throw "no pip" }
    } catch {
        Write-Fail "pip not found"
        Write-Info "Install: $PyCmd -m ensurepip --upgrade"
        $Errors++
    }
}
Write-Host ""

# ── Step 2d: Python packages ──
Write-Host "--- [4/6] Python packages (defusedxml) ---"
$PyPkgs = @(
    @{ Module = "defusedxml"; Package = "defusedxml" }
)

$MissingPy = @()
if ($PyCmd) {
    foreach ($pkg in $PyPkgs) {
        try {
            $result = & $PyCmd -c "import $($pkg.Module); print(getattr($($pkg.Module), '__version__', 'ok'))" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Ok "$($pkg.Package) ($result)"
            } else { throw "not installed" }
        } catch {
            Write-Fail "$($pkg.Package) not installed"
            $MissingPy += $pkg.Package
        }
    }

    if ($MissingPy.Count -gt 0) {
        Write-Info "Installing: $($MissingPy -join ', ')"
        $installArgs = @("-m", "pip", "install") + $PipMirrorArgs + $MissingPy
        try {
            & $PyCmd @installArgs 2>&1 | Out-Null
            Write-Ok "Installed: $($MissingPy -join ', ')"
        } catch {
            Write-Fail "pip install failed. Try: $PyCmd -m pip install $($PipMirrorArgs -join ' ') $($MissingPy -join ' ')"
            $Errors++
        }
    }
}
Write-Host ""

# ── Step 2e: Font Installation (from CDN) ──
Write-Host "--- [5/6] Font Installation ---"
$FontCdnBase = "https://z-cdn.chatglm.cn/office-skill/fonts"
$FontList = Join-Path $ScriptDir "font_list.txt"

$UserFontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
if (-not (Test-Path $UserFontDir)) { New-Item -ItemType Directory -Path $UserFontDir -Force | Out-Null }

$Marker = Join-Path $UserFontDir ".office-skill-fonts-installed"
if (Test-Path $Marker) {
    Write-Ok "Fonts already installed (marker found). To re-install, delete $Marker"
} else {
    if (-not (Test-Path $FontList)) {
        Write-Fail "Font list not found: $FontList"
        $Errors++
    } else {
        $lines = Get-Content $FontList | Where-Object { $_.Trim() -ne "" }
        $Total = $lines.Count
        $Installed = 0; $Skipped = 0; $Failed = 0
        Write-Info "Downloading $Total fonts from CDN..."
        
        foreach ($relPath in $lines) {
            $fname = Split-Path $relPath -Leaf
            $dest = Join-Path $UserFontDir $fname
            
            if (Test-Path $dest) {
                $Skipped++
                continue
            }
            
            $encoded = $relPath -replace '\[','%5B' -replace '\]','%5D' -replace ' ','%20'
            $url = "$FontCdnBase/$encoded"
            
            try {
                Invoke-WebRequest -Uri $url -OutFile $dest -TimeoutSec 30 -ErrorAction Stop
                $regPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
                $null = New-ItemProperty -Path $regPath -Name $fname -Value $dest -PropertyType String -Force -ErrorAction SilentlyContinue
                $Installed++
            } catch {
                Write-Warn "Failed to download: $relPath"
                $Failed++
                Remove-Item $dest -Force -ErrorAction SilentlyContinue
            }
        }
        
        if ($Failed -eq 0) {
            New-Item -ItemType File -Path $Marker -Force | Out-Null
            Write-Ok "Fonts: $Installed newly installed, $Skipped already present (target: $UserFontDir)"
        } else {
            Write-Warn "Fonts: $Installed installed, $Skipped skipped, $Failed failed (marker not written, will retry next run)"
            $Errors++
        }
    }
}

# Set DOCX_FONTS_DIR to user font directory (fonts are now installed there)
$DOCX_FONTS_DIR = $UserFontDir
$env:DOCX_FONTS_DIR = $DOCX_FONTS_DIR
Write-Host ""

# ── Step 2f: CJK Font Verification ──
Write-Host "--- [6/6] CJK Font Verification ---"
$CjkFound = $false
$FontsDir = Join-Path $env:WINDIR "Fonts"
$UserFontDir2 = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
$CjkFonts = @("NotoSansSC[wght].ttf", "NotoSerifSC-Regular.ttf")
foreach ($f in $CjkFonts) {
    if ((Test-Path (Join-Path $FontsDir $f)) -or (Test-Path (Join-Path $UserFontDir2 $f))) {
        Write-Ok "CJK font found: $f"
        $CjkFound = $true
        break
    }
}

if (-not $CjkFound) {
    Write-Warn "No CJK font verified yet - fonts were just installed, restart may be needed"
}
Write-Host ""

# ── Summary ──
Write-Host "============================================"
if ($Errors -eq 0) {
    Write-Host "  All dependencies OK."
} else {
    Write-Host "  $Errors issue(s) found. Fix them above."
}
Write-Host "  DOCX_SKILL_DIR=$DOCX_SKILL_DIR"
Write-Host "  DOCX_FONTS_DIR=$DOCX_FONTS_DIR (user font directory)"
Write-Host "============================================"
