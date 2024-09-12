$WTPATH = "$ENV:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
if (Test-Path $WTPATH) {
	$PROCESS = "$WTPATH -ArgumentList powershell $MyInvocation.MyCommand"
} else {
	$PROCESS = "powershell -ArgumentList $MyInvocation.MyCommand"
}
if ((Fltmc).Count -eq 3) {
	Write-Host "`n  以管理员权限重新执行`n"
	Write-Host Start-Process $PROCESS -Verb RunAs
} else {
	Write-Host "`n  OK`n"
}
$MyInvocation
$MyInvocation.MyCommand
pause
