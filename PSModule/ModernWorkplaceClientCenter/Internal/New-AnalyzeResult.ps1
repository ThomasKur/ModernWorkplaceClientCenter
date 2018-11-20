function New-AnalyzeResult{
    <#
    .Synopsis
    Creates an new analysis object which will be returned by most of the analytics functions in the module.

    .Description
    Returns an object with the following properties:
    - Testname
    - Type
    - Issue
    - PossibleCause

    .Example
    # New Error Result
    New-AnalyzeResult -Testname "AD Check" -Type Error -Issue "Description of the found Issue" -PossibleCause "Description of possible solutions related to the Issue"

    #>
    [OutputType([PSObject])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true)]
        [String]$TestName,
        [ValidateSet("Error","Warning","Information")]
        [String]$Type = "Information",
        [String]$Issue,
        [String]$PossibleCause

    )
    $newResolution = New-Object -TypeName PSObject
    Add-Member -InputObject $newResolution -MemberType NoteProperty -Name "Testname" -Value $TestName
    Add-Member -InputObject $newResolution -MemberType NoteProperty -Name "Type" -Value $Type
    Add-Member -InputObject $newResolution -MemberType NoteProperty -Name "Issue" -Value $Issue
    Add-Member -InputObject $newResolution -MemberType NoteProperty -Name "PossibleCause" -Value $PossibleCause
    if ($PSCmdlet.ShouldProcess("Should return Object?")) {
        return $newResolution
    }
}