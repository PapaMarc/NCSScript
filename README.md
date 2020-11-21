# NetCam Studio - System ARM/DisARM (ADA_NCS, or ADA) console

ADA_NCS aims to be a functional, Windows UI, NetCam Studio Service 'System Console' which facilitates:

USABILITY
(presuming one can handle using a Powershell script, and configuring a few variables):
1) ARM/disARM of ALL cameras (the whole house system) with a single click v. manually serially enabling motion on each of n cams within a running instance of the Netcam Studio Client.
2) 'ARM (system) with Delay' so a residential/home user can ARM and exit, without all cameras firing and recording your departure along with all those family interactions while getting out the door together.  With any luck, you have NO videos recorded when you get back to review other than your entry, rather than several of people arguing about who put away who's shoes or jacket somewhere they can't find during stressful moments of running late. ;-)


PERFORMANCE:

3) The simplistic UI for ArmDisArmNCSv1 (ADA) itself neither renders video stream(s) nor requests video streams of the NCS Windows Service for rendering, which can result in some mouse delay (on modest personal systems hosting NCS) while right clicking on the video of each cam to 'enable motion' if/when one ARMs the cameras manually in the NCS Client. (Of course, once one has ARMed the system any system overhead imposed on the system as required by NCS, to have video ready/available such that it can be or is being persisted as part of 'motion recording' when triggered, will be a tax on the system used for hosting and associated with the NCS service process... but at that point, you're not trying to use the machine because you're out, and it's doing its thing as and 'by design').
4) While commercial utilizations of NCS may likely warrant dedicating a beefy PC for hosting NCS, as a home-user i choose to run it on my primary PC/laptop which i often leave on my desk. So-- i'd like the 1-click ARM/DisARM console to further facilitate starting the NCS Windows Service which i do NOT usually keep running in the background. Thus-- when 'ARM' is selected in the ADA_NCS application, and if/when the WinService is not running already... ADA will start the NCS WinService, then logon to NCS prior to ARM'ing... AND ADA will remember this and then in this case stop the service (if it needed to be started when ARMing), as part of DisARMing the system after it has disabled motion recording for each of the n cameras defined.  ie. it will truly reverse the start state it encountered, and respect a potential end-user desire to minimze ANY impact on Windows System hosting NCS, by not running the service AT ALL, when NOT ARMed in the home user case with a personal (non-dedicated) PC used as the NCS hosting machine.

ArmDisArmNCSv1.ps1 is that next-turn-of-the-crank, 'smart, performant, 1click' ARM(w/delay)/DisARM System console. 
ArmDisArmNCS.ps1 was it's predecessor prototype, which was simple proof of concept of NCS json extensibility, showing those basics 'moving on the screen'

ArmDisArmNCS (ADA_NCS) depends on, and is made possible by the extensibility offered in and by the NetCam Studio Service and its ability to entertain json script commands.  
    The NCS documentation can be found here: https://netcamstudio.com/Api
    Forums here: https://community.netcamstudio.com/

Iterated on with PowerShell v5.1 in Win10... and also seems functional with PowerShell Core v7.0.3 udpate

Near the top of the ArmDisArmNCS.ps1 file are 3 variables for the AuthToken, UserName and Password:

    1) $MyNCSun = 'ReplaceWithYourNCSUserName'
    2) $MyNCSpwd = 'ReplaceWithYourNCSPassword'
    3) $MyNCSAuthToken = 'ReplaceWithYourNCSAuthToken'

used to access the target NetCam Studio service with the personal NCS user account you established above/beyond the default NCS Admin acct.
Set these, along with $ExitDelayInSec, to your personal/preferred values.


Installation... a kin to my favorite sushi recipe... 'catch fish. serve.'  :-)
    Accordingly... 'Place in the folder of your choice. Run the script.'

        a) ArmDisArmNCSv1.ps1 (the PowerShell script)
        b) the 2 jpg's and
        c) the ARMdisARM_NCS shortcut


You may use the shortcut to run the PowerShell script; it demonstrates a working variation of the command line instruction to do so.
    (I use C:\Code\PowerShell\NCSScript as the folder which houses the files and the shortcut reflects that...
    update that path in the shortcut if your folder or folder path is different).
    For further tutorial on executing powershell scripts, start here: https:/go.microsoft.com/fwlink/?LinkID=135170

FUTURE todos...

    0) track arrival of the future NCS update (currently anticipated as v1.9.3) which should add/expose the ability to enable/disable cams via json, per:
    https://community.netcamstudio.com/t/cant-enable-disable-a-configured-cam-video-source-via-webapi/3895
    eg. in short, i'd like the ability for a few cams to not regularly by connected to the NCS server, in the event the WinService IS left running in the background. I prefer to ONLY enable a subset of cameras just prior to enabling motion detection as part of system ARMing-- WHEN i want to ARM the system and depart. And DO NOT want some cameras connected to the NetcamStudioSvc (and watching me at the computer) at ANY other time, nor do i want that service to 'hold onto' that camera which i may want to use with/for other apps like a Zoom call, etc. But when ARMing my system prior to leaving my house, or my desk-- i do want to know thereafter if/when anyone sits in front of the computer (wherein as an example, that Laptop front facing webcam is the subset for enable/disable). So when ARM'ing the system, i'd like to attach or 'enable' said camera to NCS, and then include it as part of the system ARM'ing (and simlarly reverse on DisARM). Scenario described in further detail in the linked post.

    1) consider improving User ID and password handling wrt security v. storing inline in the script, let alone in the clear. And, perhaps also address pwd or pin to ARM/DisARM (though, i'm currently relying on WinDesktop lockout/pwd/pin/WinHello, etc to safeguard the console running both ADA and the NCS WinService for that matter. At present i believe this dependency is suitable, and doesn't require further investment... despite the analygous physical alarm panel having this as part of the ARM/DisARM console itself)


This has been a long overdue exercise for me to get some hands on with PowerShell, VSCode IDE and debugger, GitHub, etc.

Other Notes:
 ...tbd...
