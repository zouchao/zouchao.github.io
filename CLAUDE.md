# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

个人技术博客（中文），Jekyll + [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy) 7.6 主题，
推送到 `main` 由 `.github/workflows/pages-deploy.yml` 构建并发布到 GitHub Pages。

## 常用命令

```bash
bundle install                 # 安装依赖（本地 Ruby 3.3.5，CI 用 3.4）
bundle exec jekyll serve       # 本地预览 http://127.0.0.1:4000
JEKYLL_ENV=production bundle exec jekyll build   # 与 CI 一致的产物构建
./newpost "文章标题"            # 生成 _posts/YYYY-MM-DD-<slug>.md 骨架并用 $EDITOR 打开

# 链接检查（CI 里跑同样命令，但 continue-on-error: true，失败不阻塞部署）
bundle exec htmlproofer _site --disable-external --ignore-urls "/^http:\/\//"

# 配图渲染 / 封面光标审计（见下文「封面插图」）
bash .claude/skills/blog-illustration/scripts/render-svg.sh assets/img/posts/<slug>/cover.svg
bash .claude/skills/blog-illustration/scripts/audit-cursors.sh
```

没有测试框架，也没有独立的 lint 配置；htmlproofer 是唯一的自动校验。
CI 的 htmlproofer 步骤被刻意设为不阻塞——历史文章里有陈旧外链和裸 HTML。

## 主题定制架构

Chirpy 是 gem 主题（`_config.yml` 里 `theme: jekyll-theme-chirpy`），定制方式是**在仓库根放同名文件覆盖 gem 内文件**。
下列 `_includes/*` 都是从主题 7.6.0 整份拷来的，因此**升级主题时必须重新 diff**，否则会把上游改动丢掉。
每个文件顶部都有注释说明「相对主题的唯一改动」，改动请继续保持这种「最小 diff + 注释说明」的写法。

- `_includes/head.html` — 唯一改动：支持 `image.og` 作为 og:image / twitter:image 的位图回退
  （社交平台不渲染 SVG，所以动画封面要给一张 PNG）。
- `_includes/footer.html` — 唯一改动：在 `</body>` 前加载 `/assets/js/custom.js`。
- `_includes/sidebar.html` — 唯一改动：头像下的标题读 `site.sidebar.title`（`@ZouChao`）而非
  `site.title`（`邹超的博客`），后者仍用于 `<title>` 和 SEO。
- `assets/css/jekyll-theme-chirpy.scss` — 主题的 SCSS 入口拷贝后追加自定义样式：品牌橙强调色、
  代码块换行样式、四个动画（头像 hover、卡片渐入、标签 hover、最近更新下划线滑入）。
  强调色必须覆盖**四种选择器场景**才能同时管住「手动切换主题」和「跟随系统」：
  `:root[data-theme='light']`、`:root[data-theme='dark']`，以及
  `@media (prefers-color-scheme: light|dark)` 下的 `:root:not([data-theme])`——这就是那两个
  `brand-accents-*` mixin 存在的原因。同特异性下靠「后声明」胜出，别改动声明顺序。
- `assets/js/custom.js` — 渐进增强，两个 IIFE，与上面的 SCSS 成对存在：
  1. rouge/Chirpy 把行号和代码渲染成左右两个独立 `<pre>`，只靠相同行高对齐；一旦代码折行就错位。
     这里把两列各拆成「每行一个 span」（`.ln-line` / `.lc-line`），再用 ResizeObserver 让行号
     span 高度跟随代码 span，并给容器加 `.wrapped`（样式在 SCSS 里）。复制按钮取的是
     `td.rouge-code` 的文本，行号在 gutter 里，不受影响。
  2. IntersectionObserver 给首页 `#post-list .card-wrapper` 加 `.visible` 触发渐入。
     **卡片在 CSS 里初始 `opacity: 0`**，这段 JS 一旦失效卡片就会整片消失；无 JS 靠
     `@media (scripting: none)` 兜底。改这里务必连带验证无 JS 情况。

### URL 与 slug

`_config.yml` 的 defaults 把文章 permalink 设为 `/:title`（无日期、无尾斜杠），所以
**文件名 slug == URL slug == 封面目录名 `assets/img/posts/<slug>/`**。
重命名文章文件等于换 URL，而 giscus 评论用 `mapping: pathname` 按 URL 匹配 Discussion，
会导致老评论「消失」——非必要不改名。

## 内容约定

- 文章 front matter：`date` / `title` / `layout: post` / `tags` / `categories` / `image`。
  封面键名是 **`image.path`**（Chirpy 7.6），写成 `src` 会让整个 hash 被当字符串拼进 `src=`。
  可选 `image.og` 指定位图回退。正文是中文 Markdown，允许内嵌 `<style>` / HTML（kramdown）。
- **标签和分类的大小写必须与现有写法完全一致**：`git` 与 `Git` 会在 macOS 大小写不敏感盘上让
  jekyll-archives 撞 `/tags/<name>/` 目录，并在线上裂成两个标签页。新标签先 grep 现有写法对齐。
  现有分类：前端、git、工具、Go、Vim、Ruby、PHP、MySQL、Java。
- 提交信息用 conventional commits 前缀（`post:` / `feat:` / `fix:` / `style:` / `docs:` / `chore:`），
  中英文描述混用，与现有 git log 保持一致。

### 封面插图

所有文章封面都是**手写 SVG → Chrome headless 渲染成量化 PNG**，统一视觉规范。
配色、画布尺寸、文字估宽、光标位置公式、渲染后自检清单全部在
`.claude/skills/blog-illustration/`（`SKILL.md` 是流程，`REFERENCE.md` 是规范，`scripts/` 是渲染与审计）。
涉及配图、封面、插图的工作**一律走这个 skill**，不要另创风格；产物是
`assets/img/posts/<slug>/cover.svg` + 同目录 `cover.png`（front matter 引 PNG）。
SVG 里 shell 的 `&&` 必须写成 `&amp;&amp;`。

## 其他根目录文件

- `libre.json` / `tvbox.json` — 原样发布到站点根路径的订阅配置，由外部 App 消费，不是博客内容。
- `slideshare/` — 遗留的 reveal.js 幻灯片，静态托管在 `/slideshare/vim/`，由 2010 年那篇文章链接。
- `baidu_verify_*.html` / `google*.html` — 站长平台校验文件，别删。
- `.gitignore` 里的 `!*.svg` 是为了抵消 vim 交换文件规则 `*.s[a-w][a-z]`（它会误伤 `*.svg`），
  SVG 必须入库，别把这条否定规则删掉。
