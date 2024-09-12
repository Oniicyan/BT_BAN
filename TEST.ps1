$WTPATH = "$ENV:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
if (Test-Path $WTPATH) {
	$SHELL = "$WTPATH powershell"
} else {
	$SHELL = "powershell"
}
if ((Fltmc).Count -eq 3) {
	Write-Host "`n  以管理员权限重新执行`n"
	Start-Process $SHELL -ArgumentList $MyInvocation.MyCommand
} else {
	Write-Host "`n  OK`n"
}
pause
