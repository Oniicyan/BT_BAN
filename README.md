## 介绍
此项目从 [BTN-Collected-Rules](https://github.com/PBH-BTN/BTN-Collected-Rules) 同步黑名单（combine/all.txt）

使用 PowerShell 配置 Windows 防火墙动态关键字（类似 Linux 的 ipset），只对选定程序生效，不影响其他通信活动

不限客户端类型，可能有客户端的启动文件和通信文件不同

虽然不建议，但你也可以为 BT 以外的程序配置过滤规则


## 使用方法

提供自动配置脚本，说明手动配置流程

所有脚本及命令默认在 PowerShell 下以管理员权限执行

至少要求 Windows 10 21H2 左右的版本 （[未确认](https://github.com/MicrosoftDocs/windows-powershell-docs/blob/main/docset/winserver2022-ps/netsecurity/Get-NetFirewallDynamicKeywordAddress.md)）

### 自动配置

#### 启用配置

执行

`iex (irm bt-ban.pages.dev)`

选择需要启用过滤的 BT 应用程序文件即可自动完成配置

多款 BT 应用启用需要执行多次，程序的文件名不能重复

#### 清除配置

执行

`iex (irm bt-ban.pages.dev/unset)`

确认清除的项目后按 Enter 键继续

### 手动配置

#### 配置过滤规则

BT 的特性上，需要同时配置入站与出站规则

```
$BTPATH = '* BT 程序的绝对路径 *' # 
$BTNAME = [System.IO.Path]::GetFileName($BTPATH) # 从绝对路径中提取文件名
$DYKWID = '{3817fa89-3f21-49ca-a4a4-80541ddf7465}' # 可用 New-GUID 生成，注意添加大括号
New-NetFirewallRule -DisplayName "BT_BAN_$BTNAME" -Direction Inbound -Action Block -Program $BTPATH -RemoteDynamicKeywordAddresses $DYKWID
New-NetFirewallRule -DisplayName "BT_BAN_$BTNAME" -Direction Outbound -Action Block -Program $BTPATH -RemoteDynamicKeywordAddresses $DYKWID
```

#### 配置动态关键字

```
$IPLIST = irm https://bt-ban.pages.dev/IPLIST.txt # 示例脚本中默认使用 ZIP 压缩包
New-NetFirewallDynamicKeywordAddress -Id $DYKWID -Keyword "BT_BAN_IPLIST" -Addresses $IPLIST
```

配置动态关键字后即可生效

后续只需要更新动态关键字，无需更改过滤规则

#### 配置任务计划

通过任务计划更新动态关键字的 IP 列表

任务计划执行的命令分为以下几种

- `powershell ""iex (irm $PS1URL -TimeoutSec 30)""`

    从网络上的 PS1 脚本执行更新
  
- `powershell $DIRPATH\IPLIST.ps1`

   从本地的 PS1 脚本执行更新

- `$DIRPATH\IPLIST.cmd`

    从本地的 CMD 脚本执行更新

为隐藏执行更新时的窗口显示，以上命令均通过 VBS 脚本嵌套执行

为显示通知消息，VBS 脚本由当前用户执行

CMD 脚本无法显示通知，因此可以由 SYSTEM 直接执行来隐藏窗口，而无需通过 VBS 脚本嵌套

**IPLIST.ps1 IPLIST.cmd IPLIST.vbs** 可从仓库中查看及下载示例

```
# 创建 VBS 脚本用作隐藏窗口
$VBS = 'createobject("wscript.shell").run "CMD",0'
$CMD = "powershell `"`"iex (irm $PS1URL -TimeoutSec 30)`"`"" # 示例从网络上的 PS1 脚本执行更新
$VBS.Replace("CMD","$CMD") >$env:USERPROFILE\BT_BAN\UPDATE.vbs

# 部分设置项目并非必要
$PRINCIPAL = New-ScheduledTaskPrincipal -UserId (whoami) -RunLevel Highest
$SETTINGS = New-ScheduledTaskSettingsSet -RestartCount 5 -RestartInterval (New-TimeSpan -Seconds 60) -StartWhenAvailable -AllowStartIfOnBatteries
$TRIGGER = New-ScheduledTaskTrigger -Once -At 00:00 -RepetitionInterval (New-TimeSpan -Hours 8) -RandomDelay (New-TimeSpan -Hours 1)
$ACTION = New-ScheduledTaskAction -Execute $env:USERPROFILE\BT_BAN\UPDATE.vbs
$TASK = New-ScheduledTask -Principal $PRINCIPAL -Settings $SETTINGS -Trigger $TRIGGER -Action $ACTION
Register-ScheduledTask BT_BAN_UPDATE -InputObject $TASK
```

##### 说明

- `New-ScheduledTaskPrincipal -UserId (whoami) -RunLevel Highest`

    由当前用户以最高权限执行

- `New-ScheduledTaskSettingsSet -RestartCount 5 -RestartInterval (New-TimeSpan -Seconds 60) -StartWhenAvailable -AllowStartIfOnBatteries`

    尝试重启 5 次，间隔 60 秒；可在错过预定时间后执行；允许使用电池时执行

- `New-ScheduledTaskTrigger -Once -At 00:00 -RepetitionInterval (New-TimeSpan -Hours 8) -RandomDelay (New-TimeSpan -Hours 1)`

    > 在 今日 的 0:00 时 - 触发后，无限期地每隔 08:00:00 重复一次。

- `New-ScheduledTaskAction -Execute $env:USERPROFILE\BT_BAN\UPDATE.vbs`

    执行 `$env:USERPROFILE\BT_BAN\UPDATE.vbs`

- `New-ScheduledTask -Principal $PRINCIPAL -Settings $SETTINGS -Trigger $TRIGGER -Action $ACTION`

    创建包含以上内容的实例

- `Register-ScheduledTask BT_BAN_UPDATE -InputObject $TASK`

    使用以上实例注册名为 `BT_BAN_UPDATE` 的任务计划
