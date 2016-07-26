#sharding拆分问题

sharding是按照一定规则数据重新分布的方式
主要解决单机写入压力过大和容量问题
主要有垂直拆分和水平拆分两种方式
拆分要适度，切勿过度拆分
有中间层控制拆分逻辑最好，否则拆分过细管理成本会很高


#数据库备份

##目前备份方式
全量备份 VS 增量备份
热备 VS 冷备
物理备份 VS 逻辑备份
延时备份
全量binlog备份

##建议方式
热备＋物理备份
核心业务：延时备份＋逻辑备份
全量binlog备份

##主要做的几点
备份策略集中式调度管理
xtrabackup热备
备份结果统计分析
备份数据一致性校验
采用分布式文件系统存储备份


#性能优化
##复制优化
MySQL复制：

MySQL应用得最普遍的应用技术，扩展成本低
逻辑复制
单线程问题，从库延时问题
可以做备份或读复制

####单线程解决方案:
官方5.6+多线程方案
Tungsten为代表的第三方并行复制工具
sharding
MySQL5.6
目前实现的并行复制原理图，是基于库级别的复制，所以如果你只有一个库，使用这个意义不大!
5.7引入了另外一种并行复制方式，基于logical
timestamp的并行复制，并行复制不再受限于库的个数，效率会大大提升。

MySQL原来只支持异步复制，这种数据安全性是非常差的，所以后来引入了半同步复制，从5.5开始支持.

在5.7之后，半同步也可以配置你指定多个从库参与半同步复制，之前版本都是默认一个从库。

对于半同步复制效率问题有一个小的优化，就是使用5.6+的mysqlbinlog以daemon方式作为从库，同步效率会好很多。

关于更安全的复制，MySQL 5.7也是有方案的，方案名叫Group replication
官方多主方案，基于Corosync实现。

##主从延时问题
原因：一般都会做读写分离，其实从库压力反而比主库大／从库读写压力大非常容易导致延时。
###解决方案：
首先定位延时瓶颈
如果是IO压力，可以通过升级硬件解决，比如替换SSD等
如果IO和CPU都不是瓶颈，非常有可能是SQL单线程问题，解决方案可以考虑刚才提到的并行复制方案
如果还有问题，可以考虑sharding拆分方案

提到延时不得不提到很坑人的Seconds behind master，使用过MySQL的应该很熟悉。
Secondsbehindmaster来判断延时不可靠，在网络抖动或者一些特殊参数配置情况下，会造成这个值是0但其实延时很大了。通过heartbeat表插入时间戳这种机制判断延时是更靠谱的.

####复制注意点
Binlog格式，建议都采用row格式，数据一致性更好
Replication filter应用

##InnoDB优化
成熟开源事务存储引擎，支持ACID，支持事务四个隔离级别，更好的数据安全性，高性能高并发，MVCC，细粒度锁，支持O_DIRECT。
###主要优化参数
innodb_file_per_table =1
innodb_buffer_pool_size，根据数据量和内存合理设置
innodb_flush_log_at_trxcommit= 0 1 2
innodb_log_file_size，可以设置大一些
innodb_page_size
Innodb_flush_method = o_direct
innodb_undo_directory 放到高速设备(5.6＋)
innodb_buffer_pool_dump
atshutdown ，buffer_pool_dump (5.6+)

###InnoDB比较好的特性
Bufferpool预热和动态调整大小，动态调整大小需要5.7支持
Page size自定义调整，适应目前硬件
InnoDB压缩，大大降低数据容量，一般可以压缩50%，节省存储空间和IO，用CPU换空间

###InnoDB在SSD上的优化
在5.5以上，提高innodbwriteiothreads和innodbreadiothreads
innodbiocapacity需要调大*
日志文件和redo放到机械硬盘，undo放到SSD，建议这样，但必要性不大
atomic write,不需要Double Write Buffer
InnoDB压缩
单机多实例

##搞清楚InnoDB哪些文件是顺序读写，哪些是随机读写
###随机读写
datadir
innodbdata file_path
innodbundo directory
###顺序读写
innodbloggrouphomedir
log-bin

#QA
对于用于MySQL的ssd，测试方式和ssd的参数配置方面，有没有好的建议？
关于SATA SSD配置参数，建议使用Raid5，想更保险使用Raid50，更土豪使用Raid 10.
echo noop/deadline > /sys/block/[device]/queue/scheduler
echo 0 > /sys/block/[device]/queue/add_random
echo 2 > /sys/block/[device]/queue/rq_affinity (CentOS 6.4 +)
echo 0 > /sys/block/[device]/queue/rotational

如何最大限度提高innodb的命中率？
这个问题前提是你的数据要有热点，读写热点要有交集，否则命中率很难提高。在有热点的前提下，也要求你的你的内存要足够大，能够存更多的热点数据。尽量不要做一些可能污染bufferpool的操作，比如全表扫描这种。

主从复制的情况下，如果有CAS这样的需求，是不是只能强制连主库？因为有延迟的存在，如果读写不在一起的话，会有脏数据。
如果有CAS需求，确实还是直接读主库好一些，因为异步复制还是会有延迟的。只要SQL优化的比较好，读写都在主库也是没什么问题的。

对于binlog格式，为什么只推荐row，而不用网上大部分文章推荐的Mix ？
主要是考虑数据复制的可靠性，row更好。mixed含义是指如果有一些容易导致主从不一致的SQL
，比如包含UUID函数的这种，转换为row。既然要革命，就搞的彻底一些。这种mix的中间状态最坑人了。

关于备份，binlog备份自然不用说了，物理备份有很多方式，有没有推荐的一种，逻辑备份在量大的时候恢复速度比较慢，一般用在什么场景？

物理备份采用xtrabackup热备方案比较好。逻辑备份一般用在单表恢复效果会非常好。比如你删了一个2G表，但你总数据量2T，用物理备份就会要慢了，逻辑备份就非常有用了。



