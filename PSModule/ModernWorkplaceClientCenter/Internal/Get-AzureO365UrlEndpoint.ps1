function Get-AzureO365UrlEndpoint{
    <#
    .Synopsis
    Returns list of Azure/O365 endpoints from the official Microsoft webservice.

    .Description
    Try loading the actual list of Azure/O365 endpoints from the official Microsoft webservice. If not possible it will used a cached version. If an online version can be retriefed and the script is executed with administrative permission it also updates the local cache.

    .Example
    Get-AzureO365UrlEndpoint

    #>
    [OutputType([PSCustomObject[]])]
    [CmdletBinding()]
    param(
        [String]
        $Path
    )
    $Endpoints = Invoke-WebRequest -Uri "https://endpoints.office.com/endpoints/worldwide?clientrequestid=$(New-Guid)"
    if($Endpoints.StatusCode -ne 200){
        Write-Error "Error downloading the actual endpoint list ($($Endpoints.StatusDescription) - $($Endpoints.StatusCode)) `n https://endpoints.office.com" -ErrorAction Continue
        Write-Warning "Try using cached endpoint list"

        try{
            $AzureEndpointCache = Get-Content -Path "$Path\Data\AzureEndpointCache.json" -ErrorAction Stop
            $EndpointsObjs = $AzureEndpointCache | ConvertFrom-Json 
        } catch {
            throw "Could not find '$Path\Data\AzureEndpointCache.json, failed to load azure endpoints for connectivity tests."
        }
    } else {
        $EndpointsObjs = $Endpoints.Content | ConvertFrom-Json 
        Write-Verbose "Successfully retrieved $($EndpointsObjs.Length) Endpoints from online source."
        if(Get-IsAdmin){
            Write-Verbose "Function is executed as Administrator, therefore trying to update local cache file."
            Out-File -FilePath "$Path\Data\AzureEndpointCache.json" -InputObject $Endpoints.content -Force
        }
    }
    return $EndpointsObjs
}