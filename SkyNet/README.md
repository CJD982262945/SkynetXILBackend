# ChessServer
基于 skynet 棋牌项目

#install percona-mongodb 
sudo yum install http://www.percona.com/downloads/percona-release/redhat/0.1-6/percona-release-0.1-6.noarch.rpm
sudo yum list | grep percona
sudo yum install Percona-Server-MongoDB-36
sudo service mongod status
systemctl enable mongod

#uninstall percona-mongodb
sudo service mongod stop
sudo yum remove Percona-Server-MongoDB*
rm -rf /var/lib/mongodb
rm -f /etc/mongod.cnf

#pika
拷贝pika_tool 目录

#部署
设置setting中网关信息 和dirpath信息
请确保系统至少2G内存