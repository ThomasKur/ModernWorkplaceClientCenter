$functionFolders = @('Functions', 'Internal')

# Importing all the Functions required for the module from the subfolders.
ForEach ($folder in $functionFolders) {
    $folderPath = Join-Path -Path $PSScriptRoot -ChildPath $folder
    If (Test-Path -Path $folderPath)
    {
        Write-Verbose -Message "Importing from $folder"
        $functions = Get-ChildItem -Path $folderPath -Filter '*.ps1'
        ForEach ($function in $functions)
        {
            Write-Verbose -Message "  Loading $($function.FullName)"
            . ($function.FullName)
        }
    } else {
         Write-Warning "Path $folderPath not found. Some parts of the module will not work."
    }
}