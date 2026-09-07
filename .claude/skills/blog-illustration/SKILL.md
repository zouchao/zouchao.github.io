---
name: blog-illustration
description: 为 zouchao.github.io（Jekyll + Chirpy）博客文章生成统一风格的封面与插图（手绘 SVG → Chrome 渲染 PNG），并挂载到 front matter / 正文。Use when 用户要求给博客文章配图、画封面、加插图、为新文章出图，或检查/修复现有封面（光标位置、溢出、死链替换）。
---

# Blog Illustration

## 单一事实来源

- 视觉规范：本 skill 的 [REFERENCE.md](REFERENCE.md)（色板、版式语法、文字估宽、XML 转义、光标公式），自包含，不依赖仓库其他文档。动手前必读。
- 范本：仓库 `assets/img/posts/ssh-config-notes/cover.svg`。
- 渲染脚本：本 skill 的 `scripts/render-svg.sh`（SVG → 2400×1350、128 色量化 PNG，应 ≤300KB）。

## 单篇流程

1. 通读文章，提取机制与**真实值**（命令、报错、IP、配置项；禁止编造文章没有的事实）。
2. 画 SVG → `assets/img/posts/<slug>/cover.svg`（slug = 文件名去日期和 `.md`；画布固定 1600×900）。
   两条高频坑：shell `&&` 在 SVG 里必须写 `&amp;&amp;`；标题光标 rect 的
   x = 标题 text x + 字符数 × 字号 × 0.60 + 14。
3. 执行 `bash .claude/skills/blog-illustration/scripts/render-svg.sh assets/img/posts/<slug>/cover.svg`，
   然后 **Read PNG 自检**：文字无溢出/压盖、箭头连接正确、中文非豆腐块、光标不压字不离太远。有问题改 SVG 重渲染。
4. 挂封面：front matter 结束 `---` 前插入（已有 `image:` 则跳过）：

   ```yaml
   image:
       path: /assets/img/posts/<slug>/cover.png
       alt: 一句话中文描述
   ```

   键名是 `path`（Chirpy 7.6）。写成 `src` 会让整个 hash 被当字符串拼进 `src=`。
5. 可选插图（每篇 ≤1，仅当流程图明显比文字清楚时）：同目录自命名 svg，**不要大页眉**；
   正文最有助于理解处插入 `![中文alt](/assets/img/posts/<slug>/<name>.png)`（前后空行）。
6. 验证：本地 serve 页面或 `_site/<slug>.html` 里封面 href 存在、无 `/{` 残留。

## 批量流程（多篇）

- 并行派子 agent，每人 ≤5 篇；prompt 必须包含：先读 STYLE.md 与范本、执行上面单篇流程全文、
  渲染后 Read 自检、不改文章其他内容、不 git commit。
- 收活后统一 QA：
  1. 总览拼贴：`magick montage $(所有 cover.png) -tile 4x4 -geometry 760x428+8+8 -background '#20242c' /tmp/grid.png` 后 Read；
  2. 光标审计：`bash .claude/skills/blog-illustration/scripts/audit-cursors.sh`，
     列出偏差 >6px 的封面，用 `/usr/bin/sed -i ''` 改 rect x 后重渲染（注意 GNU sed 的 `-i` 语义不同）；
  3. 疑点放大：`magick cover.png -crop 1400x260+0+0 +repage /tmp/crop.png` 再 Read。
- 子 agent 断线（idle_notification failed）不要重派新 agent：先看磁盘进度，再 SendMessage 让原 agent 从断点续跑。

## 替换历史裂图

- 文本类截图（报错、命令输出、配置文件）→ 还原成围栏代码块，内容取自 alt 或正文，信息零损失。
- GUI 类截图 → 按规范重画插图替换；示意值用 `x.x.x.x` 占位，不编造具体数据。
- 完工标准：`grep -rn sinaimg _posts/` 为零（或其他死图床域名）。

## 相关坑备忘

- 标签大小写不统一（`Git` vs `git`）会让 jekyll-archives 在 macOS 大小写不敏感盘上撞目录、
  在线上裂成两个标签页；新文章标签先 grep 现有写法对齐。
- 主题 gem 自带 `site.webmanifest`，与仓库同名文件冲突警告属原有、无害，忽略。
