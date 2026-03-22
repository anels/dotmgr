function Invoke-DotGit {
    param(
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )
    $config = Get-DotConfig
    $repoPath = $config.repoPath
    $workTree = $config.workTree
    # Must cd to work-tree: git resolves relative paths from CWD, not --work-tree
    Push-Location $workTree
    try {
        # Don't merge stderr (2>&1) — keeps stdout clean for parsing
        & git --git-dir=$repoPath --work-tree=$workTree @Arguments
    } finally {
        Pop-Location
    }
}

function Test-DotRepo {
    $configPath = Get-DotConfigPath
    if (-not (Test-Path $configPath)) { return $false }
    try {
        $config = Get-DotConfig
        return (Test-Path $config.repoPath)
    } catch {
        return $false
    }
}

function Test-GitAvailable {
    $version = & git --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        return $version
    }
    return $null
}

function Update-TrackedFolders {
    $config = Get-DotConfig
    $existing = @($config.trackedFolders | Where-Object {
        Test-Path (Join-Path $config.workTree $_)
    })
    if ($existing.Count -gt 0) {
        Invoke-DotGit add @existing 2>$null | Out-Null
    }
}

function Resolve-DotRelativePath {
    param(
        [string]$InputPath,
        [switch]$MustExist,
        [switch]$ForwardSlash
    )

    $config = Get-DotConfig

    # Expand ~ and resolve relative paths
    $resolved = if ($InputPath.StartsWith('~')) {
        $InputPath -replace '^~', $HOME
    } elseif (-not [System.IO.Path]::IsPathRooted($InputPath)) {
        Join-Path (Get-Location) $InputPath
    } else {
        $InputPath
    }

    # Try to resolve to real filesystem path
    $resolvedFull = (Resolve-Path $resolved -ErrorAction SilentlyContinue).Path
    if ($resolvedFull) {
        $resolved = $resolvedFull
    } elseif ($MustExist) {
        return @{ RelativePath = $null; AbsolutePath = $null; Error = 'NotFound' }
    }

    # Make relative to work tree (workTree is pre-normalized by Get-DotConfig)
    $workTree = $config.workTree
    if ($resolved.StartsWith($workTree, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relativePath = $resolved.Substring($workTree.Length).TrimStart('\', '/')
    } elseif (-not $MustExist) {
        $relativePath = $InputPath.TrimStart('\', '/', '~').TrimStart('\', '/')
    } else {
        return @{ RelativePath = $null; AbsolutePath = $resolved; Error = 'OutsideWorkTree' }
    }

    if ($ForwardSlash) {
        $relativePath = $relativePath -replace '\\', '/'
    }

    return @{ RelativePath = $relativePath; AbsolutePath = $resolved; Error = $null }
}
