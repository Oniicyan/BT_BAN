Remove-Variable * -ErrorAction Ignore
$PS1URL = 'https://bt-ban.pages.dev/run'
$ZIPURL = 'https://bt-ban.pages.dev/IPLIST.zip'

echo "  成功获取脚本"
New-Item -ItemType Directory -Path $env:USERPROFILE\BT_BAN -ErrorAction Ignore | Out-Null
$TASKINFO = Get-ScheduledTask BT_BAN_* -ErrorAction Ignore

$TOAST = {
	$XML = '<toast DDPARM><visual><binding template="ToastText02"><text id="1">BT_BAN_IPLIST</text><text id="2">DDTEXT</text></binding></visual><audio silent="BOOL"/><actions>MYLINK</actions></toast>'
	$XmlDocument = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]::New()
	$XmlDocument.loadXml($XML.Replace("DDPARM","$DDPARM").Replace("DDTEXT","$DDTEXT").Replace("BOOL","$SILENT").Replace("MYLINK","$MYLINK"))
	$AppId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
	[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]::CreateToastNotifier($AppId).Show($XmlDocument)
}

$SET_UPDATE = {
	$VBS = 'createobject("wscript.shell").run "CMD",0'
	$CMD = "powershell `"`"iex (irm $PS1URL -TimeoutSec 30)`"`""
	$VBS.Replace("CMD","$CMD") >$env:USERPROFILE\BT_BAN\UPDATE.vbs

	$PRINCIPAL = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest
	$SETTINGS = New-ScheduledTaskSettingsSet -RestartCount 5 -RestartInterval (New-TimeSpan -Seconds 60) -StartWhenAvailable -AllowStartIfOnBatteries
	$TRIGGER = New-ScheduledTaskTrigger -Once -At 00:00 -RepetitionInterval (New-TimeSpan -Hours 8) -RandomDelay (New-TimeSpan -Hours 1)
	$ACTION = New-ScheduledTaskAction -Execute $env:USERPROFILE\BT_BAN\UPDATE.vbs
	$TASK = New-ScheduledTask -Principal $PRINCIPAL -Settings $SETTINGS -Trigger $TRIGGER -Action $ACTION

	$TASKLIST = (Get-ScheduledTask BT_BAN_*).TaskName
	if ($TASKLIST) {Unregister-ScheduledTask $TASKLIST -Confirm:$false}
	Register-ScheduledTask BT_BAN_UPDATE -InputObject $TASK | Out-Null

	$SILENT = 'false'
	$DDTEXT = "任务计划已创建"
	$DDPARM = ''
	$MYLINK = ''
	if ($TASKINFO) {$DDTEXT = "任务计划已重建"}
	&$TOAST

	Start-ScheduledTask BT_BAN_UPDATE
	return
}

if ($TASKINFO.Principal.UserId -Match 'SYSTEM') {
	if ($USERNAME = (quser) -Match '^>' -Replace ' .*' -Replace '>') {
	} elseif ($USERNAME = (Get-WMIObject -class Win32_ComputerSystem).UserName){
	} else {
		$PROCINFO = Get-WmiObject Win32_Process -Filter "name='explorer.exe'"
		$USERNAME = $PROCINFO.GetOwner().User
	}
	if ($USERNAME) {
		$PRINCIPAL = New-ScheduledTaskPrincipal -UserId $USERNAME -RunLevel Highest
		Set-ScheduledTask $TASKINFO.Uri -Principal $PRINCIPAL
		Start-ScheduledTask $TASKINFO.Uri
		exit
	}
}

if ($TASKINFO) {
	if ($TASKINFO.Principal.RunLevel -Notmatch 'Highest') {
		$SILENT = 'false'
		$DDTEXT = "当前任务计划未配置最高权限`n若提示权限不足，请执行启用命令重建`n> iex (irm bt-ban.pages.dev)`n无提示或正在重建时，请忽略本通知"
		$DDPARM = 'duration="long"'
		$MYLINK = '<action content="查看帮助" activationType="protocol" arguments="https://github.com/Oniicyan/BT_BAN"/>'
		&$TOAST
		$SETFLAG = 1
	}
}

if ((Fltmc).Count -eq 3) {
	$SILENT = 'false'
	$DDTEXT = "权限不足`n请以正确方式执行脚本"
	$DDPARM = ''
	$MYLINK = ''
	&$TOAST
	exit 1
}

if ((Get-NetFirewallRule -DisplayName "BT_BAN_*").Count -lt 2) {
	$SILENT = 'false'
	$DDTEXT = "过滤规则丢失，请执行启用命令重建`n> iex (irm bt-ban.pages.dev)"
	$DDPARM = 'scenario="incomingCall"'
	$MYLINK = '<action content="查看帮助" activationType="protocol" arguments="https://github.com/Oniicyan/BT_BAN"/>'
	&$TOAST
	exit 1
}

if ($TASKINFO) {
	if ($TASKINFO.Uri -Notmatch 'BT_BAN_UPDATE') {$SETFLAG = 1}
	if ($TASKINFO.Principal.UserId -Notmatch $env:USERNAME) {$SETFLAG = 1}
	if ($TASKINFO.Triggers.RandomDelay -Notmatch 'PT1H') {$SETFLAG = 1}
	if (!(Test-Path $env:USERPROFILE\BT_BAN\UPDATE.vbs)) {$SETFLAG = 1}
} else {$SETFLAG = 1}

if ($SETFLAG -eq 1) {
	&$SET_UPDATE
	return
}

while ($ZIP -lt 5) {
	$ZIP++
	try {
		Invoke-RestMethod -OutFile $env:USERPROFILE\BT_BAN\IPLIST.zip $ZIPURL -TimeoutSec 30
		break
	} catch {
		echo "  IP 列表下载失败，等待 1 分钟后尝试 （$ZIP/5）"
		sleep 60
		if ($ZIP -ge 5) {
			$SILENT = 'true'
			$DDTEXT = "IP 列表下载失败`n通常是服务器问题，跳过本次更新"
			$DDPARM = ''
			$MYLINK = ''
			&$TOAST
			exit 1
		}
	}
}
Expand-Archive -Force -Path $env:USERPROFILE\BT_BAN\IPLIST.zip -DestinationPath $env:USERPROFILE\BT_BAN
$IPLIST = (Get-Content $env:USERPROFILE\BT_BAN\IPLIST.txt) -Join ','

$DYKWID = '{3817fa89-3f21-49ca-a4a4-80541ddf7465}'
if (Get-NetFirewallDynamicKeywordAddress -Id $DYKWID -ErrorAction Ignore) {
	Update-NetFirewallDynamicKeywordAddress -Id $DYKWID -Addresses $IPLIST | Out-Null
	$SILENT = 'true'
	$DDTEXT = "动态关键字已更新，当前共 $(((Get-NetFirewallDynamicKeywordAddress -Id $DYKWID).Addresses -Split ',').Count) 条 IP（段）"
	$DDPARM = ''
	$MYLINK = ''
} else {
	New-NetFirewallDynamicKeywordAddress -Id $DYKWID -Keyword "BT_BAN_IPLIST" -Addresses $IPLIST | Out-Null
	$SILENT = 'false'
	$DDTEXT = "动态关键字已启用，当前共 $(((Get-NetFirewallDynamicKeywordAddress -Id $DYKWID).Addresses -Split ',').Count) 条 IP（段）"
	$DDPARM = 'duration="long"'
	$MYLINK = ''
}
&$TOAST
