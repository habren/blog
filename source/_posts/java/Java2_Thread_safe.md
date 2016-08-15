---
title: Java进阶（二）当我们说线程安全时，到底在说什么
page_title: 什么是线程安全 怎么实现线程安全 volatile synchronized lock 锁 原子性 可见性 有序性
date: 2016-06-13 07:11:29
permalink: java/thread_safe
keywords:
  - java
  - Java
  - 注解
  - 原子性 可见性 有序性
  - volatile
  - synchronized
  - lock
  - 内存屏障
  - 锁
  - java 线程安全
  - java 同步
  - Jason's Blog
  - 郭俊 Jason
  - 大数据架构
tags:
  - java
categories:
  - java
description: 提到线程安全，可能大家的第一反应是要确保接口对共享变量的操作要具体原子性。实际上，在多线程编程中我们需要同时关注可见性、顺序性和原子性问题。本篇文章将从这三个问题出发，结合实例详解volatile如何保证可见性及一定程序上保证顺序性，同时例讲synchronized如何同时保证可见性和原子性，最后对比volatile和synchronized的适用场景。
---

　　原创文章，转载请务必将下面这段话置于文章开头处。
　　本文转发自[**Jason's Blog**](http://www.jasongj.com)，[原文链接](http://www.jasongj.com/java/thread_safe/)　[http://www.jasongj.com/java/thread_safe/](http://www.jasongj.com/java/thread_safe/)



# 多线程编程中的三个核心概念
## 原子性
这一点，跟数据库事务的原子性概念差不多，即一个操作（有可能包含有多个子操作）要么全部执行（生效），要么全部都不执行（都不生效）。

关于原子性，一个非常经典的例子就是银行转账问题：比如A和B同时向C转账10万元。如果转账操作不具有原子性，A在向C转账时，读取了C的余额为20万，然后加上转账的10万，计算出此时应该有30万，但还未来及将30万写回C的账户，此时B的转账请求过来了，B发现C的余额为20万，然后将其加10万并写回。然后A的转账操作技术——将30万写回C的余额。这种情况下C的最终余额为30万，而非预期的40万。


## 可见性
可见性是指，当多个线程并发访问共享变量时，一个线程对共享变量的修改，其它线程能够立即看到。可见性问题是好多人忽略或者理解错误的一点。

CPU从主内存中读数据的效率相对来说不高，现在主流的计算机中，都有几级缓存。每个线程读取共享变量时，都会将该变量加载进其对应CPU的高速缓存里，修改该变量后，CPU会立即更新该缓存，但并不一定会立即将其写回主内存（实际上写回主内存的时间不可预期）。此时其它线程（尤其是不在同一个CPU上执行的线程）访问该变量时，从主内存中读到的就是旧的数据，而非第一个线程更新后的数据。

这一点是操作系统或者说是硬件层面的机制，所以很多应用开发人员经常会忽略。


## 顺序性
顺序性指的是，程序执行的顺序按照代码的先后顺序执行。

以下面这段代码为例
```java
boolean started = false; // 语句1
long counter = 0L; // 语句2
counter = 1; // 语句3
started = true; // 语句4
```

从代码顺序上看，上面四条语句应该依次执行，但实际上JVM真正在执行这段代码时，并不保证它们一定完全按照此顺序执行。

处理器为了提高程序整体的执行效率，可能会对代码进行优化，其中的一项优化方式就是调整代码顺序，按照更高效的顺序执行代码。

讲到这里，有人要着急了——什么，CPU不按照我的代码顺序执行代码，那怎么保证得到我们想要的效果呢？实际上，大家大可放心，CPU虽然并不保证完全按照代码顺序执行，但它会保证程序最终的执行结果和代码顺序执行时的结果一致。

# Java如何解决多线程并发问题
## Java如何保证原子性
### 锁和同步
常用的保证Java操作原子性的工具是锁和同步方法（或者同步代码块）。使用锁，可以保证同一时间只有一个线程能拿到锁，也就保证了同一时间只有一个线程能执行申请锁和释放锁之间的代码。
```java
public void testLock () {
  lock.lock();
  try{
    int j = i;
    i = j + 1;
  } finally {
    lock.unlock();
  }
}
```

与锁类似的是同步方法或者同步代码块。使用非静态同步方法时，锁住的是当前实例；使用静态同步方法时，锁住的是该类的Class对象；使用静态代码块时，锁住的是`synchronized`关键字后面括号内的对象。下面是同步代码块示例
```java
public void testLock () {
  synchronized (anyObject){
    int j = i;
    i = j + 1;
  }
}
```

无论使用锁还是synchronized，本质都是一样，通过锁来实现资源的排它性，从而实际目标代码段同一时间只会被一个线程执行，进而保证了目标代码段的原子性。这是一种以牺牲性能为代价的方法。

### CAS（compare and swap）
基础类型变量自增（i++）是一种常被新手误以为是原子操作而实际不是的操作。Java中提供了对应的原子操作类来实现该操作，并保证原子性，其本质是利用了CPU级别的CAS指令。由于是CPU级别的指令，其开销比需要操作系统参与的锁的开销小。AtomicInteger使用方法如下。
```java
AtomicInteger atomicInteger = new AtomicInteger();
for(int b = 0; b < numThreads; b++) {
  new Thread(() -> {
    for(int a = 0; a < iteration; a++) {
      atomicInteger.incrementAndGet();
    }
  }).start();
}
```

## Java如何保证可见性
Java提供了`volatile`关键字来保证可见性。当使用volatile修饰某个变量时，它会保证对该变量的修改会立即被更新到内存中，并且将其它缓存中对该变量的缓存设置成无效，因此其它线程需要读取该值时必须从主内存中读取，从而得到最新的值。

## Java如何保证顺序性
上文讲过编译器和处理器对指令进行重新排序时，会保证重新排序后的执行结果和代码顺序执行的结果一致，所以重新排序过程并不会影响单线程程序的执行，却可能影响多线程程序并发执行的正确性。

Java中可通过`volatile`在一定程序上保证顺序性，另外还可以通过synchronized和锁来保证顺序性。


synchronized和锁保证顺序性的原理和保证原子性一样，都是通过保证同一时间只会有一个线程执行目标代码段来实现的。

除了从应用层面保证目标代码段执行的顺序性外，JVM还通过被称为happens-before原则隐式的保证顺序性。两个操作的执行顺序只要可以通过happens-before推导出来，则JVM会保证其顺序性，反之JVM对其顺序性不作任何保证，可对其进行任意必要的重新排序以获取高效率。

## happens-before原则（先行发生原则）
 - 传递规则：如果操作1在操作2前面，而操作2在操作3前面，则操作1肯定会在操作3前发生。该规则说明了happens-before原则具有传递性
 - 锁定规则：一个unlock操作肯定会在后面对同一个锁的lock操作前发生。这个很好理解，锁只有被释放了才会被再次获取
 - volatile变量规则：对一个被volatile修饰的写操作先发生于后面对该变量的读操作
 - 程序次序规则：一个线程内，按照代码顺序执行
 - 线程启动规则：Thread对象的start()方法先发生于此线程的其它动作
 - 线程终结原则：线程的终止检测后发生于线程中其它的所有操作
 - 线程中断规则： 对线程interrupt()方法的调用先发生于对该中断异常的获取
 - 对象终结规则：一个对象构造先于它的finalize发生


# volatile适用场景
volatile适用于不需要保证原子性，但却需要保证可见性的场景。一种典型的使用场景是用它修饰用于停止线程的状态标记。如下所示
```java
boolean isRunning = false;

public void start () {
  new Thread( () -> {
    while(isRunning) {
      someOperation();
    }
  }).start();
}

public void stop () {
  isRunning = false;
}
```

在这种实现方式下，即使其它线程通过调用stop()方法将isRunning设置为false，循环也不一定会立即结束。可以通过volatile关键字，保证while循环及时得到isRunning最新的状态从而及时停止循环，结束线程。


# 线程安全十万个为什么
问：平时项目中使用锁和synchronized比较多，而很少使用volatile，难道就没有保证可见性？
答：锁和synchronized即可以保证原子性，也可以保证可见性。都是通过保证同一时间只有一个线程执行目标代码段来实现的。

<p id="synchronized_visibility">
问：锁和synchronized为何能保证可见性？
答：根据<a href="http://docs.oracle.com/javase/7/docs/api/java/util/concurrent/package-summary.html#MemoryVisibility" title="JDK 7的Java doc" target="_blank" rel="external nofollow">JDK 7的Java doc</a>中对`concurrent`包的说明，一个线程的写结果保证对另外线程的读操作可见，只要该写操作可以由`happen-before`原则推断出在读操作之前发生。
</p>
>The results of a write by one thread are guaranteed to be **visible** to a read by another thread only if the write operation happens-before the read operation. The synchronized and volatile constructs, as well as the Thread.start() and Thread.join() methods, can form happens-before relationships.



问：既然锁和synchronized即可保证原子性也可保证可见性，为何还需要volatile？
答：synchronized和锁需要通过操作系统来仲裁谁获得锁，开销比较高，而volatile开销小很多。因此在只需要保证可见性的条件下，使用volatile的性能要比使用锁和synchronized高得多。

问：既然锁和synchronized可以保证原子性，为什么还需要AtomicInteger这种的类来保证原子操作？
答：锁和synchronized需要通过操作系统来仲裁谁获得锁，开销比较高，而AtomicInteger是通过CPU级的CAS操作来保证原子性，开销比较小。所以使用AtomicInteger的目的还是为了提高性能。

问：还有没有别的办法保证线程安全
答：有。尽可能避免引起非线程安全的条件——共享变量。如果能从设计上避免共享变量的使用，即可避免非线程安全的发生，也就无须通过锁或者synchronized以及volatile解决原子性、可见性和顺序性的问题。

问：synchronized即可修饰非静态方式，也可修饰静态方法，还可修饰代码块，有何区别
答：synchronized修饰非静态同步方法时，锁住的是当前实例；synchronized修饰静态同步方法时，锁住的是该类的Class对象；synchronized修饰静态代码块时，锁住的是`synchronized`关键字后面括号内的对象。


# Java进阶系列
 - [Java进阶（一）Annotation（注解）](//www.jasongj.com/2016/01/17/Java1_注解Annotation/)
 - [Java进阶（二）当我们说线程安全时，到底在说什么](//www.jasongj.com/java/thread_safe)
 - [Java进阶（三）多线程开发关键技术](//www.jasongj.com/java/multi_thread)
 - [Java进阶（四）线程间通信方式对比](//www.jasongj.com/java/thread_communication)