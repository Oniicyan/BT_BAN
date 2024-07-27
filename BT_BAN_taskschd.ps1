If ((Fltmc).Count -eq 3) {
	echo "请以管理员权限重新执行"
	echo ""
	pause
	exit
}

echo "请指定启用过滤规则的 BT 应用程序（可选择快捷方式）"
echo ""
pause

Add-Type -AssemblyName System.Windows.Forms
$BTINFO = New-Object System.Windows.Forms.OpenFileDialog -Property @{InitialDirectory = [Environment]::GetFolderPath('Desktop')}
$BTINFO.ShowDialog() | Out-Null

if (!$BTINFO.FileName) {
	cls
	echo "请重新执行，并正确选择 BT 应用程序"
	echo ""
	pause
	exit
}

$BTPATH = $BTINFO.FileName
$BTNAME = [System.IO.Path]::GetFileName($BTPATH)

Unregister-ScheduledTask BT_BAN_$BTNAME -Confirm:$false -ErrorAction Ignore

$PRINCIPAL = New-ScheduledTaskPrincipal -UserId SYSTEM -RunLevel Highest
$SETTINGS = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries
$TRIGGER = New-ScheduledTaskTrigger -Once -At 00:00 -RepetitionInterval  (New-TimeSpan -Hours 1)
$ACTION = New-ScheduledTaskAction -Execute powershell -Argument "`"iex `"`"&{`$(irm https://gitee.com/oniicyan/bt_ban/raw/master/BT_BAN.ps1)} '$BTPATH'`"`"`""
$TASK = New-ScheduledTask -Principal $PRINCIPAL -Settings $SETTINGS -Trigger $TRIGGER -Action $ACTION

Register-ScheduledTask BT_BAN_$BTNAME -InputObject $TASK | Out-Null
Start-ScheduledTask BT_BAN_$BTNAME

cls
echo "已添加过滤规则与计划任务，每小时更新"
echo ""
echo "如需复原，请执行以下操作"
echo ""
echo "运行 taskschd 删除 BT_BAN 开头的计划任务"
echo "运行 wf.msc，分别删除 BT_BAN 开头的入站规则与出站规则"
echo "运行 Remove-NetFirewallDynamicKeywordAddress 删除所有动态关键字"
echo ""
echo "taskschd 与 wf.msc 可直接 Win + R 键执行"
echo "Remove-NetFirewallDynamicKeywordAddress 需在 PowerShell 下执行"
echo ""