(*
Script simulating Time Capsule-like automatic backup of Mac to PC network drive.
Features:
- Looks for connection to home wifi
- Wakes up PC with wake-on-lan
- Automatic network located sparse bundle mapping
- Automatic unmapping after backup completion
- Connects to PC only once per calendar day

Author: Martin Machyna
Date: August 19, 2020
*)

global lastBackup
global TMstat
global isConnected
global SSID
global wifiName1
global wifiName2
global TMname
global pcIP
global pcMacAddress
global smbUserName
global smbPwd
global smbPath
global smbMountPoint
global sparseBundleMountPoint
global sparseBundlePath

(* User specific settings *)
set wifiName1 to "Wifi_5G"
set wifiName2 to "Wifi_2.4G"
set TMname to "TimeMachineHome"
set pcIP to "192.168.1.0" -- This was to contain subnet mask. See: https://github.com/jpoliv/wakeonlan
set pcMacAddress to "A4:BB:6D:A5:C4:07"
set smbUserName to "john.doe" -- For email adresses replace @ with URL form %40 e.g. john.doe%40gmail.com
set smbPwd to "password"
set smbPath to "desktop-PCname/shared_folder"
set smbMountPoint to "/Users/johndoe/shared_folder" -- Need to create empty folder with this name in order to successfully mount
set sparseBundleMountPoint to "/Volumes/TimeMachineHome"
set sparseBundlePath to "/Users/johndoe/shared_folder/johndoes-mac_TimeMachine.sparsebundle"


(* Set initial values at start up *)
set lastBackup to do shell script "log show --style syslog --info --last 48h --predicate 'processImagePath contains \"backupd\" and subsystem beginswith \"com.apple.TimeMachine\"' | grep 'Backup completed successfully' | tail -n 1 | cut -d' ' -f1 | awk -v FS=\"-\" '{print int($3) \".\" int($2) \".\" substr($1, 3)}'"
set isConnected to false
set TMstat to "BackupNotRunning"

on idle
    set SSID to do shell script "/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I | awk '/ SSID: / {print $2}'"

    (* Check if we are connected to home wifi network *)
    if (SSID is wifiName1) or (SSID is wifiName2) then

        set TMstat to do shell script "tmutil currentphase"

        (* After connecting to wifi and after back up is finished update last backup date  *)
        if (lastBackup is not short date string of (current date)) and (TMstat is "BackupNotRunning") then
            set lastBackup to do shell script "log show --style syslog --info --last 48h --predicate 'processImagePath contains \"backupd\" and subsystem beginswith \"com.apple.TimeMachine\"' | grep 'Backup completed successfully' | tail -n 1 | cut -d' ' -f1 | awk -v FS=\"-\" '{print int($3) \".\" int($2) \".\" substr($1, 3)}'"
        end if

        (* If there is no backup today keep cheking for Time Machine drive connection and keep PC awake *)
        if lastBackup is not short date string of (current date) then
            do shell script "/opt/local/bin/wakeonlan -i " & pcIP & " " & pcMacAddress
            delay 60

            try
                tell application "Finder"
                    set isConnected to disk TMname exists
                end tell
            end try

            if isConnected = false then
                try
                    do shell script "mount_smbfs //" & smbUserName & ":" & smbPwd & "@" & smbPath & " " & smbMountPoint
                    do shell script "hdiutil attach -mountpoint " & sparseBundleMountPoint & " " & sparseBundlePath
                end try
            end if
        end if

        (* After the back up is done disconnect from PC *)
        if (lastBackup is short date string of (current date)) and (TMstat is "BackupNotRunning") and (isConnected = true) then
            try
                do shell script "hdiutil detach " & sparseBundleMountPoint
                delay 60
                do shell script "diskutil unmount " & smbMountPoint
            end try

            try
                tell application "Finder"
                    set isConnected to disk "TimeMachineHome" exists
                end tell
            end try
        end if

    end if

    return 300
end idle
