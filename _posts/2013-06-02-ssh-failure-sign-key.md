---
date: 2013-06-02 12:26:00 +0800
title: 解决Agent admitted failure to sign using the key的方法
layout: post
tags:
    - git
    - 版本控制
    - SSH
categories:
    - git
image:
    path: /assets/img/posts/ssh-failure-sign-key/cover.png
    alt: Agent 签名失败：ssh-agent 持旧钥与服务器公钥错位，ssh-add 修复
---
这两天没事瞎折腾`ruby`的`heroku`，把`~/.ssh/id_rsa`搞乱了，结果直接导致我在`github`上的项目没法管理了！对于刚接触`git`不久的我来说算是遇到一个不大不小的麻烦了！

```shell
$git push origin master 
Agent admitted failure to sign using the key.
Permission denied (publickey).
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

### 解决方法

```shell
$ssh-add
Identity added: /home/user/.ssh/id_rsa (/home/user/.ssh/id_rsa)
```

