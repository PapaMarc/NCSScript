# NetCam Studio - System ARM/DisARM console
Working prototype Windows UI for a NetCam Studio Service 'System Console' which facilitates:
1) ARM/disARM of ALL cameras with one click (v. manually enabling motion on each cam individually in NCS Admin UI)
2) 'ARM with Delay' so that one can ARM a system and leave the house, without all cameras firing and recording video of one's departure

Depends on the NetCam Studio Service and its ability to entertain script commands.  
    cursory documentation here: https://netcamstudio.com/Api
    (eg. so per that, up-to-date relative to running service version info here: http://localhost:8124/?singlewsdl )
    forums here: https://community.netcamstudio.com/

Based on Powershell Core v7.0.3

Near the top of the ArmDisArmNCS.ps1 file are 3 variables for the AuthToken, UserName and Password:
$MyNCSun = 'ReplaceWithYourNCSUserName'
$MyNCSpwd = 'ReplaceWithYourNCSPassword'
$MyNCSAuthToken = 'ReplaceWithYourNCSAuthToken'
used to access the target NetCam Studio service with the account you established above/beyond the default NCS Admin acct.
Set these, along with <$DelayInSec>, to your personal/preferred values.


Installation:

    Place in the folder of your choice:
        ArmDisArmNCS.ps1             PowerShell script
#       ArmDisArmNCS                 Shortcut

        
    Modify the Shortcut to point to this folder.
    
    Copy the Shortcut to the desktop or where ever you like



To execute:

    Run the PowerShell script which should happen by clicking the shortcut.




FUTURE todos moving fwd... in no particular order:
    
    -Cleanup formatting.
    -pursue some degree elegance, as at present there's none ;-( eg. Get Array working to populate ComboBox v. manually filling it, and similar throughout... this is a learning PowerShell, VSCode, GitHub from VSCode exercise for me.
    -Make User ID and password handling more secure; require pwd to DisARM (currently rely on WinDesktop lockout/pwd to get back to console running on WinDesktop so anyone with access can hit the button and disarm)
    -work through issues, which i presently suspect are on the NetCamStudio side, wrt enabling/disabling a camera all together. eg. i don't want my laptop webcam always connected to the NCS server. I ONLY want to enable it, and then enable motion detection on it-- WHEN i want to ARM the system and depart. I DO NOT want that cam connected to the NetcamStudioSvc (and watching me at the computer) at ANY other time, nor do i want that service to 'hold onto' that camera which i may want to use with/for other apps like a Zoom call, etc. But when i leave my house, let alone my desk-- i want to know if/when anyone sits in front of the computer, so at that point on ARM'ing the system, i'd like to attach the camera to NCS, and include it as part of the ARM'ed system. More on that here:
    https://community.netcamstudio.com/t/cant-enable-disable-a-configured-cam-video-source-via-webapi/3895


            
            
            
            
 Other Notes:

