$ModulePath = "$PSScriptRoot\ModernWorkplaceClientCenter"
. "$PSScriptRoot\ModernWorkplaceClientCenter\Internal\Get-UrlWildCardLookup.ps1"
$HttpConModulePath = "$PSScriptRoot\ModernWorkplaceClientCenter\NestedModules\HttpConnectivityTester\HttpConnectivityTester.psd1"
Import-Module $HttpConModulePath
$TcpConModulePath = "$PSScriptRoot\ModernWorkplaceClientCenter\NestedModules\TcpConnectivityTester\TcpConnectivityTester.psd1"
Import-Module $TcpConModulePath
#region Update Azure Endpoints
$Endpoints = Invoke-WebRequest -Uri "https://endpoints.office.com/endpoints/worldwide?clientrequestid=$(New-Guid)"
Out-File -FilePath "$ModulePath\Data\AzureEndpointCache.json" -InputObject $Endpoints.content -Force 
#endregion Update Azure Endpoints

#region Expected Results
$data = New-Object System.Collections.Generic.List[PSCustomObject]
$EndpointsObjs = $Endpoints.content | ConvertFrom-Json
Write-Verbose "Found $($EndpointsObjs.length) endpoints to check"
foreach($EndpointsObj in $EndpointsObjs){
    if($null -eq $EndpointsObj.tcpPorts){
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
            if($url -notmatch "\*"){
                $data.Add([PSCustomObject]@{ TestType = $TestType; TestUrl = $url; UsePort = $UsePort; Protocol = $Protocol; UrlPattern = $url; Description = "$($EndpointsObj.serviceAreaDisplayName)$Notes"; PerformBluecoatLookup=$false; Verbose=$false }) 
            } else {
                $staticUrls = Get-UrlWildCardLookup -Url $url -Path $ModulePath
                foreach($staticUrl in $staticUrls){
                    $data.Add([PSCustomObject]@{ TestType = $TestType; TestUrl = $staticUrl; UsePort = $UsePort; Protocol = $Protocol; UrlPattern = $url; Description = "$($EndpointsObj.serviceAreaDisplayName)$Notes"; PerformBluecoatLookup=$false; Verbose=$false }) 
                }
            }
        }
    }
}

$results = New-Object System.Collections.Generic.List[pscustomobject]

$i = 0
<#
ForEach($d in $data) {
    Write-Progress -Activity "Connectivity Tests" -status "Processing $($d.TestUrl)" -percentComplete ($i / $data.count*100)
    $connectivity = Get-HttpConnectivity -TestUrl $d.TestUrl -Method "GET" -UrlPattern $d.UrlPattern -ExpectedStatusCode $d.ExpectedStatusCode -Description $d.Description -PerformBluecoatLookup $d.PerformBluecoatLookup -IgnoreCertificateValidationErrors
    $results.Add($connectivity)
    $i += 1
}#>

foreach ($d in $data) {
    $running = @(Get-Job | Where-Object { $_.State -eq 'Running' })
    if ($running.Count -ge 10) {
        $running | Wait-Job -Any | Out-Null
    }

    Write-Progress -Activity "Connectivity Tests" -status "Processing $($d.TestUrl)" -percentComplete ($i / $data.count*100)
    
    $i += 1
    Start-Job -ArgumentList @($d,$HttpConModulePath,$TcpConModulePath) -ScriptBlock {
    param($d,$HttpConModulePath,$TcpConModulePath)
        
        
        if($d.TestType -eq "HTTP"){
            Import-Module $HttpConModulePath
            $connectivity = Get-HttpConnectivity -TestUrl ($d.Protocol + $d.TestUrl) -Method "GET" -UrlPattern ($d.Protocol + $d.UrlPattern) -ExpectedStatusCode 200 -Description $d.Description -IgnoreCertificateValidationErrors
        } else {
            Import-Module $TcpConModulePath
            $connectivity = Get-TcpConnectivity -TestHostname $d.TestUrl -TestPort $d.UsePort -HostnamePattern ($d.UrlPattern + ":" + $d.UsePort) -ExpectedStatusCode 1 -Description $d.Description
        }
        $connectivity
    } | Out-Null
}

# Wait for all jobs to complete and results ready to be received
Wait-Job * | Out-Null

# Process the results
foreach($job in Get-Job)
{
    $result = Receive-Job $job -AutoRemoveJob -Wait
    $results.Add($result)
}

$CachedResults = $results | Foreach-Object { [pscustomobject]@{
        UnblockUrl = $_.UnblockUrl;
        ActualStatusCode = $_.ActualStatusCode;
        Blocked = $_.Blocked;
        HasError = $_.ServerCertificate.HasError;
    }} | Select-Object UnblockUrl,ActualStatusCode,HasError,Blocked
Out-File -FilePath "$ModulePath\Data\AzureEndpointExpectedResults.json" -InputObject ($CachedResults | ConvertTo-Json) -Force  
#endregion Expected Results