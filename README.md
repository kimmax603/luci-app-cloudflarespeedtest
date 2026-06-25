# luci-app-cloudflarespeedtest

Cloudflare 优选 IP OpenWrt LuCI 插件，集成 Cloudflare DNS 自动更新功能。

## 功能特性

- **Cloudflare IP 测速**：完整支持 [XIU2/CloudflareSpeedTest](https://github.com/XIU2/CloudflareSpeedTest) 所有参数
- **Cloudflare DNS 自动更新**：测速完成后自动通过 Cloudflare API 更新 DNS 记录
- **多 IP 模式**：支持单 IP（最优）和多 IP（前 N 个）两种更新模式
- **定时任务**：支持定时自动测速
- **通知推送**：支持 Telegram（含代理）和 Pushplus 通知
- **代理兼容**：测速时自动处理 PassWall/PassWall2/OpenClash/SSR-Plus/Nikki/Momo/HomeProxy/dae/daed
- **中英双语**：完整的中文界面
- **架构专用**：每个 ipk 内置对应架构的 cfst 二进制，离线可用

## 依赖

- `cfst` - [XIU2/CloudflareSpeedTest](https://github.com/XIU2/CloudflareSpeedTest)（ipk 已内置）
- `curl`
- `openssl-util`
- `ca-bundle`

## 安装方法

### 方法一：ipk 安装（推荐）

```bash
# 1. 安装依赖（通常已预装）
opkg update
opkg install curl openssl-util

# 2. 下载对应架构的 ipk（从 Releases 页面）
# https://github.com/kimmax603/luci-app-cloudflarespeedtest/releases

# 3. 上传并安装
scp luci-app-cloudflarespeedtest_*_arm64.ipk root@路由器IP:/tmp/
ssh root@路由器IP "opkg install /tmp/luci-app-cloudflarespeedtest_*_arm64.ipk"
```

### 方法二：编译安装

```bash
# 将源码放入 OpenWrt 的 package 目录
cp -r luci-app-cloudflarespeedtest /path/to/openwrt/package/

# 编译
cd /path/to/openwrt
make package/luci-app-cloudflarespeedtest/compile V=s
```

## 使用方法

1. 浏览器打开 **服务 → Cloudflare Speed Test**
2. 在 **Basic Settings** 填写基本参数
3. 在 **Cloudflare DNS** 配置 DNS API（可选）
4. 点击 **测速并应用**
5. 测速完成后自动更新 DNS 记录

## 参数说明

### Basic Settings（基本设置）

| 参数 | 默认值 | 说明 |
|------|--------|------|
| Enable | 关闭 | 启用定时任务 |
| IPv6 Mode | 关闭 | 启用 IPv6 测速（禁用 IPv4） |
| Bandwidth (Mbps) | 100 | 宽带速度，自动计算下载下限 |
| Speed Test URL | speed.cloudflare.com | 下载测速地址 |
| Custom Cron | 关闭 | 使用 cron 表达式定时 |
| Cron Expression | - | 如 `0 5 * * *`（每天5点） |
| Hour / Minute | 5:0 | 定时时间 |
| Proxy Plugins | Keep Current | 测速时关闭代理插件 |
| Advanced Settings | 关闭 | 显示高级参数 |

### Advanced Settings（高级设置）

| 参数 | 默认值 | 对应参数 | 说明 |
|------|--------|---------|------|
| Threads | 100 | `-n` | 延迟测速并发线程 (1-1000) |
| Test Count | 4 | `-t` | 每个 IP 测速次数 |
| Port | 443 | `-tp` | 测速端口 |
| HTTPing Mode | TCPing | `-httping` | 切换 HTTPing 可获取地区码 |
| HTTPing Valid Code | 200 | `-httping-code` | HTTPing 有效状态码 |
| Region Filter | 空 | `-cfcolo` | 地区过滤，如 HKG,LAX,NRT |
| Avg Latency Upper | 200ms | `-tl` | 平均延迟上限 |
| Avg Latency Lower | 40ms | `-tll` | 平均延迟下限 |
| Packet Loss Upper | 1.00 | `-tlr` | 丢包率上限 (0.00-1.00) |
| Download Count | 1 | `-dn` | 下载测速 IP 数量 |
| Download Timeout | 10s | `-dt` | 每个 IP 下载超时 |
| Download Speed Lower | 0 | `-sl` | 下载速度下限 MB/s |
| Disable Download | 关闭 | `-dd` | 仅延迟测速 |
| Display Count | 5 | `-p` | 显示结果数量 |
| Test All IPs | 关闭 | `-allip` | 测试范围内每个 IP |
| Debug Mode | 关闭 | `-debug` | 显示详细错误 |
| Custom IP Data | 空 | `-ip` | 指定 IP 段，如 1.1.1.1/24 |

### Cloudflare DNS（DNS 更新设置）

| 参数 | 默认值 | 说明 |
|------|--------|------|
| Enable DNS Update | 关闭 | 启用 DNS 自动更新 |
| Cloudflare Email | 空 | 账户邮箱 |
| API Key | 空 | Global API Key |
| Zone ID | 空 | 域名 Zone ID |
| Domain | 空 | 主域名，如 example.com |
| Subdomain | 空 | 子域名，如 cf → cf.example.com |
| Orange Cloud | 关闭 | 橙色云朵代理（隐藏源站 IP） |
| TTL | Auto | DNS TTL |
| Delete Old Records | 开启 | 更新前删除旧记录 |
| Update Mode | 单IP | 单IP(最优) / 多IP(所有结果) |
| Max Records | 5 | 多IP 模式最大记录数（0=不限制） |

### Notification（通知设置）

| 参数 | 默认值 | 说明 |
|------|--------|------|
| Telegram Notification | 关闭 | 启用 TG 推送 |
| Bot Token | 空 | Telegram Bot Token |
| Chat ID | 空 | Telegram 用户/群组 ID |
| Telegram API Proxy | api.telegram.org | API 代理地址（国内可填反代） |
| Pushplus Notification | 关闭 | 启用 Pushplus 推送 |
| Pushplus Token | 空 | Pushplus Token |

## Cloudflare API 获取方法

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 选择域名 → **Overview** → 底部找到 **Zone ID**
3. **My Profile** → **API Tokens** → **Global API Key** → 查看

## 文件结构

```
luci-app-cloudflarespeedtest/
├── .github/workflows/
│   ├── build-all.yml                # GitHub Actions 编译 ipk
│   └── check-cfst-update.yml        # 每日检测上游 cfst 更新
├── cfst_version.txt                 # 记录当前 cfst 版本
├── Makefile                         # OpenWrt 编译配置
├── README.md
├── luasrc/
│   ├── controller/cloudflarespeedtest.lua
│   ├── model/cbi/cloudflarespeedtest/
│   │   ├── cloudflarespeedtest.lua   # 基本设置页面
│   │   ├── cf_dns.lua               # DNS 设置页面
│   │   └── logread.lua              # 日志页面模型
│   └── view/cloudflarespeedtest/
│       ├── actions.htm              # 操作按钮
│       └── logread.htm              # 日志查看
├── po/
│   └── zh-cn/cloudflarespeedtest.po  # 中文翻译源文件
└── root/
    ├── etc/config/cloudflarespeedtest
    ├── etc/init.d/cloudflarespeedtest
    └── usr/
        ├── bin/cloudflarespeedtest/
        │   ├── cloudflarespeedtest.sh  # 主脚本
        │   └── proxy.sh               # 代理插件管理
        └── share/rpcd/acl.d/luci-app-cloudflarespeedtest.json
```

## 兼容性

- OpenWrt 19.x ~ 25.x
- iStoreOS
- ImmortalWrt
- 所有基于 OpenWrt 的固件

## 注意事项

- 测速时请确保没有代理干扰，否则结果不准确
- Cloudflare Global API Key 拥有最高权限，请妥善保管
- 建议首次使用时手动测试，确认正常后再启用定时
- 如果下载速度为 0，尝试更换测速地址或开启 Debug Mode
- Telegram 无法直连时可填写 API 代理地址

## 致谢

- [XIU2/CloudflareSpeedTest](https://github.com/XIU2/CloudflareSpeedTest) - Cloudflare 优选 IP 工具（cfst 二进制来源）
- [mingxiaoyu/luci-app-cloudflarespeedtest](https://github.com/mingxiaoyu/luci-app-cloudflarespeedtest) - 原版 LuCI 插件
- MiMo Code Agent - 本项目由 AI 辅助开发完成

## License

GPL-3.0
