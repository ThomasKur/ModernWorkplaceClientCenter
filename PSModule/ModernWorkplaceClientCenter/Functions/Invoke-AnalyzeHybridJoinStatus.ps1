function Invoke-AnalyzeHybridJoinStatus {
    <#
    .Synopsis
    Analyzes current status of the device regarding Azure AD Hybrid Join.

    .Description
    Analyzes current status of the device regarding Azure AD Hybrid Join. It checks also AD Service Connection Points and IE Site Assignments and GPO Settings.

    Returns array of Messages with four properties:

    - Testname: Name of the Tets
    - Type: Information, Warning or Error
    - Issue: Description of the issue
    - Possible Cause: Tips on how to solve the issue.

    .Parameter IncludeEventLog
    By specifying this command also the most relevant Windows Event Log entries from the last 10 Minutes related to Azure AD and Hybrid Join are included in the Output of this CmdLet.

    .Example
    # Displays a deep analyisis of the currently found issues in the system.
    Invoke-AnalyzeHybridJoinStatus

    #>
    param(
        [switch]$IncludeEventLog
    )
    $dsreg = Get-DsRegStatus
    $possibleErrors = @()
    if($dsreg.AzureAdJoined -eq "NO"){
        $possibleErrors += New-AnalyzeResult -TestName "AzureAdJoined" -Type Error -Issue "The join to Azure AD has not completed yet." -PossibleCause "Authentication of the computer for a join failed.
        There is an HTTP proxy in the organization that cannot be discovered by the computer
        The computer cannot reach Azure AD to authenticate or Azure DRS for registration
        The computer may not be on the organization's internal network or on VPN with direct line of sight to an on-premises AD domain controller.
        If the computer has a TPM, it can be in a bad state.
        There might be a misconfiguration in the services noted in the document earlier that you will need to verify again. Common examples are:
        - Your federation server does not have WS-Trust endpoints enabled
        - Your federation server does not allow inbound authentication from computers in your network using Integrated Windows Authentication.
        - There is no Service Connection Point object that points to your verified domain name in Azure AD in the AD forest where the computer belongs to."
    }

    if($dsreg.DomainJoined -eq "NO"){
        $possibleErrors += New-AnalyzeResult -TestName "DomainJoined" -Type Error -Issue "This field indicates whether the device is joined to an on-premises Active Directory or not. If the value is NO, the device cannot perform a hybrid Azure AD join." -PossibleCause "Join the device to a domain, otherwise no Hybrid Join will be possible."
    } else {
        # Check Service Connection Point
        $getdomain = [System.Directoryservices.Activedirectory.Domain]::GetCurrentDomain()
        $getdomaindn = $getdomain.Name.Split('.') -join ",DC="
        $scp = New-Object System.DirectoryServices.DirectoryEntry
        $scp.Path = "LDAP://CN=62a0ff2e-97b9-4513-943f-0d221bd30080,CN=Device Registration Configuration,CN=Services,CN=Configuration,DC=$getdomaindn";
        if([String]::IsNullOrWhiteSpace($scp.Keywords)){
            $possibleErrors += New-AnalyzeResult -TestName "ADServiceConnectionPoint" -Type Error -Issue "No Service COnnection Point defined in Active Directory." -PossibleCause "Join the device to a domain, otherwise no Hybrid Join will be possible."
        } else {
            $possibleErrors += New-AnalyzeResult -TestName "ADServiceConnectionPoint" -Type Warning -Issue "Current Value: $($scp.Keywords) `n Validate if the AzureAD GUID and tenant name is correct." -PossibleCause "Sometimes there are incorrect vslues left from a PoC or Testenvironment which can result in an incorrect entriy."
        }
    }

    if($dsreg.WorkplaceJoined -eq "YES"){
        if($dsreg.DomainJoined -eq "YES"){
            $possibleErrors += New-AnalyzeResult -TestName "WorkplaceJoined" -Type Error -Issue "A work or school account was added before the completion of a hybrid Azure AD join." -PossibleCause "If the value is YES, a work or school account was added prior to the completion of the hybrid Azure AD join. In this case, the account is ignored when using the Anniversary Update version of Windows 10 (1607). This value should be NO for a domain-joined computer that is also hybrid Azure AD joined."
        }
    }

    if($dsreg.WamDefaultSet -eq "NO"){
        $possibleErrors += New-AnalyzeResult -TestName "WamDefaultSet" -Type Error -Issue "These fields indicate whether the user has successfully authenticated to Azure AD when signing in to the device." -PossibleCause "If the values are NO, it could be due:
        Bad storage key (STK) in TPM associated with the device upon registration (check the KeySignTest while running elevated).
        Alternate Login ID
        HTTP Proxy not found"
    }

    if($dsreg.AzureAdPrt -eq "NO"){
        $possibleErrors += New-AnalyzeResult -TestName "AzureAdPrt" -Type Error -Issue "These fields indicate whether the user has successfully authenticated to Azure AD when signing in to the device." -PossibleCause "If the values are NO, it could be due:
        Bad storage key (STK) in TPM associated with the device upon registration (check the KeySignTest while running elevated).
        Alternate Login ID
        HTTP Proxy not found"
    }
    $IESites = Get-SiteToZoneAssignment | Where-Object { $_.Url -match "https://autologon.microsoftazuread-sso.com" -and $_.Zone -eq "Local Intranet Zone" }
    if($null -eq $IESites){
        $possibleErrors += New-AnalyzeResult -TestName "IE Site Assignment" -Type Warning -Issue "We could not detect https://autologon.microsoftazuread-sso.com in the Local Intranet Zone of Internet Explorer." -PossibleCause "One possibility is, that you have configured it manually on this test client in Internet Explorer. This check only validates, if it is assigned through a group policy.
        The second option is, that you configured a toplevel site in the intranet site and not especially the above mentioned URL including the protocol."
    }

    $IESites = Get-SiteToZoneAssignment | Where-Object { $_.Url -match "https://device.login.microsoftonline.com" -and $_.Zone -eq "Local Intranet Zone" }
    if($null -eq $IESites){
        $possibleErrors += New-AnalyzeResult -TestName "IE Site Assignment" -Type Warning -Issue "We could not detect https://device.login.microsoftonline.com in the Local Intranet Zone of Internet Explorer. To avoid certificate prompts when users in register devices authenticate to Azure AD you can push a policy to your domain-joined devices to add the following URL to the Local Intranet zone in Internet Explorer." -PossibleCause "One possibility is, that you have configured it manually on this test client in Internet Explorer. This check only validates, if it is assigned through a group policy.
        The second option is, that you configured a toplevel site in the intranet site and not especially the above mentioned URL including the protocol."
    }
    # GPO Checks
    try{
        $IEStatusBarUpdates = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\1" -Name 2103 -ErrorAction SilentlyContinue
    } catch {
        $IEStatusBarUpdates = $null
    }
    if($IEStatusBarUpdates -eq 3){
        $possibleErrors += New-AnalyzeResult -TestName "IE Update Status Bar" -Type Error -Issue "The following setting should be enabled in the user's intranet zone, if you plan to use SSO: 'Allow status bar updates via script.'. This is also the default value, which means you have a policy which disables this explicity." -PossibleCause "Reconfigure the policy"
    }
    try{
        $AutoDeviceReg = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin" -Name autoWorkplaceJoin -ErrorAction SilentlyContinue
    } catch {
        $AutoDeviceReg = $null
    }
    if($AutoDeviceReg -ne 1){
        $possibleErrors += New-AnalyzeResult -TestName "Auto Workplace Join GPO" -Type Error -Issue "The following setting should be enabled to trigger the automatic Azure AD Hybrid Join." -PossibleCause "Reconfigure the policy: Computer Configuration > Policies > Administrative Templates > Windows Components > Device Registration > Register domain-joined computers as devices"
    }
    # Analyze Eventlogs
    if($IncludeEventLog){
        $AADEvents = Get-WinEvent -LogName "Microsoft-Windows-AAD/Operational" | Where-Object { ($_.LevelDisplayName -eq "Error" -or $_.LevelDisplayName -eq "Warning") -and $_.TimeCreated -gt [DateTime]::Now.AddMinutes(-10)  }
        foreach($AADEvent in ($AADEvents | Group-Object -Property Id)){
            $possibleErrors += New-AnalyzeResult -TestName "EventLog-AAD" -Type ($AADEvent.Group[0].LevelDisplayName) -Issue "EventId: $($AADEvent.Name)`n$($AADEvent.Group[0].Message)" -PossibleCause ""
        }
        $WPJoinEvents = Get-WinEvent -LogName "Microsoft-Windows-Workplace Join/Admin" | Where-Object { ($_.LevelDisplayName -eq "Error" -or $_.LevelDisplayName -eq "Warning") -and $_.TimeCreated -gt [DateTime]::Now.AddMinutes(-10)  }
        foreach($WPJoinEvent in ($WPJoinEvents | Group-Object -Property Id)){
            $possibleErrors += New-AnalyzeResult -TestName "EventLog-WorkplaceJoin" -Type ($WPJoinEvent.Group[0].LevelDisplayName) -Issue "EventId: $($WPJoinEvent.Name)`n$($WPJoinEvent.Group[0].Message)" -PossibleCause ""
        }
    }
    # No errors detected, return success message
    if($null -eq $possibleErrors){
        $possibleErrors += New-AnalyzeResult -TestName "All" -Type Information -Issue "All tests went trough successfull." -PossibleCause ""
    }

    return $possibleErrors
}