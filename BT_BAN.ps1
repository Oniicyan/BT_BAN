$IRMURL = https://bt-ban.pages.dev/IPLIST.zip

$BTPATH = $args[0]
$BTNAME = [System.IO.Path]::GetFileName($BTPATH)
$DYKWID = '{3817fa89-3f21-49ca-a4a4-80541ddf7465}'

Invoke-WebRequest -OutFile "$env:temp\BT_BAN_IPLIST.zip" $IRMURL
Expand-Archive -Force -Path $env:temp\BT_BAN_IPLIST.zip -DestinationPath $env:temp\BT_BAN
$IPLIST = Get-Content $env:temp\BT_BAN\IPLIST.txt

$RULES = Get-NetFirewallRule -DisplayName "BT_BAN_$BTNAME" -ErrorAction Ignore

$SET_RULES = {
	Remove-NetFirewallRule -DisplayName "BT_BAN_$BTNAME" -ErrorAction Ignore
	New-NetFirewallRule -DisplayName "BT_BAN_$BTNAME" -Direction Inbound -Action Block -Program $BTPATH -RemoteDynamicKeywordAddresses $DYKWID | Out-Null
	New-NetFirewallRule -DisplayName "BT_BAN_$BTNAME" -Direction Outbound -Action Block -Program $BTPATH -RemoteDynamicKeywordAddresses $DYKWID | Out-Null
}

if (($RULES | Out-String -Stream | Select-String -SimpleMatch $DYKWID).Count -ne 2) {
	&$SET_RULES
}
elseif (($RULES | Get-NetFirewallApplicationFilter | Out-String -Stream | Select-String -SimpleMatch $BTPATH).Count -ne 2) {
	&$SET_RULES
}
elseif (($RULES | Out-String -Stream | Select-String -SimpleMatch Inbound).Count -ne 1) {
	&$SET_RULES
}

if (Get-NetFirewallDynamicKeywordAddress -Id $DYKWID -ErrorAction Ignore) {
	Update-NetFirewallDynamicKeywordAddress -Id $DYKWID -Addresses $IPLIST | Out-Null
}
else {
	New-NetFirewallDynamicKeywordAddress -Id $DYKWID -Keyword "BT_BAN_IPLIST" -Addresses $IPLIST | Out-Null
}
