$WTPATH = "$ENV:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
if (Test-Path $WTPATH) {
	$PROCESS = "$WTPATH -ArgumentList `"powershell $($MyInvocation.MyCommand.Definition)`""
} else {
	$PROCESS = "powershell -ArgumentList `"$($MyInvocation.MyCommand.Definition)`""
}
if ((Fltmc).Count -eq 3) {
	Write-Host "`n  以管理员权限重新执行`n"
	Invoke-Expression "Start-Process $PROCESS -Verb RunAs"
} else {
	Write-Host "`n  OK`n"
}
pause
