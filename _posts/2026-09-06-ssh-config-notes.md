---
date: 2026-09-06 14:20:00 +0800
title: 从我的 ~/.ssh 目录说起：SSH 认证、多账号 Git 与端口转发
layout: post
tags:
    - SSH
    - Git
    - macOS
    - 网络
    - 安全
categories:
    - 工具
---

`~/.ssh` 是那种配好就再也不看的目录——直到某天换机器、加账号，或者 git push 突然开始报 `Permission denied (publickey)`，才会发现里面躺着一堆自己都认不出来的文件。这几天整理密钥，顺手把自己的配置逐行过了一遍，发现里面其实塞了不少 SSH 的典型用法：443 端口连 GitHub、一台机器三个 GitHub 账号、云效、走 Tailscale 的内网 Git 服务、还有把云上内网的 MySQL 转发到本地。

这篇就当一份"以真实配置为线索"的 SSH 科普：先讲清楚 SSH 认证到底在干什么，再逐段解读 config，最后补上我**还没配但值得知道**的部分——agent、连接复用、跳板机、代理。

> 文中的 IP、邮箱，以及和公司相关的密钥文件名、Host 别名都做了脱敏；示例里的公网 IP 用的是文档保留段 `203.0.113.0/24`。

## 先盘点一下目录

```bash
$ ls -la ~/.ssh
-rw-r--r--  config
-rw-------  id_rsa                       # 个人 GitHub（RSA）
-rw-r--r--  id_rsa.pub
-rw-------  id_rsa_work                  # 公司 GitHub（其实是 ed25519）
-rw-r--r--  id_rsa_work.pub
-rw-------  id_rsa_aliyun                # 阿里云效（其实是 ed25519）
-rw-r--r--  id_rsa_aliyun.pub
-rw-------  id_rsa_alt                   # 另一个 GitHub 账号（RSA）
-rw-r--r--  id_rsa_alt.pub
-rw-------  github_xxx_id_ed25519        # 遗留密钥，没有 .pub，config 里也注释掉了
-rw-------  known_hosts
-rw-------  known_hosts.old
drwx------  agent/                       # 某个工具另起的 ssh-agent 的 socket
```

三个观察：

1. **文件名和算法完全无关。** `id_rsa_work`、`id_rsa_aliyun` 里装的其实是 ed25519 密钥——只是当初生成时顺手沿用了 `id_rsa_` 前缀。文件名就是个标签，SSH 认的是文件内容。想知道一把公钥到底是什么算法，看第一列：

   ```bash
   $ awk '{print $1, $NF}' ~/.ssh/*.pub
   ssh-rsa me@personal
   ssh-ed25519 me@personal
   ssh-ed25519 me@work
   ```

2. **权限是硬要求。** 目录 `700`、私钥 `600`。服务端 sshd 默认开 `StrictModes`，私钥要是变成 `644`，很多配置下会直接被拒绝。

3. **有该清理的东西。** 那把没有 `.pub` 的 `github_xxx_id_ed25519` 是某次实验的遗留，config 里注释掉了但文件还在。密钥这东西，"不知道还有没有用"本身就是风险，定期盘点一次比较好。

## SSH 认证到底在干什么

日常用 SSH 干两件事：**登录远程机器**，和**通过 git 协议推拉代码**（`git@github.com:xxx/yyy.git` 本质就是"以 git 用户 SSH 登录 github.com，然后跑 `git-upload-pack`"）。两件事走的是同一套认证。

密码认证的问题很好理解：密码要通过网络传过去，服务器要存它，而且人可以复用同一个密码。公钥认证换了个思路——**非对称加密**：

- 私钥留在本地，永远不出门；
- 公钥放到服务器的 `~/.ssh/authorized_keys` 里（GitHub 就是网页上"SSH keys"那一栏）；
- 连接时，服务器用一段随机数据"出题"，客户端用私钥签名作答，服务器用公钥验签。答对了就放行。

整个过程私钥没有被发送过，公钥公开了也无所谓——它只能验签，不能签名。

### known_hosts：反向认证服务器

上面说的是"客户端证明自己是自己"，但还有个对称的问题：**你怎么知道对面真的是 github.com，而不是中间人？** 答案在 `known_hosts` 里，它记录了你见过的每台服务器的主机公钥指纹。

第一次连接时会看到：

```text
The authenticity of host 'github.com (20.205.243.166)' can't be established.
ED25519 key fingerprint is SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

这叫 TOFU（Trust On First Use，首次使用即信任）：你按下 yes，指纹就被写进 `known_hosts`，以后再连同一台机器，指纹对不上就会大声报警：

```text
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```

这个警告**不要无脑 yes 过去**。它有两种可能：服务器重装/换密钥了（正常），或者你真的被中间人了（严重）。确认过之后，用下面的命令删掉旧记录，而不是手工编辑文件：

```bash
ssh-keygen -R github.com
```

顺便说，`known_hosts.old` 就是 `ssh-keygen -R` 修改文件时留下的备份，我的目录里那个 18KB 的 `.old` 说明这事发生过不止一次。

## 密钥怎么选：一把钥匙一个身份

生成新密钥，现在没什么理由不用 ed25519：密钥短（68 字符的公钥 vs RSA 的 700+）、签名快、没有"选错参数就完蛋"的坑：

```bash
ssh-keygen -t ed25519 -C "me@work" -f ~/.ssh/id_ed25519_work
```

RSA 也没到不能用的地步（GitHub 至今仍支持），但要用就至少 3072 位。我的个人 GitHub 和马甲号还是当年的 RSA，属于"能用就先不动"。

比算法更重要的是**管理原则**：

- **一把钥匙一个身份。** 个人 GitHub、公司 GitHub、云效，各一把。这样某个平台泄露（或者你离职）时，撤销的是单独一把钥匙，不会牵连其他账号；`config` 里也能明确地把身份和平台绑死。
- **给私钥设 passphrase。** 私钥文件被偷走 ≠ 立刻沦陷，前提是它加了密。担心每次输入麻烦，交给 agent 处理（后面讲）。
- **comment 写清楚用途。** `-C` 那个注释是给你自己看的，写 `me@work` 比写主机名有用得多——半年后在 GitHub 的 key 列表里，你能一眼认出哪把是哪台机器的。

## ~/.ssh/config：给每个连接建档

没有 config 之前，连服务器要背一串参数：

```bash
ssh -i ~/.ssh/id_ed25519_work -p 2222 git@100.64.0.10
```

config 的作用就是把这些参数固化成"别名 + 档案"：

```ini
# ~/.ssh/config
Host mygit              # 别名，命令行里敲的就是它
  HostName 100.64.0.10  # 真正连接的地址
  Port 2222
  User git
  IdentityFile ~/.ssh/id_ed25519_work
```

之后 `ssh mygit`、`git clone mygit:org/repo.git` 就够了。

有一条规则值得单独记住：**对同一个参数，SSH 采用"第一次出现的值"（first-match-wins）**。一个 Host 块没写的参数，会继续往下找其他匹配块。这带来两个推论：

- 具体的 Host 块要写在前面，通配的 `Host *` 写在最后；
- 想知道某次连接最终生效的配置是什么，别靠猜，直接问 SSH：

  ```bash
  $ ssh -G tx | grep -E 'hostname|port|user|identityfile'
  ```

下面按我 config 里的实际内容逐段过。

### Include：把机器生成的配置拼进来

```ini
Include ~/.orbstack/ssh/config
```

`Include` 支持通配符，可以拆分成多个文件。我这里包含的是 OrbStack 自动生成的配置（它给每个容器/虚拟机分配了 `ssh orb` 之类的入口）。注意文件头写着 *AUTO-GENERATED, DO NOT EDIT*——这类"工具托管"的配置用 Include 拼进来是最干净的做法，自己的手写内容和工具的自动内容互不污染。

### 用 443 端口连 GitHub

```ini
Host github.com
  Hostname ssh.github.com
  Port 443
  User git
  GSSAPIAuthentication no
  IdentityFile ~/.ssh/id_rsa
```

这段的别名就是 `github.com` 本身，所以**所有仓库地址不用改一个字**，`git@github.com:me/repo.git` 会静默地改走 `ssh.github.com:443`。

为什么这么做：不少公司网络、酒店 WiFi、某些运营商会封锁出站的 22 端口，症状是 `ssh -T git@github.com` 卡住直到超时。GitHub 为此专门提供了 SSH over 443 的入口 `ssh.github.com`。443 是 HTTPS 的端口，几乎不会被封。验证一下：

```bash
$ ssh -T -p 443 git@ssh.github.com
Hi zouchao! You've successfully authenticated, but GitHub does not provide shell access.
```

最后那句 "does not provide shell access" 是正常现象——GitHub 的 SSH 只服务 git 操作，不给你 shell。

`GSSAPIAuthentication no` 是个小优化：客户端默认会尝试 GSSAPI（Kerberos）认证，在没配 Kerberos 的普通环境下纯属浪费一轮往返，某些网络下还会造成明显的连接延迟。我的 `Host *` 块里也重复设了一次，属于"被坑过所以到处关"。

### 一台机器，三个 GitHub 账号

多账号的核心手法：**为每个账号造一个 Host 别名，各自绑定各自的密钥**。

```ini
Host github.com-work            # 公司账号
  HostName ssh.github.com
  Port 443
  User git
  IdentityFile ~/.ssh/id_rsa_work
  IdentitiesOnly yes

Host alt.github.com             # 另一个账号
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_rsa_alt
```

用的时候，把仓库地址里的 `github.com` 换成别名：

```bash
git clone git@github.com-work:company/repo.git
ssh -T git@github.com-work      # 验证：Hi work-user!
```

注意 `alt.github.com` 这个别名——它长得像个真实域名，其实**根本不需要能被 DNS 解析**，因为 `HostName github.com` 会告诉 SSH 真正该连哪儿。别名只是 config 里的查找键，随便起。（这个块当年没跟着改成 443 端口，在封 22 的网络下会连不上，属于该顺手统一的遗留问题。）

这里最关键的一行是 `IdentitiesOnly yes`。默认情况下，SSH 会把 agent 里加载的**所有**密钥挨个递给服务器试。多账号场景下这有两个恶果：

- 公司密钥可能先被递上去，于是你以错误账号的身份通过认证，push 到个人仓库时报权限错误——**串号**；
- 密钥多了，试错次数超过服务端 `MaxAuthTries`（默认 6），直接收到 `Too many authentication failures`。

`IdentitiesOnly yes` 的意思是"只用我在 `IdentityFile` 里明确指定的密钥，agent 里其他的别碰"。多账号配置里，这一行建议每块都写上。

### 云厂商的代码托管

```ini
Host codeup.aliyun.com
  User git
  IdentityFile ~/.ssh/id_rsa_aliyun
  IdentitiesOnly yes
```

阿里云效（Codeup）和 GitHub 一个套路，单独一把密钥即可。国内的 Gitee、Coding、GitLab 自建实例都同理。

### 走 Tailscale 的内网 Git 服务

```ini
Host github.com-local
  HostName 100.64.0.10    # Tailscale 分配的地址
  Port 2222
  User git
  IdentityFile ~/.ssh/id_rsa_work
```

`100.64.0.0/10` 是运营商级 NAT 的保留段，Tailscale 用它给组网内的每台设备发地址。家里那台跑自建 Git 服务的机器，因此在任何地方都像是"在同一个内网"，不需要公网 IP，也不需要路由器上做端口映射。SSH config 里直接写这个地址，等于把"内网服务"和"公网服务"用同一套语法管理起来。

### Host *：全局兜底

```ini
Host *
  ServerAliveInterval 60
  ServerAliveCountMax 30
  GSSAPIAuthentication no
```

`Host *` 匹配所有连接，用来放全局默认值：

- `ServerAliveInterval 60`：每 60 秒给服务器发一个心跳包。挂着的 SSH 会话被 NAT/防火墙因"空闲"掐掉，是最常见的"过一会儿就断"的原因，这行专治它。
- `ServerAliveCountMax 30`：连续 30 次心跳没回应才断开，也就是容忍 30 分钟的网络中断（合上笔记本去开会，回来会话还在）。

前面说过 first-match-wins，所以严格讲这个块应该放在文件**最末尾**——我的 config 里它夹在中间，后面的 `tx`、`3b-admin` 块没有和它冲突的参数所以没出问题，但这是运气而不是设计。整理时值得挪到最后一行。

## 端口转发：把远程内网的服务拉到本地

```ini
Host tx
  HostName 203.0.113.10
  User root
  LocalForward 16379 172.16.0.10:6379
  LocalForward 13306 172.16.0.10:3306
  IdentityFile ~/.ssh/id_rsa
```

云上服务器通常挂在私有网络里，Redis 和 MySQL 只监听内网地址 `172.16.0.10`，公网根本摸不到——也不应该摸到。`LocalForward` 的做法是：在 SSH 这条加密隧道里开个洞，把**本地的 16379 端口**转发到**从服务器视角能看到的 172.16.0.10:6379**。

```text
本地 redis-cli -p 16379  →  localhost:16379  ══SSH 隧道══>  tx  →  172.16.0.10:6379
```

于是 `ssh tx` 之后，本地跑 `redis-cli -p 16379` 或用 DBeaver 连 `127.0.0.1:13306`，操作的就是云上的内网服务。数据库不暴露公网，流量全程加密，权限跟着 SSH 走。等价的命令行写法是 `ssh -L 16379:172.16.0.10:6379 tx`，写进 config 的好处是不用每次背。

转发一共有三个方向，顺便记一下：

| 写法 | 方向 | 典型场景 |
| --- | --- | --- |
| `-L` / `LocalForward` | 远程服务 → 本地端口 | 连内网数据库、访问远端的管理后台 |
| `-R` / `RemoteForward` | 本地服务 → 远程端口 | 把本地开发机的服务暴露给服务器（webhook 调试） |
| `-D` / `DynamicForward` | 本地 SOCKS 代理 | `ssh -D 1080 tx`，把浏览器/命令行流量经由服务器出海 |

`-D` 值得多说一句：它让 SSH 临时变成一个 SOCKS5 代理，任何支持 SOCKS 的工具都能借这条加密隧道上网。不过它是"整条连接走服务器"，不如按需转发的 `-L` 精确，也别忘了这台服务器是你在付费和负责的。

## 我还没配、但值得知道的

下面这些是我 config 里缺席的部分。有的是"目前没遇到痛点"，有的是"确实该补"。

### ssh-agent 与 macOS 钥匙串

给私钥设了 passphrase 之后，每次 git 操作都要输一遍，很快你就会想把它去掉——**别**。正确做法是让 agent 代劳：agent 是一个持有已解锁私钥的后台进程，密钥本身仍然不落明文。

macOS 上只要三行：

```ini
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

再把 passphrase 存进钥匙串（一次就够）：

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

之后重启也不用管，SSH 会自动从 Keychain 取 passphrase 解锁并塞进 agent。`ssh-add -l` 可以看当前 agent 里有哪些密钥——多账号场景下如果发现里面躺着一堆，那就更需要前面说的 `IdentitiesOnly yes`。

反过来，agent 里**没有**该有的一把，也是经典故障源。很多年前我就踩过：`git push` 报 `Agent admitted failure to sign using the key` 然后 `Permission denied (publickey)`，原因是密钥被重新生成过、agent 里还留着旧的，一句 `ssh-add` 就好了（见[《解决 Agent admitted failure to sign using the key 的方法》]({% post_url 2013-06-02-ssh-failure-sign-key %})）。十几年过去了，这个报错的排查思路没变：先看 agent 里有什么，再看 config 指了什么。

### ControlMaster：连接复用

对同一个主机反复 `ssh`（或者 git 频繁 push/pull），每次都要重走 TCP + 密钥交换。开启复用之后，第一条连接建好，后续连接直接搭它的便车：

```ini
Host *
  ControlMaster auto
  ControlPath ~/.ssh/cm-%r@%h-%p
  ControlPersist 10m
```

`ControlPersist 10m` 表示主连接退出后再保留 10 分钟。注意 macOS 上 socket 路径有 104 字符的长度限制，`ControlPath` 别写太长。（顺便一提，macOS 本来就有一个 launchd 托管的 ssh-agent 在跑，`echo $SSH_AUTH_SOCK` 能看到；我目录里 `agent/` 下那个 socket 是别的工具又起的一个 agent，两个 agent 互不相通，排查"密钥明明加了却不生效"时值得先看一眼 `ssh-add -l` 问的是哪一个。）

### ProxyJump：跳板机

现在的 `tx` 有公网 IP，所以能直连。但生产环境常见的拓扑是：只有堡垒机能从外网访问，业务机器藏在它后面。传统做法是先 ssh 上堡垒机再 ssh 一次，复制粘贴来复制粘贴去；现代写法是 `-J`：

```bash
ssh -J bastion app-server
```

或者写进 config：

```ini
Host bastion
  HostName 203.0.113.10
  User ops

Host app-*
  ProxyJump bastion
  User deploy
```

`ProxyJump` 在本地建立到目标机的端到端加密连接，堡垒机只负责转发字节、看不到内容，也不需要把私钥拷到堡垒机上。多级跳板用逗号连起来：`ProxyJump bastion1,bastion2`。

### ProxyCommand：让 SSH 走代理

这是"SSH 怎么走代理"最常被问到的场景：本地开了 Clash/Surge 之类的代理，浏览器能出去，但 `ssh` 和 `git push` 依然连不上——因为 SSH 默认不理会系统代理设置。补法是用 `ProxyCommand` 指定"由谁来建立底层 TCP 连接"。

macOS 自带的 `nc` 就支持 SOCKS：

```ini
Host github.com
  ProxyCommand nc -X 5 -x 127.0.0.1:1087 %h %p
```

`-X 5` 是 SOCKS5（`-X connect` 则是 HTTP CONNECT），`%h`/`%p` 会被替换成目标主机和端口。装了 nmap 套件的话用 `ncat` 写法等价：

```ini
  ProxyCommand ncat --proxy-type socks5 --proxy 127.0.0.1:1087 %h %p
```

只有 HTTP 代理可用时（典型是公司网络），传统工具是 `corkscrew`：

```bash
brew install corkscrew
```

```ini
  ProxyCommand corkscrew proxy.corp.example.com 8080 %h %p
```

几点提醒：

- 需要走代理和不需要走代理的 Host，最好分成两个块，否则离开这个网络后所有连接都会因为代理不可达而失败；`Match exec` 可以做条件判断（见下）。
- **git 有独立的代理设置**，和 SSH 代理互不相干：HTTPS 远程地址看 `git config --global http.proxy`，SSH 远程地址只看上面这套 `ProxyCommand`。两者要分别配。
- 走 443 端口的 SSH（本文前面那段）本身就是为了绕开 22 被封，它和"走代理"是解决同一类问题的两种手段，通常二选一即可。

### Match：按条件生效的配置

`Host` 只能按主机名匹配，`Match` 能按更多条件：

```ini
Match host *.corp.example.com exec "on-corp-vpn"
  User dev
  IdentityFile ~/.ssh/id_ed25519_work

Match host github.com exec "test -n \"$HTTP_PROXY\""
  ProxyCommand nc -X 5 -x 127.0.0.1:1087 %h %p
```

第二个块的意思是"只有在环境变量里有代理时才启用 ProxyCommand"，正好解决上面提到的"离开代理网络就全挂"的问题。`Match` 支持 `host`、`user`、`originalhost`、`localuser`、`exec`（命令退出码为 0 即匹配）和 `all`。同样遵循 first-match-wins，所以 `Match` 块通常也放在文件靠后的位置。

### 免密登录普通服务器

`ssh-copy-id` 是把公钥追加到远端 `authorized_keys` 的最省事方式（它会自动处理权限）：

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server
```

之后在服务端把密码登录关掉（`/etc/ssh/sshd_config` 里 `PasswordAuthentication no`、`PermitRootLogin prohibit-password`），一台暴露在公网的机器才算及格。我的 `3b-admin` 块连的就是同一台服务器的另一个账号——用非 root 账号做日常操作、root 只在必要时上，这个习惯也体现在了 config 里。

### 硬件密钥

如果密钥文件本身可能连同笔记本一起丢，可以考虑 FIDO2 硬件密钥：

```bash
ssh-keygen -t ed25519-sk -C "yubikey"
```

私钥存在安全芯片里，签名时需要物理触碰。GitHub、GitLab 都已支持这种公钥。对个人来说属于锦上添花，对能碰到生产环境的人来说值得认真评估。

## 排错速查

SSH 出问题时的排查顺序，按我的经验：

```bash
ssh -vvv myhost          # 详细日志，认证失败看它基本能定位
ssh -G myhost            # 打印最终生效的配置（config 解析结果）
ssh -T git@github.com    # 测试 git 平台的认证，看 "Hi xxx!" 确认是哪个账号
ssh-add -l               # agent 里现在有哪些密钥
```

几个高频症状：

| 症状 | 大概率原因 | 处理 |
| --- | --- | --- |
| `Permission denied (publickey)` | 公钥没上传 / `IdentityFile` 指错 / 私钥权限太开放 | `ssh -vvv` 看它尝试了哪些密钥；检查服务端 `authorized_keys` |
| `Too many authentication failures` | agent 里密钥太多，试错超限 | 对应 Host 加 `IdentitiesOnly yes` |
| 连 GitHub 卡住直到超时 | 出站 22 被封 | 改走 `ssh.github.com:443` |
| push 到了错误的账号 | 多密钥串号 | `IdentitiesOnly yes` + 检查 `ssh -T` 返回的用户名 |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` | 服务器换密钥，或中间人 | 先核实，再 `ssh-keygen -R host` |
| 会话闲置一会儿就断 | NAT 超时掐连接 | `ServerAliveInterval 60` |

还有一个容易被忽略的联动：**SSH 身份和 git 提交身份是两件事**。config 决定了"以哪个账号推拉"，但 commit 里记录的 author 邮箱由 git 配置决定，配错了照样会把公司邮箱写进个人仓库的历史。多账号场景下这两套要一起配，我在[《一台 Mac 多个 git 身份》]({% post_url 2026-08-28-git-multi-identity-includeif-hasconfig %})里写过用 `includeIf hasconfig` 按远程地址自动切换 git 身份的做法，正好和本文的 Host 别名方案配套。

## 小结

如果要给"一台开发机的 SSH 该长什么样"列个清单：

- [ ] 密钥用 ed25519，一把钥匙一个身份，comment 写清用途
- [ ] 私钥设 passphrase，配 `AddKeysToAgent` + `UseKeychain` 免除重复输入
- [ ] 所有连接信息进 `~/.ssh/config`，命令行只敲别名
- [ ] 多账号块一律加 `IdentitiesOnly yes`
- [ ] `Host *` 兜底：`ServerAliveInterval`、`GSSAPIAuthentication no`，并放在文件末尾
- [ ] 内网服务用 `LocalForward` 拉出来，别把数据库暴露到公网
- [ ] 有堡垒机就用 `ProxyJump`，需要代理就配 `ProxyCommand`（git 的 http 代理另算）
- [ ] 出问题 `ssh -vvv` / `ssh -G`，别瞎猜
- [ ] 每半年盘点一次目录，删掉认不出来的密钥

SSH 的配置成本几乎是一次性的，但它每天替你省下的，是背 IP、背端口、背用户名，以及在多个身份之间手工切换的全部心智负担。
