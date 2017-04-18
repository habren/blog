---
title: Java设计模式（五） 组合模式
date: 2016-04-24 07:09:46
updated: 2017-02-17 20:31:23
permalink: design_pattern/composite
keywords:
  - java
  - Java
  - java 组合模式
  - 设计模式
  - 组合模式
  - java 设计模式
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
description: 本文介绍了组合模式的概念，UML类图，优缺点，实例讲解以及组合模式（未）遵循的OOP原则。
---

>原创文章，转载请务必将下面这段话置于文章开头处（保留超链接）。
>本文转发自[**技术世界**](http://www.jasongj.com)，[原文链接](http://www.jasongj.com/design_pattern/composite/)　[http://www.jasongj.com/design_pattern/composite/](http://www.jasongj.com/design_pattern/composite/)



# 组合模式介绍
## 组合模式定义
组合模式（Composite Pattern）将对象组合成树形结构以表示“部分-整体”的层次结构。组合模式使得用户可以使用一致的方法操作单个对象和组合对象。

## 组合模式类图
组合模式类图如下
![Composite pattern class diagram](//www.jasongj.com/img/designpattern/composite/composite.png)

## 组合模式角色划分
 - 抽象组件，如上图中的Component
 - 简单组件，如上图中的SimpleComponent
 - 复合组件，如上图中的CompositeComponent

# 组合模式实例
## 实例介绍
对于一家大型公司，每当公司高层有重要事项需要通知到总部每个部门以及分公司的各个部门时，并不希望逐一通知，而只希望通过总部各部门及分公司，再由分公司通知其所有部门。这样，对于总公司而言，不需要关心通知的是总部的部门还是分公司。

## 实例类图
组合模式实例类图如下（点击可查看大图）
![Composite pattern example class diagram](//www.jasongj.com/img/designpattern/composite/composite_example.png)

## 实例解析
本例代码可从作者[Github](https://github.com/habren/JavaDesignPattern/tree/master/CompositePattern/src/main)下载

## 抽象组件
抽象组件定义了组件的通知接口，并实现了增删子组件及获取所有子组件的方法。同时重写了`hashCode`和`equales`方法（至于原因，请读者自行思考。如有疑问，请在评论区留言）。
```java
package com.jasongj.organization;

import java.util.ArrayList;
import java.util.List;

public abstract class Organization {

  private List<Organization> childOrgs = new ArrayList<Organization>();

  private String name;

  public Organization(String name) {
    this.name = name;
  }

  public String getName() {
    return name;
  }

  public void addOrg(Organization org) {
    childOrgs.add(org);
  }

  public void removeOrg(Organization org) {
    childOrgs.remove(org);
  }

  public List<Organization> getAllOrgs() {
    return childOrgs;
  }

  public abstract void inform(String info);

  @Override
  public int hashCode(){
    return this.name.hashCode();
  }
  
  @Override
  public boolean equals(Object org){
    if(!(org instanceof Organization)) {
      return false;
    }
    return this.name.equals(((Organization) org).name);
  }

}

```
## 简单组件（部门）
简单组件在通知方法中只负责对接收到消息作出响应。
```java
package com.jasongj.organization;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Department extends Organization{
  
  public Department(String name) {
    super(name);
  }

  private static Logger LOGGER = LoggerFactory.getLogger(Department.class);
  
  public void inform(String info){
    LOGGER.info("{}-{}", info, getName());
  }

}
```

### 复合组件（公司）
复合组件在自身对消息作出响应后，还须通知其下所有子组件
```java
package com.jasongj.organization;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Company extends Organization{
  
  private static Logger LOGGER = LoggerFactory.getLogger(Company.class);
  
  public Company(String name) {
    super(name);
  }

  public void inform(String info){
    LOGGER.info("{}-{}", info, getName());
    List<Organization> allOrgs = getAllOrgs();
    allOrgs.forEach(org -> org.inform(info+"-"));
  }

}

```

# 组合模式优缺点
## 组合模式优点
 - 高层模块调用简单。组合模式中，用户不用关心到底是处理简单组件还是复合组件，可以按照统一的接口处理。不必判断组件类型，更不用为不同类型组件分开处理。
 - 组合模式可以很容易的增加新的组件。若要增加一个简单组件或复合组件，只须找到它的父节点即可，非常容易扩展，符合“开放-关闭”原则。

## 组合模式缺点
 - 无法限制组合组件中的子组件类型。在需要检测组件类型时，不能依靠编译期的类型约束来实现，必须在运行期间动态检测。


# 组合模式与OOP原则
## 已遵循的原则
 - 依赖倒置原则（复合类型不依赖于任何具体的组件而依赖于抽象组件）
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
- [Java设计模式（九） 桥接模式](//www.jasongj.com/design_pattern/bridge/)
- [Java设计模式（十） 你真的用对单例模式了吗？](//www.jasongj.com/design_pattern/singleton/)
- [Java设计模式（十一） 享元模式](//www.jasongj.com/design_pattern/flyweight/)
- [Java设计模式（十二） 策略模式](//www.jasongj.com/design_pattern/strategy/)
