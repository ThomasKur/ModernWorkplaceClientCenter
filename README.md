# Modern Workplace Client Center

<img align="right" src="https://raw.githubusercontent.com/ThomasKur/ModernWorkplaceClientCenter/master/Logo/MWCC-Logo-256.png" alt="MWCC Logo">This repository will be the home of a PowerShell Module, which helps to simplify tasks on MDM managed Windows clients. In a second step there will be a UI, which leverages these PowerShell functions for Admins which like a UI. Feedback is welcome!

## PowerShell Module 

This PowerShell module will contain all functions for DevOps like me, which like to use PowerShell everywhere. The goal of the module is not only to read and display properties, instead it should correleate settings and event log entries together and help you during troubleshooting. If you have some specific use cases like "If this happens, then you can apply this solution", then I'm happy to get your feedback.

The following functions are available now:

* Get-DsRegStatus --> Ever used dsregcmd and thought about why it is not a PowerShell command? Here it is...
* Invoke-AnalyzeHybridJoinStatus --> Troubleshoots Azure Hybrid Join status and covers already 13 checks.
* Invoke-AnalyzeMDMEnrollmentStatus --> Troubleshoots Windows 10 MDM Enrollment status and covers 4 checks.
* Get-SiteToZoneAssignment --> Returns Internet Explorer Site to Zone assignments. This is more a helper function, but perhaps it helps you somewhere else.
* Get-MdmMsiApp --> Retrieves information about all MDM assigned applications, including their installation state.
* Get-MDMDeviceOwnership --> Returns information about the Ownership of the Device.
* Reset-MDMEnrollmentStatus --> Resets Windows 10 MDM Enrollment Status.
* Get-MDMEnrollmentStatus --> Get Windows 10 MDM Enrollment Status.
* Get-MDMPSScriptStatus --> Returns information about the execution of PowerShell Scripts deployed with Intune.

The following functions will be available in the near future:

* Autopilot Troubleshooting
* Improvement Intune Enrollment Troubleshooting
* Intune MSI App Installation Troubleshooting
* Intune PowerShell Script Installation Troubleshooting
* BranchCache and Delivery Optimization Troubleshooting
* Pester Tests

### Usage

Download the PS module from the PSGallery and Import the module:

```
Install-Module ModernWorkplaceClientCenter
```

Get all available Commands of the module:

```
Get-Command -Module ModernWorkplaceClientCenter 
```

## Client Center UI

This is a planned project for the next months as soon the PowerShell functions are well working.

# Issues / Feedback

For any issues or feedback related to this module, please register for GitHub, and post your inquiry to this project's issue tracker.
