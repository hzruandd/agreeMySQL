#测试磁盘读写速率

##题外话

传统的UNIX实现在内核中设有缓冲区高速缓存或页面高速缓存，大多数磁盘I/O都通过缓冲进行。当将数据写入文件时，
内核通常先将该数据复制到其中一个缓冲区中，如果该缓冲区尚未写满，则并不将其排入输出队列，而是等待其写满或
者当内核需要重用该缓冲区以便存放其他磁盘块数据时，再将该缓冲排入输出队列，然后待其到达队首时，才进行实际的I/O操作。这种输出方式被称为延迟写（delayed write）
，延迟写减少了磁盘读写次数，但是却降低了文件内容的更新速度，使得欲写到文件中的数据在一段时间内并没有
写到磁盘上。当系统发生故障时，这种延迟可能造成文件更新内容的丢失。为了保证磁盘上实际文件系统与缓冲区
高速缓存中内容的一致性，UNIX系统提供了sync、fsync和fdatasync三个函数。
sync函数只是将所有修改过的块缓冲区排入写队列，然后就返回，它并不等待实际写磁盘操作结束。
通常称为update的系统守护进程会周期性地（一般每隔30秒）调用sync函数。这就保证了定期冲洗内
核的块缓冲区。命令sync(1)也调用sync函数。fsync函数只对由文件描述符filedes指定的单一文件起作用，
并且等待写磁盘操作结束，然后返回。fsync可用于数据库这样的应用程序，这种应用程序需要确保将修改过的块立即写到磁盘上。
fdatasync函数类似于fsync，但它只影响文件的数据部分。而除数据外，fsync还会同步更新文件的属性。
[更多介绍请点击我](https://github.com/hzruandd/agreeMySQL/blob/master/docs/data_persistence.md)

##测试磁盘读写的影响因素
1，保障没有其他应用在跑；
2，手工清理缓存，echo 3 > /proc/sys/vm/drop_caches；

##测试方法
1，hdparm；
2，dd；
3，cp；
4，scp；
####其中dd和cp测试时，要利用好/dev/null,/dev/zero两个文件。


=============================
##这里先介绍dd的“正确”使用

功能说明：读取，转换并输出数据。

=============================
语　　法：dd
[bs=<字节数>][cbs=<字节数>][conv=<关键字>][count=<区块数>][ibs=<字节数>][if=<文件>][obs=<字节数>][of=<文件>][seek=<区块数>][skip=<区块数>][--help][--version]

补充说明：dd可从标准输入或文件读取数据，依指定的格式来转换数据，再输出到文件，设备或标准输出。

参　　数：

  bs=<字节数>   将ibs( 输入)与obs(输出)设成指定的字节数。

  cbs=<字节数>   转换时，每次只转换指定的字节数。

  conv=<关键字>   指定文件转换的方式。

  count=<区块数>   仅读取指定的区块数。

  ibs=<字节数>   每次读取的字节数。

  if=<文件>   从文件读取。

  obs=<字节数>   每次输出的字节数。

  of=<文件>   输出到文件。

  seek=<区块数>   一开始输出时，跳过指定的区块数。

  skip=<区块数>   一开始读取时，跳过指定的区块数。

  --help   帮助。

  --version   显示版本信息。


=============================
###dd常用参数详解

=============================
if=xxx  从xxx读取，如if=/dev/zero,该设备无穷尽地提供0,（不产生读磁盘IO）
of=xxx
向xxx写出，可以写文件，可以写裸设备。如of=/dev/null，"黑洞"，它等价于一个只写文件.
所有写入它的内容都会永远丢失. （不产生写磁盘IO）
bs=8k  每次读或写的大小，即一个块的大小。
count=xxx  读写块的总数量。

=============================
###使用sync、fsync、fdatasync，避免操作系统“写缓存”干扰测试
=============================
dd bs=8k count=4k if=/dev/zero of=test.log conv=fsync 

dd bs=8k count=4k if=/dev/zero of=test.log conv=fdatasync

dd bs=8k count=4k if=/dev/zero of=test.log oflag=dsync

dd bs=8k count=4k if=/dev/zero of=test.log  默认“写缓存”启作用

dd bs=8k count=4k if=/dev/zero of=test.log conv=sync   “写缓存”启作用

dd bs=8k count=4k if=/dev/zero of=test.log; sync   “写缓存”启作用

dd bs=8k count=4k if=/dev/zero of=test.log conv=fsync 
加入这个参数后，dd命令执行到最后会真正执行一次“同步(sync)”操作，，这样算出来的时间才是比较符合
实际使用结果的。conv=fsync表示把文件的“数据”和“metadata”都写入磁盘（metadata包括size、访问时间st_atime& st_mtime等等），
因为文件的数据和metadata通常存在硬盘的不同地方，因此fsync至少需要两次IO写操作，fsync
与fdatasync相差不大。（重要，最有参考价值）

dd bs=8k count=4k if=/dev/zero of=test.log conv=fdatasync
加入这个参数后，dd命令执行到最后会真正执行一次“同步(sync)”操作，这样算出来的时间才是比较符合实际使用结果的。conv=fdatasync表示只把文件的“数据”写入磁盘，fsync
与fdatasync相差不大。（重要，最有参考价值）

dd bs=8k count=4k if=/dev/zero of=test.log oflag=dsync
加入这个参数后，每次读取8k后就要先把这8k写入磁盘，然后再读取下面一个8k，一共重复4K次。这是最慢的一种方式了。

dd bs=8k count=4k if=/dev/zero of=test
####没加关于操作系统“写缓存”的参数，默认“写缓存”启作用。dd先把数据写的操作系统“写缓存”，就完成了写操作。通常称为update的系统守护进程会周期性地（一般每隔30秒）调用sync函数，把“写缓存”#####中的数据刷入磁盘。####因为“写缓存”起作用，你会测试出一个超级快的性能。
如：163840000 bytes (164 MB) copied, 0.742906 seconds, 221 MB/s

dd bs=8k count=4k if=/dev/zero of=test conv=sync  

conv=sync参数明确“写缓存”启作用，默认值就是conv=sync 

dd bs=8k count=4k if=/dev/zero of=test; sync 

与第1个完全一样，分号隔开的只是先后两个独立的命令。当sync命令准备开始往磁盘上真正写入数据的时候，前面dd命令已经把错误的“写入速度”值显示在屏幕上了。所以你还是得不到真正的写入速度。
