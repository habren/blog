---
title: 分布式事务（一）两阶段提交及JTA
page_title: 两阶段提交 two-phase commit 分布式事务 JTA
date: 2016-08-01 06:55:29
permalink: big_data/two_phase_commit
keywords:
  - 分布式事务
  - 两阶段提交
  - two-phase commit
  - Jason's Blog
  - 郭俊 Jason
  - 大数据架构
tags:
  - big data
  - 分布式事务
  - 分布式
categories:
  - big data
  - 分布式
description: 分布式事务与本地事务一样，包含原子性（Atomicity）、一致性（Consistency）、隔离性（Isolation）和持久性（Durability）。两阶段提交是保证分布式事务中原子性的重要方法。本文重点介绍了两阶段提交的原理，PostgreSQL中两阶段提交接口，以及Java中两阶段提交接口规范JTA的使用方式。
---

　　原创文章，转载请务必将下面这段话置于文章开头处。
　　本文转发自[**Jason's Blog**](http://www.jasongj.com)，[原文链接](http://www.jasongj.com/big_data/two_phase_commit/)　[http://www.jasongj.com/big_data/two_phase_commit/](http://www.jasongj.com/big_data/two_phase_commit/)


# 分布式事务
## 分布式事务简介
分布式事务是指会涉及到操作多个数据库（或者提供事务语义的系统，如JMS）的事务。其实就是将对同一数据库事务的概念扩大到了对多个数据库的事务。目的是为了保证分布式系统中事务操作的原子性。分布式事务处理的关键是必须有一种方法可以知道事务在任何地方所做的所有动作，提交或回滚事务的决定必须产生统一的结果（全部提交或全部回滚）。


## 分布式事务实现机制
如同作者在《[SQL优化（六） MVCC PostgreSQL实现事务和多版本并发控制的精华](//www.jasongj.com/sql/mvcc/)》一文中所讲，事务包含原子性（Atomicity）、一致性（Consistency）、隔离性（Isolation）和持久性（Durability）。

PostgreSQL针对ACID的实现技术如下表所示。

| ACID | 实现技术 |
|---------------------------|
| 原子性（Atomicity） | MVCC |
| 一致性（Consistency） | 约束（主键、外键等） |
| 隔离性 | MVCC |
| 持久性 | WAL |

分布式事务的实现技术如下表所示。（以PostgreSQL作为事务参与方为例）

| 分布式ACID | 实现技术 |
|---------------------------|
| **原子性（Atomicity）** | **MVCC + 两阶段提交** |
| 一致性（Consistency） | 约束（主键、外键等） |
| 隔离性 | MVCC |
| 持久性 | WAL |

从上表可以看到，一致性、隔离性和持久性靠的是各分布式事务参与方自己原有的机制，而两阶段提交主要保证了分布式事务的原子性。

# 两阶段提交
## 分布式事务如何保证原子性
在分布式系统中，各个节点（或者事务参与方）之间在物理上相互独立，通过网络进行协调。每个独立的节点（或组件）由于存在事务机制，可以保证其数据操作的ACID特性。但是，各节点之间由于相互独立，无法确切地知道其经节点中的事务执行情况，所以多节点之间很难保证ACID，尤其是原子性。

如果要实现分布式系统的原子性，则须保证所有节点的数据写操作，要不全部都执行（生效），要么全部都不执行（生效）。但是，一个节点在执行本地事务的时候无法知道其它机器的本地事务的执行结果，所以它就不知道本次事务到底应该commit还是 roolback。常规的解决办法是引入一个“协调者”的组件来统一调度所有分布式节点的执行。

## XA规范
XA是由X/Open组织提出的分布式事务的规范。XA规范主要定义了（全局）事务管理器（Transaction Manager）和（局部）资源管理器（Resource Manager）之间的接口。XA接口是双向的系统接口，在事务管理器（Transaction Manager）以及一个或多个资源管理器（Resource Manager）之间形成通信桥梁。XA引入的事务管理器充当上文所述全局事务中的“协调者”角色。事务管理器控制着全局事务，管理事务生命周期，并协调资源。资源管理器负责控制和管理实际资源（如数据库或JMS队列）。目前，Oracle、Informix、DB2、Sybase和PostgreSQL等各主流数据库都提供了对XA的支持。

XA规范中，事务管理器主要通过以下的接口对资源管理器进行管理
 - xa_open，xa_close：建立和关闭与资源管理器的连接。
 - xa_start，xa_end：开始和结束一个本地事务。
 - xa_prepare，xa_commit，xa_rollback：预提交、提交和回滚一个本地事务。
 - xa_recover：回滚一个已进行预提交的事务。


## 两阶段提交原理
二阶段提交的算法思路可以概括为：协调者询问参与者是否准备好了提交，并根据所有参与者的反馈情况决定向所有参与者发送commit或者rollback指令（协调者向所有参与者发送相同的指令）。

所谓的两个阶段是指
 - ``准备阶段`` 又称投票阶段。在这一阶段，协调者询问所有参与者是否准备好提交，参与者如果已经准备好提交则回复`Prepared`，否则回复`Non-Prepared`。
 - ``提交阶段`` 又称执行阶段。协调者如果在上一阶段收到所有参与者回复的`Prepared`，则在此阶段向所有参与者发送`commit`指令，所有参与者立即执行`commit`操作；否则协调者向所有参与者发送`rollback`指令，参与者立即执行`rollback`操作。

两阶段提交中，协调者和参与方的交互过程如下图所示。
![Two-phase commit](//www.jasongj.com/img/bigdata/two_phase_commit.png)

## 两阶段提交前提条件
 - 网络通信是可信的。虽然网络并不可靠，但两阶段提交的主要目标并不是解决诸如拜占庭问题的网络问题。同时两阶段提交的主要网络通信危险期（In-doubt Time）在事务提交阶段，而该阶段非常短。
 - 所有crash的节点最终都会恢复，不会一直处于crash状态。
 - 每个分布式事务参与方都有WAL日志，并且该日志存于稳定的存储上。
 - 各节点上的本地事务状态即使碰到机器crash都可从WAL日志上恢复。

## 两阶段提交容错方式
两阶段提交中的异常主要分为如下三种情况
1. 协调者正常，参与方crash
2. 协调者crash，参与者正常
3. 协调者和参与方都crash

对于第一种情况，若参与方在准备阶段crash，则协调者收不到`Prepared`回复，协调方不会发送`commit`命令，事务不会真正提交。若参与方在提交阶段提交，当它恢复后可以通过从其它参与方或者协调方获取事务是否应该提交，并作出相应的响应。

第二种情况，可以通过选出新的协调者解决。

第三种情况，是两阶段提交无法完美解决的情况。尤其是当协调者发送出`commit`命令后，唯一收到`commit`命令的参与者也crash，此时其它参与方不能从协调者和已经crash的参与者那儿了解事务提交状态。但如同上一节[两阶段提交前提条件](#u4E24_u9636_u6BB5_u63D0_u4EA4_u5047_u8BBE_u6761_u4EF6)所述，两阶段提交的前提条件之一是所有crash的节点最终都会恢复，所以当收到`commit`的参与方恢复后，其它节点可从它那里获取事务状态并作出相应操作。


# JTA
## JTA介绍
作为java平台上事务规范JTA（Java Transaction API）也定义了对XA事务的支持，实际上，JTA是基于XA架构上建模的。在JTA 中，事务管理器抽象为`javax.transaction.TransactionManager`接口，并通过底层事务服务（即Java Transaction Service）实现。像很多其他的Java规范一样，JTA仅仅定义了接口，具体的实现则是由供应商(如J2EE厂商)负责提供，目前JTA的实现主要有以下几种：
 - J2EE容器所提供的JTA实现(如JBoss)。
 - 独立的JTA实现：如JOTM（Java Open Transaction Manager），Atomikos。这些实现可以应用在那些不使用J2EE应用服务器的环境里用以提供分布事事务保证。

## PostgreSQL两阶段提交接口
 - `PREPARE TRANSACTION transaction_id` PREPARE TRANSACTION 为当前事务的两阶段提交做准备。 在命令之后，事务就不再和当前会话关联了；它的状态完全保存在磁盘上， 它提交成功有非常高的可能性，即使是在请求提交之前数据库发生了崩溃也如此。这条命令必须在一个用BEGIN显式开始的事务块里面使用。
 - `COMMIT PREPARED transaction_id` 提交已进入准备阶段的ID为`transaction_id`的事务
 - `ROLLBACK PREPARED transaction_id` 回滚已进入准备阶段的ID为`transaction_id`的事务

典型的使用方式如下
```sql
postgres=> BEGIN;
BEGIN
postgres=> CREATE TABLE demo(a TEXT, b INTEGER);    
CREATE TABLE
postgres=> PREPARE TRANSACTION 'the first prepared transaction';
PREPARE TRANSACTION
postgres=> SELECT * FROM pg_prepared_xacts;
 transaction |              gid               |           prepared            | owner | database 
-------------+--------------------------------+-------------------------------+-------+----------
       23970 | the first prepared transaction | 2016-08-01 20:44:55.816267+08 | casp  | postgres
(1 row)
```

从上面代码可看出，使用`PREPARE TRANSACTION transaction_id`语句后，PostgreSQL会在`pg_catalog.pg_prepared_xact`表中将该事务的`transaction_id`记于gid字段中，并将该事务的本地事务ID，即23970，存于`transaction`字段中，同时会记下该事务的创建时间及创建用户和数据库名。


继续执行如下命令
```sql
postgres=> \q
SELECT * FROM pg_prepared_xacts;
 transaction |              gid               |           prepared            | owner | database 
-------------+--------------------------------+-------------------------------+-------+----------
       23970 | the first prepared transaction | 2016-08-01 20:44:55.816267+08 | casp  | cqdb
(1 row)

cqdb=> ROLLBACK PREPARED 'the first prepared transaction';            
ROLLBACK PREPARED
cqdb=> SELECT * FROM pg_prepared_xacts;
 transaction | gid | prepared | owner | database 
-------------+-----+----------+-------+----------
(0 rows)
```

即使退出当前session，`pg_catalog.pg_prepared_xact`表中关于已经进入准备阶段的事务信息依然存在，这与上文所述准备阶段后各节点会将事务信息存于磁盘中持久化相符。注：如果不使用`PREPARED TRANSACTION 'transaction_id'`，则已BEGIN但还未COMMIT或ROLLBACK的事务会在session退出时自动ROLLBACK。

在ROLLBACK已进入准备阶段的事务时，必须指定其`transaction_id`。

## PostgreSQL两阶段提交注意事项
 - `PREPARE TRANSACTION transaction_id`命令后，事务状态完全保存在磁盘上。
 - `PREPARE TRANSACTION transaction_id`命令后，事务就不再和当前会话关联，因此当前session可继续执行其它事务。
 - `COMMIT PREPARED`和`ROLLBACK PREPARED`可在任何会话中执行，而并不要求在提交准备的会话中执行。
 - 不允许对那些执行了涉及临时表或者是创建了带`WITH HOLD`游标的事务进行PREPARE。 这些特性和当前会话绑定得实在是太紧密了，因此在一个准备好的事务里没什么可用的。
 - 如果事务用`SET`修改了运行时参数，这些效果在`PREPARE TRANSACTION`之后保留，并且不会被任何以后的`COMMIT PREPARED`或`ROLLBACK PREPARED`所影响，因为`SET`的生效范围是当前session。
 - 从性能的角度来看，把一个事务长时间停在准备好的状态是不明智的，因为它会影响`VACUUM`回收存储的能力。
 - 已准备好的事务会继续持有它们获得的锁，直到该事务被commit或者rollback。所以如果已进入准备阶段的事务一直不被处理，其它事务可能会因为获取不到锁而被block或者失败。
 - 默认情况下，PostgreSQL并不开启两阶段提交，可以通过在`postgresql.conf`文件中设置`max_prepared_transactions`配置项开启PostgreSQL的两阶段提交。


# JTA实现PostgreSQL两阶段提交
本文使用Atomikos提供的JTA实现，利用PostgreSQL提供的两阶段提交特性，实现了分布式事务。本文中的分布式事务使用了2个不同机器上的PostgreSQL实例。

本例所示代码可从[作者Github](https://github.com/habren/atomikos-jta-tomcat)获取。

```java
package com.jasongj.jta.resource;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.sql.DataSource;
import javax.transaction.NotSupportedException;
import javax.transaction.SystemException;
import javax.transaction.UserTransaction;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.WebApplicationException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Path("/jta")
public class JTAResource {
  private static final Logger LOGGER = LoggerFactory.getLogger(JTAResource.class);

  @GET
  public String test(@PathParam(value = "commit") boolean isCommit)
      throws NamingException, SQLException, NotSupportedException, SystemException {
    UserTransaction userTransaction = null;
    try {
      Context context = new InitialContext();
      userTransaction = (UserTransaction) context.lookup("java:comp/UserTransaction");
      userTransaction.setTransactionTimeout(600);
      
      userTransaction.begin();
      
      DataSource dataSource1 = (DataSource) context.lookup("java:comp/env/jdbc/1");
      Connection xaConnection1 = dataSource1.getConnection();
      
      DataSource dataSource2 = (DataSource) context.lookup("java:comp/env/jdbc/2");
      Connection xaConnection2 = dataSource2.getConnection();
      LOGGER.info("Connection autocommit : {}", xaConnection1.getAutoCommit());

      Statement st1 = xaConnection1.createStatement();
      Statement st2 = xaConnection2.createStatement();
      LOGGER.info("Connection autocommit after created statement: {}", xaConnection1.getAutoCommit());
      

      st1.execute("update casp.test set qtime=current_timestamp, value = 1");
      st2.execute("update casp.test set qtime=current_timestamp, value = 2");
      LOGGER.info("Autocommit after execution : ", xaConnection1.getAutoCommit());

      userTransaction.commit();
      LOGGER.info("Autocommit after commit: ",  xaConnection1.getAutoCommit());
      return "commit";

    } catch (Exception ex) {
      if (userTransaction != null) {
        userTransaction.rollback();
      }
      LOGGER.info(ex.toString());
      throw new WebApplicationException("failed", ex);
    }
  }
}
```

从上示代码中可以看到，虽然使用了Atomikos的JTA实现，但因为使用了面向接口编程特性，所以只出现了JTA相关的接口，而未显式使用Atomikos相关类。具体的Atomikos使用是在`WebContent/META-INFO/context.xml`中配置。

```xml
<Context>
  <Transaction factory="com.atomikos.icatch.jta.UserTransactionFactory" />
    <Resource name="jdbc/1"
    auth="Container"
    type="com.atomikos.jdbc.AtomikosDataSourceBean"
    factory="com.jasongj.jta.util.EnhancedTomcatAtomikosBeanFactory"
    uniqueResourceName="DataSource_Resource1"
    minPoolSize="2"
    maxPoolSize="8"
    testQuery="SELECT 1"
    xaDataSourceClassName="org.postgresql.xa.PGXADataSource"
    xaProperties.databaseName="postgres"
    xaProperties.serverName="192.168.0.1"
    xaProperties.portNumber="5432"
    xaProperties.user="casp"
    xaProperties.password=""/>

    <Resource name="jdbc/2"
    auth="Container"
    type="com.atomikos.jdbc.AtomikosDataSourceBean"
    factory="com.jasongj.jta.util.EnhancedTomcatAtomikosBeanFactory"
    uniqueResourceName="DataSource_Resource2"
    minPoolSize="2"
    maxPoolSize="8"
    testQuery="SELECT 1"
    xaDataSourceClassName="org.postgresql.xa.PGXADataSource"
    xaProperties.databaseName="postgres"
    xaProperties.serverName="192.168.0.2"
    xaProperties.portNumber="5432"
    xaProperties.user="casp"
    xaProperties.password=""/>  
</Context>
```








