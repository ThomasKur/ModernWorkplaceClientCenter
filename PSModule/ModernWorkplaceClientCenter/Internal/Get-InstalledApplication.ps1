Function Get-InstalledApplication {
    <#
    .SYNOPSIS
         Retrieves information about all installed applications.
    .DESCRIPTION
         Retrieves information about all installed applications by querying the registry.
         Returns information about application publisher, name & version, product code, uninstall string, install source, location, date, and application architecture.

    .EXAMPLE
         Get-InstalledApplication
    #>
    [OutputType([System.Object[]])]
    [CmdletBinding()]
    param()
    [string[]]$regKeyApplications = 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    ## Enumerate the installed applications from the registry for applications that have the "DisplayName" property
    [psobject[]]$regKeyApplication = @()
    ForEach ($regKey in $regKeyApplications) {
        If (Test-Path -LiteralPath $regKey -ErrorAction 'SilentlyContinue') {
            [psobject[]]$UninstallKeyApps = Get-ChildItem -LiteralPath $regKey -ErrorAction 'SilentlyContinue'
            ForEach ($UninstallKeyApp in $UninstallKeyApps) {
                Try {
                        [psobject]$regKeyApplicationProps = Get-ItemProperty -LiteralPath $UninstallKeyApp.PSPath -ErrorAction 'Stop'
                        If ($regKeyApplicationProps.DisplayName) { [psobject[]]$regKeyApplication += $regKeyApplicationProps }
                }
                Catch{
                        Write-Warning "Unable to enumerate properties from registry key path [$($UninstallKeyApp.PSPath)]."
                        Continue
                }
            }
        }
    }

    ## Create a custom object with the desired properties for the installed applications and sanitize property details
    [psobject[]]$installedApplication = @()
    ForEach ($regKeyApp in $regKeyApplication) {
        Try {
            [string]$appDisplayName = ''
            [string]$appDisplayVersion = ''
            [string]$appPublisher = ''

            ## Remove any control characters which may interfere with logging and creating file path names from these variables
            $appDisplayName = $regKeyApp.DisplayName -replace '[^\u001F-\u007F]',''
            $appDisplayVersion = $regKeyApp.DisplayVersion -replace '[^\u001F-\u007F]',''
            $appPublisher = $regKeyApp.Publisher -replace '[^\u001F-\u007F]',''

            ## Determine if application is a 64-bit application
            [boolean]$Is64BitApp = If (($is64Bit) -and ($regKeyApp.PSPath -notmatch '^Microsoft\.PowerShell\.Core\\Registry::HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node')) { $true } Else { $false }

            $installedApplication += New-Object -TypeName 'PSObject' -Property @{
                UninstallSubkey = $regKeyApp.PSChildName
                ProductCode = If ($regKeyApp.PSChildName -match $MSIProductCodeRegExPattern) { $regKeyApp.PSChildName } Else { [string]::Empty }
                DisplayName = $appDisplayName
                DisplayVersion = $appDisplayVersion
                UninstallString = $regKeyApp.UninstallString
                InstallSource = $regKeyApp.InstallSource
                InstallLocation = $regKeyApp.InstallLocation
                InstallDate = $regKeyApp.InstallDate
                Publisher = $appPublisher
                Is64BitApplication = $Is64BitApp
            }
        }
        Catch {
            Write-Error "Failed to resolve application details from registry for [$appDisplayName]. $($_.Exception)"
            Continue
        }
    }

    Write-Information "Found $($installedApplication.Count) Apps."
    return $installedApplication
}