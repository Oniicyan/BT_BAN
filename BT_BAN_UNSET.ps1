if ((Fltmc).Count -eq 3) {
	echo ""
	echo "  请以管理员权限重新执行"
	echo ""
	pause
	exit
}

$TASKLIST = (Get-ScheduledTask BT_BAN_*).TaskName
if ($TASKLIST) {
	echo ""
	echo "  找到并删除以下任务计划"
	echo ""
	$TASKLIST | ForEach-Object {'  ' + $_}
	Unregister-ScheduledTask $TASKLIST -Confirm:$false
} else {
	echo ""
	echo "  没有需要删除的任务计划"
}

$RULELIST = Get-NetFirewallRule -DisplayName BT_BAN_* | Select-Object -Property Displayname, Direction
if ($RULELIST) {
	echo ""
	echo "  找到并删除以下过滤规则"
	echo ""
	$RULELIST | ForEach-Object {'  ' + $_.DisplayName + ' (' + $_.Direction + ')'}
	Remove-NetFirewallRule -DisplayName $RULELIST.DisplayName
} else {
	echo ""
	echo "  没有需要删除的过滤规则"
}

$FILELIST = (Get-Childitem $env:USERPROFILE\BT_BAN -Recurse).FullName
if ($FILELIST) {
	echo ""
	echo "  找到并删除以下脚本文件"
	echo ""
	echo "  $env:USERPROFILE\BT_BAN"
	$FILELIST | ForEach-Object {'  ' + $_}
	Remove-Item $env:USERPROFILE\BT_BAN -Force -Recurse -ErrorAction Ignore
} else {
	echo ""
	echo "  没有需要删除的脚本文件"
}

$DYKWID = '{3817fa89-3f21-49ca-a4a4-80541ddf7465}'
$DYKWNAME = (Get-NetFirewallDynamicKeywordAddress -Id $DYKWID -ErrorAction Ignore).Keyword
if ($DYKWNAME) {
	echo ""
	echo "  找到并删除以下动态关键字"
	echo ""
	$DYKWNAME | ForEach-Object {'  ' + $_}
	Remove-NetFirewallDynamicKeywordAddress -Id $DYKWID
} else {
	echo ""
	echo "  没有需要删除的动态关键字"
	echo ""
	echo "  若首次启用，请等待右下角弹出通知后再清除"
}

echo ""
