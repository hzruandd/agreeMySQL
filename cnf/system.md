cat /sys/block/sda/queue/scheduler
noop deadline [cfq]
#修改为cfq
echo 'cfq'>/sys/block/sda/queue/scheduler

#避免系统做无效的swap
vmstat 查看si、so（接近0最好）、swpd等
cat /proc/sys/vm/swappiness

#默认值0-100，服务器建议设置为0
echo 0 > /proc/sys/vm/swappiness

#访问文件目录，不修改访问文件元信息，对于频繁的小文件负载，可以有效提高性能。
mount /dev/sdb1 /cache1 -o defaults,noatime,nodirtime,async,data=writeback,barrier=0 (if with journal)
mount /dev/sdb1 /cache1 -o defaults,noatime,nodirtime,async (if without journal)


####################################################################################
#CPU性能分析工具：
vmstat
ps
sar
time
strace
pstree
top
#Memory性能分析工具：
vmstat
strace
top
ipcs
ipcrm
cat /proc/meminfo
cat /proc/slabinfo
cat /proc//maps
#I/O性能分析工具：
vmstat
iostat
repquota
quotacheck
#Network性能分析工具：
ifconfig
ethereal
tethereal
iptraf
iwconfig
nfsstat
mrtg
ntop
netstat

#Linux 性能调优工具

当通过上述工具及命令，我们发现了应用的性能瓶颈以后，我们可以通过以下工具或者命令来进行性能的调整。
#CPU性能调优工具：
nice / renic
sysctl
#Memory性能调优工具：
swapon
ulimit
sysctl
#I/O性能调优工具：
edquota
quoton
sysctl
boot line:
elevator=
#Network性能调优工具：
ifconfig
iwconfig
sysctl


##I/O性能调整
系统出现以下情况时，我们认为该系统存在I/O性能问题：
系统等待I/O的时间超过50%；
一个设备的平均队列长度大于5。
1.修改I/O调度算法
2.文件系统调整。
对于文件系统的调整，有几个公认的准则：
将I/O负载相对平均的分配到所有可用的磁盘上；
选择合适的文件系统，Linux内核支持reiserfs、ext2、ext3、jfs、xfs等文件系统；
# mkfs -t reiserfs -j /dev/sdc1
文件系统即使在建立后，本身也可以通过命令调优；
tune2fs (ext2/ext3)
reiserfstune (reiserfs)
jfs_tune (jfs)
3.文件系统Mount时可加入选项noatime、nodiratime
4.调整块设备的READAHEAD，调大RA值.
blockdev --report
blockdev --setra 2048 /dev/sdb1


##Network性能调整
一个应用系统出现如下情况时，我们认为该系统存在网络性能问题：
网络接口的吞吐量小于期望值；
出现大量的丢包现象；
出现大量的冲突现象。
Network性能调整方法：
1.调整网卡的参数
#ethtool -s eth0 duplex full
#ifconfig eth0 mtu 9000 up
2.增加网络缓冲区和包的队列
cat /proc/sys/net/ipv4/tcp_mem
cat /proc/sys/net/core/rmem_default
cat /proc/sys/net/core/rmem_max
cat /proc/sys/net/core/wmem_default
cat /proc/sys/net/core/wmem_max
cat /proc/sys/net/core/optmem_max
cat /proc/sys/net/core/netdev_max_backlog
# sysctl -w net.core.rmem_max=135168
net.core.rmem_max = 135168
3.调整Webserving
# sysctl net.ipv4.tcp_tw_reuse
net.ipv4.tcp_tw_reuse = 0
# sysctl -w net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_tw_reuse = 1
# sysctl net.ipv4.tcp_tw_recycle
net.ipv4.tcp_tw_recycle = 0
# sysctl -w net.ipv4.tcp_tw_recycle=1
net.ipv4.tcp_tw_recycle = 1



#linux I/O调度方式启用异步方式，提高读写性能

有关IO的几个内核参数：
#/proc/sys/vm/dirty_ratio
这个参数控制文件系统的文件系统写缓冲区的大小，单位是百分比，表示系统内存的百分比，表示当写缓冲使用到系统内存多少的时候，开始向磁盘写出数 据。
增大之会使用更多系统内存用于磁盘写缓冲，也可以极大提高系统的写性能。但是，当你需要持续、恒定的写入场合时，应该降低其数值，一般启动上缺省是 10
#/proc/sys/vm/dirty_expire_centisecs
这个参数声明Linux内核写缓冲区里面的数据多“旧”了之后，pdflush进程就开始考虑写到磁盘中去。单位是 1/100秒。
缺省是30000，也就是30秒的数据就算旧了，将会刷新磁盘。对于特别重载的写操作来说，
这个值适当缩小也是好的，但也不能缩小太多，因为缩小太多也会导致IO提高太快。建议设置为 1500，也就是15秒算旧。
#/proc/sys/vm/dirty_background_ratio
这个参数控制文件系统的pdflush进程，在何时刷新磁盘。单位是百分比，表示系统内存的百分比，意思是当写缓冲使用到系统内存多少的时候， 
pdflush开始向磁盘写出数据。增大之会使用更多系统内存用于磁盘写缓冲，也可以极大提高系统的写性能。
但是，当你需要持续、恒定的写入场合时，应该 降低其数值，一般启动上缺省是 5
#/proc/sys/vm/dirty_writeback_centisecs
这个参数控制内核的脏数据刷新进程pdflush的运行间隔。单位是 1/100 秒。缺省数值是500，也就是 5 秒。
如果你的系统是持续地写入动作，那么实际上还是降低这个数值比较好，这样可以把尖峰的写操作削平成多次写操作
当然最主要的还是升级硬件或通过做RAID实现

####################################################################################
