function Invoke-TestAutopilotNetworkEndpoint {
    <#
    .Synopsis
    Analyzes network connectivity for Autopilot.

    .Description
    Analyzes network connectivity for Autopilot.

    Returns array of Messages with four properties:

    - Testname: Name of the Tets
    - Type: Information, Warning or Error
    - Issue: Description of the issue
    - Possible Cause: Tips on how to solve the issue.

    
    .Example
    # Displays a deep analyisis of the currently found issues in the system.
    Invoke-TestAutopilotNetworkEndpoint -UPNDomain "wpninja.ch"

    #>
    param(
        [String]$UPNDomain,
        [String]$ConfigMgrCMGUrl
    )
    $possibleErrors = @()
    #region HybridJoin Connectivity Tests
    $isVerbose = $VerbosePreference -eq 'Continue'

    $data = New-Object System.Collections.Generic.List[System.Collections.Hashtable]

    # https://docs.microsoft.com/en-us/azure/active-directory/devices/hybrid-azuread-join-manual-steps

    $data.Add(@{ TestUrl = 'https://enterpriseregistration.windows.net'; ExpectedStatusCode = 404; PerformBluecoatLookup = $PerformBluecoatLookup; Verbose = $isVerbose }) 
    $data.Add(@{ TestUrl = 'https://login.microsoftonline.com'; IgnoreCertificateValidationErrors = $false; PerformBluecoatLookup = $PerformBluecoatLookup; Verbose = $isVerbose })
    $data.Add(@{ TestUrl = 'https://device.login.microsoftonline.com'; IgnoreCertificateValidationErrors = $true; PerformBluecoatLookup = $PerformBluecoatLookup; Verbose = $isVerbose }) 
    $data.Add(@{ TestUrl = 'https://autologon.microsoftazuread-sso.com'; ExpectedStatusCode = 404; Description = 'URL required for Seamless SSO'; IgnoreCertificateValidationErrors = $true; PerformBluecoatLookup = $PerformBluecoatLookup; Verbose = $isVerbose })
    
    $results = New-Object System.Collections.Generic.List[pscustomobject]

    $data | ForEach-Object {
        $connectivity = Get-HttpConnectivity @_
        $results.Add($connectivity)
        if ($connectivity.Blocked -eq $true) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-AADHybridJoin" -Type "Error" -Issue "Connection blocked `n $($connectivity)" -PossibleCause "Firewall is blocking connection to '$($connectivity.UnblockUrl)'."
        } elseif ($connectivity.ExpectedStatusCode -notcontains $connectivity.ActualStatusCode) {
            if($connectivity.ActualStatusCode -eq 407){
                $Cause = "Keep in mind that the proxy has to be set in WinHTTP.`nWindows 1709 and newer: Set the proxy by using netsh or WPAD. --> https://docs.microsoft.com/en-us/windows/desktop/WinHttp/winhttp-autoproxy-support `nWindows 1709 and older: Set the proxy by using 'netsh winhttp set proxy ?' --> https://blogs.technet.microsoft.com/netgeeks/2018/06/19/winhttp-proxy-settings-deployed-by-gpo/ "
             } else {
                $Cause = "Interfering Proxy server can change HTTP status codes."
             }
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-AADHybridJoin" -Type "Error" -Issue "Returned HTTP Status code '$($connectivity.ActualStatusCode)' is not expected '$($connectivity.ExpectedStatusCode)'`n $($connectivity)" -PossibleCause $Cause
        }
        if ($connectivity.Resolved -eq $false) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-AADHybridJoin" -Type "Error" -Issue "DNS name not resolved `n $($connectivity)" -PossibleCause "DNS server not correctly configured."
        }
        
        if ($null -ne $connectivity.ServerCertificate -and $connectivity.ServerCertificate.HasError) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-AADHybridJoin" -Type "Error" -Issue "Certificate Error when connecting to $($connectivity.TestUrl)`n $(($connectivity.ServerCertificate))" -PossibleCause "Interfering Proxy server can change Certificate or not the Root Certificate is not trusted."
        }
    }
    #endregion 
    #region DO
    Write-Verbose "Conenctivity Tests to Delivery Optimization Service"
    $data = New-Object System.Collections.Generic.List[System.Collections.Hashtable]

    # https://docs.microsoft.com/en-us/windows/privacy/manage-windows-endpoints#windows-update
    $data.Add(@{ TestUrl = 'https://geo-prod.do.dsp.mp.microsoft.com'; UrlPattern = 'https://*.do.dsp.mp.microsoft.com'; ExpectedStatusCode = 403; Description = 'Updates for applications and the OS on Windows 10 1709 and later. Windows Update Delivery Optimization metadata, resiliency, and anti-corruption.'; PerformBluecoatLookup=$false; Verbose=$false }) # many different *-prod.do.dsp.mp.microsoft.com, but geo-prod.do.dsp.mp.microsoft.com is the most common one
    
    $results = New-Object System.Collections.Generic.List[pscustomobject]

    $data | ForEach-Object {
        $connectivity = Get-HttpConnectivity @_
        $results.Add($connectivity)
        if ($connectivity.Blocked -eq $true) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-DeliveryOptimization" -Type "Error" -Issue "Connection blocked `n $($connectivity)" -PossibleCause "Firewall is blocking connection to '$($connectivity.UnblockUrl)'. Delivery Optimization contacts a cloud service for a list of peers. This service uses HTTPS to *.do.dsp.mp.microsoft.com (communication to this service has to be allowed outbound to the Internet even if only local sharing is enabled)."
        } elseif ($connectivity.ExpectedStatusCode -notcontains $connectivity.ActualStatusCode) {
            if($connectivity.ActualStatusCode -eq 407){
                $Cause = "Keep in mind that the proxy has to be set in WinHTTP.`nWindows 1709 and newer: Set the proxy by using netsh or WPAD. --> https://docs.microsoft.com/en-us/windows/desktop/WinHttp/winhttp-autoproxy-support `nWindows 1709 and older: Set the proxy by using 'netsh winhttp set proxy ?' --> https://blogs.technet.microsoft.com/netgeeks/2018/06/19/winhttp-proxy-settings-deployed-by-gpo/ "
             } else {
                $Cause = "Interfering Proxy server can change HTTP status codes."
             }
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-DeliveryOptimization" -Type "Error" -Issue "Returned HTTP Status code '$($connectivity.ActualStatusCode)' is not expected '$($connectivity.ExpectedStatusCode)'`n $($connectivity)" -PossibleCause $Cause
        }
        if ($connectivity.Resolved -eq $false) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-DeliveryOptimization" -Type "Error" -Issue "DNS name not resolved `n $($connectivity)" -PossibleCause "DNS server not correctly configured."
        }
        
        if ($null -ne $connectivity.ServerCertificate -and $connectivity.ServerCertificate.HasError) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-DeliveryOptimization" -Type "Error" -Issue "Certificate Error when connecting to $($connectivity.TestUrl)`n $(($connectivity.ServerCertificate))" -PossibleCause "Interfering Proxy server can change Certificate or not the Root Certificate is not trusted."
        }
    }
    #endregion DO
    #region IntuneEnrollment
    #DNS Name Resolution Intune Enrollment
    if(-not [String]::IsNullOrWhiteSpace($UPNDomain)){ 
          $dns = Resolve-DnsName "EnterpriseEnrollment.$UPNDomain" -DnsOnly
          if($dns[0].NameHost -ne "EnterpriseEnrollment-s.manage.microsoft.com"){
               $possibleErrors += New-AnalyzeResult -TestName "DNSCheck-IntuneEnrollment" -Type Warning -Issue "The DNS CName 'EnterpriseEnrollment.$UPNDomain' is not pointing to 'EnterpriseEnrollment-s.manage.microsoft.com'. This is not required for Autoenrollment, but without it the servername has to be entered during a manual enrollment to Intune." -PossibleCause "Add the CName in your DNS Zone."
          }
          $dns = Resolve-DnsName "EnterpriseRegistration.$UPNDomain" -DnsOnly
          if($dns[0].NameHost -ne "EnterpriseRegistration.windows.net"){
               $possibleErrors += New-AnalyzeResult -TestName "DNSCheck-IntuneEnrollment" -Type Warning -Issue "The DNS CName 'EnterpriseRegistration.$UPNDomain' is not pointing to 'EnterpriseRegistration.windows.net'. This is not required for Autoenrollment, but without it the servername has to be entered during a manual enrollment to Intune." -PossibleCause "Add the CName in your DNS Zone."
          }
    }
    #endregion IntuneEnrollment
    #region CMG
    Write-Verbose "Conenctivity Tests to ConfigMgrCMG Service"
    $data = New-Object System.Collections.Generic.List[System.Collections.Hashtable]
    if($ConfigMgrCMGUrl){
        $data.Add(@{ TestUrl = "https://$ConfigMgrCMGUrl"; UrlPattern = "https://$ConfigMgrCMGUrl"; ExpectedStatusCode = 403;  IgnoreCertificateValidationErrors=$true; Description = 'ConfigMgr Cloud Management Gateway needs to be available during enrollment.'; PerformBluecoatLookup=$false; Verbose=$false }) 
    }
    $results = New-Object System.Collections.Generic.List[pscustomobject]

    $data | ForEach-Object {
        $connectivity = Get-HttpConnectivity @_
        $results.Add($connectivity)
        if ($connectivity.Blocked -eq $true) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-CMG" -Type "Error" -Issue "Connection blocked `n $($connectivity)" -PossibleCause "Firewall is blocking connection to '$($connectivity.UnblockUrl)'."
        } elseif ($connectivity.ExpectedStatusCode -notcontains $connectivity.ActualStatusCode) {
            if($connectivity.ActualStatusCode -eq 407){
                $Cause = "Keep in mind that the proxy has to be set in WinHTTP.`nWindows 1709 and newer: Set the proxy by using netsh or WPAD. --> https://docs.microsoft.com/en-us/windows/desktop/WinHttp/winhttp-autoproxy-support `nWindows 1709 and older: Set the proxy by using 'netsh winhttp set proxy ?' --> https://blogs.technet.microsoft.com/netgeeks/2018/06/19/winhttp-proxy-settings-deployed-by-gpo/ "
             } else {
                $Cause = "Interfering Proxy server can change HTTP status codes."
             }
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-CMG" -Type "Error" -Issue "Returned HTTP Status code '$($connectivity.ActualStatusCode)' is not expected '$($connectivity.ExpectedStatusCode)'`n $($connectivity)" -PossibleCause $Cause
        }
        if ($connectivity.Resolved -eq $false) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-CMG" -Type "Error" -Issue "DNS name not resolved `n $($connectivity)" -PossibleCause "DNS server not correctly configured."
        }
        
        if ($null -ne $connectivity.ServerCertificate -and $connectivity.ServerCertificate.HasError) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-CMG" -Type "Error" -Issue "Certificate Error when connecting to $($connectivity.TestUrl)`n $(($connectivity.ServerCertificate))" -PossibleCause "Interfering Proxy server can change Certificate or not the Root Certificate is not trusted."
        }
    }
    #endregion CMG
    #region NCSI Network Connection Status Indicator
    Write-Verbose "Conenctivity Tests to NCSI Service"
    $data = New-Object System.Collections.Generic.List[System.Collections.Hashtable]
    if($ConfigMgrCMGUrl){
        $data.Add(@{ TestUrl = "http://www.msftconnecttest.com/"; UrlPattern = "http://www.msftconnecttest.com/"; ExpectedStatusCode = 200; Description = 'Windows must be able to tell that the device is able to access the internet. For more information, see Network Connection Status Indicator (NCSI). www.msftconnecttest.com must be resolvable via DNS and accessible via HTTP.'; PerformBluecoatLookup=$false; Verbose=$false }) 
    }
    $results = New-Object System.Collections.Generic.List[pscustomobject]

    $data | ForEach-Object {
        $connectivity = Get-HttpConnectivity @_
        $results.Add($connectivity)
        if ($connectivity.Blocked -eq $true) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-NCSI" -Type "Error" -Issue "Connection blocked `n $($connectivity)" -PossibleCause "Firewall is blocking connection to '$($connectivity.UnblockUrl)'."
        } elseif ($connectivity.ExpectedStatusCode -notcontains $connectivity.ActualStatusCode) {
            if($connectivity.ActualStatusCode -eq 407){
                $Cause = "Keep in mind that the proxy has to be set in WinHTTP.`nWindows 1709 and newer: Set the proxy by using netsh or WPAD. --> https://docs.microsoft.com/en-us/windows/desktop/WinHttp/winhttp-autoproxy-support `nWindows 1709 and older: Set the proxy by using 'netsh winhttp set proxy ?' --> https://blogs.technet.microsoft.com/netgeeks/2018/06/19/winhttp-proxy-settings-deployed-by-gpo/ "
             } else {
                $Cause = "Interfering Proxy server can change HTTP status codes."
             }
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-NCSI" -Type "Error" -Issue "Returned HTTP Status code '$($connectivity.ActualStatusCode)' is not expected '$($connectivity.ExpectedStatusCode)'`n $($connectivity)" -PossibleCause $Cause
        }
        if ($connectivity.Resolved -eq $false) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-NCSI" -Type "Error" -Issue "DNS name not resolved `n $($connectivity)" -PossibleCause "DNS server not correctly configured."
        }
        
        if ($null -ne $connectivity.ServerCertificate -and $connectivity.ServerCertificate.HasError) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-NCSI" -Type "Error" -Issue "Certificate Error when connecting to $($connectivity.TestUrl)`n $(($connectivity.ServerCertificate))" -PossibleCause "Interfering Proxy server can change Certificate or not the Root Certificate is not trusted."
        }
    }
    #endregion  NCSI Network Connection Status Indicator
    #region Autopilot
    Write-Verbose "Connectivity Tests to Autopilot Service"
    $data = New-Object System.Collections.Generic.List[System.Collections.Hashtable]

    $data.Add(@{ TestUrl = 'https://cs.dds.microsoft.com/'; UrlPattern = 'https://cs.dds.microsoft.com/'; ExpectedStatusCode = 503; Description = 'After a network connection is in place, each Windows 10 device will contact the Windows Autopilot Deployment Service. With Windows 10 version 1903 and above, the following URLs are used.'; PerformBluecoatLookup=$false; Verbose=$false }) 
    $data.Add(@{ TestUrl = 'https://ztd.dds.microsoft.com'; UrlPattern = 'https://ztd.dds.microsoft.com'; ExpectedStatusCode = 503; Description = 'After a network connection is in place, each Windows 10 device will contact the Windows Autopilot Deployment Service. With Windows 10 version 1903 and above, the following URLs are used.'; PerformBluecoatLookup=$false; Verbose=$false }) 
    $results = New-Object System.Collections.Generic.List[pscustomobject]

    $data | ForEach-Object {
        $connectivity = Get-HttpConnectivity @_
        $results.Add($connectivity)
        if ($connectivity.Blocked -eq $true) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-Autopilot" -Type "Error" -Issue "Connection blocked `n $($connectivity)" -PossibleCause "Firewall is blocking connection to '$($connectivity.UnblockUrl)'. Autopilot requires this url without Proxy Authentication."
        } elseif ($connectivity.ExpectedStatusCode -notcontains $connectivity.ActualStatusCode) {
            if($connectivity.ActualStatusCode -eq 407){
                $Cause = "Keep in mind that the proxy has to be set in WinHTTP.`nWindows 1709 and newer: Set the proxy by using netsh or WPAD. --> https://docs.microsoft.com/en-us/windows/desktop/WinHttp/winhttp-autoproxy-support `nWindows 1709 and older: Set the proxy by using 'netsh winhttp set proxy ?' --> https://blogs.technet.microsoft.com/netgeeks/2018/06/19/winhttp-proxy-settings-deployed-by-gpo/ "
             } else {
                $Cause = "Interfering Proxy server can change HTTP status codes."
             }
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-Autopilot" -Type "Error" -Issue "Returned HTTP Status code '$($connectivity.ActualStatusCode)' is not expected '$($connectivity.ExpectedStatusCode)'`n $($connectivity)" -PossibleCause $Cause
        }
        if ($connectivity.Resolved -eq $false) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-Autopilot" -Type "Error" -Issue "DNS name not resolved `n $($connectivity)" -PossibleCause "DNS server not correctly configured."
        }
        
        if ($null -ne $connectivity.ServerCertificate -and $connectivity.ServerCertificate.HasError) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-Autopilot" -Type "Error" -Issue "Certificate Error when connecting to $($connectivity.TestUrl)`n $(($connectivity.ServerCertificate))" -PossibleCause "Interfering Proxy server can change Certificate or not the Root Certificate is not trusted."
        }
    }
    #endregion Autopilot
    #region AzureAD Connectivity
    $possibleErrors += Invoke-AnalyzeAzureConnectivity -OnlyRequired | Where-Object { $_.TestName -ne "All" }
    #endregion AzureAD Connectivity
    #region NTP Server
    try{
        $timeFromNtp = Get-NtpTime time.windows.com
        if([datetime]'1/1/1900' -eq $timeFromNtp){
            throw "Failed to get time."
        }
    } catch {
        $possibleErrors += New-AnalyzeResult -TestName "Connectivity-NTP" -Type "Error" -Issue "Failed to get time from time.windows.com. $($_.Exception)" -PossibleCause "Firewall is blocking access to time.windows.com UDP 123."
    }
    
    #endregion NTP Server
    #region TPM Certificates
    Write-Verbose "Connectivity Tests to TPM Firmware Certificates Service"
    $data = New-Object System.Collections.Generic.List[System.Collections.Hashtable]

    $data.Add(@{ TestUrl = 'https://ekop.intel.com/ekcertservice/'; UrlPattern = 'https://ekop.intel.com/ekcertservice/'; ExpectedStatusCode = 404; Description = 'Firmware TPM devices, which are only provided by Intel, AMD, or Qualcomm, do not include all needed certificates at boot time and must be able to retrieve them from the manufacturer on first use. Devices with discrete TPM chips(including ones from any other manufacturer) come with these certificates preinstalled. Make sure that these URLs are accessible for each firmware TPM provider so that certificates can be successfully requested.'; PerformBluecoatLookup=$false; Verbose=$false }) 
    $data.Add(@{ TestUrl = 'https://ekcert.spserv.microsoft.com/EKCertificate/GetEKCertificate/v1'; UrlPattern = 'https://ekcert.spserv.microsoft.com/EKCertificate/GetEKCertificate/v1'; ExpectedStatusCode = 405; Description = 'Firmware TPM devices, which are only provided by Intel, AMD, or Qualcomm, do not include all needed certificates at boot time and must be able to retrieve them from the manufacturer on first use. Devices with discrete TPM chips(including ones from any other manufacturer) come with these certificates preinstalled. Make sure that these URLs are accessible for each firmware TPM provider so that certificates can be successfully requested.'; PerformBluecoatLookup=$false; Verbose=$false }) 
    $data.Add(@{ TestUrl = 'https://ftpm.amd.com/'; UrlPattern = 'https://ftpm.amd.com/'; ExpectedStatusCode = 200; Description = 'Firmware TPM devices, which are only provided by Intel, AMD, or Qualcomm, do not include all needed certificates at boot time and must be able to retrieve them from the manufacturer on first use. Devices with discrete TPM chips(including ones from any other manufacturer) come with these certificates preinstalled. Make sure that these URLs are accessible for each firmware TPM provider so that certificates can be successfully requested.'; PerformBluecoatLookup=$false; Verbose=$false }) 
    $results = New-Object System.Collections.Generic.List[pscustomobject]

    $data | ForEach-Object {
        $connectivity = Get-HttpConnectivity @_
        $results.Add($connectivity)
        if ($connectivity.Blocked -eq $true) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-TPM" -Type "Error" -Issue "Connection blocked `n $($connectivity)" -PossibleCause "Firewall is blocking connection to '$($connectivity.UnblockUrl)'. Autopilot requires this url without Proxy Authentication."
        } elseif ($connectivity.ExpectedStatusCode -notcontains $connectivity.ActualStatusCode) {
            if($connectivity.ActualStatusCode -eq 407){
                $Cause = "Keep in mind that the proxy has to be set in WinHTTP.`nWindows 1709 and newer: Set the proxy by using netsh or WPAD. --> https://docs.microsoft.com/en-us/windows/desktop/WinHttp/winhttp-autoproxy-support `nWindows 1709 and older: Set the proxy by using 'netsh winhttp set proxy ?' --> https://blogs.technet.microsoft.com/netgeeks/2018/06/19/winhttp-proxy-settings-deployed-by-gpo/ "
             } else {
                $Cause = "Interfering Proxy server can change HTTP status codes."
             }
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-TPM" -Type "Error" -Issue "Returned HTTP Status code '$($connectivity.ActualStatusCode)' is not expected '$($connectivity.ExpectedStatusCode)'`n $($connectivity)" -PossibleCause $Cause
        }
        if ($null -ne $connectivity.ServerCertificate -and $connectivity.ServerCertificate.HasError) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-TPM" -Type "Error" -Issue "Certificate Error when connecting to $($connectivity.TestUrl)`n $(($connectivity.ServerCertificate))" -PossibleCause "Interfering Proxy server can change Certificate or not the Root Certificate is not trusted."
        }
        if ($connectivity.Resolved -eq $false) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-TPM" -Type "Error" -Issue "DNS name not resolved `n $($connectivity)" -PossibleCause "DNS server not correctly configured."
        }
    }
    #endregion TPM Certificates
    #region Windows Telemetry
    Write-Verbose "Connectivity Tests to Windows Telemetry Service"
    $data = New-Object System.Collections.Generic.List[System.Collections.Hashtable]

    # https://docs.microsoft.com/en-us/windows/privacy/configure-windows-diagnostic-data-in-your-organization#endpoints



    $data.Add(@{ TestUrl = 'https://v10.vortex-win.data.microsoft.com/collect/v1'; ExpectedStatusCode = 400; Description = 'Diagnostic/telemetry data for Windows 10 1607 and later.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })
    $data.Add(@{ TestUrl = 'https://v20.vortex-win.data.microsoft.com/collect/v1'; ExpectedStatusCode = 400; Description = 'Diagnostic/telemetry data for Windows 10 1703 and later.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })
    $data.Add(@{ TestUrl = 'https://settings-win.data.microsoft.com'; ExpectedStatusCode = 404; Description = 'Used by applications, such as Windows Connected User Experiences and Telemetry component and Windows Insider Program, to dynamically update their configuration.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })
    $data.Add(@{ TestUrl = 'https://watson.telemetry.microsoft.com'; ExpectedStatusCode = 404; Description = 'Windows Error Reporting.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })
    $data.Add(@{ TestUrl = 'https://ceuswatcab01.blob.core.windows.net'; ExpectedStatusCode = 400; Description = 'Windows Error Reporting Central US 1.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })
    $data.Add(@{ TestUrl = 'https://ceuswatcab02.blob.core.windows.net'; ExpectedStatusCode = 400; Description = 'Windows Error Reporting Central US 2.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })
    $data.Add(@{ TestUrl = 'https://eaus2watcab01.blob.core.windows.net'; ExpectedStatusCode = 400; Description = 'Windows Error Reporting East US 1.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })
    $data.Add(@{ TestUrl = 'https://eaus2watcab02.blob.core.windows.net'; ExpectedStatusCode = 400; Description = 'Windows Error Reporting East US 2.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })
    $data.Add(@{ TestUrl = 'https://weus2watcab01.blob.core.windows.net'; ExpectedStatusCode = 400; Description = 'Windows Error Reporting West US 1.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })
    $data.Add(@{ TestUrl = 'https://weus2watcab02.blob.core.windows.net'; ExpectedStatusCode = 400; Description = 'Windows Error Reporting West US 2.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })    
    $data.Add(@{ TestUrl = 'https://oca.telemetry.microsoft.com'; ExpectedStatusCode = 404; Description = 'Online Crash Analysis.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })
    $data.Add(@{ TestUrl = 'https://vortex.data.microsoft.com/collect/v1'; ExpectedStatusCode = 400; Description = 'OneDrive app for Windows 10.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

     # https://docs.microsoft.com/en-us/windows/deployment/update/windows-analytics-get-started#enable-data-sharing



    $data.Add(@{ TestUrl = 'https://v10.events.data.microsoft.com'; ExpectedStatusCode = 404; Description = 'Connected User Experience and Diagnostic component endpoint for use with Windows 10 1803 and later'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://v10.vortex-win.data.microsoft.com'; ExpectedStatusCode = 404; Description = 'Connected User Experience and Diagnostic component endpoint for Windows 10 1709 and earlier'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://vortex.data.microsoft.com'; ExpectedStatusCode = 404; Description = 'Connected User Experience and Diagnostic component endpoint for operating systems older than Windows 10'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://v10c.events.data.microsoft.com'; ExpectedStatusCode = 404; Description = 'Connected User Experience and Diagnostic component endpoint for use with Windows 10 releases that have the September 2018, or later, Cumulative Update installed: KB4457127 (1607), KB4457141 (1703), KB4457136 (1709), KB4458469 (1803).'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://settings-win.data.microsoft.com'; ExpectedStatusCode = 404; Description = 'Enables the compatibility update to send data to Microsoft.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://adl.windows.com'; ExpectedStatusCode = 404; Description = 'Allows the compatibility update to receive the latest compatibility data from Microsoft.'; IgnoreCertificateValidationErrors=$true; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    

    $data | ForEach-Object {
        $connectivity = Get-HttpConnectivity @_
        $results.Add($connectivity)
        if ($connectivity.Blocked -eq $true) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-Telemetry" -Type "Error" -Issue "Connection blocked `n $($connectivity)" -PossibleCause "Firewall is blocking connection to '$($connectivity.UnblockUrl)'. Autopilot requires this url without Proxy Authentication."
        } elseif ($connectivity.ExpectedStatusCode -notcontains $connectivity.ActualStatusCode) {
            if($connectivity.ActualStatusCode -eq 407){
                $Cause = "Keep in mind that the proxy has to be set in WinHTTP.`nWindows 1709 and newer: Set the proxy by using netsh or WPAD. --> https://docs.microsoft.com/en-us/windows/desktop/WinHttp/winhttp-autoproxy-support `nWindows 1709 and older: Set the proxy by using 'netsh winhttp set proxy ?' --> https://blogs.technet.microsoft.com/netgeeks/2018/06/19/winhttp-proxy-settings-deployed-by-gpo/ "
             } else {
                $Cause = "Interfering Proxy server can change HTTP status codes."
             }
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-Telemetry" -Type "Error" -Issue "Returned HTTP Status code '$($connectivity.ActualStatusCode)' is not expected '$($connectivity.ExpectedStatusCode)'`n $($connectivity)" -PossibleCause $Cause
        }
        if ($connectivity.Resolved -eq $false) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-Telemetry" -Type "Error" -Issue "DNS name not resolved `n $($connectivity)" -PossibleCause "DNS server not correctly configured."
        }
        
        if ($null -ne $connectivity.ServerCertificate -and $connectivity.ServerCertificate.HasError) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-Telemetry" -Type "Error" -Issue "Certificate Error when connecting to $($connectivity.TestUrl)`n $(($connectivity.ServerCertificate))" -PossibleCause "Interfering Proxy server can change Certificate or not the Root Certificate is not trusted."
        }
    }


    #endregion Windows Telemetry
    #region Windows Defender
    Write-Verbose "Connectivity Tests to Windows Defender Service"
    $data = New-Object System.Collections.Generic.List[System.Collections.Hashtable]

    # https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-defender-antivirus/configure-network-connections-windows-defender-antivirus#allow-connections-to-the-windows-defender-antivirus-cloud


    $data.Add(@{ TestUrl = 'https://wdcp.microsoft.com'; ExpectedStatusCode = 503; Description = 'Windows Defender Antivirus cloud-delivered protection service, also referred to as Microsoft Active Protection Service (MAPS). Used by Windows Defender Antivirus to provide cloud-delivered protection.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose }) # cloud-delivered protection service aka MAPS https://cloudblogs.microsoft.com/enterprisemobility/2016/05/31/important-changes-to-microsoft-active-protection-service-maps-endpoint/

    $data.Add(@{ TestUrl = 'https://wdcpalt.microsoft.com'; ExpectedStatusCode = 503; Description = 'Windows Defender Antivirus cloud-delivered protection service, also referred to as Microsoft Active Protection Service (MAPS). Used by Windows Defender Antivirus to provide cloud-delivered protection.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose }) # cloud-delivered protection service aka MAPS https://cloudblogs.microsoft.com/enterprisemobility/2016/05/31/important-changes-to-microsoft-active-protection-service-maps-endpoint/

    $data.Add(@{ TestUrl = 'https://update.microsoft.com'; UrlPattern='https://*.update.microsoft.com'; Description = 'Microsoft Update Service (MU). Signature and product updates.'; IgnoreCertificateValidationErrors=$true; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://download.microsoft.com'; UrlPattern='https://*.download.microsoft.com'; Description = 'Alternate location for Windows Defender Antivirus definition updates if the installed definitions fall out of date (7 or more days behind).'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://onboardingpackageseusprd.blob.core.windows.net'; UrlPattern='https://*.blob.core.windows.net'; Description = 'Malware submission storage. Upload location for files submitted to Microsoft via the Submission form or automatic sample submission.'; ExpectedStatusCode = 400; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose }) # todo need to change to different URL to represent upload location for https://www.microsoft.com/en-us/wdsi/filesubmission

    $data.Add(@{ TestUrl = 'http://www.microsoft.com/pkiops/crl'; ExpectedStatusCode = 404; Description = 'Microsoft Certificate Revocation List (CRL). Used by Windows when creating the SSL connection to MAPS for updating the CRL.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'http://www.microsoft.com/pkiops/certs'; ExpectedStatusCode = 404; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'http://crl.microsoft.com/pki/crl/products'; ExpectedStatusCode = 404; Description = 'Microsoft Certificate Revocation List (CRL). Used by Windows when creating the SSL connection to MAPS for updating the CRL.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'http://www.microsoft.com/pki/certs'; ExpectedStatusCode = 404; Description = 'Microsoft certificates.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://msdl.microsoft.com/download/symbols'; Description = 'Microsoft Symbol Store. Used by Windows Defender Antivirus to restore certain critical files during remediation flows.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://vortex-win.data.microsoft.com'; ExpectedStatusCode = 404; Description = 'Used by Windows to send client diagnostic data, Windows Defender Antivirus uses this for product quality monitoring purposes.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://settings-win.data.microsoft.com'; ExpectedStatusCode = 404; Description = 'Used by Windows to send client diagnostic data, Windows Defender Antivirus uses this for product quality monitoring purposes.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://definitionupdates.microsoft.com'; ExpectedStatusCode = 400; Description = 'Windows Defender Antivirus definition updates for Windows 10 1709+.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://unitedstates.cp.wd.microsoft.com'; ExpectedStatusCode = 503; Description = 'Geo-affinity URL for wdcp.microsoft.com and wdcpalt.microsoft.com as of 06/26/2018 with WDAV 4.18.1806.18062+'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose }) # appears to be a possible replacement for wdcp.microsoft.com and wdcpalt.microsoft.com as of 06/26/2018 with WDAV 4.18.1806.18062. Seems related to HKLM\SOFTWARE\Microsoft\Windows Defender\Features\    GeoPreferenceId = 'US'

    $data.Add(@{ TestUrl = 'https://adldefinitionupdates-wu.azurewebsites.net'; ExpectedStatusCode = 200; Description = 'Alternative to https://adl.windows.com which allows the compatibility update to receive the latest compatibility data from Microsoft'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'http://ctldl.windowsupdate.com'; Description='Microsoft Certificate Trust List download URL'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })


    $data | ForEach-Object {
        $connectivity = Get-HttpConnectivity @_
        $results.Add($connectivity)
        if ($connectivity.Blocked -eq $true) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-Defender" -Type "Error" -Issue "Connection blocked `n $($connectivity)" -PossibleCause "Firewall is blocking connection to '$($connectivity.UnblockUrl)'. Autopilot requires this url without Proxy Authentication."
        } elseif ($connectivity.ExpectedStatusCode -notcontains $connectivity.ActualStatusCode) {
            if($connectivity.ActualStatusCode -eq 407){
                $Cause = "Keep in mind that the proxy has to be set in WinHTTP.`nWindows 1709 and newer: Set the proxy by using netsh or WPAD. --> https://docs.microsoft.com/en-us/windows/desktop/WinHttp/winhttp-autoproxy-support `nWindows 1709 and older: Set the proxy by using 'netsh winhttp set proxy ?' --> https://blogs.technet.microsoft.com/netgeeks/2018/06/19/winhttp-proxy-settings-deployed-by-gpo/ "
             } else {
                $Cause = "Interfering Proxy server can change HTTP status codes."
             }
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-Defender" -Type "Error" -Issue "Returned HTTP Status code '$($connectivity.ActualStatusCode)' is not expected '$($connectivity.ExpectedStatusCode)'`n $($connectivity)" -PossibleCause $Cause
        }
        if ($connectivity.Resolved -eq $false) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-Defender" -Type "Error" -Issue "DNS name not resolved `n $($connectivity)" -PossibleCause "DNS server not correctly configured."
        }
        
        if ($null -ne $connectivity.ServerCertificate -and $connectivity.ServerCertificate.HasError) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-Defender" -Type "Error" -Issue "Certificate Error when connecting to $($connectivity.TestUrl)`n $(($connectivity.ServerCertificate))" -PossibleCause "Interfering Proxy server can change Certificate or not the Root Certificate is not trusted."
        }
    }


    #endregion Windows Defender
    #region Windows SmartScreen
    Write-Verbose "Connectivity Tests to Windows Defender Smart Screen Service"
    $data = New-Object System.Collections.Generic.List[System.Collections.Hashtable]

    # https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-defender-smartscreen/windows-defender-smartscreen-overview

	# https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/ee126149(v=ws.10)



    $data.Add(@{ TestUrl = 'https://apprep.smartscreen.microsoft.com'; UrlPattern='https://*.smartscreen.microsoft.com'; ExpectedStatusCode = 404; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose})
    $data.Add(@{ TestUrl = 'https://ars.smartscreen.microsoft.com'; UrlPattern='https://*.smartscreen.microsoft.com'; ExpectedStatusCode = 404; Description = 'SmartScreen URL used by Windows Defender SmartScreen (smartscreen.exe)'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })
    $data.Add(@{ TestUrl = 'https://c.urs.microsoft.com'; UrlPattern='https://*.urs.microsoft.com'; ExpectedStatusCode = 404; Description = 'SmartScreen URL used by Internet Explorer (iexplore.exe), Edge (MicrosoftEdge.exe)'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://feedback.smartscreen.microsoft.com'; UrlPattern='https://*.smartscreen.microsoft.com'; ExpectedStatusCode = 403; Description = 'SmartScreen URL used by users to report feedback on SmartScreen accuracy for a URL'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://nav.smartscreen.microsoft.com'; UrlPattern='https://*.smartscreen.microsoft.com'; ExpectedStatusCode = 404; Description = 'SmartScreen URL used by Windows Defender SmartScreen (smartscreen.exe)'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://nf.smartscreen.microsoft.com'; UrlPattern='https://*.smartscreen.microsoft.com'; ExpectedStatusCode = 404; Description = 'SmartScreen URL used by Windows Defender Antivirus Network Inspection Service (NisSrv.exe)'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://ping.nav.smartscreen.microsoft.com'; UrlPattern='https://*.smartscreen.microsoft.com'; ExpectedStatusCode = 404; Description = 'SmartScreen URL used by Windows Defender SmartScreen (smartscreen.exe)'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://ping.nf.smartscreen.microsoft.com'; UrlPattern='https://*.smartscreen.microsoft.com'; ExpectedStatusCode = 404; Description = 'SmartScreen URL used by Windows Defender Antivirus Network Inspection Service (NisSrv.exe), Windows Defender SmartScreen (smartscreen.exe)'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://t.nav.smartscreen.microsoft.com'; UrlPattern='https://*.smartscreen.microsoft.com'; ExpectedStatusCode = 404; Description = 'SmartScreen URL used by Windows Defender SmartScreen (smartscreen.exe)'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://t.nf.smartscreen.microsoft.com'; UrlPattern='https://*.smartscreen.microsoft.com'; ExpectedStatusCode = 404; Description = 'SmartScreen URL used by Windows Defender Antivirus Network Inspection Service (NisSrv.exe)'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://unitedstates.smartscreen.microsoft.com'; UrlPattern='https://unitedstates.smartscreen.microsoft.com'; ExpectedStatusCode = 404; Description = 'SmartScreen URL used by Windows Defender Antivirus Network Inspection Service (NisSrv.exe) and Windows Defender SmartScreen (smartscreen.exe)'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://unitedstates.smartscreen-prod.microsoft.com'; UrlPattern='https://unitedstates.smartscreen-prod.microsoft.com'; ExpectedStatusCode = 404; Description = 'SmartScreen URL used by Windows Defender Antivirus Network Inspection Service (NisSrv.exe) and Windows Defender SmartScreen (smartscreen.exe)'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://t.urs.microsoft.com'; UrlPattern='https://*.urs.microsoft.com'; ExpectedStatusCode = 404; Description = 'SmartScreen URL used by Internet Explorer (iexplore.exe), Edge (MicrosoftEdge.exe)'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://urs.microsoft.com' ; UrlPattern='https://urs.microsoft.com'; ExpectedStatusCode = 404; Description = 'SmartScreen URL used by Internet Explorer (iexplore.exe)'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://urs.smartscreen.microsoft.com'; UrlPattern='https://*.smartscreen.microsoft.com'; ExpectedStatusCode = 404; Description = 'SmartScreen URL used by Windows Defender Antivirus Network Inspection Service (NisSrv.exe), Windows Defender SmartScreen (smartscreen.exe), Windows Defender Exploit Guard Network Protection (wdnsfltr.exe)'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })



    $data | ForEach-Object {
        $connectivity = Get-HttpConnectivity @_
        $results.Add($connectivity)
        if ($connectivity.Blocked -eq $true) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-SmartScreen" -Type "Error" -Issue "Connection blocked `n $($connectivity)" -PossibleCause "Firewall is blocking connection to '$($connectivity.UnblockUrl)'. Autopilot requires this url without Proxy Authentication."
        } elseif ($connectivity.ExpectedStatusCode -notcontains $connectivity.ActualStatusCode) {
            if($connectivity.ActualStatusCode -eq 407){
                $Cause = "Keep in mind that the proxy has to be set in WinHTTP.`nWindows 1709 and newer: Set the proxy by using netsh or WPAD. --> https://docs.microsoft.com/en-us/windows/desktop/WinHttp/winhttp-autoproxy-support `nWindows 1709 and older: Set the proxy by using 'netsh winhttp set proxy ?' --> https://blogs.technet.microsoft.com/netgeeks/2018/06/19/winhttp-proxy-settings-deployed-by-gpo/ "
             } else {
                $Cause = "Interfering Proxy server can change HTTP status codes."
             }
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-SmartScreen" -Type "Error" -Issue "Returned HTTP Status code '$($connectivity.ActualStatusCode)' is not expected '$($connectivity.ExpectedStatusCode)'`n $($connectivity)" -PossibleCause $Cause
        }
        if ($connectivity.Resolved -eq $false) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-SmartScreen" -Type "Error" -Issue "DNS name not resolved `n $($connectivity)" -PossibleCause "DNS server not correctly configured."
        }
        
        if ($null -ne $connectivity.ServerCertificate -and $connectivity.ServerCertificate.HasError) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-SmartScreen" -Type "Error" -Issue "Certificate Error when connecting to $($connectivity.TestUrl)`n $(($connectivity.ServerCertificate))" -PossibleCause "Interfering Proxy server can change Certificate or not the Root Certificate is not trusted."
        }
    }


    #endregion Windows SmartScreen
    #region Windows Update
    Write-Verbose "Connectivity Tests to Windows Update Service"
    $data = New-Object System.Collections.Generic.List[System.Collections.Hashtable]

    $data.Add(@{ TestUrl = 'http://windowsupdate.microsoft.com'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://windowsupdate.microsoft.com'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://windowsupdate.microsoft.com'; UrlPattern = 'http://*.windowsupdate.microsoft.com'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://geo-prod.do.dsp.mp.microsoft.com'; UrlPattern = 'https://*.do.dsp.mp.microsoft.com'; ExpectedStatusCode = 403; Description = 'Updates for applications and the OS on Windows 10 1709 and later. Windows Update Delivery Optimization metadata, resiliency, and anti-corruption.'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose }) # many different *-prod.do.dsp.mp.microsoft.com, but geo-prod.do.dsp.mp.microsoft.com is the most common one

    $data.Add(@{ TestUrl = 'http://download.windowsupdate.com'; Description = 'Download operating system patches and updates'; IgnoreCertificateValidationErrors=$true; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'http://au.download.windowsupdate.com'; UrlPattern = 'http://*.au.download.windowsupdate.com'; IgnoreCertificateValidationErrors=$true; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose }) # many different *.download.windowsupdate.com, au.download.windowsupdate.com is most common. *.au.download.windowsupdate.com, *.l.windowsupdate.com

    $data.Add(@{ TestUrl = 'https://cds.d2s7q6s2.hwcdn.net'; UrlPattern = 'https://cds.*.hwcdn.net'; ExpectedStatusCode = 504; Description = 'Highwinds Content Delivery Network used for Windows Update on Windows 10 1709 and later'; IgnoreCertificateValidationErrors=$true; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'http://cs9.wac.phicdn.net'; UrlPattern = 'http://*.wac.phicdn.net'; Description = 'Verizon Content Delivery Network used for Windows Update on Windows 10 1709 and later'; IgnoreCertificateValidationErrors=$true; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://cs491.wac.edgecastcdn.net'; UrlPattern = 'https://*.wac.edgecastcdn.net'; ExpectedStatusCode = 404; Description = 'Verizon Content Delivery Network used for Windows Update on Windows 10 1709 and later'; IgnoreCertificateValidationErrors=$true; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'http://dl.delivery.mp.microsoft.com'; UrlPattern = 'http://*.dl.delivery.mp.microsoft.com'; ExpectedStatusCode = 403; IgnoreCertificateValidationErrors=$true; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'http://tlu.dl.delivery.mp.microsoft.com'; UrlPattern = 'http://*.tlu.dl.delivery.mp.microsoft.com'; ExpectedStatusCode = 403; IgnoreCertificateValidationErrors=$true; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://emdl.ws.microsoft.com'; ExpectedStatusCode = 504; Description = 'Update applications from the Microsoft Store'; IgnoreCertificateValidationErrors=$true; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://fe2.update.microsoft.com'; UrlPattern = 'https://*.update.microsoft.com'; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://sls.update.microsoft.com'; UrlPattern = 'https://*.update.microsoft.com'; ExpectedStatusCode = 403; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://fe3.delivery.mp.microsoft.com'; UrlPattern = 'https://*.delivery.mp.microsoft.com'; ExpectedStatusCode = 403; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })

    $data.Add(@{ TestUrl = 'https://tsfe.trafficshaping.dsp.mp.microsoft.com'; UrlPattern = 'https://*.dsp.mp.microsoft.com'; ExpectedStatusCode = 403; PerformBluecoatLookup=$PerformBluecoatLookup; Verbose=$isVerbose })




    $data | ForEach-Object {
        $connectivity = Get-HttpConnectivity @_
        $results.Add($connectivity)
        if ($connectivity.Blocked -eq $true) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-WindowsUpdate" -Type "Error" -Issue "Connection blocked `n $($connectivity)" -PossibleCause "Firewall is blocking connection to '$($connectivity.UnblockUrl)'. Autopilot requires this url without Proxy Authentication."
        } elseif ($connectivity.ExpectedStatusCode -notcontains $connectivity.ActualStatusCode) {
            if($connectivity.ActualStatusCode -eq 407){
                $Cause = "Keep in mind that the proxy has to be set in WinHTTP.`nWindows 1709 and newer: Set the proxy by using netsh or WPAD. --> https://docs.microsoft.com/en-us/windows/desktop/WinHttp/winhttp-autoproxy-support `nWindows 1709 and older: Set the proxy by using 'netsh winhttp set proxy ?' --> https://blogs.technet.microsoft.com/netgeeks/2018/06/19/winhttp-proxy-settings-deployed-by-gpo/ "
             } else {
                $Cause = "Interfering Proxy server can change HTTP status codes."
             }
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-WindowsUpdate" -Type "Error" -Issue "Returned HTTP Status code '$($connectivity.ActualStatusCode)' is not expected '$($connectivity.ExpectedStatusCode)'`n $($connectivity)" -PossibleCause $Cause
        }
        if ($connectivity.Resolved -eq $false) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-WindowsUpdate" -Type "Error" -Issue "DNS name not resolved `n $($connectivity)" -PossibleCause "DNS server not correctly configured."
        }
        
        if ($null -ne $connectivity.ServerCertificate -and $connectivity.ServerCertificate.HasError) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity-WindowsUpdate" -Type "Error" -Issue "Certificate Error when connecting to $($connectivity.TestUrl)`n $(($connectivity.ServerCertificate))" -PossibleCause "Interfering Proxy server can change Certificate or not the Root Certificate is not trusted."
        }
    }


    #endregion Windows Update
    # No errors detected, return success message
    if ($possibleErrors.Count -eq 0) {
        $possibleErrors += New-AnalyzeResult -TestName "All" -Type Information -Issue "All tests went through successfully. $(if(-not $IncludeEventLog){'You can try to run the command again with the -IncludeEventLog parameter.'})" -PossibleCause ""
    }

    return $possibleErrors
}