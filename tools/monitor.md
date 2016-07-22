#监控和查看服务器资源

nagios,或许是开源里最流行的监控报警系统。

zabbix，储存更多的数据类型，展示历史数据报表，网络画图，可视化能力比nagios更好。

监控交换机，使用SNMP的low level discovery（LLD），全自动的添加端口监控，应该是非常容易的。但部分交换机不存在现成的LLD模板，需要自己定制。可参考https://github.com/jjmartres/Zabbix/tree/master/zbx-templates/zbx-cisco这里罗列的模板。另外对图形的展示方面，zabbix不如cacti方便，目前58同城的开源项目zatree解决了这个问题，参考该项目https://github.com/spide4k/zatree

关于nagios和zabbix的选择，可以浏览https://www.zhihu.com/question/19973178

Open-Falcon 是小米运维部开源的一款互联网企业级监控系统解决方案,http://open-falcon.org/

nmon

glance



#MySQL 支持的查看语句

SHOW TABLES FROM INFORMATION_SCHEMA '%_STATISTICS';
找出什么地方花费了最多时间，什么表或者索引使用的最频繁、最不频繁

show innodb status\G;
SEMAPHORES,这部分主要显示系统中当前的信号等待信息以及各种等待信号的统计信息,这部
分输出的信息对于我们调整 innodb_thread_concurrency参数有非常大的帮助,当等待信号量
非常大的时候,可能就需要禁用并发线程检测设置innodb_thread_concurrency=0;

TRANSACTIONS,这里主要展示系统的锁等待信息和当前活动事务信息。通过这部分输出,我们
可以查追踪到死锁的详细信息;

FILE I/O,文件 IO 相关的信息,主要是 IO 等待信息;

INSERT BUFFER AND ADAPTIVE HASH INDEX;显示插入缓存当前状态信息以及自适应Hash
Index的状态;

LOG,Innodb事务日志相关信息,包括当前的日志序列号(LogSequenceNumber),已经刷新
同步到哪个序列号,最近的Check Point到哪个序列号了。除此之外,还显示了系统从启动到
现在已经做了多少次Ckeck Point,多少次日志刷新;

BUFFER POOL AND MEMORY,这部分主要显示 Innodb Buffer Pool相关的各种统计信息,以及其
他一些内存使用的信息;

ROW OPERATIONS,顾名思义,主要显示的是与客户端的请求Query 和这些 Query
所影响的记录统计信息。


#mysqladmin
ping命令可以很容易检测MySQL Server是否还能正常提供服务 
mysqladmin -u user -ppwd -h localhost ping mysqld is alive

status命令可以获取当前MySQL Server的几个基本的状态值:
mysqladmin -u sky -ppwd -h localhost status


processlist 获取当前数据库的连接线程信息:
mysqladmin -u sky -ppwd -h localhost processlist

mysqladmin 来 start slave 和 stop slave,kill 某个连接到 MySQL Server 的线程等等


#mysqlbinlog
mysqlbinlog 就可以帮助我们找到恢复操作需要做哪些事情。通过mysqlbinlog,我们
可以解析出 binlog 中指定时间段或者指定日志起始和结束位置的内容解析成SQL 语句,并
导出到指定的文件中,在解析过程中,还可以通过指定数据库名称来过滤输出内容

#mysqlcheck
mysqlcheck 工具程序可以检查( check) ,修复(repair) ,分析(analyze)和优化
(optimize)MySQL Server 中的表,但并不是所有的存储引擎都支持这里所有的四个功能,
像 Innodb 就不支持修复功能。 实际上,mysqlcheck 程序的这四个功能都可以通过 mysql
连 接登录到MySQL Server之后来执行相应命令完成完全相同的任务。)


#myisampack
对 MyISAM 表进行压缩处理,以缩减占用存储空间,一般主要用在归档备份的场景下,
而且压缩后的 MyISAM 表会变成只读,不能进行任何修改操作。当我们希望归档备份某些历
史数据表,而又希望该表能够提供较为高效的查询服务的时候,就可以通过myisampack 工
具程序来对该 MyISAM 表进行压缩,因为即使虽然更换成 archive
存储引擎也能够将表变成 只读的压缩表,但是 archive
表是没有索引支持的,而通过压缩后的MyISAM 表仍然可以使 用其索引。


mysqldumpslow分析处理 slowlog 


#查看半同步状态：
show variables like '%sync%';  

#有几个状态参数值得关注的
show status like '%sync%'; 
rpl_semi_sync_master_status：显示主服务是异步复制模式还是半同步复制模式  
rpl_semi_sync_master_clients：显示有多少个从服务器配置为半同步复制模式  
rpl_semi_sync_master_yes_tx：显示从服务器确认成功提交的数量  
rpl_semi_sync_master_no_tx：显示从服务器确认不成功提交的数量  
rpl_semi_sync_master_tx_avg_wait_time：事务因开启semi_sync，平均需要额外等待的时间  
rpl_semi_sync_master_net_avg_wait_time：事务进入等待队列后，到网络平均等待时间  

