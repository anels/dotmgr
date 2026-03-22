$script:DotConfigCache = $null
$script:DotConfigCacheTime = [datetime]::MinValue

function Get-DotConfigPath {
    Join-Path $HOME '.dotfiles' 'config.json'
}

function Get-DotConfig {
    $path = Get-DotConfigPath
    if ($null -ne $script:DotConfigCache) {
        $fileTime = (Get-Item $path -ErrorAction SilentlyContinue).LastWriteTime
        if ($fileTime -le $script:DotConfigCacheTime) {
            return $script:DotConfigCache
        }
    }
    if (-not (Test-Path $path)) {
        throw "Dotfiles not initialized. Run 'dot init' first."
    }
    try {
        $config = Get-Content $path -Raw | ConvertFrom-Json
        if ($config.workTree) {
            $config.workTree = $config.workTree.TrimEnd('\', '/')
        }
        $script:DotConfigCache = $config
        $script:DotConfigCacheTime = (Get-Item $path).LastWriteTime
        return $script:DotConfigCache
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
    $script:DotConfigCache = $Config
    $script:DotConfigCacheTime = (Get-Item $path).LastWriteTime
}

function New-DotConfig {
    param(
        [string]$RepoPath,
        [string]$WorkTree
    )
    [PSCustomObject]@{
        version         = '1.0'
        repoPath        = $RepoPath
        workTree        = $WorkTree.TrimEnd('\', '/')
        trackedFolders  = @()
        excludePatterns = @(
            '*.pem', '*.key', '*.pfx', '*.p12',
            'id_rsa', 'id_ed25519', 'id_ecdsa', 'id_dsa',
            '*.env', '.env.*',
            '*secret*', '*token*', '*credential*', '*password*'
        )
    }
}

function Add-DotTrackedFolder {
    param([string]$Folder)
    $config = Get-DotConfig
    if ($Folder -notin $config.trackedFolders) {
        $config.trackedFolders = @($config.trackedFolders) + $Folder
        Set-DotConfig -Config $config
    }
}

function Remove-DotTrackedFolder {
    param([string]$Folder)
    $config = Get-DotConfig
    $filtered = @($config.trackedFolders | Where-Object { $_ -ine $Folder })
    if ($filtered.Count -ne @($config.trackedFolders).Count) {
        $config.trackedFolders = $filtered
        Set-DotConfig -Config $config
    }
}

function Get-OneDriveCandidates {
    @(
        (Join-Path $HOME 'OneDrive'),
        (Join-Path $HOME 'OneDrive - UiPath'),
        $env:OneDrive
    ) | Where-Object { $_ }
}
