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
分输出的信息对于我们调整 innodb_thread_concurrency
参数有非常大的帮助,当等待信号量
非常大的时候,可能就需要禁用并发线程检测设置innodb_thread_concurrency=0;
◆
TRANSACTIONS,这里主要展示系统的锁等待信息和当前活动事务信息。通过这部分输出,我们
可以查追踪到死锁的详细信息;
◆ FILE I/O,文件 IO 相关的信息,主要是 IO 等待信息;
◆ INSERT BUFFER AND ADAPTIVE HASH INDEX;显示插入缓存当前状态信息以及自适应Hash
Index
的状态;
◆ LOG,Innodb事务日志相关信息,包括当前的日志序列号(LogSequenceNumber),已经刷新
同步到哪个序列号,最近的Check Point到哪个序列号了。除此之外,还显示了系统从启动到
现在已经做了多少次Ckeck Point,多少次日志刷新;
◆ BUFFER POOL AND MEMORY,这部分主要显示 Innodb Buffer Pool
相关的各种统计信息,以及其
他一些内存使用的信息;
◆ ROW OPERATIONS,顾名思义,主要显示的是与客户端的请求Query 和这些 Query
所影响的记录统
计信息。

