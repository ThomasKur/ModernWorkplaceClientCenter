# Release Notes

## 0.1.6 - Bugfix in Module Manifest

* Bugfix Module manifest to Load Nested Module

## 0.1.5 - Added Connectifity Tests

* Correct Typos
* Added connectifity Tests to Invoke-AnalyzeHybridJoinStatus
* Added Nested Module HttpConnectivityTester from https://github.com/nsacyber/HTTP-Connectivity-Tester

## 0.1.4 - Added Analytic checks

* New DNS checks in Invoke-AnalyzeMDMEnrollmentStatus
* Bugfix in generating Successmessage in Invoke-AnalyzeMDMEnrollmentStatus

## 0.1.3 - Improved Analytic results

* Improved Anayltic results by hiding unhelpful tips when the root cause is also well known like the device is not domain joined.
* Get-MDMDeviceOwnership --> Return well interpretable strings instead of just integer values.

## 0.1.2 - Bugfixing

* Bugfixing Get-MDMEnrollmentStatus, Get-MDMMsiApp, Get-MDMPSScriptStatus for unenrolled devices.

## 0.1.1 - Improved build process

* Improved build.ps1

## 0.1.0 - First Release

* Get-DsRegStatus --> Ever used dsregcmd and thought about why it is not a PowerShell command? Here it is...
* Invoke-AnalyzeHybridJoinStatus --> Troubleshoots Azure Hybrid Join status and covers already 13 checks.
* Invoke-AnalyzeMDMEnrollmentStatus --> Troubleshoots Windows 10 MDM Enrollment status and covers 4 checks.
* Get-SiteToZoneAssignment --> Returns Internet Explorer Site to Zone assignments. This is more a helper function, but perhaps it helps you somewhere else.
* Get-MdmMsiApp --> Retrieves information about all MDM assigned applications, including their installation state.
* Get-MDMDeviceOwnership --> Returns information about the Ownership of the Device.
* Reset-MDMEnrollmentStatus --> Resets Windows 10 MDM Enrollment Status.
* Get-MDMEnrollmentStatus --> Get Windows 10 MDM Enrollment Status.
* Get-MDMPSScriptStatus --> Returns information about the execution of PowerShell Scripts deployed with Intune.
