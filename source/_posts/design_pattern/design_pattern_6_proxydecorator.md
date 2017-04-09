---
title: Java设计模式（六） 代理模式 VS. 装饰模式
date: 2016-04-29 20:42:46
updated: 2017-02-17 20:31:23
permalink: design_pattern/proxy_decorator
keywords:
  - java 代理模式
  - java 装饰模式
  - 代理模式 装饰模式
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
description: 代理模式与装饰模式在代码组织结构上非常相近，以至于很多读者很难区分它们。本文将结合实例对比代理模式和装饰模式的适用场景，实现方式。
---

>原创文章，转载请务必将下面这段话置于文章开头处（保留超链接）。
>本文转发自[**Jason's Blog**](http://www.jasongj.com)，[原文链接](http://www.jasongj.com/design_pattern/proxy_decorator/)　[http://www.jasongj.com/design_pattern/proxy_decorator/](http://www.jasongj.com/design_pattern/proxy_decorator/)



# 模式介绍
 - **代理模式**（Proxy Pattern），为其它对象提供一种代理以控制对这个对象的访问。
 - **装饰模式**（Decorator Pattern），动态地给一个对象添加一些额外的职责。

从语意上讲，代理模式的目标是控制对被代理对象的访问，而装饰模式是给原对象增加额外功能。

# 类图
代理模式类图如下
![Proxy pattern class diagram](//www.jasongj.com/img/designpattern/proxydecorator/ProxyPattern.png)

装饰模式类图如下
![Decorator pattern class diagram](//www.jasongj.com/img/designpattern/proxydecorator/DecoratorPattern.png)

从上图可以看到，代理模式和装饰模式的类图非常类似。下面结合具体的代码讲解两者的不同。



# 代码解析
本文所有代码均可从[作者Github](https://github.com/habren/JavaDesignPattern/tree/master/ProxyAndDecoratorPattern/src/main)下载

## 相同部分
代理模式和装饰模式都包含ISubject和ConcreteSubject，并且这两种模式中这两个Component的实现没有任何区别。

ISubject代码如下
```java
package com.jasongj.subject;

public interface ISubject {

  void action();

}
```

ConcreteSubject代码如下
```java
package com.jasongj.subject;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public class ConcreteSubject implements ISubject {

  private static final Logger LOG = LoggerFactory.getLogger(ConcreteSubject.class);

  @Override
  public void action() {
    LOG.info("ConcreteSubject action()");
  }

}
```

## 代理类和使用方式
代理类实现方式如下
```java
package com.jasongj.proxy;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.Random;

import com.jasongj.subject.ConcreteSubject;
import com.jasongj.subject.ISubject;

public class ProxySubject implements ISubject {

  private static final Logger LOG = LoggerFactory.getLogger(ProxySubject.class);

  private ISubject subject;

  public ProxySubject() {
    subject = new ConcreteSubject();
  }

  @Override
  public void action() {
    preAction();
    if((new Random()).nextBoolean()){
      subject.action();
    } else {
      LOG.info("Permission denied");
    }
    postAction();
  }

  private void preAction() {
    LOG.info("ProxySubject.preAction()");
  }

  private void postAction() {
    LOG.info("ProxySubject.postAction()");
  }

}
```

从上述代码中可以看到，被代理对象由代理对象在编译时确定，并且代理对象可能限制对被代理对象的访问。

代理模式使用方式如下
```java
package com.jasongj.client;

import com.jasongj.proxy.ProxySubject;
import com.jasongj.subject.ISubject;

public class StaticProxyClient {

  public static void main(String[] args) {
    ISubject subject = new ProxySubject();
    subject.action();
  }

}
```

从上述代码中可以看到，调用方直接调用代理而不需要直接操作被代理对象甚至都不需要知道被代理对象的存在。同时，代理类可代理的具体被代理类是确定的，如本例中ProxySubject只可代理ConcreteSubject。


## 装饰类和使用方式
装饰类实现方式如下
```java
package com.jasongj.decorator;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.jasongj.subject.ISubject;

public class SubjectPreDecorator implements ISubject {

  private static final Logger LOG = LoggerFactory.getLogger(SubjectPreDecorator.class);

  private ISubject subject;

  public SubjectPreDecorator(ISubject subject) {
    this.subject = subject;
  }

  @Override
  public void action() {
    preAction();
    subject.action();
  }

  private void preAction() {
    LOG.info("SubjectPreDecorator.preAction()");
  }

}
```

```java
package com.jasongj.decorator;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.jasongj.subject.ISubject;

public class SubjectPostDecorator implements ISubject {

  private static final Logger LOG = LoggerFactory.getLogger(SubjectPostDecorator.class);

  private ISubject subject;

  public SubjectPostDecorator(ISubject subject) {
    this.subject = subject;
  }

  @Override
  public void action() {
    subject.action();
    postAction();
  }

  private void postAction() {
    LOG.info("SubjectPostDecorator.preAction()");
  }

}
```

装饰模式使用方法如下
```java
package com.jasongj.client;

import com.jasongj.decorator.SubjectPostDecorator;
import com.jasongj.decorator.SubjectPreDecorator;
import com.jasongj.subject.ConcreteSubject;
import com.jasongj.subject.ISubject;

public class DecoratorClient {

  public static void main(String[] args) {
    ISubject subject = new ConcreteSubject();
    ISubject preDecorator = new SubjectPreDecorator(subject);
    ISubject postDecorator = new SubjectPostDecorator(preDecorator);
    postDecorator.action();
  }

}
```

从上述代码中可以看出，装饰类可装饰的类并不固定，并且被装饰对象是在使用时通过组合确定。如本例中SubjectPreDecorator装饰ConcreteSubject，而SubjectPostDecorator装饰SubjectPreDecorator。并且被装饰对象由调用方实例化后通过构造方法（或者setter）指定。

装饰模式的本质是***动态组合***。动态是手段，组合是目的。每个装饰类可以只负责添加一项额外功能，然后通过组合为被装饰类添加复杂功能。由于每个装饰类的职责比较简单单一，增加了这些装饰类的可重用性，同时也更符合单一职责原则。

# 总结
 - 从语意上讲，代理模式是为控制对被代理对象的访问，而装饰模式是为了增加被装饰对象的功能
 - 代理类所能代理的类完全由代理类确定，装饰类装饰的对象需要根据实际使用时客户端的组合来确定
 - 被代理对象由代理对象创建，客户端甚至不需要知道被代理类的存在；被装饰对象由客户端创建并传给装饰对象



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
