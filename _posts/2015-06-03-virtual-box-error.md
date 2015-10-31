---
date: 2015-06-03 12:36:33
title: VirtualBox无法启动报错
layout: post
tags:
    - virtual box
    - VM
    - centos
categories:
    - tools
---

由于本屌穷且爱折腾，因此目前大多数时候的工作环境都是在linux虚拟机下面。虽然有备份但是一般也是几个月的周期才备份一次（原谅我是个懒人）

但是就在今天来公司我发现我的虚拟机居然神奇般的打不开了

> 不能为虚拟电脑 Centos 打开一个新任务.  
> VM cannot start because the saved state file   
> 'F:\VirtualBox VMs\Centos\Snapshots\2015-06-03T02-43-10-456513000Z.sav' is invalid (VERR_FILE_NOT_FOUND)  
> Delete the saved state prior to starting the VM.   
> 返回 代码:VBOX_E_FILE_ERROR (0x80BB0004) 组件:Console 界面:IConsole {db7ab4ca-2a3f-4183-9243-c1208da92392}

这个可给我吓出一身冷汗啊，今天还必须的完成一个重要的项目呢。

不过还好感谢万能的GOOGLE，查到了解决办法，因此留文存档，用以警示自己帮助他人。

#### 解决办法(本方案只针对virtual box):

打开Oracle VM VirtualBox管理器主界面（GUI） - 控制 - 清除保存的状态（I）


