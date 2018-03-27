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
> ```go
> fmt.Printf("Hello, world or 你好，世界 or καλημ ́ρα κóσμ or こんにちはせかい\n")
> ```

2. `_`下划线是个特殊的变量名，任何赋予它的值都会被丢弃。
> ```go
> _, b := 34, 35
> ```

3. 在方法 `func` 内申明的变量必须使用，全局变量则不用，但是尽量不要定义不使用的变量

4. 常量的定义最好都大写，虽然不做强制要求，但保持好的习惯

5. 常量声明省略值时，默认和之前一个值的字面相同。

6. 分组申明常量时`iota`，的值表示为`const的行数的值,从0开始`
> ```go
> const (
>    a       = iota             //a=0
>    b       = "B"
>    c       = iota             //c=2
>    d, e, f = iota, iota, iota //d=3,e=3,f=3
>    g       = iota             //g = 4
> )
> ```

#### 二. 内置基础类型

1. 整数类型有无符号`uint`和带符号`int`两种。
2. `rune`是`int32`的别称，`byte`是`uint8`的别称。
3. 整数类型位数对应表
> | 类型名称|有无符号|bit数
> | --------|--------|
> | int8|Yes|8
> | int16|Yes|16
> | int32|Yes|32
> | int64|Yes|64
> | uint8|No|8
> | uint16|No|16
> | uint32|No|32
> | uint64|No|64
> | int|Yes|等于cpu位数
> | uint|No|等于cpu位数
> | rune|Yes|与 int32 等价
> | byte|No|与 uint8 等价
> | uintptr|No|-

4. 不同类型的变量之间不允许互相赋值或操作
>
> ```go
> var a int8
> var b int32
> c:=a + b
> ```
> 另外，尽管int的长度是32 bit, 但int 与 int32并不可以互用。

5. 字符串不允许使用单引号`'`

6. 在Go中字符串是不可以直接修改的
> ```go
> var s string = "hello"
> s[0] = 'c'
> // 报错: cannot assign to s[0]
>
> // 如果硬要修改可如下方式：
> // 1. 将字符串 s 转换为 []byte 类型
> c := []byte(s)
> c[0] = 'c'                 // 或者c[0] = 99, 单引号 == ASCII码值
> s2 := string(c)            // 再转换回 string 类型
> fmt.Printf("%s\n", s2)     // cello
> // 2. 通过+号连接2个字符串
> s = "c" + s[1:]            // 字符串虽不能更改，但可进行切片操作
> fmt.Printf("%s\n", s)      // cello
> ```

7. `` ` `` 括起的字符串为Raw字符串，即字符串在代码中的形式就是打印时的形式，它没有字符转义，换行也将原样输出。

8. 数组的长度是固定的，不可改变
> ```go
> a := [3]int{1, 2, 3} // 声明了一个长度为3的int数组
> ```

9. 数组作为参数传递的时候是传递的副本，而不是它的指针, 而`slice`可以传递指针

10. `array[i:j]`的长度是`j - i`
> ```go
> // 声明一个含有10个元素元素类型为byte的数组
> var ar = [10]string{"a", "b", "c", "d", "e", "f", "g", "h", "i", "j"}
>
> // 声明两个含有byte的slice
> var a []string
>
> // a指向数组的第3个元素开始，并到第五个元素结束，
> a = ar[2:5]
> //现在a含有的元素: ar[2]、ar[3]和ar[4]
> fmt.Println(a) // output: [c d e]
> ```

11. `slice`总是指向一个底层`array`

12. `map`和其他基本型别不同，它不是`thread-safe`，在多个`go-routine`存取时，必须使用`mutex lock`机制

13. `make`用于内建类型（`map`、`slice` 和`channel`）的内存分配。`new`用于各种类型的内存分配。

14. `new`返回指针

15. `make`返回初始化后的（非零）值
