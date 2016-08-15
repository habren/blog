---
title: Java设计模式（三） 抽象工厂模式
date: 2016-04-09 20:39:46
permalink: design_pattern/abstract_factory
keywords:
  - java
  - Java
  - java 抽象工厂
  - 设计模式
  - 抽象工厂模式
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
description: 本文介绍了抽象工厂模式的概念，UML类图，优缺点，实现方式以及（未）遵循的OOP原则。同时结合J2EE中常用的DAO实例详解了抽象工厂模式的实现。
---

　　原创文章，转载请务必将下面这段话置于文章开头处。
　　本文转发自[**Jason's Blog**](http://www.jasongj.com)，[原文链接](http://www.jasongj.com/design_pattern/abstract_factory/)　[http://www.jasongj.com/design_pattern/abstract_factory/](http://www.jasongj.com/design_pattern/abstract_factory/)


# 抽象工厂模式解决的问题
上文《[工厂方法模式](http://www.jasongj.com/design_pattern/factory_method/)》中提到，在工厂方法模式中一种工厂只能创建一种具体产品。而在抽象工厂模式中一种具体工厂可以创建多个种类的具体产品。


# 抽象工厂模式
## 抽象工厂模式介绍
抽象工厂模式（Factory Method Pattern）中，抽象工厂提供一系列创建多个抽象产品的接口，而具体的工厂负责实现具体的产品实例。抽象工厂模式与工厂方法模式最大的区别在于抽象工厂中每个工厂可以创建多个种类的产品。

## 抽象工厂模式类图
抽象工厂模式类图如下 （点击可查看大图）
![Factory Method Pattern Class Diagram](//www.jasongj.com/img/designpattern/abstractfactory/abstract_factory.png)

## 抽象工厂模式角色划分
 - 抽象产品（或者产品接口），如上文类图中的IUserDao，IRoleDao，IProductDao
 - 具体产品，如PostgreSQLProductDao
 - 抽象工厂（或者工厂接口），如IFactory
 - 具体工厂，如果MySQLFactory
 - 产品族，如Oracle产品族，包含OracleUserDao，OracleRoleDao，OracleProductDao

## 抽象工厂模式使用方式
与工厂方法模式类似，在创建具体产品时，客户端通过实例化具体的工厂类，并调用其创建目标产品的方法创建具体产品类的实例。根据依赖倒置原则，具体工厂类的实例由工厂接口引用，具体产品的实例由产品接口引用。具体调用代码如下
```java
package com.jasongj.client;

import com.jasongj.bean.Product;
import com.jasongj.bean.User;
import com.jasongj.dao.role.IRoleDao;
import com.jasongj.dao.user.IUserDao;
import com.jasongj.dao.user.product.IProductDao;
import com.jasongj.factory.IDaoFactory;
import com.jasongj.factory.MySQLDaoFactory;

public class Client {

  public static void main(String[] args) {
    IDaoFactory factory = new MySQLDaoFactory();

    IUserDao userDao = factory.createUserDao();
    User user = new User();
    user.setUsername("demo");
    user.setPassword("demo".toCharArray());
    userDao.addUser(user);

    IRoleDao roleDao = factory.createRoleDao();
    roleDao.getRole("admin");

    IProductDao productDao = factory.createProductDao();
    Product product = new Product();
    productDao.removeProduct(product);

  }

}
```

## 抽象工厂模式案例解析

本文所述抽象工厂模式示例代码可从[作者Github](https://github.com/habren/JavaDesignPattern/tree/master/AbstractFactoryPattern/src/main)下载

上例是J2EE开发中常用的DAO（Data Access Object），操作对象（如User和Role，对应于数据库中表的记录）需要对应的DAO类。

在实际项目开发中，经常会碰到要求使用其它类型的数据库，而不希望过多修改已有代码。因此，需要为每种DAO创建一个DAO接口（如IUserDao，IRoleDao和IProductDao），同时为不同数据库实现相应的具体类。

调用方依赖于DAO接口而非具体实现（依赖倒置原则），因此切换数据库时，调用方代码无需修改。

这些具体的DAO实现类往往不由调用方实例化，从而实现具体DAO的使用方与DAO的构建解耦。实际上，这些DAO类一般由对应的具体工厂类构建。调用方不依赖于具体工厂而是依赖于抽象工厂（依赖倒置原则，又是依赖倒置原则）。

每种具体工厂都能创建多种产品，由同一种工厂创建的产品属于同一产品族。例如PostgreSQLUserDao，PostgreSQLRoleDao和PostgreSQLProductDao都属于PostgreSQL这一产品族。

切换数据库即是切换产品族，只需要切换具体的工厂类。如上文示例代码中，客户端使用的MySQL，如果要换用Oracle，只需将MySQLDaoFactory换成OracleDaoFactory即可。


## 抽象工厂模式优点
 - 因为每个具体工厂类只负责创建产品，没有简单工厂中的逻辑判断，因此符合单一职责原则。
 - 与简单工厂模式不同，抽象工厂并不使用静态工厂方法，可以形成基于继承的等级结构。
 - 新增一个产品族（如上文类图中的MySQLUserDao，MySQLRoleDao，MySQLProductDao）时，只需要增加相应的具体产品和对应的具体工厂类即可。相比于简单工厂模式需要修改判断逻辑而言，抽象工厂模式更符合开-闭原则。

## 抽象工厂模式缺点
 - 新增产品种类（如上文类图中的UserDao，RoleDao，ProductDao）时，需要修改工厂接口（或者抽象工厂）及所有具体工厂，此时不符合开-闭原则。抽象工厂模式对于新的产品族符合开-闭原则而对于新的产品种类不符合开-闭原则，这一特性也被称为开-闭原则的倾斜性。

# 抽象工厂模式与OOP原则
## 已遵循的原则
 - 依赖倒置原则（工厂构建产品的方法均返回产品接口而非具体产品，从而使客户端依赖于产品抽象而非具体）
 - 迪米特法则
 - 里氏替换原则
 - 接口隔离原则
 - 单一职责原则（每个工厂只负责创建自己的具体产品族，没有简单工厂中的逻辑判断）
 - 开闭原则（增加新的产品族，不像简单工厂那样需要修改已有的工厂，而只需增加相应的具体工厂类）

## 未遵循的原则
 - 开闭原则（虽然对新增产品族符合开-闭原则，但对新增产品种类不符合开-闭原则）


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
