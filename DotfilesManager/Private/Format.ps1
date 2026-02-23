function Write-DotSuccess {
    param([string]$Message)
    Write-Host "  $([char]0x2713) $Message" -ForegroundColor Green
}

function Write-DotWarning {
    param([string]$Message)
    Write-Host "  ! $Message" -ForegroundColor Yellow
}

function Write-DotError {
    param([string]$Message)
    Write-Host "  x $Message" -ForegroundColor Red
}

function Write-DotHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "  $Title" -ForegroundColor Cyan
    $line = [string]::new([char]0x2500, $Title.Length + 2)
    Write-Host "  $line" -ForegroundColor DarkGray
}

function Write-DotInfo {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor Gray
}
