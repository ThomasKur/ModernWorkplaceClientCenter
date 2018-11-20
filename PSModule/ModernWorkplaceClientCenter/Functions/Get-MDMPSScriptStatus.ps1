function Get-MDMPSScriptStatus(){
    <#
    .SYNOPSIS
         Returns information about the execution of PowerShell Scripts deployed with Intune.
    .DESCRIPTION
         Returns information about the execution of PowerShell Scripts deployed with Intune.

    .EXAMPLE
         Get-MDMPSScriptStatus
    .NOTES

    #>
    $PSStatus = @()
    $Users = Get-ChildItem HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Policies\
    foreach($user in $users){
        $Scripts = Get-ChildItem "$($user.PSPath)"
        foreach($Script in $Scripts){
            $Script = Get-ItemProperty $Script.PSPath
            $PSStatus += $App
        }
    }
    return $PSStatus
}