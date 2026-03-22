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
        $result = Resolve-DotRelativePath -InputPath $p
        $relativePath = $result.RelativePath

        # Check if it's a tracked folder
        $isTrackedFolder = $relativePath -in $config.trackedFolders

        # git rm --cached (keeps file on disk)
        if ($isTrackedFolder) {
            $output = Invoke-DotGit rm --cached -r $relativePath 2>&1
        } else {
            $output = Invoke-DotGit rm --cached $relativePath 2>&1
        }

        if ($LASTEXITCODE -ne 0) {
            Write-DotError "Failed to untrack: $relativePath"
            Write-DotInfo ($output | Out-String).Trim()
            continue
        }

        # Remove from trackedFolders if applicable
        if ($isTrackedFolder) {
            Remove-DotTrackedFolder -Folder $relativePath
        }

        Write-DotSuccess "Untracked: $relativePath (file preserved on disk)"
    }

    Write-Host ""
    Write-DotInfo "Run 'dot commit' to save."
}
