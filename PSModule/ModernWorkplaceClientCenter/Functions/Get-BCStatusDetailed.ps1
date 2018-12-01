function Get-BCStatusDetailed(){
    <#
    .Synopsis
    Returns Branch Cache usage statistsics of the last downloads per source host including peer usage statistics.

    .Description
    Returns Windows BranchCache usage statistsics of the last downloads per source host including peer usage statistics. With this information you are able to analyze if downloads are using the peers and save internet bandwidth.

    .Example
    # Displays a full report BranchCache downloads.
    Get-BCStatusDetailed
    #>
    $Events = Get-WinEvent -LogName "Microsoft-Windows-Bits-Client/Operational" | Where-Object { 60 -eq $_.Id }

    ForEach ($Event in $Events) {            
        # Convert the event to XML            
        $eventXML = [xml]$Event.ToXml()            
        # Iterate through each one of the XML message properties            
        For ($i=0; $i -lt $eventXML.Event.EventData.Data.Count; $i++) {    
            if($eventXML.Event.EventData.Data[$i].name -eq "url"){
                Add-Member -InputObject $Event -MemberType NoteProperty -Force -Name "UrlHost" -Value ([uri]($eventXML.Event.EventData.Data[$i].'#text')).DnsSafeHost 
            }        
            # Append these as object properties            
            Add-Member -InputObject $Event -MemberType NoteProperty -Force -Name  $eventXML.Event.EventData.Data[$i].name -Value $eventXML.Event.EventData.Data[$i].'#text'            
        }            
    } 
    $BCStatsExtended = @()
    $BCStats = $Events | Group-Object -Property "UrlHost" 
    foreach($BCStat in $BCStats){ 
        $t = New-Object PSObject
        Add-Member -InputObject $t -MemberType NoteProperty -Force -Name  "UrlHost" -Value $BCStat.Name
        Add-Member -InputObject $t -MemberType NoteProperty -Force -Name  "Count" -Value $BCStat.Count
        Add-Member -InputObject $t -MemberType NoteProperty -Force -Name  "MBTotal" -Value (($BCStat.Group | Measure-Object -Property bytesTotal -Sum).Sum/1MB)
        Add-Member -InputObject $t -MemberType NoteProperty -Force -Name  "MBTransferedFromPeers" -Value (($BCStat.Group | Measure-Object -Property bytesTransferredFromPeer -Sum).Sum/1MB)
        Add-Member -InputObject $t -MemberType NoteProperty -Force -Name  "peerProtocolFlagsOfFirstDownload" -Value (($BCStat.Group | Select-Object -First 1 -Property peerProtocolFlags).peerProtocolFlags)
        $BCStatsExtended += $t
    }
    $BCStatsExtended
}