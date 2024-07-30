$IRMURL = 'https://bt-ban.pages.dev/BT_BAN.ps1'

$TESTGUID = '{62809d89-9d3b-486b-808f-8c893c1c3378}'
Remove-NetFirewallDynamicKeywordAddress -Id $TESTGUID -ErrorAction Ignore
if (New-NetFirewallDynamicKeywordAddress -Id $TESTGUID -Keyword "BT_BAN_TEST" -Address 1.2.3.4 -ErrorAction Ignore) {
	Remove-NetFirewallDynamicKeywordAddress -Id $TESTGUID
} else {
	echo ""
	echo "  Windows 版本不支持动态关键字，请升级操作系统"
	echo ""
	pause
	exit
}

if ((Fltmc).Count -eq 3) {
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
echo "  详细请阅 https://github.com/Oniicyan/BT_BAN"
echo ""
echo "  可选择快捷方式"
echo "  可选择多款客户端（需再次执行脚本）"
echo ""
echo "  同名客户端多开，即使目录不同，也需修改文件名以区分"
echo ""
pause

Add-Type -AssemblyName System.Windows.Forms
$BTINFO = New-Object System.Windows.Forms.OpenFileDialog -Property @{InitialDirectory = [Environment]::GetFolderPath('Desktop')}
$BTINFO.ShowDialog() | Out-Null

if (!$BTINFO.FileName) {
	cls
	echo ""
	echo "  未选择文件"
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
	echo "  如需要同名客户端多开，请修改文件名以区分"
	echo ""
	echo "  覆盖请按 Enter 键，退出请按 Ctrl + C 键"
	echo ""
	pause
}

$VBS = 'createobject("wscript.shell").run "CMD",0'
$CMD = "powershell `"`"iex `"`"`"`"&{`$(irm $IRMURL -TimeoutSec 30)} '$BTPATH'`"`"`"`"`"`""
$VBS.Replace("CMD","$CMD") >$env:USERPROFILE\BT_BAN_$BTNAME.vbs

Unregister-ScheduledTask BT_BAN_$BTNAME -Confirm:$false -ErrorAction Ignore

$PRINCIPAL = New-ScheduledTaskPrincipal -UserId (whoami) -RunLevel Highest
$SETTINGS = New-ScheduledTaskSettingsSet -RestartCount 5 -RestartInterval (New-TimeSpan -Seconds 60) -AllowStartIfOnBatteries
$TRIGGER = New-ScheduledTaskTrigger -Once -At 00:00 -RepetitionInterval  (New-TimeSpan -Hours 8)
$ACTION = New-ScheduledTaskAction -Execute $env:USERPROFILE\BT_BAN_$BTNAME.vbs
$TASK = New-ScheduledTask -Principal $PRINCIPAL -Settings $SETTINGS -Trigger $TRIGGER -Action $ACTION

Register-ScheduledTask BT_BAN_$BTNAME -InputObject $TASK | Out-Null
Start-ScheduledTask BT_BAN_$BTNAME

cls
echo ""
echo "  已添加任务计划并执行，每 8 小时更新"
echo ""
echo "  首次执行脚本，可能需要等待 30 秒左右生效"
echo ""
echo "  启用及更新结果，请留意右下角通知"
echo ""
echo "  执行以下命令清除配置"
echo ""
echo "  iex (irm bt-ban.pages.dev/BT_BAN_UNSET.ps1)"
echo ""
echo "  启用配置与清除配置的脚本均允许重复执行"
echo ""
