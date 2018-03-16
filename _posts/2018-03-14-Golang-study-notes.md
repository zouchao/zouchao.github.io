---
date: 2018-03-14 11:00:12
title: Go语言学习笔记
layout: post
tags:
    - 笔记
    - Golang
categories:
    - Go
---

### Golang基础

#### 一. 变量、常量
1. 内置支持utf8编码
```go
   fmt.Printf("Hello, world or 你好，世界 or καλημ ́ρα κóσμ or こんにちはせかい\n")
```

2. `_`下划线是个特殊的变量名，任何赋予它的值都会被丢弃。
```go
_, b := 34, 35
```

3. 在方法 `func` 内申明的变量必须使用，全局变量则不用

4. 常量的定义最好都大写，虽然不做强制要求，但保持好的习惯

5. 常量声明省略值时，默认和之前一个值的字面相同。

6. 分组申明常量时`iota`，的值表示为`const的行数的值,从0开始`
```go
const (
    a       = iota             //a=0
    b       = "B"
    c       = iota             //c=2
    d, e, f = iota, iota, iota //d=3,e=3,f=3
    g       = iota             //g = 4
)
```

#### 二. 内置基础类型

1. 整数类型有无符号`uint`和带符号`int`两种。
2. `rune`是`int32`的别称，`byte`是`uint8`的别称。
3. 整数类型位数对应表
> | 类型名称|有无符号|bit数
| --------|--------|
| int8|Yes|8
| int16|Yes|16
| int32|Yes|32
| int64|Yes|64
| uint8|No|8
| uint16|No|16
| uint32|No|32
| uint64|No|64
| int|Yes|等于cpu位数
| uint|No|等于cpu位数
| rune|Yes|与 int32 等价
| byte|No|与 uint8 等价
| uintptr|No|-

5. dada
