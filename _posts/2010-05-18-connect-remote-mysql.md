---
date: 2010-05-18 15:50:00
title: mysql开放远程访问的设置问题
keywords: mysql,远程访问,数据库
layout: post
tags:
    - mysql
    - 远程访问
    - 数据库
categories:
    - mysql
---
mysql安装好后默认是不支持远程访问的，如果要使mysql能被远程访问需要做一些什么操作呢？  
一、首先在安装mysql的服务器，登陆mysql:`mysql -u用户名 -p密码`
<pre class="prettyprint">
use mysql;
grant all privileges on *.* to '用户名'@'%' identified by '密码';
flush privileges;
</pre>
二、修改mysql的绑定`sudo vi /etc/mysql/my.cnf`修改`bind-address = 0.0.0.0`
