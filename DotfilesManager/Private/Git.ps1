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

function Update-TrackedFolders {
    $config = Get-DotConfig
    foreach ($folder in $config.trackedFolders) {
        $fullPath = Join-Path $config.workTree $folder
        if (Test-Path $fullPath) {
            Invoke-DotGit add $folder 2>$null | Out-Null
        }
    }
}
