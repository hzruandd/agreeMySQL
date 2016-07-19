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
