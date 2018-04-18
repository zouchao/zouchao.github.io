# VI<i class="icon-maxcdn"></i>
### the ubiquitous text editor

Tue Dec 20 22:21:46 CST 2016

!---

## <i class="icon-linux"></i> Linux
## <i class="icon-apple"></i> apple
## <span><i class="icon-windows"></i> windows</span> <!-- .element: class="fragment" data-fragment-index="0" -->
Note: vim的版本已经到8.0

!---

- #### <i class="icon-terminal"></i> 一些简单的命令
- #### <i class="icon-tasks"></i> vim有几种模式？
- #### <i class="icon-keyboard"></i> 自定义快捷键
- #### <i class="icon-dropbox"></i> 丰富的插件
- #### <i class="icon-facetime-video"></i> 宏录制
- #### <i class="icon-gamepad"></i> 小游戏

Note: 这次演讲的主要内容, 大致的目的

!---

## <i class="icon-terminal"></i> 一些简单的命令


![vim shortcuts](https://ws1.sinaimg.cn/large/6a629b92gy1fqh6ja1nmoj20u00irdj9.jpg)


![vim cheat sheet for programmers print](https://ws1.sinaimg.cn/large/6a629b92gy1fqh6jzftz5j20u00n6k8y.jpg)

Note:
- x,ZZ或者:wq
- $来表示最后一行，而%代表每一行。复制全文，删除全文，替换
- 重复任务，.
- ctrl+g 显示当前行

!---

## <i class="icon-tasks"></i> VI<i class="icon-maxcdn"></i>有几种模式？


VIM主要有 ` 六 ` 种模式，和各种稀奇古怪的派生模式<!-- .slide: data-transition="fade-in fade-out" data-transition-speed="fast" -->
<!-- .element: class="fragment" data-fragment-index="0" -->


VIM主要有 ` 五 ` 种模式，和各种稀奇古怪的派生模式<!-- .slide: data-transition="fade-in slide-out" -->


- ### Normal Mode <!-- .element: class="fragment" data-fragment-index="0" -->
- ### Visual Mode <!-- .element: class="fragment" data-fragment-index="1" -->
- ### Insert Mode <!-- .element: class="fragment" data-fragment-index="2" -->
- ### Command-Line/Ex Mode <!-- .element: class="fragment" data-fragment-index="3" -->
- ### Select Mode <!-- .element: class="fragment" data-fragment-index="4" -->

Note:
- **Normal Mode** 也就是最一般的普通模式，默认进入vim之后，处于这种模式。
- **Visual Mode** 一般译作可视模式，在这种模式下选定一些字符、行、多列。在普通模式下，可以按v进入。
- **Insert Mode** 插入模式，其实就是指处在编辑输入的状态。普通模式下，可以按i进入。
- **Command-Line/Ex Mode** 普通模式下按Q进入Ex模式
- **Select Mode** 选择模式, 用鼠标拖选区域的时候，就进入了选择模式。和可视模式不同的是，在这个模式下，选择完了高亮区域后，敲任何按键就直接输入并替换选择的文本了。
和windows下的编辑器选定编辑的效果一致。普通模式下，可以按gh进入。

!---

## <i class="icon-keyboard"></i> 自定义快捷键


根据模式的不同，对于map而言，可能有这么几种前缀

1. nore 表示非递归，见下面的介绍
2. n 表示在普通模式下生效
3. v 表示在可视模式下生效
4. i 表示在插入模式下生效
5. c 表示在命令行模式下生效


###Recursive Mapping

```ruby
map a b
map c a

"对于c效果等同于
"map c b
```


![map list](https://ws1.sinaimg.cn/large/6a629b92gy1fqh6l1x1i8j20os09qgne.jpg)

!---

## <i class="icon-dropbox"></i> 丰富的插件


Vundle, the plug-in manager for Vim http://github.com/VundleVim/Vundle.Vim


```ruby
set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/Vundle.vim'
Plugin 'carlhuda/janus'
Plugin 'kien/ctrlp.vim'
Plugin 'scrooloose/nerdtree'
Plugin 'plasticboy/vim-markdown'
Plugin 'junegunn/vim-easy-align'
Plugin 'altercation/vim-colors-solarized'

call vundle#end()
filetype plugin indent on 
```
!---

## <i class="icon-facetime-video"></i> 宏录制

在vim中快速的打出一列自增长数字

!---

## <i class="icon-gamepad"></i> 小游戏

!---

# T<i class="icon-h-sign"></i>ANK YOU

[@ZOUCHAO](https://zouchao.me)
