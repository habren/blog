---
title: Java进阶（三）多线程开发关键技术
page_title: Java多线程 sleep wait synchronized 锁 await signal 信号量 Semaphore
date: 2016-06-20 06:55:29
permalink: java/multi_thread
keywords:
  - java
  - Java
  - sleep wait
  - synchronized 锁
  - await signal signalAll
  - 信号量 Semaphore
  - java 多线程
  - Jason's Blog
  - 郭俊 Jason
  - 大数据架构
tags:
  - java
categories:
  - java
description: 本文将介绍Java多线程开发必不可少的锁和同步机制，同时介绍sleep和wait等常用的暂停线程执行的方法，并详述synchronized的几种使用方式，以及Java中的重入锁（ReentrantLock）和读写锁（ReadWriteLock），之后结合实例分析了重入锁条件变量（Condition）的使用技巧，最后介绍了信号量（Semaphore）的适用场景和使用技巧。
---

>原创文章，转载请务必将下面这段话置于文章开头处（保留超链接）。
>本文转发自[**Jason's Blog**](http://www.jasongj.com)，[原文链接](http://www.jasongj.com/java/multi_thread/)　[http://www.jasongj.com/java/multi_thread/](http://www.jasongj.com/java/multi_thread/)


# sleep和wait到底什么区别
其实这个问题应该这么问——sleep和wait有什么相同点。因为这两个方法除了都能让当前线程暂停执行完，几乎没有其它相同点。

wait方法是Object类的方法，这意味着所有的Java类都可以调用该方法。sleep方法是Thread类的静态方法。

wait是在当前线程持有wait对象锁的情况下，暂时放弃锁，并让出CPU资源，并积极等待其它线程调用同一对象的notify或者notifyAll方法。注意，即使只有一个线程在等待，并且有其它线程调用了notify或者notifyAll方法，等待的线程只是被激活，但是它必须得再次获得锁才能继续往下执行。换言之，即使notify被调用，但只要锁没有被释放，原等待线程因为未获得锁仍然无法继续执行。测试代码如下所示
```java
import java.util.Date;

public class Wait {

  public static void main(String[] args) {
    Thread thread1 = new Thread(() -> {
      synchronized (Wait.class) {
        try {
          System.out.println(new Date() + " Thread1 is running");
          Wait.class.wait();
          System.out.println(new Date() + " Thread1 ended");
        } catch (Exception ex) {
          ex.printStackTrace();
        }
      }
    });
    thread1.start();
    
    Thread thread2 = new Thread(() -> {
      synchronized (Wait.class) {
        try {
          System.out.println(new Date() + " Thread2 is running");
          Wait.class.notify();
          // Don't use sleep method to avoid confusing
          for(long i = 0; i < 200000; i++) {
            for(long j = 0; j < 100000; j++) {}
          }
          System.out.println(new Date() + " Thread2 release lock");
        } catch (Exception ex) {
          ex.printStackTrace();
        }
      }
      
      for(long i = 0; i < 200000; i++) {
        for(long j = 0; j < 100000; j++) {}
      }
      System.out.println(new Date() + " Thread2 ended");
    });
    
    // Don't use sleep method to avoid confusing
    for(long i = 0; i < 200000; i++) {
      for(long j = 0; j < 100000; j++) {}
    }
    thread2.start();
  }
}
```

执行结果如下
```
Tue Jun 14 22:51:11 CST 2016 Thread1 is running
Tue Jun 14 22:51:23 CST 2016 Thread2 is running
Tue Jun 14 22:51:36 CST 2016 Thread2 release lock
Tue Jun 14 22:51:36 CST 2016 Thread1 ended
Tue Jun 14 22:51:49 CST 2016 Thread2 ended
```

从运行结果可以看出
 - thread1执行wait后，暂停执行
 - thread2执行notify后，thread1并没有继续执行，因为此时thread2尚未释放锁，thread1因为得不到锁而不能继续执行
 - thread2执行完synchronized语句块后释放锁，thread1得到通知并获得锁，进而继续执行

**注意**：wait方法需要释放锁，前提条件是它已经持有锁。所以wait和notify（或者notifyAll）方法都必须被包裹在synchronized语句块中，并且synchronized后锁的对象应该与调用wait方法的对象一样。否则抛出**IllegalMonitorStateException**

sleep方法告诉操作系统至少指定时间内不需为线程调度器为该线程分配执行时间片，并不释放锁（如果当前已经持有锁）。实际上，调用sleep方法时并不要求持有任何锁。

```java
package com.test.thread;

import java.util.Date;

public class Sleep {

  public static void main(String[] args) {
    Thread thread1 = new Thread(() -> {
      synchronized (Sleep.class) {
        try {
          System.out.println(new Date() + " Thread1 is running");
          Thread.sleep(2000);
          System.out.println(new Date() + " Thread1 ended");
        } catch (Exception ex) {
          ex.printStackTrace();
        }
      }
    });
    thread1.start();
    
    Thread thread2 = new Thread(() -> {
      synchronized (Sleep.class) {
        try {
          System.out.println(new Date() + " Thread2 is running");
          Thread.sleep(2000);
          System.out.println(new Date() + " Thread2 ended");
        } catch (Exception ex) {
          ex.printStackTrace();
        }
      }
      
      for(long i = 0; i < 200000; i++) {
        for(long j = 0; j < 100000; j++) {}
      }
    });
    
    // Don't use sleep method to avoid confusing
    for(long i = 0; i < 200000; i++) {
      for(long j = 0; j < 100000; j++) {}
    }
    thread2.start();
  }
}
```

执行结果如下
```
Thu Jun 16 19:46:06 CST 2016 Thread1 is running
Thu Jun 16 19:46:08 CST 2016 Thread1 ended
Thu Jun 16 19:46:13 CST 2016 Thread2 is running
Thu Jun 16 19:46:15 CST 2016 Thread2 ended
```

由于thread 1和thread 2的run方法实现都在同步块中，无论哪个线程先拿到锁，执行sleep时并不释放锁，因此其它线程无法执行。直到前面的线程sleep结束并退出同步块（释放锁），另一个线程才得到锁并执行。

注意：sleep方法并不需要持有任何形式的锁，也就不需要包裹在synchronized中。


# synchronized几种用法
每个Java对象都可以用做一个实现同步的互斥锁，这些锁被称为内置锁。线程进入同步代码块或方法时自动获得内置锁，退出同步代码块或方法时自动释放该内置锁。进入同步代码块或者同步方法是获得内置锁的唯一途径。

## 实例同步方法
synchronized用于修饰实例方法（非静态方法）时，执行该方法需要获得的是该类实例对象的内置锁（同一个类的不同实例拥有不同的内置锁）。如果多个实例方法都被synchronized修饰，则当多个线程调用同一实例的不同同步方法（或者同一方法）时，需要竞争锁。但当调用的是不同实例的方法时，并不需要竞争锁。

## 静态同步方法
synchronized用于修饰静态方法时，执行该方法需要获得的是该类的class对象的内置锁（一个类只有唯一一个class对象）。调用同一个类的不同静态同步方法时会产生锁竞争。

## 同步代码块
synchronized用于修饰代码块时，进入同步代码块需要获得synchronized关键字后面括号内的对象（可以是实例对象也可以是class对象）的内置锁。

## synchronized使用总结
锁的使用是为了操作临界资源的正确性，而往往一个方法中并非所有的代码都操作临界资源。换句话说，方法中的代码往往并不都需要同步。此时建议不使用同步方法，而使用同步代码块，只对操作临界资源的代码，也即需要同步的代码加锁。这样做的好处是，当一个线程在执行同步代码块时，其它线程仍然可以执行该方法内同步代码块以外的部分，充分发挥多线程并发的优势，从而相较于同步整个方法而言提升性能。

释放Java内置锁的唯一方式是synchronized方法或者代码块执行结束。若某一线程在synchronized方法或代码块内发生死锁，则对应的内置锁无法释放，其它线程也无法获取该内置锁（即进入跟该内置锁相关的synchronized方法或者代码块）。


# Java中的锁
## 重入锁
Java中的重入锁（即ReentrantLock）与Java内置锁一样，是一种排它锁。使用synchronized的地方一定可以用ReentrantLock代替。

重入锁需要显示请求获取锁，并显示释放锁。为了避免获得锁后，没有释放锁，而造成其它线程无法获得锁而造成死锁，一般建议将释放锁操作放在finally块里，如下所示。
```java
try{
  renentrantLock.lock();
  // 用户操作
} finally {
  renentrantLock.unlock();
}
```

如果重入锁已经被其它线程持有，则当前线程的lock操作会被阻塞。除了***lock()***方法之外，重入锁（或者说锁接口）还提供了其它获取锁的方法以实现不同的效果。
 - ***lockInterruptibly()*** 该方法尝试获取锁，若获取成功立即返回；若获取不成功则阻塞等待。与lock方法不同的是，在阻塞期间，如果当前线程被打断（interrupt）则该方法抛出*InterruptedException*。该方法提供了一种解除死锁的途径。
 - ***tryLock()*** 该方法试图获取锁，若该锁当前可用，则该方法立即获得锁并立即返回true；若锁当前不可用，则立即返回false。该方法不会阻塞，并提供给用户对于成功获利锁与获取锁失败进行不同操作的可能性。
 - ***tryLock(long time, TimeUnit unit)*** 该方法试图获得锁，若该锁当前可用，则立即获得锁并立即返回true。若锁当前不可用，则等待相应的时间（由该方法的两个参数决定）：1）若该时间内锁可用，则获得锁，并返回true；2）若等待期间当前线程被打断，则抛出*InterruptedException*；3）若等待时间结束仍未获得锁，则返回false。

重入锁可定义为公平锁或非公平锁，默认实现为非公平锁。
 - 公平锁是指多个线程获取锁被阻塞的情况下，锁变为可用时，最新申请锁的线程获得锁。可通过在重入锁（RenentrantLock）的构造方法中传入true构建公平锁，如*Lock lock = new RenentrantLock(true)*
 - 非公平锁是指多个线程等待锁的情况下，锁变为可用状态时，哪个线程获得锁是随机的。synchonized相当于非公平锁。可通过在重入锁的构造方法中传入false或者使用无参构造方法构建非公平锁。


## 读写锁
如上文《[Java进阶（二）当我们说线程安全时，到底在说什么](//www.jasongj.com/java/thread_safe)》所述，锁可以保证原子性和可见性。而原子性更多是针对写操作而言。对于读多写少的场景，一个读操作无须阻塞其它读操作，只需要保证读和写或者写与写不同时发生即可。此时，如果使用重入锁（即排它锁），对性能影响较大。Java中的读写锁（ReadWriteLock）就是为这种读多写少的场景而创造的。

实际上，ReadWriteLock接口并非继承自Lock接口，ReentrantReadWriteLock也只实现了ReadWriteLock接口而未实现Lock接口。ReadLock和WriteLock，是ReentrantReadWriteLock类的静态内部类，它们实现了Lock接口。

一个**ReentrantReadWriteLock**实例包含一个**ReentrantReadWriteLock.ReadLock**实例和一个**ReentrantReadWriteLock.WriteLock**实例。通过*readLock()*和*writeLock()*方法可分别获得读锁实例和写锁实例，并通过Lock接口提供的获取锁方法获得对应的锁。

读写锁的锁定规则如下：
 - 获得读锁后，其它线程可获得读锁而不能获取写锁
 - 获得写锁后，其它线程既不能获得读锁也不能获得写锁

```java
package com.test.thread;

import java.util.Date;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

public class ReadWriteLockDemo {

  public static void main(String[] args) {
    ReadWriteLock readWriteLock = new ReentrantReadWriteLock();

    new Thread(() -> {
      readWriteLock.readLock().lock();
      try {
        System.out.println(new Date() + "\tThread 1 started with read lock");
        try {
          Thread.sleep(2000);
        } catch (Exception ex) {
        }
        System.out.println(new Date() + "\tThread 1 ended");
      } finally {
        readWriteLock.readLock().unlock();
      }
    }).start();

    new Thread(() -> {
      readWriteLock.readLock().lock();
      try {
        System.out.println(new Date() + "\tThread 2 started with read lock");
        try {
          Thread.sleep(2000);
        } catch (Exception ex) {
        }
        System.out.println(new Date() + "\tThread 2 ended");
      } finally {
        readWriteLock.readLock().unlock();
      }
    }).start();

    new Thread(() -> {
      Lock lock = readWriteLock.writeLock();
      lock.lock();
      try {
        System.out.println(new Date() + "\tThread 3 started with write lock");
        try {
          Thread.sleep(2000);
        } catch (Exception ex) {
          ex.printStackTrace();
        }
        System.out.println(new Date() + "\tThread 3 ended");
      } finally {
        lock.unlock();
      }
    }).start();
  }
}
```

执行结果如下
```
Sat Jun 18 21:33:46 CST 2016  Thread 1 started with read lock
Sat Jun 18 21:33:46 CST 2016  Thread 2 started with read lock
Sat Jun 18 21:33:48 CST 2016  Thread 2 ended
Sat Jun 18 21:33:48 CST 2016  Thread 1 ended
Sat Jun 18 21:33:48 CST 2016  Thread 3 started with write lock
Sat Jun 18 21:33:50 CST 2016  Thread 3 ended
```

从上面的执行结果可见，thread 1和thread 2都只需获得读锁，因此它们可以并行执行。而thread 3因为需要获取写锁，必须等到thread 1和thread 2释放锁后才能获得锁。


# 条件锁
条件锁只是一个帮助用户理解的概念，实际上并没有条件锁这种锁。对于每个重入锁，都可以通过*newCondition()*方法绑定若干个条件对象。

条件对象提供以下方法以实现不同的等待语义
 - ***await()*** 调用该方法的前提是，当前线程已经成功获得与该条件对象绑定的重入锁，否则调用该方法时会抛出**IllegalMonitorStateException**。调用该方法外，当前线程会释放当前已经获得的锁（这一点与上文讲述的Java内置锁的wait方法一致），并且等待其它线程调用该条件对象的*signal()*或者*signalAll()*方法（这一点与Java内置锁wait后等待*notify()*或*notifyAll()*很像）。或者在等待期间，当前线程被打断，则*wait()*方法会抛出**InterruptedException**并清除当前线程的打断状态。
 - ***await(long time, TimeUnit unit)*** 适用条件和行为与*await()*基本一致，唯一不同点在于，指定时间之内没有收到*signal()*或*signalALL()*信号或者线程中断时该方法会返回false;其它情况返回true。
 - ***awaitNanos(long nanosTimeout)*** 调用该方法的前提是，当前线程已经成功获得与该条件对象绑定的重入锁，否则调用该方法时会抛出**IllegalMonitorStateException**。**nanosTimeout**指定该方法等待信号的的最大时间（单位为纳秒）。若指定时间内收到*signal()*或*signalALL()*则返回**nanosTimeout**减去已经等待的时间；若指定时间内有其它线程中断该线程，则抛出**InterruptedException**并清除当前线程的打断状态；若指定时间内未收到通知，则返回0或负数。
 - ***awaitUninterruptibly()*** 调用该方法的前提是，当前线程已经成功获得与该条件对象绑定的重入锁，否则调用该方法时会抛出**IllegalMonitorStateException**。调用该方法后，结束等待的唯一方法是其它线程调用该条件对象的*signal()*或*signalALL()*方法。等待过程中如果当前线程被中断，该方法仍然会继续等待，同时保留该线程的中断状态。
 - ***awaitUntil(Date deadline)*** 适用条件与行为与***awaitNanos(long nanosTimeout)***完全一样，唯一不同点在于它不是等待指定时间，而是等待由参数指定的某一时刻。

调用条件等待的注意事项
 - 调用上述任意条件等待方法的前提都是当前线程已经获得与该条件对象对应的重入锁。
 - 调用条件等待后，当前线程让出CPU资源。
 - 上述等待方法结束后，方法返回的前提是它能重新获得与该条件对象对应的重入锁。如果无法获得锁，仍然会继续等待。这也是***awaitNanos(long nanosTimeout)***可能会返回负值的原因。
 - 一旦条件等待方法返回，则当前线程肯定已经获得了对应的重入锁。
 - 重入锁可以创建若干个条件对象，*signal()*和*signalAll()*方法只能唤醒相同条件对象的等待。
 - 一个重入锁上可以生成多个条件变量，不同线程可以等待不同的条件，从而实现更加细粒度的的线程间通信。

*signal()*与*signalAll()*
 - ***signal()*** 若有一个或若干个线程在等待该条件变量，则该方法会唤醒其中的一个（具体哪一个，无法预测）。调用该方法的前提是当前线程持有该条件变量对应的锁，否则抛出**IllegalMonitorStateException**。
 - ***signalALL()*** 若有一个或若干个线程在等待该条件变量，则该方法会唤醒所有等待。调用该方法的前提是当前线程持有该条件变量对应的锁，否则抛出**IllegalMonitorStateException**。


```java
package com.test.thread;

import java.util.Date;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class ConditionTest {

  public static void main(String[] args) throws InterruptedException {
    Lock lock = new ReentrantLock();
    Condition condition = lock.newCondition();
    new Thread(() -> {
      lock.lock();
      try {
        System.out.println(new Date() + "\tThread 1 is waiting");
        try {
          long waitTime = condition.awaitNanos(TimeUnit.SECONDS.toNanos(2));
          System.out.println(new Date() + "\tThread 1 remaining time " + waitTime);
        } catch (Exception ex) {
          ex.printStackTrace();
        }
        System.out.println(new Date() + "\tThread 1 is waken up");
      } finally {
        lock.unlock();
      }
    }).start();
    
    new Thread(() -> {
      lock.lock();
      try{
        System.out.println(new Date() + "\tThread 2 is running");
        try {
          Thread.sleep(4000);
        } catch (Exception ex) {
          ex.printStackTrace();
        }
        condition.signal();
        System.out.println(new Date() + "\tThread 2 ended");
      } finally {
        lock.unlock();
      }
    }).start();
  }
}
```

执行结果如下
```
Sun Jun 19 15:59:09 CST 2016  Thread 1 is waiting
Sun Jun 19 15:59:09 CST 2016  Thread 2 is running
Sun Jun 19 15:59:13 CST 2016  Thread 2 ended
Sun Jun 19 15:59:13 CST 2016  Thread 1 remaining time -2003467560
Sun Jun 19 15:59:13 CST 2016  Thread 1 is waken up
```

从执行结果可以看出，虽然thread 2一开始就调用了*signal()*方法去唤醒thread 1，但是因为thread 2在4秒钟后才释放锁，也即thread 1在4秒后才获得锁，所以thread 1的await方法在4秒钟后才返回，并且返回负值。

# 信号量Semaphore
信号量维护一个许可集，可通过*acquire()*获取许可（若无可用许可则阻塞），通过*release()*释放许可，从而可能唤醒一个阻塞等待许可的线程。

与互斥锁类似，信号量限制了同一时间访问临界资源的线程的个数，并且信号量也分公平信号量与非公平信号量。而不同的是，互斥锁保证同一时间只会有一个线程访问临界资源，而信号量可以允许同一时间多个线程访问特定资源。所以信号量并不能保证原子性。

信号量的一个典型使用场景是限制系统访问量。每个请求进来后，处理之前都通过acquire获取许可，若获取许可成功则处理该请求，若获取失败则等待处理或者直接不处理该请求。

信号量的使用方法
 - ***acquire(int permits)*** 申请**permits**（必须为非负数）个许可，若获取成功，则该方法返回并且当前可用许可数减permits；若当前可用许可数少于permits指定的个数，则继续等待可用许可数大于等于permits；若等待过程中当前线程被中断，则抛出**InterruptedException**。
 - ***acquire()*** 等价于*acquire(1)*。
 - ***acquireUninterruptibly(int permits)*** 申请**permits**（必须为非负数）个许可，若获取成功，则该方法返回并且当前可用许可数减permits；若当前许可数少于permits，则继续等待可用许可数大于等于permits；若等待过程中当前线程被中断，继续等待可用许可数大于等于permits，并且获取成功后设置线程中断状态。
 - ***acquireUninterruptibly()*** 等价于*acquireUninterruptibly(1)*。
 - ***drainPermits()*** 获取所有可用许可，并返回获取到的许可个数，该方法不阻塞。
 - ***tryAcquire(int permits)*** 尝试获取permits个可用许可，如果当前许可个数大于等于permits，则返回true并且可用许可数减permits；否则返回false并且可用许可数不变。
 - ***tryAcquire()*** 等价于*tryAcquire(1)*。
 - ***tryAcquire(int permits, long timeout, TimeUnit unit)*** 尝试获取permits（必须为非负数）个许可，若在指定时间内获取成功则返回true并且可用许可数减permits；若指定时间内当前线程被中断，则抛出**InterruptedException**；若指定时间内可用许可数均小于permits，则返回false。
 - ***tryAcquire(long timeout, TimeUnit unit)*** 等价于tryAcquire(1, long timeout, TimeUnit unit)*
 - ***release(int permits)*** 释放permits个许可，该方法不阻塞并且某线程调用release方法前并不需要先调用acquire方法。
 - ***release()*** 等价于*release(1)*。

注意：与wait/notify和await/signal不同，acquire/release完全与锁无关，因此acquire等待过程中，可用许可满足要求时acquire可立即返回，而不用像锁的wait和条件变量的await那样重新获取锁才能返回。或者可以理解成，只要可用许可满足需求，就已经获得了锁。


# Java进阶系列
 - [Java进阶（一）Annotation（注解）](//www.jasongj.com/2016/01/17/Java1_注解Annotation/)
 - [Java进阶（二）当我们说线程安全时，到底在说什么](//www.jasongj.com/java/thread_safe)
 - [Java进阶（三）多线程开发关键技术](//www.jasongj.com/java/multi_thread)
 - [Java进阶（四）线程间通信方式对比](//www.jasongj.com/java/thread_communication)
