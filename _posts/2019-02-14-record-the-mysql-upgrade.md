---
date: 2019-02-14 11:14:12
title: 记录一次mysql升级之后rails遇到的问题
layout: post
tags:
   - rails
   - activerecord
   - mysql
   - ruby
categories:
   - activerecord
---

mysql升级之后数据文件夹共用, 但是无法使用`db:migrate`

错误信息大致如下：

```ruby
E, [2019-02-14T11:06:23.650106 #68912] ERROR -- : Mysql2::Error: Table 'performance_schema.session_variables' doesn't exist: SHOW VARIABLES LIKE 'character_set_database'
rake aborted!
ActiveRecord::StatementInvalid: Mysql2::Error: Table 'performance_schema.session_variables' doesn't exist: SHOW VARIABLES LIKE 'character_set_database'
```
解决方式：
```shell
mysql_upgrade -u 用户名 -p --force
```
然后一定记得重启mysql服务
