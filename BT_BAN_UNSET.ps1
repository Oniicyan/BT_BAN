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
	echo "  首次执行脚本，可能需要等待 30 秒左右"
}

$DYKWID = '{3817fa89-3f21-49ca-a4a4-80541ddf7465}'
$DYKWNAME = (Get-NetFirewallDynamicKeywordAddress -Id $DYKWID).Keyword
if ($DYKWNAME) {
	echo ""
	echo "  找到并删除以下动态关键字"
	echo ""
	$DYKWNAME | ForEach-Object {'  ' + $_}
	Remove-NetFirewallDynamicKeywordAddress -Id $DYKWID
} else {
	echo ""
	echo "  没有需要删除的动态关键字"
	echo "  首次执行脚本，可能需要等待 30 秒左右"
}

echo ""
