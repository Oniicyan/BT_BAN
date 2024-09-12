if ((Fltmc).Count -eq 3) {
	$APPWTPATH = "$ENV:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
	if (Test-Path $APPWTPATH) {
		$PROCESS = "$APPWTPATH -ArgumentList `"powershell $($MyInvocation.MyCommand.Definition)`""
	} else {
		$PROCESS = "powershell -ArgumentList `"$($MyInvocation.MyCommand.Definition)`""
	}
	Write-Host "`n10 秒后以管理员权限继续执行"
	timeout 10
	Invoke-Expression "Start-Process $PROCESS -Verb RunAs"
	return
}

Write-Host `n即将扫描 Windows 防火墙中，关联程序已被删除或移动的过滤规则
Write-Host `n可能需要耗时几分钟`n
pause

$LIST = (Get-NetFirewallApplicationFilter).Program | Select-String -Notmatch 'Any|^System$|%systemroot%' | Sort-Object | Get-Unique
$LOST = @()
$FAIL = @()
foreach ($PATH in $LIST) {
	if ($PATH -Match '^%') {
		$TEST = Invoke-Expression (($PATH -Replace '^%','${ENV:').Replace('%','} + ''') + "'")
	} else {
		$TEST = $PATH
	}
	if (!(Test-Path $TEST)) {$LOST += $PATH}
}
if ($LOST) {
	foreach ($PATH in $LOST) {
		Write-Host
		Write-Host 程序：$PATH
		Write-Host 规则：
		if ($RULE = Get-NetFirewallApplicationFilter -Program $PATH | Get-NetFirewallRule) {
			$RULE | ForEach-Object {'　　　' + $_.DisplayName + ' (' +$_.Direction + ')'}
		} else {$FAIL += $PATH}
	}
} else {
	Write-Host `n没有需要清理的过滤规则，10 秒后退出
 	timeout 10
	return
}

Write-Host `n以上过滤规则的关联程序已被删除或移动
Write-Host Inbound/Outbound 代表 入站规则/出站规则`n
Write-Host 如要清理，请按 Enter 键
Write-Host 如要退出，请按 Ctrl+C 键或关闭本窗口`n
pause
Get-NetFirewallApplicationFilter -Program $LOST | Remove-NetFirewallRule
Write-Host `n清理完成`n
if ($FAIL) {
	Write-Host 以下关联程序的过滤规则清理失败，请手动删除`n
	$FAIL
}
Read-Host 操作完成，按 Enter 键结束...
