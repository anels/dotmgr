function Invoke-DotStatus {
    if (-not (Test-DotRepo)) {
        Write-DotError "Dotfiles not initialized. Run 'dot init' first."
        return
    }

    # Auto-track new files in tracked folders
    Update-TrackedFolders

    $output = Invoke-DotGit status --porcelain
    if (-not $output) {
        Write-DotHeader "Dotfiles Status"
        Write-DotSuccess "Everything up to date."
        Write-Host ""
        return
    }

    $modified = @()
    $deleted = @()
    $added = @()
    $renamed = @()

    foreach ($line in @($output)) {
        $line = "$line"
        if ($line.Length -lt 4) { continue }
        $statusCode = $line.Substring(0, 2)
        $filePath = $line.Substring(3)

        # -Wildcard '??' matches any 2 chars; break prevents multi-match
        switch -Wildcard ($statusCode) {
            ' M' { $modified += $filePath; break }
            'M ' { $modified += $filePath; break }
            'MM' { $modified += $filePath; break }
            ' D' { $deleted += $filePath; break }
            'D ' { $deleted += $filePath; break }
            'A ' { $added += $filePath; break }
            'AM' { $added += $filePath; break }
            'R*' { $renamed += $filePath; break }
            '??' { $added += $filePath; break }
            default { $modified += $filePath }
        }
    }

    Write-DotHeader "Dotfiles Status"

    if ($modified) {
        Write-Host "  Modified:" -ForegroundColor Yellow
        foreach ($f in $modified) {
            Write-Host "    M  $f" -ForegroundColor Yellow
        }
    }

    if ($deleted) {
        Write-Host "  Deleted:" -ForegroundColor Red
        foreach ($f in $deleted) {
            Write-Host "    D  $f" -ForegroundColor Red
        }
    }

    if ($added) {
        Write-Host "  New (staged):" -ForegroundColor Green
        foreach ($f in $added) {
            Write-Host "    +  $f" -ForegroundColor Green
        }
    }

    if ($renamed) {
        Write-Host "  Renamed:" -ForegroundColor Cyan
        foreach ($f in $renamed) {
            Write-Host "    R  $f" -ForegroundColor Cyan
        }
    }

    Write-Host ""
    $counts = @()
    if ($modified) { $counts += "$($modified.Count) modified" }
    if ($deleted)  { $counts += "$($deleted.Count) deleted" }
    if ($added)    { $counts += "$($added.Count) new" }
    if ($renamed)  { $counts += "$($renamed.Count) renamed" }
    Write-DotInfo ($counts -join ', ')
    Write-Host ""
}
