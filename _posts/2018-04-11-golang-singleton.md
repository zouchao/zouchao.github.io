---
date: 2018-04-11 14:11:35
title: Go语言如何实现单例模式
layout: post
tags:
    - 笔记
    - Golang
    - 设计模式
    - 并发编程
categories:
    - Go
---

单例模式是常见的设计模式，被广泛用于创建数据库，redis等单实例。作用在于可以控制实例个数节省系统资源

## 特点：
1. 保证调用多次，只会产生单个实例
2. 全局访问

## 单例的分类
单例模式大致分为2大类:
* 懒汉式: 指全局的单例实例在第一次被使用时构建。
* 饿汉式: 指全局的单例实例在类装载时构建。

## sync.Once
这里我们不做一步一步的演进，哪种好，哪种不好见仁见智。我们来看看golang中如何实现单例模式:
```go
type singleton struct{}
var ins *singleton
var once sync.Once
func GetIns() *singleton {
    once.Do(func(){
        ins = &singleton{}
    })
    return ins
}
```

## sync.Once源码解读
```go
package sync

type Once struct {
    m    Mutex
    done uint32
}

func (o *Once) Do(f func()) {
    if atomic.LoadUint32(&o.done) == 1 { 	// 保证原子性操作，加载标记，如果存在直接返回
        return
    }
    // Slow-path.
    o.m.Lock() 					// 加锁进一步保证f()方法只能被执行一次
    defer o.m.Unlock()
    if o.done == 0 {
        defer atomic.StoreUint32(&o.done, 1) 	// 设置标志
        f()					// 注意：如果f()内部报错，sync.Once仍然不会执行第二次
    }
}
```
