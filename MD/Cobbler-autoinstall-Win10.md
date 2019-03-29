#Cobbler 安装Windows10
>v1.0<br>
>Create date:3/24/2019 10:42:49 PM <br>
>Creater:Zishan
##准备Windows引导PE
###1、下载工具
Windows ADK (分别下载 Download the Windows ADK for Windows 10, version 1809 和 Download the Windows PE add-on for the ADK)

https://go.microsoft.com/fwlink/?linkid=2026036

https://go.microsoft.com/fwlink/?linkid=2022233

安装以上两个工具，安装时只需要安装部署工具。

安装完成后启动【部署和映像工作环境】，并执行如下命令,完成PE的制作
<pre>
copype amd64 C:\winpe

Dism /mount-image /imagefile:C:\winpe\media\sources\boot.wim /index:1 /mountdir:C:\winpe\mount

echo net use z:\\cobbler.zishan.com\share >> C:\winpe\mount\Windows\System32\startnet.cmd
echo z:\win\setup.exe /unattend:z:\win\win10_x64_bios_auto.xml >> C:\winpe\mount\Windows\System32\startnet.cmd

Dism /unmount-image /mountdir:C:\winpe\mount /commit
MakeWinPEMedia /ISO C:\winpe C:\winpe\winpe_win10_amd64.iso
</pre>

>1. 本地生成winpe文件目录<br>
>2. dism 挂载 winpe的启动文件到winpe的mount目录<br>
>3. 将启动命令硬编码写死到winpe的startnet.cmd文件里<br>
>4. 无人值守安装<br>
>5. 卸载winpe的挂载（一定要执行，否则直接强制删除文件夹会出一些稀奇古怪的问题）<br>
>6. 制作win10镜像，名为 winpe_win10_amd64.iso<br>

###2、创建自动应答文件

创建自动应答文件(win10_x64_bios_auto.xml)

可通过如下网站创建

http://www.windowsafg.com/win10x86_x64.html

应答文件创建完成后需要如下两个地方
>1. 应答文件中的Key需要与将要实现无人值守安装的系统的Key一样，否则会出现找不到可以安装的操作系统映像问题。<br>
>Windows 10 Pro: VK7JG-NPHTM-C97JM-9MPGT-3V66T<br>
Windows 10 Home: TX9XD-98N7V-6WMQ6-BX7FG-H8Q99<br>
Windows 10 Enterprise: NPPR9-FWDCX-D2C8J-H872K-2YT43<br>
Windows 10 Enterprise LTSR:M7XTQ-FN8P6-TTKYV-9D4CC-J462D<br>
>2. 应答文件中的语言如安装中文操作系统除了<SetupUILanguage\>中的UILanguage中的使用en-US外，其他都要使用zh-CN。否则会停在选择语言界面。

##cobbler配置
Cobbler安装配置完成后，将上面制作的PE镜像上传到服务器的/root/,在cobbler服务器上执行如下命令：
<pre>
cobbler distro add --name=windows_10_x64 --kernel=/var/lib/tftpboot/memdisk --initrd=/root/winpe_win10_amd64.iso --kopts="raw iso"
touch /var/lib/cobbler/kickstarts/winpe.xml
cobbler profile add --name=windows_10_x64 --distro=windows_10_x64 --kickstart=/var/lib/cobbler/kickstarts/winpe.xml
cobbler sync
</pre>

>1. 使用PE镜像文件创建一个distro,创建完成后将会把winpe_win10_amd64.iso和memdisk文件复制到/var/www/cobbler/image下。
>2. 创建一个空的kickstart文件
>3. 使用distro和kickstart创建一个profile。

##安装配置smb服务器
###1、smb服务器的安装配置
执行如下命令完成smb服务器的安装配置

    yum install samba -y
    mkdir -p /smb/win
    cat > /etc/samba/smb.conf <<EOF
    [global]
    log file = /var/log/samba/log.%m
    max log size = 5000
    security = user
    guest account = nobody
    map to guest = Bad User
    load printers = yes
    cups options = raw
     
    [share]
    comment = share directory
    path = /smb/
    directory mask = 0755
    create mask = 0755
    guest ok=yes
    writable=yes
    EOF
	service smb start
	systemctl enable smb

将Windows 10的系统映像文件挂载到服务器上，并将文件拷贝到/smb/win中。
将自动应答文件上到服务器/smb/win中

	mount -o loop,ro /tmp/cn_windows_10_business_edition_version_1809_updated_sept_2018_x64_dvd_84ac403f.iso /mnt/
	cp -r /mnt/* /smb/win

##配置DNS服务
>由于在制作PE映像时使用了cobbler.zishan.com这个域名，所以需要安装DNS服务
使用如下命令安装配置DNS

	yum install bind bind-chroot
	echo 'include "/etc/named/named.conf.local";'>>/etc/named.conf
	mkdir /etc/named/zones
	cat >/etc/named/named.conf.local <<EOF
	zone "zishan.com" {
	    type master;
	    file "/etc/named/zones/db.zishan.com"; # zone file path
	};
	EOF
	
	cat >/etc/named/zones/db.zishan.com <<EOF
	$TTL	604800
	@       IN      SOA   @   cobbler.zishan.com. (
			      3     ; Serial
			 604800     ; Refresh
			  86400     ; Retry
			2419200     ; Expire
			 604800 )   ; Negative Cache TTL
	
	; name servers - NS records
			IN      NS      cobbler.zishan.com.
	
	; name servers - A records
	cobbler.zishan.com.          IN      A      192.168.237.200
	EOF

>配置完成后就可以安装Windows10操作系统，如系统重启后需要启动如下服务。

	systemctl start httpd
	systemctl start dhcpd
	systemctl start xinetd
	systemctl start rsyncd
	systemctl start named
	systemctl start named-chroot
	systemctl start cobblerd
	systemctl start smb





