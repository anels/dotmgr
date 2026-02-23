function Get-DotConfigPath {
    Join-Path $HOME '.dotfiles' 'config.json'
}

function Get-DotConfig {
    $path = Get-DotConfigPath
    if (-not (Test-Path $path)) {
        throw "Dotfiles not initialized. Run 'dot init' first."
    }
    try {
        Get-Content $path -Raw | ConvertFrom-Json
    } catch {
        throw "Config file is corrupted: $path`nRun 'dot doctor' to diagnose."
    }
}

function Set-DotConfig {
    param([PSCustomObject]$Config)
    $path = Get-DotConfigPath
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $Config | ConvertTo-Json -Depth 10 | Set-Content $path -Encoding UTF8
}

function New-DotConfig {
    param(
        [string]$RepoPath,
        [string]$WorkTree
    )
    [PSCustomObject]@{
        version         = '1.0'
        repoPath        = $RepoPath
        workTree        = $WorkTree
        trackedFolders  = @()
        excludePatterns = @(
            '*.pem', '*.key', '*.pfx', '*.p12',
            'id_rsa', 'id_ed25519', 'id_ecdsa', 'id_dsa',
            '*.env', '.env.*',
            '*secret*', '*token*', '*credential*', '*password*'
        )
    }
}
