@{
    RootModule        = 'DotfilesManager.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'a3b7c9d1-e5f2-4a6b-8c0d-2e4f6a8b0c2d'
    Author            = 'ruilin.liu'
    Description       = 'Bare Git Repo based dotfiles manager for Windows'
    PowerShellVersion = '7.0'
    FunctionsToExport = @('Invoke-Dot')
    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('dotfiles', 'git', 'configuration')
            ProjectUri = ''
        }
    }
}
