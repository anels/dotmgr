function Invoke-Dot {
    # Simple function (no CmdletBinding) so $args works for flexible forwarding
    if ($args.Count -eq 0) {
        Invoke-DotHelp
        return
    }

    $Command = [string]$args[0]

    $commandMap = @{
        'init'    = 'Invoke-DotInit'
        'add'     = 'Invoke-DotAdd'
        'remove'  = 'Invoke-DotRemove'
        'rm'      = 'Invoke-DotRemove'
        'list'    = 'Invoke-DotList'
        'ls'      = 'Invoke-DotList'
        'status'  = 'Invoke-DotStatus'
        'st'      = 'Invoke-DotStatus'
        'diff'    = 'Invoke-DotDiff'
        'commit'  = 'Invoke-DotCommit'
        'ci'      = 'Invoke-DotCommit'
        'restore' = 'Invoke-DotRestore'
        'log'     = 'Invoke-DotLog'
        'show'    = 'Invoke-DotShow'
        'cat'     = 'Invoke-DotShow'
        'doctor'  = 'Invoke-DotDoctor'
        'help'    = 'Invoke-DotHelp'
    }

    $funcName = $commandMap[$Command.ToLower()]
    if (-not $funcName) {
        Write-DotError "Unknown command: $Command"
        Write-DotInfo "Run 'dot help' to see available commands."
        return
    }

    if ($args.Count -le 1) {
        & $funcName
        return
    }

    # Forward remaining args: rebuild as expression so PowerShell parser
    # recognizes -ParamName as named parameters (not positional strings)
    $parts = @($funcName)
    for ($i = 1; $i -lt $args.Count; $i++) {
        $s = [string]$args[$i]
        if ($s -match '^-\w+') {
            # Parameter name or switch — pass through literally
            $parts += $s
        } else {
            # Value — single-quote escape for safe embedding
            $parts += "'" + ($s -replace "'", "''") + "'"
        }
    }
    Invoke-Expression ($parts -join ' ')
}

# Tab completion for both 'Invoke-Dot' and the 'dot' alias
Register-ArgumentCompleter -Native -CommandName @('dot', 'Invoke-Dot') -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $subcommands = @(
        @{ Name = 'init';    Tip = 'Interactive setup wizard' },
        @{ Name = 'add';     Tip = 'Stage files/folders for tracking' },
        @{ Name = 'remove';  Tip = 'Untrack files (keeps on disk)' },
        @{ Name = 'list';    Tip = 'List all tracked files' },
        @{ Name = 'status';  Tip = 'Show pending changes' },
        @{ Name = 'diff';    Tip = 'Show file differences' },
        @{ Name = 'commit';  Tip = 'Commit staged changes' },
        @{ Name = 'restore'; Tip = 'Restore files to last commit' },
        @{ Name = 'log';     Tip = 'View commit history' },
        @{ Name = 'show';    Tip = 'Show committed version of a file' },
        @{ Name = 'doctor';  Tip = 'Health check' },
        @{ Name = 'help';    Tip = 'Show help message' }
    )

    $tokens = $commandAst.CommandElements
    # Complete subcommand (second token, after 'dot' or 'Invoke-Dot')
    if ($tokens.Count -le 2) {
        $subcommands | Where-Object { $_.Name -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new(
                $_.Name, $_.Name, 'ParameterValue', $_.Tip
            )
        }
    }
}
