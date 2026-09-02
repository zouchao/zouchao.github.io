---
date: 2026-09-02 22:45:00 +0800
title: 博客翻新记：整理标签、换上 Chirpy，再排掉 GitHub Pages 的一串坑
layout: post
tags:
    - blog
    - Jekyll
    - Chirpy
    - GitHub
categories:
    - 工具
---

这个博客从 2010 年开站，主题还是当年手改的 Jekyll 默认模板，十几年下来积累了不少历史包袱：标签越打越散、代码块还在用 Google Code Prettify 的 `<pre class="prettyprint">`、统计用的 Universal Analytics 早被 Google 停服、评论区干脆没有。这次花了点时间一次性翻新，做了五件事：**整理标签和分类、迁移 Chirpy 主题、部署切到 GitHub Actions、接入 giscus 评论、换统计方案**。过程里踩了一串 GitHub Pages 的坑，值得一记。

## 第一步：给标签和分类立规矩

老博客最常见的状态就是标签放飞：同一个东西三种写法，混着一堆"工具安装""搜索"这种一次性关键词。整理的原则很简单：

- **只留主题标签**：一个标签要有多篇文章复用的潜力，用真实工具名；方法名和泛泛的关键词（远程访问、数据库、科技产品……）一律删掉，它们更适合出现在标题里而不是标签里
- **大小写按官方写法**：`PHP`、`MySQL`、`Golang`、`macOS`、`VSCode`、`VirtualBox`；`git` 官方就是小写，保持小写。Jekyll 的标签是大小写敏感的，`git` 和 `Git` 会被渲染成两个标签，所以重点不是全小写，而是**全库一致**
- **中文标签不动**：代理、缓存这类用中文本来就自然

标签从散乱状态收敛到 40 个。分类顺手也整了：15 个分类合并成 8 个（`tools`/`工具`/`代理` 合一、单篇分类就近归队），还揪出一篇 Golang 调试文章被误挂在「建站, blog」下面这种陈年悬案。

## 第二步：换主题，选了 Chirpy

候选里看了 Minimal Mistakes 和 Chirpy，最后选了 [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy)：文章页自带目录、全文搜索、深色模式、归档/标签/分类页开箱即用，而且是 gem 形式安装——主题代码进 gem 包，仓库里只剩配置和内容，以后升级就是一行版本号的事。

迁移本身是体力活：删掉自己维护了十几年的 `_layouts`/`_includes`，按 Chirpy 的约定建 `_tabs` 集合（归档、标签、分类、关于各一个文件，侧边栏自动成型），`_config.yml` 基本重写。其中一个关键决定：

```yaml
defaults:
  - scope:
      path: ""
      type: posts
    values:
      permalink: /:year/:month/:day/:title
```

**permalink 保持和旧站完全一致**。十几年的外链、搜索引擎收录、别人文章里的引用全都指向 `/2013-05-16/git-commands` 这种地址，换主题的代价不应该由 URL 来付。

## 第三步：部署从「分支构建」换成 GitHub Actions

这里有个容易忽略的前提：**GitHub Pages 的内置构建（"从分支部署"）跑在一个固定的 `github-pages` gem 白名单上，白名单里没有 Chirpy**，分支构建必然失败。用第三方主题，部署源必须切到 GitHub Actions 自己构建。workflow 很标准：

```yaml
- uses: ruby/setup-ruby@v1
  with:
    ruby-version: 3.4
    bundler-cache: true
- run: bundle exec jekyll b -d "_site"
  env:
    JEKYLL_ENV: "production"
- uses: actions/upload-pages-artifact@v5
- uses: actions/deploy-pages@v5
```

中间还塞了一步 `htmlproofer` 自检（校验内链和文件完整性，`continue-on-error` 不阻塞部署），以后写文章把链接打错，CI 会第一时间提醒。

## 踩的坑

### 坑一：时区把文章 URL 挪了一天

`_config.yml` 里设了 `timezone: Asia/Shanghai` 之后，一篇日期写 `2026-08-26 16:30:00`（不带时区）的文章，URL 变成了 `/2026-08-27/...`。原因是 Jekyll 对裸日期的处理：**解析时按 UTC，渲染时再转站点时区**，16 点之后的时间加 8 小时就跨天了。解法是把所有文章的 front matter 日期统一钉上时区：

```yaml
date: 2026-08-26 16:30:00 +0800
```

一条正则批量改完。教训：**站点时区和文章日期，有一个带时区，另一个就必须全部带**。

### 坑二：部署成功，文章页却全部 404

这个是本次装修最大的坑。现象：Actions 全绿、部署成功，首页、标签页、资源文件全部正常，**唯独所有文章页 404**，而且只有一部分访问者能看到。

排查过程值得复盘，因为每一步都在缩小范围：

1. **先怀疑构建产物**：把部署用的 artifact 下载解包，文章文件全在，路径正确——排除
2. **字节级比对**：线上首页、分页页的 etag 尺寸与产物文件逐一吻合，旧主题文件全部消失——确认线上服务的确实是我的新部署，而不是某个旧构建的残留
3. **找差异**：同一个部署里，`/tags/`、`/page2/`、嵌套的图片脚本全部 200，只有文章 URL 404
4. **最后才看到根源**：仓库的 Pages 源还停留在「从分支构建」。也就是说每次 push，GitHub 会同时跑两套部署——我的 Actions 工作流，和内置的分支构建（后者因白名单没有 Chirpy 而失败）。两套系统打架加上 CDN 边缘节点把故障窗口期的 404 缓存了下来，就造成了这种「部署是好的、部分路径就是 404」的分裂症状

解法只有一个：**把 Pages 源从「从分支构建」切到「GitHub Actions」**（仓库 Settings → Pages → Source），让部署链路只剩一条。切换后分支构建彻底停用，问题解决。

还有一个验证上的教训：故障期间我从自己机器的出口测，始终是 404，差点以为没修好；后来用 check-host.net 从全球 59 个节点探测，全绿（包括日本节点）。**单一测试点会被自己链路上的缓存骗到**，验证线上问题要多找几个视角。

## 补齐配套

- **评论：giscus**。基于 GitHub Discussions，无广告不追踪，评论数据就是自己仓库里的 Discussion 帖子。接入三步：仓库开 Discussions 功能、安装 Giscus App、把 `repo_id`/`category_id` 填进 Chirpy 配置。代价是评论者需要 GitHub 账号——技术博客，读者本来就有
- **代码块考古**：全站 41 个 `<pre class="prettyprint">` 全部换成带语言标注的围栏代码块（php/sql/shell/ruby/vim/ini），kramdown + Rouge 高亮直接生效，顺带把两块「转载自/译自」的文字说明改成了引用格式
- **统计**：旧站的 `UA-xxx` 随 Universal Analytics 停服一起进了坟墓，换成 GA4；另外接了 [GoatCounter](https://www.goatcounter.com) 在文章页显示阅读量——GA 负责看报表，GoatCounter 无 cookie、只管展示，分工明确

## 小结

几条经验留给下次折腾（或者留给正在折腾老博客的你）：

1. **翻新老站，permalink 一个字都别动**，主题、部署方式随便换
2. GitHub Pages 用白名单之外的主题，**部署源必须切 GitHub Actions**，别留「分支构建」在那打架
3. Jekyll 的裸日期按 UTC 解析，站点时区不是 UTC 就全部钉上 `+0800`
4. 线上问题验证，**别信单一测试点**，多节点探测能救命
5. 标签分类这种东西，立规矩要趁早：官方大小写、只留主题词，十年后你会感谢自己

博客现在是 Chirpy 的样子了。下一篇见。
