# Release Notes

## 0.1.16 - Bugfix Get-Dsregcmd

* Last section was not returned

## 0.1.15 - Improving Get-Dsregcmd parsing

* The sections displayed in the dsregcmd /status output are now sub objects. Therfore also multiple work accounts are not supported.
* Updating chached results for connectivity tests

## 0.1.14 - Adding Invoke-TestAutopilotNetworkEndpoints and Invoke-IntuneCleanup

* Automatically clean up duplicated devices in Intune based on the device serial number.
* Check Autopilot Network Endpoints

## 0.1.13 - Bugfixing Invoke-AnalyzeHybridJoinStatus

* Bugfix with String Array and Split Invoke-AnalyzeHybridJoinStatus.

## 0.1.12 - Improvement Invoke-AnalyzeHybridJoinStatus

* Improve SCP check inInvoke-AnalyzeHybridJoinStatus to read information from root domain.

## 0.1.11 - Bugfix

* Bugfix Invoke-AnalyzeAzureConnectivity

## 0.1.10 - Extended Azure AD Hybrid Join checks

* Extended Azure AD Hybrid Join checks to include User Device Registration Event Log Invoke-AnalyzeHybridJoinStatus
* Check manually defined IE Intranet Sites Invoke-AnalyzeHybridJoinStatus
* Added TcpConnectivityTester Module to check Non HTTP Connections
* Added Invoke-AnalyzeAzureConnectivity to check for connectivity issues to O365 and Azure based on the actual published list of Microsoft.

## 0.1.9 - Delivery Optimization

* Improved loading of HttpConnectivtyTester Module
* Added new function top analyze Delivery Optimization Configuration and connectifity on a device Invoke-AnalyzeDeliveryOptimization

## 0.1.8 - IE Site to Zone Checks improved to detect URL's correctly when entered without https

* Verifiy Site to Zone alignment if not exaxtly the correct urls are entered(With or Without HTTP(S)) Invoke-AnalyzeHybridJoinStatus
* Improve remediation action description if HTTP Error 407 is returned by a proxy
* Added new function to analyze BranchCache traffic. Get-BCStatusDetailed

## 0.1.7 - Bugfix in Get-SiteToZoneAssignment

* Bugfix Get-SiteToZoneAssignment: Method invocation failed because Microsoft.Win32.RegistryKey does not contain a method named 'op_Addition'

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
