# 邹超的博客

> 记录、整理、分享 —— 一个程序猿的技术自留地

线上地址：<https://zouchao.github.io>

## 技术栈

- 静态生成：[Jekyll](https://jekyllrb.com/)
- 主题：[Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy)
- 部署：GitHub Actions 构建 → GitHub Pages（见 `.github/workflows/pages-deploy.yml`）

## 本地运行

```bash
bundle install
bundle exec jekyll serve
```

## 目录结构

- `_posts/`：文章
- `_tabs/`：侧边栏页面（归档、标签、分类、关于）
- `_config.yml`：站点配置
- `slideshare/`：本地托管的旧幻灯片静态页
