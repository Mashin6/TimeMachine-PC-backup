# TimeMachine to PC backup
Script for automatic Time Machine backup of Mac to PC HDD over local wifi network. Simulates the discontinued Time Capsule behavior, but restricts time machine backups to only once per day. Script will silently autoload after mac bootup or restart and will keep running invisibly in the background.

*Requires:*
* MacOS 10.15 Catalina
* Wakeonlan (https://github.com/jpoliv/wakeonlan), which can be istalled with Mac Ports (https://ports.macports.org/port/wakeonlan)
* PC needs to be set up to be able to boot and/or wake from sleep with wake-on-lan

## What's it doing:
1. Checks every 5 minutes if Mac is connected to wifi network with predefined name
2. When connected, script checks if any time machine backup was done on that day
3. If no backup was done that day, script wakes up remote PC with wake-on-lan
4. Mounts shared folder on PC and attaches there located sparse bundle
5. Keeps PC awake by regularly sending wake-on-lan packets
5. Waits for successfull finish of a backup and then disconnects from sparsebundle and PC


## Installation/Set up
1. Set up disk for Time machine back up
    1. Create Sparse bundle virtual disk
        * Run Disk Utility
        * File > New Image > Blank Image
        * Sparse bundle disk image
        * Single partition - GUID
        * Select Mac OS Extended journaled
        * Select max size (e.g. 5 TB)
        * Choose name for disk and file: e.g. `TimeMachineHome`
        * Choose a file name e.g. `mac_TimeMachine.sparsebundle`  
    2. Map as network drive
        * On PC: On HDD you want to use for backup create new folder e.g. `mac_backup_folder`. Set sharing by right click > Properties > sharing > share + permissions all allow
        * On Mac: Go to Finder and Connect to PC (or `cmd + K`). Use address: `smb://name_of_PC/mac_backup_folder`. As credentials use you windows account login.
        * Create mount point for your PC folder in your home directory by creating new folder with name `mac_backup_folder`(in Treminal: `mkdir ~/mac_backup_folder`) as mount_smbfs utility can't mount to Volumes folder.
        * Copy Sparsebundle file to shared folder on PC.
        * Mount the sparsebundle disk by running in terminal `hdiutil attach -mountpoint /Volumes/TimeMachineHome /Volumes/mac_backup_folder/mac_TimeMachine.sparsebundle`
    3. Make TimeMachine back up to the drive
        * Go to Time Machine preferences and add the TimeMachineHome disk as backup disk. In case you already have one and this will be your second backup destination run in Terminal: `sudo  tmutil setdestination -a /Volumes/TimeMachineHome/`
2. Install Wakeonlan with: `sudo ports install wakeonlan`
3. Open `PC-TimeMachine.scpt` in Script Editor.app on Mac and modify values of set up variables
    * Name of your wifi network(s) where PC is reachable: `wifiName1` and/or `wifiName2`
    * Name of your Time Machine sparse bundle disk: `TMname` e.g. `TimeMachineHome`
    * Broadcast IP address of PC machine (note: this takes into account your subnet mask see: https://github.com/jpoliv/wakeonlan) : `pcIP`
    * MAC address of PC. Wifi adapter if wake-on-lan over wifi is supported on PC, but typically ethernet card and PC is connected to router via ethernet cable: `pcMacAddress`
    * Login credentials for PC: `smbUserName` and `smbPwd`. (Note if user name is email `@` symbol must be replaced by `%40` e.g. `john.doe%40gmail.com`
    * Network path to shared folder on PC. PC-name/mac_backup_folder: `smbPath`
    * Path to created mount point in your home directory /Users/johndoe/mac_backup_folder: `smbMountPoint`
    * Mount point for sparse bundle /Volumes/TimeMachineHome: `sparseBundleMountPoint`
    * Path to sparse bundle file on PC. That is `smbMountPoint` + sparse bundle file name /Users/johndoe/mac_backup_folder/mac_TimeMachine.sparsebundle: `sparseBundlePath`
4. Save script into your Applications folder under name `PC-TimeMachine.app`. Choose `File format: Application` and select `Stay open after run handler`
5. Make script run invisibly without showing icon in Dock. 
    1. Find `PC-TimeMachine.app` in Finder, right click > Show package contents.
    2. In Contents folder, open `Info.plist` file in text editor and add key-value pair:<br/>
  ```
    <key>LSUIElement</key>
    <string>1</string>
  ```
7. Copy `AutoPCTimeMachine.plist` file to `/Users/johndoe/Library/LaunchAgents/` folder.
6. Start the script with `launchctl load -w /Users/johndoe/Library/LaunchAgents/AutoPCTimeMachine.plist`
    * Maual launch: `launchctl start AutoDellTimeMachine`
    * To stop script: `launchctl unload -w /Users/johndoe/Library/LaunchAgents/AutoDellTimeMachine.plist`

## Set up for Wake-on-lan (Windows 10)
1. In BIOS: Enable WOL in BIOS and Disable Deep Sleep (Check your manual)
2. In Windows 10: 
    * Under Power management, enable all WOL settings
    * Under Hardware > NIC settings: Turn off any "Energy efficient ethernet" and "Enable any settings for WOL"
    
