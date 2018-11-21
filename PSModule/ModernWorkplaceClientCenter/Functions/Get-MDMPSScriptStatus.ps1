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
    if((Get-MDMEnrollmentStatus).EnrollmentState -eq 1){
        $Users = Get-ChildItem HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Policies\ -ErrorAction SilentlyContinue
        foreach($user in $users){
            $Scripts = Get-ChildItem "$($user.PSPath)"
            foreach($Script in $Scripts){
                $Script = Get-ItemProperty $Script.PSPath
                $PSStatus += $App
            }
        }
    } else {
        Write-Error "Device is not enrolled to MDM."
    }
    return $PSStatus
}