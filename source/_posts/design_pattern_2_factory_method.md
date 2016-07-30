---
title: Java设计模式（二） 工厂方法模式
date: 2016-04-02 08:00:01
permalink: design_pattern/factory_method
keywords:
  - java
  - Java
  - java 工厂方法
  - 设计模式
  - 工厂方法模式
  - java 设计模式
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
description: 本文介绍了工厂方法模式的概念，优缺点，实现方式，UML类图，并介绍了工厂方法（未）遵循的OOP原则
---

　　原创文章，转载请务必将下面这段话置于文章开头处。
　　本文转发自[**Jason's Blog**](http://www.jasongj.com)，[原文链接](http://www.jasongj.com/design_pattern/factory_method/)　[http://www.jasongj.com/design_pattern/factory_method/](http://www.jasongj.com/design_pattern/factory_method/)


# 工厂方法模式解决的问题
上文《[简单工厂模式不简单](http://www.jasongj.com/design_pattern/simple_factory/)》中提到，简单工厂模式有如下缺点，而工厂方法模式可以解决这些问题
 - 由于工厂类集中了所有实例的创建逻辑，这就直接导致一旦这个工厂出了问题，所有的客户端都会受到牵连。
 - 由于简单工厂模式的产品是基于一个共同的抽象类或者接口，这样一来，产品的种类增加的时候，即有不同的产品接口或者抽象类的时候，工厂类就需要判断何时创建何种接口的产品，这就和创建何种种类的产品相互混淆在了一起，违背了单一职责原则，导致系统丧失灵活性和可维护性。
 - 简单工厂模式违背了“开放-关闭原则”，因为当我们新增加一个产品的时候必须修改工厂类，相应的工厂类就需要重新编译一遍。
 - 简单工厂模式由于使用了静态工厂方法，造成工厂角色无法形成基于继承的等级结构。

# 工厂方法模式
## 工厂方法模式介绍
工厂方法模式（Factory Method Pattern）又称为工厂模式，也叫多态工厂模式或者虚拟构造器模式。在工厂方法模式中，工厂父类定义创建产品对象的公共接口，具体的工厂子类负责创建具体的产品对象。每一个工厂子类负责创建一种具体产品。

## 工厂方法模式类图
工厂模式类图如下 (点击可查看大图)
![Factory Method Pattern Class Diagram](//www.jasongj.com/img/designpattern/factorymethod/factory_method.png)

## 工厂方法模式角色划分
 - 抽象产品（或者产品接口），如上图中IUserDao
 - 具体产品，如上图中的MySQLUserDao，PostgreSQLUserDao和OracleUserDao
 - 抽象工厂（或者工厂接口），如IFactory
 - 具体工厂，如MySQLFactory，PostgreSQLFactory和OracleFactory



## 工厂方法模式使用方式
如简单工厂模式直接使用静态工厂方法创建产品对象不同，在工厂方法，客户端通过实例化具体的工厂类，并调用其创建实例接口创建具体产品类的实例。根据依赖倒置原则，具体工厂类的实例由工厂接口引用（客户端依赖于抽象工厂而非具体工厂），具体产品的实例由产品接口引用（客户端和工厂依赖于抽象产品而非具体产品）。具体调用代码如下
```java
package com.jasongj.client;

import com.jasongj.dao.IUserDao;
import com.jasongj.factory.IDaoFactory;
import com.jasongj.factory.MySQLDaoFactory;

public class Client {

  public static void main(String[] args) {
    IDaoFactory factory = new MySQLDaoFactory();
    IUserDao userDao = factory.createUserDao();
    userDao.getUser("admin");

  }

}
```

## 工厂方法模式示例代码
本文所述工厂方法模式示例代码可从[作者Github](https://github.com/habren/JavaDesignPattern/tree/master/FactoryMethodPattern/src/main)下载

## 工厂方法模式优点
 - 因为每个具体工厂类只负责创建产品，没有简单工厂中的逻辑判断，因此符合单一职责原则。
 - 与简单工厂模式不同，工厂方法并不使用静态工厂方法，可以形成基于继承的等级结构。
 - 新增一种产品时，只需要增加相应的具体产品类和相应的工厂子类即可，相比于简单工厂模式需要修改判断逻辑而言，工厂方法模式更符合开-闭原则。

## 工厂方法模式缺点
 - 添加新产品时，除了增加新产品类外，还要提供与之对应的具体工厂类，系统类的个数将成对增加，在一定程度上增加了系统的复杂度，有更多的类需要编译和运行，会给系统带来一些额外的开销。
 - 虽然保证了工厂方法内的对修改关闭，但对于使用工厂方法的类，如果要换用另外一种产品，仍然需要修改实例化的具体工厂。
 - 一个具体工厂只能创建一种具体产品

# 简单工厂模式与OOP原则
## 已遵循的原则
 - 依赖倒置原则
 - 迪米特法则
 - 里氏替换原则
 - 接口隔离原则
 - 单一职责原则（每个工厂只负责创建自己的具体产品，没有简单工厂中的逻辑判断）
 - 开闭原则（增加新的产品，不像简单工厂那样需要修改已有的工厂，而只需增加相应的具体工厂类）

## 未遵循的原则
 - 开闭原则（虽然工厂对修改关闭了，但更换产品时，客户代码还是需要修改）


# Java设计模式系列
- [Java设计模式（一） 简单工厂模式不简单](//www.jasongj.com/design_pattern/simple_factory/)
- [Java设计模式（二） 工厂方法模式](//www.jasongj.com/design_pattern/factory_method/)
- [Java设计模式（三） 抽象工厂模式](//www.jasongj.com/design_pattern/abstract_factory/)
- [Java设计模式（四） 观察者模式 ](//www.jasongj.com/design_pattern/observer/)
- [Java设计模式（五） 组合模式](//www.jasongj.com/design_pattern/composite/)
- [Java设计模式（六） 代理模式 VS. 装饰模式](//www.jasongj.com/design_pattern/proxy_decorator/)
- [Java设计模式（七） Spring AOP JDK动态代理 vs. cglib](//www.jasongj.com/design_pattern/dynamic_proxy_cglib/)
- [Java设计模式（八） 适配器模式](//www.jasongj.com/design_pattern/adapter/)
- [Java设计模式（九） 桥接模式](//www.jasongj.com/design_pattern/bridge/)
- [Java设计模式（十） 你真的用对单例模式了吗？](//www.jasongj.com/design_pattern/singleton/)
- [Java设计模式（十一） 享元模式](//www.jasongj.com/design_pattern/flyweight/)
- [Java设计模式（十二） 策略模式](//www.jasongj.com/design_pattern/strategy/)
- [Java设计模式（十三） 别人再问你设计模式，叫他看这篇文章](//www.jasongj.com/design_pattern/summary/)
