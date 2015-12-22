---
date: 2015-03-23 10:59:10
title: Vundle管理vim插件
layout: post
tags:
    - git
    - vim 
    - Vundle
categories:
    - vim
---
### 使用Vundle管理安装vim插件

`$ git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim`

再在vimrc加类似如下配置:

<pre class="prettyprint linenums">
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/vundle'
Plugin 'tpope/vim-fugitive'
Plugin 'Lokaltog/vim-easymotion'
.
# 此处放置你需要安装的插件
.

call vundle#end()
filetype plugin indent on     " required!
</pre>

然随意打开一个vim窗口
<pre class="prettyprint linenums">
$ vim
:PluginInstall
</pre>

### 我的vimrc:

<pre class="prettyprint linenums">
if has('gui_running')
  " set background=light
  set background=dark
else
  set background=dark
endif
let g:solarized_termcolors=256
set tabstop=2
set shiftwidth=2
set laststatus=2
" set dictionary+=$HOME/.mydict
" set dictionary+=/usr/share/dict/words
set isk+=- "把-分割的单词视为一个整体
" set mouse=nv
set encoding=utf-8 fileencodings=ucs-bom,utf-8,cp936
set autoindent
set cindent
set sw=2
set ts=2
set expandtab
set number                     " 行号
syntax on                      " 语法高亮
syntax enable

autocmd FileType php setlocal tabstop=4 shiftwidth=4 softtabstop=4 textwidth=79

nnoremap < v<
nnoremap > v>
vnoremap < <gv
vnoremap > >gv

let mapleader = ","
map <F3> :%s/\s*$//g<CR>:noh<CR>   "移除行尾空格
nmap <F2> :NERDTreeToggle <CR>
nmap ff :NERDTreeFind <CR>
nmap gb :Gblame <CR>
imap zsj <c-r>=strftime("%F %T")<CR>
"set cursorline "高亮光标所在行
let Tlist_Use_Right_Window=1 "方法列表放在屏幕的右侧

set list
set listchars=tab:,.,trail:.,extends:#,nbsp:.
let g:vim_markdown_folding_disabled=1


set guifont=Monaco:h15
set nocompatible               " be iMproved
filetype off                   " required!
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle
" " required!
Plugin 'gmarik/Vundle.vim'

" My Plugins here:
"
" original repos on github
Plugin 'tpope/vim-fugitive'
Plugin 'Lokaltog/vim-easymotion'
Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
Plugin 'tpope/vim-rails.git'

Plugin 'L9'
Plugin 'FuzzyFinder'
Plugin 'kien/ctrlp.vim'
" Plugin 'vim-scripts/snipMate'
Plugin 'mattn/emmet-vim'
Plugin 'scrooloose/nerdtree'
Plugin 'groenewege/vim-less'
Plugin 'kchmck/vim-coffee-script'
Plugin 'slim-template/vim-slim'
Plugin 'yaymukund/vim-rabl'
Plugin 'godlygeek/tabular'
Plugin 'plasticboy/vim-markdown'
Plugin 'eikenberry/acp'
Plugin 'airblade/vim-gitgutter'
Plugin 'honza/vim-snippets'
Plugin 'altercation/vim-colors-solarized'

call vundle#end()
filetype plugin indent on     " required!

colorscheme solarized
"
" Brief help
" :PluginList          - list configured bundles
" :PluginInstall(!)    - install(update) bundles
" :PluginSearch(!) foo - search(or refresh cache first) for foo
" :PluginClean(!)      - confirm(or auto-approve) removal of unused bundles
"
" see :h vundle for more details or wiki for FAQ
" NOTE: comments after Plugin command are not allowed..

</pre>
