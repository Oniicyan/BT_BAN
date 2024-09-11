$AppId = 'BT_BAN_IPLIST'
Remove-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\$AppId" -Name "Enabled" -Force -ErrorAction Ignore
"" | Out-File $ENV:LOCALAPPDATA\Microsoft\Windows\Notifications\wpndatabase.db -Force -ErrorAction Ignore
"" | Out-File $ENV:LOCALAPPDATA\Microsoft\Windows\Notifications\wpndatabase.db-wal -Force -ErrorAction Ignore
Write-Host "`n  正在重启通知平台，可能需要几分钟...`n"
$SVCLIST = Get-Service -Name OneSyncSvc_*,CDPUserSvc_*,WpnUserService_*
foreach ($SVCNAME in $SVCLIST.Name) {
	Start-Job {Stop-Service $Using:SVCNAME} | Out-Null
}
Get-Job | Wait-Job | Out-Null
try {
	Remove-Item $ENV:LOCALAPPDATA\Microsoft\Windows\Notifications\wpndatabase.db-shm -Force -ErrorAction Ignore
} catch {}
foreach ($SVCNAME in $SVCLIST.Name) {
	Start-Job {Start-Service $Using:SVCNAME} | Out-Null
}
Get-Job | Wait-Job | Out-Null
Get-Job | Remove-Job -Force
$XML = '<toast><visual><binding template="ToastText01"><text id="1">已恢复推送通知</text></binding></visual></toast>'
$XmlDocument = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]::New()
$XmlDocument.loadXml($XML)
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]::CreateToastNotifier($AppId).Show($XmlDocument)
Write-Host "  已恢复推送通知`n"
if ((Fltmc).Count -eq 3) {
	Write-Host "  如未显示，请以管理员权限执行`n"
} else {
	Write-Host "  如未显示，请重启 Windows`n"
}
