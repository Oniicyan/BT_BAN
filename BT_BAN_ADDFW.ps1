Remove-Variable * -ErrorAction Ignore
$BTSCAN = 'Azureus\.exe|BitComet\.exe|BitComet_.*\.exe|biglybt\.exe|BitTorrent\.exe|btweb\.exe|deluge\.exe|qbittorrent\.exe|transmission-qt\.exe|uTorrent\.exe|utweb\.exe|tixati\.exe'

Write-Host

if ((Fltmc).Count -eq 3) {
	$APPWTPATH = "$ENV:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
	if (Test-Path $APPWTPATH) {
		$PROCESS = "$APPWTPATH -ArgumentList `"powershell $($MyInvocation.MyCommand.Definition)`""
	} else {
		$PROCESS = "powershell -ArgumentList `"$($MyInvocation.MyCommand.Definition)`""
	}
	Write-Host "  10 秒后以管理员权限继续执行"
	timeout 10
	Invoke-Expression "Start-Process $PROCESS -Verb RunAs"
	return
}

$TESTGUID = '{62809d89-9d3b-486b-808f-8c893c1c3378}'
Remove-NetFirewallDynamicKeywordAddress -Id $TESTGUID -ErrorAction Ignore
if (New-NetFirewallDynamicKeywordAddress -Id $TESTGUID -Keyword "BT_BAN_TEST" -Address 1.2.3.4 -ErrorAction Ignore) {
	Remove-NetFirewallDynamicKeywordAddress -Id $TESTGUID
} else {
	Write-Host "  当前 Windows 版本不支持动态关键字，请升级操作系统`n"
	return
}

if ((Get-NetFirewallProfile).Enabled -contains 0) {
	if ([string](Get-NetFirewallProfile | ForEach-Object {
	if ($_.Enabled -eq 1) {$_.Name}})`
	-Notmatch (((Get-NetFirewallSetting -PolicyStore ActiveStore).ActiveProfile) -Replace ', ','|')) {
		Write-Host "  当前网络下未启用 Windows 防火墙`n"
		Write-Host "  通常防护软件可与 Windows 防火墙共存，不建议禁用`n"
		Write-Host "  仍可继续配置，在 Windows 防火墙启用时生效`n"
		pause
	}
}

Write-Host "  已配置以下过滤规则`n"
Get-NetFirewallRule -DisplayName BT_BAN_* | ForEach-Object {'  ' + $_.DisplayName + ' (' + $_.Direction + ')'}
Write-Host

$DYKWID = '{3817fa89-3f21-49ca-a4a4-80541ddf7465}'
Write-Host "  --------------------------------"
Write-Host "  请指定启用过滤规则的 BT 应用程序"
Write-Host "  --------------------------------"
Write-Host
Write-Host "  1. 自动识别"
Write-Host "     从现有的 Windows 防火墙过滤规则中识别 BT 应用程序路径"
Write-Host "     仅识别常见的 BT 应用程序"
Write-Host
Write-Host "  2. 手动选择"
Write-Host "     可选择快捷方式"
Write-Host "     每次选择单个 BT 应用程序"
Write-Host
$BTRULE = Read-Host "请输入 1 或 2（默认为自动识别）"
switch ($BTRULE) {
	2 {
		Add-Type -AssemblyName System.Windows.Forms
		$BTINFO = New-Object System.Windows.Forms.OpenFileDialog -Property @{InitialDirectory = [Environment]::GetFolderPath('Desktop')}
		while ($True) {
			$BTINFO.ShowDialog() | Out-Null
			if ($BTINFO.FileName) {break} else {Write-Host "`n  未选择文件`n"}
		}
		$BTPATH = $BTINFO.FileName
		$BTNAME = [System.IO.Path]::GetFileName($BTPATH)
		Remove-NetFirewallRule -DisplayName "BT_BAN_$BTNAME" -ErrorAction Ignore
		New-NetFirewallRule -DisplayName "BT_BAN_$BTNAME" -Direction Inbound -Action Block -Program $BTPATH -RemoteDynamicKeywordAddresses $DYKWID | Out-Null
		New-NetFirewallRule -DisplayName "BT_BAN_$BTNAME" -Direction Outbound -Action Block -Program $BTPATH -RemoteDynamicKeywordAddresses $DYKWID | Out-Null
	}
	default {
		$FWLIST = (Get-NetFirewallApplicationFilter).Program | Select-String $BTSCAN | Sort-Object | Get-Unique
		$BTLIST =@()
		foreach ($BTPATH in $FWLIST) {
			if ($BTPATH -Match '^%') {
				$BTTEST = Invoke-Expression (($BTPATH -Replace '^%','${ENV:').Replace('%','} + ''') + "'")
			} else {
				$BTTEST = $BTPATH
			}
			if (Test-Path $BTTEST) {$BTLIST += $BTPATH}
		}
		if (!$BTLIST) {Write-Host "`n  识别不到 BT 应用程序`n  请重新执行脚本并手动选择`n"; return}
		foreach ($BTPATH in $BTLIST) {
			$BTNAME = [System.IO.Path]::GetFileName($BTPATH)
			Remove-NetFirewallRule -DisplayName "BT_BAN_$BTNAME" -ErrorAction Ignore
			New-NetFirewallRule -DisplayName "BT_BAN_$BTNAME" -Direction Inbound -Action Block -Program $BTPATH -RemoteDynamicKeywordAddresses $DYKWID | Out-Null
			New-NetFirewallRule -DisplayName "BT_BAN_$BTNAME" -Direction Outbound -Action Block -Program $BTPATH -RemoteDynamicKeywordAddresses $DYKWID | Out-Null
		}
	}
}

Clear-Host
Write-Host "`n  已配置以下过滤规则`n"
Get-NetFirewallRule -DisplayName BT_BAN_* | ForEach-Object {'  ' + $_.DisplayName + ' (' + $_.Direction + ')'}
Read-Host "`n操作已完成，按 Enter 键结束"
