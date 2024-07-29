If ((Fltmc).Count -eq 3) {
	echo ""
	echo "  请以管理员权限重新执行"
	echo ""
	pause
	exit
}

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Name "DisableFirstRunCustomize" -Value 2

echo ""
echo "  请指定启用过滤规则的 BT 应用程序文件"
echo ""
echo "  本方案仅对选中的程序生效，不影响其他程序的通信"
echo ""
echo "  可选择快捷方式"
echo "  可选择多款客户端（需要再次执行脚本）"
echo "  同款客户端多开，需要修改文件名以区分"
echo ""
pause

Add-Type -AssemblyName System.Windows.Forms
$BTINFO = New-Object System.Windows.Forms.OpenFileDialog -Property @{InitialDirectory = [Environment]::GetFolderPath('Desktop')}
$BTINFO.ShowDialog() | Out-Null

if (!$BTINFO.FileName) {
	cls
	echo ""
	echo "  请重新执行，并正确选择 BT 应用程序"
	echo ""
	pause
	exit
}

$BTPATH = $BTINFO.FileName
$BTNAME = [System.IO.Path]::GetFileName($BTPATH)

if (Get-ScheduledTask BT_BAN_$BTNAME -ErrorAction Ignore) {
	cls
	echo ""
	echo "  BT_BAN_$BTNAME 任务计划已存在"
	echo ""
	echo "  覆盖请按 Enter 键，退出请按 Ctrl + C 键"
	echo ""
	pause
}

Unregister-ScheduledTask BT_BAN_$BTNAME -Confirm:$false -ErrorAction Ignore

$PRINCIPAL = New-ScheduledTaskPrincipal -UserId SYSTEM -RunLevel Highest
$SETTINGS = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries
$TRIGGER = New-ScheduledTaskTrigger -Once -At 00:00 -RepetitionInterval  (New-TimeSpan -Hours 8)
$ACTION = New-ScheduledTaskAction -Execute powershell -Argument "`"iex `"`"&{`$(irm https://gitee.com/oniicyan/bt_ban/raw/master/BT_BAN.ps1)} '$BTPATH'`"`"`""
$TASK = New-ScheduledTask -Principal $PRINCIPAL -Settings $SETTINGS -Trigger $TRIGGER -Action $ACTION

Register-ScheduledTask BT_BAN_$BTNAME -InputObject $TASK | Out-Null
Start-ScheduledTask BT_BAN_$BTNAME

cls
echo ""
echo "  已添加任务计划并执行，每 8 小时更新"
echo ""
echo "  如需复原，请执行以下操作"
echo ""
echo "  运行 taskschd 删除 'BT_BAN' 开头的任务计划"
echo "  运行 wf.msc 分别删除 'BT_BAN' 开头的入站规则与出站规则"
echo "  运行 Remove-NetFirewallDynamicKeywordAddress -Id '{3817fa89-3f21-49ca-a4a4-80541ddf7465}' 删除动态关键字"
echo ""
echo "  taskschd 与 wf.msc 可直接按 Win + R 键运行"
echo "  Remove-NetFirewallDynamicKeywordAddress 需在 PowerShell 下运行"
echo ""