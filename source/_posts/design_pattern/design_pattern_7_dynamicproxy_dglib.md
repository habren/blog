---
title: Java设计模式（七） Spring AOP  JDK动态代理 VS. cglib
date: 2016-05-02 20:42:46
permalink: design_pattern/dynamic_proxy_cglib
keywords:
  - jdk 动态代理
  - cglib
  - 动态代理 cglib
  - AOP cglib
  - AOP 动态代理
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
description: Spring的AOP有JDK动态代理和cglib两种实现方式。JDK动态代理要求被代理对象实现接口；cglib通过动态继承实现，因此不能代理被final修饰的类；JDK动态代理生成代理对象速度比cglib快；cglib生成的代理对象比JDK动态代理生成的代理对象执行效率高。
---

>原创文章，转载请务必将下面这段话置于文章开头处（保留超链接）。
>本文转发自[**Jason's Blog**](http://www.jasongj.com)，[原文链接](http://www.jasongj.com/design_pattern/dynamic_proxy_cglib/)　[http://www.jasongj.com/design_pattern/dynamic_proxy_cglib/](http://www.jasongj.com/design_pattern/dynamic_proxy_cglib/)

# 静态代理 VS. 动态代理
静态代理，是指程序运行前就已经存在了代理类的字节码文件，代理类和被代理类的关系在运行前就已经确定。

上一篇文章《[Java设计模式（六） 代理模式 VS. 装饰模式](http://www.jasongj.com/design_pattern/proxy_decorator/)》所讲的代理为静态代理。如上文所讲，一个静态代理类只代理一个具体类。如果需要对实现了同一接口的不同具体类作代理，静态代理需要为每一个具体类创建相应的代理类。

动态代理类的字节码是在程序运行期间动态生成，所以不存在代理类的字节码文件。代理类和被代理类的关系是在程序运行时确定的。


# JDK动态代理
JDK从1.3开始引入动态代理。可通过`java.lang.reflect.Proxy`类的静态方法`Proxy.newProxyInstance`动态创建代理类和实例。并且由它动态创建出来的代理类都是Proxy类的子类。

## 定义代理行为
代理类往往会在代理对象业务逻辑前后增加一些功能性的行为，如使用事务或者打印日志。本文把这些行为称之为***代理行为***。

使用JDK动态代理，需要创建一个实现`java.lang.reflect.InvocationHandler`接口的类，并在该类中定义代理行为。


```java
package com.jasongj.proxy.jdkproxy;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SubjectProxyHandler implements InvocationHandler {

  private static final Logger LOG = LoggerFactory.getLogger(SubjectProxyHandler.class);

  private Object target;
  
  @SuppressWarnings("rawtypes")
  public SubjectProxyHandler(Class clazz) {
    try {
      this.target = clazz.newInstance();
    } catch (InstantiationException | IllegalAccessException ex) {
      LOG.error("Create proxy for {} failed", clazz.getName());
    }
  }

  @Override
  public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
    preAction();
    Object result = method.invoke(target, args);
    postAction();
    return result;
  }

  private void preAction() {
    LOG.info("SubjectProxyHandler.preAction()");
  }

  private void postAction() {
    LOG.info("SubjectProxyHandler.postAction()");
  }

}
```

从上述代码中可以看到，被代理对象的类对象作为参数传给了构造方法，原因如下
 - 如上文所述，动态代理可以代理多种类，而且具体代理哪种类并非台静态代理那样编译时确定，而是在运行时指定
 - 之所以不传被代理类的实例而是传类对象，是为了与上文《[Java设计模式（六） 代理模式 VS. 装饰模式](http://www.jasongj.com/design_pattern/proxy_decorator/)》吻合——被代理对象不由客户端创建而由代理创建，客户端甚至都不需要知道被代理对象的存在。具体传被代理类的实例还是传类对象，并无严格规定
 - 一些讲JDK动态代理的例子会专门使用一个public方法去接收该参数。但笔者个人认为最好不要在具体类中实现未出现在接口定义中的public方法


注意，SubjectProxyHandler定义的是代理行为而非代理类本身。实际上代理类及其实例是在运行时通过反射动态创建出来的。


## JDK动态代理使用方式
代理行为定义好后，先实例化SubjectProxyHandler（在构造方法中指明被代理类），然后通过Proxy.newProxyInstance动态创建代理类的实例。
```java
package com.jasongj.client;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Proxy;

import com.jasongj.proxy.jdkproxy.SubjectProxyHandler;
import com.jasongj.subject.ConcreteSubject;
import com.jasongj.subject.ISubject;

public class JDKDynamicProxyClient {

  public static void main(String[] args) {
    InvocationHandler handler = new SubjectProxyHandler(ConcreteSubject.class);
    ISubject proxy =
        (ISubject) Proxy.newProxyInstance(JDKDynamicProxyClient.class.getClassLoader(),
            new Class[] {ISubject.class}, handler);
    proxy.action();
  }

}
```

从上述代码中也可以看到，Proxy.newProxyInstance的第二个参数是类对象数组，也就意味着被代理对象可以实现多个接口。

运行结果如下
```
SubjectProxyHandler.preAction()
ConcreteSubject action()
SubjectProxyHandler.postAction()
Proxy class name com.sun.proxy.$Proxy18
```

从上述结果可以看到，定义的代理行为顺利的加入到了执行逻辑中。同时，最后一行日志说明了代理类的类名是`com.sun.proxy.$Proxy18`，验证了上文的论点——SubjectProxyHandler定义的是代理行为而非代理类本身，代理类及其实例是在运行时通过反射动态创建出来的。

## 生成的动态代理类
Proxy.newProxyInstance是通过静态方法`ProxyGenerator.generateProxyClass`动态生成代理类的字节码的。为了观察创建出来的代理类的结构，本文手工调用该方法，得到了代理类的字节码，并将之输出到了class文件中。

```java
byte[] classFile = ProxyGenerator.generateProxyClass("$Proxy18", ConcreteSubject.class.getInterfaces());
```

使用反编译工具可以得到代理类的代码
```java
import com.jasongj.subject.ISubject;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.lang.reflect.UndeclaredThrowableException;

public final class $Proxy17 extends Proxy implements ISubject {
  private static Method m1;
  private static Method m2;
  private static Method m0;
  private static Method m3;

  public $Proxy17(InvocationHandler paramInvocationHandler) {
    super(paramInvocationHandler);
  }

  public final boolean equals(Object paramObject) {
    try {
      return ((Boolean) this.h.invoke(this, m1, new Object[] {paramObject})).booleanValue();
    } catch (Error | RuntimeException localError) {
      throw localError;
    } catch (Throwable localThrowable) {
      throw new UndeclaredThrowableException(localThrowable);
    }
  }

  public final String toString() {
    try {
      return (String) this.h.invoke(this, m2, null);
    } catch (Error | RuntimeException localError) {
      throw localError;
    } catch (Throwable localThrowable) {
      throw new UndeclaredThrowableException(localThrowable);
    }
  }

  public final int hashCode() {
    try {
      return ((Integer) this.h.invoke(this, m0, null)).intValue();
    } catch (Error | RuntimeException localError) {
      throw localError;
    } catch (Throwable localThrowable) {
      throw new UndeclaredThrowableException(localThrowable);
    }
  }

  public final void action() {
    try {
      this.h.invoke(this, m3, null);
      return;
    } catch (Error | RuntimeException localError) {
      throw localError;
    } catch (Throwable localThrowable) {
      throw new UndeclaredThrowableException(localThrowable);
    }
  }

  static {
    try {
      m1 = Class.forName("java.lang.Object").getMethod("equals",
          new Class[] {Class.forName("java.lang.Object")});
      m2 = Class.forName("java.lang.Object").getMethod("toString", new Class[0]);
      m0 = Class.forName("java.lang.Object").getMethod("hashCode", new Class[0]);
      m3 = Class.forName("com.jasongj.subject.ISubject").getMethod("action", new Class[0]);
    } catch (NoSuchMethodException localNoSuchMethodException) {
      throw new NoSuchMethodError(localNoSuchMethodException.getMessage());
    } catch (ClassNotFoundException localClassNotFoundException) {
      throw new NoClassDefFoundError(localClassNotFoundException.getMessage());
    }
  }
}
```

从该类的声明中可以看到，继承了Proxy类，并实现了ISubject接口。验证了上文中的论点——所有生成的动态代理类都是Proxy类的子类。同时也解释了为什么JDK动态代理只能代理实现了接口的类——Java不支持多继承，代理类已经继承了Proxy类，无法再继承其它类。

同时，代理类重写了hashCode，toString和equals这三个从Object继承下来的接口，通过InvocationHandler的invoke方法去实现。除此之外，该代理类还实现了ISubject接口的action方法，也是通过InvocationHandler的invoke方法去实现。这就解释了示例代码中代理行为是怎样被调用的。

前文提到，被代理类可以实现多个接口。从代理类代码中可以看到，代理类是通过InvocationHandler的invoke方法去实现代理接口的。所以当被代理对象实现了多个接口并且希望对不同接口实施不同的代理行为时，应该在SubjectProxyHandler类，也即代理行为定义类中，通过判断方法名，实现不同的代理行为。

# cglib
## cglib介绍
cglib是一个强大的高性能代码生成库，它的底层是通过使用一个小而快的字节码处理框架ASM（Java字节码操控框架）来转换字节码并生成新的类。

## cglib方法拦截器
使用cglib实现动态代理，需要在MethodInterceptor实现类中定义代理行为。
```java
package com.jasongj.proxy.cglibproxy;

import java.lang.reflect.Method;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import net.sf.cglib.proxy.MethodInterceptor;
import net.sf.cglib.proxy.MethodProxy;

public class SubjectInterceptor implements MethodInterceptor {

  private static final Logger LOG = LoggerFactory.getLogger(SubjectInterceptor.class);

  @Override
  public Object intercept(Object obj, Method method, Object[] args, MethodProxy proxy)
      throws Throwable {
    preAction();
    Object result = proxy.invokeSuper(obj, args);
    postAction();
    return result;
  }

  private void preAction() {
    LOG.info("SubjectProxyHandler.preAction()");
  }

  private void postAction() {
    LOG.info("SubjectProxyHandler.postAction()");
  }

}
```

代理行为在intercept方法中定义，同时通过getInstance方法（该方法名可以自定义）获取动态代理的实例，并且可以通过向该方法传入类对象指定被代理对象的类型。

## cglib使用方式
```java
package com.jasongj.client;

import com.jasongj.proxy.cglibproxy.SubjectInterceptor;
import com.jasongj.subject.ConcreteSubject;
import com.jasongj.subject.ISubject;

import net.sf.cglib.proxy.Enhancer;
import net.sf.cglib.proxy.MethodInterceptor;

public class CgLibProxyClient {

  public static void main(String[] args) {
    MethodInterceptor methodInterceptor = new SubjectInterceptor();
    Enhancer enhancer = new Enhancer();
    enhancer.setSuperclass(ConcreteSubject.class);
    enhancer.setCallback(methodInterceptor);
    ISubject subject = (ISubject)enhancer.create();
    subject.action();
  }

}
```

# 性能测试
分别使用JDK动态代理创建代理对象1亿次，并分别执行代理对象方法10亿次，代码如下
```java
package com.jasongj.client;

import java.io.IOException;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Proxy;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.jasongj.proxy.cglibproxy.SubjectInterceptor;
import com.jasongj.proxy.jdkproxy.SubjectProxyHandler;
import com.jasongj.subject.ConcreteSubject;
import com.jasongj.subject.ISubject;

import net.sf.cglib.proxy.Enhancer;
import net.sf.cglib.proxy.MethodInterceptor;

public class DynamicProxyPerfClient {

  private static final Logger LOG = LoggerFactory.getLogger(DynamicProxyPerfClient.class);
  private static int creation = 100000000;
  private static int execution = 1000000000;

  public static void main(String[] args) throws IOException {
    testJDKDynamicCreation();
    testJDKDynamicExecution();
    testCglibCreation();
    testCglibExecution();
  }

  private static void testJDKDynamicCreation() {
    long start = System.currentTimeMillis();
    for (int i = 0; i < creation; i++) {
      InvocationHandler handler = new SubjectProxyHandler(ConcreteSubject.class);
      Proxy.newProxyInstance(DynamicProxyPerfClient.class.getClassLoader(),
          new Class[] {ISubject.class}, handler);
    }
    long stop = System.currentTimeMillis();
    LOG.info("JDK creation time : {} ms", stop - start);
  }

  private static void testJDKDynamicExecution() {
    long start = System.currentTimeMillis();
    InvocationHandler handler = new SubjectProxyHandler(ConcreteSubject.class);
    ISubject subject =
        (ISubject) Proxy.newProxyInstance(DynamicProxyPerfClient.class.getClassLoader(),
            new Class[] {ISubject.class}, handler);
    for (int i = 0; i < execution; i++) {
      subject.action();
    }
    long stop = System.currentTimeMillis();
    LOG.info("JDK execution time : {} ms", stop - start);
  }

  private static void testCglibCreation() {
    long start = System.currentTimeMillis();
    for (int i = 0; i < creation; i++) {
      MethodInterceptor methodInterceptor = new SubjectInterceptor();
      Enhancer enhancer = new Enhancer();
      enhancer.setSuperclass(ConcreteSubject.class);
      enhancer.setCallback(methodInterceptor);
      enhancer.create();
    }
    long stop = System.currentTimeMillis();
    LOG.info("cglib creation time : {} ms", stop - start);
  }

  private static void testCglibExecution() {
    MethodInterceptor methodInterceptor = new SubjectInterceptor();
    Enhancer enhancer = new Enhancer();
    enhancer.setSuperclass(ConcreteSubject.class);
    enhancer.setCallback(methodInterceptor);
    ISubject subject = (ISubject) enhancer.create();
    long start = System.currentTimeMillis();
    for (int i = 0; i < execution; i++) {
      subject.action();
    }
    long stop = System.currentTimeMillis();
    LOG.info("cglib execution time : {} ms", stop - start);
  }

}
```

结果如下
```
JDK creation time : 9924 ms
JDK execution time : 3472 ms
cglib creation time : 16108 ms
cglib execution time : 6309 ms
```

该性能测试表明，JDK动态代理创建代理对象速度是cglib的约1.6倍，并且JDK创建出的代理对象执行速度是cglib代理对象执行速度的约1.8倍

# JDK动态代理与cglib对比

 - 字节码创建方式：JDK动态代理通过JVM实现代理类字节码的创建，cglib通过ASM创建字节码
 - 对被代理对象的要求：JDK动态代理要求被代理对象实现接口，cglib要求被代理对象未被final修饰
 - 代理对象创建速度：JDK动态代理创建代理对象速度比cglib快
 - 代理对象执行速度：JDK动态代理代理对象执行速度比cglib快

本文所有示例代理均可从[作者Github](https://github.com/habren/JavaDesignPattern/tree/master/DynamicProxy)下载

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
