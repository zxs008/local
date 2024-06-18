#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

sed -i 's/[0-9\.]\+[ ]\+www.bt.cn//g' /etc/hosts
sed -i 's/[0-9\.]\+[ ]\+auth.bt.sy//g' /etc/hosts

if [ ! -d /www/server/panel/BTPanel ];then
	echo "============================================="
	echo "错误, 5.x不可以使用此命令升级!"
	echo "5.9平滑升级到6.0的命令：curl http://download.bt.sy/install/update_to_6.sh|bash"
	exit 0;
fi

download_Url=$NODE_URL
downloads_Url=https://zxs008.github.io/local/linux/kxbt

public_file=/www/server/panel/install/public.sh
publicFileMd5=$(md5sum ${public_file} 2>/dev/null|awk '{print $1}')
md5check="a70364b7ce521005e7023301e26143c5"
if [ "${publicFileMd5}" != "${md5check}"  ]; then
	wget -O Tpublic.sh $downloads_Url/public.sh -T 20;
	publicFileMd5=$(md5sum Tpublic.sh 2>/dev/null|awk '{print $1}')
	if [ "${publicFileMd5}" == "${md5check}"  ]; then
		\cp -rpa Tpublic.sh $public_file
	fi
	rm -f Tpublic.sh
fi
. $public_file

Centos8Check=$(cat /etc/redhat-release | grep ' 8.' | grep -iE 'centos|Red Hat')
if [ "${Centos8Check}" ];then
	if [ ! -f "/usr/bin/python" ] && [ -f "/usr/bin/python3" ] && [ ! -d "/www/server/panel/pyenv" ]; then
		ln -sf /usr/bin/python3 /usr/bin/python
	fi
fi

mypip="pip"
env_path=/www/server/panel/pyenv/bin/activate
if [ -f $env_path ];then
	mypip="/www/server/panel/pyenv/bin/pip"
fi

setup_path=/www
version=$(curl -Ss --connect-timeout 5 -m 2 $downloads_Url/get_version)
if [ "$version" = '' ];then
	version='7.7.0'
fi

wget -T 5 -O /tmp/panel.zip https://github.com/zxs008/local/releases/download/btpanel/LinuxPanel-${version}.zip
#wget -T 5 -O /tmp/panel.zip $downloads_Url/install/update/LinuxPanel-7.7.0.zip
dsize=$(du -b /tmp/panel.zip|awk '{print $1}')
if [ $dsize -lt 10240 ];then
	echo "获取更新包失败！"
	exit;
fi
rm -rf /www/server/panel/class/PluginLoader.cpython-37m-aarch64-linux-gnu.so
rm -rf /www/server/panel/class/PluginLoader.cpython-37m-x86_64-linux-gnu.so
rm -rf /www/server/panel/class/PluginLoader.so
rm -rf /www/server/panel/class/pluginAuth.cpython-37m-aarch64-linux-gnu.so
rm -rf /www/server/panel/class/pluginAuth.cpython-37m-x86_64-linux-gnu.so
rm -rf /www/server/panel/class/pluginAuth.so
rm -rf /www/server/panel/pyenv/lib/python3.7/site-packages/requests/api.py.bak
unzip -o /tmp/panel.zip -d $setup_path/server/ > /dev/null
chattr -i /www/server/panel/data/userInfo.json
wget -T 5 -O /www/server/panel/pyenv/lib/python3.7/site-packages/requests/api.py $downloads_Url/api.py
rm -f /tmp/panel.zip
cd $setup_path/server/panel/
check_bt=`cat /etc/init.d/bt`
if [ "${check_bt}" = "" ];then
	rm -f /etc/init.d/bt
	wget -O /etc/init.d/bt $downloads_Url/bt6.init -T 20
	#sed -i 's/[0-9\.]\+[ ]\+www.bt.cn//g' /etc/hosts
	chmod +x /etc/init.d/bt
fi
rm -f /www/server/panel/*.pyc
rm -f /www/server/panel/class/*.pyc
#pip install flask_sqlalchemy
#pip install itsdangerous==0.24

pip_list=$($mypip list)
request_v=$(echo "$pip_list"|grep requests)
if [ "$request_v" = "" ];then
	$mypip install requests
fi
openssl_v=$(echo "$pip_list"|grep pyOpenSSL)
if [ "$openssl_v" = "" ];then
	$mypip install pyOpenSSL
fi

#cffi_v=$(echo "$pip_list"|grep cffi|grep 1.12.)
#if [ "$cffi_v" = "" ];then
#	$mypip install cffi==1.12.3
#fi

pymysql=$(echo "$pip_list"|grep pymysql)
if [ "$pymysql" = "" ];then
	$mypip install pymysql
fi

pymysql=$(echo "$pip_list"|grep pycryptodome)
if [ "$pymysql" = "" ];then
	$mypip install pycryptodome
fi

#psutil=$(echo "$pip_list"|grep psutil|awk '{print $2}'|grep '5.7.')
#if [ "$psutil" = "" ];then
#	$mypip install -U psutil
#fi

if [ -d /www/server/panel/class/BTPanel ];then
	rm -rf /www/server/panel/class/BTPanel
fi

chattr -i /etc/init.d/bt
chmod +x /etc/init.d/bt
echo "====================================="
rm -f /dev/shm/bt_sql_tips.pl
rm -rf /www/server/panel/data/bind.pl
kill $(ps aux|grep -E "task.pyc|main.py"|grep -v grep|awk '{print $2}')
/www/server/panel/pyenv/bin/pip install -U Flask==2.1.3
/etc/init.d/bt start
echo 'True' > /www/server/panel/data/restart.pl
pkill -9 gunicorn &
echo "已成功升级到[$version]企业版";


