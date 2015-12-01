---
date: 2015-03-22 16:06:00
title: webp图片格式配置，bundle时web_ffi未成功
layout: post
tags:
    - webp
    - web-ffi
    - bundle
    - gem
categories:
    - gem
---
首先安装依赖包
### 1. 安装依赖包

`CentOS:`  
sudo yum install libjpeg-devel libpng-devel libtiff-devel  
`Ubuntu:`  
sudo apt-get install libjpeg-dev libpng-dev libtiff-dev  
`MaxOS:`  
sudo  port install jpeg libpng tiff

### 2. Building:
<pre class="prettyprint linenums">
git clone https://chromium.googlesource.com/webm/libwebp
cd libwebp
./autogen.sh
./configure
make
sudo make install
</pre>
### 3. 安装webp gem
`gem install webp-ffi`
### 4. 如果以上两步装完后，启动服务器并且访问出错，错误信息类似：
.rvm/gems/ruby-2.0.0-p247@tuan800/gems/webp-ffi-0.1.7/ext/webp_ffi/x86_64-linux/libwebp_ffi.so

解决方法：  
sudo sh -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/user_local.conf'  
sudo ldconfig
