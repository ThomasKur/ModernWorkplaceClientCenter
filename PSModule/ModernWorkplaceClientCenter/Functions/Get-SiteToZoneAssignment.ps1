function Get-SiteToZoneAssignment{
    <#
    .Synopsis
    Returns Internet Explorer Site to Zone assignments.

    .Description
    Returns a list of sites in the Trusted, Intranet or Restricted Sites of Internet explorer which are defined through Group Policy.

    Important: User defined are not returned.

    .Example
    # Displays all sites
    Get-SiteToZoneAssignment
    #>
    [CmdletBinding()]
    param()
    $_RegKeyList1 = @()
    $_RegKeyList2 = @()
    $_RegKeyInfo  = @()
    Write-Verbose "Loading registry key 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey'"
    $_RegKeyList1 = $(Get-Item 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey' -ErrorAction SilentlyContinue)
    Write-Verbose "Loading registry key 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey'"
    $_RegKeyList2 = $(Get-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey' -ErrorAction SilentlyContinue)
    
    
    Write-Information "Found $($_RegKeyList1.Count) Site to zone assignments for Current User."
    Foreach($_RegValue in $_RegKeyList1.Property){
         $Value = ($_RegKeyList1 | Get-ItemProperty).$($_RegValue)
         Switch($Value){
              0 {$_ZoneType = 'My Computer'}
              1 {$_ZoneType = 'Local Intranet Zone'}
              2 {$_ZoneType = 'Trusted sites Zone'}
              3 {$_ZoneType = 'Internet Zone'}
              4 {$_ZoneType = 'Restricted Sites Zonet'}
              Default { break }
         }
         $newEntry = New-Object -TypeName PSObject
         Add-Member -InputObject $newEntry -MemberType NoteProperty -Name "Zone" -Value $_ZoneType
         Add-Member -InputObject $newEntry -MemberType NoteProperty -Name "Url" -Value $_RegValue
         Write-Verbose "Detected '$($newEntry.Url)' --> '$($newEntry.Zone)'"
         $_RegKeyInfo += $newEntry

    }
    Write-Information "Found $($_RegKeyList2.Count) Site to zone assignments for Current Machine."
    Foreach($_RegValue in $_RegKeyList2.Property){
         $Value = ($_RegKeyList2 | Get-ItemProperty).$($_RegValue)
         Switch($Value){
              0 {$_ZoneType = 'My Computer'}
              1 {$_ZoneType = 'Local Intranet Zone'}
              2 {$_ZoneType = 'Trusted sites Zone'}
              3 {$_ZoneType = 'Internet Zone'}
              4 {$_ZoneType = 'Restricted Sites Zonet'}
              Default { break }
         }
         $newEntry = New-Object -TypeName PSObject
         Add-Member -InputObject $newEntry -MemberType NoteProperty -Name "Zone" -Value $_ZoneType
         Add-Member -InputObject $newEntry -MemberType NoteProperty -Name "Url" -Value $_RegValue
         Write-Verbose "Detected '$($newEntry.Url)' --> '$($newEntry.Zone)'"
         $_RegKeyInfo += $newEntry

    }
    return $_RegKeyInfo
}