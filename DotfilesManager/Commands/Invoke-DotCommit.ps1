function Invoke-DotCommit {
    param(
        [Parameter(Position = 0)]
        [string]$Message
    )

    if (-not (Test-DotRepo)) {
        Write-DotError "Dotfiles not initialized. Run 'dot init' first."
        return
    }

    # Auto-track new files in tracked folders
    Update-TrackedFolders

    # Stage changes to already-tracked files
    Invoke-DotGit add -u 2>$null | Out-Null

    # Check if there's anything to commit
    $status = Invoke-DotGit status --porcelain
    if (-not $status) {
        Write-DotInfo "Nothing to commit. Working tree clean."
        return
    }

    # Auto-generate message if not provided
    if (-not $Message) {
        $changedFiles = @($status) | ForEach-Object {
            if ($_.Length -ge 4) {
                Split-Path $_.Substring(3).Trim() -Leaf
            }
        } | Where-Object { $_ } | Select-Object -Unique -First 5

        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
        $fileList = $changedFiles -join ', '
        if (@($status).Count -gt 5) {
            $fileList += ", +$(@($status).Count - 5) more"
        }
        $Message = "update: $fileList @ $timestamp"
    }

    $result = Invoke-DotGit commit -m $Message
    if ($LASTEXITCODE -eq 0) {
        Write-DotSuccess "Committed: `"$Message`""
        # Show stats from the last line of git output
        $statsLine = @($result) | Where-Object { $_ -match 'files? changed' } | Select-Object -Last 1
        if ($statsLine) {
            Write-DotInfo "$statsLine"
        }
    } else {
        Write-DotError "Commit failed."
        $result | ForEach-Object { Write-DotInfo "$_" }
    }
    Write-Host ""
}
