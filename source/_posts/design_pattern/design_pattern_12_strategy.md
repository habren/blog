---
title: Java设计模式（十二） 策略模式
date: 2016-05-30 07:46:09
permalink: design_pattern/strategy
keywords:
  - java 策略模式
  - java strategy pattern
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
description: 本文结合实例详述了策略模式的实现方式，并介绍了如何结合简单工厂模式及Annotation优化策略模式。最后分析了策略模式的优缺点及已（未）遵循的OOP原则
---

　　原创文章，转载请务必将下面这段话置于文章开头处。
　　本文转发自[**Jason's Blog**](http://www.jasongj.com)，[原文链接](http://www.jasongj.com/design_pattern/strategy/)　[http://www.jasongj.com/design_pattern/strategy/](http://www.jasongj.com/design_pattern/strategy/)


# 策略模式介绍

## 策略模式定义
策略模式（Strategy Pattern），将各种算法封装到具体的类中，作为一个抽象策略类的子类，使得它们可以互换。客户端可以自行决定使用哪种算法。


## 策略模式类图
策略模式类图如下
![Strategy Pattern Class Diagram](//www.jasongj.com/img/designpattern/strategy/Strategy.png)


## 策略模式角色划分
 - ***Strategy*** 策略接口或者（抽象策略类），定义策略执行接口
 - ***ConcreteStrategy*** 具体策略类
 - ***Context*** 上下文类，持有具体策略类的实例，并负责调用相关的算法


# 策略模式实例解析
本文代码可从[作者Github](https://github.com/habren/JavaDesignPattern/tree/master/StrategyPattern/src/main)下载

## 典型策略模式实现
策略接口，定义策略执行接口
```java
package com.jasongj.strategy;

public interface Strategy {

  void strategy(String input);

}
```

具体策略类，实现策略接口，提供具体算法
```java
package com.jasongj.strategy;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@com.jasongj.annotation.Strategy(name="StrategyA")
public class ConcreteStrategyA implements Strategy {

  private static final Logger LOG = LoggerFactory.getLogger(ConcreteStrategyB.class);

  @Override
  public void strategy(String input) {
    LOG.info("Strategy A for input : {}", input);
  }

}
```

```java
package com.jasongj.strategy;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@com.jasongj.annotation.Strategy(name="StrategyB")
public class ConcreteStrategyB implements Strategy {

  private static final Logger LOG = LoggerFactory.getLogger(ConcreteStrategyB.class);

  @Override
  public void strategy(String input) {
    LOG.info("Strategy B for input : {}", input);
  }

}
```

Context类，持有具体策略类的实例，负责调用具体算法
```java
package com.jasongj.context;

import com.jasongj.strategy.Strategy;

public class SimpleContext {

  private Strategy strategy;
  
  public SimpleContext(Strategy strategy) {
    this.strategy = strategy;
  }
  
  public void action(String input) {
    strategy.strategy(input);
  }
  
}
```

客户端可以实例化具体策略类，并传给Context类，通过Context统一调用具体算法
```java
package com.jasongj.client;

import com.jasongj.context.SimpleContext;
import com.jasongj.strategy.ConcreteStrategyA;
import com.jasongj.strategy.Strategy;

public class SimpleClient {

  public static void main(String[] args) {
    Strategy strategy = new ConcreteStrategyA();
    SimpleContext context = new SimpleContext(strategy);
    context.action("Hellow, world");
  }

}
```

## 使用Annotation和简单工厂模式增强策略模式
上面的实现中，客户端需要显示决定具体使用何种策略，并且一旦需要换用其它策略，需要修改客户端的代码。解决这个问题，一个比较好的方式是使用简单工厂，使得客户端都不需要知道策略类的实例化过程，甚至都不需要具体哪种策略被使用。

如《[Java设计模式（一） 简单工厂模式不简单](//www.jasongj.com/design_pattern/simple_factory/)》所述，简单工厂的实现方式比较多，可以结合《[Java系列（一）Annotation（注解）](//www.jasongj.com/2016/01/17/Java1_注解Annotation)》中介绍的Annotation方法。

使用Annotation和简单工厂模式的Context类如下
```java
package com.jasongj.context;

import java.util.Collections;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import org.apache.commons.configuration.ConfigurationException;
import org.apache.commons.configuration.XMLConfiguration;
import org.reflections.Reflections;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.jasongj.strategy.Strategy;

public class SimpleFactoryContext {

  private static final Logger LOG = LoggerFactory.getLogger(SimpleFactoryContext.class);
  private static Map<String, Class> allStrategies;

  static {
    Reflections reflections = new Reflections("com.jasongj.strategy");
    Set<Class<?>> annotatedClasses =
        reflections.getTypesAnnotatedWith(com.jasongj.annotation.Strategy.class);
    allStrategies = new ConcurrentHashMap<String, Class>();
    for (Class<?> classObject : annotatedClasses) {
      com.jasongj.annotation.Strategy strategy = (com.jasongj.annotation.Strategy) classObject
          .getAnnotation(com.jasongj.annotation.Strategy.class);
      allStrategies.put(strategy.name(), classObject);
    }
    allStrategies = Collections.unmodifiableMap(allStrategies);
  }

  private Strategy strategy;

  public SimpleFactoryContext() {
    String name = null;
    try {
      XMLConfiguration config = new XMLConfiguration("strategy.xml");
      name = config.getString("strategy.name");
      LOG.info("strategy name is {}", name);
    } catch (ConfigurationException ex) {
      LOG.error("Parsing xml configuration file failed", ex);
    }

    if (allStrategies.containsKey(name)) {
      LOG.info("Created strategy name is {}", name);
      try {
        strategy = (Strategy) allStrategies.get(name).newInstance();
      } catch (InstantiationException | IllegalAccessException ex) {
        LOG.error("Instantiate Strategy failed", ex);
      }
    } else {
      LOG.error("Specified Strategy name {} does not exist", name);
    }

  }

  public void action(String input) {
    strategy.strategy(input);
  }

}
```

从上面的实现可以看出，虽然并没有单独创建一个简单工厂类，但它已经融入了简单工厂模式的设计思想和实现方法。

客户端调用方式如下
```java
package com.jasongj.client;

import com.jasongj.context.SimpleFactoryContext;

public class SimpleFactoryClient {

  public static void main(String[] args) {
    SimpleFactoryContext context = new SimpleFactoryContext();
    context.action("Hellow, world");
  }

}
```

从上面代码可以看出，引入简单工厂模式后，客户端不再需要直接实例化具体的策略类，也不需要判断应该使用何种策略，可以方便应对策略的切换。


# 策略模式分析
## 策略模式优点
 - 策略模式提供了对“开闭原则”的完美支持，用户可以在不修改原有系统的基础上选择算法（策略），并且可以灵活地增加新的算法（策略）。
 - 策略模式通过Context类提供了管理具体策略类（算法族）的办法。
 - 结合简单工厂模式和Annotation，策略模式可以方便的在不修改客户端代码的前提下切换算法（策略）。

## 策略模式缺点
 - 传统的策略模式实现方式中，客户端必须知道所有的具体策略类，并须自行显示决定使用哪一个策略类。但通过本文介绍的通过和Annotation和简单工厂模式结合，可以有效避免该问题
 - 如果使用不当，策略模式可能创建很多具体策略类的实例，但可以通过使用上文《[Java设计模式（十一） 享元模式](//www.jasongj.com/design_pattern/flyweight/)》介绍的享元模式有效减少对象的数量。

# 策略模式已（未）遵循的OOP原则
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
