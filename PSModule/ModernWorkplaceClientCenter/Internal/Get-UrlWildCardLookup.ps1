function Get-UrlWildCardLookup{
    <#
    .Synopsis
    tryes to find a static URL for a Wildcard URL from the .

    .Description
    Returns $true if the script is executed with administrator priviledge, false if not.

    .Example
    Get-UrlWildCardLookup -Url "*.contoso.com"

    #>
    [OutputType([String[]])]
    [CmdletBinding()]
    param(
        [String]$Url,
        [String]$Path
    )
    

    [String[]]$StaticUrls = @()
    Write-Verbose "Try to resolve '$Url' Wildcard Url to an static url from file '$Path\Data\UrlWildcardLookup.json'."
    try{
        $AddToCache = $true
        $WildCardJSON = Get-Content -Path "$Path\Data\UrlWildcardLookup.json" -ErrorAction Stop
        $WildCardJSONObjs = $WildCardJSON | ConvertFrom-Json
        foreach($WildCardJSONObj in $WildCardJSONObjs){
            if($WildCardJSONObj.Wildcard -eq $Url){
                if($null -ne $WildCardJSONObj.static){
                    foreach($UrlPart in $WildCardJSONObj.static.Split(",")){
                        if(-not [String]::IsNullOrWhiteSpace($UrlPart)){
                            $StaticUrls += $Url -replace "\*",$UrlPart
                            Write-Verbose "Resolved URL $($Url -replace "\*",$UrlPart)"
                        }
                    }
                } else {
                    $AddToCache = $false
                    Write-Verbose "Found a matching URL, but there are no static entries for '$Url' Url. Please add them in the '$Path\Data\UrlWildcardLookup.json'." 
                }
            }
        }
        if($StaticUrls.Length -eq 0 -and $AddToCache){
            Write-Warning "Could not find a matching static URL for the suplied wildcard '$Url' Url."
            $WildCardJSONObjs += [PSCustomObject]@{ Wildcard = $Url; static = $null }
            Out-File -FilePath "$Path\Data\UrlWildcardLookup.json" -InputObject ($WildCardJSONObjs | ConvertTo-Json) -Force 
        }
    } catch {
        Write-Warning "Could not find '$Path\Data\UrlWildcardLookup.json', failed to convert wildcard into static url. $($_.Exception.Message)" 
        
    }
    return [String[]]$StaticUrls
}