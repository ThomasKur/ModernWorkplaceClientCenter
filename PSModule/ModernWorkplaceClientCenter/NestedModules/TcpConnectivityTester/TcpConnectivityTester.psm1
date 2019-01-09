Set-StrictMode -Version 4

Function Get-ErrorMessage() {
<#
    .SYNOPSIS
    Gets a formatted error message from an error record.

    .DESCRIPTION
    Gets a formatted error message from an error record.

    .EXAMPLE
    Get-ErrorMessage -ErrorRecords $_
    #>
    [CmdletBinding()]
    [OutputType([string])]
    Param(
        [Parameter(Mandatory=$true, HelpMessage='The PowerShell error record object to get information from')]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    Process {
        $msg = [System.Environment]::NewLine,'Exception Message: ',$ErrorRecord.Exception.Message -join ''

        if($null -ne $ErrorRecord.Exception.HResult) {
            $msg = $msg,[System.Environment]::NewLine,'Exception HRESULT: ',('{0:X}' -f $ErrorRecord.Exception.HResult),$ErrorRecord.Exception.HResult -join ''
        }

        if($null -ne $ErrorRecord.Exception.StackTrace) {
            $msg = $msg,[System.Environment]::NewLine,'Exception Stacktrace: ',$ErrorRecord.Exception.StackTrace -join ''
        }

        if ($null -ne ($ErrorRecord.Exception | Get-Member | Where-Object { $_.Name -eq 'WasThrownFromThrowStatement'})) {
            $msg = $msg,[System.Environment]::NewLine,'Explicitly Thrown: ',$ErrorRecord.Exception.WasThrownFromThrowStatement -join ''
        }

        if ($null -ne $ErrorRecord.Exception.InnerException) {
            if ($ErrorRecord.Exception.InnerException.Message -ne $ErrorRecord.Exception.Message) {
                $msg = $msg,[System.Environment]::NewLine,'Inner Exception: ',$ErrorRecord.Exception.InnerException.Message -join ''
            }

            if($null -ne $ErrorRecord.Exception.InnerException.HResult) {
                $msg = $msg,[System.Environment]::NewLine,'Inner Exception HRESULT: ',('{0:X}' -f $ErrorRecord.Exception.InnerException.HResult),$ErrorRecord.Exception.InnerException.HResult -join ''
            }
        }

        $msg = $msg,[System.Environment]::NewLine,'Call Site: ',$ErrorRecord.InvocationInfo.PositionMessage -join ''

        if ($null -ne ($ErrorRecord | Get-Member | Where-Object { $_.Name -eq 'ScriptStackTrace'})) {
            $msg = $msg,[System.Environment]::NewLine,"Script Stacktrace: ",$ErrorRecord.ScriptStackTrace -join ''
        }

        return $msg
    }
}



Function Get-IPAddress() {
    <#
    .SYNOPSIS
    Gets the IP address(es) for a hostname.

    .DESCRIPTION
    Gets the IP address(es) for a hostname.

    .EXAMPLE
    Get-IPAddress -Hostname www.site.com
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    Param (
        [Parameter(Mandatory=$true, HelpMessage='The Hostname to get the IP address for.')]
        [ValidateNotNullOrEmpty()]
        [Alias("Url")]
        [String]$Hostname
    )

    $addresses = [string[]]@()

    $dnsResults = $null

    $dnsResults = @(Resolve-DnsName -Name $Hostname -NoHostsFile -Type A_AAAA -QuickTimeout -ErrorAction SilentlyContinue | Where-Object {$_.Type -eq 'A'})

    $addresses = [string[]]@($dnsResults | ForEach-Object { try { $_.IpAddress } catch [System.Management.Automation.PropertyNotFoundException] {Write-Verbose "No IP in Object."} }) # IpAddress results in a PropertyNotFoundException when a URL is blocked upstream

    return [string[]](,$addresses)
}

Function Get-IPAlias() {
    <#
    .SYNOPSIS
    Gets DNS alias for a Hostname.

    .DESCRIPTION
    Gets DNS alias for a Hostname.

    .EXAMPLE
    Get-IPAlias -Hostname http://www.site.com
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    Param (
        [Parameter(Mandatory=$true, HelpMessage='The Hostname to get the alias address for.')]
        [ValidateNotNullOrEmpty()]
        [Alias("Url")]
        [String]$Hostname
    )

    $aliases = [string[]]@()

    $dnsResults = $null

    $dnsResults = @(Resolve-DnsName -Name $Hostname -NoHostsFile -QuickTimeout -ErrorAction SilentlyContinue | Where-Object { $_.Type -eq 'CNAME' })

    $aliases = [string[]]@($dnsResults | ForEach-Object { $_.NameHost })

    return [string[]](,$aliases)
}



Function Get-TcpConnectivity() {
    <#
    .SYNOPSIS
    Gets TCP connectivity information for a hostname and port.

    .DESCRIPTION
    Gets TCP connectivity information for a hostname and port.

    .EXAMPLE
    Get-TcpConnectivity -TestHostname "www.site.com" -TestPort 111

    .EXAMPLE
    Get-TcpConnectivity -TestHostname "www.site.com" -TestPort 111 -HostnamePattern "*.site.com" -Description 'A site that does something'

    #>
    [CmdletBinding()]
    [OutputType([void])]
    Param(
        [Parameter(Mandatory=$true, HelpMessage='The hostname to test.')]
        [ValidateNotNullOrEmpty()]
        [String]$TestHostname,

        [Parameter(Mandatory=$true, HelpMessage='The TCP port to test.')]
        [ValidateNotNullOrEmpty()]
        [Int32]$TestPort,

        [Parameter(Mandatory=$true, HelpMessage='The Expected status code.')]
        [Int32]$ExpectedStatusCode,

        [Parameter(Mandatory=$false, HelpMessage='The hostname pattern to unblock when the hostname to unblock is not a literal hostname.')]
        [ValidateNotNullOrEmpty()]
        [string]$HostnamePattern,

        [Parameter(Mandatory=$false, HelpMessage='A description of the connectivity test or purpose of the hostname.')]
        [ValidateNotNullOrEmpty()]
        [string]$Description

    )

    $parameters = $PSBoundParameters

    $isVerbose = $verbosePreference -eq 'Continue'

    $TestHostname = $TestHostname.ToLower()


    if($parameters.ContainsKey('HostnamePattern')) {
        $UnblockHostname = $HostnamePattern
    } else {
        $UnblockHostname = $TestHostname
    }

    $newLine = [System.Environment]::NewLine

    Write-Verbose -Message ('{0}*************************************************{1}Testing {2}{3}*************************************************{4}' -f $newLine,$newLine,$TestHostname,$newLine,$newLine)

    
    $statusCode = 0
    $statusMessage = ''
    $response = $null

    try {
        $response = Test-NetConnection -ComputerName $TestHostname -Port $TestPort -Verbose:$isVerbose
        if($response.TcpTestSucceeded){
            $statusCode = 1
            $statusMessage = "Tcp test succeeded"
        } elseif($response.PingSucceeded){ 
            $statusCode = 2
            $statusMessage = "Ping test succeeded"
        } elseif($response.NameResolutionSucceeded){ 
            $statusCode = 3
            $statusMessage = "Name resolution succeeded"
        }else {
            $statusCode = 5
            $statusMessage = "Unknown error"
        }
        
        
    } catch {
        $statusMessage = Get-ErrorMessage -ErrorRecord $_
    } 

    $address = Get-IPAddress -Hostname $TestHostname -Verbose:$false
    $alias = Get-IPAlias -Hostname $TestHostname -Verbose:$false
    $resolved = (@($address)).Length -ge 1 -or (@($alias)).Length -ge 1
    $actualStatusCode = [int]$statusCode
    $isBlocked = $statusCode -eq 1 -and $resolved
    $urlType = if ($HostnamePattern.Contains('*')) { 'Pattern' } else { 'Literal' }

    $isUnexpectedStatus = $statusCode -ne 1
    $simpleStatusMessage = if ($isUnexpectedStatus) { $statusMessage } else { '' }

    $connectivitySummary = ('{0}Test Hostname: {1}{2}Hostname to Unblock: {3}{4}Hostname Type: {5}{6}Description: {7}{8}Resolved: {9}{10}IP Addresses: {11}{12}DNS Aliases: {13}{14}Actual Status Code: {15}{16}Expected Status Code: {17}{18}Is Unexpected Status Code: {19}{20}Status Message: {21}{22}Blocked: {23}{24}{25}' -f $newLine,$TestHostname,$newLine,$HostnamePattern,$newLine,$urlType,$newLine,$Description,$newLine,$resolved,$newLine,($address -join ', '),$newLine,($alias -join ', '),$newLine,$actualStatusCode,$newLine,$ExpectedStatusCode,$newLine,$isUnexpectedStatus,$newLine,$simpleStatusMessage,$newLine,$isBlocked,$newLine,$newLine)
    Write-Verbose -Message $connectivitySummary

    $connectivity = [pscustomobject]@{
        TestUrl = $TestHostname;
        UnblockUrl = $UnblockHostname;
        UrlType = $urlType;
        Resolved = $resolved;
        IpAddresses = [string[]]$address;
        DnsAliases = [string[]]$alias;
        Description = $Description;
        ActualStatusCode = [int]$actualStatusCode;
        ExpectedStatusCode = $ExpectedStatusCode;
        UnexpectedStatus = $isUnexpectedStatus;
        StatusMessage = $simpleStatusMessage;
        DetailedStatusMessage = $statusMessage;
        Blocked = $isBlocked;
        ServerCertificate = $null;
    }

    return $connectivity
}

Function Save-TcpConnectivity() {
    <#
    .SYNOPSIS
    Saves TCP connectivity objects to a JSON file.

    .DESCRIPTION
    Saves TCP connectivity objects to a JSON file.

    .EXAMPLE
    Save-TcpConnectivity -FileName 'Connectivity' -Objects $connectivity

    .EXAMPLE
    Save-TcpConnectivity -FileName 'Connectivity' -Objects $connectivity -OutputPath "$env:userprofile\Documents\ConnectivityTestResults"

    .EXAMPLE
    Save-TcpConnectivity -FileName 'Connectivity' -Objects $connectivity -Compress
    #>
    [CmdletBinding()]
    [OutputType([void])]
    Param(
        [Parameter(Mandatory=$true, HelpMessage='The filename without the extension.')]
        [ValidateNotNullOrEmpty()]
        [string]$FileName,

        [Parameter(Mandatory=$true, HelpMessage='The connectivity object(s) to save.')]
        [System.Collections.Generic.List[pscustomobject]]$Objects,

        [Parameter(Mandatory=$false, HelpMessage="The path to save the file to. Defaults to the user's Desktop folder.")]
        [string]$OutputPath,

        [Parameter(Mandatory=$false, HelpMessage='Compress the JSON text output.')]
        [switch]$Compress
    )

    $parameters = $PSBoundParameters

    if (-not($parameters.ContainsKey('OutputPath'))) {
        $OutputPath = $env:USERPROFILE,'Desktop' -join [System.IO.Path]::DirectorySeparatorChar
    }

    $OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)

    if (-not(Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory
    }

    $json = $Objects | ConvertTo-Json -Depth 3 -Compress:$Compress
    $json | Out-File -FilePath "$OutputPath\$FileName.json" -NoNewline -Force
}
