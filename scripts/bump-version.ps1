# bump-version.ps1 - Increment Git-Core Protocol version
# Usage: .\scripts\bump-version.ps1 [-Type major|minor|patch]

param(
    [ValidateSet("major", "minor", "patch")]
    [string]$Type = "patch"
)

$VersionFile = ".git-core-protocol-version"

# Get current version
if (-not (Test-Path $VersionFile)) {
    "1.0.0" | Out-File $VersionFile -NoNewline
}

$Current = (Get-Content $VersionFile -Raw).Trim()
$Parts = $Current -split '\.'
$Major = [int]$Parts[0]
$Minor = [int]$Parts[1]
$Patch = [int]$Parts[2]

switch ($Type) {
    "major" {
        $Major++
        $Minor = 0
        $Patch = 0
    }
    "minor" {
        $Minor++
        $Patch = 0
    }
    "patch" {
        $Patch++
    }
}

$NewVersion = "$Major.$Minor.$Patch"

# Update version file
$NewVersion | Out-File $VersionFile -NoNewline -Encoding utf8

Write-Host "🔄 Version Bumped" -ForegroundColor Cyan
Write-Host "   $Current → $NewVersion" -ForegroundColor Green
Write-Host ""

# Update AGENTS.md version reference
if (Test-Path "AGENTS.md") {
    $content = Get-Content "AGENTS.md" -Raw
    $content = $content -replace "Protocol Version: .*", "Protocol Version: $NewVersion"
    $content | Out-File "AGENTS.md" -NoNewline -Encoding utf8
    Write-Host "✓ Updated AGENTS.md" -ForegroundColor Green
}

# Show git commands
Write-Host ""
Write-Host "📋 To commit this version bump:" -ForegroundColor Yellow
Write-Host "   git add $VersionFile AGENTS.md"
Write-Host "   git commit -m `"chore: bump version to v$NewVersion`""
Write-Host "   git tag -a v$NewVersion -m `"Release v$NewVersion`""
Write-Host "   git push origin main --tags"
