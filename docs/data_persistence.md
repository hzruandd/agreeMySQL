#保障文件的更新持久化到磁盘

##write不够，需要fsync
一般情况下，对硬盘（或者其他持久存储设备）文件的write操作，更新的只是内存中的页缓存（page
cache），而脏页面不会立即更新到硬盘中，而是由操作系统统一调度，如由专门的flusher内核线程在满足一定条件时（如一定时间间隔、内存中的脏页达到一定比例）内将脏页面同步到硬盘上（放入设备的IO请求队列）。
因为write调用不会等到硬盘IO完成之后才返回，因此如果OS在write调用之后、硬盘同步之前崩溃，则数据可能丢失。虽然这样的时间窗口很小，但是对于需要保证事务的持久化（durability）和一致性（consistency）的数据库程序来说，write()所提供的“松散的异步语义”是不够的，通常需要OS提供的同步IO（synchronized-IO）原语来保证：

`#include <unistd.h>
int fsync(int fd);`
fsync的功能是确保文件fd所有已修改的内容已经正确同步到硬盘上，该调用会阻塞等待直到设备报告IO完成。
 
 
PS：如果采用内存映射文件的方式进行文件IO（使用mmap，将文件的page
cache直接映射到进程的地址空间，通过写内存的方式修改文件），也有类似的系统调用来确保修改的内容完全同步到硬盘之上：

`#incude <sys/mman.h>
int msync(void *addr, size_t length, int flags)`

msync需要指定同步的地址区间，如此细粒度的控制似乎比fsync更加高效（因为应用程序通常知道自己的脏页位置），但实际上（Linux）kernel中有着十分高效的数据结构，能够很快地找出文件的脏页，使得fsync只会同步文件的修改内容。


##fsync的性能问题，与fdatasync
除了同步文件的修改内容（脏页），fsync还会同步文件的描述信息（metadata，包括size、访问时间st_atime
& st_mtime等等），因为文件的数据和metadata通常存在硬盘的不同地方，因此fsync至少需要两次IO写操作多余的一次IO操作，有多么昂贵呢？根据Wikipedia的数据，当前硬盘驱动的平均寻道时间（Average
seek time）大约是3~15ms，7200RPM硬盘的平均旋转延迟（Average rotational latency）大约为4ms，因此一次IO操作的耗时大约为10ms左右。这个数字意味着什么？下文还会提到。

 

Posix同样定义了fdatasync，放宽了同步的语义以提高性能：

`#include <unistd.h>
int fdatasync(int fd);`

fdatasync的功能与fsync类似，但是仅仅在必要的情况下才会同步metadata，因此可以减少一次IO写操作。那么，什么是“必要的情况”呢？
举例来说，文件的尺寸（st_size）如果变化，是需要立即同步的，否则OS一旦崩溃，即使文件的数据部分已同步，由于metadata没有同步，依然读不到修改的内容。而最后访问时间(atime)/修改时间(mtime)是不需要每次都同步的，只要应用程序对这两个时间戳没有苛刻的要求，基本无伤大雅。
 
 
PS：open时的参数O_SYNC/O_DSYNC有着和fsync/fdatasync类似的语义：使每次write都会阻塞等待硬盘IO完成。（实际上，Linux对O_SYNC/O_DSYNC做了相同处理，没有满足Posix的要求，而是都实现了fdatasync的语义）相对于fsync/fdatasync，这样的设置不够灵活，应该很少使用。


##使用fdatasync优化日志同步
文章开头时已提到，为了满足事务要求，数据库的日志文件是常常需要同步IO的。由于需要同步等待硬盘IO完成，所以事务的提交操作常常十分耗时，成为性能的瓶颈。
在Berkeley
DB下，如果开启了AUTO_COMMIT（所有独立的写操作自动具有事务语义）并使用默认的同步级别（日志完全同步到硬盘才返回），写一条记录的耗时大约为5~10ms级别，基本和一次IO操作（10ms）的耗时相同。
我们已经知道，在同步上fsync是低效的。但是如果需要使用fdatasync减少对metadata的更新，则需要确保文件的尺寸在write前后没有发生变化。日志文件天生是追加型（append-only）的，总是在不断增大，似乎很难利用好fdatasync。
 
看Berkeley DB是怎样处理日志文件的：
    1.每个log文件固定为10MB大小，从1开始编号，名称格式为log.%010
    2.每次log文件创建时，先写文件的最后1个page，将log文件扩展为10MB大小
    3.向log文件中追加记录时，由于文件的尺寸不发生变化，使用fdatasync可以大大优化写log的效率
    4.如果一个log文件写满了，则新建一个log文件，也只有一次同步metadata的开销"
