function Invoke-DotList {
    if (-not (Test-DotRepo)) {
        Write-DotError "Dotfiles not initialized. Run 'dot init' first."
        return
    }

    $files = Invoke-DotGit ls-files
    if (-not $files) {
        Write-DotInfo "No files tracked yet. Run 'dot add <path>' to start."
        return
    }

    Write-DotHeader "Tracked Files"

    $fileList = @($files)
    foreach ($f in $fileList) {
        Write-Host "    $f" -ForegroundColor Gray
    }

    Write-Host ""
    Write-DotInfo "$($fileList.Count) file(s) tracked"
    Write-Host ""
}
