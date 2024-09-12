Remove-Variable * -ErrorAction Ignore
$PS1URL = 'https://bt-ban.pages.dev/run'
$BTSCAN = 'Azureus\.exe|BitComet\.exe|BitComet_.*\.exe|biglybt\.exe|BitTorrent\.exe|btweb\.exe|deluge\.exe|qbittorrent\.exe|transmission-qt\.exe|uTorrent\.exe|utweb\.exe|tixati\.exe'

Write-Host

if ((Fltmc).Count -eq 3) {
	$APPWTPATH = "$ENV:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
	if (Test-Path $APPWTPATH) {
		$PROCESS = "$APPWTPATH -ArgumentList `"powershell $($MyInvocation.MyCommand.Definition)`""
	} else {
		$PROCESS = "powershell -ArgumentList `"$($MyInvocation.MyCommand.Definition)`""
	}
	Write-Host "  10 秒后以管理员权限继续执行`n"
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

if ($DISABLED = Get-NetFirewallProfile | Where-Object {$_.Enabled -eq 0}) {
	$ACTIVEPF = ((Get-NetFirewallSetting -PolicyStore ActiveStore).ActiveProfile) -Replace ', ','|'
	$NEEDEDPF = @()
	foreach ($PFNAME in $DISABLED.Name) {if ($PFNAME -Match $ACTIVEPF) {$NEEDEDPF += $PFNAME}}
	if ($NEEDEDPF) {
		Write-Host "  当前网络下未启用 Windows 防火墙`n"
		Write-Host "  通常防护软件可与 Windows 防火墙共存，不建议禁用`n"
		Write-Host "  仍可继续配置，在 Windows 防火墙启用时生效`n"
		$ENABLEPF = Read-Host "输入 Y 启用 Windows 防火墙，否则跳过"
		Clear-Host
		switch -regex ($ENABLEPF) {
			'Y|y' {
				Set-NetFirewallProfile $NEEDEDPF -Enabled 1
				Write-Host "`n  成功启用 Windows 防火墙`n"
			}
			default {
				Write-Host "`n  跳过启用 Windows 防火墙`n"
			}
		}
	}
}

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
$BTRULE = Read-Host "请输入 1 或 2（默认为 自动识别）"
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
Write-Host
Write-Host "  成功配置过滤规则`n"
Write-Host "  正在获取并执行任务计划，可能需要等待 30 秒左右`n"

Remove-Item $ENV:USERPROFILE\BT_BAN\IPLIST.txt -Force -ErrorAction Ignore
try {
	Invoke-Expression (Invoke-RestMethod $PS1URL -TimeoutSec 30)
} catch {
	Write-Host "  脚本获取或执行失败，请尝试手动执行配置命令`n"
	Write-Host "  iex (irm bt-ban.pages.dev/run)`n"
	return
}

$RULELIST = Get-NetFirewallRule -DisplayName BT_BAN_* | Select-Object -Property Displayname, Direction
$TASKLIST = (Get-ScheduledTask BT_BAN_*).TaskName
Clear-Host
Write-Host "`n  成功配置以下过滤规则`n"
$RULELIST | ForEach-Object {'  ' + $_.DisplayName + ' (' + $_.Direction + ')'}
Write-Host "`n  成功配置以下任务计划`n"
$TASKLIST | ForEach-Object {'  ' + $_}
Write-Host "`n  成功配置以下动态关键字`n`n  BT_BAN_IPLIST `n"
Write-Host "  -------------------------------------`n"
Write-Host "  每小时更新 IP 黑名单订阅`n"
Write-Host "  每天 00:05 以及用户登录时，通知当前 IP 规则数量`n"
Write-Host "  执行以下命令恢复推送通知"
Write-Host "  iex (irm bt-ban.pages.dev/push)`n"
Write-Host "  执行以下命令添加过滤规则"
Write-Host "  iex (irm bt-ban.pages.dev/add)`n"
Write-Host "  执行以下命令清除所有配置"
Write-Host "  iex (irm bt-ban.pages.dev/unset)`n"
Write-Host "  -------------------------------------`n"
