function Invoke-AnalyzeMDMEnrollmentStatus {
    <#
    .Synopsis
    Analyzes current status of the device regarding Intune/MDM enrollment.

    .Description
    Analyzes current status of the device regarding Intune/MDM enrollment.

    Returns array of Messages with four properties:

    - Testname: Name of the Tets
    - Type: Information, Warning or Error
    - Issue: Description of the issue
    - Possible Cause: Tips on how to solve the issue.

    .Parameter IncludeEventLog
    By specifying this command also the most relevant Windows Event Log entries from the last 10 Minutes related to MDMe Enrollment are included in the Output of this CmdLet.

    .Example
    # Displays a deep analyisis of the currently found issues in the system.
    Invoke-AnalyzeIntuneEnrollmentStatus

    #>
    param(
         [switch]$IncludeEventLog
    )
    $mdmstatus = Get-MDMEnrollmentStatus
    $possibleErrors = @()
    if($null -eq $mdmstatus){
         $possibleErrors += New-AnalyzeResult -TestName "MDM Enrollment Regkeys" -Type Error -Issue "We could not locate MDM enrollment registry key under HKLM:\SOFTWARE\Microsoft\Enrollments." -PossibleCause "Try starting enrollment again. Xou can start MDM enrollment by executing 'ms-device-enrollment:?mode=mdm'."
    } else {
         if($mdmstatus.EnrollmentState -eq 0 -or $mdmstatus.EnrollmentType -eq 0){
              $possibleErrors += New-AnalyzeResult -TestName "MDM Enrollment Regkeys" -Type Error -Issue "The enrollment has not yet started because Enrollment Type or EnrollmentState is still 0 in the registry($($mdmstatus.PSPath))." -PossibleCause "Try starting enrollment again. Xou can start MDM enrollment by executing 'ms-device-enrollment:?mode=mdm'."
         }
    }
    $dsregstatus = Get-DsRegStatus
    if($dsregstatus.AzureAdJoined -ne "YES"){
         $possibleErrors += New-AnalyzeResult -TestName "Azure AD Join" -Type Warning -Issue "The device is not Azure AD Joined or Hybrid registered. Therefore auto enrollment will not work. If you do the enrollment manually, then you can ignore this warning." -PossibleCause "Try analysing the Azure AD Hybrid Join by using Invoke-AnalyzeHybridJoinStatus."
    }
    $AutoEnrollTask =  Get-ScheduledTask -TaskName "Schedule created by enrollment client for automatically enrolling in MDM from AAD" -ErrorAction SilentlyContinue
    if($null -eq $AutoEnrollTask){
         $possibleErrors += New-AnalyzeResult -TestName "Scheduled Task" -Type Warning -Issue "The task for auto enrollment could not be found in the Windows Event log '\Microsoft\Windows\EnterpriseMgmt'." -PossibleCause "Please check if automatic enrollment is configured by GPO 'https://docs.microsoft.com/en-us/windows/client-management/mdm/enroll-a-windows-10-device-automatically-using-group-policy#configure-the-auto-enrollment-for-a-group-of-devices'"
    }
    # Analyze Eventlogs
    if($IncludeEventLog){
         $MDMEvents = Get-WinEvent -LogName "Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin" | Where-Object { ($_.LevelDisplayName -eq "Error" -or $_.LevelDisplayName -eq "Warning") -and $_.TimeCreated -gt [DateTime]::Now.AddMinutes(-10)  }
         foreach($MDMEvent in ($MDMEvents | Group-Object -Property Id)){
              $possibleErrors += New-AnalyzeResult -TestName "EventLog-WorkplaceJoin" -Type ($MDMEvent.Group[0].LevelDisplayName) -Issue "EventId: $($MDMEvent.Name)`n$($MDMEvent.Group[0].Message)" -PossibleCause ""
         }
    }

    # No errors detected, return success message
    if($null -eq $possibleErrors){
         $possibleErrors += New-AnalyzeResult -TestName "All" -Type Information -Issue "All tests went trough successfull." -PossibleCause ""
    }

    return $possibleErrors
}