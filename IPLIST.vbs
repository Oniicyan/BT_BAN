rem 命令部分如要双引号，请每一端添加两个

rem 从网络上的 PS1 脚本执行更新
createobject("wscript.shell").run "powershell iex (irm bt-ban.pages.dev/IPLIST.ps1 -TimeoutSec 30)",0

rem 从本地的 PS1 脚本执行更新
rem createobject("wscript.shell").run "powershell D:\BT_BAN\IPLIST.ps1",0

rem 从本地的 CMD 脚本执行更新
rem CMD 脚本建议使用 SYSTEM 执行任务计划来隐藏窗口，而不是使用 VBS 脚本
rem createobject("wscript.shell").run "powershell D:\BT_BAN\IPLIST.cmd",0
