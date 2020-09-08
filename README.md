# NetCam Studio - System ARM/DisARM console
Working prototype Windows UI for a NetCam Studio Service 'System Console' which facilitates:
1) ARM/disARM of ALL cameras with 1 click v. manually enabling motion on each cam individually in NCS Admin UI
2) 'ARM with Delay' so you can ARM and exit, without all cameras firing and recording your departure

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
Set these, along with $ExitDelayInSec, to your personal/preferred values.


Installation... a kin to my favorite sushi recipe... 'catch fish. serve.'  :-)
    Place in the folder of your choice:
        ArmDisArmNCS.ps1             PowerShell script
    Run script.
For further tutorial on executing powershell scripts, start here: https:/go.microsoft.com/fwlink/?LinkID=135170 


FUTURE todos moving fwd... in no particular order:
    
    0) pursue some degree elegance, as at present there is precisely zero ;-(  This is a long overdue exercise for me learning PowerShell, VSCode and debugger, GitHub, etc.
    1) Use Array to populate ComboBox v. manually filling it, and similar learning curve throughout... 
    2) Better error handling, use of try/catch, etc
    3) Cleanup formatting and related conventions... it's a mess.
    4) Improve User ID and password handling wrt security; maybe add pwd to DisARM (currently relying on WinDesktop lockout/pwd to get back to console running on WinDesktop so anyone with access can hit the button and disarm. And look through code and see creds, etc.)
    5) work through issues, wrt enabling/disabling a camera all together.  Doesn't appear to be accessible in NCS via json.
    eg. i don't want my laptop webcam always connected to the NCS server. I ONLY want to enable it, and then enable motion detection on it-- WHEN i want to ARM the system and depart. I DO NOT want that cam connected to the NetcamStudioSvc (and watching me at the computer) at ANY other time, nor do i want that service to 'hold onto' that camera which i may want to use with/for other apps like a Zoom call, etc. But when i leave my house, let alone my desk-- i want to know if/when anyone sits in front of the computer. So when ARM'ing the system, i'd like to attach the camera to NCS, and then include it as part of the system ARM'ing. More on that here:
    https://community.netcamstudio.com/t/cant-enable-disable-a-configured-cam-video-source-via-webapi/3895


            
            
            
            
 Other Notes:

