# 从网络上的 ZIP 文件中获取 IPLIST
# 可自行替换 URL
$ZIPURL = 'https://bt-ban.pages.dev/IPLIST.zip'
New-Item -ItemType Directory -Path $env:temp\BT_BAN -ErrorAction Ignore | Out-Null
while ($ZIP -lt 5) {
	try {
		Invoke-WebRequest -OutFile $env:temp\BT_BAN\IPLIST.zip $ZIPURL -TimeoutSec 30
		break
	} catch {
		sleep 60
		$ZIP++
		if ($ZIP -ge 5) {exit 1}
	}
}
Expand-Archive -Force -Path $env:temp\BT_BAN\IPLIST.zip -DestinationPath $env:temp\BT_BAN
$IPLIST = (Get-Content $env:USERPROFILE\BT_BAN\IPLIST.txt) -Join ','

# 从网络上的 TXT 文件中获取 IPLIST
# 可自行替换 URL
# 请自行删除注释以启用
# $IPLIST = irm https://bt-ban.pages.dev/IPLIST.txt

# 配置动态关键字
# 可自行替换 GUID
$DYKWID = '{3817fa89-3f21-49ca-a4a4-80541ddf7465}'
if (Get-NetFirewallDynamicKeywordAddress -Id $DYKWID -ErrorAction Ignore) {
	Update-NetFirewallDynamicKeywordAddress -Id $DYKWID -Addresses $IPLIST | Out-Null
} else {
	New-NetFirewallDynamicKeywordAddress -Id $DYKWID -Keyword "BT_BAN_IPLIST" -Addresses $IPLIST | Out-Null
}

# 弹出通知
# 若不需要，可自行删除
# 不需要通知时，建议使用 CMD 脚本
$XML = '<toast><visual><binding template="ToastText01"><text id="1">IPLIST 已更新</text></binding></visual><audio silent="true"/></toast>'
$XmlDocument = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]::New()
$XmlDocument.loadXml($XML)
$AppId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]::CreateToastNotifier($AppId).Show($XmlDocument)
