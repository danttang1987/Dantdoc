# Cobbler 安装配置
> v 1.0<br>
> Create date:3/24/2019 11:11:28 PM <br>
> Creater:Zishan
## Cobbler 安装
####1、安装好Centos 7的操作系统，关闭防火墙和selinux
<pre>
systemctl stop firewalld
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
</pre>

####2、安装epol源
<pre>
rpm -ivh http://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm
</pre>

####3、yum安装Cobbler
<pre>
yum install -y httpd dhcp tftp cobbler cobbler-web pykickstart xinetd
</pre>

####4、启动cobbler
<pre>
systemctl start httpd
systemctl start cobblerd
systemctl start xinetd
cobbler check
</pre>
> 运行cobbler check后将列出cobbler需要配置和准备的内容

## Coobler 配置
###1、cobbler 基本配置
>运行如下命令完成Cobbler配置，IP地址请更换成环境相应的IP
<pre>
sed -i '/^next_server/s/127.0.0.1/192.168.237.200/' /etc/cobbler/settings
sed -i '/^server/s/127.0.0.1/192.168.237.200/' /etc/cobbler/settings
sed -i '/disable/s/yes/no/g' /etc/xinetd.d/tftp
systemctl start rsyncd
cobbler get-loaders
Pd=`openssl passwd -1 -salt 'zishan' '123.commm'`
sed -i '/^default_password_crypted:/d' /etc/cobbler/settings
echo "default_password_crypted:\"$Pd\"" >> /etc/cobbler/settings
sed -i '/^manage_dhcp/s/0/1/' /etc/cobbler/settings
</pre>

>配置完成后在使用cobbler check命令检查一次

###2、配置DHCP模板
>修改DHCP模板文件vim /etc/cobbler/dhcp.template

###3、重启并应用Cobbler配置
<pre>
systemctl restart cobblerd
cobbler sync
</pre>

##导入安装映像及编辑profile
###1、导入Centos操作系统映像
>将操作系统的ISO文件挂载到系统的/mnt下，执行如下命令.<br>
>注:--name后的名称就是profile的名称
<pre>
cobbler import --path=/mnt --name=centos-7-x86_64 --arch=x86_64
</pre>
>完成此命令后将操作系统导入到/var/www/cobbler/ks_mirror目录中。<br>
>导入完成后可使用如下命令查看profile
<pre>
cobbler profile
cobbler profile list
cobbler profile report
</pre>
###2、上传kickstart文件
>将Kickstart文件上传到/var/lib/cobbler/kickstarts/目录中<br>
>以下是Centos6和Centos7的kickstart文件模板

* Centos7
<pre>
#Kickstart Configurator for cobbler by centos 7
#platform=x86, AMD64, or Intel EM64T
#System  language
lang en_US
#System keyboard
keyboard us
#Sytem timezone
timezone Asia/Shanghai
#Root password
rootpw --iscrypted $default_password_crypted
#Use text mode install
text
#Install OS instead of upgrade
install
#Use NFS installation Media
url --url=$tree
#System bootloader configuration
bootloader --location=mbr
#Clear the Master Boot Record
zerombr
#Partition clearing information
clearpart --all --initlabel 
#Disk partitioning information
part /boot --fstype xfs --size 1024 --ondisk sda
part swap --size 16384 --ondisk sda
part / --fstype xfs --size 1 --grow --ondisk sda
#System authorization infomation
auth  --useshadow  --enablemd5 
#Network information
$SNIPPET('network_config')
#network --bootproto=dhcp --device=em1 --onboot=on
# Reboot after installation
reboot
#Firewall configuration
firewall --disabled 
#SELinux configuration
selinux --disabled
#Do not configure XWindows
skipx
#Package install information
%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
# Enable installation monitoring
$SNIPPET('pre_anamon')
%end

%packages
@ base
@ core
sysstat
iptraf
ntp
lrzsz
ncurses-devel
openssl-devel
zlib-devel
OpenIPMI-tools
mysql
nmap
screen
%end

%post
systemctl disable postfix.service
$yum_config_stanza
%end

</pre>

* Centos6
<pre>
#Kickstart Configurator for cobbler by Jason Zhao
#platform=x86, AMD64, or Intel EM64T
key --skip
#System  language
lang en_US
#System keyboard
keyboard us
#Sytem timezone
timezone Asia/Shanghai
#Root password
rootpw --iscrypted $default_password_crypted
#Use text mode install
text
#Install OS instead of upgrade
install
#Use NFS installation Media
url --url=$tree
#System bootloader configuration
bootloader --location=mbr
#Clear the Master Boot Record
zerombr yes
#Partition clearing information
clearpart --all --initlabel 
#Disk partitioning information
part /boot --fstype ext4 --size 1024 --ondisk sda
part swap --size 16384 --ondisk sda
part / --fstype ext4 --size 1 --grow --ondisk sda
#System authorization infomation
auth  --useshadow  --enablemd5 
#Network information
$SNIPPET('network_config')
#network --bootproto=dhcp --device=em1 --onboot=on
#Reboot after installation
reboot
#Firewall configuration
firewall --disabled 
#SELinux configuration
selinux --disabled
#Do not configure XWindows
skipx
#Package install information
%packages
@ base
@ chinese-support
@ core
sysstat
iptraf
ntp
e2fsprogs-devel
keyutils-libs-devel
krb5-devel
libselinux-devel
libsepol-devel
lrzsz
ncurses-devel
openssl-devel
zlib-devel
OpenIPMI-tools
mysql
lockdev
minicom
nmap

%post
#/bin/sed -i 's/#Protocol 2,1/Protocol 2/' /etc/ssh/sshd_config
/bin/sed  -i 's/^ca::ctrlaltdel:/#ca::ctrlaltdel:/' /etc/inittab
/sbin/chkconfig --level 3 diskdump off
/sbin/chkconfig --level 3 dc_server off
/sbin/chkconfig --level 3 nscd off
/sbin/chkconfig --level 3 netfs off
/sbin/chkconfig --level 3 psacct off
/sbin/chkconfig --level 3 mdmpd off
/sbin/chkconfig --level 3 netdump off
/sbin/chkconfig --level 3 readahead off
/sbin/chkconfig --level 3 wpa_supplicant off
/sbin/chkconfig --level 3 mdmonitor off
/sbin/chkconfig --level 3 microcode_ctl off
/sbin/chkconfig --level 3 xfs off
/sbin/chkconfig --level 3 lvm2-monitor off
/sbin/chkconfig --level 3 iptables off
/sbin/chkconfig --level 3 nfs off
/sbin/chkconfig --level 3 ipmi off
/sbin/chkconfig --level 3 autofs off
/sbin/chkconfig --level 3 iiim off
/sbin/chkconfig --level 3 cups off
/sbin/chkconfig --level 3 openibd off
/sbin/chkconfig --level 3 saslauthd off
/sbin/chkconfig --level 3 ypbind off
/sbin/chkconfig --level 3 auditd off
/sbin/chkconfig --level 3 rdisc off
/sbin/chkconfig --level 3 tog-pegasus off
/sbin/chkconfig --level 3 rpcgssd off
/sbin/chkconfig --level 3 kudzu off
/sbin/chkconfig --level 3 gpm off
/sbin/chkconfig --level 3 arptables_jf off
/sbin/chkconfig --level 3 dc_client off
/sbin/chkconfig --level 3 lm_sensors off
/sbin/chkconfig --level 3 apmd off
/sbin/chkconfig --level 3 sysstat off
/sbin/chkconfig --level 3 cpuspeed off
/sbin/chkconfig --level 3 rpcidmapd off
/sbin/chkconfig --level 3 rawdevices off
/sbin/chkconfig --level 3 rhnsd off
/sbin/chkconfig --level 3 nfslock off
/sbin/chkconfig --level 3 winbind off
/sbin/chkconfig --level 3 bluetooth off
/sbin/chkconfig --level 3 isdn off
/sbin/chkconfig --level 3 portmap off
/sbin/chkconfig --level 3 anacron off
/sbin/chkconfig --level 3 irda off
/sbin/chkconfig --level 3 NetworkManager off
/sbin/chkconfig --level 3 acpid off
/sbin/chkconfig --level 3 pcmcia off
/sbin/chkconfig --level 3 atd off
/sbin/chkconfig --level 3 sendmail off
/sbin/chkconfig --level 3 haldaemon off
/sbin/chkconfig --level 3 smartd off
/sbin/chkconfig --level 3 xinetd off
/sbin/chkconfig --level 3 netplugd off
/sbin/chkconfig --level 3 readahead_early off
/sbin/chkconfig --level 3 xinetd off
/sbin/chkconfig --level 3 ntpd on
/sbin/chkconfig --level 3 avahi-daemon off
/sbin/chkconfig --level 3 ip6tables off
/sbin/chkconfig --level 3 restorecond off
/sbin/chkconfig --level 3 postfix off
</pre>


###3、编辑profiler指定kickstart文件
<pre>
cobbler profile edit --name=centos-7-x86_64 --kickstart=/var/lib/cobbler/kickstarts/CentOS-7-x86_64.cfg
</pre>

###4、修改系统内核参数
>例如：Centos7网上命名修改
<pre>
cobbler profile edit --name=centos-7-x86_64 --kopts='net.ifnames=0 biosdevname=0'
</pre>

###5、应用配置
>使用如下命令应用配置后，就可以使用cobbler安装操作系统。
<pre>
cobbler sync
</pre>

##cobbler 自动重装系统

cobbler自动重装系统需要在重装的服务器上安装koan软件，执行如下命令完成系统自动重装

	rpm -ivh http://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm
	yum instll -y koan
	koan --server=cobblerIP --list=profile
	koan --replace-self --server=cobblerIP  --profile=centos6-x86_64
	reboot


##Cobbler创建私有YUM仓库
###1、创建yum仓库

	cobbler repo add --name=centos7-epel --mirror=https://mirrors.aliyun.com/epel/7/x86_64/ --arch=x86_64 --breed=yum
	cobbler repo add --name=centos6-epel --mirror=https://mirrors.aliyun.com/epel/6Server/x86_64/ --arch=x86_64 --breed=yum
>上面创建两个YUM仓库，一个Centos6的epel，一个Centos7的epel

###2、同步yum仓库
	
	cobbler reposync
	echo "1 3 * * * /usr/bin/cobbler reposync --tries=3 --no-fail" >>/var/spool/cron/root

###3、为profile指定私有yum仓库

	cobbler profile edit --name=centos7-x86_64 --repos="centos6-epel"
	cobbler profile edit --name=centos6-x86_64 --repos="centos6-epel"
	cobbler sync
>需要在profile使用的kickstart文件中启用私有yum,在kickstartk中的post里添加如下内容。 

	$yum_config_stanza

##Cobbler 自定义安装系统

	cobbler system add --name=linux-node3 --mac=00:0C:29:D3:34:B0 --profile=centos-7-x86_64 --ip-address=192.168.237.151 --subnet=255.255.255.0  --gateway=192.168.237.2  --interface=eth0 --static=1 --hostname=linux-node2  --name-servers=192.168.237.200 --kickstart=/var/lib/cobbler/kickstarts/CentOS-7-x86_64.cfg 
	cobbler sync






