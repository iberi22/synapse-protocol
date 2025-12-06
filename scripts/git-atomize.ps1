# git-atomize.ps1 - Split staged changes into atomic commits
# Part of Git-Core Protocol
#
# Usage:
#   .\git-atomize.ps1              # Interactive mode
#   .\git-atomize.ps1 -Analyze     # Analyze and show grouping plan
#   .\git-atomize.ps1 -Auto        # Auto-commit following suggestions
#   .\git-atomize.ps1 -DryRun      # Show plan without executing
#   .\git-atomize.ps1 -Strict      # Fail if mixed concerns detected
#   .\git-atomize.ps1 -CI          # CI mode, output JSON

param(
    [switch]$Analyze,
    [switch]$Auto,
    [switch]$DryRun,
    [switch]$Strict,
    [switch]$CI,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Show help
if ($Help) {
    Write-Host "git-atomize - Split staged changes into atomic commits"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\git-atomize.ps1              Interactive mode (default)"
    Write-Host "  .\git-atomize.ps1 -Analyze     Analyze and show grouping plan"
    Write-Host "  .\git-atomize.ps1 -Auto        Auto-commit following suggestions"
    Write-Host "  .\git-atomize.ps1 -DryRun      Show plan without executing"
    Write-Host "  .\git-atomize.ps1 -Strict      Fail if mixed concerns detected"
    Write-Host "  .\git-atomize.ps1 -CI          CI mode, output JSON"
    Write-Host ""
    exit 0
}

# Get staged files
function Get-StagedFiles {
    $files = git diff --cached --name-only 2>$null
    return $files
}

# Determine the concern/group for a file
function Get-FileGroup {
    param([string]$FilePath)
    
    $dir = Split-Path -Parent $FilePath
    $ext = [System.IO.Path]::GetExtension($FilePath).TrimStart('.')
    $basename = Split-Path -Leaf $FilePath
    
    # Normalize path separators
    $dir = $dir -replace '\\', '/'
    
    # By directory patterns
    switch -Wildcard ($dir) {
        ".github/workflows*" { return "ci:workflows" }
        ".github/actions*" { return "ci:actions" }
        ".github/ISSUE_TEMPLATE*" { return "chore:issue-templates" }
        ".github*" { return "ci:github" }
        "docs*" { return "docs:documentation" }
        "doc*" { return "docs:documentation" }
        "supabase/migrations*" { return "feat:db-migrations" }
        "supabase*" { return "feat:db" }
        "migrations*" { return "feat:db-migrations" }
        "tests*" { return "test:tests" }
        "test*" { return "test:tests" }
        "__tests__*" { return "test:tests" }
        "scripts*" { return "chore:scripts" }
        "src/components*" { return "feat:ui" }
        "src/api*" { return "feat:api" }
        "api*" { return "feat:api" }
        "src/utils*" { return "refactor:utils" }
        "utils*" { return "refactor:utils" }
        "lib*" { return "refactor:utils" }
        "src/hooks*" { return "feat:hooks" }
        "src/styles*" { return "style:styles" }
        "styles*" { return "style:styles" }
        "src/config*" { return "chore:config" }
        "config*" { return "chore:config" }
        ".ai*" { return "docs:architecture" }
    }
    
    # By file extension
    switch ($ext) {
        "sql" { return "feat:db" }
        "md" { return "docs:markdown" }
        { $_ -in "yml", "yaml" } {
            if ($dir -like ".github*") {
                return "ci:github"
            }
            return "chore:config"
        }
        "json" {
            switch -Wildcard ($basename) {
                "package.json" { return "chore:deps" }
                "package-lock.json" { return "chore:deps" }
                "tsconfig*.json" { return "chore:config" }
                "jsconfig*.json" { return "chore:config" }
                default { return "chore:data" }
            }
        }
        { $_ -in "css", "scss", "sass", "less" } { return "style:styles" }
    }
    
    # By file name patterns
    switch -Wildcard ($basename) {
        "*.test.*" { return "test:tests" }
        "*.spec.*" { return "test:tests" }
        "test_*" { return "test:tests" }
        "*_test.*" { return "test:tests" }
        "*-listener*" { return "feat:services" }
        "*-manager*" { return "feat:services" }
        "*-handler*" { return "feat:services" }
        "*-service*" { return "feat:services" }
        "*-hook*" { return "feat:hooks" }
        "use[A-Z]*" { return "feat:hooks" }
        ".gitignore" { return "chore:git" }
        ".gitattributes" { return "chore:git" }
        ".env*" { return "chore:env" }
        "*.env" { return "chore:env" }
        "Dockerfile*" { return "ci:docker" }
        "docker-compose*" { return "ci:docker" }
        ".dockerignore" { return "ci:docker" }
        "README*" { return "docs:root" }
        "CHANGELOG*" { return "docs:root" }
        "LICENSE*" { return "docs:root" }
        "CONTRIBUTING*" { return "docs:root" }
        "AGENTS.md" { return "chore:ai-config" }
        ".cursorrules" { return "chore:ai-config" }
        ".windsurfrules" { return "chore:ai-config" }
    }
    
    # Default based on extension for source files
    if ($ext -in "js", "ts", "jsx", "tsx", "py", "rb", "go", "rs", "java", "kt", "swift", "c", "cpp", "h", "hpp") {
        return "feat:source"
    }
    
    # Fallback
    return "chore:misc"
}

# Generate commit message for a group
function Get-CommitMessage {
    param(
        [string]$GroupKey,
        [int]$FileCount,
        [string[]]$Files
    )
    
    $parts = $GroupKey -split ":"
    $type = $parts[0]
    $scope = $parts[1]
    
    # Generate description based on group
    $description = switch ($scope) {
        "workflows" { "update CI/CD workflows" }
        "actions" { "update GitHub actions" }
        "github" { "update GitHub configuration" }
        "issue-templates" { "update issue templates" }
        "documentation" { "update documentation" }
        "db-migrations" { "add database migrations" }
        "db" { "update database configuration" }
        "tests" { "update tests" }
        "scripts" { "update scripts" }
        "ui" { "update UI components" }
        "api" { "update API endpoints" }
        "utils" { "update utility functions" }
        "hooks" { "update hooks" }
        "styles" { "update styles" }
        "config" { "update configuration" }
        "architecture" { "update architecture documentation" }
        "markdown" { "update markdown files" }
        "deps" { "update dependencies" }
        "data" { "update data files" }
        "services" { "update services" }
        "git" { "update git configuration" }
        "env" { "update environment configuration" }
        "docker" { "update Docker configuration" }
        "root" { "update root documentation" }
        "ai-config" { "update AI agent configuration" }
        "source" { "update source files" }
        "misc" { "update miscellaneous files" }
        default { "update $scope" }
    }
    
    # Format: type(scope): description
    if ($scope -in "misc", "source") {
        return "${type}: ${description}"
    }
    return "${type}(${scope}): ${description}"
}

# Main analysis function
function Invoke-Analysis {
    $stagedFiles = Get-StagedFiles
    
    if (-not $stagedFiles -or $stagedFiles.Count -eq 0) {
        if ($CI) {
            $errorOutput = @{
                error = "No staged files found"
                groups = @()
            }
            Write-Output ($errorOutput | ConvertTo-Json -Compress)
        } else {
            Write-Host "⚠️  No staged files found." -ForegroundColor Yellow
            Write-Host "Stage files first with: git add <files>"
        }
        return $null
    }
    
    # Ensure stagedFiles is an array
    if ($stagedFiles -is [string]) {
        $stagedFiles = @($stagedFiles)
    }
    
    $totalFiles = $stagedFiles.Count
    
    # Group files
    $groups = @{}
    
    foreach ($file in $stagedFiles) {
        if ([string]::IsNullOrWhiteSpace($file)) { continue }
        
        $group = Get-FileGroup -FilePath $file
        
        if (-not $groups.ContainsKey($group)) {
            $groups[$group] = @()
        }
        $groups[$group] += $file
    }
    
    $groupCount = $groups.Count
    
    # Check for mixed concerns in strict mode
    if ($Strict -and $groupCount -gt 1) {
        if ($CI) {
            $errorOutput = @{
                error = "Mixed concerns detected"
                group_count = $groupCount
                groups = @()
            }
            Write-Output ($errorOutput | ConvertTo-Json -Compress)
        } else {
            Write-Host "❌ STRICT MODE: Mixed concerns detected!" -ForegroundColor Red
            Write-Host "Found $groupCount different concern groups in staged files." -ForegroundColor Yellow
            Write-Host "Please separate changes into atomic commits."
        }
        exit 1
    }
    
    # Output in CI/JSON mode
    if ($CI) {
        $jsonGroups = @()
        foreach ($group in $groups.Keys) {
            $files = $groups[$group]
            $commitMsg = Get-CommitMessage -GroupKey $group -FileCount $files.Count -Files $files
            
            $jsonGroup = @{
                group = $group
                file_count = $files.Count
                commit_message = $commitMsg
                files = $files
            }
            $jsonGroups += $jsonGroup
        }
        
        $output = @{
            total_files = $totalFiles
            group_count = $groupCount
            groups = $jsonGroups
        }
        
        Write-Output ($output | ConvertTo-Json -Depth 3 -Compress)
        return
    }
    
    # Human-readable output
    Write-Host "📊 Analysis of " -ForegroundColor Cyan -NoNewline
    Write-Host "$totalFiles" -ForegroundColor Yellow -NoNewline
    Write-Host " staged files:" -ForegroundColor Cyan
    Write-Host ""
    
    $groupNum = 1
    foreach ($group in $groups.Keys) {
        $files = $groups[$group]
        $count = $files.Count
        $scope = ($group -split ":")[1]
        $commitMsg = Get-CommitMessage -GroupKey $group -FileCount $count -Files $files
        
        $plural = if ($count -ne 1) { "s" } else { "" }
        Write-Host "📦 Group ${groupNum}: " -ForegroundColor Blue -NoNewline
        Write-Host "$scope" -ForegroundColor Magenta -NoNewline
        Write-Host " ($count file$plural)"
        
        foreach ($f in $files) {
            if ([string]::IsNullOrWhiteSpace($f)) { continue }
            Write-Host "   - $f" -ForegroundColor Cyan
        }
        
        Write-Host "   Suggested commit: " -ForegroundColor Green -NoNewline
        Write-Host "$commitMsg" -ForegroundColor Yellow
        Write-Host ""
        
        $groupNum++
    }
    
    # Only return groups if not in analyze-only mode
    if (-not $Analyze -and -not $Strict) {
        return $groups
    }
}

# Execute commits for each group
function Invoke-Commits {
    param([hashtable]$Groups)
    
    if (-not $Groups -or $Groups.Count -eq 0) {
        return
    }
    
    # Store original staged files for dry-run restore
    $originalStagedFiles = Get-StagedFiles
    if ($originalStagedFiles -is [string]) {
        $originalStagedFiles = @($originalStagedFiles)
    }
    
    $totalGroups = $Groups.Count
    $currentGroup = 1
    
    foreach ($group in $Groups.Keys) {
        $files = $Groups[$group]
        $count = $files.Count
        $scope = ($group -split ":")[1]
        $commitMsg = Get-CommitMessage -GroupKey $group -FileCount $count -Files $files
        
        Write-Host "[$currentGroup/$totalGroups] " -ForegroundColor Blue -NoNewline
        Write-Host "$scope" -ForegroundColor Magenta
        Write-Host "   Files: $count"
        Write-Host "   Commit: " -NoNewline
        Write-Host "$commitMsg" -ForegroundColor Yellow
        
        if ($DryRun) {
            Write-Host "   (dry-run: would commit these files)" -ForegroundColor Cyan
        } else {
            # Unstage all files first
            git reset HEAD -- . 2>$null | Out-Null
            
            # Stage only files in this group
            foreach ($f in $files) {
                if ([string]::IsNullOrWhiteSpace($f)) { continue }
                git add $f 2>$null | Out-Null
            }
            
            if ($Auto) {
                git commit -m $commitMsg 2>$null | Out-Null
                Write-Host "   ✓ Committed" -ForegroundColor Green
            } else {
                # Interactive mode - ask for confirmation
                Write-Host "   Proceed with commit? [Y/n/e(dit message)] " -ForegroundColor Yellow -NoNewline
                $response = Read-Host
                
                switch ($response.ToLower()) {
                    "n" {
                        Write-Host "   Skipped" -ForegroundColor Cyan
                    }
                    "e" {
                        $newMsg = Read-Host "   Enter new message"
                        if (-not [string]::IsNullOrWhiteSpace($newMsg)) {
                            $commitMsg = $newMsg
                        }
                        git commit -m $commitMsg
                        Write-Host "   ✓ Committed" -ForegroundColor Green
                    }
                    default {
                        git commit -m $commitMsg
                        Write-Host "   ✓ Committed" -ForegroundColor Green
                    }
                }
            }
        }
        
        Write-Host ""
        $currentGroup++
    }
    
    if ($DryRun) {
        Write-Host "ℹ️  Dry run complete. No commits were made." -ForegroundColor Cyan
        # Re-stage all original files
        foreach ($file in $originalStagedFiles) {
            if ([string]::IsNullOrWhiteSpace($file)) { continue }
            git add $file 2>$null | Out-Null
        }
    } else {
        Write-Host "✅ All groups committed successfully!" -ForegroundColor Green
    }
}

# Main execution
if ($Analyze -or $CI -or $Strict) {
    Invoke-Analysis
} else {
    # Show analysis first, then execute
    $groups = Invoke-Analysis
    
    if ($null -eq $groups) {
        exit 0
    }
    
    if (-not $DryRun -and -not $Auto) {
        Write-Host "═══════════════════════════════════════" -ForegroundColor Yellow
        Write-Host "Proceed with atomic commits? [Y/n] " -ForegroundColor Yellow -NoNewline
        $proceed = Read-Host
        
        if ($proceed -match "^[Nn]$") {
            Write-Host "Aborted." -ForegroundColor Cyan
            exit 0
        }
    }
    
    Invoke-Commits -Groups $groups
}
