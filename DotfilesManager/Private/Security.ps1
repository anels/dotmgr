function Test-PathSafe {
    param(
        [string]$Path,
        [switch]$Force,
        [string[]]$ExcludePatterns
    )

    if (-not $ExcludePatterns) {
        $ExcludePatterns = (Get-DotConfig).excludePatterns
    }

    $issues = @()

    $leaf = Split-Path $Path -Leaf
    foreach ($pattern in $ExcludePatterns) {
        if ($leaf -like $pattern -or $Path -like $pattern) {
            $issues += "Matches exclude pattern: $pattern"
        }
    }

    $item = Get-Item $Path -ErrorAction SilentlyContinue
    if ($item -and -not $item.PSIsContainer -and $item.Length -gt 1MB) {
        $sizeMB = [math]::Round($item.Length / 1MB, 1)
        $issues += "Large file: ${sizeMB}MB (limit: 1MB)"
    }

    if ($issues -and -not $Force) {
        return @{ Safe = $false; Issues = $issues }
    }
    return @{ Safe = $true; Issues = @() }
}
