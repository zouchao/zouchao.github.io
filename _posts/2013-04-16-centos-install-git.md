---
date: 2013-04-16 11:26:00
title: CentOS下安装git
keywords: CentOS,git
layout: post
tags:
    - 工具安装
    - git
categories:
    - git
---
centos的yum源中没有git，所以需要源码安装。留文以作记录。
#### 依赖包安装
<pre class="prettyprint">
yum install gcc curl curl-devel zlib-devel openssl-devel perl perl-devel cpio expat-devel gettext-devel
</pre>
#### 下载源码包
<pre class="prettyprint">
wget https://git-core.googlecode.com/files/git-1.8.1.6.tar.gz
tar xzvf git-1.8.1.6.tar.gz
</pre>
#### 编译安装
<pre class="prettyprint">
cd git-1.8.1.6
autoconf
./configure
make
sudo make install 
</pre>
OK！如果一路顺利没有看见error那么恭喜你，安装成功。
#### 验证
<pre class="prettyprint">
git --version
</pre>
