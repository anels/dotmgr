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
        $result = Resolve-DotRelativePath -InputPath $Path
        $relativePath = $result.RelativePath

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

        Invoke-DotGit checkout -- . 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-DotSuccess "Restored all tracked files to last committed version"
        } else {
            Write-DotError "Restore failed."
        }
    }
    Write-Host ""
}
