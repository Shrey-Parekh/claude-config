<#
.SYNOPSIS
    Apply this repo's portable Claude Code config onto ~/.claude on this machine.
.DESCRIPTION
    Copies CLAUDE.md, RTK.md, settings.json, and skills/ from this repo into ~/.claude.
    Backs up any existing files in ~/.claude before overwriting them.
    Never deletes anything in ~/.claude that this repo doesn't manage.
    settings.json is copied as-is (not merged) - review it, especially the
    "hooks" section which contains absolute paths, before trusting it on a new machine.
#>

$ErrorActionPreference = "Stop"

$RepoRoot   = Split-Path -Parent $PSScriptRoot
$RepoClaude = Join-Path $RepoRoot ".claude"
$ClaudeDir  = Join-Path $HOME ".claude"
$BackupDir  = Join-Path $ClaudeDir ("backups\sync-from-repo-" + (Get-Date -Format "yyyyMMdd-HHmmss"))

Write-Host "==> Applying repo config: $RepoClaude -> $ClaudeDir" -ForegroundColor Cyan

if (-not (Test-Path $RepoClaude)) {
    Write-Host "ERROR: $RepoClaude not found. Run this from inside the cloned repo." -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

function Backup-IfExists($path) {
    if (Test-Path $path) {
        $name = Split-Path $path -Leaf
        Copy-Item -Path $path -Destination (Join-Path $BackupDir $name) -Recurse -Force
        Write-Host "  backed up existing $name"
    }
}

foreach ($file in @("CLAUDE.md", "RTK.md", "settings.json")) {
    $src = Join-Path $RepoClaude $file
    if (Test-Path $src) {
        $dest = Join-Path $ClaudeDir $file
        Backup-IfExists $dest
        Copy-Item $src $dest -Force
        Write-Host "  applied $file"
    }
}

foreach ($dir in @("skills", "commands", "agents", "hooks")) {
    $srcDir = Join-Path $RepoClaude $dir
    if (Test-Path $srcDir) {
        Get-ChildItem $srcDir -Directory | ForEach-Object {
            $dest = Join-Path $ClaudeDir "$dir\$($_.Name)"
            Backup-IfExists $dest
            New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
            Copy-Item $_.FullName $dest -Recurse -Force
            Write-Host "  applied $dir/$($_.Name)"
        }
    }
}

Write-Host ""
Write-Host "==> Done. Backup of anything overwritten: $BackupDir" -ForegroundColor Green
Write-Host "==> settings.json was copied as-is - check the 'hooks' commands use paths valid on THIS machine." -ForegroundColor Yellow
Write-Host "==> Secrets are never included in this repo; sign in / configure API keys separately on this machine." -ForegroundColor Yellow
