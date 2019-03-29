#!/bin/bash
. /etc/init.d/functions
usage(){
  echo "usage:$0 user password host port OR $0 user password sock"
  exit 1
}
check_up(){
  if [ $1 -ne 0 ];then
     action "$1"  /bin/false
     exit 1
  else
     action "$1"  /bin/true
  fi
}
if [ $# -eq 3 ];then
  Mysql_Sock=$3
  MysqlUser=$1
  MysqlPs=$2
  MysqlCMD="/application/mysql/bin/mysql -u$MysqlUser -p$MysqlPs -S $Mysql_Sock"
  MysqlDump="/application/mysql/bin/mysqldump -u$MysqlUser -p$MysqlPs -S $Mysql_Sock"
elif [ $# -eq 4 ];then
  Mysql_Host=$3
  MysqlUser=$1
  MysqlPs=$2
  Mysql_Port=$4
  MysqlCMD="/application/mysql/bin/mysql -u$MysqlUser -p$MysqlPs -h $Mysql_Host -P $Mysql_Port"
  MysqlDump="/application/mysql/bin/mysqldump -u$MysqlUser -p$MysqlPs -h $Mysql_Host -P $Mysql_Port"
else
  usage
fi
for Database in `$MysqlCMD -e "show databases;"|egrep -v "mysql|test|information_schema|performance_schema|Database"`
do
  mkdir /backup/$Database -p
  for Table in `$MysqlCMD -e "use $Database;show tables;"| grep -v "Tables_"`
  do
    $MysqlDump $Database $Table |gzip >/backup/$Database/${Database}-${Table}-`date +%F`.sql.gz
  done
done