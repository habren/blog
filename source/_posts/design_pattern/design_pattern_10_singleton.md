---
title: Java设计模式（十） 你真的用对单例模式了吗？
date: 2016-05-16 07:34:46
updated: 2017-11-12 15:31:23
permalink: design_pattern/singleton
keywords:
  - java 单例模式
  - java singleton pattern
  - java 设计模式
  - 设计模式
  - 技术世界
  - 郭俊 Jason
  - 大数据架构
tags:
  - Java
  - 设计模式
  - Design Pattern
categories:
  - 设计模式
  - Design Pattern
mathjax: false
description: 本文介绍了为何需要单例模式，单例模式的设计要点，饿汉和懒汉的区别，并通过实例介绍了实现单例模式的八种实现方式及其优缺点。
---

>原创文章，转载请务必将下面这段话置于文章开头处（保留超链接）。
>本文转发自[**技术世界**](http://www.jasongj.com)，[原文链接](http://www.jasongj.com/design_pattern/singleton/)　[http://www.jasongj.com/design_pattern/singleton/](http://www.jasongj.com/design_pattern/singleton/)


# 为何需要单例模式

对于系统中的某些类来说，只有一个实例很重要，例如，一个系统只能有一个窗口管理器或文件系统；一个系统只能有一个计时工具或ID（序号）生成器。


# 单例模式设计要点
 - 保证该类只有一个实例。将该类的构造方法定义为私有方法，这样其他处的代码就无法通过调用该类的构造方法来实例化该类的对象
 - 提供一个该实例的访问点。一般由该类自己负责创建实例，并提供一个静态方法作为该实例的访问点

# 饿汉 vs. 懒汉
 - 饿汉 声明实例引用时即实例化
 - 懒汉 静态方法第一次被调用前不实例化，也即懒加载。对于创建实例代价大，且不定会使用时，使用懒加载模式可以减少开销

# 实现单例模式的九种方法

## 线程不安全的懒汉 - 多线程不可用

```java
package com.jasongj.singleton1;

public class Singleton {

  private static Singleton INSTANCE;

  private Singleton() {};

  public static Singleton getInstance() {
    if (INSTANCE == null) {
      INSTANCE = new Singleton();
    }
    return INSTANCE;
  }

}
```

 - 优点：达到了Lazy Loading的效果
 - 缺点：只有在单线程下能保证只有一个实例，多线程下有创建多个实例的风险


## 同步方法下的懒汉 - 可用，不推荐
```java
package com.jasongj.singleton2;

public class Singleton {

  private static Singleton INSTANCE;

  private Singleton() {};

  public static synchronized Singleton getInstance() {
    if (INSTANCE == null) {
      INSTANCE = new Singleton();
    }
    return INSTANCE;
  }
}
 ```

 - 优点：线程安全，可确保正常使用下（不考虑通过反射调用私有构造方法）只有一个实例
 - 缺点：每次获取实例都需要申请锁，开销大，效率低

## 同步代码块下的懒汉 - 不可用
```java
package com.jasongj.singleton3;

public class Singleton {

  private static Singleton INSTANCE;

  private Singleton() {};

  public static Singleton getInstance() {
    if (INSTANCE == null) {
      synchronized (Singleton.class) {
        INSTANCE = new Singleton();
      }
    }
    return INSTANCE;
  }
}
```

 - 优点：不需要在每次调用时加锁，效率比上一个高
 - 缺点：虽然使用了`synchronized`，但本质上是线程不安全的。


## 双重检查（Double Check）下的懒汉 - 推荐
```java
package com.jasongj.singleton4;

public class Singleton {

  private static volatile Singleton INSTANCE;

  private Singleton() {};

  public static Singleton getInstance() {
    if (INSTANCE == null) {
      synchronized(Singleton.class){
        if(INSTANCE == null) {
          INSTANCE = new Singleton();
        }
      }
    }
    return INSTANCE;
  }

}
```

 - 优点：使用了双重检查，避免了线程不安全，同时也避免了不必要的锁开销。
 - 缺点：NA

注：
 - 但是这里的`synchronized`已经保证了`INSTANCE`写操作对其它线程读操作的可见性。具体原理请参考《[Java进阶（二）当我们说线程安全时，到底在说什么](http://www.jasongj.com/java/thread_safe/#synchronized_visibility)》
 - 使用`volatile`关键字的目的不是保证可见性（`synchronized`已经保证了可见性），而是为了保证顺序性。具体来说，`INSTANCE = new Singleton()`不是原子操作，实际上被拆分为了三步：1) 分配内存；2) 初始化对象；3) 将INSTANCE指向分配的对象内存地址。 如果没有`volatile`，可能会发生指令重排，使得INSTANCE先指向内存地址，而对象尚未初始化，其它线程直接使用INSTANCE引用进行对象操作时出错。详细原理可参见《<a href="http://www.infoq.com/cn/articles/double-checked-locking-with-delay-initialization" target="_blank" title="双重检查锁定与延迟初始化" rel="external nofollow">双重检查锁定与延迟初始化</a>》

## 静态常量 饿汉 - 推荐
```java
package com.jasongj.singleton6;

public class Singleton {

  private static final Singleton INSTANCE = new Singleton();

  private Singleton() {};

  public static Singleton getInstance() {
    return INSTANCE;
  }

}
```

 - 优点：实现简单，无线程同步问题
 - 缺点：在类装载时完成实例化。若该实例一直未被使用，则会造成资源浪费


## 静态代码块 饿汉 可用
```java
package com.jasongj.singleton7;

public class Singleton {

  private static Singleton INSTANCE;
  
  static{
    INSTANCE = new Singleton();
  }

  private Singleton() {};

  public static Singleton getInstance() {
    return INSTANCE;
  }

}
```

 - 优点：无线程同步问题
 - 缺点：类装载时创建实例，无Lazy Loading。实例一直未被使用时，会浪费资源


## 静态内部类 推荐
```java
package com.jasongj.singleton8;

public class Singleton {

  private Singleton() {};

  public static Singleton getInstance() {
    return InnerClass.INSTANCE;
  }
  
  private static class InnerClass {
    private static final Singleton INSTANCE = new Singleton();
  }

}
```

 - 优点：无线程同步问题，实现了懒加载（Lazy Loading）。因为只有调用`getInstance`时才会装载内部类，才会创建实例。同时因为使用内部类时，先调用内部类的线程会获得类初始化锁，从而保证内部类的初始化（包括实例化它所引用的外部类对象）线程安全。即使内部类创建外部类的实例`Singleton INSTANCE = new Singleton()`发生指令重排也不会引起[双重检查（Double-Check）下的懒汉](#双重检查（Double-Check）下的懒汉-推荐)模式中提到的问题，因此无须使用`volatile`关键字。
 - 缺点：NA

## 枚举 强烈推荐
```java
package com.jasongj.singleton9;

public enum Singleton {

  INSTANCE;
  
  public void whatSoEverMethod() { }

  // 该方法非必须，只是为了保证与其它方案一样使用静态方法得到实例
  public static Singleton getInstance() {
    return INSTANCE;
  }

}
```

 - 优点：枚举本身是线程安全的，且能防止通过反射和反序列化创建多实例。
 - 缺点：使用的是枚举，而非类。
　　



# Java设计模式系列
- [Java设计模式（一） 简单工厂模式不简单](http://www.jasongj.com/design_pattern/simple_factory/)
- [Java设计模式（二） 工厂方法模式](http://www.jasongj.com/design_pattern/factory_method/)
- [Java设计模式（三） 抽象工厂模式](http://www.jasongj.com/design_pattern/abstract_factory/)
- [Java设计模式（四） 观察者模式 ](http://www.jasongj.com/design_pattern/observer/)
- [Java设计模式（五） 组合模式](http://www.jasongj.com/design_pattern/composite/)
- [Java设计模式（六） 代理模式 VS. 装饰模式](http://www.jasongj.com/design_pattern/proxy_decorator/)
- [Java设计模式（七） Spring AOP JDK动态代理 vs. cglib](http://www.jasongj.com/design_pattern/dynamic_proxy_cglib/)
- [Java设计模式（八） 适配器模式](http://www.jasongj.com/design_pattern/adapter/)
- [Java设计模式（九） 桥接模式](http://www.jasongj.com/design_pattern/bridge/)
- [Java设计模式（十） 你真的用对单例模式了吗？](http://www.jasongj.com/design_pattern/singleton/)
- [Java设计模式（十一） 享元模式](http://www.jasongj.com/design_pattern/flyweight/)
- [Java设计模式（十二） 策略模式](http://www.jasongj.com/design_pattern/strategy/)

