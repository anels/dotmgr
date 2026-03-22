function Invoke-DotShow {
    param(
        [Parameter(Position = 0)]
        [string]$Path,

        [Parameter(Position = 1)]
        [string]$Ref = 'HEAD'
    )

    if (-not (Test-DotRepo)) {
        Write-DotError "Dotfiles not initialized. Run 'dot init' first."
        return
    }

    if (-not $Path) {
        Write-DotError "Usage: dot show <path> [ref]"
        Write-DotInfo "  dot show .gitconfig          Show latest committed version"
        Write-DotInfo "  dot show .gitconfig HEAD~1   Show previous commit's version"
        return
    }

    # git show needs forward slashes
    $result = Resolve-DotRelativePath -InputPath $Path -ForwardSlash
    $relativePath = $result.RelativePath

    $output = Invoke-DotGit show "${Ref}:${relativePath}" 2>&1
    if ($LASTEXITCODE -ne 0) {
        $errMsg = ($output | Out-String).Trim()
        if ($errMsg -match 'does not exist|not exist in|bad revision') {
            Write-DotError "File not found in commit ${Ref}: $relativePath"
        } else {
            Write-DotError $errMsg
        }
        return
    }

    $output
}
