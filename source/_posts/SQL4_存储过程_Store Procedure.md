title: SQL优化（四） PostgreSQL存储过程
date: 2015-12-27 14:59:45
tags:
  - PostgreSQL
  - Database
  - SQL优化
categories:
  - Database
  - SQL优化
description:
  - 本文介绍了存储过程的概念，优势，并结合实例讲解了存储过程在PostgreSQL中的实现，注意事项
---

原创文章，转载请务必在文章开头处注明出自[Jason's Blog](http://www.jasongj.com)，并给出原文链接[http://www.jasongj.com/2015/12/27/SQL4_%E5%AD%98%E5%82%A8%E8%BF%87%E7%A8%8B_Store%20Procedure/](http://www.jasongj.com/2015/12/27/SQL4_%E5%AD%98%E5%82%A8%E8%BF%87%E7%A8%8B_Store%20Procedure/)

# 存储过程简介
## 什么是存储过程
　　百度百科是这么描述存储过程的：存储过程（Stored Procedure）是在大型数据库系统中，一组为了完成特定功能的SQL语句集，存储在数据库中，首次编译后再次调用不需要再次编译，用户通过指定存储过程的名字并给出参数（如果有）来执行它。它是数据库中的一个重要对象，任何一个设计良好的数据库应用程序都应该用到存储过程。
　　
　　维基百科是这样定义的：A stored procedure (also termed proc, storp, sproc, StoPro, StoredProc, StoreProc, sp, or SP) is a subroutine available to applications that access a relational database management system (RDMS). Such procedures are stored in the database data dictionary。

　　PostgreSQL对存储过程的描述是：存储过程和用户自定义函数（UDF）是SQL和过程语句的集合，它存储于数据库服务器并能被SQL接口调用。

　　总结下来存储过程有如下特性：
- 存储于数据库服务器
- 一次编译后可多次调用
- 设计良好的数据库应用程序很可能会用到它
- 由SQL和过程语句来定义
- 应用程序通过SQL接口来调用


## 使用存储过程的优势及劣势

　　首先看看使用存储过程的优势
- 减少应用与数据库服务器的通信开销，从而提升整体性能。笔者在项目中使用的存储过程，少则几十行，多则几百行甚至上千行（假设一行10个字节，一千行即相当于10KB），如果不使用存储过程而直接通过应用程序将相应SQL请求发送到数据库服务器，会增大网络通信开销。相反，使用存储过程能降低该开销，从而提升整体性能。尤其在一些BI系统中，一个页面往往要使用多个存储过程，此时存储过程降低网络通信开销的优势非常明显
- 一次编译多次调用，提高性能。存储过程存于数据库服务器中，第一次被调用后即被编译，之后再调用时无需再次编译，直接执行，提高了性能
- 同一套业务逻辑可被不同应用程序共用，减少了应用程序的开发复杂度，同时也保证了不同应用程序使用的一致性
- 保护数据库元信息。如果应用程序直接使用SQL语句查询数据库，会将数据库表结构暴露给应用程序，而使用存储过程是应用程序并不知道数据库表结构
- 更细粒度的数据库权限管理。直接从表读取数据时，对应用程序只能实现表级别的权限管理，而使用存储过程是，可在存储过程中将应用程序无权访问的数据屏蔽
- 将业务实现与应用程序解耦。当业务需求更新时，只需更改存储过程的定义，而不需要更改应用程序
- 可以通过其它语言并可及其它系统交互。比如可以使用PL/Java与Kafka交互，将存储过程的参数Push到Kafka或者将从Kafka获取的数据作为存储过程的结果返回给调用方

　　当然，使用存储过程也有它的劣势
- 不便于调试。尤其在做性能调优时，以PostgreSQL为例，可使用EXPLAIN ANALYZE检查SQL查询计划，从而方便的进行性能调优。而使用存储过程时，EXPLAIN ANALYZE无法显示其内部查询计划
- 不便于移植到其它数据库。直接使用SQL时，SQL存于应用程序中，对大部分标准SQL而言，换用其它数据库并不影响应用程序的使用。而使用存储过程时，由于不同数据库的存储过程定义方式不同，支持的语言及语法不同，移植成本较高


# 存储过程在PostgreSQL中的使用

## PostgreSQL支持的过程语言
　　PostgreSQL官方支持PL/pgSQL，PL/Tcl，PL/Perl和PL/Python这几种过程语言。同时还支持一些第三方提供的过程语言，如PL/Java，PL/PHP，PL/Py，PL/R，PL/Ruby，PL/Scheme，PL/sh。


## 基于SQL的存储过程定义
```SQL
CREATE OR REPLACE FUNCTION add(a INTEGER, b NUMERIC)
RETURNS NUMERIC
AS $$
	SELECT a+b;
$$ LANGUAGE SQL;
```

　　调用方法
```SQL
SELECT add(1,2);
 add
-----
   3
(1 row)

SELECT * FROM add(1,2);
 add
-----
   3
(1 row)
```

　　上面这种方式参数列表只包含函数输入参数，不包含输出参数。下面这个例子将同时包含输入参数和输出参数
```SQL
CREATE OR REPLACE FUNCTION plus_and_minus
(IN a INTEGER, IN b NUMERIC, OUT c NUMERIC, OUT d NUMERIC)
AS $$
	SELECT a+b, a-b;
$$ LANGUAGE SQL;
```
　调用方式
```SQL
SELECT plus_and_minus(3,2);
 add_and_minute
----------------
 (5,1)
(1 row)

SELECT * FROM plus_and_minus(3,2);
 c | d
---+---
 5 | 1
(1 row)
```
　　该例中，IN代表输入参数，OUT代表输出参数。这个带输出参数的函数和之前的`add`函数并无本质区别。事实上，输出参数的最大价值在于它为函数提供了返回多个字段的途径。

　　在函数定义中，可以写多个SQL语句，不一定是SELECT语句，可以是其它任意合法的SQL。但最后一条SQL必须是SELECT语句，并且该SQL的结果将作为该函数的输出结果。
```SQL
CREATE OR REPLACE FUNCTION plus_and_minus
(IN a INTEGER, IN b NUMERIC, OUT c NUMERIC, OUT d NUMERIC)
AS $$
	SELECT a+b, a-b;
	INSERT INTO test VALUES('test1');
	SELECT a-b, a+b;
$$ LANGUAGE SQL;
```
　　其效果如果
```SQL
SELECT * FROM plus_and_minus(5,3);
 c | d
---+---
 2 | 8
(1 row)

SELECT * FROM test;
   a
-------
 test1
(1 row)
```


## 基于PL/PgSQL的存储过程定义

　　PL/pgSQL是一个块结构语言。函数定义的所有文本都必须是一个块。一个块用下面的方法定义：
```PLPGSQL
[ <<label>> ]
[DECLARE
	declarations]
BEGIN
	statements
END [ label ];
```
- 中括号部分为可选部分
- 块中的每一个declaration和每一条statement都由一个分号终止
- 块支持嵌套，嵌套时子块的END后面必须跟一个分号，最外层的块END后可不跟分号
- BEGIN后面不必也不能跟分号
- END后跟的label名必须和块开始时的标签名一致
- 所有关键字都不区分大小写。标识符被隐含地转换成小写字符，除非被双引号包围
- 声明的变量在当前块及其子块中有效，子块开始前可声明并覆盖（只在子块内覆盖）外部块的同名变量
- 变量被子块中声明的变量覆盖时，子块可以通过外部块的label访问外部块的变量


　　声明一个变量的语法如下：
```SQL
name [ CONSTANT ] type [ NOT NULL ] [ { DEFAULT | := } expression ];
```

　　使用PL/PgSQL语言的函数定义如下：
```SQL
CREATE FUNCTION somefunc() RETURNS integer AS $$
DECLARE
	quantity integer := 30;
BEGIN
	-- Prints 30
	RAISE NOTICE 'Quantity here is %', quantity;
	quantity := 50;

	-- Create a subblock
    DECLARE
    	quantity integer := 80;
    BEGIN
    	-- Prints 80
    	RAISE NOTICE 'Quantity here is %', quantity;
    	-- Prints 50
    	RAISE NOTICE 'Outer quantity here is %', outerblock.quantity;
    END;

    -- Prints 50
	RAISE NOTICE 'Quantity here is %', quantity;
    RETURN quantity;
END;
$$ LANGUAGE plpgsql;
```


## 声明函数参数
　　如果只指定输入参数类型，不指定参数名，则函数体里一般用$1，$n这样的标识符来使用参数。
```PLPGSQL
CREATE OR REPLACE FUNCTION discount(NUMERIC)
RETURNS NUMERIC
AS $$
BEGIN
	RETURN $1 * 0.8;
END;
$$ LANGUAGE PLPGSQL;
```


　　但该方法可读性不好，此时可以为$n参数声明别名，然后可以在函数体内通过别名指向该参数值。
```PLPGSQL
CREATE OR REPLACE FUNCTION discount(NUMERIC)
RETURNS NUMERIC
AS $$
DECLARE
	total ALIAS FOR $1;
BEGIN
	RETURN total * 0.8;
END;
$$ LANGUAGE PLPGSQL;
```


　　笔者认为上述方法仍然不够直观，也不够完美。幸好PostgreSQL提供另外一种更为直接的方法来声明函数参数，即在声明参数类型时同时声明相应的参数名。
```PLPGSQL
CREATE OR REPLACE FUNCTION discount(total NUMERIC)
RETURNS NUMERIC
AS $$
BEGIN
	RETURN total * 0.8;
END;
$$ LANGUAGE PLPGSQL;
```

## 返回多行或多列

### 使用自定义复合类型返回一行多列
　　PostgreSQL除了支持自带的类型外，还支持用户创建自定义类型。在这里可以自定义一个复合类型，并在函数中返回一个该复合类型的值，从而实现返回一行多列。
```PLPGSQL
CREATE TYPE compfoo AS (col1 INTEGER, col2 TEXT);


CREATE OR REPLACE FUNCTION getCompFoo
(in_col1 INTEGER, in_col2 TEXT)
RETURNS compfoo
AS $$
DECLARE result compfoo;
BEGIN
	result.col1 := in_col1 * 2;
	result.col2 := in_col2 || '_result';
	RETURN result;
END;
$$ LANGUAGE PLPGSQL;


SELECT * FROM getCompFoo(1,'1');
 col1 |   col2
------+----------
    2 | 1_result
(1 row)
```



### 使用输出参数名返回一行多列
　　在声明函数时，除指定输入参数名及类型外，还可同时声明输出参数类型及参数名。此时函数可以输出一行多列。

```PLPGSQL
CREATE OR REPLACE FUNCTION get2Col
(IN in_col1 INTEGER,IN in_col2 TEXT,
OUT out_col1 INTEGER, OUT out_col2 TEXT)
AS $$
BEGIN
	out_col1 := in_col1 * 2;
	out_col2 := in_col2 || '_result';
END;
$$ LANGUAGE PLPGSQL;


SELECT * FROM get2Col(1,'1');
 out_col1 | out_col2 
----------+----------
        2 | 1_result
(1 row)
```


### 使用SETOF返回多行记录
　　实际项目中，存储过程经常需要返回多行记录，可以通过SETOF实现。
```PLPGSQL
CREATE TYPE compfoo AS (col1 INTEGER, col2 TEXT);

CREATE OR REPLACE FUNCTION getSet(rows INTEGER)
RETURNS SETOF compfoo
AS $$
BEGIN
	RETURN QUERY SELECT i * 2, i || '_text' 
	FROM generate_series(1, rows, 1) as t(i);
END;
$$ LANGUAGE PLPGSQL;


SELECT col1, col2 FROM getSet(2);
 col1 |  col2
------+--------
    2 | 1_text
    4 | 2_text
(2 rows)
```
　　本例返回的每一行记录是复合类型，该方法也可返回基本类型的结果集，即多行一列。




### 使用RETURN TABLE返回多行多列
```PLPGSQL
CREATE OR REPLACE FUNCTION getTable(rows INTEGER)
RETURNS TABLE(col1 INTEGER, col2 TEXT)
AS $$
BEGIN
	RETURN QUERY SELECT i * 2, i || '_text'
	FROM generate_series(1, rows, 1) as t(i);
END;
$$ LANGUAGE PLPGSQL;


SELECT col1, col2 FROM getTable(2);
 col1 |  col2
------+--------
    2 | 1_text
    4 | 2_text
(2 rows)
```
　　此时从函数中读取字段就和从表或视图中取字段一样，可以看此种类型的函数看成是带参数的表或者视图。



## 使用EXECUTE语句执行动态命令
　　有时在PL/pgSQL函数中需要生成动态命令，这个命令将包括他们每次执行时使用不同的表或者字符。EXECUTE语句用法如下：
```PLPGSQL
EXECUTE command-string [ INTO [STRICT] target] [USING expression [, ...]];
```

　　此时PL/plSQL将不再缓存该命令的执行计划。相反，在该语句每次被执行的时候，命令都会编译一次。这也让该语句获得了对各种不同的字段甚至表进行操作的能力。
　　command-string包含了要执行的命令，它可以使用参数值，在命令中通过引用如$1，$2等来引用参数值。这些符号的值是指USING字句的值。这种方法对于在命令字符串中使用参数是最好的：它能避免运行时数值从文本来回转换，并且不容易产生SQL注入，而且它不需要引用或者转义。
```PLPGSQL
CREATE TABLE testExecute
AS
SELECT
	i || '' AS a,
	i AS b
FROM
	generate_series(1, 10, 1) AS t(i);

CREATE OR REPLACE FUNCTION execute(filter TEXT)
RETURNS TABLE (a TEXT, b INTEGER)
AS $$
BEGIN
	RETURN QUERY EXECUTE
		'SELECT * FROM testExecute where a = $1'
	USING filter;
END;
$$ LANGUAGE PLPGSQL;


SELECT * FROM execute('3');
 a | b
---+---
 3 | 3
(1 row)

SELECT * FROM execute('3'' or ''c''=''c');
 a | b
---+---
(0 rows)
```


　　当然，也可以使用字符串拼接的方式在command-string中使用参数，但会有SQL注入的风险。
```PLPGSQL
CREATE TABLE testExecute
AS
SELECT
	i || '' AS a,
	i AS b
FROM
	generate_series(1, 10, 1) AS t(i);

CREATE OR REPLACE FUNCTION execute(filter TEXT)
RETURNS TABLE (a TEXT, b INTEGER)
AS $$
BEGIN
	RETURN QUERY EXECUTE
		'SELECT * FROM testExecute where b = '''
		|| filter || '''';
END;
$$ LANGUAGE PLPGSQL;


SELECT * FROM execute(3);
 a | b
---+---
 3 | 3
(1 row)

 SELECT * FROM execute('3'' or ''c''=''c');
 a  | b
----+----
 1  |  1
 2  |  2
 3  |  3
 4  |  4
 5  |  5
 6  |  6
 7  |  7
 8  |  8
 9  |  9
 10 | 10
(10 rows)
```
　　从该例中可以看出使用字符串拼接的方式在command-string中使用参数会引入SQL注入攻击的风险，而使用USING的方式则能有效避免这一风险。


## PostgreSQL中的UDF与存储过程

　　本文中并未区分PostgreSQL中的UDF和存储过程。实际上PostgreSQL创建存储与创建UDF的方式一样，并没有专用于创建存储过程的语法，如CREATE PRECEDURE。在PostgreSQL官方文档中也暂未找到这二者的区别。倒是从一些资料中找对了它们的对比，如下表如示，仅供参考。
![UDF VS. Stored Precedure](http://www.jasongj.com/img/SQL4/pg_udf_stored_precedure.png)


## 多态SQL函数
　　SQL函数可以声明为接受多态类型（anyelement和anyarray）的参数或返回多态类型的返回值。
- 函数参数和返回值均为多态类型。其调用方式和调用其它类型的SQL函数完全相同，只是在传递字符串类型的参数时，需要显示转换到目标类型，否则将会被视为unknown类型。
```PLPGSQL
CREATE OR REPLACE FUNCTION get_array(anyelement, anyelement)
RETURNS anyarray
AS $$
	SELECT ARRAY[$1, $2];
$$ LANGUAGE SQL;

SELECT get_array(1,2), get_array('a'::text,'b'::text);
 get_array | get_array 
-----------+-----------
 {1,2}     | {a,b}
(1 row)
```

-  函数参数为多态类型，而返回值为基本类型
```PLPGSQL
CREATE OR REPLACE FUNCTION is_greater(anyelement, anyelement)
RETURNS BOOLEAN
AS $$
	SELECT $1 > $2;
$$ LANGUAGE SQL;

SELECT is_greater(7.0, 4.5);
 is_greater 
------------
 t
(1 row)

SELECT is_greater(2, 4);    
 is_greater 
------------
 f
(1 row)
```

- 输入输出参数均为多态类型。这种情况与第一种情况一样。
```PLPGSQL
CREATE OR REPLACE FUNCTION get_array
(IN anyelement, IN anyelement, OUT anyelement, OUT anyarray)
AS $$
	SELECT $1, ARRAY[$1, $2];
$$ LANGUAGE SQL;

SELECT get_array(4,5), get_array('c'::text, 'd'::text);
  get_array  |  get_array  
-------------+-------------
 (4,"{4,5}") | (c,"{c,d}")
(1 row)
```

## 函数重载（Overwrite）
　　在PostgreSQL中，多个函数可共用同一个函数名，但它们的参数必须得不同。这一规则与面向对象语言（比如Java）中的函数重载类似。也正因如此，在PostgreSQL删除函数时，必须指定其参数列表，如：
```SQL
DROP FUNCTION get_array(anyelement, anyelement);
```

　　另外，在实际项目中，经常会用到CREATE OR REPLACE FUNCTION去替换已有的函数实现。如果同名函数已存在，但输入参数列表不同，会创建同名的函数，也即重载。如果同名函数已存在，且输入输出参数列表均相同，则替换。如果已有的函数输入参数列表相同，但输出参数列表不同，则会报错，并提示需要先DROP已有的函数定义。


# SQL优化系列
- [SQL优化（一） Merge Join vs. Hash Join vs. Nested Loop](http://www.jasongj.com/2015/03/07/Join1/)
- [SQL优化（二） 快速计算Distinct Count](http://www.jasongj.com/2015/03/15/count_distinct/)
- [SQL优化（三） PostgreSQL Table Partitioning](http://www.jasongj.com/2015/12/13/SQL3_partition/)
- [SQL优化（四） Postgre Sql存储过程](http://www.jasongj.com/2015/12/27/SQL4_%E5%AD%98%E5%82%A8%E8%BF%87%E7%A8%8B_Store%20Procedure/)
　　