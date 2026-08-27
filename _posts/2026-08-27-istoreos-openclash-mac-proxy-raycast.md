---
date: 2026-08-27 22:00:00
title: 本地虚拟机跑 OpenClash 接管整台 Mac 的代理，Raycast 一键切换
layout: post
tags:
   - proxy
   - openclash
   - istoreos
   - raycast
   - macos
categories:
   - 工具
---

浏览器可以靠 PAC 分流，但终端、各种 GUI 应用也想走代理，还希望一个热键全局开关——这是我折腾这套东西的出发点。方案：**iStoreOS 虚拟机里跑 OpenClash，向局域网提供代理服务；Mac 本机不装任何代理客户端**，只用几个 bash 脚本（挂到 Raycast）管理系统代理和环境变量。干净、可随时拆。

## 架构

```
Mac（宿主机）
 ├─ 系统代理 / 终端 env ──▶ <VM_IP>:7890 (HTTP) / :7891 (SOCKS)
 └─ PAC 规则模式 ─────────▶ OpenClash 生成的 PAC 地址
```

虚拟机用共享/NAT 网络，Mac 和 VM 之间是私有网段，代理端口只暴露在这条内网里。

## 虚拟机侧：iStoreOS + OpenClash

### 1. UTM + 镜像

- 虚拟机：[UTM](https://utmapp.com/)（免费，Apple Silicon / Intel 通用），`brew install --cask utm` 也行
- 镜像：[fw.koolcenter.com/iStoreOS](https://fw.koolcenter.com/iStoreOS/)，Apple Silicon 选 `aarch64` EFI 版，Intel 选 `x86_64`

新建虚拟机时选 **Virtualize**（ARM Mac + aarch64 镜像），内存 1–2G、核心 1–2 个足够，网络保持默认 Shared Network。

### 2. 网络

把 iStoreOS 的 LAN 口改成 **DHCP 客户端**（或固定 IP，比如共享网段的 `.2`），并**关掉它自带的 DHCP 服务器**——否则会和宿主的共享网络 DHCP 打架。默认 `root` / `password` 登录后改密码，LuCI 就是 `http://<VM_IP>`。

### 3. 装 OpenClash

- 手动装 ipk（我用的）：[Are-u-ok Releases](https://github.com/bcseputetto/Are-u-ok/releases)，挑和 iStoreOS 版本对应的 tag（如 `iStoreOS_24.10`），下载后 LuCI → 系统 → 软件包 → 上传安装
- 或者 LuCI 侧边栏的 iStore 商店里装，或 [OpenClash 官方 Releases](https://github.com/vernesong/OpenClash/releases)

### 4. 关键设置

1. 配置文件管理里加上你的订阅
2. 端口：HTTP 7890 / SOCKS 7891（记下来，Mac 侧脚本要用）
3. **允许局域网连接：开启**
4. **代理认证：留空**。这是第一个坑——开了认证的话，TCP 端口探测是通的，但所有真实请求都会 407，表现就是"时好时坏"

### 5. 验证

```bash
nc -z -G 2 <VM_IP> 7890 && echo ok
curl -x http://<VM_IP>:7890 https://www.google.com -o /dev/null -w '%{http_code}\n'
```

## Mac 侧：Raycast Script Commands

脚本都放在 [github.com/zouchao/raycast-proxy](https://github.com/zouchao/raycast-proxy)，四个命令：

| 命令 | 作用 |
|---|---|
| Toggle Proxy | 一键开关系统代理（HTTP/HTTPS/SOCKS 全设），同步终端 env |
| Toggle PAC Mode | 系统代理切到 OpenClash 的 PAC 规则模式 |
| Proxy Status | 当前模式 / VM 可达性 / env 状态 |
| Chrome with Proxy | 带 `--proxy-server` 启动 Chrome（下面会讲为什么需要它） |

在 Raycast 设置里把目录加进 Script Commands，给 Toggle Proxy 绑个热键，完事。

核心就是 `networksetup` 三件套加 bypass 名单：

```bash
networksetup -setwebproxy        "$svc" "$VM_IP" 7890 off
networksetup -setsecurewebproxy  "$svc" "$VM_IP" 7890 off
networksetup -setsocksfirewallproxy "$svc" "$VM_IP" 7891 off
networksetup -setproxybypassdomains "$svc" localhost 127.0.0.1 '*.local' '10.*' '192.168.*' '172.16.*'
```

bypass 名单保证内网、本地流量直连，不进代理。

终端程序（curl/git/npm/pip）是不读系统代理的，所以脚本开关时会同步写一个 `~/.config/proxy-env.sh`（开 = export `http_proxy`/`https_proxy`/`all_proxy`/`no_proxy`，关 = unset），`.zshrc` 里加一行 source，新终端就自动继承代理状态。

另外两个细节：VM 端口不可达时脚本会**拒绝开启**并提示，避免设一个死代理让你误判网络坏了；global 和 PAC 模式互斥，开一个自动关另一个。

## 坑位记录

### 407 Proxy Authentication Required

端口通、请求全挂，curl Verbose 看到 407 —— OpenClash 侧开了代理认证。关掉，或者给所有客户端配账密。

### 连上企业 VPN 后，系统代理对 GUI 应用"消失"

这是最隐蔽的一个。以 GlobalProtect 为例：VPN 连上后它会注册一个隐藏的网络服务并抢占 **primary service** 位置，而 macOS 应用读的系统代理配置取自 primary service——我们在 Wi-Fi 服务上设的代理就被无视了。`networksetup` 改不到这个隐藏服务（它不在服务列表里），底层动态 store 又归 configd 管，外部写入会被实时重建覆盖。

表现：终端（走 env）一切正常，Chrome 等 GUI 应用却像没设代理一样。

务实的解法：Chrome 用启动参数显式指定代理，绕开系统配置：

```bash
open -na "Google Chrome" --args \
  --proxy-server="http=<VM_IP>:7890;https=<VM_IP>:7890;socks=<VM_IP>:7891" \
  --proxy-bypass-list="localhost;127.0.0.1;*.local;10.*;192.168.*;172.16.*"
```

注意要先完全退出 Chrome 再这样启动。仓库里的 `chrome-proxy.sh` / `chromep` 别名就是干这个的。

### "局域网拦、隧道里通"的出口检测现象

有个有意思的观察：某些受管网络环境下，代理节点流量在局域网里会被出口检测拦掉（国内直连正常、走节点超时）；而连上 VPN 后，同样的节点流量因为封装在隧道里反而畅通。如果你也遇到"节点时好时坏"，可以先确认自己处于哪种网络状态，再下结论。

## 参考

- [iStoreOS 固件](https://fw.koolcenter.com/iStoreOS/)
- [OpenClash](https://github.com/vernesong/OpenClash) / [Are-u-ok（iStoreOS 适配包）](https://github.com/bcseputetto/Are-u-ok)
- [UTM](https://utmapp.com/)
- 本文配套脚本：[zouchao/raycast-proxy](https://github.com/zouchao/raycast-proxy)
