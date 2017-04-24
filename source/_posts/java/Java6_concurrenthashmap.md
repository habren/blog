---
title: Java进阶（六）从ConcurrentHashMap的演进看Java多线程
page_title: ConcurrentHashMap演进从Java7到Java8
date: 2016-05-06 10:42:26
permalink: java/concurrenthashmap
keywords:
  - java
  - Java
  - NIO
  - Reactor
  - I/O模型
  - 技术世界
  - 郭俊 Jason
  - 大数据架构
tags:
  - java
categories:
  - java
description: 本文介绍了Java中的四种I/O模型，同步阻塞，同步非阻塞，多路复用，异步阻塞。同时将NIO和BIO进行了对比，并详细分析了基于NIO的Reactor模式，包括经典单线程模型以及多线程模式和多Reactor模式。
---

>原创文章，转载请务必将下面这段话置于文章开头处（保留超链接）。
>本文转发自[**技术世界**](http://www.jasongj.com)，[原文链接](http://www.jasongj.com/java/concurrenthashmap/)　[http://www.jasongj.com/java/concurrenthashmap/](http://www.jasongj.com/java/concurrenthashmap/)


# 线程不安全的HashMap
众所周知，HashMap是非线程安全的。而HashMap的线程不安全主要体现在resize时的死循环及使用迭代器时的fast-fail上。

注：本章的代码均基于JDK 1.7.0_67
  
## HashMap工作原理
### HashMap数据结构
常用的底层数据结构主要有数组和链表。数组存储区间连续，占用内存较多，寻址容易，插入和删除困难。链表存储区间离散，占用内存较少，寻址困难，插入和删除容易。
  
HashMap要实现的是哈希表的效果，尽量实现O(1)级别的增删改查。它的具体实现则是同时使用了数组和链表，可以认为最外层是一个数组，数组的每个元素是一个链表的表头。


### HashMap寻址方式
对于新插入的数据或者待读取的数据，HashMap将Key的哈希值对数组长度取模，结果作为该Entry在数组中的index。在计算机中，取模的代价远高于位操作的代价，因此HashMap要求数组的长度必须为2的N次方。此时将Key的哈希值对2^N-1进行与运算，其效果即与取模等效。HashMap并不要求用户在指定HashMap容量时必须传入一个2的N次方的整数，而是会通过Integer.highestOneBit算出比指定整数小的最大2^N值，其实现方法如下。
```java
public static int highestOneBit(int i) {
  i |= (i >>  1);
  i |= (i >>  2);
  i |= (i >>  4);
  i |= (i >>  8);
  i |= (i >> 16);
  return i - (i >>> 1);
}
```
  
由于Key的哈希值的分布直接决定了所有数据在哈希表上的分布或者说决定了哈希冲突的可能性，因此为防止糟糕的Key的hashCode实现（例如低位都相同，只有高位不相同，与2^N-1取与后的结果都相同），JDK 1.7的HashMap通过如下方法使得最终的哈希值的二进制形式中的1尽量均匀分布从而尽可能小的减少哈希冲突。
```java
int h = hashSeed;
h ^= k.hashCode();
h ^= (h >>> 20) ^ (h >>> 12);
return h ^ (h >>> 7) ^ (h >>> 4);
```
  
## resize死循环
### transfer方法
当HashMap的size超过Capacity*loadFactor时，需要对HashMap进行扩容。具体方法是，创建一个新的，长度为原来Capacity两倍的数组，保证新的Capacity仍为2的N次方，从而保证上述寻址方式仍适用。同时需要通过如下transfer方法将原来的所有数据全部重新插入（rehash）到新的数组中。
```java
void transfer(Entry[] newTable, boolean rehash) {
  int newCapacity = newTable.length;
  for (Entry<K,V> e : table) {
    while(null != e) {
      Entry<K,V> next = e.next;
      if (rehash) {
        e.hash = null == e.key ? 0 : hash(e.key);
      }
      int i = indexFor(e.hash, newCapacity);
      e.next = newTable[i];
      newTable[i] = e;
      e = next;
    }
  }
}
```
  
该方法并不保证线程安全，而且在多线程并发调用时，可能出现死循环。其执行过程如下。从步骤2可见，转移时链表顺序反转。
1. 遍历原数组中的元素
2. 对链表上的每一个节点遍历：用next取得要转移那个元素的下一个，将e转移到新数组的头部，使用头插法插入节点
3. 循环2，直到链表节点全部转移
4. 循环1，直到所有索引数组全部转移
  
### 单线程rehash
单线程情况下，rehash无问题。下图演示了单线程条件下的rehash过程
![HashMap rehash single thread](//www.jasongj.com/img/java/concurrenthashmap/single_thread_rehash.png)
  
### 多线程并发下的rehash
这里假设有两个线程同时执行了put操作并引发了rehash，执行了transfer方法，并假设线程一进入transfer方法并执行完next = e.next后，因为线程调度所分配时间片用完而“暂停”，此时线程二完成了transfer方法的执行。此时状态如下。
  
![HashMap rehash multi thread step 1](//www.jasongj.com/img/java/concurrenthashmap/multi_thread_rehash_1.png)
  
接着线程1被唤醒，被继续执行每一轮循环的剩余部分
```java
e.next = newTable[1] = null
newTable[1] = e = key(5)
e = next = key(9)
```
结果如下图所示
![HashMap rehash multi thread step 2](//www.jasongj.com/img/java/concurrenthashmap/multi_thread_rehash_2.png)
  
接着执行下一轮循环，结果状态图如下所示
![HashMap rehash multi thread step 3](//www.jasongj.com/img/java/concurrenthashmap/multi_thread_rehash_3.png)

继续下一轮循环，结果状态图如下所示
![HashMap rehash multi thread step 4](//www.jasongj.com/img/java/concurrenthashmap/multi_thread_rehash_4.png)
  
此时循环链表形成，并且key(11)无法加入到线程1的新数组。在下一次访问该链表时会出现死循环。
  
## Fast-fail
### 产生原理
在使用迭代器的过程中如果HashMap被修改，那么`ConcurrentModificationException`将被抛出，就即是Fast-fail策略。
  
当HashMap的iterator()方法被调用时，会构造并返回一个新的EntryIterator对象，并将EntryIterator的expectedModCount设置为HashMap的modCount（该变量记录了HashMap被修改的次数）
```java
HashIterator() {
  expectedModCount = modCount;
  if (size > 0) { // advance to first entry
  Entry[] t = table;
  while (index < t.length && (next = t[index++]) == null)
    ;
  }
}
```
  
在通过该Iterator的next方法访问下一个Entry时，它会先检查自己的expectedModCount与HashMap的modCount是否相等，如果不相等，说明HashMap被修改，直接抛出`ConcurrentModificationException`。该Iterator的remove方法也会做类似的检查。该异常的抛出意在提醒用户及早意识到线程安全问题。

### 线程安全解决方案
单线程条件下，为避免出现`ConcurrentModificationException`，需要保证只通过HashMap本身或者只通过Iterator去修改数据，不能在Iterator使用结束之前使用HashMap本身的方法修改数据。因为通过Iterator删除数据，HashMap的modCount和Iterator的expectedModCount都会自增，不影响二者的相等性。如果是增加数据，只能通过HashMap本身的方法完成，此时如果要继续遍历数据，需要重新调用iterator()方法从而重新构造出一个新的Iterator，使得新Iterator的expectedModCount与更新后的HashMap的modCount相等。
  
多线程条件下，可使用`Collections.synchronizedMap`方法构造出一个同步Map，或者直接使用线程安全的ConcurrentHashMap
  
# Java 7基于分段锁的ConcurrentHashMap
## 数据结构
Java 7中的ConcurrentHashMap的底层数据结构仍然是数组和链表。与HashMap不同的是，ConcurrentHashMap最外层不是一个大的数组，而是一个Segment的数组。每个Segment包含一个与HashMap数据结构差不多的链表数组。整体数据结构如下图所示。
![JAVA 7 ConcurrentHashMap](//www.jasongj.com/img/java/concurrenthashmap/concurrenthashmap_java7.png)

  
## 寻址方式
在读写某个Key时，先取该Key的哈希值。并将哈希值的高N位对Segment个数取模从而得到该Key应该属于哪个Segment，接着如同操作HashMap一样操作这个Segment。为了保证不同的值均匀分布到不同的Segment，需要通过如下方法计算哈希值。
```java
private int hash(Object k) {
  int h = hashSeed;
  if ((0 != h) && (k instanceof String)) {
    return sun.misc.Hashing.stringHash32((String) k);
  }
  h ^= k.hashCode();
  h += (h <<  15) ^ 0xffffcd7d;
  h ^= (h >>> 10);
  h += (h <<   3);
  h ^= (h >>>  6);
  h += (h <<   2) + (h << 14);
  return h ^ (h >>> 16);
}
```

同样为了提高取模运算效率，通过如下计算，ssize即为大于concurrencyLevel的最小的2的N次方，同时segmentMask为2^N-1。这一点跟上文中计算数组长度的效果一致。对于某一个Key的哈希值，只需要向右移segmentShift位以取高sshift位，再与segmentMask取与操作即可得到它在Segment数组上的索引。
```java
int sshift = 0;
int ssize = 1;
while (ssize < concurrencyLevel) {
  ++sshift;
  ssize <<= 1;
}
this.segmentShift = 32 - sshift;
this.segmentMask = ssize - 1;
Segment<K,V>[] ss = (Segment<K,V>[])new Segment[ssize];
```

## 上锁方式
Segment继承自ReentrantLock，所以我们可以很方便的对每一个Segment上锁。
  
对于读操作，获取Key所在的Segment时，需要保证可见性(请参考[如何保证多线程条件下的可见性](http://www.jasongj.com/java/thread_safe/#Java如何保证可见性))。具体实现上可以使用volatile关键字，也可使用锁。但使用锁开销太大，而使用volatile时每次写操作都会让所有CPU内缓存无效，也有一定开销。ConcurrentHashMap使用如下方法保证可见性，取得最新的Segment。
```java
Segment<K,V> s = (Segment<K,V>)UNSAFE.getObjectVolatile(segments, u)
```
  
获取Segment中的HashEntry时也使用了类似方法
```java
HashEntry<K,V> e = (HashEntry<K,V>) UNSAFE.getObjectVolatile
  (tab, ((long)(((tab.length - 1) & h)) << TSHIFT) + TBASE)
```

对于写操作，并不要求同时获取所有Segment的锁，因为那样相当于锁住了整个Map。它会先获取该Key-Value对所在的Segment的锁，获取成功后就可以像操作一个普通的HashMap一样操作该Segment，并保证该Segment的安全性。
同时由于其它Segment的锁并未被获取，因此理论上可支持concurrencyLevel（等于Segment的个数）个线程安全的并发读写。
  
获取锁时，并不直接使用lock来获取，因为该方法获取锁失败时会挂起（参考[可重入锁](http://www.jasongj.com/java/multi_thread/#重入锁)）。事实上，它使用了自旋锁，如果tryLock获取锁失败，说明锁被其它线程占用，此时通过循环再次以tryLock的方式申请锁。如果在循环过程中该Key所对应的链表头被修改，则重置retry次数。如果retry次数超过一定值，则使用lock方法申请锁。
  
这里使用自旋锁是因为自旋锁的效率比较高，但是它消耗CPU资源比较多，因此在自旋次数超过阈值时切换为互斥锁。


# Java 8基于CAS的ConcurrentHashMap








