function Get-IsAdmin{
    <#
    .Synopsis
    Returns $true if the script is executed with administrator priviledge, false if not.

    .Description
    Returns $true if the script is executed with administrator priviledge, false if not.

    .Example
    Get-IsAdmin

    #>
    [OutputType([bool])]
    [CmdletBinding()]
    param()
    $CurrentUser = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent())
    $IsAdmin = $CurrentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    Write-Verbose "Detected that the current session is$(if($IsAdmin){ " not"}) running with administrator priviledges."
    return $IsAdmin
}