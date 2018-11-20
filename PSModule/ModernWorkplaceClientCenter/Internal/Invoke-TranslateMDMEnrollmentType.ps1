function Invoke-TranslateMDMEnrollmentType {
    <#
    .SYNOPSIS
         This function translates the MDM Enrollment Type in a readable string.
    .DESCRIPTION
         This function translates the MDM Enrollment Type in a readable string.

    .EXAMPLE
         Invoke-TranslateMDMEnrollmentType
    #>
    [OutputType([String])]
    [CmdletBinding()]
    param(
        [Int]$Id
    )
    switch($Id){
        0 {"Not enrolled"}
        6 {"MDM enrolled"}
        13 {"Azure AD joined"}
    }
}