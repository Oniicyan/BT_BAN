if ((Fltmc).Count -eq 3) {
	Write-Host `n请以管理员权限执行`n
	return
}
$LIST = (Get-NetFirewallApplicationFilter).Program | Select-String -Notmatch 'Any|^System$|%systemroot%' | Unique
$LOST = @()
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
		Write-Host "程序：$PATH"
		Write-Host "规则："
		Get-NetFirewallApplicationFilter -Program $PATH | Get-NetFirewallRule | ForEach-Object {'　　　' + $_.DisplayName + ' (' +$_.Direction + ')'}
		Write-Host
	}
} else {
	Write-Host `n没有需要清理的过滤规则
	return
}
Write-Host 以上过滤规则的关联程序不存在`n
Write-Host 如要清理，请按 Enter 键
Write-Host 如要退出，请按 Ctrl+C 键或关闭本窗口`n
pause
Get-NetFirewallApplicationFilter -Program $LOST | Remove-NetFirewallRule
Write-Host `n清理完成
