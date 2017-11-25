---
date: 2013-05-16 12:26:00
title: Git常用命令收集
layout: post
tags:
    - git
    - 版本控制
categories:
    - git
---
### 1) 远程仓库相关命令

> 检出仓库：`$ git clone git://github.com/jquery/jquery.git`  
> 查看远程仓库：`$ git remote -v`  
> 添加远程仓库：`$ git remote add [name] [url]`  
> 删除远程仓库：`$ git remote rm [name]`  
> 修改远程仓库：`$ git remote set-url --push [name] [newUrl]`  
> 拉取远程仓库：`$ git pull [remoteName] [localBranchName]`  
> 推送远程仓库：`$ git push [remoteName] [localBranchName]`  

如果想把本地的某个分支test提交到远程仓库，并作为远程仓库的master分支，或者作为另外一个名叫test的分支，如下：

<pre class="prettyprint">
$ git push origin test:master         // 提交本地test分支作为远程的master分支
$ git push origin test:test              // 提交本地test分支作为远程的test分支
</pre>

### 2）分支(branch)操作相关命令

> 查看本地分支：`$ git branch`  
> 查看远程分支：`$ git branch -r` （如果还是看不到就先 git fetch origin 先）  
> 创建本地分支：`$ git branch [name]` ----注意新分支创建后不会自动切换为当前分支  
> 切换分支：`$ git checkout [name]`  
> 创建新分支并立即切换到新分支：`$ git checkout -b [name]`  
> 直接检出远程分支：`$ git checkout -b [name] [remoteName]` (如：`git checkout -b myNewBranch origin/dragon`)  
> 删除分支：`$ git branch -d [name]` ---- -d选项只能删除已经参与了合并的分支，对于未有合并的分支是无法删除的。如果想强制删除一个分支，可以使用-D选项  
> 合并分支：`$ git merge [name]` ----将名称为[name]的分支与当前分支合并  
> 合并最后的2个提交：`$ git rebase -i HEAD~2` ---- 数字2按需修改即可（如果需提交到远端`$ git push -f origin master` 慎用！）  
> 创建远程分支(本地分支push到远程)：`$ git push origin [name]`  
> 删除远程分支：`$ git push origin :heads/[name]` 或 `$ git push origin :[name]`  

创建空的分支：(执行命令之前记得先提交你当前分支的修改，否则会被强制删干净没得后悔)

<pre class="prettyprint">
$ git symbolic-ref HEAD refs/heads/[name]
$ rm .git/index
$ git clean -fdx
</pre>

### 3）版本(tag)操作相关命令

> 查看版本：`$ git tag`  
> 创建版本：`$ git tag [name]`  
> 删除版本：`$ git tag -d [name]`  
> 查看远程版本：`$ git tag -r`  
> 创建远程版本(本地版本push到远程)：`$ git push origin [name]`  
> 删除远程版本：`$ git push origin :refs/tags/[name]`  
> 合并远程仓库的tag到本地：`$ git pull origin --tags`  
> 上传本地tag到远程仓库：`$ git push origin --tags`  
> 创建带注释的tag：`$ git tag -a [name] -m 'yourMessage'`

### 4) 子模块(submodule)相关操作命令

* 添加子模块：`$ git submodule add [url] [path]`  
  如：`$ git submodule add git://github.com/soberh/ui-libs.git src/main/webapp/ui-libs`  
* 初始化子模块：`$ git submodule init  ----只在首次检出仓库时运行一次就行`  
* 更新子模块：`$ git submodule update ----每次更新或切换分支后都需要运行一下`  
* 删除子模块：（分4步走哦）
  1. $ git rm --cached [path]
  2. 编辑“.gitmodules”文件，将子模块的相关配置节点删除掉
  3. 编辑“ .git/config”文件，将子模块的相关配置节点删除掉
  4. 手动删除子模块残留的目录

### 5）忽略一些文件、文件夹不提交

在仓库根目录下创建名称为`.gitignore`文件，写入不需要的文件夹名或文件，每个元素占一行即可，如

<pre class="prettyprint">
target
bin
*.db
</pre>

### 6）后悔药

> 删除当前仓库内未受版本管理的文件：`$ git clean -f`  
> 恢复仓库到上一次的提交状态：`$ git reset --hard`  
> 回退所有内容到上一个版本：`$ git reset HEAD^`  
> 回退a.py这个文件的版本到上一个版本：`$ git reset HEAD^ a.py`  
> 回退到某个版本：`$ git reset 057d `  
> 将本地的状态回退到和远程的一样：`$ git reset –hard origin/master`  
> 向前回退到第3个版本：`$ git reset –soft HEAD~3`  

### 7）Git一键推送多个远程仓库

编辑本地仓库的`.git/config`文件：

<pre class="prettyprint">
[remote "all"]
url = git@github.com:dragon/test.git
url = git@gitcafe.com:dragon/test.git
</pre>

这样，使用git push all即可一键Push到多个远程仓库中。

资料参考：

* [Git Submodule 的認識與正確使用！](http://josephjiang.com/entry.php?id=342)
* [如何保持在 Git Submodule 代码的开放和私有共存](http://icyleaf.com/2010/08/03/how-to-keep-public-and-private-versions-of-a-git-submodule-repo-in-sync/)
* [Git Submodule Tutorial](https://git.wiki.kernel.org/index.php/GitSubmoduleTutorial)
* [删除 git submodule ](http://blog.ossxp.com/2010/01/425/)
* [pages.github.com](http://pages.github.com/)
* [Git获取远程分支](http://lfeng.me/2009/07/23/git-remote-branch-access/)
* [Git for Windows Unicode Support](https://github.com/msysgit/msysgit/wiki/Git-for-Windows-Unicode-Support)
* [Git一键推送多个远程仓库](http://my.oschina.net/chinesedragon/blog/81483)
* [图解Git](http://my.oschina.net/u/198088/blog/114383)
* [使用git并多个提交](http://www.cnblogs.com/wujianlundao/archive/2012/07/30/2615873.html)
* [git:多个commit合并提交](http://zn-moonlight-gmail-com.iteye.com/blog/1217841)
* [git merge 和git rebase](http://blog.csdn.net/nebulali/article/details/7682813)
* [版本控制系統 Git 精要](http://ihower.tw/git/)

说明：Git for Windows 从 1.7.9 版本开始支持使用中文文件、文件夹名称了，结束了跨平台中文乱码的问题。

