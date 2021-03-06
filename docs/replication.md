#MySQL复制小结

#Master - Slave 解决基本的主备设计

普通的一个 Master 后面复制一个或者多个 Slave 的架构设计中,当我们的某一台 Slave
出现故障不能提供服务之后,我们还有至少一台 MySQL 服务器(Master)可以提供
服务,不至于所有和数据库相关的业务都不能运行下去。如果Slave 超过一台,那么剩下 的
Slave 也仍然能够不受任何干扰的继续提供服务。

故，如果可以，请给至少两台salve。


#Master 单点问题的解决
上面的架构可以很容易的解决 Slave 出现故障的情况,而且不需要进行任何调整就能
继续提供服务。 但是, 当我们的Master 出现问题后呢?当我们的 Master 出现问题之后所
有客户端的 Write 请求就都无法处理了。

##有如下两种解决方案：
一个是将 Slave 中的某一台切换成 Master 对外提供服务,同时将其他所有的 Slave 都以通过 CHANGE MASTER 命令来将通过新的
Master 进行复制。

另一个方案就是新增一台 Master,也就是 Dual Master 的解决方案。

对于方案一，最大的一个弊端就是切换步骤比较多,实现比较复杂。而且,在Master 出现
故障 crash 的那个时刻,我们的所有Slave 的复制进度并不一定完全一致,有可能有少量
的差异。这时候,选择哪一个 Slave 作为 Master 也是一个比较头疼的问题。所以这个方
案的可控性并不是特别的高。

方案二，通过两台 MySQL Server 搭建成 Dual Master 环境,正常情况下,所有客户端的
Write 请求都写往 Master A,然后通过 Replication 将 Master A 复制到 Master B。一
旦 Master A 出现问题之后,所有的 Write 请求都转向 Master B。而在正常情况下,当
Master B 出现问题的时候,实际上不论是数据库还是客户端的请求,都不会受到实质性的
影响。

###当我们的Master A 出现问题的时候,应用如何做到自 动将请求转向到 Master B
###呢?其实很简单,我们只需要通过相应的硬件设备如 F5 或者 Cluster 管理软件如
###Heartbeat 来设置一个 VIP,正常情况下该 VIP 指向 Master A,而 一旦 Master
###A出现异常 crash 之后,则自动切换指向到Master B,前端所的应用都通过 这个 VIP
###来访问 Master。这样,既解决了应用的IP 切换问题,还保证了在任何时刻应用
###都只会见到一台 Master,避免了多点写入出现数据紊乱的可能。

#Dual Master 与级联复制结合解决异常故障下的高可用
通过前面的部署架构分析,我们分别得到了 Slave 出现故障后的解决方案,也解决了 Master
的单点问题。现在我们再通过Dual Master 与级联复制结合的架构,来得到一个整
体的解决方案,解决系统整体可靠性的问题。

###首先考虑 Slave 出现异常的情况。在这个架构中,Slave 出现异常后的
处理情况和普通的 Master - Slave 架构的处理方式完全一样, 仅仅需要在应用访问Slave
集群的访问配置中去掉一个 Slave 节点即可解决,不论是通过应用程序自己判断,还是通
过硬件解决方案如 F5 都可以很容易的实现。

###接下来，假设当 Master A 出现故障 crash 之后,Master A 与 Master B
之间的复制将中断,所有 客户端向 Master A 的 Write 请求都必须转向 Master B。
这个转向动作的实现, 可以过通 上一节中所介绍的第二中方案中所介绍的通过 VIP
的方式实现。 由于之前所有的Slave 就 都是从 Master B 来实现复制, 所以Slave
集群不会受到任何的影响, 客户端的所有Read 请求也就不会受到任何的影响,
整个过程可以完全自动进行, 不需要任何的人为干预。

###最后，假设Master B出现故障 crash 之后，会怎样呢?首先可以确定的是我们 的所有
Write 请求都不会受到任何影响,而且所有的 Read 请求也都还是能够正常访问。 但所有
Slave 的复制都会中断,Slave 上面的数据会开始出现滞后的现象。这时候我们需
要做的就是将所有的 Slave 进行 CHANGE MASTER TO 操作,改为从 Master A 进行复制。
由于所有 Slave 的复制都不可能超前最初的数据源,所以可以根据 Slave 上面的 Relay
Log 中的时间戳信息与 Master A 中的时间戳信息进行对照来找到准确的复制起始点,
会不 造成任何的数据丢失。

#Dual Master 与级联复制结合解决在线 DDL 变更问题
当我们使用 Dual Master 加级联复制的组合架构的时候, 对于MySQL 的一个致命伤也
就是在线 DDL 变更来说, 也可以得到一定的解决。 如当我们需要给某个表tab
增加一个字 段。
##可以通过如下在上述架构中来实现:

1、在 Slave 集群中抽出一台暂时停止提供服务,然后对其进行变更,完成后再放回
集群继续提供服务;

2、 重复第一步的操作完成所有 Slave 的变更;

3、暂停 Master B 的复制,同时关闭当前 session 记录二进制日志的功能,对其进
行变更,完成后再启动复制;

4、 通过 VIP 切换,将应用所有对 Master A 的请求切换至 Master B; 5、关闭 Master A
当前 session 记录二进制日志的功能,然后进行变更; 6、 最后再将 VIP 从 Master B
切换回 Master A,至此,所有变更完成。

##变更过程中有几点需要注意的:
1、 整个 Slave 集群需要能够承受在少一台 MySQL 的时候仍然能够支撑所有业务;

2、Slave 集群中增加或者减少一台 MySQL 的操作简单,可通过在线调整应用配置来实现;

3、Dual Master 之间的 VIP 切换简单,且切换时间较短,因为这个切换过程会造成
短时间段内 应用无法访问 Master 数据库。

4、在变更 Master B 的时候,会出现短时间段内 Slave 集群数据的延时,所以如果
单台主机的变更时间较长的话,需要在业务量较低的凌晨进行变更。如果有必要,
甚至可能需要变更 Master B 之前将所有 Slave 切换为以 Master B 作为 Master。

当然,即使是这样,由于存在 Master A 与 Master B 之间的 VIP 切换,我们仍然会出现短时间段内应用无法进行写入操作的情况。 所以说,这种方案也仅仅能够在一定程上度 面解决 MySQL 在线 DDL的问题。而且当集群数量较多,而且每个集群的节点也较多的况情
下,整个操作过程将会非常的复杂也很漫长。对于MySQL 在线 DDL 的问题,目前也确实还没有一个非常完美的解决方案。


#利用 MySQL Cluster 实现整体高可用
这个分布式计算方案的选型就复杂一些了，目前就继续使用mycat吧。

#GTID(Global Transaction Identifiers,全局事务标识,
MySQL-5.6.5开始支持的,MySQL-5.6.10后开始完善)带来了什么？
SQL线程执行的事件也可以通过配置选项来决定是否写入 其自己的二进制日志中,它对于我们
稍后提到的场景非常有用。这种复制架构实现了获取事件和重放事件的解耦,允许这两个过
程异步进行。也就是说I/o线程能够独立于SQL线程之外工作。但这种架构也限制了复制的过程,其中最重要
的一点是在主库上 并发运行的査询在备库只能串行化执行,因为只有一个SQL线程来重
放中继日志中的事件。后面我们将会看到,这是很多工作负 载的性能瓶颈所在。虽然有
一些针对该问题的解决方案,但大多数用户仍然受制于单线程。MySQL5.6以后,提供了基于GTID
开启多线程同步复制的方案,即每个库有一个单独的(sql thread)
进行同步复制,这将大大改善MySQL主从同步的数据延迟问题,配合Mycat分片,可以更好的将一个超级大表的数据同步的时延
降低到最低。此外,用GTID避免了在传送 binlog逻辑上依赖文件名和物理偏移量,能够更好的支持自动容灾切换,对运维人员
来说应该是一件令人高兴的事情,因为传统的方式里,你需要找到binlog和POS点,然后change
master to指向,而不是很有经验的运维,往往会将其找错,造成主从同步复制报错,在mysql5.6里,无须再
知道binlog和POS点,需要知道master的IP、端口,账号密码即可,因为同步复制是自动的,mysql通过内部机制GTID自动找点同步。

#支持多源复制（Multi-source replication）
这对采用分库分表的同学绝对是个超级重磅福音。可以把多个MASTER的数据归并到一个实例上，
有助于提高SLAVE服务器的利用率。不过如果是同一个表的话，会存在主键和唯一索引冲突的风险，需要提前做好规划。

#支持多线程复制（Multi-Threaded Slaves, 简称MTS）
在5.6版本中实现了SCHEMA级别的并行复制，不过意义不大，因为我们线上大部分实例的读写压力基本集中在某几个数据表，基本无助于缓解复制延迟问题。倒是MariaDB的多线程并行复制大放异彩，有不少人因为这个特性选择MariaDB（比如我也是其一，呵呵）。

MySQL 5.7 MTS支持两种模式，一种是和5.6一样，另一种则是基于binlog group
commit实现的多线程复制，也就是MASTER上同时提交的binlog在SLAVE端也可以同时被apply，实现并行复制。关于MTS的更多详细介绍可以查看姜承尧的分享MySQL 5.7 并行复制实现原理与调优，我这里就不重复说了。

值得一提的是，经过对比测试，5.7采用新的并行复制后，仍然会存在一定程度的延迟，只不过相比5.6版本减少了86%，相比MariaDB的并行复制延迟也小不少。


#MySQL主从复制的几个问题
##MySQL主从复制并不完美,存在着几个由来已久的问题,首先一个问题是复制方式：
基于SQL语句的复制(statement-based replication, SBR);

基于行的复制(row-based replication, RBR);

混合模式复制(mixed-based replication, MBR);

基于SQL语句的方式最古老的方式,也是目前默认的复制方式,后来的两种是MySQL5以后才出现的复制方式。

###RBR 的优点：
####任何情况都可以被复制,这对复制来说是最安全可靠的;

和其他大多数数据库系统的复制技术一样;

多数情况下,从服务器上的表如果有主键的话,复制就会快了很多;

###RBR的缺点
binlog 大了很多;

复杂的回滚时 binlog 中会包含大量的数据;

主服务器上执行 UPDATE 语句时,所有发生变化的记录都会写到 binlog 中,而 SBR只会写一次,这会导致频繁发生 binlog 的并发写问题
无法从 binlog 中看到都复制了写什么语句;

###SBR 的优点:
历史悠久,技术成熟;

binlog文件较小;

binlog中包含了所有数据库更改信息,可以据此来审核数据库的安全等情况;

binlog可以用于实时的还原,而不仅仅用于复制;

主从版本可以不一样,从服务器版本可以比主服务器版本高;

###SBR 的缺点:
不是所有的UPDATE语句都能被复制,尤其是包含不确定操作的时候;

复制需要进行全表扫描(WHERE 语句中没有使用到索引)的 UPDATE 时,需要比 RBR

请求更多的行级锁;

对于一些复杂的语句,在从服务器上的耗资源情况会更严重,而 RBR模式下,只会对那个发生变化的记录产生影响

数据表必须几乎和主服务器保持一致才行,否则可能会导致复制出错;

执行复杂语句如果出错的话,会消耗更多资源;

==================================

选择哪种方式复制,会影响到复制的效率以及服务器的损耗,甚以及数据一致性性问题,目前其实没有很好的客观手手段去评估
一个系统更适合哪种方式的复制。

关于主从同步的监控问题,Mysql有主从同步的状态信息,可以通过命令show slave status获取,除了获知当前是
否主从同步正常工作,另外一个重要指标就是Seconds_Behind_Master,从字面理解,它表示当前MySQL主从数据的同步延
迟,单位是秒,但这个指标从DBA的角度并不能简单的理解为延迟多少秒,感兴趣的同学可以自己去研究,但对于应用来说,简
单的认为是主从同步的时间差就可以了。

=========
[MYSQL并行复制的实现与配置](http://www.innomysql.com/article/6276.html)
