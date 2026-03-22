function Invoke-DotDoctor {
    Write-DotHeader "Dotfiles Doctor"

    $allGood = $true

    # Check git
    $gitVersion = Test-GitAvailable
    if ($gitVersion) {
        Write-DotSuccess "git found: $gitVersion"
    } else {
        Write-DotError "git not found in PATH"
        $allGood = $false
    }

    # Check PowerShell version
    Write-DotSuccess "PowerShell: $($PSVersionTable.PSVersion)"

    # Check config
    $configPath = Get-DotConfigPath
    if (-not (Test-Path $configPath)) {
        Write-DotError "Config not found: $configPath"
        Write-DotInfo "Run 'dot init' to set up."
        return
    }

    try {
        $config = Get-DotConfig
        Write-DotSuccess "Config valid: $configPath"
    } catch {
        Write-DotError "Config corrupted: $configPath"
        $allGood = $false
        return
    }

    # Check bare repo
    if (Test-Path $config.repoPath) {
        Write-DotSuccess "Bare repo exists: $($config.repoPath)"
    } else {
        Write-DotError "Bare repo missing: $($config.repoPath)"
        $allGood = $false
    }

    # Check if repo is on OneDrive
    $oneDrivePaths = @(Get-OneDriveCandidates)
    $onOneDrive = $oneDrivePaths | Where-Object { $config.repoPath.StartsWith($_, [System.StringComparison]::OrdinalIgnoreCase) }
    if ($onOneDrive) {
        Write-DotSuccess "Repo is on OneDrive (cloud backup active)"
    } else {
        Write-DotWarning "Repo is NOT on OneDrive (no cloud backup)"
    }

    # Check tracked files
    $tracked = @(Invoke-DotGit ls-files 2>$null)
    $trackedFolderCount = $config.trackedFolders.Count
    Write-DotSuccess "Tracked: $($tracked.Count) files across $trackedFolderCount folders"

    # Check for missing tracked files
    $missing = @()
    foreach ($f in $tracked) {
        $fullPath = Join-Path $config.workTree $f
        if (-not (Test-Path $fullPath)) {
            $missing += $f
        }
    }

    if ($missing) {
        $allGood = $false
        Write-DotError "$($missing.Count) tracked file(s) missing from disk:"
        foreach ($m in $missing) {
            Write-DotInfo "  $m"
        }
    }

    # Check for uncommitted changes
    $status = Invoke-DotGit status --porcelain 2>$null
    if ($status) {
        $changeCount = @($status).Count
        Write-DotWarning "$changeCount uncommitted change(s) — run 'dot status' for details"
    } else {
        Write-DotSuccess "No uncommitted changes"
    }

    Write-Host ""
    if ($allGood) {
        Write-DotSuccess "All checks passed!"
    }
    Write-Host ""
}
