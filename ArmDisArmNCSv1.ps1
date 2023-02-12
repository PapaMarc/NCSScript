# Copyright (c) Marc Seinfeld.
# Licensed under the MIT License.

<#
script for  ARMing and DisARMing of the NetCamStudio security system
work in progress.
With any luck, this will give you a head start at a common end-user, home security system scenario.

Enjoy. Marc
#>

<#
Forked from ArmDisArmNCS.ps1... which was an initial test harness / prototype for enumerating functionality,
this v1 attempts to make a simplistic, 1-click Arm with Delay / DisArm console
which auto-starts/stops the service and auto-enables/disables a subset of the cams
as part of the Arm/DisArm. 
v1 is an attempt to aide in automating the primary home user scenario from a 'whole system' perspective.
The underpinnings to get there:
-refactor the primary arm/disarm relative to the v0 to streamline those and other functions (several new app internal helper functions),
-add some relevant error handling for improved reliability in implemented cases
NOTE/Disclaimer: there are many cases which ARE NOT handled.
  This NCS complementary script uses NO event sinks to maintain an understanding of ongoing camera state,
  nor does it constantly interogate the core NCS system to attempt to approximate this understanding.
  Any notion of a 'camera group' is limited to this application, and it exists as a non-validated config.
  Similarly any notion of an 'armed state' is germaine to this application, and there is no common understanding with NCS itself.
  At best it is tracked within the running instance of this script and
  no persisted attempt to maintain this state exists across instances or sessions.
As such:
-camera state may be changed in parallel by alternate NCS clients; this may result in inconsistencies within ArmDisArmNCS which does not syncrhonize such changes.  
-minimal notion of session state exists within ArmDisArmNCS, no multiple instance handling has been considered or tested.
-closing/restarting ArmDisArmNCS will not properly indicate an ARMED state.
-no effort is made to verify hardware is available as defined, online and otherwise accessible as configured, so when not all bets are off...
-Arming/DisArming, enabling/disabling subset of cams also relies on proper configuration of the 2 relevant arrays below.
-etc
#>

#----------------------------------------------
#Import Assemblies
#----------------------------------------------
#for GUI    
Add-Type -AssemblyName System.Drawing | Out-Null
Add-Type -AssemblyName System.Windows.Forms | Out-Null
Add-Type -AssemblyName System.Speech
# Load / Prep Speech assembly
# Note: if you're attempting to execute this in PowerShell6 or PowerShell7 you won't hear anything
# This .dll is from .Net, whereas PS6 and 7 are .Net CORE and that API is not presently ported.
# More here re: PS6 https://github.com/PowerShell/PowerShell/issues/8809
# And the ongoing discussion here re: PS7 https://github.com/dotnet/wpf/issues/2935
$Speech = New-Object System.Speech.Synthesis.SpeechSynthesizer

# Variable and Array definitions
# Define vars

#----------------------------------------------
#______Please be sure to configure these <below> properly for your NCS system______
#----------------------------------------------

# Define NetCamStudio specific logon related vars
# uncomment 1 of the following 2.
#$NCS = 'NetcamStudioSvc'   # this is the 32bit NCS Service
$NCS = 'NetcamStudioSvc64'  # while this reflects the 64bit installation
# uncomment for default NCS Library location
#$RecLibPath = "C:\ProgramData\Moonware\Netcam Studio\Server\Library\Recordings"
# or clarify custom Library location here
$RecLibPath = "D:\NCS\Library\Recordings"

$MyNCSun = 'ReplaceWithYourNCSUserName'
$MyNCSpwd = 'ReplaceWithYourNCSPassword'
$MyNCSAuthToken = 'ReplaceWithYourNCSAuthToken'

# Define ArmDisArmNCS application specific vars
$ExitDelayInSec = 18
$Announce = "true"   #true will facilitate 5sec audible countdown & system ARMed/DisARMed announce.  "false" will silence the voice narration

# Array definitions
# cams that will be enabled prior to Arming, and disconnected on DisArm
$array_disAbleCams = @(1, 3)  #1=livingRm  #3=Laptop
# cams to be Armed/DisArmed as part of the whole system
$array_awayCams = @(0, 1, 2, 3)  #0=Entry  #2=Garage
# by default, prior array is for arming while AWAY. The array which follows will overide when @Home is selected in GUI dropdown
$array_atHome = @(0, 2)
# in the event you don't use the dropdown set an initial default
$array_motionCams = $array_awayCams
# though thereafter the button will heed dropdown 'default' if you set away...
#----------------------------------------------
#______Please be sure to configure these <above> properly for your NCS system______
#----------------------------------------------


# used to populate ComboBox. Enumerated the initial Windows Service status/start/stop manually
$Array_NCSActions = @('NCS Logon', 'NCS Enumerate Cams', 'NCS Process Info', 'NCS Service Status', 'NCS Full Report', 'ARM NCS', 'ARM NCS with DELAY', 'ARM NCS@Home', 'Announce Video Tally', 'DisARM NCS')

# Function Definitions
function UpdateLable () {
  $Action = $ComboBox.Text
  #$Script:text = "Command: " + $Action
  #CenterLabel $text
  $Label_ArmStatus.Text = "Command: " + $Action
  $Label_ArmStatus.ForeColor = "Black"
  #$Label_ArmStatus.Refresh()
}

# Set ComboBox selection to var and take action
function Return_Combo () {
  UpdateLable
  If ( 0 -eq $ComboBox.SelectedIndex ) {
    WinServiceStatus 1 #with some verbose output
  }
  Elseif ( 1 -eq $ComboBox.SelectedIndex ) {
    WinServiceStart
    #    WinServiceStatus 0
  }
  Elseif ( 2 -eq $ComboBox.SelectedIndex ) {
    WinServiceStop
    WinServiceStatus 0
  }
  Elseif ( 3 -eq $ComboBox.SelectedIndex ) {
    Logon
  }
  Elseif ( 4 -eq $ComboBox.SelectedIndex ) {
    GetCams
  }
  Elseif ( 5 -eq $ComboBox.SelectedIndex ) {
    ProcessInfo
  }
  Elseif ( 6 -eq $ComboBox.SelectedIndex ) {
    ServiceStatus
  }
  Elseif ( 7 -eq $ComboBox.SelectedIndex ) {
    FullReport
  }
  Elseif ( 8 -eq $ComboBox.SelectedIndex ) {
    $script:array_motionCams = $array_awayCams
    $Button1.Text = "ARM system   <AWAY no delay>"
    ArmNCS
  }
  Elseif ( 9 -eq $ComboBox.SelectedIndex ) {
    $Button1.Text = "ARM system   <AWAY with delay>"
    ExitDelayCountdown
  }
  Elseif ( 10 -eq $ComboBox.SelectedIndex ) {
    # a modified quick start of select cams for recording while at home
    $ExitDelayInSec = 10
    $Script:array_motionCams = $array_atHome
    $Button1.Text = "ARM system <@Home>"
    ExitDelayCountdown
  }
  Elseif ( 11 -eq $ComboBox.SelectedIndex ) {
    VidCheckCount
  }
  Elseif ( 12 -eq $ComboBox.SelectedIndex ) {
    DisArmNCS
  }
}
#
# Service Status (ComboBox Index=0)
function isAdmin {
  # Returns true/false
  $script:isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

function Return_Checkbox0 () {
  If ($Checkbox0.Checked -eq $true)
  { Write-Host "checkbox checked" }
  elseif ($checkbox0.Checked -eq $false)
  { Write-Host "checkbox UNchecked" }
}
function WinServiceStatus ([Int]$report) {
  $script:Result = Get-Service -Name $NCS
  If ( 1 -eq $report ) {
    Write-Host "Service: "$Result.ServiceName
    Write-Host "DisplayName: "$Result.NamePending
    Write-Host "Status: "$Result.Status
    Write-Host "---"
  }
  # and to WinForm
  if ("Running" -eq $Result.Status) {
    $Label_ArmStatus.ForeColor = "Green"
    if ($null -eq $NCSver) {
      GetVer
    }
  }
  elseif ("Stopped" -eq $Result.Status) {
    $Label_ArmStatus.ForeColor = "Tomato"   #Red works in PSv5.1 In PSv7++ need better...
  }
  $Label_ArmStatus.Text = "WinService Status: " + $Result.Status   # ...Stopped, StartPending, or Running...
}

#
# Start Status (ComboBox Index=1)
function WinServiceStart () {
  isAdmin
  If ("true" -eq $isAdmin) {
    Start-Service $NCS | Write-Output
  }
  else {
    Start-Process powershell.exe "-Command", ("Start-Service " + $NCS) -Verb runAs
  }  
  # No current error handling wrt WaitForStatus so may unintentionally run indefinitely if all doesn't go as planned... investigate some error handling, proper callbacks, etc
  WinServiceStatus 0
  $Result = Get-Service -Name $NCS
  $Result.WaitForStatus("StartPending")
  WinServiceStatus 1
  $Result = Get-Service -Name $NCS
  $Result.WaitForStatus("Running")
  WinServiceStatus 1  
}

#
# Stop Status (ComboBox Index=2)
function WinServiceStop () {
  isAdmin
  If ("true" -eq $isAdmin) {
    Stop-Service $NCS | Write-Output
  }
  else {
    Start-Process powershell.exe "-Command", ("Stop-Service " + $NCS) -Verb runAs
  }
  WinServiceStatus 0
  $Result = Get-Service -Name $NCS
  $Result.WaitForStatus("Stopped")
  WinServiceStatus 1
  $script:ADANCSstate = "NOTReadyToARM"
  DisplayImage
}

#
#Logon NetCam Studio (NCS) (ComboBox Index=3 , Array Index = 0)
function Logon () {
  if ("ARMED" -ne $ADANCSstate) {
    $URLLogon = "http://localhost:8124/Json/Login?username=" + $MyNCSun + "&" + "password=" + "$MyNCSpwd"
    $Error.Clear()
    Invoke-WebRequest -Uri $URLLogon -Method GET -OutVariable output #| out-null not working to hide console output of Invoke-WebRequest -known issue, and partial fix for PSv7.1 and higher (for progress bar), though not in this case in my emperical usage... https://github.com/PowerShell/PowerShell/issues/1625 
    #$Error | ../bin/Show-object.ps1
    # with service stopped... this will error out.
    if (("2" -eq $Error.Exception.Status.value__) -or ("10061" -eq $Error.Exception.InnerException.ErrorCode)) {
      # 2 works for PSv5.1... PSv7+ use10061... go figure
      Write-Host "Logon attempt:" $Error.Exception.Status
      Write-Host "Logon attempt:" $Error.Exception.InnerException.Message
      # could call for service start here...
      WinServiceStatus 1
    }
    #Write-Host "STDOUT"
    #Write-Host $output
    #$msg = $output[0] | ../bin/Show-object.ps1

    # with service running... 
    else {
      $script:msg = $output[0].AllElements[3].outerText | ConvertFrom-String
    }
    #Write-Host $msg
    #$stuff = $msg | ConvertFrom-String
    #$stuff | ../bin/Show-object.ps1

    # success looks like this
    if ("true," -eq $msg.P3) {
      Write-Host $msg.P2 $msg.P3
      Write-Host $msg.P6 $msg.P7
      Write-Host "_____"
      Write-Host "NCS System: READY TO ARM!"
      Write-Host "_____"
      $Label_ArmStatus.ForeColor = "Green"
      #$Label_ArmStatus.Refresh()
      $Label_ArmStatus.Text = "NCS System: READY TO ARM!"
      $script:ADANCSstate = "ReadyToARM"   # logged on
      DisplayImage
    }
    # failure like this
    elseif ("false," -eq $msg.p3) {
      Write-Host $msg.P2 $msg.P3
      Write-Host $msg.P4 $msg.P5 $msg.P6 $msg.P7 $msg.P8
      Write-Host "NCS Logon failed"
      WinServiceStatus 1
      $Label_ArmStatus.ForeColor = "Tomato"
      $Label_ArmStatus.Text = "NCS Logon failed"
    }
    $Error.Clear()
  }
  Elseif (("ARMED" -eq $ADANCSstate) -and ($Label_ArmStatus.Text -ne 'System ARMED!')) {
    $Label_ArmStatus.Text = 'System ARMED!'
    $Label_ArmStatus.ForeColor = "Tomato"
    if ("true" -eq $Announce) {
      $Speech.Speak("System, already ARMED. Bro!")
    }
  }
}

#
#Get Cams  (ComboBox Index=4)
function GetCams () {
  $URLGetCams = "http://localhost:8124/Json/GetCameras?authToken=" + "$MyNCSAuthToken"
  Invoke-WebRequest -Uri $URLGetCams -Method GET | Write-Host
  $Error.Clear()
  Write-Host "_____"
}
#
#Get ProcessInfo  (ComboBox Index=5)
function ProcessInfo () {
  $URLProcessInfo = "http://localhost:8124/Json/GetProcessInfo?authToken=" + "$MyNCSAuthToken"
  Invoke-WebRequest -Uri $URLProcessInfo -Method GET | Write-Host
  $Error.Clear()
  Write-Host "_____"
}
#
#
function GetVer () {
  # $NCSver= (Get-ItemProperty -Path "HKLM:\SOFTWARE\Moonware\Netcam Studio").Version   #this gets NCS version from registry... for future potential use 
  $URLProcessInfo = "http://localhost:8124/Json/GetProcessInfo?authToken=" + "$MyNCSAuthToken"
  Invoke-WebRequest -Uri $URLProcessInfo -Method GET -OutVariable output >$null
  #$output | ../bin/Show-object.ps1
  $Pinf = $output.AllElements[0].outerText | ConvertFrom-String
  $Error.Clear()
  $script:NCSver = "{0}.{1}.{2}.{3}" -f "NCS v", $Pinf.P32, $Pinf.P34, $Pinf.P36
  Write-Host $NCSver
  Write-Host "_____"
  [INT]$script:NCSverInt = "{0}{1}{2}" -f $Pinf.P32, $Pinf.P34, $Pinf.P36
  $Error.Clear()
}
#
#Get ServiceStatus  (ComboBox Index=6)
function ServiceStatus () {
  $URLServiceStatus = "http://localhost:8124/Json/GetServiceStatus?authToken=" + "$MyNCSAuthToken"
  Invoke-WebRequest -Uri $URLServiceStatus -Method GET | Write-Host
  $Error.Clear()
  Write-Host "_____"
}
#
#Get FullReport  (ComboBox Index=7)
function FullReport () {
  $URLFullReport = "http://localhost:8124/Json/GetGlobalStatus?authToken=" + "$MyNCSAuthToken"
  Invoke-WebRequest -Uri $URLFullReport -Method GET | Write-Host
  $Error.Clear()
  Write-Host "_____"
}
# Exit Delay Countdown Function (AND ARM) (ComboBox Index=9)
function ExitDelayCountdown () {
  Logon
  $Button1.Text = "ARM system   <AWAY with delay>"
  if (10 -eq $ComboBox.SelectedIndex ) {
    $ExitDelayInSec = 10
    $Button1.Text = "ARM system <@Home>"
  }
  if (8 -eq $ComboBox.SelectedIndex ) {
    $Button1.Text = "ARM system   <AWAY no delay>"
    ArmNCS
  }
  if ("false," -ne $msg.p3) {
    if (("ARMED" -ne $ADANCSstate) -and (1 -le $ExitDelayInSec)) {
      1..$ExitDelayInSec | ForEach-Object { 
        Start-Sleep -s 1
        $TMinus = $ExitDelayInSec - $_
        if (0 -ne $TMinus) {
          Write-Progress -Activity "Arming System in: " -Status ($TMinus)
          #   Write-Progress -Activity  -SecondsRemaining ($ExitDelayInSec) -PercentComplete ($ExitDelayInSec)
          #   update the UI
          if (8 -eq $TMinus) {
            if ("true" -eq $Announce) {
              $Speech.SpeakAsync("Arming in")
            }
          }
          $Label_ArmStatus.ForeColor = "Tomato"
          if (6 -gt $TMinus) {
            if ("true" -eq $Announce) {
              $Speech.SpeakAsync("$TMinus")
            }
          }
          $Label_ArmStatus.Text = "Arming System in: $TMinus"
          $Label_ArmStatus.Refresh()
        }
        #   Added exit delay... NOW do the real work / call the ARM function...
      }
    }
    ArmNCS
  }
  if ("false," -eq $msg.p3) {
    Write-Host "Arm System failed"
    Write-Host "_____"
  }
}

function ArmNCS () {
  if ("ARMED" -ne $ADANCSstate) {
    RecordingNotification start
  }
  Logon   # no logoff at present via json, so reversal in AutoDisArm not accomodated for
  if ("false," -eq $msg.p3) {
    Write-Host "Arm System failed"
    Write-Host "_____"
  }
  elseif ("ARMED" -ne $ADANCSstate) {
    Write-Host 'Arming System...'
    EnableCam true
    $motion = "true"
    foreach ($camX in $array_motionCams) {
      $URLMoCamx = "http://localhost:8124/Json/StartStopMotionDetector?sourceId=" + $camX + "&" + "enabled=" + $motion + "&" + "authToken=" + "$MyNCSAuthToken"
      #Write-Host "$URLMoCamx" # useful for testing to output to console; can comment out following invoke-webrequest to minimize churn on the service
      Invoke-WebRequest -Uri $URLMoCamx
    }
    if ("false," -ne $msg.p3) { 
      Write-Host 'System ARMED!'
      Write-Host "_*_*_*_*_"
      $script:ADANCSstate = "ARMED"
      DisplayImage

      $Label_ArmStatus.Text = 'System ARMED!'
      $Label_ArmStatus.ForeColor = "Tomato"
      if ("true" -eq $Announce) {
        $Speech.Speak("System, ARMED!")
      }
    }
  }
}

#
# DisArm NCS  (ComboBox Index=10)
function DisArmNCS () {
  $motion = "false"
  foreach ($camX in $array_motionCams) {
    $URLMoCamx = "http://localhost:8124/Json/StartStopMotionDetector?sourceId=" + $camX + "&" + "enabled=" + $motion + "&" + "authToken=" + "$MyNCSAuthToken"
    #Write-Host $URLMoCamx  
    Invoke-WebRequest -Uri $URLMoCamx
  }
  Write-Host 'System disarmed'
  Write-Host "_*_*_*_*_"
  $Label_ArmStatus.Text = 'System disarmed'
  $Label_ArmStatus.ForeColor = "Green"
  $script:ADANCSstate = "ReadyToARM"
  DisplayImage
  if ("true" -eq $Announce) {
    $Speech.Speak("System, DisARMed")
    RecordingNotification stop
  }
  If ("true" -eq $ReverseEnablementLater) {
    EnableCam false
    WinServiceStatus
  }
}

# Per https://community.netcamstudio.com/t/cant-enable-disable-a-configured-cam-video-source-via-webapi/3895
# The following is intended to attach aka 'enable' NCS configured cams (ie. ready for motion recording enabling, stream viewable in NCS admin console)
# it will need to be verified and presumably tweaked somewhat upon release of this new enable/disable function
# This was initially developed against 1.9.2 and in Jan'22 on updating to 1.9.5 it still does not seem to be supported 
# I'll continue to monitor for the new export and update the code accordingly wrt version and URL syntax, and until i see it supported i'll keep the version check which follows bumped beyond the current version in which it is not supported
function EnableCam ($offOn) {
  # 'true' param passed in will enable cam(s), 'false' will disable/detach configured cam(s) from the NCS service
  if ($NCSverInt -ge "196") {
    # this function to be supported by NCS v1.9.6 or higher thus checked for above; prior versions do not support enablement/disablment of cams via json
    foreach ($camX in $array_disAbleCams) {
      $URLAblementCamx = "http://localhost:8124/EnableCameraJson?sourceId=" + $camX + "&" + "enabled=" + $offOn + "&" + "authToken=" + "$MyNCSAuthToken"
      $script:ReverseEnablementLater = $offOn
      Write-Host $URLAblementCamx
      #        Invoke-WebRequest -Uri $URLAblementCamx
    }
  }
}

function DisplayImage () {
  switch ($ADANCSstate) {
    "ARMED" { $image = "ARMed_red.jpg" }
    "ReadyToARM" { $image = "READYtoArm_green.jpg" }
  }
  if ("NOTReadyToARM" -eq $ADANCSstate) {
    $Form_ArmDisArm.controls.remove($pictureBox)
  }
  else {
    $Form_ArmDisArm.controls.add($pictureBox)
    $img = [System.Drawing.Image]::Fromfile((Split-Path -Parent $PSCommandPath) + "\" + $image)
    $pictureBox.top = 30
    $pictureBox.left = 155
    $pictureBox.Width = 120
    $pictureBox.Height = 120
    #$pictureBox.Width = $img.Size.Width
    #$pictureBox.Height = $img.Size.Height
    $pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    $pictureBox.Image = $img
    $pictureBox.Refresh()
  }
}

<#
the following function is fraught with potential issues
it is minimally tested and PRONE to error... due to cursory, inexhaustive handling of path, date/time at present wrt complexities across days, etc...
and exceedingly limited investment in testing of, and error handling.
It's working for me as a quick/dirty heads up at the moment
feel free to disable the two calls to it currently living in the ArmNCS and DisARMNCS functions on/around line 339 & 386 respectively
by commenting those 2 lines if you're hitting cases i didn't explore, and it is problematic for you
#>
function RecordingNotification ($startStop) {
  switch ($startStop) {
    "start" { $script:startDT = Get-Date } # set $startDT (and $stopDT) at the time the system is armed and disarmed respectively
    "stop" { $script:stopDT = Get-Date }
  }

  if ("stop" -eq $startStop) {
    $DateStr = (Get-Date).ToString("yyyyMMdd")
    $exist = Test-Path -Path "$RecLibPath\$DateStr"
    if ("True" -eq $exist) {
      $Speech.Speak("a recordings folder was created today")
      $files = Get-ChildItem -Path "$RecLibPath\$DateStr" -File
      foreach ($DT in $files.LastWriteTime) {
        if (($startDT -le $DT) -and ($stopDT -ge $DT)) {
          # and see if files in there were created between the start/stop times of the most recently armed session
          $count = $count + 1   #and count those new recordings
        }
      } 
      $Speech.Speak("containing $count new motion captures while armed")
      Write-Host "$count recording(s) made while ARMed!"
      Start-Process "$RecLibPath\$DateStr"
    }
  }
}

function VidCheckCount () {
  # apologies for the ugly dupe; at some point perhaps i'll cleanup for proper reuse w/above
  $DateStr = (Get-Date).ToString("yyyyMMdd")
  $exist = Test-Path -Path "$RecLibPath\$DateStr"
  if ("True" -eq $exist) {
    $Speech.Speak("Today's recording folder")
    $files = Get-ChildItem -Path "$RecLibPath\$DateStr" -File
    foreach ($DT in $files.LastWriteTime) {
      $count = $count + 1   # Give raw/total all up count in the day's folder v. disarm which gives count within current ARM session
    }
    if ($null -eq $count) {
      $count = "0"
    }
    $Speech.Speak("contains $count motion captures")
    if ("0" -eq $count) {
      $Speech.Speak("Day ain't over yet")
    }
  } 
  if ("False" -eq $exist) {
    $Speech.Speak("nothing to see here, boss")
  } 
}


function Allin1_AutoArm () {
  # StartServiceAsApprop, then logon if needed, enableCamsAsApprop, then StartMotionRecording
  if ("ARMED" -ne $ADANCSstate) {
    WinServiceStatus
    if ("Running" -eq $Result.Status) {
      $script:ADAStopNCSOnAutoDis = "false"
    }
    elseif ("Stopped" -eq $Result.Status) {
      $script:ADAStopNCSOnAutoDis = "true" # for later reversal to leave as it was found in AutoDisArm
      WinServiceStart
    }
    Logon   # no logoff at present via json, so reversal in AutoDisArm not accomodated for
    if ("false," -eq $msg.p3) {
      Write-Host "Auto-ArmSystem failed"
      Write-Host "_____"
      #      break
    }
    elseif ("ARMED" -eq $ADANCSstate) {
      Write-Host "System is already ARMED"
      Write-Host "_____"
    }
    else {
      ExitDelayCountdown
    }
  }
}

function Reverse_AutoDisArm () {
  if ("ARMED" -ne $ADANCSstate) {
    Write-Host "The system IS NOT ARMed"
    Write-Host "_____"
  }
  elseif ("ARMED" -eq $ADANCSstate) {
    #StopMotionRecording, then disableAsApprop if/when can, then logoff if/when can, thenStopServiceAsApprop
    DisArmNCS
    $script:ADANCSstate = "ReadyToARM"
    DisplayImage
    if ("true" -eq $ADAStopNCSOnAutoDis) {
      WinServiceStop
      $script:ADANCSstate = "NOTReadyToARM"
      DisplayImage
    }
  }
}

#___________
#
# Main
#
#___________

# Define and Draw Form
$Form_ArmDisArm = New-Object System.Windows.Forms.Form
$Form_ArmDisArm.Text = "Arm / DisArm Console - NetCam Studio"
$Form_ArmDisArm.Size = New-Object System.Drawing.Size(450, 300)
$Form_ArmDisArm.StartPosition = "CenterScreen"
  
$ComboBox = New-Object System.Windows.Forms.ComboBox
$ComboBox.DropDownStyle = 'DropDownList'
$ComboBox.Location = New-Object System.Drawing.Point(30, 220)
$ComboBox.Size = New-Object System.Drawing.Size(280, 20)
$ComboBox.Height = 80
#  populate initial 3 Windows Service related entries manually
[void] $ComboBox.Items.Add('NCS WinService Status')
[void] $ComboBox.Items.Add('NCS WinService Start')
[void] $ComboBox.Items.Add('NCS WinService Stop')
#  populate the remaining NCS specific entries, ComboBoxIndex3-10, looping through an Array...
foreach ($ArrayAction in $Array_NCSActions) {
  [void] $ComboBox.Items.Add($ArrayAction)
}

$Label_ArmStatus = New-Object System.Windows.Forms.Label
# dynamically set initial $Label_ArmStatus.Text & color... based on NCS Service state
WinServiceStatus 1
if ("Running" -eq $Label_ArmStatus.Text) {
  GetVer
}

$Label_ArmStatus.Location = New-Object System.Drawing.Size(30, 180)
$Label_ArmStatus.Size = New-Object System.Drawing.Size(400, 30)
#  $Label_ArmStatus.AutoSize = $true
$Label_ArmStatus.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 16, [System.Drawing.FontStyle]::Bold)

$Button0 = New-Object System.Windows.Forms.Button
$Button0.Size = New-Object System.Drawing.Size(120, 120)
$Button0.Location = New-Object System.Drawing.Size(280, 30)
$Button0.Text = "DisArm system"

$Button1 = New-Object System.Windows.Forms.Button
$Button1.Size = New-Object System.Drawing.Size(120, 120)
$Button1.Location = New-Object System.Drawing.Size(30, 30)
$Button1.Text = "ARM system   <AWAY with delay>"

$Checkbox0 = New-Object System.Windows.Forms.Checkbox
$Checkbox0.Size = New-Object System.Drawing.Size(10, 10)
$Checkbox0.Location = New-Object System.Drawing.Size(30, 155)
#$Checkbox0.Text = "DISARM Sunset to Sunrise"
$Label_cb0 = New-Object System.Windows.Forms.Label
$Label_cb0.Location = New-Object System.Drawing.Size(45, 155)
$Label_cb0.Size = New-Object System.Drawing.Size(300, 30)
$Label_cb0.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 7, [System.Drawing.FontStyle]::Regular)
$Label_cb0.Text = "DISARM Sunset to Sunrise"


$pictureBox = New-Object Windows.Forms.PictureBox

# Draw actual form... 
$Form_ArmDisArm.Controls.Add($Label_ArmStatus)
$Form_ArmDisArm.Controls.Add($ComboBox)
$Form_ArmDisArm.Controls.Add($Button0)
$Form_ArmDisArm.Controls.Add($Button1)
$Form_ArmDisArm.Controls.Add($Checkbox0)
$Form_ArmDisArm.Controls.Add($Label_cb0)
$Form_ArmDisArm.controls.add($pictureBox)
$Button0.Add_Click( { Reverse_AutoDisArm })
$Button1.Add_Click( { Allin1_AutoArm })
$ComboBox.Add_SelectedIndexChanged( { Return_Combo })
$Checkbox0.Add_CheckStateChanged( { Return_Checkbox0 })

$Form_ArmDisArm.ShowDialog()