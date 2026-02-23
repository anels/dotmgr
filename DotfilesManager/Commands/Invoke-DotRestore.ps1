function Invoke-DotRestore {
    param(
        [Parameter(Position = 0)]
        [string]$Path
    )

    if (-not (Test-DotRepo)) {
        Write-DotError "Dotfiles not initialized. Run 'dot init' first."
        return
    }

    if ($Path) {
        # Restore single file
        $resolved = if ($Path.StartsWith('~')) {
            $Path -replace '^~', $HOME
        } elseif (-not [System.IO.Path]::IsPathRooted($Path)) {
            Join-Path (Get-Location) $Path
        } else {
            $Path
        }

        $config = Get-DotConfig
        $workTreeNorm = $config.workTree.TrimEnd('\', '/')
        $resolvedFull = (Resolve-Path $resolved -ErrorAction SilentlyContinue).Path
        if ($resolvedFull) { $resolved = $resolvedFull }

        if ($resolved.StartsWith($workTreeNorm, [System.StringComparison]::OrdinalIgnoreCase)) {
            $relativePath = $resolved.Substring($workTreeNorm.Length).TrimStart('\', '/')
        } else {
            $relativePath = $Path.TrimStart('\', '/', '~').TrimStart('\', '/')
        }

        Invoke-DotGit checkout -- $relativePath 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-DotSuccess "Restored: $relativePath"
        } else {
            Write-DotError "Failed to restore: $relativePath"
        }
    } else {
        # Restore all - needs confirmation
        Write-DotWarning "This will overwrite ALL local changes with the last committed version."
        $confirm = Read-Host "  Continue? [y/N]"
        if ($confirm -notmatch '^[Yy]$') {
            Write-DotInfo "Cancelled."
            return
        }

        $trackedFiles = @(Invoke-DotGit ls-files)
        Invoke-DotGit checkout -- . 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-DotSuccess "Restored $($trackedFiles.Count) files to last committed version"
        } else {
            Write-DotError "Restore failed."
        }
    }
    Write-Host ""
}
