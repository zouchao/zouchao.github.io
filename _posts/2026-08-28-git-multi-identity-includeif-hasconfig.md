---
date: 2026-08-28 00:30:00 +0800
title: 一台 Mac 多个 git 身份：用 includeIf hasconfig 按远程地址自动切换
layout: post
tags:
   - git
   - GitHub
   - macOS
categories:
   - 工具
---

一台机器上同时有几个 git 身份是很常见的：个人 GitHub、公司仓库、也许还有几个上古马甲号。全局配置只能写一个身份，靠"每个仓库手动设 local"又吃记忆力——忘了设，就会把公司邮箱写进个人仓库的历史里，或者用一个拼错的邮箱提交（GitHub 根本不把这些 commit 算你头上）。踩完坑之后我换成了**按远程地址条件包含配置**，从此身份自动正确。

## 思路

git 的身份解析是 repo-local 覆盖 global。与其在每个仓库里记着设 local，不如反过来：global 放最常用的个人身份，然后告诉 git——"凡是远程地址长这样的仓库，加载另一份身份配置"：

```ini
# ~/.gitconfig
[user]
    name = Your Name
    email = you@personal.dev
[pull]
    rebase = true
[includeIf "hasconfig:remote.*.url:git@github-work:*/**"]
    path = ~/.gitconfig-work
[includeIf "hasconfig:remote.*.url:ssh://git@github-work/**"]
    path = ~/.gitconfig-work
```

```ini
# ~/.gitconfig-work
[user]
    name = Your Work Name
    email = name@company.com
```

`hasconfig:remote.*.url:` 的语义是：仓库的**任意一个** remote URL 匹配模式，条件就成立。配合 `~/.ssh/config` 的 Host 别名使用最干净——工作仓库统一用别名做远程地址：

```
Host github-work
    HostName ssh.github.com
    Port 443
    User git
    IdentityFile ~/.ssh/id_work
    IdentitiesOnly yes
```

这样 clone 来的工作仓库天然带 `git@github-work:...` 地址，身份自动切换；个人仓库走 global。新 clone 的仓库也立刻正确，零记忆负担。

## 坑一：glob 里裸 `*` 不跨 `/`

我第一版写的是 `*github-work*`，不匹配。查 man page 才发现：hasconfig 的模式用标准 glob，**裸 `*` 不跨斜杠**，只有两个额外通配 `**/` 和 `/**` 能跨多级组件。而 scp 形式的 URL `git@github-work:team/repo.git` 里全是斜杠，所以必须写成：

- scp 形式：`git@github-work:*/**`
- ssh:// 形式：`ssh://git@github-work/**`

两种形式都加上 includeIf，就都覆盖了。

## 坑二：别用 `git config` 验证

`git config user.email` **不会评估 hasconfig 条件**，看到的永远是静态解析结果，会给你"配置没生效"的错觉。最靠谱的验证是在临时仓库里真实建一个 commit 看 author：

```bash
t=$(mktemp -d); git init -q "$t"
git -C "$t" remote add origin git@github-work:team/test.git
git -C "$t" commit -q --allow-empty -m test
git -C "$t" log -1 --pretty='%ae'   # 应输出公司邮箱
rm -rf "$t"
```

## 坑三：已经提交错了怎么办

**没 push**：`git commit --amend --reset-author --no-edit`（先设好正确身份）。

**已 push**：重写历史。如果仓库是 fork 的上游项目、历史里有一百个作者，你只想改自己那几条错误邮箱，用条件 env-filter，别人的一个字节都不碰：

```bash
git filter-branch -f --env-filter '
if [ "$GIT_AUTHOR_EMAIL" = "wrong@old.dev" ]; then
    export GIT_AUTHOR_NAME="Your Name" GIT_AUTHOR_EMAIL="you@personal.dev"
fi
if [ "$GIT_COMMITTER_EMAIL" = "wrong@old.dev" ]; then
    export GIT_COMMITTER_NAME="Your Name" GIT_COMMITTER_EMAIL="you@personal.dev"
fi
' -- --all
```

（`git filter-repo` 是官方推荐的现代替代，大仓库用它；小仓库 filter-branch 足够。）

重写时还有两个子坑：

1. **filter-branch 要求工作区干净**。有未提交改动就先处理（stash 或提交），它不会帮你做这个决定。
2. **push 时 `--force-with-lease` 报 stale info**。因为 filter-branch 会连本地的 `refs/remotes/origin/*` 一起重写，lease 的期望值已经不是远程真实值了。解法：先拿远程真实 SHA 再推：

```bash
sha=$(git ls-remote origin main | awk '{print $1}')
git push --force-with-lease=main:$sha origin main
```

重写完成后记得删掉备份引用，否则 `git log --all` 还能看到旧身份：

```bash
git for-each-ref --format='%(refname)' refs/original | xargs -n1 git update-ref -d
```

## 归属细节

GitHub 把 commit 算到谁头上，看的是 author email 是否挂在某个账号下。不想把真实邮箱写进公开历史，用 noreply 地址（`用户名@users.noreply.github.com`）——既保护隐私又保留归属。重写历史后，force push 上去，GitHub 侧的归属会跟着变。

## 小结

- global 放个人身份，`includeIf hasconfig` 按远程地址加载工作身份，配合 ssh Host 别名使用
- 裸 `*` 不跨 `/`，模式用 `*/**`、`/**`
- 验证靠真实 commit，不靠 `git config`
- 改历史：条件 env-filter 只动自己的错误邮箱；force push 用 `ls-remote` 拿真实 SHA；收尾删 `refs/original`
- 马甲号仓库需要独立身份的，repo-local config 优先级最高，单独设即可
