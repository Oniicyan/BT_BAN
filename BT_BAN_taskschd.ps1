If ((Fltmc).Count -eq 3) {
	echo "���Թ���ԱȨ������ִ��"
	echo ""
	pause
	exit
}

echo "��ָ�����ù��˹���� BT Ӧ�ó��򣨿�ѡ���ݷ�ʽ��"
echo ""
pause

Add-Type -AssemblyName System.Windows.Forms
$BTINFO = New-Object System.Windows.Forms.OpenFileDialog -Property @{InitialDirectory = [Environment]::GetFolderPath('Desktop')}
$BTINFO.ShowDialog() | Out-Null

if (!$BTINFO.FileName) {
	cls
	echo "������ִ�У�����ȷѡ�� BT Ӧ�ó���"
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
echo "����ӹ��˹�����ƻ�����ÿСʱ����"
echo ""
echo "���踴ԭ����ִ�����²���"
echo ""
echo "���� taskschd ɾ�� BT_BAN ��ͷ�ļƻ�����"
echo "���� wf.msc���ֱ�ɾ�� BT_BAN ��ͷ����վ�������վ����"
echo "���� Remove-NetFirewallDynamicKeywordAddress ɾ�����ж�̬�ؼ���"
echo ""
echo "taskschd �� wf.msc ��ֱ�� Win + R ��ִ��"
echo "Remove-NetFirewallDynamicKeywordAddress ���� PowerShell ��ִ��"
echo ""