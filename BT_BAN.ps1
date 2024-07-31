$PS1URL = 'https://bt-ban.pages.dev/BT_BAN.ps1'
$ZIPURL = 'https://bt-ban.pages.dev/IPLIST.zip'

$TOAST ={
	$XML = '<toast DDPARM><visual><binding template="ToastText02"><text id="1">BT_BAN_IPLIST</text><text id="2">DDTEXT</text></binding></visual><audio silent="BOOL"/><actions>MYLINK</actions></toast>'
	$XmlDocument = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]::New()
	$XmlDocument.loadXml($XML.Replace("DDPARM","$DDPARM").Replace("DDTEXT","$DDTEXT").Replace("BOOL","$SILENT").Replace("MYLINK","$MYLINK"))
	$AppId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
	[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]::CreateToastNotifier($AppId).Show($XmlDocument)
}

if (! (Get-NetFirewallRule -DisplayName "BT_BAN_*")) {
	$DDPARM = 'scenario="incomingCall"'
	$DDTEXT = "过滤规则丢失，请重新执行配置命令`n> iex (irm bt-ban.pages.dev)"
	$SILENT = 'false'
	$MYLINK = '<action content="查看帮助" activationType="protocol" arguments="https://github.com/Oniicyan/BT_BAN"/>'

	&$TOAST
	exit 1
}

New-Item -ItemType Directory -Path $env:USERPROFILE\BT_BAN -Force | Out-Null
while ($ZIP -lt 5) {
	try {
		Invoke-WebRequest -OutFile $env:USERPROFILE\BT_BAN\IPLIST.zip $ZIPURL -TimeoutSec 30
		break
	} catch {
		sleep 60
		$ZIP++
		if ($ZIP -ge 5) {exit 1}
	}
}
Expand-Archive -Force -Path $env:USERPROFILE\BT_BAN\IPLIST.zip -DestinationPath $env:USERPROFILE\BT_BAN
$IPLIST = Get-Content $env:USERPROFILE\BT_BAN\IPLIST.txt

$DYKWID = '{3817fa89-3f21-49ca-a4a4-80541ddf7465}'
if (Get-NetFirewallDynamicKeywordAddress -Id $DYKWID -ErrorAction Ignore) {
	Update-NetFirewallDynamicKeywordAddress -Id $DYKWID -Addresses $IPLIST | Out-Null
	$DDPARM = ''
	$DDTEXT = '动态关键字已更新'
	$SILENT = "true"
} else {
	New-NetFirewallDynamicKeywordAddress -Id $DYKWID -Keyword "BT_BAN_IPLIST" -Addresses $IPLIST | Out-Null
	$DDPARM = 'duration="long"'
	$DDTEXT = '动态关键字已启用'
	$SILENT = "false"
}

$SET_UPDATE ={
	$VBS = 'createobject("wscript.shell").run "CMD",0'
	$CMD = "powershell `"`"iex `"`"`"`"&{`$(irm $IRMURL -TimeoutSec 30)} '$BTPATH'`"`"`"`"`"`""
	$VBS.Replace("CMD","$CMD") >$env:USERPROFILE\BT_BAN\UPDATE.vbs
	
	$PRINCIPAL = New-ScheduledTaskPrincipal -UserId (whoami) -RunLevel Highest
	$SETTINGS = New-ScheduledTaskSettingsSet -RestartCount 5 -RestartInterval (New-TimeSpan -Seconds 60) -AllowStartIfOnBatteries
	$TRIGGER = New-ScheduledTaskTrigger -Once -At 00:05 -RepetitionInterval  (New-TimeSpan -Hours 8)
	$ACTION = New-ScheduledTaskAction -Execute $env:USERPROFILE\BT_BAN\UPDATE.vbs
	$TASK = New-ScheduledTask -Principal $PRINCIPAL -Settings $SETTINGS -Trigger $TRIGGER -Action $ACTION

	$TASKLIST = (Get-ScheduledTask BT_BAN_*).TaskName
	if ($TASKLIST) {Unregister-ScheduledTask $TASKLIST -Confirm:$false}
	Register-ScheduledTask BT_BAN_UPDATE -InputObject $TASK | Out-Null

	$DDPARM = 'duration="long"'
	$DDTEXT = "$DDTEXT`n任务计划已重建"
	$SILENT = 'false'

	# 删除旧版本文件，此部分保留一段时间
	$SYSTMP = [System.Environment]::GetEnvironmentVariable('TEMP','Machine')
	$SYSUSR = 'C:\Windows\system32\config\systemprofile'
	Remove-Item $SYSTMP -Include BT_BAN* -Recurse -Force -ErrorAction Ignore
	Remove-Item $SYSUSR -Include BT_BAN* -Recurse -Force -ErrorAction Ignore
}

[XML]$TASKINFO = Export-ScheduledTask BT_BAN_UPDATE -ErrorAction Ignore
if (! ($TASKINFO.Task.RegistrationInfo.URI -Match 'BT_BAN_UPDATE')) {
	&$SET_UPDATE
}

&$TOAST
