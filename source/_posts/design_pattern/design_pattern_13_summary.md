---
title: Java设计模式（十三） 别人再问你设计模式，叫他看这篇文章
page_title: Java 设计模式 终结篇 OOP三大特征 OOD七项原则 设计模式十万个为什么
date: 2016-06-02 07:26:09
updated: 2017-02-17 20:31:23
permalink: design_pattern/summary
keywords:
  - java 设计模式
  - java design pattern
  - 设计模式
  - design pattern
  - 为什么 设计模式
  - why design pattern
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
description: 本文讲解了设计模式与OOP的三大特性及OOP七项原则间的关系，并讲解了使用设计模式的好处及为何需要使用设计模式。最后通过问答形式讲解了设计模式相关的常见问题
---

>原创文章，转载请务必将下面这段话置于文章开头处（保留超链接）。
>本文转发自[**Jason's Blog**](http://www.jasongj.com)，[原文链接](http://www.jasongj.com/design_pattern/summary/)　[http://www.jasongj.com/design_pattern/summary/](http://www.jasongj.com/design_pattern/summary/)


# OOP三大基本特性
## 封装
封装，也就是把客观事物封装成抽象的类，并且类可以把自己的属性和方法只让可信的类操作，对不可信的进行信息隐藏。

## 继承
继承是指这样一种能力，它可以使用现有的类的所有功能，并在无需重新编写原来类的情况下对这些功能进行扩展。

## 多态
多态指一个类实例的相同方法在不同情形有不同的表现形式。具体来说就是不同实现类对公共接口有不同的实现方式，但这些操作可以通过相同的方式（公共接口）予以调用。

# OOD***七***大原则
面向对象设计（OOD）有***七***大原则（是的，你没看错，是七大原则，不是六大原则），它们互相补充。

## 开-闭原则
Open-Close Principle（OCP），即开-闭原则。开，指的是对扩展开放，即要支持方便地扩展；闭，指的是对修改关闭，即要严格限制对已有内容的修改。开-闭原则是最抽象也是最重要的OOD原则。[简单工厂模式](//www.jasongj.com/design_pattern/simple_factory/)、[工厂方法模式](//www.jasongj.com/design_pattern/factory_method/)、[抽象工厂模式](//www.jasongj.com/design_pattern/abstract_factory/)中都提到了如何通过良好的设计遵循开-闭原则。

## 里氏替换原则
Liskov Substitution Principle（LSP），即里氏替换原则。该原则规定“子类必须能够替换其父类，否则不应当设计为其子类”。换句话说，父类出现的地方，都应该能由其子类代替。所以，子类只能去扩展基类，而不是隐藏或者覆盖基类。

## 依赖倒置原则
Dependence Inversion Principle（DIP），依赖倒置原则。它讲的是“设计和实现要依赖于抽象而非具体”。一方面抽象化更符合人的思维习惯；另一方面，根据里氏替换原则，可以很容易将原来的抽象替换为扩展后的具体，这样可以很好的支持开-闭原则。

## 接口隔离原则
Interface Segration Principle（ISP），接口隔离原则，“将大的接口打散成多个小的独立的接口”。由于Java类支持实现多个接口，可以很容易的让类具有多种接口的特征，同时每个类可以选择性地只实现目标接口。

## 单一职责原则
Single Responsibility Principle（SRP），单一职责原则。它讲的是，不要存在多于一个导致类变更的原因，是高内聚低耦合的一个体现。

## 迪米特法则/最少知道原则
Law of Demeter or Least Knowledge Principle（LoD or LKP），迪米特法则或最少知道原则。它讲的是“一个对象就尽可能少的去了解其它对象”，从而实现松耦合。如果一个类的职责过多，由于多个职责耦合在了一起，任何一个职责的变更都可能引起其它职责的问题，严重影响了代码的可维护性和可重用性。

## 合成/聚合复用原则
Composite/Aggregate Reuse Principle（CARP / CRP），合成/聚合复用原则。如果新对象的某些功能在别的已经创建好的对象里面已经实现，那么应当尽量使用别的对象提供的功能，使之成为新对象的一部分，而不要再重新创建。新对象可通过向这些对象的委派达到复用已有功能的效果。简而言之，要尽量使用合成/聚合，而非使用继承。《[Java设计模式（九） 桥接模式](//www.jasongj.com/design_pattern/bridge/)》中介绍的桥接模式即是对这一原则的典型应用。

# 设计模式
## 什么是设计模式
可以用一句话概括设计模式———设计模式是一种利用OOP的封闭、继承和多态三大特性，同时在遵循单一职责原则、开闭原则、里氏替换原则、迪米特法则、依赖倒置原则、接口隔离原则及合成/聚合复用原则的前提下，被总结出来的经过反复实践并被多数人知晓且经过分类和设计的可重用的软件设计方式。

## 设计模式十万个为什么
### 为什么要用设计模式
 - 设计模式是高级软件工程师和架构师面试基本必问的项目（先通过面试进入这个门槛我们再谈其它）
 - 设计模式是经过大量实践检验的安全高效可复用的解决方案。不要重复发明轮子，而且大多数时候你发明的轮子还没有已有的好
 - 设计模式是被主流工程师/架构师所广泛接受和使用的，你使用它，方便与别人沟通，也方便别人code review（这个够实在吧）
 - 使用设计模式可以帮你快速解决80%的代码设计问题，从而让你更专注于业务本身
 - 设计模式本身是对几大特性的利用和对几大设计原则的践行，代码量积累到一定程度，你会发现你已经或多或少的在使用某些设计模式了
 - 架构师或者team leader教授初级工程师设计模式，可以很方便的以大家认可以方式提高初级工程师的代码设计水平，从而有利于提高团队工程实力

### 是不是一定要尽可能使用设计模式
每个设计模式都有其适合范围，并解决特定问题。所以项目实践中应该针对特定使用场景选用合适的设计模式，如果某些场景下现在的设计模式都不能很完全的解决问题，那也不必拘泥于设计模式本身。实际上，学习和使用设计模式本身并不是目的，目的是通过学习和使用它，强化面向对象设计思路并用合适的方法解决工程问题。

### 设计模式有时并非最优解
有些人认为，在某些特定场景下，设计模式并非最优方案，而自己的解决方案可能会更好。这个问题得分两个方面来讨论：一方面，如上文所述，所有设计模式都有其适用场景，“one size does not fit all”；另一方面，确实有可能自己设计的方案比设计模式更适合，但这并不影响你学习并使用设计模式，因为设计模式经过大量实战检验能在绝大多数情况下提供良好方案。

### 设计模式太教条化
设计模式虽然都有其相对固定的实现方式，但是它的精髓是利用OOP的三大特性，遵循OOD七大原则解决工程问题。所以学习设计模式的目的不是学习设计模式的固定实现方式本身，而是其思想。

### 我有自己的一套思路，没必要引导团队成员学习设计模式
设计模式是被广泛接受和使用的，引导团队成员使用设计模式可以减少沟通成本，而更专注于业务本身。也许你有自己的一套思路，但是你怎么能保证团队成员一定认可你的思路，进而将你的思路贯彻实施呢？统一使用设计模式能让团队只使用20%的精力决解80%的问题。其它20%的问题，才是你需要花精力解决的。



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
- [Java设计模式（十三） 别人再问你设计模式，叫他看这篇文章](//www.jasongj.com/design_pattern/summary/)
