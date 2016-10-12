---
title: Java设计模式（十一） 享元模式
date: 2016-05-23 07:34:46
permalink: design_pattern/flyweight
keywords:
  - java 享元模式
  - java flyweight pattern
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
  - 设计模式
  - Design Pattern
mathjax: false
description: 本文介绍了享元模式的适用场景，并结合实例详述了享元模式的实现方式。最后分析了享元模式的优缺点及已（未）遵循的OOP原则
---

>原创文章，转载请务必将下面这段话置于文章开头处（保留超链接）。
>本文转发自[**Jason's Blog**](http://www.jasongj.com)，[原文链接](http://www.jasongj.com/design_pattern/flyweight/)　[http://www.jasongj.com/design_pattern/flyweight/](http://www.jasongj.com/design_pattern/flyweight/)


# 享元模式介绍
## 享元模式适用场景
面向对象技术可以很好的解决一些灵活性或可扩展性问题，但在很多情况下需要在系统中增加类和对象的个数。当对象数量太多时，将导致对象创建及垃圾回收的代价过高，造成性能下降等问题。享元模式通过共享相同或者相似的细粒度对象解决了这一类问题。


## 享元模式定义
享元模式（Flyweight Pattern），又称轻量级模式（这也是其英文名为FlyWeight的原因），通过共享技术有效地实现了大量细粒度对象的复用。


## 享元模式类图
享元模式类图如下
![FlyWeight Pattern Class Diagram](//www.jasongj.com/img/designpattern/flyweight/FlyWeight.png)


## 享元模式角色划分
 - ***FlyWeight*** 享元接口或者（抽象享元类），定义共享接口
 - ***ConcreteFlyWeight*** 具体享元类，该类实例将实现共享
 - ***UnSharedConcreteFlyWeight*** 非共享享元实现类
 - ***FlyWeightFactory*** 享元工厂类，控制实例的创建和共享

## 内部状态 vs. 外部状态
 - ***内部状态***是存储在享元对象内部，一般在构造时确定或通过setter设置，并且不会随环境改变而改变的状态，因此内部状态可以共享。
 - ***外部状态***是随环境改变而改变、不可以共享的状态。外部状态在需要使用时通过客户端传入享元对象。外部状态必须由客户端保存。

# 享元模式实例解析
本文代码可从[作者Github](https://github.com/habren/JavaDesignPattern/tree/master/FlyweightPattern/src/main)下载


享元接口，定义共享接口
```java
package com.jasongj.flyweight;

public interface FlyWeight {

  void action(String externalState);

}
```

具体享元类，实现享元接口。该类的对象将被复用
```java
package com.jasongj.flyweight;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ConcreteFlyWeight implements FlyWeight {

  private static final Logger LOG = LoggerFactory.getLogger(ConcreteFlyWeight.class);

  private String name;

  public ConcreteFlyWeight(String name) {
    this.name = name;
  }

  @Override
  public void action(String externalState) {
    LOG.info("name = {}, outerState = {}", this.name, externalState);
  }

}
```

享元模式中，最关键的享元工厂。它将维护已创建的享元实例，并通过实例标记（一般用内部状态）去索引对应的实例。当目标对象未创建时，享元工厂负责创建实例并将其加入标记-对象映射。当目标对象已创建时，享元工厂直接返回已有实例，实现对象的复用。
```java
package com.jasongj.factory;

import java.util.concurrent.ConcurrentHashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.jasongj.flyweight.ConcreteFlyWeight;
import com.jasongj.flyweight.FlyWeight;

public class FlyWeightFactory {

  private static final Logger LOG = LoggerFactory.getLogger(FlyWeightFactory.class);

  private static ConcurrentHashMap<String, FlyWeight> allFlyWeight = new ConcurrentHashMap<String, FlyWeight>();

  public static FlyWeight getFlyWeight(String name) {
    if (allFlyWeight.get(name) == null) {
      synchronized (allFlyWeight) {
        if (allFlyWeight.get(name) == null) {
          LOG.info("Instance of name = {} does not exist, creating it");
          FlyWeight flyWeight = new ConcreteFlyWeight(name);
          LOG.info("Instance of name = {} created");
          allFlyWeight.put(name, flyWeight);
        }
      }
    }
    return allFlyWeight.get(name);
  }

}
```

从上面代码中可以看到，享元模式中对象的复用完全依靠享元工厂。同时本例中实现了对象创建的懒加载。并且为了保证线程安全及效率，本文使用了双重检查（Double Check）。

本例中，`name`可以认为是内部状态，在构造时确定。`externalState`属于外部状态，由客户端在调用时传入。



# 享元模式分析
## 享元模式优点
 - 享元模式的外部状态相对独立，使得对象可以在不同的环境中被复用（共享对象可以适应不同的外部环境）
 - 享元模式可共享相同或相似的细粒度对象，从而减少了内存消耗，同时降低了对象创建与垃圾回收的开销

## 享元模式缺点
 - 外部状态由客户端保存，共享对象读取外部状态的开销可能比较大
 - 享元模式要求将内部状态与外部状态分离，这使得程序的逻辑复杂化，同时也增加了状态维护成本

# 享元模式已（未）遵循的OOP原则
## 已遵循的OOP原则
 - 依赖倒置原则
 - 迪米特法则
 - 里氏替换原则
 - 接口隔离原则
 - 单一职责原则
 - 开闭原则

## 未遵循的OOP原则
 - NA



# Java设计模式系列
- [Java设计模式（一） 简单工厂模式不简单](//www.jasongj.com/design_pattern/simple_factory/)
- [Java设计模式（二） 工厂方法模式](//www.jasongj.com/design_pattern/factory_method/)
- [Java设计模式（三） 抽象工厂模式](//www.jasongj.com/design_pattern/abstract_factory/)
- [Java设计模式（四） 观察者模式](//www.jasongj.com/design_pattern/observer/)
- [Java设计模式（五） 组合模式](//www.jasongj.com/design_pattern/composite/)
- [Java设计模式（六） 代理模式 VS. 装饰模式](//www.jasongj.com/design_pattern/proxy_decorator/)
- [Java设计模式（七） Spring AOP JDK动态代理 vs. cglib](//www.jasongj.com/design_pattern/dynamic_proxy_cglib/)
- [Java设计模式（八） 适配器模式](//www.jasongj.com/design_pattern/adapter/)
- [Java设计模式（九） 桥接模式](//www.jasongj.com/design_pattern/bridge/)
- [Java设计模式（十） 你真的用对单例模式了吗？](//www.jasongj.com/design_pattern/singleton/)
- [Java设计模式（十一） 享元模式](//www.jasongj.com/design_pattern/flyweight/)
- [Java设计模式（十二） 策略模式](//www.jasongj.com/design_pattern/strategy/)

