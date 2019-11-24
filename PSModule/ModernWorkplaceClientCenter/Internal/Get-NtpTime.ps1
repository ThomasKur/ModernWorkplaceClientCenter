Function Get-NtpTime ( [String]$NTPServer )
{
    # Build NTP request packet. We'll reuse this variable for the response packet
    $NTPData    = New-Object byte[] 48  # Array of 48 bytes set to zero
    $NTPData[0] = 27                    # Request header: 00 = No Leap Warning; 011 = Version 3; 011 = Client Mode; 00011011 = 27

    # Open a connection to the NTP service
    $Socket = New-Object Net.Sockets.Socket ( 'InterNetwork', 'Dgram', 'Udp' )
    $Socket.SendTimeOut    = 2000  # ms
    $Socket.ReceiveTimeOut = 2000  # ms
    $Socket.Connect( $NTPServer, 123 )

    # Make the request
    $Null = $Socket.Send(    $NTPData )
    $Null = $Socket.Receive( $NTPData )

    # Clean up the connection
    $Socket.Shutdown( 'Both' )
    $Socket.Close()

    # Extract relevant portion of first date in result (Number of seconds since "Start of Epoch")
    $Seconds = [BitConverter]::ToUInt32( $NTPData[43..40], 0 )

    # Add them to the "Start of Epoch", convert to local time zone, and return
    ( [datetime]'1/1/1900' ).AddSeconds( $Seconds ).ToLocalTime()
} 