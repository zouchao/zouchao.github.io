---
date: 2018-09-25 09:45:08 +0800
title: 给终端设置代理
layout: post
tags:
    - proxy
categories:
    - 工具
image:
    path: /assets/img/posts/set-proxy-for-iterm/cover.png
    alt: 终端 HTTP 代理配置：Shadowsocks 端口与 zshrc alias 快切
---

如下是初级工程师Bob和老程序员Bill的又一个故事。

> Bob：我这`golang`装个包太困难了。动不动就`time out`  
> Bill：开代理啊  
> Bob：开了，我有`shadowsocks`, 而且我开了全局代理.  
> Bill: 那你一定是没有给你的终端设置`http`代理。ss设置的系统代理是`socks5`代理, 给你一个教程吧!

### 教程

* 首先找到ss里面的HTTP Proxy Preference, 如下图：

![Shadowsocks 的 HTTP Proxy 设置与端口](/assets/img/posts/set-proxy-for-iterm/pref-pane.png)

* 然后确认端口（我这里是 1087，即下面 alias 里的地址）：

* 在`~/.bashrc`或者`~/.zshrc`中加入如下代码:
```shell
# alias for proxy
alias proxy="export http_proxy=http://127.0.0.1:1087 && export https_proxy=http://127.0.0.1:1087"
alias unproxy="unset http_proxy && unset https_proxy"
alias ip="curl https://ip.cn"
```

* 检查是否使用代理

![proxy/unproxy 切换后的出口对照](/assets/img/posts/set-proxy-for-iterm/verify.png)
