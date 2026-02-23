function Invoke-DotLog {
    param(
        [Parameter(Position = 0)]
        [int]$Count = 20
    )

    if (-not (Test-DotRepo)) {
        Write-DotError "Dotfiles not initialized. Run 'dot init' first."
        return
    }

    $result = Invoke-DotGit log --pretty="format:%C(yellow)%h%C(reset)  %C(cyan)%ar%C(reset)    %s" --color=always -n $Count
    if (-not $result) {
        Write-DotInfo "No commits yet."
        return
    }

    Write-DotHeader "Commit History"
    foreach ($line in @($result)) {
        Write-Host "    $line"
    }
    Write-Host ""
}
