---
date: 2015-10-27 14:00:00
title: 安装Laravel Homestead遇到的坑
layout: post
tags:
    - php
    - laravel
    - vagrant
    - virtualbox
categories:
    - php
    - virtualbox
---

#### 一、安装条件
由于`VMWare`需要收费，本章只介绍安装`Vagrant`和`VirtualBox`所遇到的麻烦，首先请在如下  
网站下载和自己系统匹配的安装包，并完成安装

> * VirtualBox： [https://www.virtualbox.org/wiki/Downloads] [virtualbox_url]

> * Vagrant： [https://www.vagrantup.com/downloads.html][vagrant_url]

然后
<pre class="prettyprint">
vagrant box add laravel/Homestead
</pre>
#### 二、安装中断，没法继续？
兴高采烈安Homestead，网速太渣报错误：
![SSL read: error:00000000:lib(0):func(0):reason(0), errno 54] [1]
无奈又来第二次，结果始终报如下错误:
![HTTP server doesn't seem to support byte ranges. Cannot resume.] [2]
解决办法：
<pre class="prettyprint">
rm ~/.vagrant.d/tmp/*
</pre>

#### 三、更好的方式
1. 更好的方式还是直接下载下来文件,但是用p2p工具的同学千万记住不要用离线下载, 也千万不要用高速通道，就是这么残忍，坑在这里：  
    ![bsdtar: Error opening archive: gzip decompression failed] [3]  
    没错 当你下载的文件名叫`virtualbox.box`那么你很可能已经陷入这个深坑了，正确的文件名大致是这样的`hc-download`，下载完毕了再修改文件名后缀

2. 貌似还有一种方式：
    <pre class="prettyprint">
    vagrant box add laravel/Homestead -c </pre>
    加`-c`参数，作用是断点续传，但是我亲试之后还是有问题的，只怪我网络环境特别不好，一、两次可以，多几次之后并没有断点续传。不知道是不是我的问题。大家可以试试，成功的话，希望评论告知，感激

#### 四、福利始终在最后
提供的版本`homesteam0.3.0_virtualbox.box`
百度云盘下载链接: [http://pan.baidu.com/s/1jGfIahw][pan.baidu.com] 密码: `9xbp`


[virtualbox_url]: https://www.virtualbox.org/wiki/Downloads
[vagrant_url]: https://www.vagrantup.com/downloads.html
[pan.baidu.com]: http://pan.baidu.com/s/1jGfIahw

[1]: https://ws1.sinaimg.cn/large/6a629b92gy1fqh64k1hhcj20u008vju4.jpg 'SSL read: error:00000000:lib(0):func(0):reason(0), errno 54'
[2]: https://ws1.sinaimg.cn/large/6a629b92gy1fqh65po22qj20u00ajjue.jpg "HTTP server doesn't seem to support byte ranges. Cannot resume."
[3]: https://ws1.sinaimg.cn/large/6a629b92gy1fqh672m9urj20mn04n0ty.jpg "bsdtar: Error opening archive: gzip decompression failed"
