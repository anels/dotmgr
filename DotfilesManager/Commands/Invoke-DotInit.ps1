function Invoke-DotInit {
    param(
        [string]$RepoPath,
        [switch]$NoInteractive
    )

    Write-DotHeader "Dotfiles Manager Setup"

    # Check if already initialized
    if (Test-DotRepo) {
        $config = Get-DotConfig
        Write-DotWarning "Already initialized with repo at: $($config.repoPath)"
        Write-DotInfo "To reinitialize, remove ~/.dotfiles/config.json first."
        return
    }

    # Check git is available
    $gitVersion = & git --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-DotError "git not found. Please install git first."
        return
    }

    $workTree = $HOME

    # Step 1: Choose repo path
    if ($RepoPath) {
        $selectedPath = $RepoPath
    } elseif ($NoInteractive) {
        Write-DotError "RepoPath is required in non-interactive mode."
        return
    } else {
        Write-Host ""
        Write-Host "  [1/3] " -ForegroundColor Cyan -NoNewline
        Write-Host "Where should the bare repo be stored?" -ForegroundColor White

        $oneDrivePath = $null
        $defaultOptions = @()

        # Detect OneDrive path
        $possibleOneDrive = @(
            (Join-Path $HOME 'OneDrive'),
            (Join-Path $HOME 'OneDrive - UiPath'),
            $env:OneDrive
        ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

        if ($possibleOneDrive) {
            $oneDrivePath = Join-Path $possibleOneDrive 'repos' 'dotfiles.git'
            $defaultOptions += $oneDrivePath
        }

        $localPath = Join-Path $HOME '.dotfiles-repo'
        $defaultOptions += $localPath

        for ($i = 0; $i -lt $defaultOptions.Count; $i++) {
            $marker = if ($i -eq 0) { "(recommended)" } else { "" }
            Write-Host "    [$($i + 1)] " -ForegroundColor Yellow -NoNewline
            Write-Host "$($defaultOptions[$i]) " -NoNewline
            if ($marker) { Write-Host $marker -ForegroundColor Green } else { Write-Host "" }
        }
        $customIdx = $defaultOptions.Count + 1
        Write-Host "    [$customIdx] " -ForegroundColor Yellow -NoNewline
        Write-Host "Custom path..."

        Write-Host ""
        $choice = Read-Host "  Select [1]"
        if ([string]::IsNullOrWhiteSpace($choice)) { $choice = '1' }

        if ($choice -eq "$customIdx") {
            $selectedPath = Read-Host "  Enter path"
        } elseif ($choice -ge 1 -and $choice -le $defaultOptions.Count) {
            $selectedPath = $defaultOptions[[int]$choice - 1]
        } else {
            $selectedPath = $defaultOptions[0]
        }
    }

    # Normalize path
    $selectedPath = $selectedPath.Replace('/', '\')
    if (-not $selectedPath.EndsWith('.git')) {
        $selectedPath = "$selectedPath.git"
    }

    # Step 2: Confirm work tree
    if (-not $NoInteractive) {
        Write-Host ""
        Write-Host "  [2/3] " -ForegroundColor Cyan -NoNewline
        Write-Host "Work tree (Home directory):" -ForegroundColor White
        Write-Host "    $workTree" -ForegroundColor Gray
        Write-Host ""
    }

    # Create bare repo
    $repoDir = Split-Path $selectedPath -Parent
    if (-not (Test-Path $repoDir)) {
        New-Item -ItemType Directory -Path $repoDir -Force | Out-Null
    }

    if (Test-Path $selectedPath) {
        Write-DotWarning "Directory already exists: $selectedPath"
        Write-DotInfo "Using existing directory as bare repo."
    } else {
        & git init --bare $selectedPath 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-DotError "Failed to create bare repo at: $selectedPath"
            return
        }
    }

    # Configure bare repo
    & git --git-dir=$selectedPath config status.showUntrackedFiles no

    # Create config
    $config = New-DotConfig -RepoPath $selectedPath -WorkTree $workTree
    Set-DotConfig -Config $config

    Write-DotSuccess "Bare repo created at $selectedPath"
    Write-DotSuccess "Config saved to $(Get-DotConfigPath)"

    # Step 3: Scan for common config files
    $commonPaths = @(
        @{ Path = '.gitconfig';                    Label = '.gitconfig' },
        @{ Path = '.claude';                       Label = '.claude/' },
        @{ Path = '.ssh\config';                   Label = '.ssh/config' },
        @{ Path = 'AppData\Local\nvim';            Label = 'AppData/Local/nvim/' },
        @{ Path = '.wslconfig';                    Label = '.wslconfig' },
        @{ Path = '.npmrc';                        Label = '.npmrc' },
        @{ Path = 'profile.local.ps1';             Label = 'profile.local.ps1' }
    )

    $existing = $commonPaths | Where-Object {
        Test-Path (Join-Path $workTree $_.Path)
    }

    if ($existing -and -not $NoInteractive) {
        Write-Host ""
        Write-Host "  [3/3] " -ForegroundColor Cyan -NoNewline
        Write-Host "Found config files. Add them now?" -ForegroundColor White

        $toAdd = @()
        foreach ($item in $existing) {
            $answer = Read-Host "    Add $($item.Label)? [Y/n]"
            if ($answer -eq '' -or $answer -match '^[Yy]') {
                $toAdd += $item.Path
            }
        }

        if ($toAdd.Count -gt 0) {
            $addedFiles = 0
            foreach ($path in $toAdd) {
                $fullPath = Join-Path $workTree $path
                $isFolder = (Get-Item $fullPath).PSIsContainer

                Invoke-DotGit add $path 2>$null | Out-Null

                if ($isFolder) {
                    # Register folder for auto-tracking
                    $config = Get-DotConfig
                    if ($path -notin $config.trackedFolders) {
                        $folders = [System.Collections.ArrayList]@($config.trackedFolders)
                        $folders.Add($path) | Out-Null
                        $config.trackedFolders = @($folders)
                        Set-DotConfig -Config $config
                    }
                    $fileCount = (Get-ChildItem $fullPath -Recurse -File).Count
                    $addedFiles += $fileCount
                    Write-DotSuccess "Staged: $path ($fileCount files)"
                } else {
                    $addedFiles++
                    Write-DotSuccess "Staged: $path"
                }
            }

            # Also track the .dotfiles directory itself
            $dotfilesRel = '.dotfiles'
            Invoke-DotGit add $dotfilesRel 2>$null | Out-Null

            # Initial commit
            $result = Invoke-DotGit commit -m "init: dotfiles setup"
            if ($LASTEXITCODE -eq 0) {
                Write-DotSuccess "Initial commit created ($addedFiles files)"
            }
        }
    }

    Write-Host ""
    Write-DotSuccess "Ready! Run 'dot add <file>' to start tracking more files."
    Write-Host ""
}
