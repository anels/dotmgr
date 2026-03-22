function Invoke-DotDiff {
    param(
        [Parameter(Position = 0)]
        [string]$Path
    )

    if (-not (Test-DotRepo)) {
        Write-DotError "Dotfiles not initialized. Run 'dot init' first."
        return
    }

    if ($Path) {
        $result = Resolve-DotRelativePath -InputPath $Path
        Invoke-DotGit diff --color=always -- $result.RelativePath
    } else {
        Invoke-DotGit diff --color=always
    }
}
