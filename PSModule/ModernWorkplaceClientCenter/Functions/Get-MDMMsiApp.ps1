function Get-MDMMsiApp() {
    <#
    .SYNOPSIS
         Retrieves information about all MDM assigned applications, including their installation state.
    .DESCRIPTION
         Retrieves information about all MDM assigned applications by combining policy information combained with additional information from registry to provide a complete list.

    .EXAMPLE
         Get-MdmMsiApp
    .NOTES

    #>
    [OutputType([System.Object[]])]
    $AppStatus = @()
    $Users = Get-ChildItem HKLM:\SOFTWARE\Microsoft\EnterpriseDesktopAppManagement\ -ErrorAction SilentlyContinue
    if($Users){
        $AddRemoveApps = Get-InstalledApplication
        foreach($user in $users){
            if($user.PSChildName -eq "S-0-0-00-0000000000-0000000000-000000000-000")
            {
                $UserName = "LocalSystem"
                $Authority = "LocalSystem"
            } else {
                $objSID = New-Object System.Security.Principal.SecurityIdentifier($user.PSChildName)
                $objUser = $objSID.Translate( [System.Security.Principal.NTAccount])
                $UserName = $objUser.Value.Split("\")[1]
                $Authority = $objUser.Value.Split("\")[0]
            }
            if(Test-Path "$($user.PSPath)\MSI"){
                $Apps = Get-ChildItem "$($user.PSPath)\MSI"
                foreach($App in $Apps){
                    $App = ($App | Get-ItemProperty)
                    $AppTemp = New-Object PSCustomObject
                    $AddRemoveApp = $AddRemoveApps | Where-Object { $_.ProductCode -eq $App.PSChildName }
                    if($AddRemoveApp){
                        Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "Publisher" -Value $AddRemoveApp.Publisher
                        Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "DisplayVersion" -Value $AddRemoveApp.DisplayVersion
                        Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "AppName" -Value $AddRemoveApp.DisplayName
                    } else {
                        Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "Publisher" -Value " "
                        Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "DisplayVersion" -Value " "
                        Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "AppName" -Value " "
                    }
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "ProductCode" -Value $App.PSChildName
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "ProductVersion" -Value $App.ProductVersion
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "ActionType" -Value $App.ActionType
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "Status" -Value (Invoke-TranslateAppStatus -Id $App.Status)
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "LastError" -Value $App.LastError
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "DownloadLocation" -Value $App.DownloadLocation
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "DownloadInstall" -Value $App.DownloadInstall
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "DownloadUrlList" -Value $App.DownloadUrlList
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "CurrentDownloadUrl" -Value $App.CurrentDownloadUrl
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "EnforcementStartTime" -Value ([DateTime]::FromFileTime($App.EnforcementStartTime))
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "EnforcementTimeout" -Value $App.EnforcementTimeout
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "EnforcementRetryIndex" -Value $App.EnforcementRetryIndex
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "EnforcementRetryCount" -Value $App.EnforcementRetryCount
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "EnforcementRetryInterval" -Value $App.EnforcementRetryInterval
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "LocURI" -Value $App.LocURI
                    #Check if App is from Syntaro
                    $SyntaroApp = $null
                    $SyntaroApps = Get-ChildItem -Path HKLM:\SOFTWARE\Syntaro\ApplicationManagement\
                    foreach($TempSyntaroApp in $SyntaroApps){
                        if((Get-ItemProperty -Path $TempSyntaroApp.PSPath).MsiCode -eq $App.PSChildName){
                            $SyntaroApp = (Get-ItemProperty -Path $TempSyntaroApp.PSPath)
                        }
                    }
                    $App = Get-ItemProperty $App.PSPath
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "AssignedUserName" -Value $UserName
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "AssignedUserAuthority" -Value $Authority
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "AssignmentType" -Value $App.AssignmentType
                    if($SyntaroApp){
                        Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "AppType" -Value "Syntaro"
                    } else {
                        Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "AppType" -Value "Native"
                    }
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "SyntaroAction" -Value $SyntaroApp.Action
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "SyntaroProcessed" -Value $SyntaroApp.Processed
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "SyntaroNotFoundInRepo" -Value $SyntaroApp.NotFoundInRepo
                    Add-Member -InputObject $AppTemp -MemberType NoteProperty -Name "CreationTime" -Value ([DateTime]::FromFileTime($App.CreationTime))

                    $AppStatus += $AppTemp

                }
            }
        }
    } else {
        Write-Error "Device is not enrolled to MDM."
    }
    return $AppStatus
}