Remove-Variable * -ErrorAction Ignore
if ((Fltmc).Count -eq 3) {
	$APPWTPATH = "$ENV:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
	if (Test-Path $APPWTPATH) {
		$PROCESS = "$APPWTPATH -ArgumentList `"powershell $($MyInvocation.MyCommand.Definition)`""
	} else {
		$PROCESS = "powershell -ArgumentList `"$($MyInvocation.MyCommand.Definition)`""
	}
	Write-Host "`n  10 秒后以管理员权限继续执行"
	timeout 10
	Invoke-Expression "Start-Process $PROCESS -Verb RunAs"
	return
}

if ($RULELIST = Get-NetFirewallRule -DisplayName BT_BAN_*) {
	Write-Host "`n  清除以下过滤规则`n"
	$RULELIST | ForEach-Object {'  ' + $_.DisplayName + ' (' + $_.Direction + ')'}
	Write-Host
	pause
	Remove-NetFirewallRule $RULELIST
} else {
	Write-Host "`n  没有需要清除的过滤规则`n"
}

if ($TASKLIST = Get-ScheduledTask BT_BAN_*) {
	Write-Host "`n  清除以下任务计划`n"
	$TASKLIST.TaskName | ForEach-Object {'  ' + $_}
	Write-Host
	pause
	Unregister-ScheduledTask $TASKLIST.TaskName -Confirm:$false
} else {
	Write-Host "`n  没有需要清除的任务计划`n"
}

$GUID = '{3817fa89-3f21-49ca-a4a4-80541ddf7465}'
if ($DYKW = Get-NetFirewallDynamicKeywordAddress -Id $GUID -ErrorAction Ignore) {
	Write-Host "`n  清除以下动态关键字`n"
	$DYKW.Keyword | ForEach-Object {'  ' + $_}
	Write-Host
	pause
	Remove-NetFirewallDynamicKeywordAddress -Id $GUID
} else {
	Write-Host "`n  没有需要清除的动态关键字`n"
}

if (Test-Path $ENV:USERPROFILE\BT_BAN) {
	Write-Host "`n  清除以下脚本文件`n"
	Write-Host "  $ENV:USERPROFILE\BT_BAN"
	(Get-Childitem $ENV:USERPROFILE\BT_BAN -Recurse).FullName | ForEach-Object {'  ' + $_}
	Write-Host
	pause
	Remove-Item $ENV:USERPROFILE\BT_BAN -Force -Recurse -ErrorAction Ignore
} else {
	Write-Host "`n  没有需要清除的脚本文件`n"
}

Write-Host "`n  已清除所有配置`n"
Read-Host "操作已完成，按 Enter 键结束..."
