---
date: 2017-07-06 11:00:12
title: 如何使用Visual Studio Code调试Golang程序
layout: post
tags:
    - IDE
    - Golang
    - VSCode
categories:
    - 建站
    - blog
---

最近想玩玩golang，同事安利了一个编辑器`Visual Studio Code`, 是用nodejs开发的，用起来十分趁手,如何配置golang的环境就不表了，网上帖子一大把，自行查阅。

今天只说说如何用`VSCode`的debug模式调试`Golang`：

1. 在VSCode中打开你的`package main`的文件

2. `(Shift) ⇧ + (Command) ⌘ + D`呼出`debug`侧边栏

3. 点击绿色三角形符号的`Start Debugging`按钮

4. 第一次使用VSCode会自动判断你的语言类型，生产如下的一个`launch.josn`文件
![](https://ww1.sinaimg.cn/large/6a629b92gy1fluf8ejfztj21r41asan3.jpg)

5. 成功之后会在你所在的项目目录下生产如下2个文件
```
debug
.vscode/launch.json
```

6. `git status`也能看到他们，所以别忘了把他们加到`.gitignore`文件中去哦
![](https://ww1.sinaimg.cn/large/6a629b92gy1flufndpw0fj211w0vcag6.jpg)

#### 当然你也有可能和我一样遇到如下问题：
```
2017/11/24 15:34:15 server.go:73: Using API v1
2017/11/24 15:34:15 debugger.go:96: launching process with args: [/Users/sean/Code/Go/src/go_bms_web/debug]
could not launch process: exec: "lldb-server": executable file not found in $PATH
Process exiting with code: 1
```
没关系，在terminal中执行如下语句，就可以了
```
xcode-select --install
```
