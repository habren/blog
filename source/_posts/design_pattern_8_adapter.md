---
title: Java设计模式（八） 适配器模式
date: 2016-05-09 07:04:46
permalink: design_pattern/adapter
keywords:
  - java 适配器模式
  - java adapter
  - java 设计模式
  - 设计模式
  - Jason's Blog
  - 郭俊 Jason
  - 大数据架构
tags:
  - Java
  - 设计模式
  - Design Pattern
categories:
  - Java
  - 设计模式
  - Design Pattern
description: 适配器模式可将一个类的接口转换成调用方希望的另一个接口。这种需求往往发生在后期维护阶段，因此有观点认为适配器模式只是前期系统接口设计缺乏的一种弥补。从实际工程来看，并不完全这样，有时不同产商的功能类似但接口很难完全一样，而为了系统使用方式的一致性，也会用到适配器模式。
---

　　原创文章，转载请务必将下面这段话置于文章开头处。
　　本文转发自[**Jason's Blog**](http://www.jasongj.com)，[原文链接](http://www.jasongj.com/design_pattern/adapter/)　[http://www.jasongj.com/design_pattern/adapter/](http://www.jasongj.com/design_pattern/adapter/)



# 适配器模式介绍
## 适配器模式定义
适配器模式（Adapter Pattern），将一个类的接口转换成客户希望的另外一个接口。适配器模式使得原本由于接口不兼容而不能一起工作的那些类可以一起工作。


## 适配器模式类图
适配器模式类图如下
![Adapter pattern class diagram](//www.jasongj.com/img/designpattern/adapter/Adapter.png)

## 适配器模式角色划分
- 目标接口，如上图中的ITarget
- 具体目标实现，如ConcreteTarget
- 适配器，Adapter
- 待适配类，Adaptee


## 实例解析
本文代码可从作者[Github](https://github.com/habren/JavaDesignPattern/tree/master/AdapterPattern/src/main)下载

目标接口
```java
package com.jasongj.target;

public interface ITarget {

  void request();

}
```

目标接口实现
```java
package com.jasongj.target;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public class ConcreteTarget implements ITarget {

  private static Logger LOG = LoggerFactory.getLogger(ConcreteTarget.class);

  @Override
  public void request() {
    LOG.info("ConcreteTarget.request()");
  }

}
```

待适配类，其接口名为onRequest，而非目标接口request
```java
package com.jasongj.adaptee;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.jasongj.target.ConcreteTarget;

public class Adaptee {

  private static Logger LOGGER = LoggerFactory.getLogger(ConcreteTarget.class);

  public void onRequest() {
    LOGGER.info("Adaptee.onRequest()");
  }

}
```

适配器类
```java
package com.jasongj.target;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.jasongj.adaptee.Adaptee;

public class Adapter implements ITarget {

  private static Logger LOG = LoggerFactory.getLogger(Adapter.class);

  private Adaptee adaptee = new Adaptee();

  @Override
  public void request() {
    LOG.info("Adapter.request");
    adaptee.onRequest();
  }

}
```


从上面代码可看出，适配器类实际上是目标接口的类，因为持有待适配类的实例，所以可以在适配器类的目标接口被调用时，调用待适配对象的接口，而客户端并不需要知道二者接口的不同。通过这种方式，客户端可以使用统一的接口使用不同接口的类。

```java
package com.jasongj.client;

import com.jasongj.target.Adapter;
import com.jasongj.target.ConcreteTarget;
import com.jasongj.target.ITarget;

public class AdapterClient {

  public static void main(String[] args) {
    ITarget adapter = new Adapter();
    adapter.request();

    ITarget target = new ConcreteTarget();
    target.request();
  }

}
```

# 适配器模式适用场景
- 调用双方接口不一致且都不容易修改时，可以使用适配器模式使得原本由于接口不兼容而不能一起工作的那些类可以一起工作
- 多个组件功能类似，但接口不统一且可能会经常切换时，可使用适配器模式，使得客户端可以以统一的接口使用它们

# 适配器模式优缺点
## 观察者模式优点
 - 客户端可以以统一的方式使用ConcreteTarget和Adaptee
 - 适配器负责适配过程，而不需要修改待适配类，其它直接依赖于待适配类的调用方不受适配过程的影响
 - 可以为不同的目标接口实现不同的适配器，而不需要修改待适配类，符合开放-关闭原则



# 适配器模式与OOP原则
## 已遵循的原则
 - 依赖倒置原则
 - 迪米特法则
 - 里氏替换原则
 - 接口隔离原则
 - 单一职责原则
 - 开闭原则

## 未遵循的原则
 - NA


# Java设计模式系列
- [Java设计模式（一） 简单工厂模式不简单](//www.jasongj.com/design_pattern/simple_factory/)
- [Java设计模式（二） 工厂方法模式](//www.jasongj.com/design_pattern/factory_method/)
- [Java设计模式（三） 抽象工厂模式](//www.jasongj.com/design_pattern/abstract_factory/)
- [Java设计模式（四） 观察者模式 ](//www.jasongj.com/design_pattern/observer/)
- [Java设计模式（五） 组合模式](//www.jasongj.com/design_pattern/composite/)
- [Java设计模式（六） 代理模式 VS. 装饰模式](//www.jasongj.com/design_pattern/proxy_decorator/)
- [Java设计模式（七） Spring AOP JDK动态代理 vs. cglib](//www.jasongj.com/design_pattern/dynamic_proxy_cglib/)
- [Java设计模式（八） 适配器模式](//www.jasongj.com/design_pattern/adapter/)
