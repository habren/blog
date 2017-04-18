---
title: UML(一) 类图详解
page_title: UML 类图 架构师 依赖 关联 聚合 组合 实现 继承 
date: 2016-08-08 06:55:29
updated: 2017-03-15 21:17:39
permalink: uml/class_diagram
keywords:
  - UML
  - 类图
  - 系统设计
  - 架构设计
  - 技术世界
  - 郭俊 Jason
  - 大数据架构
tags:
  - system design
  - 系统设计
  - 架构设计
  - UML
categories:
  - system design
  - 系统设计
description: 在UML 2.*的13种图形中，类图是使用频率最高的UML图之一，它表示了类与类之间的关系，帮助开发人员理解系统。它是系统分析和设计阶段的重要产物，也是系统编码和测试的重要模型依据。本文详细介绍了类间的依赖关系，关联关系（聚合、组合等），实现关系以及继承关系的UML表示形式及其在代码中的实现方式。
---

>原创文章，转载请务必将下面这段话置于文章开头处（保留超链接）。
>本文转发自[**技术世界**](http://www.jasongj.com)，[原文链接](http://www.jasongj.com/uml/class_diagram/)　[http://www.jasongj.com/uml/class_diagram/](http://www.jasongj.com/uml/class_diagram/)

# UML类图
## UML类图介绍
在UML 2.*的13种图形中，类图是使用频率最高的UML图之一。类图用于描述系统中所包含的类以及它们之间的相互关系，帮助开发人员理解系统，它是系统分析和设计阶段的重要产物，也是系统编码和测试的重要模型依据。

## 类的UML图示
在UML类图中，类使用包含类名、属性和方法且带有分隔线的长方形来表示。如一个Employee类，它包含private属性age，protected属性name，public属性email，package属性gender，public方法work()。其UML类图表示如下图所示。
![Class in Class Diagram](//www.jasongj.com/img/system_design/uml/class/employee.png)

### 属性及方法表示形式
UML规定类图中属性的表示方式为
```
可见性 名称 : 类型 [=缺省值]
```

方法表示形式为
```
可见性 方法名 [参数名 : 参数类型] : 返回值类型
```

方法的多个参数间用逗号隔开，无返回值时，其类型为`void`


### 属性及方法可见性
 - **public** 用`+`表示
 - **private** 用`-`表示
 - **protected** 用`#`表示
 - **package** 用`~`表示

### 接口的UML图示
![Class in Class Diagram](//www.jasongj.com/img/system_design/uml/class/person.png)

接口的表示形式与类类似，区别在于接口名须以尖括号包裹，同时接口无属性框，方法可见性只可能为`public`，这是由接口本身的特性决定的。

# 类间关系

## 依赖关系
### 依赖关系说明
依赖关系是一种偶然的、较弱的使用关系，特定事物的改变可能影响到使用该事情的其它事物，在需要表示一个事物使用另一个事物时使用依赖关系。

### 依赖关系UML表示
UML中使用带箭头的虚线表示类间的依赖（Dependency）关系，箭头由依赖类指向被依赖类。下图表示Dirver类依赖于Car类
![Class in Class Diagram](//www.jasongj.com/img/system_design/uml/class/dependency.png)


### 依赖关系的表现形式
 - B类的实例作为A类方法的参数
 - B类的实例作为A类方法的局部变量
 - A类调用B类的静态方法


## 关联关系
关联（Association）关系是一种结构化关系，用于表示一类对象与另一类对象之间的联系。在Java中实现关联关系时，通常将一个类的对象作为另一个类的成员变量。

在UML类图中，用实线连接有关联关系的类，并可在关联线上标注角色名或关系名。

在UML中，关联关系包含如下四种形式

### 双向关联
默认情况下，关联是双向的。例如数据库管理员（DBA）管理数据库（DB），同时每个数据库都被某位管理员管理。因此，DBA和DB之间具有双向关联关系，如下图所示。

![Dual Association](//www.jasongj.com/img/system_design/uml/class/dba_db.png)

从上图可看出，双向关联的类的实例，互相持有对方的实例，并且可在关联线上注明二者的关系，必须同时注明两种关系（如上图中的manage和managed by）。


### 单向关联
单向关联用带箭头的实线表示，同时一方持有另一方的实例，并且由于是单向关联，如果在关联线上注明关系，则只可注明单向的关系，如下图所示。

![One-way Association](//www.jasongj.com/img/system_design/uml/class/student_score.png)

### 自关联
自关联是指属性类型为该类本身。例如在链表中，每个节点持有下一个节点的实例，如下图所示。

![Self Association](//www.jasongj.com/img/system_design/uml/class/node.png)

### 多重性关联
多重性（Multiplicity）关联关系，表示两个对象在数量上的对应关系。在UML类图中，对象间的多重性可在关联线上用一个数字或数字范围表示。常见的多重性表示方式如下表所示。

| 表示方式 | 多重性说明 |
|---------------------------|
| 1..1 | 另一个类的一个对象只与该类的一个对象有关系 |
| 0..* | 另一个类的一个对象只与该类的零个或多个对象有关系 |
| 1..* | 另一个类的一个对象与该类的一个或多个对象有关系 |
| 0..1 | 另一个类的一个对象与该类的对象没关系或者只与该类的一个对象有关系 |
| m..n | 另一个类的一个对象与该类最少m，最多n个对象有关系 |

例如一个网页可能没有可点击按钮，也可能有多个按钮，但是该页面中的一个按钮只属于该页面，其关联多重性如下图所示。
![Multiplicity](//www.jasongj.com/img/system_design/uml/class/page_button.png)

## 聚合关系
聚合（Aggregation）关系表示整体与部分的关系。在聚合关系中，部分对象是整体对象的一部分，但是部分对象可以脱离整体对象独立存在，也即整体对象并不控制部分对象的生命周期。从代码实现上来讲，部分对象不由整体对象创建，一般通过整体类的带参构造方法或者Setter方法或其它业务方法传入到整体对象，并且有整体对象以外的对象持有部分对象的引用。

在UML类图中，聚合关系由带箭头的实线表示，并且实线的起点处以空心菱形表示，如下图所示。
![Aggregation](//www.jasongj.com/img/system_design/uml/class/library_book.png)

《[Java设计模式（六）代理模式 vs. 装饰模式](//www.jasongj.com/design_pattern/proxy_decorator/)》一文中所述[装饰模式](//www.jasongj.com/design_pattern/proxy_decorator/#u88C5_u9970_u7C7B_u548C_u4F7F_u7528_u65B9_u5F0F)中，装饰类的对象与被装饰类的对象即为聚合关系。


## 组合关系
组合（Composition）关系也表示类之间整体和部分的关系，但是在组合关系中整体对象控制成员对象的生命周期，一旦整体对象不存在了，成员对象也即随之消亡。

从代码实现上看，一般在整体类的构造方法中直接实例化成员类，并且除整体类对象外，其它类的对象无法获取该对象的引用。

在UML类图中，组合关系的表示方式与聚合关系类似，区别在于实线以实心菱形表示。
![Composition](//www.jasongj.com/img/system_design/uml/class/cat_leg.png)

《[Java设计模式（六）代理模式 vs. 装饰模式](//www.jasongj.com/design_pattern/proxy_decorator/)》一文中所述[代理模式](//www.jasongj.com/design_pattern/proxy_decorator/#u4EE3_u7406_u7C7B_u548C_u4F7F_u7528_u65B9_u5F0F)中，代理类的对象与被代理类的对象即为组合关系。


## 泛化关系/继承关系
泛化（Generalization）关系，用于描述父类与子类之间的关系，父类又称作超类或者其类，子类又称为派生类。注意，父类和子类都可为抽象类或者具体类。

在Java中，我们使用面向对象的三大特性之一——继承来实现泛化关系，具体来说会用到`extends`关键字。

在UML类图中，泛化关系用带空心三角形（指向父类）的实线表示。并且子类中不需要标明其从父类继承下来的属性和方法，只须注明其新增的属性和方法即可。
![Generalization](//www.jasongj.com/img/system_design/uml/class/employee_manager.png)

## 实现关系
很多面向对象编程语言（如Java）中都引入了接口的概念。接口与接口之间可以有类与类之间类似的继承和依赖关系。同时接口与类之间还存在一种实现（Realization）关系，在这种关系中，类实现了接口中声明的方法。

在UML类图中，类与接口间的实现关系用带空心三角形的虚线表示。同时类中也需要列出接口中所声明的所有方法（这一点与类间的继承关系表示不同）。
![Realization](//www.jasongj.com/img/system_design/uml/class/truck_car.png)


# UML类图十万个为什么

***聚合关系与组合关系都表示整体与部分的关系，有何区别？***
聚合关系中，部分对象的生命周期独立于整体对象的生命周期，或者整体对象消亡后部分对象仍然可以独立存在，同时在代码中一般通过整体类的带参构造方法或Setter方法将部分类对象传入整体类的对象，UML中表示聚合关系的实线以空心菱形开始。
组合关系中，部分类对象的生命周期由整体对象控制，一旦整体对象消亡，部分类的对象随即消亡。代码中一般在整体类的构造方法内创建部分类的对象，UML中表示组合关系的实线以实心菱形开始。
同时在组合关系中，部分类的对象只属于某一个确定的整体类对象；而在聚合关系中，部分类对象可以属于一个或多个整体类对象。
如同《[Java设计模式（六）代理模式 vs. 装饰模式](//www.jasongj.com/design_pattern/proxy_decorator/)》一文中所述[代理模式](//www.jasongj.com/design_pattern/proxy_decorator/#u4EE3_u7406_u7C7B_u548C_u4F7F_u7528_u65B9_u5F0F)中，代理类的对象与被代理类的对象即为组合关系。[装饰模式](//www.jasongj.com/design_pattern/proxy_decorator/#u88C5_u9970_u7C7B_u548C_u4F7F_u7528_u65B9_u5F0F)中，装饰类的对象与被装饰类的对象即为聚合关系。


***聚合关系、组合关系与关联关系有何区别和联系？***
聚合关系、组合关系和关联关系实质上是对象间的关系（继承和实现是类与类和类与接口间的关系）。从语意上讲，关联关系中两种对象间一般是平等的，而聚合和组合则代表整体和部分间的关系。而聚合与组合的区别主要体现在实现上和生命周期的管理上。


***依赖关系与关联关系的区别是？***
依赖关系是较弱的关系，一般表现为在局部变量中使用被依赖类的对象、以被依赖类的对象作为方法参数以及使用被依赖类的静态方法。而关联关系是相对较强的关系，一般表现为一个类包含一个类型为另外一个类的属性。










