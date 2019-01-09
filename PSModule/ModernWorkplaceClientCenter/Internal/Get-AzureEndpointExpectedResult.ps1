function Get-AzureEndpointExpectedResult{
    <#
    .Synopsis
    Returns the expected result and SSL error for a specific endpoint.

    .Description
    Returns the expected result and SSL error for a specific endpoint.

    .Example
    Get-AzureEndpointExpectedResult -Url "http://*.contoso.com" -Path "PathToModule"

    #>
    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    param(
        [String]$Url,
        [String]$Path,
        [String]$TestType
    )
    $returnValue = $null
    Write-Verbose "Try to get expected connectivity result for '$Url' from file '$Path\Data\AzureEndpointExpectedResults.json'."
    try{
        $ExpectedResult = Get-Content -Path "$Path\Data\AzureEndpointExpectedResults.json" -ErrorAction Stop
        $ExpectedResultObjs = $ExpectedResult | ConvertFrom-Json
        foreach($ExpectedResultObj in $ExpectedResultObjs){
            if($ExpectedResultObj.UnblockUrl -eq $Url){
                $returnValue = $ExpectedResultObj 
                break
            }
        }
    } catch {
        Write-Warning "Could not find '$Path\Data\AzureEndpointExpectedResults.json', failed to get expected connectifity results."
    }

    if($null -eq $returnValue){
        if($TestType -eq "HTTP"){
            Write-Warning "Using default Expected Result Http Status 200 without SSL validation for url $($url)."
            $returnValue = [PSCustomObject]@{ UnblockUrl = $Url;ActualStatusCode = 200; HasError = $true }
        } else {
            Write-Warning "Using default Expected Result Tcp Status 1 $($url)."
            $returnValue = [PSCustomObject]@{ UnblockUrl = $Url;ActualStatusCode = 1; HasError = $true }
        }
    }
    return $returnValue
}