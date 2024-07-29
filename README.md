此项目从 [BTN-Collected-Rules](https://github.com/PBH-BTN/BTN-Collected-Rules) 同步黑名单，并以脚本自动配置 Windows 防火墙动态关键字

不限客户端类型，少数客户端的启动文件和通信文件可能不同

以管理员权限在 PowerShell 下运行

`iex (irm https://gitee.com/oniicyan/bt_ban/raw/master/BT_BAN_SETUP.ps1)`

并选择 BT 应用程序文件即可完成部署

也可自行配置脚本 `BT_BAN.ps1` 与任务计划