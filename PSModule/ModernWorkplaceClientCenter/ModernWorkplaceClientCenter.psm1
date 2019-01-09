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

$HttpConnectivitytester = Get-Module -Name HttpConnectivityTester
if($HttpConnectivitytester){
    Write-Verbose -Message "HttpConnectivityTester module is loaded."
} else {
    Write-Warning -Message "HttpConnectivityTester module is not loaded, trying to import it."
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "NestedModules\HttpConnectivityTester\HttpConnectivityTester.psd1")
}

$TcpConnectivitytester = Get-Module -Name TcpConnectivityTester
if($TcpConnectivitytester){
    Write-Verbose -Message "TcpConnectivityTester module is loaded."
} else {
    Write-Warning -Message "TcpConnectivityTester module is not loaded, trying to import it."
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "NestedModules\TcpConnectivityTester\TcpConnectivityTester.psd1")
}