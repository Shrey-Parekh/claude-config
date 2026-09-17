<#
.SYNOPSIS
    Copy portable Claude Code config from ~/.claude into this repo.
.DESCRIPTION
    Only copies known-portable files/dirs (CLAUDE.md, RTK.md, settings.json, skills/).
    Never touches credentials. Backs up repo files before overwriting.
    Does not delete anything from ~/.claude.
#>

$ErrorActionPreference = "Stop"

$ClaudeDir = Join-Path $HOME ".claude"
$RepoRoot  = Split-Path -Parent $PSScriptRoot
$RepoClaude = Join-Path $RepoRoot ".claude"
$BackupDir = Join-Path $RepoRoot ("scripts\.backups\" + (Get-Date -Format "yyyyMMdd-HHmmss"))

Write-Host "==> Syncing portable config: $ClaudeDir -> $RepoClaude" -ForegroundColor Cyan

if (-not (Test-Path $ClaudeDir)) {
    Write-Host "ERROR: $ClaudeDir not found." -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

function Backup-IfExists($path) {
    if (Test-Path $path) {
        $rel = Resolve-Path $path -Relative
        $dest = Join-Path $BackupDir ($rel -replace '^\.[\\/]', '')
        New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
        Copy-Item -Path $path -Destination $dest -Recurse -Force
    }
}

# --- CLAUDE.md ---
$src = Join-Path $ClaudeDir "CLAUDE.md"
if (Test-Path $src) {
    Backup-IfExists (Join-Path $RepoClaude "CLAUDE.md")
    Copy-Item $src (Join-Path $RepoClaude "CLAUDE.md") -Force
    Write-Host "  copied CLAUDE.md"
}

# --- RTK.md ---
$src = Join-Path $ClaudeDir "RTK.md"
if (Test-Path $src) {
    Backup-IfExists (Join-Path $RepoClaude "RTK.md")
    Copy-Item $src (Join-Path $RepoClaude "RTK.md") -Force
    Write-Host "  copied RTK.md"
}

# --- settings.json ---
$src = Join-Path $ClaudeDir "settings.json"
if (Test-Path $src) {
    Backup-IfExists (Join-Path $RepoClaude "settings.json")
    Copy-Item $src (Join-Path $RepoClaude "settings.json") -Force
    Write-Host "  copied settings.json"
    Write-Host "  NOTE: review settings.json for API keys/tokens before committing." -ForegroundColor Yellow
}

# --- skills/ (excluding 'learned' which is machine-local scratch) ---
$srcSkills = Join-Path $ClaudeDir "skills"
if (Test-Path $srcSkills) {
    Get-ChildItem $srcSkills -Directory | Where-Object { $_.Name -ne "learned" } | ForEach-Object {
        $dest = Join-Path $RepoClaude "skills\$($_.Name)"
        Backup-IfExists $dest
        New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
        Copy-Item $_.FullName $dest -Recurse -Force
        Write-Host "  copied skills/$($_.Name)"
    }
}

# --- commands/ / agents/ / hooks/ (only if they exist) ---
foreach ($dir in @("commands", "agents", "hooks")) {
    $src = Join-Path $ClaudeDir $dir
    if (Test-Path $src) {
        $dest = Join-Path $RepoClaude $dir
        Backup-IfExists $dest
        Copy-Item $src $dest -Recurse -Force
        Write-Host "  copied $dir/"
    }
}

Write-Host ""
Write-Host "==> Done. Backup of previous repo state: $BackupDir" -ForegroundColor Green
Write-Host "==> Review changes with 'git status' / 'git diff' before committing." -ForegroundColor Yellow
Write-Host "==> Double-check no secrets were pulled in (API keys, tokens, credentials)." -ForegroundColor Yellow
