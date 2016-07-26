#如果高效删除亿级别数据

删除之前，做个完整备份。
我在删除前先保存当前索引的DDL，然后删除其索引，
然后根据使用的删除条件建立一个临时的索引（这是提高速度的另外一个重要原因！）
开始删除操作，完成之后再重建之前的索引。

如果需要保留的数据比较少的话，可以把要保留的数据备份出来。在drop表。重新创建，先不要急着创建索引、主键，把数据导回去，然后在建索引、约束之类的。

###记得在删除的时候不要在记录日志的模式下面，否则日志文件就要爆了。
###DELETE语句不使用LIMIT ，容易造成主从不一致。
###高危操作检查，Drop前做好数据备份

#Online DDL问题
原生MySQL执行DDL时需要锁表，且锁表期间业务是无法写入数据的，对服务影响很大，MySQL对这方面的支持是比较差的。大表做DDL对DBA来说是很痛苦的，相信很多人经历过。
Facebook OSC和5.6 OSC也是目前两种比较靠谱的方案。但是MySQL
5.6的OSC方案还是解决不了DDL的时候到从库延时的问题，所以现在建议使用Facebook
OSC这种思路更优雅。

后来Percona公司根据Facebook
OSC思路，用perl重写了一版，就是我们现在用得很多的pt-online-schema-change。


##使用pt-online-schema-change的优点有：

无阻塞写入
完善的条件检测和延时负载策略控制

##使用pt-online-schema-change的限制
改表时间会比较长(相比直接alter table改表)
修改的表需要有唯一键或主键
在同一端口上的并发修改不能太多


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

