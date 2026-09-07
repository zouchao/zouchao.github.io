---
date: 2025-12-21 21:30:00 +0800
title: Neovim AI 实战：Copilot Free、本地 Ollama 与百炼的三层分工
layout: post
tags:
   - Neovim
   - AI
   - Ollama
   - Copilot
categories:
   - 工具
image:
    path: /assets/img/posts/nvim-ai-copilot-ollama-bailian/cover.png
    alt: Neovim AI 三层架构：Copilot Free 自动补全、Ollama 本地手动补全、百炼大模型聊天编辑
---

GitHub Copilot 订阅到期了。续费之前先想清楚一个问题：**编辑器里的 AI 能力，到底需要几层、每层用什么最划算？** 折腾完的结论是三层分工——云端免费档管自动补全、本地模型管手动补全、国产大模型管聊天和改代码。这篇记录架构和一路踩的坑（最后一个键位冲突藏得极深）。

## 最终架构

| 场景 | 方案 | 模型 | 成本 |
|------|------|------|------|
| 行内自动补全（幽灵文本） | copilot.lua | GitHub Copilot | Free 档，2000 次/月 |
| 行内手动补全（按需召唤） | minuet-ai.nvim + ollama | qwen2.5-coder:1.5b-base | 0，代码不出机器 |
| 聊天 / 选区编辑 | avante.nvim | qwen3.8-max（百炼 Anthropic 兼容端点） | 按量计费 |

分工逻辑：日常补全吃 Copilot Free 的额度；额度用完、或者代码敏感不能出机器时，手动召唤本地模型；需要「理解上下文改一段代码」时才动用大模型聊天。

我的 nvim 配置（LazyVim）用 home-manager 声明式管理，配置源文件在 `~/nix-config/home/nvim/`，激活后符号链接到 `~/.config/nvim`。有个小细节：lazy.nvim 的 lockfile 要显式指回仓库路径，因为 nix store 是只读的，插件更新后 lazy 写不回锁文件：

```lua
lockfile = vim.env.HOME .. "/nix-config/home/nvim/lazy-lock.json",
```

## 第一层：copilot.lua + Copilot Free

GitHub 的免费档每月 2000 次补全，对个人轻度使用完全够。copilot.lua 首次使用会自动下载 `copilot-language-server` 二进制（来自 GitHub Releases），网络不好时 `:checkhealth copilot` 会看到卡在 downloading。

登录流程：

```vim
:Copilot auth signin   " 打开浏览器 OAuth
:Copilot status        " 显示 Online / attached 即成功
```

配置很薄，自动触发 + Tab 接受：

```lua
{
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  opts = {
    suggestion = {
      enabled = true,
      auto_trigger = true,
      keymap = {
        accept = "<Tab>",
        next = false,   -- 关键，见踩坑 3
        prev = false,
      },
    },
    panel = { enabled = false },
  },
}
```

## 第二层：minuet-ai.nvim + ollama（本地手动补全）

[minuet-ai.nvim](https://github.com/milanglacier/minuet-ai.nvim) 提供真正的幽灵文本（virtual text），支持任何 OpenAI 兼容的 FIM 端点——ollama 的 `/v1/completions` 正好是。

ollama 用 nix 装好并配了 launchd 常驻（`ollama serve` 开机自启），模型拉一个轻量的 FIM 模型：

```bash
ollama pull qwen2.5-coder:1.5b-base
```

minuet 配置：

```lua
opts = {
  provider = "openai_fim_compatible",
  n_completions = 1,
  context_window = 1024,
  provider_options = {
    openai_fim_compatible = {
      api_key = "TERM",   -- ollama 不需要 key，借任意存在的环境变量过校验
      name = "Ollama",
      end_point = "http://127.0.0.1:11434/v1/completions",
      model = "qwen2.5-coder:1.5b-base",
      optional = { max_tokens = 56, top_p = 0.9 },
    },
  },
  virtualtext = {
    auto_trigger_ft = {}, -- 保持空：永不自动触发，把自动补全留给 copilot
    keymap = {
      accept = "<A-A>", accept_line = "<A-a>", accept_n_lines = "<A-z>",
      prev = "<A-[>", next = "<A-]>", dismiss = "<A-e>",
    },
  },
}
```

这一层的注意事项：

1. **端点写 `127.0.0.1` 别写 `localhost`** —— ollama 默认只绑 IPv4，`localhost` 可能解析到 `::1` 然后连接被拒
2. **`ollama ps` 空是正常的** —— 它只显示已载入内存的模型；模型按需加载、闲置 5 分钟自动卸载。补全触发后 5 分钟内再看就有了
3. **FIM 用 base 模型** —— `qwen2.5-coder:1.5b-base` 是专门做填中间的变体，instruct 版不适合补全场景
4. **必须插入模式** —— minuet 的 trigger 在 normal 模式下静默返回，不报任何错

终端要让 Option 组合键（`<A-]>` 等）传进 nvim：Ghostty 配置 `macos-option-as-alt = left`（左 Option 作 Alt，右 Option 保留输入特殊字符）；iTerm2 则是 Profiles → Keys → Left Option 设为 Esc+。

## 第三层：avante.nvim + 百炼（聊天 / 选区编辑）

avante 0.3+ 把自定义供应商从 `vendors` 挪到了 `providers`（旧写法会报 DEPRECATED 警告）。百炼提供 Anthropic 兼容端点，所以直接继承 claude 的请求实现：

```lua
opts = {
  provider = "bailian",
  behaviour = { auto_suggestions = false },  -- 见踩坑 1
  providers = {
    bailian = {
      __inherited_from = "claude",
      endpoint = "https://<你的应用>.cn-beijing.maas.aliyuncs.com/apps/anthropic",
      model = "qwen3.8-max",
      api_key_name = [[cmd:sqlite3 $HOME/.cc-switch/cc-switch.db "SELECT json_extract(settings_config, '$.env.ANTHROPIC_AUTH_TOKEN') FROM providers WHERE name='Bailian' AND app_type='claude';"]],
      extra_request_body = { max_tokens = 4096 },
    },
  },
  mappings = { ask = "<leader>aa", edit = "<leader>ae", refresh = "<leader>ar" },
}
```

重点是 `api_key_name` 的 `cmd:` 前缀：**key 不落盘、不进 git，每次请求时从 cc-switch 的本地数据库实时读取**。cc-switch 里轮换 key 或换模型后 nvim 自动跟随，唯一事实来源只有一个。

## 踩坑记

### 坑 1：avante 的 auto_suggestions 不是「幽灵文本」

看到 `auto_suggestions` 这个选项名，我以为它就是行内自动补全，配上本地 ollama 就是 Copilot 平替。开启后没有任何补全出现，`:messages` 里反复报 `Error while decoding suggestions`。

读源码才发现完全想错了：它是一个实验性的**「全文件 JSON 编辑建议」协议**——把整个文件发给模型，要求返回 JSON 格式的结构化编辑指令，再解码应用。1.5b 的 base 模型根本输出不了合法 JSON，所以永远解码失败。

教训：**选项名不可信，行为存疑直接读源码。** 行内补全请认准 copilot.lua / minuet / blink.cmp 这类专门实现。

### 坑 2：:Lazy sync 全军覆没，TLS connect error

14 个插件仓库全部 `TLS connect error`，但终端里 git clone 同一批仓库完全正常，浏览器访问 GitHub 也正常。

用 `ps eww <nvim的pid>` 一看：nvim 进程的环境变量里带着一堆**僵尸代理**（`http_proxy` 指向一个早已关闭的本地代理端口）。进程启动时对环境变量做了快照，之后我用 Raycast 关掉了代理，但 nvim 里的旧值还在，所有 git 子进程都继承了它。nix 环境里的 git（OpenSSL 3.x）只是对「连接被异常掐断」报错更严格，把问题暴露出来了——换成系统 git 只会表现为静默卡死。

修复：nvim 里 `:let $http_proxy='' | let $https_proxy=''`（大写同理），或者直接重启 nvim。

### 坑 3：Option+] 毫无反应——两层静默叠加（最隐蔽）

minuet 装好后，插入模式按 `<A-]>` 没有任何反应：不报错、不出补全、`ollama ps` 也没有模型载入（说明请求根本没发出去）。

逐环节排查：配置生效 ✓、插件已装 ✓、ollama 服务正常 ✓、直接 curl minuet 用的那个端点能返回补全 ✓。headless 跑 nvim 手动调 minuet 的请求函数，也能拿到结果 ✓。整条链路都是通的，唯独真实按键无效。

最后一条命令破案：

```vim
:verbose imap <M-]>
```

输出显示**同一个键上叠了两条映射**：

```
i  <M-]>  *@  copilot.lua/lua/copilot/keymaps/init.lua   [copilot] next suggestion
i  <M-]>  *   minuet-ai.nvim/lua/minuet/virtualtext.lua  [minuet.virtualtext] next suggestion
```

copilot.lua 的默认「下一条建议」键也是 `<M-]>`（`<A-` 和 `<M-` 在 nvim 里是同一个键），而且它是 attach 到 buffer 时以 **buffer 级**注册的——buffer 级映射优先级永远高于 minuet 的全局映射。于是我按 Option+] 时触发的是 copilot 的处理器，它发现没有待切换的建议，**静默返回**。

为什么 headless 测试发现不了？因为 copilot 只在真实 attach 到 buffer 后才注册这些映射，headless 环境里它从不 attach，键位表干干净净。

修复：copilot 的 `next` / `prev` 设为 `false` 让位（Free 档一次只出一条建议，切换键本来就没用）。

这个坑的恶劣之处在于**两层静默叠加**：键位被抢占不报错，抢占者的空转也不报错。表现和「按键根本没传进终端」一模一样。`:verbose imap <键>` 是唯一能看出叠影的地方。

## 排查方法论小结

1. **`:verbose imap <键>`** —— 查键位冲突和映射来源，比猜测快一万倍
2. **`:messages` / `:checkhealth`** —— 一闪而过的报错都堆在这
3. **headless 复现** —— `nvim --headless` + Lua 脚本可以把插件行为剥离出来单测；但注意它复现不了依赖真实 attach 的行为（比如坑 3）
4. **读源码确认语义** —— 选项名会骗人（坑 1），静默返回的守卫条件只有源码里写着（minuet 的 trigger 非插入模式直接 return）
5. **秘钥只做运行时读取** —— `cmd:` 前缀、环境变量、keychain，永远不要把明文写进会进 git 的文件

## 键位速查

| 键位（插入模式） | 功能 |
|------|------|
| `<Tab>` | 接受 copilot 自动补全 |
| `<A-]>` / `<A-[>` | 召唤 minuet / 切换建议 |
| `<A-A>` / `<A-a>` | 接受 minuet 整段 / 一行 |
| `<A-z>` / `<A-e>` | 接受 N 行 / 取消 |
| `<leader>aa` / `<leader>ae` | avante 提问 / 编辑选区 |
