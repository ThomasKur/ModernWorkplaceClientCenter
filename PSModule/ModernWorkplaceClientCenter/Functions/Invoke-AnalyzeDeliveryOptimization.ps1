function Invoke-AnalyzeDeliveryOptimization {
    <#
    .Synopsis
    Analyzes current device regarding the possibility to use Delivery Optimization.

    .Description
    Delivery Optimization is the built-in feature to optimize data traffic and a lot of Microsoft products and services are using it. Therefore it's crucial, that you are aware of the status in your environment.

    Returns array of Messages with four properties:

    - Testname: Name of the Tets
    - Type: Information, Warning or Error
    - Issue: Description of the issue
    - Possible Cause: Tips on how to solve the issue.

    .Example
    # Displays a deep analyisis of the currently found issues in the system.
    Invoke-AnalyzeDeliveryOptimization

    #>
    [alias("Invoke-AnalyzeDO")]
    param(
    )
    $possibleErrors = @()
    Write-Verbose "Checking Service Status"
    if((get-service "DoSvc").Status -ne "Running"){
        if((get-service "DoSvc").StartType -eq "Automatic"){
            $possibleErrors += New-AnalyzeResult -TestName "Service" -Type Error -Issue "The Delivery Optimization Service (DoSvc) is not running on the system." -PossibleCause "Try to to start it again `nStart-Service -Name DoSvc"
        } else {
            $possibleErrors += New-AnalyzeResult -TestName "Service" -Type Error -Issue "The Delivery Optimization Service (DoSvc) is not running on the system and the start type is not 'Automatic', therefore an administrator has changed this behavior." -PossibleCause "Chnage the startup type to automatic and start the service. `nSet-Service -Name DoSvc -StartupType Automatic`nStart-Service -Name DoSvc"
        }
    }

    Write-Verbose "Checking local Firewall"
    $FwProfiles = Get-NetFirewallProfile
    if($FwProfiles.Count -ne ($FwProfiles | Where-Object{$_.Enabled -eq $true}).Count){
        $possibleErrors += New-AnalyzeResult -TestName "Firewall" -Type Warning -Issue "Not all Windows Firewall profiles are enabled. Therefore, the other FIrewall related warnings can be incorrect, because the profile in the network you would like to use DO is disabled and therefore the firewall rules are not needed." -PossibleCause "Check if a Firewall Profile is used in your network or not. If not, then you can ignore the other Firewall related issues."
    }
    $FwRules = Get-NetFirewallRule @("DeliveryOptimization-UDP-In","DeliveryOptimization-TCP-In")
    if($FwRules.Count -ne 2){
        $possibleErrors += New-AnalyzeResult -TestName "Firewall" -Type Warning -Issue "Not all default Firewall Rules(DeliveryOptimization-UDP-In, DeliveryOptimization-TCP-In) regarding Delivery Optimization are found on your system." -PossibleCause "Perhaps you or another administrator has created custom rules and enabled them. These should allow incoming TCP/UDP 7680 connections on the peers. `n You can verify the connection to a peer by using the following command:`n Test-NetConnection -ComputerName %ipofpeer% -Port 7680"
    } else {
        if($FwRules[0].Profile -ne "Any"){
            $possibleErrors += New-AnalyzeResult -TestName "Firewall" -Type Warning -Issue "The rule $($FwRules[0].Name) is not aplied to all profiles(Public, Private, Domain)." -PossibleCause "Check if the you are using DO in a network which is not assigned to a profile where the rule is active($($FwRules[0].Profile))."
        }
        if($FwRules[1].Profile -ne "Any"){
            $possibleErrors += New-AnalyzeResult -TestName "Firewall" -Type Warning -Issue "The rule $($FwRules[1].Name) is not aplied to all profiles(Public, Private, Domain)." -PossibleCause "Check if the you are using DO in a network which is not assigned to a profile where the rule is active($($FwRules[1].Profile))."
        }
        if($FwRules[0].Action -ne "Allow"){
            $possibleErrors += New-AnalyzeResult -TestName "Firewall" -Type Warning -Issue "The rule $($FwRules[0].Name) does not Allow the Traffic." -PossibleCause "Change the Action to Allow in the rule."
        }
        if($FwRules[1].Action -ne "Allow"){
            $possibleErrors += New-AnalyzeResult -TestName "Firewall" -Type Warning -Issue "The rule $($FwRules[1].Name) does not Allow the Traffic." -PossibleCause "Change the Action to Allow in the rule."
        }
        if($FwRules[0].Direction -ne "Inbound"){
            $possibleErrors += New-AnalyzeResult -TestName "Firewall" -Type Warning -Issue "The rule $($FwRules[0].Name) does not target inbound traffic." -PossibleCause "Change the Direction to inbound in the rule."
        }
        if($FwRules[1].Direction -ne "Inbound"){
            $possibleErrors += New-AnalyzeResult -TestName "Firewall" -Type Warning -Issue "The rule $($FwRules[1].Name) does not target inbound traffic." -PossibleCause "Change the Direction to inbound in the rule."
        }
        if($FwRules[0].Enabled -ne $true){
            $possibleErrors += New-AnalyzeResult -TestName "Firewall" -Type Warning -Issue "The rule $($FwRules[0].Name) is not enabled." -PossibleCause "Enable the rule."
        }
        if($FwRules[1].Enabled -ne $true){
            $possibleErrors += New-AnalyzeResult -TestName "Firewall" -Type Warning -Issue "The rule $($FwRules[1].Name) is not enabled." -PossibleCause "Enable the rule."
        }
    }
    
    Write-Verbose "Conenctivity Tests to Delivery Optimization Service"
    $data = New-Object System.Collections.Generic.List[System.Collections.Hashtable]

    # https://docs.microsoft.com/en-us/windows/privacy/manage-windows-endpoints#windows-update
    $data.Add(@{ TestUrl = 'https://geo-prod.do.dsp.mp.microsoft.com'; UrlPattern = 'https://*.do.dsp.mp.microsoft.com'; ExpectedStatusCode = 403; Description = 'Updates for applications and the OS on Windows 10 1709 and later. Windows Update Delivery Optimization metadata, resiliency, and anti-corruption.'; PerformBluecoatLookup=$false; Verbose=$false }) # many different *-prod.do.dsp.mp.microsoft.com, but geo-prod.do.dsp.mp.microsoft.com is the most common one
    
    $results = New-Object System.Collections.Generic.List[pscustomobject]

    $data | ForEach-Object {
        $connectivity = Get-HttpConnectivity @_
        $results.Add($connectivity)
        if ($connectivity.Blocked -eq $true) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity" -Type "Error" -Issue "Connection blocked `n $($connectivity)" -PossibleCause "Firewall is blocking connection to '$($connectivity.UnblockUrl)'. Delivery Optimization contacts a cloud service for a list of peers. This service uses HTTPS to *.do.dsp.mp.microsoft.com (communication to this service has to be allowed outbound to the Internet even if only local sharing is enabled)."
        }
        if ($connectivity.Resolved -eq $false) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity" -Type "Error" -Issue "DNS name not resolved `n $($connectivity)" -PossibleCause "DNS server not correctly configured."
        }
        if ($connectivity.ExpectedStatusCode -notcontains $connectivity.ActualStatusCode) {
            if($connectivity.ActualStatusCode -eq 407){
                $Cause = "Keep in mind that the proxy has to be set in WinHTTP.`nWindows 1709 and newer: Set the proxy by using netsh or WPAD. --> https://docs.microsoft.com/en-us/windows/desktop/WinHttp/winhttp-autoproxy-support `nWindows 1709 and older: Set the proxy by using 'netsh winhttp set proxy ?' --> https://blogs.technet.microsoft.com/netgeeks/2018/06/19/winhttp-proxy-settings-deployed-by-gpo/ "
             } else {
                $Cause = "Interfering Proxy server can change HTTP status codes."
             }
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity" -Type "Error" -Issue "Returned HTTP Status code '$($connectivity.ActualStatusCode)' is not expected '$($connectivity.ExpectedStatusCode)'`n $($connectivity)" -PossibleCause $Cause
        }
        if ($null -ne $connectivity.ServerCertificate -and $connectivity.ServerCertificate.HasError) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity" -Type "Error" -Issue "Certificate Error when connecting to $($connectivity.TestUrl)`n $(($connectivity.ServerCertificate))" -PossibleCause "Interfering Proxy server can change Certificate or not the Root Certificate is not trusted."
        }
    }

    Write-Verbose "Checking Configuration (Policy)"
    $PolicyDODownloadMode = get-ItemPropertyValue HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization -Name DODownloadMode -ErrorAction SilentlyContinue
    if($null -ne $PolicyDODownloadMode -and @(1,2,3) -contains $PolicyDODownloadMode){
        $possibleErrors += New-AnalyzeResult -TestName "Configuration" -Type "Error" -Issue "A policy is disabling Delivery Optimization and enforce mode $PolicyDODownloadMode.  0=HTTP only, no peering. 1=HTTP blended with peering behind the same NAT. 2=HTTP blended with peering across a private group. Peering occurs on devices in the same Active Directory Site (if exist) or the same domain by default. When this option is selected, peering will cross NATs. To create a custom group use Group ID in combination with Mode 2. 3=HTTP blended with Internet Peering. 99=Simple download mode with no peering. Delivery Optimization downloads using HTTP only and does not attempt to contact the Delivery Optimization cloud services. 100=Bypass mode. Do not use Delivery Optimization and use BITS instead." -PossibleCause "Change the assigned GPO or the local GPO and switch to mode 1,2 or 3. You can find the setting in the following path in GPO: `nComputer Configuration > Policies > Administrative Templates > Windows Components > Delivery Optimization > Download Mode"
    }
    $ConfigDODownloadMode = get-ItemPropertyValue HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config -Name DODownloadMode -ErrorAction SilentlyContinue
    if($null -ne $ConfigDODownloadMode -and @(1,2,3) -contains $ConfigDODownloadMode){
        $possibleErrors += New-AnalyzeResult -TestName "Configuration" -Type "Error" -Issue "The Actual used configuration is disabling Delivery Optimization and uses mode $ConfigDODownloadMode.  0=HTTP only, no peering. 1=HTTP blended with peering behind the same NAT. 2=HTTP blended with peering across a private group. Peering occurs on devices in the same Active Directory Site (if exist) or the same domain by default. When this option is selected, peering will cross NATs. To create a custom group use Group ID in combination with Mode 2. 3=HTTP blended with Internet Peering. 99=Simple download mode with no peering. Delivery Optimization downloads using HTTP only and does not attempt to contact the Delivery Optimization cloud services. 100=Bypass mode. Do not use Delivery Optimization and use BITS instead." -PossibleCause "If you don't have any other warning regarding configuration from GPO or SettingsAppChange, then  change the registry value to mode 1,2 or 3.`nHKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config `nValueName: DODownloadMode"
    }
    $UserSettingsDODownloadMode = get-ItemPropertyValue HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config -Name DODownloadMode -ErrorAction SilentlyContinue
    if($null -ne $UserSettingsDODownloadMode -and @(1,2,3) -contains $UserSettingsDODownloadMode){
        $possibleErrors += New-AnalyzeResult -TestName "Configuration" -Type "Error" -Issue "The user has disabled Delivery Optimization through the settings app and set mode $UserSettingsDODownloadMode.  0=HTTP only, no peering. 1=HTTP blended with peering behind the same NAT. 2=HTTP blended with peering across a private group. Peering occurs on devices in the same Active Directory Site (if exist) or the same domain by default. When this option is selected, peering will cross NATs. To create a custom group use Group ID in combination with Mode 2. 3=HTTP blended with Internet Peering. 99=Simple download mode with no peering. Delivery Optimization downloads using HTTP only and does not attempt to contact the Delivery Optimization cloud services. 100=Bypass mode. Do not use Delivery Optimization and use BITS instead." -PossibleCause "Open the Settings App and search for Delivery Optmization and enable it."
    }
    # No errors detected, return success message
    if ($possibleErrors.Count -eq 0) {
        $possibleErrors += New-AnalyzeResult -TestName "All" -Type Information -Issue "All tests went through successfully." -PossibleCause ""
    }

    return $possibleErrors
}