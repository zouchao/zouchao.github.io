---
date: 2026-09-04 15:35:00 +0800
title: Bitwarden CLI 上手：安装、登录，把密钥管理搬进终端
layout: post
tags:
    - Bitwarden
    - CLI
    - macOS
    - 安全
categories:
    - 工具
---

密码和各种 token 都放在 Bitwarden 里，但总有些时刻你需要在终端里拿到它们：脚本里要导出一个 GitHub token、命令行登录某个服务要临时取个 2FA 验证码、本地起服务要注入数据库密码。浏览器插件管不了这些场景——Bitwarden 官方提供了命令行工具 `bw`，登录解锁之后，整个密码库都能在命令行里读写。我在 Mac 上用了一段时间，这篇把安装、登录、取密钥、备份的完整流程整理一下，顺带记录几个坑。

## 安装

官方文档给的安装方式里，npm 是主推渠道（文档页默认停在 npm 标签页）：

```bash
npm install -g @bitwarden/cli
```

两个注意点：Linux 上可能要先装构建工具（`apt install build-essential`）；**arm64 设备请走 npm**，官方原生二进制没有 arm64 Linux 版本。

其他平台：

```bash
sudo snap install bw              # Linux (Snap)
choco install bitwarden-cli       # Windows (Chocolatey)
# Flatpak 版随桌面应用一起：
flatpak run --command=bw com.bitwarden.desktop --version
```

也可以从官网（bitwarden.com/download，选 CLI）下载原生二进制，`chmod +x` 后丢进 PATH。官方文档没列 Homebrew，但 homebrew-core 里有现成的 formula：

```bash
brew install bitwarden-cli
```

我的 Mac 是 Nix 管理的，装的是 `nixpkgs#bitwarden-cli`，效果和上面等价。装完验证：

```bash
$ bw --version
2026.8.0
```

## 登录：三种方式

**交互式登录**（日常使用推荐）：

```bash
bw login
```

按提示输入邮箱和主密码。开了两步验证的话加参数，`--method 1` 是验证器 App 的 6 位码：

```bash
bw login --method 1 --code 123456
```

**SSO 登录**（企业版）：`bw login --sso`，会打开浏览器走组织的 SSO 流程。

**API Key 登录**（自动化场景）：先在网页端的账号设置里生成 API Key，然后：

```bash
export BW_CLIENTID="user.xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export BW_CLIENTSECRET="xxxxxxxxxxxxxxxxxxxx"
bw login --apikey
```

用 `bw login --check` 确认登录状态，`bw status` 能看到更完整的状态（服务器地址、上次同步时间、邮箱、当前是 locked 还是 unlocked）。

## 解锁和会话密钥：最核心的概念

Bitwarden 是端到端加密的，登录只解决了"你是谁"，密码库本身还是锁着的——**每次使用前要解锁，解锁会产生一个会话密钥（session key）**：

```bash
export BW_SESSION="$(bw unlock --raw)"
```

之后这个 shell 里的 `bw` 命令就靠环境变量 `BW_SESSION` 工作。也可以不落环境变量，逐条命令传：

```bash
bw list items --session "5PBYGU+..."
```

几个要点：

- 会话密钥只在当前 shell 有效，开新终端窗口要重新 `bw unlock`；
- **重新解锁会让之前的会话密钥全部失效**（`bw unlock --help` 里写明了）。所以我习惯只维护一个窗口的 session，而不是每个窗口各解锁一次；
- 用完 `bw lock` 上锁，`bw logout` 则连登录态一起清掉。

## 取密钥：list 和 get

先找到条目，再取字段。`get` 的参数既可以传条目的 UUID，也可以直接传搜索词：

```bash
bw list items --search github          # 按名字搜
bw list items --url https://github.com # 按 URL 匹配（登录类条目）

bw get password github.com             # 密码
bw get username github.com             # 用户名
bw get totp github.com                 # 当前的 2FA 验证码，很顺手
bw get notes some-secure-note          # 安全笔记全文
```

取附件要带上条目 id：

```bash
bw get attachment id_rsa.enc --itemid <item-id> --output ./id_rsa.enc
```

需要结构化数据时，`bw get item` 输出完整 JSON，配合 `jq` 随便取：

```bash
bw get item github.com | jq -r '.login.password'
```

## 注入到脚本和环境变量

最典型的用法——临时把密钥取出来用，不落盘：

```bash
export GITHUB_TOKEN="$(bw get password github-api-token)"
gh auth status
```

命令历史里只会记录 `bw get password github-api-token`，密钥本身不进 history。两个习惯要注意：**不要把密钥拼进命令行参数**（会被 `ps` 看到、写进各种日志）；用完了 `bw lock` 上锁，别让 session 一直开着。

如果是一组固定的变量要喂给某个程序，可以先解锁，再在启动前集中导出：

```bash
export BW_SESSION="$(bw unlock --raw)"
export DB_PASSWORD="$(bw get password prod-db)"
export SMTP_PASSWORD="$(bw get password smtp)"
./my-server
```

## 建条目和改条目：template + jq + encode 流水线

`bw create` / `bw edit` 吃的是 base64 编码过的 JSON，官方给的标准姿势是"模板 → jq 修改 → encode → 提交"：

```bash
# 新建一个安全笔记
bw get template item | jq '.type=2 | .secureNote.type=0 | .name="API Keys" | .notes="xxx"' \
  | bw encode | bw create item

# 改已有条目的密码
bw get item <item-id> | jq '.login.password="new-password"' \
  | bw encode | bw edit item <item-id>
```

新密码可以让它自己生成，不用另开网页：

```bash
bw generate -lusn --length 18   # 大小写+数字+特殊字符，18 位
bw generate -p --words 4        # 4 个单词的 passphrase
```

## 备份：export 别只导 CSV

密码库本身就该有备份。三种格式差别很大：

```bash
bw export --format encrypted_json --output ~/backup/bw.json   # 加密备份，首选
bw export --format zip --output ~/backup/bw.zip               # 带附件
bw export --format csv                                        # 明文！只用于迁移
```

`encrypted_json` 用账号密钥加密，可以放心存档；CSV 是全明文，用完就删。恢复或从别家迁移用 `bw import`，`bw import --formats` 列出支持的来源（lastpasscsv、1password 等），Bitwarden 自己的备份用 `bitwardencsv` / `bitwardenjson`。

## CI 里用：API Key 登录只是第一步

在 CI 里跑 `bw` 的典型写法：

```bash
export BW_CLIENTID="${{ secrets.BW_CLIENTID }}"
export BW_CLIENTSECRET="${{ secrets.BW_CLIENTSECRET }}"
bw login --apikey
export BW_SESSION="$(bw unlock --passwordenv BW_PASSWORD)"
bw get password some-key
```

这里有个容易误解的点：**API Key 只是替代"邮箱+密码"登录（并跳过两步验证），`unlock` 仍然需要主密码**——因为数据是端到端加密的，服务器不掌握解密能力。也就是说主密码还是得以某种形式进 CI，这通常不是好主意。团队项目里的密钥管理，更合适的工具是下面这个。

## 真正给项目管密钥：Secrets Manager（bws）

`bw` 管的是个人/组织密码库。如果是"服务账号、部署脚本用的 API Key、数据库密码"这类开发密钥，Bitwarden 有一个独立产品 Secrets Manager，对应另一个命令行工具 `bws`：

- 用**机器账号 + access token** 鉴权，没有 login/unlock 流程，天然适合 CI：`export BWS_ACCESS_TOKEN="..."` 即可；
- 密钥按项目组织，权限可以精确控制哪个机器账号能读哪些项目。

```bash
bws secret list <project-id>
bws secret get <secret-id>
bws secret create DB_PASSWORD "s3cret" <project-id>

# 把项目里的密钥作为环境变量注入子进程
bws run -- 'npm run start'
```

`bws run` 值得单独说：它直接把项目下的密钥注入子进程的环境变量，进程退出即消失，不留 `.env` 文件。早期文档里还有个模板注入的 `bw inject`，新版本已经移除，现在注入环境变量这件事就是 `bws run` 负责。

## 零碎但有用的几件事

- **自建服务器**：登录前先 `bw config server https://bitwarden.example.com`，指向自己的实例；
- **多账号隔离**：`bw` 的状态目录可以用 `BITWARDENCLI_APPDATA_DIR` 环境变量指定，个人号和工作号各指一个目录，互不干扰；
- **补全**：`bw completion --shell zsh` 生成 zsh 补全（目前只支持 zsh）；
- **一次性分享**：`bw send "text"` 或 `bw send -f ./file.ext` 生成一个临时分享链接，对方用 `bw receive <url>` 取；
- **同步**：`bw` 的数据是本地缓存，别处改了记得 `bw sync`。

## 小结

`bw` 的定位很清晰：把已经在 Bitwarden 里的东西接到命令行和脚本里。个人脚本取密钥，登录 + `BW_SESSION` + `bw get` 三件套就够用；团队项目、CI 场景，直接上 Secrets Manager，别让主密码躺在 CI 变量里。唯一要克制的，是把密钥导出成明文文件的冲动——库本身就是最好的密钥管理，CLI 只是给它开了个终端入口。
