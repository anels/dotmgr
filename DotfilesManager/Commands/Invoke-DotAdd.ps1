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
    $totalStaged = 0

    foreach ($p in $Path) {
        # Resolve path: support ~ and relative paths
        $resolved = if ($p.StartsWith('~')) {
            $p -replace '^~', $HOME
        } elseif (-not [System.IO.Path]::IsPathRooted($p)) {
            Join-Path (Get-Location) $p
        } else {
            $p
        }

        $resolved = (Resolve-Path $resolved -ErrorAction SilentlyContinue).Path
        if (-not $resolved) {
            Write-DotError "Path not found: $p"
            continue
        }

        # Make path relative to work tree
        $workTreeNorm = $config.workTree.TrimEnd('\', '/')
        if (-not $resolved.StartsWith($workTreeNorm, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-DotError "Path must be under home directory: $resolved"
            continue
        }
        $relativePath = $resolved.Substring($workTreeNorm.Length).TrimStart('\', '/')

        $isFolder = (Get-Item $resolved).PSIsContainer

        if ($isFolder) {
            # For folders, check each file inside
            $files = Get-ChildItem $resolved -Recurse -File
            $blocked = @()
            foreach ($file in $files) {
                $check = Test-PathSafe -Path $file.FullName -Force:$Force
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

            # Register folder for auto-tracking
            $config = Get-DotConfig
            if ($relativePath -notin $config.trackedFolders) {
                $folders = [System.Collections.ArrayList]@($config.trackedFolders)
                $folders.Add($relativePath) | Out-Null
                $config.trackedFolders = @($folders)
                Set-DotConfig -Config $config
            }

            $fileCount = $files.Count
            $totalStaged += $fileCount
            Write-DotSuccess "Staged: $relativePath\ ($fileCount files)"
            Write-DotInfo "Folder registered for auto-tracking."
        } else {
            # Single file
            $check = Test-PathSafe -Path $resolved -Force:$Force
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
