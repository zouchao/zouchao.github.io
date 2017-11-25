---
date: 2013-08-27 12:26:00
title: git grep在版本库中使用详解
layout: post
tags:
    - git
    - grep
    - 搜索
    - ruby
categories:
    - git
---
背景：公司现在的团购站所使用的数据和主站有诸多联系，因此代码里面也有部分相互纠缠不清。现在要把他们单独独立出来。
### 首先还是介绍下git grep
git grep可以不用checkout就能很方便的查找Git库的一段文字。  
例如，我们要查找文件中哪些地方是用到了Redis:
<pre class="prettyprint linenums">
$ git grep Redis
user.rb:    Redis.current.hget(CheckinScoreHashKey, id).to_i
redis_initializer.rb:      Redis.current.client.reconnect
tasks/cheating_scores.rake:    Redis.current.del(fourDaysAgoKey) # 删除四天前的数据
javascripts/dashboard.js:      updateRedisStats(data.redis);
javascripts/dashboard.js:var updateRedisStats = function(data) {
</pre>
上例只能查出以大写字母开头的Redis相关的代码，可以附加参数`-i`，如果要显示行号还可以加参数`-n`:
<pre class="prettyprint linenums">
$ git grep -ni Redis
Gemfile:29:gem "redis", ">= 2.2.0", :require => ["redis", "redis/connection/hiredis"]
Gemfile.lock:199:    redis (3.0.1)
user.rb:35:    Redis.current.hget(CheckinScoreHashKey, id).to_i
redis_initializer.rb:9:      Redis.current.client.reconnect
tasks/cheating_scores.rake:25:    Redis.current.del(fourDaysAgoKey) # 删除四天前的数据
javascripts/dashboard.js:59:      updateRedisStats(data.redis);
javascripts/dashboard.js:123:var updateRedisStats = function(data) {
</pre>
上面这种查询用的比较多，但是有时候也许我们并不需要这些信息也许我们只要文件名字，并不需要看到这些片段,这时用`--name-only`这个参数就可以搞定，
但是我想给大家介绍的并不是这个参数，而是`-c`，这个参数不仅可以简洁的显示文件名，还可以显示所查找的字符串在文件中占了多少行(单行重复出现不做统计)
<pre class="prettyprint linenums">
$ git grep -c Redis
user.rb:1 
redis_initializer.rb:1
tasks/cheating_scores.rake:1
javascripts/dashboard.js:2
</pre>
可以看到`javascripts/dashboard.js`后面显示的是2，说明这个文件有2行有`Redis`,当然你可以配合`-i`,`-n`参数使用  
git grep还可以在历史的提交号，以及tag中查找，可以通过`git log`和`git tag`来查看有那些提交号和tag，使用方法
<pre class="prettyprint linenums">
$ git grep -ni Redis release_201306261815 #这里release_201306261815是tagName
.
.
.
$ git grep -ni Redis aa4a326d4feb0f3b69f423bd66b6bc6558742c8d #提交号也可以简写aa4a326
.
.
.
</pre>
### 一个更实用的ruby脚本
这是同事分享的一段ruby脚本可以查询到是哪一行，最后是哪个人操作过这段代码。方便了解功能逻辑，不多废话了，上代码：  
文件名: `blame_after_grep.rb`
<pre class="prettyprint linenums">
#!/usr/local/bin/ruby
 
grep = `git grep -n #{ARGV[0]} #{ARGV[1]}`

interrupt = false 

grep.lines.each do |file_with_line|
  exit if interrupt

  file, line_number, line = file_with_line.split(':', 3)
  author = `git blame --line-porcelain -L #{line_number},#{line_number} #{file} | sed -n 's/^author //p'`
  puts "#{ author.rstrip } #{file} +#{line_number} #{ line.lstrip.rstrip }"
 
  trap('INT'){interrupt = true} 
end
</pre>
用法：
<pre class="prettyprint linenums">
$ ruby blame_after_grep.rb 'Redis' | grep ZouChao
</pre>
查询的展示结果如下：
<pre class="prettyprint linenums">
ZouChao user.rb +35:    Redis.current.hget(CheckinScoreHashKey, id).to_i
ZouChao tasks/cheating_scores.rake +25 Redis.current.del(fourDaysAgoKey) # 删除四天前的数据
</pre>
