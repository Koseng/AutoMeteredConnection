[void][Windows.Networking.Connectivity.NetworkInformation, Windows, ContentType = WindowsRuntime]
Add-Type -AssemblyName System.Windows.Forms
$logFile = "c:\checkMetering\logMetered.txt" 
$logFileOld = "c:\checkMetering\logMetered.old"
$msg = "Activating metered internet connection."

$macsToBeMetered = @("e0-a3-ac-ff-24-4b", "55-66-77-55-fc-fc")

function Log { Param ($text) 
    Write-Host $text
    "$(get-date -format "yyyy-MM-dd HH:mm:ss.fff"): $($text)" | out-file $logFile -Append }

try {

    Log "Script Started"
    if ((Get-ChildItem -file $logFile).length -ge 1000000) {
        Copy-Item $logFile $logFileOld
        Remove-Item $logFile
    }

    $connectionProfile = [Windows.Networking.Connectivity.NetworkInformation]::GetInternetConnectionProfile()
    if ($connectionProfile -ne $null) {

        # Determine if connection is metered
        $c = $connectionProfile.GetConnectionCost()
        $netConnectionMetered = ($c.ApproachingDataLimit -or $c.OverDataLimit -or $c.Roaming -or $c.BackgroundDataUsageRestricted -or ($c.NetworkCostType -ne "Unrestricted"))
  
        # Determine basic data of connection
        $netInterfaceGuid  = "{$($connectionProfile.NetworkAdapter.NetworkAdapterId)}"
        $netInterfaceIndex = (Get-NetAdapter -Physical | where InterfaceGuid -eq $netInterfaceGuid).InterfaceIndex
        $netGatewayIP      = (Get-NetRoute -DestinationPrefix 0.0.0.0/0 | where InterfaceIndex -eq $netInterfaceIndex).NextHop
        $netInterfaceIP    = (Get-NetIPAddress -AddressFamily IPv4 | where ifIndex -eq $netInterfaceIndex).IPAddress
        $netProfileName    = $connectionProfile.ProfileName
        $regPath           = "HKLM:\SOFTWARE\Microsoft\DusmSvc\Profiles\$($netInterfaceGuid)\*"
    
        # Determine MAC of GatewayIP
        $netGatewayMac = ""
        $arp_output = (arp -a $netGatewayIP -n $netInterfaceIP) -join '' # create a single string
        $isMatch = $arp_output -match "([0-9A-F]{2}([:-][0-9A-F]{2}){5})"
        if ($isMatch) { $netGatewayMac = $Matches[0] }

        Log "$($netProfileName)#$($netConnectionMetered)#$($netInterfaceGuid)#$($netInterfaceIndex)#$($netInterfaceIP)#$($netGatewayIP)#$($netGatewayMac)"

        # Activate metered connection if necessary
        if ($macsToBeMetered -contains $netGatewayMac) {

            if (-Not $netConnectionMetered) {
                [System.Windows.Forms.MessageBox]::Show($msg + " Profile=$($netProfileName)",'Connection Check','Ok','Warning')
                Log "Activating metered connection. Profile=$($netProfileName)"
                if ($connectionProfile.IsWlanConnectionProfile) {
                    netsh wlan set profileparameter name="$netProfileName" cost=Fixed -erroraction stop
                }
                else { # Ethernet
		    New-Item $regPath -Force | Out-Null
                    Set-Itemproperty -path $regPath -Name 'UserCost' -value 2 -Force -erroraction stop
                    Restart-Service -Name DusmSvc  -Force -erroraction stop
                }
            }
        }
        # Reset metered for ethernet
        elseif (-not $connectionProfile.IsWlanConnectionProfile -and $netConnectionMetered) {
            Log "Deactivating metered connection. Profile=$($netProfileName)"
	    New-Item $regPath -Force | Out-Null
            Set-Itemproperty -path $regPath -Name 'UserCost' -value 0 -Force -erroraction stop
            Restart-Service -Name DusmSvc  -Force -erroraction stop
        }
    }
}
catch {
    $errorMsg = $_ | Out-String
    log "$($errorMsg)"
}


