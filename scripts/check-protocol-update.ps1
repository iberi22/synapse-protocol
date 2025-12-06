# scripts/check-protocol-update.ps1
# 🔍 Check if Git-Core Protocol needs updating (PowerShell)
#
# Usage:
#   .\scripts\check-protocol-update.ps1          # Check only
#   .\scripts\check-protocol-update.ps1 -Update  # Check and update
#   .\scripts\check-protocol-update.ps1 -Force   # Force update

param(
    [switch]$Update,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Config
$TEMPLATE_REPO = "iberi22/Git-Core-Protocol"
$BASE_URL = "https://raw.githubusercontent.com/$TEMPLATE_REPO/main"
$VERSION_FILE = ".git-core-protocol-version"

Write-Host "🔍 Checking Git-Core Protocol version..." -ForegroundColor Cyan

# Get current version
if (Test-Path $VERSION_FILE) {
    $CURRENT_VERSION = (Get-Content $VERSION_FILE -Raw).Trim()
} else {
    $CURRENT_VERSION = "0.0.0"
}
Write-Host "   Current: $CURRENT_VERSION" -ForegroundColor Yellow

# Get latest version
try {
    $LATEST_VERSION = (Invoke-WebRequest -Uri "$BASE_URL/$VERSION_FILE" -UseBasicParsing).Content.Trim()
} catch {
    Write-Host "❌ Could not fetch latest version" -ForegroundColor Red
    exit 1
}
Write-Host "   Latest:  $LATEST_VERSION" -ForegroundColor Green

# Compare versions
if ($CURRENT_VERSION -eq $LATEST_VERSION -and -not $Force) {
    Write-Host "✅ Git-Core Protocol is up to date!" -ForegroundColor Green
    exit 0
}

# Update needed
Write-Host "⚠️  Update available: $CURRENT_VERSION → $LATEST_VERSION" -ForegroundColor Yellow

if (-not $Update -and -not $Force) {
    Write-Host "`nRun with -Update to apply updates" -ForegroundColor Cyan
    Write-Host "Run with -Force to force update" -ForegroundColor Cyan
    exit 0
}

# Perform update
Write-Host "`n📥 Downloading protocol files..." -ForegroundColor Cyan

# Files to download
$FILES = @(
    "AGENTS.md",
    ".cursorrules",
    ".windsurfrules",
    ".github/copilot-instructions.md",
    ".git-core-protocol-version"
)

# Ensure directories exist
New-Item -ItemType Directory -Force -Path ".github" | Out-Null

# Download and apply files
Write-Host "`n📦 Applying updates..." -ForegroundColor Cyan

foreach ($file in $FILES) {
    try {
        $content = (Invoke-WebRequest -Uri "$BASE_URL/$file" -UseBasicParsing).Content

        # Ensure parent directory exists
        $dir = Split-Path -Parent $file
        if ($dir -and -not (Test-Path $dir)) {
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
        }

        Set-Content -Path $file -Value $content -NoNewline -Encoding UTF8
        Write-Host "   ✓ $file" -ForegroundColor Green
    } catch {
        Write-Host "   ✗ $file (failed)" -ForegroundColor Red
    }
}

Write-Host "`n✅ Git-Core Protocol updated to $LATEST_VERSION" -ForegroundColor Green
Write-Host "`n📝 Don't forget to commit the changes:" -ForegroundColor Yellow
Write-Host "   git add -A; git commit -m `"chore: 🔄 Update Git-Core Protocol to $LATEST_VERSION`"" -ForegroundColor White
