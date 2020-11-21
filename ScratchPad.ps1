# ScratchPad
# to hold things to test in a PowerShell window to figure out how to access NCS via WCF
# https://www.netcamstudio.com/WebAPI/#Moonware.Server.WCF~Moonware.Server.WCF.MoonwareServerWCF_methods.html
# need to determine how to consume the SOAP WebService from PowerShell

$MyNCSun = 'P@paM@rc'
$MyNCSpwd = '$3c.M3HOmee!'
$MyNCSAuthToken = '0c3c52c2-f8a6-4583-91c4-9846d2200472'



$URI_WCF = "http://localhost:8124/?singleWsdl"
$srv_WCF = New-WebServiceProxy -URI $URI_WCF #  -UseDefaultCredential 'false'
#or??
$URI_WCF0 = "http://localhost:8124/?wsdl"
$srv_WCF0 = New-WebServiceProxy -URI $URI_WCF #  -UseDefaultCredential 'false'

$srv_WCF1 = New-WebServiceProxy -URI $URI_WCF -username $MyNCSun -password $MyNCSpwd

$srv_WCF
$srv_WCF | Get-Member
..\bin\show-object $srv_WCF
# and THIS starts to show what's going on under the covers!!!
..\bin\show-object $srv_WCF.login 
#and it shows 3 string params... username, password device Token (NOT authToken so look at GetToken next)
..\bin\show-object $srv_WCF.GetToken  #seems to yield the same...

#doesn't yield anything useful...
#$srv_WCF.GetServiceStatus

#seems to generate an exception, and then reissuing generates 401: Unauthorized... so maybe progress
$srv_WCF.Login('$MyNCSun','$MyNCSpwd','$MyNCSAuthToken')
#along with many others doesn't seem to do the trick...
$srv_WCF.Login -username '$MyNCSun' -password '$MyNCSpwd' -deviceToken '$MyNCSAuthToken' -LoginResult '$LoginResult'
$srv_WCF::Login $MyNCSun, $MyNCSpwd, $MyNCSAuthToken
#Get-Member also suggests something like this might work... though no luck
$srv_WCF.GetToken('$MyNCSun','$MyNCSpwd','$MyNCSAuthToken','$LoginResult')

$srv_WCF.login | get-member
$srv_WCF | select-object login # or any other property, or method, etc
$srv_WCF | get-member -memberType Method

#This yields 401 UnAuthorized... so i'm on to something?
$LoginResult = $srv_WCF.Login($MyNCSun,$MyNCSpwd,$MyNCSAuthToken)

Invoke-RestMethod -Method Get -URI $srv_WCF.Login($MyNCSun,$MyNCSpwd,$MyNCSAuthToken)

#getting closer:
Invoke-RestMethod -Method Get -URI $srv_WCF::GetSystemStatus()
# or
Invoke-RestMethod -Method Get -URI $srv_WCF0::GetProcessInfo()


#Invoke-WebRequest -Uri http://localhost:8124/Json/DisConnectCamera?SourceID=3"&"ConnectionStatus=2"&"authToken=0c3c52c2-f8a6-4583-91c4-9846d2200472 -Method Get | Write-Host
#returns "???true" if camera connected;
# BUT it really diconnects camera 3 and overwrites config for cam02
#and with connectionstatus=4 returns false if camera connected
#Meh... this just causes cam03 (and cam02) to be corrupted/deleted from the config it seems