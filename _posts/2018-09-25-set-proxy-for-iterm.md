---
date: 2018-09-25 09:45:08
title: 给终端设置代理
layout: post
tags:
    - 代理
categories:
    - 代理
---

如下是初级工程师Bob和老程序员Bill的又一个故事。

> Bob：我这`golang`装个包太困难了。动不动就`time out`  
> Bill：开代理啊  
> Bob：开了，我有`shadowsocks`, 而且我开了全局代理.  
> Bill: 那你一定是没有给你的终端设置`http`代理。ss设置的系统代理是`socks5`代理, 给你一个教程吧!

### 教程

* 首先找到ss里面的HTTP Proxy Preference, 如下图：

![](https://ws1.sinaimg.cn/large/6a629b92gy1fvmpbmzbm5j207l0dldgk.jpg)

* 然后查看你的端口：

![](https://ws1.sinaimg.cn/large/6a629b92gy1fvmpcgrot0j20hu0ietax.jpg)

* 在`~/.bashrc`或者`~/.zshrc`中加入如下代码:
```shell
# alias for proxy
alias proxy="export http_proxy=http://127.0.0.1:1087 && export https_proxy=http://127.0.0.1:1087"
alias unproxy="unset http_proxy && unset https_proxy"
alias ip="curl https://ip.cn"
```

* 检查是否使用代理

![](https://ws1.sinaimg.cn/large/6a629b92gy1fvmw5i1ngnj20hy0833zh.jpg)
