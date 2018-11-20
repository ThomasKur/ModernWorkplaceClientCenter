function Get-MDMDeviceOwnership(){
    <#
    .SYNOPSIS
         Returns information about the Ownership of the Device.
    .DESCRIPTION
         Returns information about the Ownership of the Device.
         - 1: Corporate Owned
         - 0: Personal Owned
         - $null: No infomration about Ownership found

    .EXAMPLE
         Get-MDMDeviceOwnership
    .NOTES

    #>
    Get-ItemPropertyValue -Path HKLM:\SOFTWARE\Microsoft\Enrollments\Ownership -Name CorpOwned -ErrorAction SilentlyContinue
}