function Get-MDMEnrollmentStatus {
    <#
    .Synopsis
    Get Windows 10 MDM Enrollment Status.

    .Description
    Get Windows 10 MDM Enrollment Status with Translated Error Codes.

    Returns $null if Device is not enrolled to an MDM.

    .Example
    # Get Windows 10 MDM Enrollment status
    Get-MDMEnrollmentStatus
    #>
    param()
    #Locate correct Enrollment Key
    $EnrollmentKey = Get-Item -Path HKLM:\SOFTWARE\Microsoft\Enrollments\* | Get-ItemProperty | Where-Object -FilterScript {$null -ne $_.UPN}
    if($EnrollmentKey){
        Add-Member -InputObject $EnrollmentKey -MemberType NoteProperty -Name EnrollmentTypeText -Value (Invoke-TranslateMDMEnrollmentType -Id ($EnrollmentKey.EnrollmentType))
    } else {
        Write-Error "Device is not enrolled to MDM."
    }
    return $EnrollmentKey
}