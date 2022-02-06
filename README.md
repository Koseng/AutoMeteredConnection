# AutoMeteredConnection
Automatic activation of metered connection on windows when connected to certain router.

The router is identified via its MAC adress. The MAC adress can be determined via ```arp -a``` in the command shell, look out for the ip adress of the router.

In the case of Wifi, Windows saves the setting for each Wifi profile. For Ethernet the setting is reset by Windows after reboot. If a connection to an internet router with a configured MAC adresses is established, metered connection is auto activated. In case of Ethernet if a connection to a non configured router is established, metered connection is auto deactivated.

## Configuration
In the default configuration the scripts reside in ```c:\checkMetering\```

In autoMeteredConnection.ps1 configure the directory for the log files and the MAC adresses which shall be checked.

``` PowerShell
$logFile = "c:\checkMetering\logMetered.txt" 
$logFileOld = "c:\checkMetering\logMetered.old"
$msg = "Activating metered internet connection."

$macsToBeMetered = @("e0-a3-ac-ff-24-4b", "55-66-77-55-fc-fc")
```

In createScheduledTask.bat configure the path of the script and set the interval in minutes how often the check shall occur. Default path is c:\checkMetering\ and cadence is every 5 minutes.

```schtasks /create /sc minute /tn CheckMetering /tr c:\checkMetering\startHidden.vbs /mo 5 /RL HIGHEST```

**To create the schedule task in windows run ```createScheduledTask.bat``` as admin.**


