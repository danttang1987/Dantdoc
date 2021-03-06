#/bin/bash
. /etc/rc.d/init.d/functions
usage(){
   echo "usage: $0 username password host/ip port or $0 username password sock"
   exit 1
}
check_up(){
   if [ $1 -ne 0 ];then
       action "$2"   /bin/false
	   exit 1
   else
       action "$2"   /bin/true
   fi
}
if [ $# -eq 3 ];then
    mysqlcmd="/application/mysql/bin/mysql -u$1 -p$2 -S $3"
fi
if [ $# -eq 4 ];then
    mysqlcmd="/application/mysql/bin/mysql -u$1 -p$2 -h $3  -P $4"
fi
if [ $# -ne 4 -a $# -ne 3 ];then
    usage
fi

$mysqlcmd -e "show processlist;"|grep -v ^Id >a.txt 
check_up $? "list mysql process"
sleep 2
$mysqlcmd -e "show processlist;"|grep -v ^Id >>a.txt 
echo "this is same host and command for 2 s:"
cat a.txt |gawk -F '\t' '{a[$3,$NF]++} END{for (c in a) {split(c,px,SUBSEP);print a[px[1],px[2]]" "px[1]" "px[2]}}'|sort -nr