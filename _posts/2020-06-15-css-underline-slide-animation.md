---
date: 2020-06-15 21:00:00 +0800
title: 纯 CSS 实现文字下划线滑入滑出动画
layout: post
tags:
  - CSS
categories:
  - 前端
---

给链接加个 hover 下划线不稀奇，但如果下划线能**像穿越一样滑过去**——鼠标移入时从左到右划过，移出时也从左到右消失——就像一条线从文字底部滑过然后离开，整体质感立刻不一样。这个效果不需要 JavaScript，纯 CSS 就能搞定，核心就一招：**用 `background-image` 画一条渐变线，靠 `background-size` 和 `background-position` 控制动画方向**。

## 最终效果

鼠标移入：下划线从左向右展开；鼠标移出：下划线继续从左向右消失，像穿过文字一样。试试下面这几个链接 👇

<style>
  .demo-underline-box {
    padding: 1rem 0;
    margin-bottom: 1.5rem;
    max-width: 500px;
  }
  .demo-underline-box li {
    list-style: none;
    padding: 0.6rem 0;
    border-bottom: 1px solid var(--btn-border-color, #e9e9e9);
  }
  .demo-underline-box li:last-child {
    border-bottom: none;
  }
  .demo-underline-box a {
    font-size: 1.05rem;
    line-height: 1.6;
    color: var(--link-color) !important;
    text-decoration: none !important;
    border-bottom: none !important;
    background-image: linear-gradient(var(--link-color), var(--link-color));
    background-size: 0% 1px;
    background-repeat: no-repeat;
    background-position: right bottom;
    transition: background-size 1.5s ease;
  }
  .demo-underline-box a:hover {
    background-size: 100% 1px;
    background-position: left bottom;
  }
</style>

<ul class="demo-underline-box">
  <li><a href="javascript:void(0)">纯 CSS 实现文字下划线滑入滑出动画：用 background-image 替代 ::after 伪元素方案</a></li>
  <li><a href="javascript:void(0)">一台 Mac 多个 git 身份：用 includeIf hasconfig 按远程地址自动切换</a></li>
  <li><a href="javascript:void(0)">用 4000 张图训一个牙科照片分类器：从 VL 大模型试错到 ResNet-18 落地</a></li>
</ul>

## 原理

常规思路是用 `::after` 伪元素 + `transform: scaleX()` 来做，但 `scaleX` 方案在移入移出方向相反时，需要靠 `transform-origin` 的瞬间切换来制造方向差，实际效果不够丝滑。

换一个思路：把下划线当成**背景**来画。CSS 的 `background-image` 可以是一个纯色渐变（`linear-gradient(color, color)`），配合 `background-size` 控制宽度、`background-position` 控制锚点，就能用 `transition` 做出方向可控的滑动效果。

关键在于 `background-position` 的切换：

| 状态  | `background-size` | `background-position` | 视觉效果               |
| ----- | ----------------- | --------------------- | ---------------------- |
| 默认  | `0% 1px`          | `right bottom`        | 无下划线，锚点在右侧   |
| hover | `100% 1px`        | `left bottom`         | 下划线铺满，锚点在左侧 |

**移入时**：position 瞬间切到 `left`，size 从 `0%` 过渡到 `100%`——线从左侧开始生长，向右展开。

**移出时**：position 瞬间切回 `right`，size 从 `100%` 回到 `0%`——锚点在右侧，所以线从左侧开始收缩，向右消失，看起来就像下划线从左到右穿过了文字。

`background-position` 本身没有过渡（在两个关键词之间切换是瞬间的），但正是这个瞬间切换制造了方向差——和 `scaleX` + `transform-origin` 的思路一样，只不过 background 方案在视觉上更平滑，因为它控制的是尺寸而不是缩放。

## 代码

```css
a {
  text-decoration: none;
  background-image: linear-gradient(currentColor, currentColor);
  background-size: 0% 1px;
  background-repeat: no-repeat;
  background-position: right bottom;
  transition: background-size 0.8s ease;
}

a:hover {
  background-size: 100% 1px;
  background-position: left bottom;
}
```

就这么多。逐行解释：

- `background-image: linear-gradient(currentColor, currentColor)` — 用当前文字颜色画一条纯色渐变，这样下划线颜色自动跟随链接色，暗色模式也不用额外适配
- `background-size: 0% 1px` — 宽度为 0（隐藏），高度 1px（下划线粗细）
- `background-repeat: no-repeat` — 不平铺
- `background-position: right bottom` — 锚定在右下角（移出时收缩方向的关键）
- `transition: background-size 0.8s ease` — 只对 size 做过渡，position 的切换保持瞬间
- hover 时 `background-size: 100% 1px` + `background-position: left bottom` — 铺满，锚点切到左边

## 调参

根据使用场景调整几个值就行：

**下划线粗细**：改 `background-size` 的第二个值，`2px` 更粗更醒目。

**动画速度**：`transition` 的时长。导航链接用 `0.3s~0.5s` 比较灵敏，内容区链接可以放慢到 `0.8s~2s`，感觉更从容。

**下划线颜色**：把 `currentColor` 换成具体色值，比如品牌色：

```css
background-image: linear-gradient(#c2410c, #c2410c);
```

**下划线位置**：`bottom` 改成具体数值可以调下划线和文字的间距：

```css
background-position: right calc(100% - 2px);
```

**反方向**：如果想要"从右到左进入、从左到右消失"，把默认和 hover 的 `background-position` 对调即可。

## 为什么不用 `text-decoration-*`

CSS 有原生的 `text-decoration` 系列属性（`text-decoration-color`、`text-decoration-thickness`），但它们目前**不支持对 `text-decoration` 整体做方向性动画**——你只能让下划线淡入淡出（`transition: text-decoration-color`），做不到方向滑动。

`::after` + `scaleX` 是另一个经典方案，效果也能做，但需要额外的伪元素和定位，代码量更多，而且 `scaleX` 在某些浏览器上有亚像素渲染的锯齿问题。background 方案代码更少、兼容性更好（`background-size` 的 transition 支持到 IE10+），是目前最优雅的写法。

## 兼容性

这个方案用到的属性（`background-image`、`background-size`、`background-position`、`transition`）兼容性都很好，所有现代浏览器都支持，IE10+ 也没问题。唯一需要注意的是 `currentColor` 在极老的浏览器上可能不支持，换成具体颜色就行。

## 小结

一条 `linear-gradient` 当下划线，`background-size` 控制长度，`background-position` 控制方向——三个属性，一行 transition，零 JavaScript。进出都是从左到右，像一条线穿过文字底部。下次给导航、文章列表、侧边栏链接加交互效果时，可以直接拿去用。
