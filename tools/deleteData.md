#删除数据库数据操作

TRUNCATE TABLE 在功能上与不带 WHERE 子句的 DELETE
语句相同：二者均删除表中的全部行。但 TRUNCATE TABLE 比 DELETE
速度快，且使用的系统和事务日志资源少。
DELETE 语句每次删除一行，并在事务日志中为所删除的每行记录一项。TRUNCATE TABLE
通过释放存储表数据所用的数据页来删除数据，并且只在事务日志中记录页的释放。
TRUNCATE TABLE
删除表中的所有行，但表结构及其列、约束、索引等保持不变。新行标识所用的计数值重置为该列的种子。如果想保留标识计数值，请改用
DELETE。如果要删除表定义及其数据，请使用 DROP TABLE 语句。
速度：innodb ，truncate table 》drop table >delete
上面是myisam engine下测试，truncate table 比drop table速度差不多；
如果是innodb ，truncate table 比drop table快一倍。
truncate talbe保留表结构,indexs ,trigger, procedure, function，而drop
table不保留这些。
执行完truncate table之后，自增字段从第一个开始。
http://hi.baidu.com/jackbillow/item/cfe5f8e03780e0a8c00d7527

#使用
在实际应用中，三者的区别是明确的。 
当你不再需要该表时， 用 drop; 
当你仍要保留该表，但要删除所有记录时， 用 truncate; 
当你要删除部分记录时（always with a WHERE clause), 用 delete.

1.DELETE
DML语言
可以回退
可以有条件的删除
DELETE FROM 表名
WHERE 条件

2.TRUNCATE TABLE
DDL语言
无法回退
默认所有的表内容都删除
删除速度比delete快。
TRUNCATE TABLE 表名

1、TRUNCATE在各种表上无论是大的还是小的都非常快。如果有ROLLBACK命令Delete将被撤销，而TRUNCATE则不会被撤销。 

2、TRUNCATE是一个DDL语言，向其他所有的DDL语言一样，他将被隐式提交，不能对TRUNCATE使用ROLLBACK命令。 

3、TRUNCATE将重新设置高水平线和所有的索引。在对整个表和索引进行完全浏览时，经过TRUNCATE操作后的表比Delete操作后的表要快得多。 

4、TRUNCATE不能触发任何Delete触发器。 

5、当表被清空后表和表的索引讲重新设置成初始大小，而delete则不能。 

6、不能清空父表。

