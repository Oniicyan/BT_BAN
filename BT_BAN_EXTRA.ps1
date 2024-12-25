Remove-Variable * -ErrorAction Ignore
$PS1URL = 'https://bt-ban.pages.dev/run'

Write-Host

if (!(Test-Path $ENV:USERPROFILE\BT_BAN\UPDATE.vbs)) {
	Read-Host 请在安装 BT_BAN 脚本后执行，按 Enter 键结束...
	return
}

Write-Host "  请输入附加规则的地址"
Write-Host "  可以是网络，也可以是本地的文件地址"
$EXTURL = Read-Host `n规则地址

try {$EXLIST = $(Invoke-RestMethod $EXTURL -TimeoutSec 30)
} catch {
	Write-Host "`n  获取附加规则失败，请检查网络或本地文件地址"
	Read-Host `n操作失败，按 Enter 键结束...
}

if ($EXLIST -Notmatch '((\d{1,3}\.){3}\d{1,3}(\/\b([1-9]|[12][0-9]|3[0-2])\b)?)|(([0-9a-f]{1,4}::?){1,7}(([0-9a-f]{1,4})|:)(\/\b([1-9]|[1-9][0-9]|1[01][0-9]|12[0-8])\b)?)') {
	Write-Host "`n  解析附加规则失败，请确认 IP 格式"
	Read-Host `n操作失败，按 Enter 键结束...
}

$VBS = 'createobject("wscript.shell").run "CMD",0'
$CMD = "powershell -v 3 `"`"iex `"`"`"`"& {`$(irm $PS1URL -TimeoutSec 30)} $EXTURL`"`"`"`"`"`""
$VBS.Replace("CMD","$CMD") | Out-File -Encoding ASCII $ENV:USERPROFILE\BT_BAN\UPDATE.vbs

Remove-Item $ENV:USERPROFILE\BT_BAN\IPLIST.txt -Force -ErrorAction Ignore
Start-ScheduledTask BT_BAN_UPDATE
Read-Host `n操作完成，按 Enter 键结束...
