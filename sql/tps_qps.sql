TPS - Transactions Per Second（每秒传输的事物处理个数），这是指服务器每秒处理的事务数，支持事务的存储引擎如InnoDB等特有的一个性能指标。

计算方法：
TPS = (COM_COMMIT + COM_ROLLBACK)/UPTIME

use information_schema;  
select VARIABLE_VALUE into @num_com from GLOBAL_STATUS where VARIABLE_NAME ='COM_COMMIT';  
select VARIABLE_VALUE into @num_roll from GLOBAL_STATUS where VARIABLE_NAME ='COM_ROLLBACK';  
select VARIABLE_VALUE into @uptime from GLOBAL_STATUS where VARIABLE_NAME ='UPTIME';  
select (@num_com+@num_roll)/@uptime;  




QPS - Queries Per Second（每秒查询处理量）同时适用与InnoDB和MyISAM 引擎 
计算方法：
QPS=QUESTIONS/UPTIME

use information_schema;  
select VARIABLE_VALUE into @num_queries from GLOBAL_STATUS where VARIABLE_NAME ='QUESTIONS';  
select VARIABLE_VALUE into @uptime from GLOBAL_STATUS where VARIABLE_NAME ='UPTIME';  
select @num_queries/@uptime;  
