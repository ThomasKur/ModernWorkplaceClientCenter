function Invoke-AnalyzeAzureConnectivity {
    <#
    .Synopsis
    Analyzes the connectifity to O365 and Azure Endpoints.

    .Description
    Analyzes the connectifity to O365 and Azure Endpoints according to https://docs.microsoft.com/en-us/office365/enterprise/urls-and-ip-address-ranges.

    Returns array of Messages with four properties:

    - Testname: Name of the Tets
    - Type: Information, Warning or Error
    - Issue: Description of the issue
    - Possible Cause: Tips on how to solve the issue.

    .Example
    # Displays a deep analyisis of the currently found issues in the system.
    Invoke-AnalyzeAzureConnectivity

    #>
    [alias("Invoke-AnalyzeO365Connectivity")]
    [CmdletBinding()]
    param(
        [ValidateSet("Common","Exchange","Skype","SharePoint","All")] 
        [String]
        $UrlSet = "Common",
        [Switch]
        $OnlyRequired
        )
    
    Write-Verbose "Conenctivity Tests to Azure Endpoints in $UrlSet category, which are Required=$OnlyRequired."
    $data = New-Object System.Collections.Generic.List[PSCustomObject]
    $possibleErrors = @()
    $results = New-Object System.Collections.Generic.List[pscustomobject]
    Write-Progress -Activity "Connectivity Tests" -status "Load TestUrls" -percentComplete 0
        
    $EndpointsObjs = Get-AzureO365UrlEndpoint -Path ((Get-Item $PSScriptRoot).Parent.FullName)
    $EndpointsObjs = $EndpointsObjs | Where-Object { ($_.serviceArea -eq $UrlSet -or $UrlSet -eq "All") -and ($OnlyRequired -eq $false -or $_.required -eq $true)}
    Write-Progress -Activity "Connectivity Tests" -status "Load TestUrls finisehed" -percentComplete 100
    Write-Verbose "Found $($EndpointsObjs.length) endpoints to check"
    $j = 0
    foreach($EndpointsObj in $EndpointsObjs){
        Write-Progress -Activity "Connectivity Tests" -status "Building urls for $($EndpointsObj.serviceArea) with id $($EndpointsObj.id)" -percentComplete ($j / $EndpointsObjs.length*100)
        if($null -ne $EndpointsObj.tcpPorts){
            Add-Member -InputObject $EndpointsObj -MemberType NoteProperty -Name tcpPorts -Value "443"
        }
        foreach($Port in $EndpointsObj.tcpPorts.Split(',')){
            switch ($Port) {
                80 {$Protocol = "http://"; $UsePort = "";$TestType="HTTP"; break}
                443 {$Protocol = "https://"; $UsePort = "";$TestType="HTTP"; break}
                default {$Protocol = ""; $UsePort = $Port;$TestType="TCP"; break}
                }
            if($EndpointsObj.PSObject.Properties.Name -match "notes"){
                $Notes = " - " + $EndpointsObj.notes
            } else {
                $Notes = ""
            }
            foreach($url in $EndpointsObj.urls){
                if($TestType -eq "HTTP"){
                    $ExpectedResult = Get-AzureEndpointExpectedResult -TestType $TestType -Url ($Protocol + $url) -Path ((Get-Item $PSScriptRoot).Parent.FullName)
                } else {
                    $ExpectedResult = Get-AzureEndpointExpectedResult -TestType $TestType -Url ($url + ":" + $UsePort) -Path ((Get-Item $PSScriptRoot).Parent.FullName)
                }
                if($url -notmatch "\*"){
                    $data.Add([PSCustomObject]@{ TestType = $TestType; TestUrl = $url; UsePort = $UsePort; Protocol = $Protocol; UrlPattern = $url; ExpectedStatusCode = $ExpectedResult.ActualStatusCode; Description = "$($EndpointsObj.serviceAreaDisplayName)$Notes"; PerformBluecoatLookup=$false; IgnoreCertificateValidationErrors=$ExpectedResult.HasError; Blocked=$ExpectedResult.Blocked; Verbose=$false }) 
                } else {
                    $staticUrls = Get-UrlWildCardLookup -Url $url -Path ((Get-Item $PSScriptRoot).Parent.FullName)
                    if($staticUrls){
                        foreach($staticUrl in $staticUrls){
                            $data.Add([PSCustomObject]@{ TestType = $TestType; TestUrl = $staticUrl; UsePort = $UsePort; Protocol = $Protocol; UrlPattern = $url; ExpectedStatusCode = $ExpectedResult.ActualStatusCode; Description = "$($EndpointsObj.serviceAreaDisplayName)$Notes"; PerformBluecoatLookup=$false; IgnoreCertificateValidationErrors=$ExpectedResult.HasError; Blocked=$ExpectedResult.Blocked; Verbose=$false }) 
                        }
                    } else {

                        $possibleErrors += New-AnalyzeResult -TestName "Connectivity" -Type "Warning" -Issue "Could not check connectivity to $url and Port $Port because no static url for this wildcard url was found." -PossibleCause $Cause
                    }
                }
            }
            <#if($EndpointsObj.PSObject.Properties.Name -match "ips"){
                foreach($ip in $EndpointsObj.ips){
                    $firstip = $ip.Split("/")[0]
                    $data.Add(@{ TestUrl = ($Protocol + $firstip + $UsePort); UrlPattern = ($Protocol + $firstip + $UsePort); ExpectedStatusCode = 403; Description = "$($EndpointsObj.serviceAreaDisplayName) - $Notes - Need communication $Protocol to $ip"; PerformBluecoatLookup=$false; Verbose=$false }) 
                }
            }#>
        }
    }
    
    $possibleErrors = $possibleErrors | Group-Object -Property @("Type", "Issue") | ForEach-Object{ $_.Group | Select-Object * -First 1} 
    $i = 1
    $dataObjs = $data | Group-Object -Property @("TestUrl","TestType","UsePort") | ForEach-Object{ $_.Group | Select-Object * -First 1} 
    ForEach($dataObj in $dataObjs) {
        Write-Progress -Activity "Connectivity Tests" -status "Processing $($d.TestUrl)" -percentComplete ($i / $dataObjs.count*100)
        if($dataObj.TestType -eq "HTTP"){
            $connectivity = Get-HttpConnectivity -TestUrl ($dataObj.Protocol + $dataObj.TestUrl) -Method "GET" -UrlPattern ($dataObj.Protocol + $dataObj.UrlPattern) -ExpectedStatusCode $dataObj.ExpectedStatusCode -Description $dataObj.Description -PerformBluecoatLookup $dataObj.PerformBluecoatLookup -IgnoreCertificateValidationErrors:$dataObj.IgnoreCertificateValidationErrors
        } else {
            $connectivity = Get-TcpConnectivity -TestHostname $dataObj.TestUrl -TestPort $dataObj.UsePort -HostnamePattern ($dataObj.UrlPattern + ":" + $dataObj.UsePort) -ExpectedStatusCode $dataObj.ExpectedStatusCode -Description $dataObj.Description
        }
        $results.Add($connectivity)
        if ($connectivity.Blocked -eq $true -and $dataObj.Blocked -eq $false) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity" -Type "Error" -Issue "Connection blocked `n $($connectivity)" -PossibleCause "Firewall is blocking connection to '$($connectivity.UnblockUrl)'."
        }
        if ($connectivity.Resolved -eq $false) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity" -Type "Error" -Issue "DNS name not resolved `n $($connectivity)" -PossibleCause "DNS server not correctly configured."
        }
        if ($connectivity.ActualStatusCode -ne $connectivity.ExpectedStatusCode) {
            if($connectivity.ActualStatusCode -eq 407){
                $Cause = "Keep in mind that the proxy has to be set in WinHTTP.`nWindows 1709 and newer: Set the proxy by using netsh or WPAD. --> https://docs.microsoft.com/en-us/windows/desktop/WinHttp/winhttp-autoproxy-support `nWindows 1709 and older: Set the proxy by using 'netsh winhttp set proxy ?' --> https://blogs.technet.microsoft.com/netgeeks/2018/06/19/winhttp-proxy-settings-deployed-by-gpo/ "
             } else {
                $Cause = "Interfering Proxy server can change HTTP status codes."
             }
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity" -Type "Error" -Issue "Returned Status code '$($connectivity.ActualStatusCode)' is not expected '$($connectivity.ExpectedStatusCode)'`n $($connectivity)" -PossibleCause $Cause
        }
        if ($null -ne $connectivity.ServerCertificate -and $connectivity.ServerCertificate.HasError -and -not $dataObj.IgnoreCertificateValidationErrors) {
            $possibleErrors += New-AnalyzeResult -TestName "Connectivity" -Type "Error" -Issue "Certificate Error when connecting to $($connectivity.TestUrl)`n $(($connectivity.ServerCertificate))" -PossibleCause "Interfering Proxy server can change Certificate or not the Root Certificate is not trusted."
        }
        $i += 1
    }
    Write-Progress -Completed -Activity "Connectivity Tests"
    
    # No errors detected, return success message
    if ($possibleErrors.Count -eq 0) {
        $possibleErrors += New-AnalyzeResult -TestName "All" -Type Information -Issue "All tests went through successfully." -PossibleCause ""
    }

    return $possibleErrors
}