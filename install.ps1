#Requires -Version 7.0
<#
.SYNOPSIS
    Install DotfilesManager module and set up the 'dot' alias.
.DESCRIPTION
    Creates a symlink from PSModulePath to this project's DotfilesManager directory
    and adds a 'dot' alias to the PowerShell profile.
#>

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "  Dotfiles Manager Installer" -ForegroundColor Cyan
Write-Host "  $([string]::new([char]0x2500, 28))" -ForegroundColor DarkGray
Write-Host ""

# Verify PowerShell 7+
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "  x PowerShell 7+ required. Current: $($PSVersionTable.PSVersion)" -ForegroundColor Red
    exit 1
}
Write-Host "  $([char]0x2713) PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Green

# Paths
$scriptDir = $PSScriptRoot
$sourceModule = Join-Path $scriptDir 'DotfilesManager'
$modulesDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell' 'Modules'
$targetLink = Join-Path $modulesDir 'DotfilesManager'

# Verify source exists
if (-not (Test-Path (Join-Path $sourceModule 'DotfilesManager.psd1'))) {
    Write-Host "  x Module source not found at: $sourceModule" -ForegroundColor Red
    exit 1
}

# Create Modules directory if needed
if (-not (Test-Path $modulesDir)) {
    New-Item -ItemType Directory -Path $modulesDir -Force | Out-Null
    Write-Host "  $([char]0x2713) Created: $modulesDir" -ForegroundColor Green
}

# Create symlink (or update existing)
if (Test-Path $targetLink) {
    $existing = Get-Item $targetLink
    if ($existing.LinkType -eq 'SymbolicLink' -or $existing.LinkType -eq 'Junction') {
        # Check if it already points to the right place
        $existingTarget = $existing.Target
        if ($existingTarget -eq $sourceModule) {
            Write-Host "  $([char]0x2713) Symlink already correct: $targetLink" -ForegroundColor Green
        } else {
            Remove-Item $targetLink -Force
            New-Item -ItemType SymbolicLink -Path $targetLink -Target $sourceModule | Out-Null
            Write-Host "  $([char]0x2713) Updated symlink: $targetLink -> $sourceModule" -ForegroundColor Green
        }
    } else {
        Write-Host "  ! Non-symlink exists at $targetLink — skipping (remove manually if needed)" -ForegroundColor Yellow
    }
} else {
    New-Item -ItemType SymbolicLink -Path $targetLink -Target $sourceModule | Out-Null
    Write-Host "  $([char]0x2713) Created symlink: $targetLink -> $sourceModule" -ForegroundColor Green
}

# Verify module loads
try {
    Import-Module DotfilesManager -Force -ErrorAction Stop
    Write-Host "  $([char]0x2713) Module loads successfully" -ForegroundColor Green
} catch {
    Write-Host "  x Module failed to load: $_" -ForegroundColor Red
    exit 1
}

# Add alias to profile
$profilePath = $PROFILE.CurrentUserCurrentHost
$aliasLine = "Set-Alias -Name dot -Value Invoke-Dot"

if (Test-Path $profilePath) {
    $profileContent = Get-Content $profilePath -Raw
} else {
    $profileContent = ''
    $profileDir = Split-Path $profilePath -Parent
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
}

if ($profileContent -match 'Set-Alias\s+-Name\s+dot\s+-Value\s+Invoke-Dot') {
    Write-Host "  $([char]0x2713) Alias 'dot' already in profile" -ForegroundColor Green
} else {
    $newLine = "`n# Dotfiles Manager`n$aliasLine`n"
    Add-Content -Path $profilePath -Value $newLine -Encoding UTF8
    Write-Host "  $([char]0x2713) Added 'dot' alias to $profilePath" -ForegroundColor Green
}

# Set alias for current session
Set-Alias -Name dot -Value Invoke-Dot -Scope Global

Write-Host ""
Write-Host "  $([char]0x2713) Installation complete!" -ForegroundColor Green
Write-Host "  Run 'dot init' to get started." -ForegroundColor Gray
Write-Host ""
