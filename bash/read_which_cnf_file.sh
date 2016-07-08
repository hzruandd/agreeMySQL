#搞清楚MySQL读取的配置文件路径是你修改cnf第一要务！
$ which mysqld
/usr/local/bin/mysqld
$ /usr/local/bin/mysqld --verbose --help|grep -A 1 'Default options'
Default options are read from the following files in the given order:
/etc/my.cnf /etc/mysql/my.cnf /usr/local/etc/my.cnf ~/.my.cnf 
