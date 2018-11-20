function Invoke-TranslateAppStatus {
    <#
    .SYNOPSIS
         This function translates the Intune MSI App Install status in a readable string.
    .DESCRIPTION
         This function translates the Intune MSI App Install status in a readable string.

    .EXAMPLE
         Invoke-TranslateAppStatus
    #>
    [OutputType([String])]
    [CmdletBinding()]
    param(
        [Int]$Id
    )
    switch($Id){
        10 {"Initialized"}
        20 {"Download in Progress"}
        25 {"Pending Download Retry"}
        30 {"Download Failed"}
        40 {"Download Completed"}
        48 {"Pending User Session"}
        50 {"Enforcement in Progress"}
        55 {"Pending Enforcement Retry"}
        60 {"Enforcement Failed"}
        70 {"Enforcement Completed"}
    }
}