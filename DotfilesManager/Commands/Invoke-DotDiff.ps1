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
        # Resolve path
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

        Invoke-DotGit diff --color=always -- $relativePath
    } else {
        Invoke-DotGit diff --color=always
    }
}
