$TASKLIST = (Get-ScheduledTask BT_BAN_*).TaskName
if ($TASKLIST) {
	echo "  找到并删除以下任务计划"
	$TASKLIST | ForEach-Object {'  ' + $_}
	Unregister-ScheduledTask $TASKLIST -Confirm:$false
}
else {
	echo "  没有需要删除的任务计划"
}

$RULELIST = (Get-NetFirewallRule -DisplayName BT_BAN_*).DisplayName
if ($RULELIST) {
	echo "  找到并删除以下过滤规则"
	$RULELIST | ForEach-Object {'  ' + $_}
	Remove-NetFirewallRule -DisplayName $RULELIST
}
else {
	echo "  没有需要删除的过滤规则"
	echo "  首次执行脚本，可能需要等待 30 秒左右"
}

$DYKWID = '{3817fa89-3f21-49ca-a4a4-80541ddf7465}'
if (Get-NetFirewallDynamicKeywordAddress -Id $DYKWID -ErrorAction Ignore) {
	echo "  找到并删除动态关键字"
	Remove-NetFirewallDynamicKeywordAddress -Id $DYKWID
}
else {
	echo "  没有需要删除的动态关键字"
	echo "  首次执行脚本，可能需要等待 30 秒左右"
}