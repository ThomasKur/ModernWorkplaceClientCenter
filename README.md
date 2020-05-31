# Modern Workplace Client Center

<img align="right" src="https://raw.githubusercontent.com/ThomasKur/ModernWorkplaceClientCenter/master/Logo/MWCC-Logo-256.png" alt="MWCC Logo">This repository will be the home of a PowerShell Module, which helps to simplify tasks on MDM managed Windows clients. In a second step there will be a UI, which leverages these PowerShell functions for Admins which like a UI. Feedback is welcome!

## PowerShell Module

This PowerShell module will contain all functions for DevOps like me, which like to use PowerShell everywhere. The goal of the module is not only to read and display properties, instead it should correleate settings and event log entries together and help you during troubleshooting. If you have some specific use cases like "If this happens, then you can apply this solution", then I'm happy to get your feedback.

The following functions are available now:

* Get-DsRegStatus --> Ever used dsregcmd and thought about why it is not a PowerShell command? Here it is...
* Invoke-AnalyzeHybridJoinStatus --> Troubleshoots Azure Hybrid Join status and covers already 17 checks.
* Invoke-AnalyzeMDMEnrollmentStatus --> Troubleshoots Windows 10 MDM Enrollment status and covers 6 checks.
* Get-SiteToZoneAssignment --> Returns Internet Explorer Site to Zone assignments. This is more a helper function, but perhaps it helps you somewhere else.
* Get-MdmMsiApp --> Retrieves information about all MDM assigned applications, including their installation state.
* Get-MDMDeviceOwnership --> Returns information about the Ownership of the Device.
* Reset-MDMEnrollmentStatus --> Resets Windows 10 MDM Enrollment Status.
* Get-MDMEnrollmentStatus --> Get Windows 10 MDM Enrollment Status.
* Get-MDMPSScriptStatus --> Returns information about the execution of PowerShell Scripts deployed with Intune.
* Get-BCStatusDetailed --> Returns Branch Cache usage statistsics of the last downloads per source host including peer usage statistics.
* Invoke-AnalyzeDeliveryOptimization --> Analyze Delivery Optimization Configuration and connectifity on a device.
* Invoke-AnalyzeAzureConnectivity --> Check for connectivity issues to O365 and Azure based on the actual published list of Microsoft(https://docs.microsoft.com/en-us/office365/enterprise/urls-and-ip-address-ranges).

The following functions will be available in the near future:

* Autopilot Troubleshooting
* Improvement Intune Enrollment Troubleshooting
* Improvement Intune MSI App Installation Troubleshooting
* Improvement Intune PowerShell Script Installation Troubleshooting
* Pester Tests

### Usage

Download the PS module from the PSGallery and Import the module:

```powershell
Install-Module ModernWorkplaceClientCenter
```

Get all available Commands of the module:

```powershell
Get-Command -Module ModernWorkplaceClientCenter
```

## Client Center UI

This is a planned project for the next months as soon the PowerShell functions are well working.

## Issues / Feedback

For any issues or feedback related to this module, please register for GitHub, and post your inquiry to this project's issue tracker.

## Contributions

* HttpConncetifityTester Module: This Work was prepared by a United States Government employee and, therefore, is excluded from copyright by Section 105 of the Copyright Act of 1976. Copyright and Related Rights in the Work worldwide are waived through the [CC0 1.0 Universal license](https://creativecommons.org/publicdomain/zero/1.0/). More great tools can be found here: https://github.com/nsacyber
