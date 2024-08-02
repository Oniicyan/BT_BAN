Remove-Variable * -ErrorAction Ignore
$PS1URL = 'https://bt-ban.pages.dev/run'

if ((Fltmc).Count -eq 3) {
	echo ""
	echo "  请以管理员权限执行"
	echo ""
	return
}

$TESTGUID = '{62809d89-9d3b-486b-808f-8c893c1c3378}'
Remove-NetFirewallDynamicKeywordAddress -Id $TESTGUID -ErrorAction Ignore
if (New-NetFirewallDynamicKeywordAddress -Id $TESTGUID -Keyword "BT_BAN_TEST" -Address 1.2.3.4 -ErrorAction Ignore) {
	Remove-NetFirewallDynamicKeywordAddress -Id $TESTGUID
} else {
	echo ""
	echo "  当前 Windows 版本不支持动态关键字，请升级操作系统"
	echo ""
	return
}

if ((Get-NetFirewallProfile).Enabled -contains 0) {
	if ([string](Get-NetFirewallProfile | %{`
	if ($_.Enabled -eq 1) {$_.Name}})`
	-Notmatch (((Get-NetFirewallSetting -PolicyStore ActiveStore).ActiveProfile) -Replace(', ','|'))) {
		echo ""
		echo "  当前网络下未启用 Windows 防火墙"
		echo ""
		echo "  通常防护软件可与 Windows 防火墙共存，不建议禁用"
		echo ""
		echo "  仍可继续配置，在 Windows 防火墙启用时生效"
		echo ""
		pause
	}
}

echo ""
echo "  请指定启用过滤规则的 BT 应用程序文件"
echo ""
echo "  本方案仅对选中的程序生效，不影响其他程序的通信"
echo "  详细请阅 https://github.com/Oniicyan/BT_BAN"
echo ""
echo "  可选择快捷方式"
echo "  可选择多款客户端（需再次执行命令）"
echo ""
echo "  同名程序多开，即使目录不同，也需修改文件名以区分"
echo ""
pause

Add-Type -AssemblyName System.Windows.Forms
$BTINFO = New-Object System.Windows.Forms.OpenFileDialog -Property @{InitialDirectory = [Environment]::GetFolderPath('Desktop')}
$BTINFO.ShowDialog() | Out-Null

if (!$BTINFO.FileName) {
	echo ""
	echo "  未选择文件"
	echo ""
	echo "  请重新执行脚本，并正确选择 BT 应用程序"
	echo ""
	return
}

$BTPATH = $BTINFO.FileName
$BTNAME = [System.IO.Path]::GetFileName($BTPATH)

if (Get-NetFirewallRule -DisplayName BT_BAN_$BTNAME -ErrorAction Ignore) {
	cls
	echo ""
	echo "  BT_BAN_$BTNAME 过滤规则已存在"
	echo ""
	echo "  如需要同名客户端多开，请修改文件名以区分"
	echo ""
	echo "  覆盖请按 Enter 键，退出请按 Ctrl + C 键"
	echo ""
	pause
}

$DYKWID = '{3817fa89-3f21-49ca-a4a4-80541ddf7465}'
$RULELS = Get-NetFirewallRule -DisplayName "BT_BAN_$BTNAME" -ErrorAction Ignore

$SET_RULES = {
	Remove-NetFirewallRule -DisplayName "BT_BAN_$BTNAME" -ErrorAction Ignore
	New-NetFirewallRule -DisplayName "BT_BAN_$BTNAME" -Direction Inbound -Action Block -Program $BTPATH -RemoteDynamicKeywordAddresses $DYKWID | Out-Null
	New-NetFirewallRule -DisplayName "BT_BAN_$BTNAME" -Direction Outbound -Action Block -Program $BTPATH -RemoteDynamicKeywordAddresses $DYKWID | Out-Null
}

if (($RULELS.RemoteDynamicKeywordAddresses -Match $DYKWID).Count -ne 2) {
	&$SET_RULES
} elseif ((($RULELS | Get-NetFirewallApplicationFilter).Program -Match [regex]::Escape($BTPATH)).Count -ne 2) {
	&$SET_RULES
} elseif (($RULELS.Direction -Match 'Inbound').Count -ne 1) {
	&$SET_RULES
}

cls
echo "  成功配置过滤规则"
echo ""
echo "  正在获取并执行任务计划，可能需要等待 30 秒左右"
echo ""

try {
	iex (irm $PS1URL -TimeoutSec 30)
} catch {
	echo "  脚本获取或执行失败，请尝试手动执行配置命令"
	echo ""
	echo "  iex (irm bt-ban.pages.dev/run)"
	echo ""
	return
}

$RULELIST = Get-NetFirewallRule -DisplayName BT_BAN_* | Select-Object -Property Displayname, Direction
$TASKLIST = (Get-ScheduledTask BT_BAN_*).TaskName
cls
echo ""
echo "  成功配置以下过滤规则"
echo ""
$RULELIST | ForEach-Object {'  ' + $_.DisplayName + ' (' + $_.Direction + ')'}
echo ""
echo "  成功配置以下任务计划"
echo ""
$TASKLIST | ForEach-Object {'  ' + $_}
echo ""
echo "  成功配置以下动态关键字"
echo ""
echo "  BT_BAN_IPLIST"
echo ""
echo "  -------------------------------------"
echo ""
echo "  每天 0-1 8-9 16-17 时之间更新 IP 列表"
echo ""
echo "  启用及更新结果，请留意右下角通知"
echo ""
echo "  执行以下命令清除配置"
echo ""
echo "  iex (irm bt-ban.pages.dev/unset)"
echo ""
echo "  启用命令与清除命令均允许重复执行"
echo ""
echo "  -------------------------------------"
echo ""
