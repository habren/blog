---
title: Java进阶（一）Annotation（注解）
date: 2016-01-17 15:11:29
updated: 2017-02-15 20:31:23
permalink: 2016/01/17/Java1_注解Annotation
sticky: 6
keywords:
  - java
  - Java
  - JAVA
  - 注解
  - annotation
  - Annotation
  - Jason's Blog
  - 郭俊 Jason
  - 大数据架构
  - java 注解
  - java annotation
tags:
  - java
categories:
  - java
description: 本文介绍了Java Annotation的概念及Java提供的四种Meta Annotation的功能，并结合实例详解了自定义Annotation的方法和注意事项
---

>原创文章，转载请务必将下面这段话置于文章开头处（保留超链接）。
>本文转发自[**Jason's Blog**](http://www.jasongj.com)，[原文链接](http://www.jasongj.com/2016/01/17/Java1_注解Annotation)　[http://www.jasongj.com/2016/01/17/Java1_注解Annotation](http://www.jasongj.com/2016/01/17/Java1_注解Annotation)



# 概念

Annotation是Java5开始引入的特性。它提供了一种安全的类似于注释和Java doc的机制。实事上，Annotation已经被广泛用于各种Java框架，如Spring，Jersey，JUnit，TestNG。注解相当于是一种嵌入在程序中的元数据，可以使用注解解析工具或编译器对其进行解析，也可以指定注解在编译期或运行期有效。这些元数据与程序业务逻辑无关，并且是供指定的工具或框架使用的。



# Meta Annotation

元注解的作用就是负责注解其他注解。Java5定义了4个标准的Meta Annotation类型，它们被用来提供对其它 Annotation类型作说明。



## @Target

`@Target`说明了Annotation所修饰的对象范围：Annotation可被用于 packages、types（类、接口、枚举、Annotation类型）、类型成员（方法、构造方法、成员变量、枚举值）、方法参数和本地变量（如循环变量、catch参数）。在Annotation类型的声明中使用了`@Target`可更加明晰其修饰的目标。

`@Target`作用：用于描述注解的使用范围，即被描述的注解可以用在什么地方

`@Target`取值(ElementType)
- `CONSTRUCTOR`：用于描述构造器
- `FIELD`：用于描述域
- `LOCAL_VARIABLE`：用于描述局部变量
- `METHOD`：用于描述方法
- `PACKAGE`：用于描述包
- `PARAMETER`：用于描述参数
- `TYPE`：用于描述类、接口(包括注解类型) 或enum声明



## @Retention

`@Retention`定义了该Annotation的生命周期：某些Annotation仅出现在源代码中，而被编译器丢弃；而另一些却被编译在class文件中；编译在class文件中的Annotation可能会被虚拟机忽略，而另一些在class被装载时将被读取（请注意并不影响class的执行，因为Annotation与class在使用上是被分离的）。`@Retention`有唯一的value作为成员。

`@Retention`作用：表示需要在什么级别保存该注释信息，用于描述注解的生命周期（即：被描述的注解在什么范围内有效）

`@Retention`取值来自`java.lang.annotation.RetentionPolicy`的枚举类型值
- SOURCE:在源文件中有效（即源文件保留）
- CLASS:在class文件中有效（即class保留）
- RUNTIME:在运行时有效（即运行时保留）



## @Documented

`@Documented`用于描述其它类型的annotation应该被作为被标注的程序成员的公共API，因此可以被例如javadoc此类的工具文档化。`@Documented`是一个标记注解，没有成员。


## @Inherited

`@Inherited` 是一个标记注解。如果一个使用了`@Inherited`修饰的annotation类型被用于一个class，则这个Annotation将被用于该class的子类。



# 自定义Annotation

在实际项目中，经常会碰到下面这种场景，一个接口的实现类或者抽象类的子类很多，经常需要根据不同情况（比如根据配置文件）实例化并使用不同的子类。典型的例子是结合工厂使用职责链模式。

此时，可以为每个实现类加上特定的Annotation，并在Annotation中给该类取一个标识符，应用程序可通过该标识符来判断应该实例化哪个子类。

下面这个例子，定义了一个名为Component的Annotation，它包含一个名为identifier的成员变量。
```Java
package com.jasongj.annotation;

import java.lang.annotation.Documented;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import java.lang.annotation.ElementType;
import java.lang.annotation.Inherited;
import java.lang.annotation.Retention;

@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
public @interface Component {
	String identifier () default "";
}
```

对于上文所说的实现类加上`@Component`
```Java
package com.jasongj;

import com.jasongj.annotation.Component;

@Component(identifier="upper")
public class UpperCaseComponent {

	public String doWork(String input) {
		if(input != null) {
			return input.toUpperCase();
		} else {
			return null;
		}
	}
}
```

应用程序中可以通过反射获取UpperCaseComponent对应的identifier
```Java
package com.jasongj;

import com.jasongj.annotation.Component;

public class Client {
    public static void main(String[] args) {
        try {
            Class componentClass = Class.forName("com.jasongj.UpperCaseComponent");
            if(componentClass.isAnnotationPresent(Component.class)) {
                Component component = (Component)componentClass.getAnnotation(Component.class);
                String identifier = component.identifier();
                System.out.println(String.format("Identifier for "
                    + "com.jasongj.UpperCaseComponent is ' %s '", identifier));
            } else {
                System.out.println("com.jasongj.UpperCaseComponent is not annotated by"
						+ " com.jasongj.annotation.Component");
            }
        } catch (ClassNotFoundException ex) {
			ex.printStackTrace();
        }
    }
}

```

结果如下
```
Identifier for com.jasongj.UpperCaseComponent is ' upper '
```

如果把`@Component`的`@Retention`设置为	`RetentionPolicy.SOURCE`或者`RetentionPolicy.CLASS`，则会得到如下结果，验证了上文中对`@Retention`的描述
```
com.jasongj.UpperCaseComponent is not annotated by com.jasongj.annotation.Component
```

# Java内置Annotation

Annotation的语法比较简单，除了@符号的使用外，他基本与Java固有的语法一致，JavaSE中内置三个标准Annotation，定义在`java.lang`中：
1. `@Override` 是一个标记型Annotation，说明了被标注的方法覆盖了父类的方法，起到了断言的作用。如果给一个非覆盖父类方法的方法添加该Annotation，编译器将报编译错误。它有两个典型的使用场景，一是在试图覆盖父类方法却写错了方法名时报错，二是删除已被子类覆盖（且用Annotation修饰）的父类方法时报错。
2. `@Deprecated` 标记型Annotation，说明被修改的元素已被废弃并不推荐使用，编译器会在该元素上加一条横线以作提示。该修饰具有一定的“传递性”：如果我们通过继承的方式使用了这个弃用的元素，即使继承后的元素（类，成员或者方法）并未被标记为`@Deprecated`，编译器仍然会给出提示。
3. `@SuppressWarnnings` 用于通知Java编译器关闭对特定类、方法、成员变量、变量初始化的警告。此种警告一般代表了可能的程序错误，例如当我们使用一个generic collection类而未提供它的类型时，编译器将提示“unchecked warning”的警告。通常当这种情况发生时，我们需要查找引起警告的代码，如果它真的表示错误，我们就需要纠正它。然而，有时我们无法避免这种警告，例如，我们使用必须和非generic的旧代码交互的generic collection类时，我们无法避免这个unchecked warning，此时可以在调用的方法前增加`@SuppressWarnnings`通知编译器关闭对此方法的警告。


`@SuppressWarnnings`不是标记型Annotation，它有一个类型为String[]的成员，这个成员的值为被禁止的警告名。常见的警告名为下。
- `unchecked` 执行了未检查的转换时的警告。例如当使用集合时没有用泛型来指定集合的类型
- `finally` finally子句不能正常完成时的警告
- `fallthrough` 当switch程序块直接通往下一种情况而没有break时的警告
- `deprecation` 使用了弃用的类或者方法时的警告
- `seriel` 在可序列化的类上缺少serialVersionUID时的警告
- `path` 在类路径、源文件路径等中有不存在的路径时的警告
- `all` 对以上所有情况的警告





# Annotation与Interface的异同

- Annotation类型使用关键字`@interface`而非`interface`。注意开头的`@`符号
- Annotataion的方法定义是受限制的。其方法必须声明为无参数、无异常抛出的。这些方法同时也定义了Annotation的成员——方法名即为成员名，而方法返回类型即为成员类型。方法返回类型必须为Java基础类型、Class类型、枚举类型、Annotation类型或者相应的一维数组。方法后面可以使用default关键字和一个默认数值来声明成员的默认值，null不能作为成员默认值。成员一般不能是泛型，只有当其类型是Class时可以使用泛型，因为此方法能够用类型转换将各种类型转换为Class
- Annotation和interface都可以定义常量、静态成员类型，也都可以被实现或者继承


# Java进阶系列
 - [Java进阶（一）Annotation（注解）](//www.jasongj.com/2016/01/17/Java1_注解Annotation/)
 - [Java进阶（二）当我们说线程安全时，到底在说什么](//www.jasongj.com/java/thread_safe)
 - [Java进阶（三）多线程开发关键技术](//www.jasongj.com/java/multi_thread)
 - [Java进阶（四）线程间通信方式对比](//www.jasongj.com/java/thread_communication)
