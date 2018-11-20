function Reset-MDMEnrollmentStatus {
    <#
    .Synopsis
    Resets Windows 10 MDM Enrollment Status.

    .Description
    If you get an error upon trying to register a Windows computer that the device was already enrolled, but you are unable or have already unenrolled the device, you may have a fragment of device enrollment configuration in the registry.

    Reset done according to https://docs.microsoft.com/en-us/windows-server/identity/ad-fs/operations/configure-device-based-conditional-access-on-premises#troubleshooting

    .Example
    # Resets the Device Enrollment state and allows to rerun the MDM enrollment Wizard
    Reset-MDMEnrollmentStatus
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()
    if(-not (Get-IsAdmin)){
        throw "Access Denied: The cmdlet needs to be executed with administrator priviledges."
    }
    #Locate correct Enrollment Key
    $EnrollmentKey = Get-Item -Path HKLM:\SOFTWARE\Microsoft\Enrollments\* | Get-ItemProperty | Where-Object -FilterScript {$null -ne $_.UPN}
    if ($PSCmdlet.ShouldProcess("Would you like to reset EnrollmentStatus to 0?")) {
        Set-ItemProperty -Path $EnrollmentKey.PSPath -Name EnrollmentType -Value 0 -Force
    }
}