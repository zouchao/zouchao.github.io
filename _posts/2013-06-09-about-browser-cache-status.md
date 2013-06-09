---
date: 2013-06-09 15:26:00
title: 关于浏览器缓存的利用 
layout: post
tags:
    - 缓存
    - php
    - header
categories:
    - 缓存
---
关于浏览器缓存，在header中有如下几个：（以下示例均为php代码）

###Last-Modified

1. 浏览器第一次打开 返回状态码 200
2. 浏览器第二次打开 返回状态码 304
3. 删除服务器文件 再访问 返回状态码 404

说明：每次打开页面依然需要向服务器发起http请求，浏览器根据用户的 `$_SERVER['HTTP_IF_MODIFIED_SINCE']` 来判断缓存是否过期
<pre class="prettyprint linenums">
$cache_time = 3600; 
$modified_time = @$_SERVER['HTTP_IF_MODIFIED_SINCE']; 
if( strtotime($modified_time)+$cache_time > time() ){ 
   header("HTTP/1.1 304"); 
   exit; 
} 
header("Last-Modified: ".gmdate("D, d M Y H:i:s", time() )." GMT");  
echo time(); 
</pre>

###Expires
1. 浏览器第一次打开 返回状态码 200
2. 浏览器第二次打开 返回状态码 200
3. 删除服务器文件 在访问 返回状态码 200

_注意：此处的过期时间实际是服务器的时间，因此如果客户端和服务端时间不一致，缓存可能不能起到效果_
<pre class="prettyprint linenums">
$cache_time = 3600; 
header("Expires: ".gmdate("D, d M Y H:i:s", time()+$cache_time )." GMT");    
echo time(); 
</pre>
###Cache-Control
1. 浏览器第一次打开 返回状态码 200
2. 浏览器第二次打开 返回状态码 200
3. 删除服务器文件 在访问 返回状态码 200

说明：`Cache-Control`就弥补了`Expires`的这种缺点,过期时间完全和客户端一致
<pre class="prettyprint linenums">
$cache_time = 3600; 
header("Cache-Control: max-age=".$cache_time); 
echo time(); 
</pre>


