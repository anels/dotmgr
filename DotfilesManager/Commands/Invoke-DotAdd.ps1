function Invoke-DotAdd {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$Path,
        [switch]$Force
    )

    if (-not (Test-DotRepo)) {
        Write-DotError "Dotfiles not initialized. Run 'dot init' first."
        return
    }

    $config = Get-DotConfig
    $excludePatterns = $config.excludePatterns
    $totalStaged = 0

    foreach ($p in $Path) {
        $result = Resolve-DotRelativePath -InputPath $p -MustExist
        if ($result.Error -eq 'NotFound') {
            Write-DotError "Path not found: $p"
            continue
        }
        if ($result.Error -eq 'OutsideWorkTree') {
            Write-DotError "Path must be under home directory: $($result.AbsolutePath)"
            continue
        }
        $relativePath = $result.RelativePath
        $resolved = $result.AbsolutePath

        $isFolder = (Get-Item $resolved).PSIsContainer

        if ($isFolder) {
            # For folders, check each file inside
            $files = Get-ChildItem $resolved -Recurse -File
            $blocked = @()
            foreach ($file in $files) {
                $check = Test-PathSafe -Path $file.FullName -Force:$Force -ExcludePatterns $excludePatterns
                if (-not $check.Safe) {
                    $blocked += @{ File = $file.Name; Issues = $check.Issues }
                }
            }
            if ($blocked -and -not $Force) {
                Write-DotWarning "Some files in '$relativePath' are blocked:"
                foreach ($b in $blocked) {
                    Write-DotInfo "  $($b.File): $($b.Issues -join ', ')"
                }
                Write-DotInfo "Use -Force to override safety checks."
                continue
            }

            Invoke-DotGit add $relativePath 2>$null | Out-Null
            Add-DotTrackedFolder -Folder $relativePath

            $fileCount = $files.Count
            $totalStaged += $fileCount
            Write-DotSuccess "Staged: $relativePath\ ($fileCount files)"
            Write-DotInfo "Folder registered for auto-tracking."
        } else {
            # Single file
            $check = Test-PathSafe -Path $resolved -Force:$Force -ExcludePatterns $excludePatterns
            if (-not $check.Safe) {
                Write-DotWarning "Blocked: $relativePath"
                foreach ($issue in $check.Issues) {
                    Write-DotInfo "  $issue"
                }
                Write-DotInfo "Use -Force to override safety checks."
                continue
            }

            Invoke-DotGit add $relativePath 2>$null | Out-Null
            $totalStaged++
            Write-DotSuccess "Staged: $relativePath"
        }
    }

    if ($totalStaged -gt 0) {
        Write-Host ""
        Write-DotInfo "$totalStaged file(s) staged. Run 'dot commit' to save."
    }
}
