---
date: 2026-08-26 16:30:48
title: 用 Nix 声明式管理我的 Mac：从入门到上手计划
layout: post
tags:
   - Nix
   - macOS
   - nix-darwin
   - home-manager
categories:
   - 工具
---

最近开始折腾 [Nix](https://nixos.org/)，目的很简单：不想再靠「手动装软件 + 手动改配置」来维护我的 Mac。这篇记录一下 Nix 是什么、能干什么，以及我打算怎么一步步把整台机器都交给它管。

## Nix 是什么

Nix 是一个**声明式、可复现**的包管理器，也有配套的发行版 NixOS。它的核心思想是把「环境配置」变成代码，让你在任何一台机器上重建出完全相同的软件环境。

关键特性：

1. **可复现** —— 用代码描述依赖，别人（或未来的自己）拿同一份配置能构建出完全一致的环境，告别「在我机器上能跑」。
2. **依赖隔离** —— 每个包装在 `/nix/store/<hash>-name/` 下，带内容哈希，多版本可以共存，不污染全局。
3. **原子更新 + 回滚** —— 升级是原子切换，出问题随时回退到上一个 generation。
4. **临时环境** —— `nix shell` / `nix develop` 进入一个只含你声明了依赖的 shell，用完即弃。
5. **管理整个系统** —— 不只是装软件：Linux 上用 NixOS，macOS 上用 `nix-darwin`，dotfiles 和用户级配置用 `home-manager`。

## 上手计划：完整系统管理

我的目标是 **nix-darwin + home-manager** 一整套，分阶段推进，每阶段都能停下来验证。

### Phase 1 —— 安装 Nix

用 Determinate 安装器（自动处理新版本 macOS 的 `/nix` 卷问题、自动开启 flakes）：

```bash
curl --proto '=https' --tlsv1.2 -sSf -L \
  https://install.determinate.systems/nix | sh -s -- install

nix --version          # 验证
```

### Phase 2 —— 建配置仓库 + flake 骨架

单独建一个 git 仓库放配置（跟 dotfiles 仓库分开）：

```bash
mkdir -p ~/nix-config && cd ~/nix-config && git init
```

`flake.nix` 是核心，三个输入（nixpkgs + nix-darwin + home-manager）全部锁定：

```nix
{
  description = "declarative macOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nix-darwin, home-manager, ... }: {
    darwinConfigurations."<主机名>" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./darwin.nix
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users."<username>" = import ./home.nix;
          };
        }
      ];
    };
  };
}
```

### Phase 3 —— nix-darwin 系统 + Homebrew（先跑最小配置）

`darwin.nix` 先用最小内容跑通，再慢慢扩：

```nix
{ ... }: {
  system.defaults = {
    dock.autohide = true;
    NSGlobalDomain.AppleInterfaceStyle = "Dark";
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "none";   # 先别自动清理手动装的包！
    brews = [ "ripgrep" "fd" ];
    casks = [ "firefox" ];
    masApps = { "Slack" = 803453959; };
  };
}
```

App Store 应用也能声明（`masApps`）——底层是 Homebrew 的 `mas` 走 Apple 官方通道，享受不到 Nix 的可复现回滚，但"装了什么"同样进了配置。

### Phase 4 —— home-manager 接管 dotfiles

重点是 vim 配置。先用「引用现有仓库」的方式过渡（零迁移），再考虑彻底接管：

```nix
{ ... }: {
  xdg.configFile."nvim".source = /path/to/nvim-repo;  # 先指向现有仓库
  programs.zsh.enable = true;
  programs.git = { enable = true; userName = "<your-name>"; };
}
```

### Phase 5 —— 首次应用 + 增量验证

```bash
cd ~/nix-config
darwin-rebuild switch --flake .#<主机名>   # 核心命令，以后改配置就跑它
```

原则：每加一小块就 rebuild 一次，出问题 `darwin-rebuild switch --rollback` 随时回退。

## 日常运维：怎么卸载和升级

跑通之后，装软件变成了「列表加一行 + rebuild」，但很快遇到两个反向问题：不想要的怎么卸？想升级的怎么升？这两个操作都比"加一行"微妙。

### 卸载：删列表项 ≠ 卸载

`onActivation.cleanup = "none"` 时，激活只负责把列表里的东西装上（本质是跑 `brew bundle`），不会动列表外的东西。所以只把某个 cask 从列表删掉再 rebuild，app 还好好躺在那儿，只是脱离了管理。

两条路：

**方式一：手动卸载（`cleanup` 保持 `"none"` 时最稳妥）**

1. 从 `casks` 列表删掉那一行
2. 手动卸掉本体：

```bash
brew uninstall --cask <名字>        # 卸载
brew uninstall --cask --zap <名字>  # 连同配置、缓存一起清掉（彻底卸载）
```

3. `darwin-rebuild switch` 同步状态

**方式二：交给 nix-darwin 自动清理**

```nix
onActivation.cleanup = "uninstall";
```

之后流程变成纯粹的「删行 → rebuild」，激活时 `brew bundle --cleanup` 会卸掉列表外的所有包。代价是**所有**手动 `brew install` 过的包也会被干掉，前提是你保证一切都在声明列表里。过渡期可以先用 `"check"` 模式：只校验不删，发现列表外有包就让激活失败。

### 升级：先接受 cask 没有版本管理

- cask 定义永远指向最新版，Brewfile 只声明"装了什么"，不记录版本
- Homebrew 4.4.0 起连 `brew bundle` 的 lockfile 都移除了，想锁版本也没入口
- 所以不存在"固定版本"或"回滚"——那是 nixpkgs 的活

好消息：手动 `brew upgrade` 不会和声明式配置打架。rebuild 只检查"装没装"，看到 app 已存在就跳过，不会把版本退回去。

**方式一：手动升级（指哪打哪）**

```bash
brew update                      # 刷新元数据
brew upgrade --cask <名字>       # 升级指定 cask
brew outdated --cask             # 看看谁有新版
```

**方式二：激活时自动升级**

```nix
homebrew = {
  onActivation.upgrade = true;      # 激活时升级所有过期的 brew/cask
  onActivation.autoUpdate = true;   # 激活前先跑 brew update
};
```

默认 `upgrade = false` 时，nix-darwin 会给 `brew bundle` 传 `--no-upgrade`，保证反复 rebuild 是幂等的。打开后每次 switch 都会全量升到最新，代价是变慢、结果不完全可复现。

会自更新的 app（如 Chrome）默认会被升级流程跳过，要强制就加 `--greedy`，或在声明里写成 `{ name = "chrome"; greedy = true; }`。

## 小结

Nix 最打动我的一点是：机器上的一切——系统设置、Homebrew 包、App Store 应用、dotfiles——都能收敛到一份版本可控的代码里。换电脑时不再是从记忆里抓软件清单，而是 `git clone` + 一条 rebuild 命令。

真正跑起来之后，日常操作其实就一张表：

| 操作 | 做法 | 备注 |
|------|------|------|
| 安装 | 列表加一行 + rebuild | 最顺的路径 |
| 卸载 | 列表删行 + `brew uninstall --cask` | 或开 `cleanup = "uninstall"` 全自动 |
| 升级 | `brew upgrade --cask <名字>` | 或开 `onActivation.upgrade` 全自动 |
| 版本锁定 / 回滚 | ❌ cask 做不到 | 需要可复现就交给 nixpkgs |

Homebrew 这层走的是"永远最新"的滚动模型；想要严格的版本控制，还是得把能进 nixpkgs 的软件尽量交给 Nix 管。