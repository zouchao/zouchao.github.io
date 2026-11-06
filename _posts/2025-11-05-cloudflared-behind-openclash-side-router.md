---
date: 2025-11-05 16:00:00 +0800
title: 旁路由下的 cloudflared：一次 TLS handshake EOF / i/o timeout 排查
layout: post
tags:
    - Cloudflare
    - OpenClash
    - Clash
    - 网络
    - Docker
categories:
    - 工具
image:
    path: /assets/img/posts/cloudflared-behind-openclash-side-router/cover.png
    alt: cloudflared 日志从 fake-ip 报错到 i/o timeout，最终加静态路由让隧道流量绕开 OpenClash 旁路由直走主路由
---

家里飞牛 NAS 上用 Docker 跑 Cloudflare Tunnel，某天突然连不上了，日志里刷满了 `TLS handshake with edge error`。这篇按排查的顺序记录：每一步看到了什么现象、当时怎么判断的，其中有两次判断是错的，最后怎么修好的。

先说结论：**问题出在 NAS 经过 OpenClash 旁路由的那条路径上，跟运营商和代理节点都没关系**。最后的解决办法是在 NAS 上给 Cloudflare 隧道 edge 的网段单独加一条路由，直接走主路由；NAS 的其他流量照常走旁路由。

> 文中的 token 都做了脱敏。

## 环境

```text
                ┌──────────── 主路由 192.168.31.1 ──── 宽带
                │
NAS 192.168.31.36 ──默认网关──> OpenClash 旁路由（iStoreOS）
  ├─ cloudflared   （Cloudflare Tunnel，把 NAS 服务暴露到公网）
  └─ OpenClaw      （需要代理访问 OpenAI 等接口）
```

OpenClash 的订阅由我自己部署的 [subconverter](https://github.com/tindy2013/subconverter) 生成，规则集也是自己维护的。cloudflared 的启动方式是最常见的一行命令：

```bash
docker run cloudflare/cloudflared:latest tunnel --no-autoupdate run --token xxxx
```

先补充一点背景：cloudflared 连接 Cloudflare edge（`region1/2.v2.argotunnel.com`，IP 段是 `198.41.192.0/24` 和 `198.41.200.0/24`）用的是 **7844 端口**，协议是 QUIC（UDP）或 HTTP2（TCP），不是 443。后面好几处判断都和这个有关。

## 第一阶段：`ip=198.18.x.x` 和 EOF

```text
ERR Unable to establish connection with Cloudflare edge error="TLS handshake with edge error: EOF" connIndex=0 event=0 ip=198.18.0.152
INF Retrying connection in up to 1m4s connIndex=0 event=0 ip=198.18.0.15
```

关键在 `ip=` 字段。**`198.18.0.0/15` 是 Clash fake-ip 模式使用的地址段**，并不是 Cloudflare 的真实 IP。也就是说：

1. NAS 的 DNS 由 OpenClash 接管，解析 `argotunnel.com` 时拿到的是 fake-ip；
2. 连接被 OpenClash 接管后按规则匹配。我在自己的规则集 `Global.list` 里早就把 `argotunnel.com` 和 `cftunnel.com` 加进了代理组；
3. 流量被送到机场节点，而节点不放行 7844 端口（也可能是转发不了），于是 TLS 握手直接被对端断开，返回 EOF。

第一版修复做了两件事：

- 把这两个域名加进 `fake-ip-filter`，让 cloudflared 能解析到真实 IP；
- 新建 `CloudflareTunnel.list`，把隧道域名和 IP 段放进去，规则组指向 `🎯 全球直连`，并且排在所有代理规则前面。

```text
DOMAIN-SUFFIX,argotunnel.com
DOMAIN-SUFFIX,cftunnel.com
IP-CIDR,198.41.192.0/24,no-resolve
IP-CIDR,198.41.200.0/24,no-resolve
IP-CIDR6,2606:4700:a0::/44,no-resolve
IP-CIDR6,2606:4700:a8::/44,no-resolve
```

## 第二阶段：真实 IP 了，但 i/o timeout

更新订阅以后，日志变了：

```text
ERR Serve tunnel error error="TLS handshake with edge error: read tcp 192.168.31.36:34048->198.41.192.107:7844: i/o timeout" ip=198.41.192.107
```

`ip=` 已经是 `198.41.x.x`，fake-ip 的问题解决了。现在的报错是 `read tcp ... i/o timeout`，说明 TCP 连接已经建立，但 TLS 握手阶段读不到任何回应。

**错误判断一：运营商阻断了 7844 端口。** 国内宽带干扰 7844 端口确实很常见，于是我又加了一个 `☁️ CF Tunnel` 分组，默认走代理节点，同时把 `DST-PORT,7844` 也加了进去。后面会看到，这个方向完全错了。

## 第三阶段：nc 通、curl 通，为什么容器不通？

在 NAS 上测试了两样东西，结果都是通的：

```bash
$ nc -v 198.41.192.167 7844
Connection to 198.41.192.167 7844 port [tcp/*] succeeded!

$ curl https://api.cloudflare.com/client/v4/user/tokens/verify -H "Authorization: Bearer ***"
{"result":{"status":"active"},"success":true, ...}
```

不过这两个测试都说明不了问题：

| 测试 | 实际验证了什么 | 和隧道的差别 |
|---|---|---|
| `nc` | 只验证 TCP 三次握手 | 报错发生在 TCP 建立之后的 TLS 阶段；而且如果前面有透明代理，`nc` 连上的其实是本地的 Clash |
| `curl api.cloudflare.com` | 443 端口上的 API 服务 | 隧道走 7844 端口，连的是另一组 edge；而且 API Token 和 Tunnel Token 是两个东西 |

**要测 TLS，就得用 `openssl s_client`：**

```bash
openssl s_client -connect 198.41.192.167:7844 -servername region1.v2.argotunnel.com </dev/null
```

第一次测试**成功了**，拿到了 `*.cftunnel.com` 的 Origin 证书，协议是 TLSv1.3。输出里的 `unable to verify the first certificate` 是正常的，因为 Origin CA 不在系统根证书里，cloudflared 自带了这个 CA。最后那个 `alert bad certificate` 是握手完成后 edge 主动断开的。openssl 只是个普通的 TLS 客户端，并不懂隧道协议，被断开不影响"TLS 能通"这个结论。

**错误判断二：DPI 按 SNI 识别隧道。** cloudflared 实际发出的 SNI 是 `h2.cftunnel.com`，ALPN 是 `h2`。我换成这组参数再测，结果超时了；拿 `example.com` 做对照，也超时了，两次都是卡住很久之后才 EOF。看起来像是按 SNI 阻断，但对照组也失败，这个结论站不住。

最后用同一个 SNI 连续测了 3 次：

```bash
for i in 1 2 3; do
  timeout 15 openssl s_client -connect 198.41.192.167:7844 \
    -servername region1.v2.argotunnel.com </dev/null 2>&1 \
    | grep -E "subject=|unexpected eof|Cipher is"
  echo "---"
done
```

```text
Terminated
---
Terminated
---
subject=O = "CloudFlare, Inc.", OU = CloudFlare Origin CA, CN = CloudFlare Origin Certificate
New, TLSv1.3, Cipher is TLS_AES_128_GCM_SHA256
---
```

**同样的请求，3 次只成功 1 次**。所以不是按内容阻断，而是这条路径本身就不稳定。

## 定位：绕开旁路由就好了

既然怀疑是路径的问题，就做一个最直接的对照：把 NAS 的网关从旁路由改回主路由。**隧道马上就连上了。**

这样一来，前面的现象都能解释了：

- 宽带到 Cloudflare 7844 端口本身是通的，"运营商阻断"不成立；
- 第一阶段是 fake-ip 把流量送进了代理节点，节点不支持 7844；
- 第二阶段虽然规则已经是 DIRECT，但流量还是要先经过旁路由转发一次，握手就时好时坏。

至于旁路由具体是哪里出了问题，我没有进一步验证。旁路由场景下常见的原因有：来回路径不对称（去程经过旁路由，回程从主路由直接回来）、MTU 不合适、透明代理接管了 TCP 连接。

## 最终方案：只让隧道流量绕开旁路由

NAS 不能完全不走旁路由，因为上面的 OpenClaw 需要代理才能访问 OpenAI 等接口。OpenClash 的「访问控制」是按来源 IP 放行的，而 cloudflared 和 OpenClaw 都从 `192.168.31.36` 发出，放行这个 IP，OpenClaw 也就不走代理了。

所以改为**在 NAS 上按目的地址加路由**：默认网关继续指向旁路由，只有发往隧道 edge 网段的流量直接交给主路由。不管容器是 bridge 模式还是 host 模式，出站流量最终都按宿主机的路由表走，所以对 cloudflared 都有效。

### 1. 先临时验证

```bash
sudo ip route add 198.41.192.0/24 via 192.168.31.1
sudo ip route add 198.41.200.0/24 via 192.168.31.1
ip route get 198.41.192.167      # 应显示 via 192.168.31.1
```

cloudflared 也顺便调整一下：DNS 直接指定公共 DNS，避免拿到 fake-ip；只连 IPv4 edge，因为上面只加了 v4 路由；协议固定为 HTTP2，走 TCP，比 QUIC 更稳。

```bash
docker rm -f cloudflared
docker run -d --name cloudflared --restart unless-stopped \
  --dns 223.5.5.5 --dns 119.29.29.29 \
  cloudflare/cloudflared:latest tunnel --no-autoupdate \
  --edge-ip-version 4 --protocol http2 run --token xxxx

docker logs -f cloudflared       # 等出现 Registered tunnel connection
```

### 2. 在飞牛 fnOS 上持久化

fnOS 基于 Debian，用的是 systemd。需要注意的是，在 fnOS 界面上改网络、网卡断开重连或者 DHCP 续租时，手动加的路由可能会被清掉。所以除了开机执行，还要在网络变化时把路由补回来。

先写一个脚本：

```bash
sudo tee /usr/local/bin/cf-tunnel-route.sh >/dev/null <<'EOF'
#!/bin/sh
# Cloudflare Tunnel edge 绕过旁路由，直走主路由
GW=192.168.31.1
for net in 198.41.192.0/24 198.41.200.0/24; do
  ip route replace "$net" via "$GW"
done
EOF
sudo chmod +x /usr/local/bin/cf-tunnel-route.sh
```

开机时执行：

```bash
sudo tee /etc/systemd/system/cf-tunnel-route.service >/dev/null <<'EOF'
[Unit]
Description=Route Cloudflare Tunnel edge via main router
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/cf-tunnel-route.sh

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now cf-tunnel-route
```

网络变化后自动补上（`systemctl is-active NetworkManager` 显示 `active` 时才需要）：

```bash
sudo tee /etc/NetworkManager/dispatcher.d/90-cf-tunnel-route >/dev/null <<'EOF'
#!/bin/sh
case "$2" in up|dhcp4-change|connectivity-change) /usr/local/bin/cf-tunnel-route.sh ;; esac
EOF
sudo chmod +x /etc/NetworkManager/dispatcher.d/90-cf-tunnel-route
```

最后重启一次 NAS 再检查：

```bash
ip route get 198.41.192.167     # via 192.168.31.1（主路由）
ip route get 104.18.0.1         # 其他地址仍走旁路由
```

## 小结

- **先看 `ip=` 字段**：`198.18.x.x` 说明拿到的是 Clash 的 fake-ip，流量被代理接管了，是真实 IP 才说明在直连。
- **`nc` 通不代表服务通**：`nc` 只验证 TCP；要测 TLS 用 `openssl s_client`，而且最好**重复测几次**。只测一次的结果，很容易让你得出错误的结论。
- **cloudflared 走的是 7844 端口，不是 443**：用 443 上的 API 测试来判断隧道能不能通，没有参考价值。
- **最有效的一步是做对照实验**：换一条网络路径直接测。我在"运营商阻断"和"SNI 阻断"上花了不少时间，其实把网关切回主路由一试就定位了问题。
- **旁路由环境下想让某个服务直连**：如果没法按来源设备区分，就按目的地址加静态路由，比在代理规则里加 DIRECT 更彻底，因为流量根本不会经过旁路由。
