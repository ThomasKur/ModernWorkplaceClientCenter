function Get-DsRegStatus {
     <#
     .Synopsis
     Returns the output of dsregcmd /status as a PSObject.

     .Description
     Returns the output of dsregcmd /status as a PSObject. All returned values are accessible by their property name. Now per section as a subobject.

     .Example
     # Displays a full output of dsregcmd / status.
     Get-DsRegStatus
     #>
     [cmdletbinding()]
     Param()
     $dsregcmd = & "$env:windir\system32\dsregcmd.exe" /status 2>&1
     $ResultObj = New-Object -TypeName PSObject

     # This was original pattern string but did not parse all properties
     ## $PatStr = ' *[A-z]+ : [A-z]+ *'

     # Updated RegEx pattern string
     $PatStr = ' *[^\n\r]+ : [^\n]+ *'

     # Parse through output using RegEx pattern, iterate through lines and build objects
     $null = $dsregcmd | Select-String -Pattern $PatStr | ForEach-Object {
          # Set noteproperty name
          $PropName = (([String]$_).Trim() -split " : ")[0]
          $PropName = $PropName.replace(' ', '')

          # Set noteproperty value
          $Val = (([String]$_).Trim() -split " : ")[1]
          # Replace YES/NO value with bool type
          $Val = $Val -Replace ('^YES$', [bool]$true) -Replace ('^NO$', [bool]$false)
          
          # Add property to PSObject of $ResultObj
          Add-Member -InputObject $ResultObj -MemberType NoteProperty -Name $PropName -Value $Val
     }
     $ResultObj
}