
<#
script ARMing and DisARMing of the NetCamStudio security system
lots to learn. work in progress.
With any luck, this will give you a head start at a common end-user scenario. Enjoy. Marc
#>

#----------------------------------------------
#Import the GUI Assemblies
#----------------------------------------------

    
 #   Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase | Out-Null
    Add-Type -AssemblyName System.Drawing | Out-Null
    Add-Type -AssemblyName System.Windows.Forms | Out-Null

#[void][reflection.assembly]::Load('System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
#[System.WIndows.Forms.Application]::EnableVisualStyles()

#
#Define Variables, Arrays, URLs etc
#Define vars
#Definie NetCamStudio specific logon related vars
$MyNCSun = 'ReplaceWithYourNCSUserName'
$MyNCSpwd = 'ReplaceWithYourNCSPassword'
$MyNCSAuthToken = 'ReplaceWithYourNCSAuthToken'

#Define application specific vars
$ExitDelayInSec = 8
$Action = 'Command Me'

# Define Actions Array
#$Array_Actions = @('NCS Service Status','NCS Service Start','NCS Service Stop','NCS Logon','NCS Enumerate Cams','ARM NCS','ARM NCS with DELAY','DisARM NCS')

#Define URLS
#Logon URL
$URLLogon = "http://localhost:8124/Json/Login?username=$MyNCSun%38%password=$MyNCSpwd"

#Combo Cams URL
$URLGetCams = "http://localhost:8124/Json/GetCameras?authToken=$MyNCSAuthToken"

#Set CamN for 'enable motion detection' (which facilitates recording to occur on motion)
$URLCam0 = "http://localhost:8124/Json/StartStopMotionDetector?sourceId=0%38%enabled=true%38%authToken=$MyNCSAuthToken"
$URLCam1 = "http://localhost:8124/Json/StartStopMotionDetector?sourceId=1%38%enabled=true%38%authToken=$MyNCSAuthToken"
#$URLCam2 = "http://localhost:8124/Json/StartStopMotionDetector?sourceId=2&enabled=true&authToken=$MyNCSAuthToken"
#$URLCam3 = "http://localhost:8124/Json/StartStopMotionDetector?sourceId=3&enabled=true&authToken=$MyNCSAuthToken"

#disables motion detector on cameras causing motion triggered recording rules to no longer fire
$URLCam0 = "http://localhost:8124/Json/StartStopMotionDetector?sourceId=0%38%enabled=false%38%authToken=$MyNCSAuthToken"
$URLCam1 = "http://localhost:8124/Json/StartStopMotionDetector?sourceId=1%38%enabled=false%38%authToken=$MyNCSAuthToken"
#$URLCam2 = "http://localhost:8124/Json/StartStopMotionDetector?sourceId=2&enabled=false&authToken=$MyNCSAuthToken"
#$URLCam3 = "http://localhost:8124/Json/StartStopMotionDetector?sourceId=3&enabled=false&authToken=$MyNCSAuthToken"


# Function Definitions

#
# Set ComboBox selection to var and take action
function Return_Combo () {
  $Action = $ComboBox.Text
  $Label_ArmStatus.Text = $Action
  $Label_ArmStatus.ForeColor= "Black"
  $Label_ArmStatus.Refresh()
         If ( 0 -eq $ComboBox.SelectedIndex )
     {
       ServiceStatus
     }
      Elseif ( 1 -eq $ComboBox.SelectedIndex )
      {
        ServiceStart
      }
      Elseif ( 2 -eq $ComboBox.SelectedIndex )
      {
        ServiceStop
      }
      Elseif ( 3 -eq $ComboBox.SelectedIndex )
      {
        Logon
      }
      Elseif ( 4 -eq $ComboBox.SelectedIndex )
      {
        GetCams
      }
      Elseif ( 5 -eq $ComboBox.SelectedIndex )
      {
        ArmNCS
      }
      Elseif ( 6 -eq $ComboBox.SelectedIndex )
      {
        ExitDelayCountdown
      }Elseif ( 7 -eq $ComboBox.SelectedIndex )
      {
        DisArmNCS
      }
  }
#
# Service Status (ComboBox Index=0)
function ServiceStatus () {
  $Result = Get-Service -Name NetcamStudioSvc
  Write-Host "Service: "$Result.ServiceName
  Write-Host "DisplayName: "$Result.Name
  Write-Host "Status: "$Result.Status
  #Some error handling for attempts to start/stop service without ADMIN perms
  If ($null = $Error.Exception.InnerException) 
    {
    Write-Host "ErrorDetail: " $Error.Exception.InnerException -ForegroundColor Red
    $Label_ArmStatus.Text = 'No can do... see console'
    $Label_ArmStatus.ForeColor= "Red"
    $Label_ArmStatus.Refresh()
    }
  $Error.Clear()
  Write-Host "-----"
}

#
# Start Status (ComboBox Index=1)
function ServiceStart () {
  Start-Service NetcamStudioSvc
        ServiceStatus      
}

#
# Stop Status (ComboBox Index=2)
function ServiceStop () {
  Stop-Service NetcamStudioSvc | Write-Output
    ServiceStatus
}
#
#Logon NetCam Studio (NCS) (ComboBox Index=3)
Function Logon () {
  PowerShell Invoke-WebRequest -Uri $URLLogon -Method GET
}
#
#Get Cams  (ComboBox Index=4)
Function GetCams () {
  PowerShell Invoke-WebRequest -Uri $URLGetCams -Method GET
}

#

# Exit Delay Countdown Function (AND ARM) (ComboBox Index=6)
#Clear-Host
Function ExitDelayCountdown () {
  1..$ExitDelayInSec | ForEach-Object { 
    Start-Sleep -s 1
    $TMinus=$ExitDelayInSec-$_
    Write-Progress -activity "Arming System in: " -Status ($TMinus)
#   Write-Progress -Activity  -SecondsRemaining ($ExitDelayInSec) -PercentComplete ($ExitDelayInSec)
#   update the UI
    $Label_ArmStatus.Text = "Arming System in: $TMinus"
       $Label_ArmStatus.Refresh()
  }
#   Added exit delay... NOW do the real work / call the ARM function...
#   ArmNCS ()
}

#
# Arm NCS  (ComboBox Index=5)
# Arms NCS on departure from apartment

#Enable source: PC/tablet built-in screen webcam - enable/disable doesn't work
#$URLEnableCam3 = "http://localhost:8124/Json/ConnectCameraJson?sourceId=3&enabled=true&authToken="$MyNCSAuthToken""
#Invoke-WebRequest -Uri $URLEnableCam3

Function ArmNCS () {
Write-Host 'Arming System...'
#non-verbose
  Invoke-WebRequest -Uri $URLCam0
  Invoke-WebRequest -Uri $URLCam1
  #Invoke-WebRequest -Uri $URLCam2
  #Invoke-WebRequest -Urk $UrlCam3
Write-Host 'System ARMED!'
    $Label_ArmStatus.Text = 'System ARMED!'
    $Label_ArmStatus.Refresh()
}

#
# DisArm NCS  (ComboBox Index=7)
Function DisArmNCS () {
  Invoke-WebRequest -Uri $URLCam0
  Invoke-WebRequest -Uri $URLCam1
  #Invoke-WebRequest -Uri $URLCam2
  Write-Host 'System disarmed'
    $Label_ArmStatus.Text = 'System disarmed'
    $Label_ArmStatus.Refresh()
}


#___________
#
# Main
#
#___________

# Define and Draw Form
$Form_ArmDisArm = New-Object System.Windows.Forms.Form
  $Form_ArmDisArm.Text = "Arm / DisArm Console - NetCam Studio"
  $Form_ArmDisArm.Size = New-Object System.Drawing.Size(500,300)
  $Form_ArmDisArm.StartPosition = "CenterScreen"
  
$ComboBox = New-Object System.Windows.Forms.ComboBox
  $ComboBox.Location = New-Object System.Drawing.Point(10,40)
  $ComboBox.Size = New-Object System.Drawing.Size(280,20)
  $ComboBox.Height = 80
#  [void] $ComboBox.Items.AddRange($Array_Actions[0..7])
  [void] $ComboBox.Items.Add('NCS Service Status')
  [void] $ComboBox.Items.Add('NCS Service Start <ADMIN required>')
  [void] $ComboBox.Items.Add('NCS Service Stop <ADMIN required>')
  [void] $ComboBox.Items.Add('NCS Logon')
  [void] $ComboBox.Items.Add('NCS Enumerate Cams')
  [void] $ComboBox.Items.Add('ARM NCS')
  [void] $ComboBox.Items.Add('ARM NCS with DELAY')
  [void] $ComboBox.Items.Add('DisARM NCS')

$Label_ArmStatus = New-Object System.Windows.Forms.Label
  $Label_ArmStatus.Text = 'Awaiting your command'
  $Label_ArmStatus.Location = New-Object System.Drawing.Size(75,200)
  $Label_ArmStatus.Size = New-Object System.Drawing.Size(400,30)
#  $Label_ArmStatus.AutoSize = $true
  $Label_ArmStatus.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 16, [System.Drawing.FontStyle]::Bold)

$Button = new-object System.Windows.Forms.Button
  $Button.Size = new-object System.Drawing.Size(100,40)
  $Button.Location = new-object System.Drawing.Size(130,100)
  $Button.Text = "Execute"
 


  $Form_ArmDisArm.Controls.Add($Label_ArmStatus)
  $Form_ArmDisArm.Controls.Add($ComboBox)
  $Form_ArmDisArm.Controls.Add($Button)
  $Button.Add_Click({Return_Combo})
  $Form_ArmDisArm.ShowDialog()









       