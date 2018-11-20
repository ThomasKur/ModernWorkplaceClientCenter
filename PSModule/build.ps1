﻿$ModulePath = ".\PSModule\ModernWorkplaceClientCenter"

## The following four lines only need to be declared once in your script.
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Description."
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Description."
$cancel = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel","Description."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no, $cancel)

#region Code Analyzer
Import-Module -Name PSScriptAnalyzer 
$ScriptAnalyzerResult = Invoke-ScriptAnalyzer $ModulePath -Recurse -ErrorAction Stop -ExcludeRule "PSAvoidTrailingWhitespace"

if($ScriptAnalyzerResult){
    $ScriptAnalyzerResult
    Write-Error "Scripts contains errors. PSScriptAnalyzer provided results above."
}
#endregion

#region Build Manifest
$ExportableFunctions = (Get-ChildItem -Path "$ModulePath\Functions" -Filter '*.ps1').BaseName
$ReleaseNotes = ((Get-Content ".\ReleaseNotes.md" -Raw) -split "##")
$ReleaseNote = ($ReleaseNotes[1] + "`n`n To see the complete history, checkout the Release Notes on Github")
Update-ModuleManifest -Path "$ModulePath\ModernWorkplaceClientCenter.psd1" -FunctionsToExport $ExportableFunctions -ReleaseNotes $ReleaseNote

#Update Version
$CurrentVersion = $ModuelManifestTest.Version
$SuggestedNewVersion = [Version]::new($CurrentVersion.Major,$CurrentVersion.Minor,$CurrentVersion.Build + 1)
$title = "Increment Version" 
$message = "Would you like to increase Module Version from $($CurrentVersion) to $($SuggestedNewVersion)?"
$result = $host.ui.PromptForChoice($title, $message, $options, 1)
switch ($result) {
    0{
        Write-Information "You selected yes to increase the version. Updating Mnaifest..."
        Update-ModuleManifest -Path "$ModulePath\ModernWorkplaceClientCenter.psd1" -ModuleVersion $SuggestedNewVersion
    }
    1{
        Write-Host "You selected no. The version will not be increased."
    }
    2{
        Write-Error "Canceled Publishing Process" -ErrorAction Stop
    }
}
Test-ModuleManifest -Path "$ModulePath\ModernWorkplaceClientCenter.psd1" -ErrorAction Stop

#endregion

#region Sign Scripts
    Copy-Item -Path $ModulePath -Destination $env:TEMP -Recurse -Force
    $cert = get-item Cert:\CurrentUser\My\* -CodeSigningCert
    $PSFiles = Get-ChildItem -Path $env:TEMP\ModernWorkplaceClientCenter -Recurse | Where-Object {$_.Extension -eq "ps1" -or $_.Extension -eq "psm1"}
    foreach($PSFile in $PSFiles){
        Set-AuthenticodeSignature -Certificate $cert -TimestampServer http://timestamp.verisign.com/scripts/timstamp.dll -FilePath ($PSFile.FullName) -Verbose
    }
#endregion
$PSGallerAPIKey = Read-Host "Insert PSGallery API Key"
Publish-Module -Path $env:TEMP\ModernWorkplaceClientCenter -NuGetApiKey $PSGallerAPIKey -WhatIf -Verbose