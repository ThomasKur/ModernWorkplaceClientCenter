function Get-MDMDeviceOwnership(){
    <#
    .SYNOPSIS
         Returns information about the Ownership of the Device.
    .DESCRIPTION
         Returns information about the Ownership of the Device.
         - Corporate Owned
         - Personal Owned
         - Unknown: No information about Ownership found

    .EXAMPLE
         Get-MDMDeviceOwnership
    .NOTES

    #>
    $CorpOwned = Get-ItemPropertyValue -Path HKLM:\SOFTWARE\Microsoft\Enrollments\Ownership -Name CorpOwned -ErrorAction SilentlyContinue
    switch($CorpOwned){
         0{return "PersonalOwned"}
         1{return "CorporateOwned"}
         $null{return "Unknown"}
    }
}