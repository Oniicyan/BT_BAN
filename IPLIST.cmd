@echo off
rem 可自行替换 TXT 文件的 URL 与动态关键字的 GUID
rem 需要弹出通知时，请使用 PS1 脚本
set IPLIST="https://bt-ban.pages.dev/IPLIST.txt"
set DYKWID="{3817fa89-3f21-49ca-a4a4-80541ddf7465}"

powershell.exe "Remove-NetFirewallDynamicKeywordAddress -Id '%DYKWID%'" >nul
powershell.exe "New-NetFirewallDynamicKeywordAddress -Id '%DYKWID%' -Keyword "BT_BAN_IPLIST" -Addresses (irm '%IPLIST%')"