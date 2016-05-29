---
title: Java设计模式（四） 观察者模式
date: 2016-04-13 20:13:46
permalink: design_pattern/observer
keywords:
  - java
  - Java
  - java 观察者模式
  - 设计模式
  - 观察者模式
  - java 设计模式
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
description: 本文介绍了观察者模式的概念，UML类图，优缺点，实例分析以及观察者模式（未）遵循的OOP原则。
---

　　原创文章，转载请务必将下面这段话置于文章开头处。
　　本文转发自[**Jason's Blog**](http://www.jasongj.com)，[原文链接](http://www.jasongj.com/design_pattern/observer/)　[http://www.jasongj.com/design_pattern/observer/](http://www.jasongj.com/design_pattern/observer/)



# 观察者模式介绍
## 观察者模式定义
观察者模式又叫发布-订阅模式，它定义了一种一对多的依赖关系，多个观察者对象可同时监听某一主题对象，当该主题对象状态发生变化时，相应的所有观察者对象都可收到通知。

## 观察者模式类图
观察者模式类图如下（点击可查看大图）
![Observer pattern class diagram](//www.jasongj.com/img/designpattern/observer/observer.png)

## 观察者模式角色划分
 - 主题，抽象类或接口，如上面类图中的AbstractSubject
 - 具体主题，如上面类图中的Subject1，Subject2
 - 观察者，如上面类图中的IObserver
 - 具体观察者，如上面类图中的Observer1，Observer2，Observer3

# 观察者模式实例
## 实例介绍
猎头或者HR往往会有很多职位信息，求职者可以在猎头或者HR那里注册，当猎头或者HR有新的岗位信息时，即会通知这些注册过的求职者。这是一个典型的观察者模式使用场景。

## 实例类图
观察者模式实例类图如下（点击可查看大图）
![Observer pattern example class diagram](//www.jasongj.com/img/designpattern/observer/observer_example.png)

## 实例解析
本例代码可从作者[Github](https://github.com/habren/JavaDesignPattern/tree/master/ObserverPattern/src/main)下载

观察者接口（或抽象观察者，如本例中的ITalent）需要定义回调接口，如下
```java
package com.jasongj.observer;

public interface ITalent {

  void newJob(String job);

}
```

具体观察者（如本例中的JuniorEngineer，SeniorEngineer，Architect）在回调接口中实现其对事件的响应方法，如
```java
package com.jasongj.observer;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Architect implements ITalent {
  
  private static final Logger LOG = LoggerFactory.getLogger(Architect.class);

  @Override
  public void newJob(String job) {
    LOG.info("Architect get new position {}", job);
  }

}
```

抽象主题类（如本例中的AbstractHR）定义通知观察者接口，并实现增加观察者和删除观察者方法（这两个方法可被子类共用，所以放在抽象类中实现），如
```java
package com.jasongj.subject;

import java.util.ArrayList;
import java.util.Collection;

import com.jasongj.observer.ITalent;

public abstract class AbstractHR {

  protected Collection<ITalent> allTalents = new ArrayList<ITalent>();

  public abstract void publishJob(String job);

  public void addTalent(ITalent talent) {
    allTalents.add(talent);
  }

  public void removeTalent(ITalent talent) {
    allTalents.remove(talent);
  }

}
```

具体主题类（如本例中的HeadHunter）只需实现通知观察者接口，在该方法中通知所有注册的具体观察者。代码如下
```java
package com.jasongj.subject;

public class HeadHunter extends AbstractHR {

  @Override
  public void publishJob(String job) {
    allTalents.forEach(talent -> talent.newJob(job));
  }

}
```

当主题类有更新（如本例中猎头有新的招聘岗位）时，调用其通知接口即可将其状态（岗位）通知给所有观察者（求职者）
```java
package com.jasongj.client;

import com.jasongj.observer.Architect;
import com.jasongj.observer.ITalent;
import com.jasongj.observer.JuniorEngineer;
import com.jasongj.observer.SeniorEngineer;
import com.jasongj.subject.HeadHunter;
import com.jasongj.subject.AbstractHR;

public class Client1 {

  public static void main(String[] args) {
    ITalent juniorEngineer = new JuniorEngineer();
    ITalent seniorEngineer = new SeniorEngineer();
    ITalent architect = new Architect();
    
    AbstractHR subject = new HeadHunter();
    subject.addTalent(juniorEngineer);
    subject.addTalent(seniorEngineer);
    subject.addTalent(architect);

    subject.publishJob("Top 500 big data position");
  }

}
```

# 观察者模式优缺点
## 观察者模式优点
 - 抽象主题只依赖于抽象观察者
 - 观察者模式支持广播通信
 - 观察者模式使信息产生层和响应层分离

## 观察者模式缺点
 - 如一个主题被大量观察者注册，则通知所有观察者会花费较高代价
 - 如果某些观察者的响应方法被阻塞，整个通知过程即被阻塞，其它观察者不能及时被通知


# 观察者模式与OOP原则
## 已遵循的原则
 - 依赖倒置原则（主题类依赖于抽象观察者而非具体观察者）
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
