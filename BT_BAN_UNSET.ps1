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

$FILELIST = (Get-ChildItem -Path $env:USERPROFILE).Name -Match 'BT_BAN_'
if ($FILELIST) {
	echo ""
	echo "  找到并删除以下 VBS 脚本"
	echo ""
	$FILELIST | ForEach-Object {'  ' + $_}
	Remove-Item $FILELIST
} else {
	echo ""
	echo "  没有需要删除的 VBS 脚本"
}

$RULELIST = (Get-NetFirewallRule -DisplayName BT_BAN_*).DisplayName
if ($RULELIST) {
	echo ""
	echo "  找到并删除以下过滤规则"
	echo ""
	$RULELIST | ForEach-Object {'  ' + $_}
	Remove-NetFirewallRule -DisplayName $RULELIST
} else {
	echo ""
	echo "  没有需要删除的过滤规则"
	echo "  首次启用时，请等待右下角通知弹出"
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
	echo "  首次启用时，请等待右下角通知弹出"
}

echo ""
