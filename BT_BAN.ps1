$ZIPURL = 'https://bt-ban.pages.dev/IPLIST.zip'
$IRMURL = 'https://bt-ban.pages.dev/BT_BAN.ps1'

$BTPATH = $args[0]
$BTNAME = [System.IO.Path]::GetFileName($BTPATH)
$DYKWID = '{3817fa89-3f21-49ca-a4a4-80541ddf7465}'

Invoke-WebRequest -OutFile "$env:temp\BT_BAN_IPLIST.zip" $ZIPURL -TimeoutSec 30
Expand-Archive -Force -Path $env:temp\BT_BAN_IPLIST.zip -DestinationPath $env:temp\BT_BAN
$IPLIST = Get-Content $env:temp\BT_BAN\IPLIST.txt

$RULES = Get-NetFirewallRule -DisplayName "BT_BAN_$BTNAME" -ErrorAction Ignore

$SET_RULES = {
	Remove-NetFirewallRule -DisplayName "BT_BAN_$BTNAME" -ErrorAction Ignore
	New-NetFirewallRule -DisplayName "BT_BAN_$BTNAME" -Direction Inbound -Action Block -Program $BTPATH -RemoteDynamicKeywordAddresses $DYKWID | Out-Null
	New-NetFirewallRule -DisplayName "BT_BAN_$BTNAME" -Direction Outbound -Action Block -Program $BTPATH -RemoteDynamicKeywordAddresses $DYKWID | Out-Null
}

if (($RULES | Out-String -Stream | Select-String -SimpleMatch $DYKWID).Count -ne 2) {
	&$SET_RULES
} elseif (($RULES | Get-NetFirewallApplicationFilter | Out-String -Stream | Select-String -SimpleMatch $BTPATH).Count -ne 2) {
	&$SET_RULES
} elseif (($RULES | Out-String -Stream | Select-String -SimpleMatch Inbound).Count -ne 1) {
	&$SET_RULES
}

if (Get-NetFirewallDynamicKeywordAddress -Id $DYKWID -ErrorAction Ignore) {
	Update-NetFirewallDynamicKeywordAddress -Id $DYKWID -Addresses $IPLIST | Out-Null
	$DDTIME = 'short'
	$DDTEXT = 'BT_BAN_IPLIST 已更新'
	$SILENT = 'true'
} else {
	New-NetFirewallDynamicKeywordAddress -Id $DYKWID -Keyword "BT_BAN_IPLIST" -Addresses $IPLIST | Out-Null
	$DDTIME = 'long'
	$DDTEXT = 'BT_BAN_IPLIST 已启用'
	$SILENT = 'false'
}

[XML]$TASKINFO = Export-ScheduledTask BT_BAN_$BTNAME -ErrorAction Ignore
if (-Not ($TASKINFO.Task.Actions.Exec.Command -Match "BT_BAN_$BTNAME.vbs")) {
	$VBS = 'createobject("wscript.shell").run "CMD",0'
	$CMD = "powershell `"`"iex `"`"`"`"&{`$(irm $IRMURL -TimeoutSec 30)} '$BTPATH'`"`"`"`"`"`""
	$VBS.Replace("CMD","$CMD") >$env:USERPROFILE\BT_BAN_$BTNAME.vbs

	Unregister-ScheduledTask BT_BAN_$BTNAME -Confirm:$false -ErrorAction Ignore

	$PRINCIPAL = New-ScheduledTaskPrincipal -UserId (whoami) -RunLevel Highest
	$SETTINGS = New-ScheduledTaskSettingsSet -RestartCount 5 -RestartInterval (New-TimeSpan -Seconds 60) -StartWhenAvailable -AllowStartIfOnBatteries
	$TRIGGER = New-ScheduledTaskTrigger -Once -At 00:00 -RepetitionInterval  (New-TimeSpan -Hours 8)
	$ACTION = New-ScheduledTaskAction -Execute $env:USERPROFILE\BT_BAN_$BTNAME.vbs
	$TASK = New-ScheduledTask -Principal $PRINCIPAL -Settings $SETTINGS -Trigger $TRIGGER -Action $ACTION

	Register-ScheduledTask BT_BAN_$BTNAME -InputObject $TASK | Out-Null
	Start-ScheduledTask BT_BAN_$BTNAME
	
	$DDTIME = 'short'
	$DDTEXT = (echo "$DDTEXT / 任务计划已重建")
	$SILENT = 'false'
}


$XML = '<toast duration="DDTIME"><visual><binding template="ToastText01"><text id="1">DDTEXT</text></binding></visual><audio silent="BOOL"/></toast>'
$XmlDocument = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]::New()
$XmlDocument.loadXml($XML.Replace("DDTIME","$DDTIME").Replace("DDTEXT","$DDTEXT").Replace("BOOL","$SILENT"))
$AppId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]::CreateToastNotifier($AppId).Show($XmlDocument)
