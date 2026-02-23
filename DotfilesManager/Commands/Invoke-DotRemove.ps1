function Invoke-DotRemove {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$Path
    )

    if (-not (Test-DotRepo)) {
        Write-DotError "Dotfiles not initialized. Run 'dot init' first."
        return
    }

    $config = Get-DotConfig

    foreach ($p in $Path) {
        # Resolve path
        $resolved = if ($p.StartsWith('~')) {
            $p -replace '^~', $HOME
        } elseif (-not [System.IO.Path]::IsPathRooted($p)) {
            Join-Path (Get-Location) $p
        } else {
            $p
        }

        # Make relative to work tree
        $workTreeNorm = $config.workTree.TrimEnd('\', '/')
        # Try to resolve if it exists, otherwise work with the string
        $resolvedFull = (Resolve-Path $resolved -ErrorAction SilentlyContinue).Path
        if ($resolvedFull) { $resolved = $resolvedFull }

        if ($resolved.StartsWith($workTreeNorm, [System.StringComparison]::OrdinalIgnoreCase)) {
            $relativePath = $resolved.Substring($workTreeNorm.Length).TrimStart('\', '/')
        } else {
            $relativePath = $p.TrimStart('\', '/', '~').TrimStart('\', '/')
        }

        # Check if it's a tracked folder
        $isTrackedFolder = $relativePath -in $config.trackedFolders

        # git rm --cached (keeps file on disk)
        if ($isTrackedFolder) {
            $result = Invoke-DotGit rm --cached -r $relativePath 2>&1
        } else {
            $result = Invoke-DotGit rm --cached $relativePath 2>&1
        }

        if ($LASTEXITCODE -ne 0) {
            Write-DotError "Failed to untrack: $relativePath"
            Write-DotInfo ($result | Out-String).Trim()
            continue
        }

        # Remove from trackedFolders if applicable
        if ($isTrackedFolder) {
            $folders = [System.Collections.ArrayList]@($config.trackedFolders)
            $folders.Remove($relativePath) | Out-Null
            $config.trackedFolders = @($folders)
            Set-DotConfig -Config $config
        }

        Write-DotSuccess "Untracked: $relativePath (file preserved on disk)"
    }

    Write-Host ""
    Write-DotInfo "Run 'dot commit' to save."
}
