function Invoke-DotHelp {
    Write-Host ""
    Write-Host "  Dotfiles Manager " -ForegroundColor Cyan -NoNewline
    Write-Host "- Track and version your config files" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Commands:" -ForegroundColor White
    Write-Host "    dot init                  " -ForegroundColor Yellow -NoNewline
    Write-Host "Interactive setup wizard" -ForegroundColor Gray
    Write-Host "    dot add <path>            " -ForegroundColor Yellow -NoNewline
    Write-Host "Stage files/folders for tracking" -ForegroundColor Gray
    Write-Host "    dot remove <path>         " -ForegroundColor Yellow -NoNewline
    Write-Host "Untrack files (keeps on disk)" -ForegroundColor Gray
    Write-Host "    dot list                  " -ForegroundColor Yellow -NoNewline
    Write-Host "List all tracked files" -ForegroundColor Gray
    Write-Host "    dot status                " -ForegroundColor Yellow -NoNewline
    Write-Host "Show pending changes" -ForegroundColor Gray
    Write-Host "    dot diff [path]           " -ForegroundColor Yellow -NoNewline
    Write-Host "Show file differences" -ForegroundColor Gray
    Write-Host "    dot commit [message]      " -ForegroundColor Yellow -NoNewline
    Write-Host "Commit staged changes" -ForegroundColor Gray
    Write-Host "    dot restore [path]        " -ForegroundColor Yellow -NoNewline
    Write-Host "Restore files to last commit" -ForegroundColor Gray
    Write-Host "    dot log [n]               " -ForegroundColor Yellow -NoNewline
    Write-Host "View commit history" -ForegroundColor Gray
    Write-Host "    dot show <path> [ref]     " -ForegroundColor Yellow -NoNewline
    Write-Host "Show committed version of a file" -ForegroundColor Gray
    Write-Host "    dot doctor                " -ForegroundColor Yellow -NoNewline
    Write-Host "Health check" -ForegroundColor Gray
    Write-Host "    dot help                  " -ForegroundColor Yellow -NoNewline
    Write-Host "This help message" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Options:" -ForegroundColor White
    Write-Host "    -Force                    " -ForegroundColor Yellow -NoNewline
    Write-Host "Bypass safety checks (add/remove)" -ForegroundColor Gray
    Write-Host ""
}
