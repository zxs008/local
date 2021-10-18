#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
export tmpVER=''
export tmpDIST=''
export tmpWORD='Passwd@Linux'
export tmpTerritory=''
export tmpMirror=''
export Relese=''
export isMirror='0'
export ddMode='0'
export tmpURL=''
export ipAddr=''
export ipMask=''
export ipGate=''

while [[ $# -ge 1 ]]; do
  case $1 in
    -v|--ver)
      shift
      tmpVER="$1"
      shift
      ;;
    -d|--debian)
      shift
      Relese='Debian'
      tmpDIST="$1"
      shift
      ;;
    -u|--ubuntu)
      shift
      Relese='Ubuntu'
      tmpDIST="$1"
      shift
      ;;
    -c|--centos)
      shift
      Relese='CentOS'
      tmpDIST="$1"
      shift
      ;;
    -f|--fedora)
      shift
      Relese='Fedora'
      tmpDIST="$1"
      shift
      ;;
    -dd|--image)
      shift
      ddMode='1'
      tmpURL="$1"
      shift
      ;;
    -p|--password)
      shift
      tmpWORD="$1"
      shift
      ;;
	-t|--territory)
      shift
      tmpTerritory="$1"
      shift
      ;;
	--ip-addr)
      shift
      ipAddr="$1"
      shift
      ;;
    --ip-mask)
      shift
      ipMask="$1"
      shift
      ;;
    --ip-gate)
      shift
      ipGate="$1"
      shift
      ;;
    --mirror)
      shift
      isMirror='1'
      tmpMirror="$1"
      shift
      ;;
    *)
      if [[ "$1" != 'error' ]]; then echo -ne "\nInvaild option: '$1'\n\n"; fi
      echo -ne " Usage:\n\tbash $(basename $0)\t-d/--debian [dists-name]\n\t\t-u/--ubuntu [dists-name]\n\t\t-c/--centos [dists-verison]\n\t\t-f/--fedora [dists-verison]\n\t\t-dd/--image\n\t\t--mirror\n"
      exit 1;
      ;;
    esac
  done

[[ "$EUID" -ne '0' ]] && echo "Error:This script must be run as root!" && exit 1;

if [[ "$Relese" == 'CentOS' ]]; then
	#minimum 2G memory.
	total_memory=$(awk '($1 == "MemTotal:"){print $2}' /proc/meminfo)
	if [ $total_memory -lt 1800000 ]; then
		echo -e "\n\033[31mError: \033[0mnetwork reinstall minimum 2G memory.";
		exit 1;
	fi
fi

#Remove QCloud servies
[[ -f /usr/local/qcloud/YunJing/uninst.sh ]] && echo -e "\nUninstall qcloud yunjing" && bash /usr/local/qcloud/YunJing/uninst.sh >>/dev/null 2>&1
[[ -f /usr/local/qcloud/stargate/admin/uninstall.sh ]] && echo -e "\nUninstall qcloud stargate" && bash /usr/local/qcloud/stargate/admin/uninstall.sh >>/dev/null 2>&1
[[ -f /usr/local/qcloud/monitor/barad/admin/uninstall.sh ]] && echo -e "\nUninstall qcloud monitor" && bash /usr/local/qcloud/monitor/barad/admin/uninstall.sh >>/dev/null 2>&1

#Disabled SELinux
if [ -f /etc/selinux/config ]; then
	SELinuxStatus=$(sestatus -v | grep "SELinux status:" | grep enabled)
	[[ "$SELinuxStatus" != "" ]] && echo -e "\033[36mDisabled SELinux\033[0m" && setenforce 0
fi

#Current relese and platform
CurrentRelese=''
Ubuntu=$(cat /proc/version | grep Ubuntu)
Debian=$(cat /proc/version | grep Debian)
CentOS='';
Fedora='';
[[ -f /etc/redhat-release ]] && CentOS=$(cat /etc/redhat-release | grep CentOS)
[[ -f /etc/redhat-release ]] && Fedora=$(cat /etc/redhat-release | grep Fedora)
if [[ "$Ubuntu" != "" ]]; then
	CurrentRelese="Ubuntu";
elif [[ "$Debian" != "" ]]; then
	CurrentRelese="Debian";
elif [[ "$CentOS" != "" ]]; then
	CurrentRelese="CentOS";
elif [[ "$Fedora" != "" ]]; then
	CurrentRelese="Fedora";
else
	echo -e "Only supported \033[36mCentOS\033[0m, \033[36mFedora\033[0m, \033[36mUbuntu\033[0m and \033[36mDebian\033[0m.";
	exit 1;
fi
PLATFORM=$(uname -i);
[[ "$PLATFORM" == "unknown" ]] && PLATFORM=$(uname -m)

#选择镜像函数
function SelectMirror(){
	[ $# -ge 3 ] || exit 1
	Relese="$1"
	DIST=$(echo "$2" |sed 's/\ //g' |sed -r 's/(.*)/\L\1/')
	PLATFORM=$(echo "$3" |sed 's/\ //g' |sed -r 's/(.*)/\L\1/')
	New=$(echo "$4" |sed 's/\ //g')
	[ -n "$Relese" ] || exit 1
	[ -n "$DIST" ] || exit 1
	[ -n "$PLATFORM" ] || exit 1
	relese=$(echo $Relese |sed -r 's/(.*)/\L\1/')
	if [ "$Relese" == "Debian" ] || [ "$Relese" == "Ubuntu" ]; then
		inUpdate=''; [ "$Relese" == "Ubuntu" ] && inUpdate='-updates'	
		imagesPart='images'; 
		if [ "$DIST" == "focal" ] || [ "$DIST" == "hirsute" ]; then
			imagesPart='legacy-images'
		fi
		MirrorTEMP="SUB_MIRROR/dists/${DIST}${inUpdate}/main/installer-${PLATFORM}/current/${imagesPart}/netboot/${relese}-installer/${PLATFORM}/initrd.gz"
	elif [ "$Relese" == "CentOS" ]; then
		if [[ "$DIST" =~ ^8.* ]]; then
			MirrorTEMP="SUB_MIRROR/${DIST}/BaseOS/${PLATFORM}/os/isolinux/initrd.img"
		else
			MirrorTEMP="SUB_MIRROR/${DIST}/os/${PLATFORM}/isolinux/initrd.img"
		fi    
	elif [ "$Relese" == "Fedora" ]; then
		MirrorTEMP="SUB_MIRROR/releases/${DIST}/Server/${PLATFORM}/os/isolinux/initrd.img"   
	fi
	[ -n "$MirrorTEMP" ] || exit 1
	MirrorStatus=0
	declare -A MirrorBackup
	ping -c 1 www.google.com >>/dev/null 2>&1
	if [[ $? != 0 ]] || [[ "$tmpTerritory" == "cn" ]]; then
	    MirrorBackup=(["Debian0"]="" ["Debian1"]="https://mirrors.aliyun.com/debian" ["Debian2"]="http://mirrors.163.com/debian-archive" ["Ubuntu0"]="" ["Ubuntu1"]="https://mirrors.aliyun.com/ubuntu" ["CentOS0"]="" ["CentOS1"]="https://mirrors.aliyun.com/centos" ["CentOS2"]="https://mirrors.aliyun.com/centos-vault" ["Fedora0"]="" ["Fedora1"]="https://mirrors.aliyun.com/fedora")
	else	
		MirrorBackup=(["Debian0"]="" ["Debian1"]="http://deb.debian.org/debian" ["Debian2"]="http://archive.debian.org/debian" ["Ubuntu0"]="" ["Ubuntu1"]="http://archive.ubuntu.com/ubuntu" ["Ubuntu2"]="http://ports.ubuntu.com" ["CentOS0"]="" ["CentOS1"]="http://mirror.centos.org/centos" ["CentOS2"]="http://vault.centos.org" ["Fedora0"]="" ["Fedora1"]="https://mirrors.aliyun.com/fedora")	
	fi
	echo "$New" |grep -q '^http://\|^https://\|^ftp://' && MirrorBackup[${Relese}0]="$New"
	for mirror in $(echo "${!MirrorBackup[@]}" |sed 's/\ /\n/g' |sort -n |grep "^$Relese")
    do
		CurMirror="${MirrorBackup[$mirror]}"
		[ -n "$CurMirror" ] || continue
		MirrorURL=`echo "$MirrorTEMP" |sed "s#SUB_MIRROR#${CurMirror}#g"`
		wget --no-check-certificate --spider --timeout=3 -o /dev/null "$MirrorURL"
		[ $? -eq 0 ] && MirrorStatus=1 && break
    done
  [ $MirrorStatus -eq 1 ] && echo "$CurMirror" || exit 1
}

#检查依赖函数
function CheckDependence(){
FullDependence='0';
for BIN_DEP in `echo "$1" |sed 's/,/\n/g'`
  do
    if [[ -n "$BIN_DEP" ]]; then
      Founded='0';
      for BIN_PATH in `echo "$PATH" |sed 's/:/\n/g'`
        do
          ls $BIN_PATH/$BIN_DEP >/dev/null 2>&1;
          if [ $? == '0' ]; then
            Founded='1';
            break;
          fi
        done
      if [ "$Founded" == '1' ]; then
        echo -en "[\033[32mok\033[0m]\t";
      else
        FullDependence='1';
        echo -en "[\033[31mNot Install\033[0m]";
      fi
      echo -en "\t$BIN_DEP\n";
    fi
  done
if [ "$FullDependence" == '1' ]; then
	echo -ne "\n\033[31mError! \033[0mPlease use '\033[33mapt\033[0m' or '\033[33myum\033[0m' install it.\n\n\n"
	exit 1;
fi
}

clear

#是否DD系统
if [[ "$ddMode" == '1' ]]; then
	echo -e "\n\033[36m# Check $tmpURL\033[0m";
	if [[ -n "$tmpURL" ]]; then
		DDURL="$tmpURL"
		echo "$DDURL" |grep -q '^http://\|^ftp://\|^https://';
		[[ $? -ne '0' ]] && echo 'Please input vaild URL,Only support http://, ftp:// and https:// !' && exit 1;
		wget --no-check-certificate --spider --timeout=3 -o /dev/null "$DDURL"
		[[ $? -ne '0' ]] && echo 'Please input vaild image URL! ' && exit 1;
	else
		echo 'Please input vaild image URL! ';
		exit 1;
	fi

	Relese='Debian';
	tmpDIST='bullseye';
fi

#系统平台
if [[ "$Relese" == "Ubuntu" ]] || [[ "$Relese" == "Debian" ]]; then
	if [[ "$PLATFORM" == "x86_64" ]] || [[ "$PLATFORM" == "x64" ]] || [[ "$PLATFORM" == "64" ]]; then
		PLATFORM="amd64"
	elif [[ "$PLATFORM" == '32' ]] || [[ "$PLATFORM" == 'i386' ]] || [[ "$PLATFORM" == 'x86' ]]; then
		PLATFORM="i386"
	fi
fi

#判断默认值
if [[ -z "$tmpDIST" ]]; then
  [ "$Relese" == 'Debian' ] && tmpDIST='bullseye' && DIST='bullseye';
  [ "$Relese" == 'Ubuntu' ] && tmpDIST='focal' && DIST='focal';
  [ "$Relese" == 'CentOS' ] && tmpDIST='8' && DIST='8';
  [ "$Relese" == 'Fedora' ] && tmpDIST='34' && DIST='34';
fi

[ -n "$Relese" ] || Relese='Debian'
linux_relese=$(echo "$Relese" |sed 's/\ //g' |sed -r 's/(.*)/\L\1/')
echo -e "\n\033[36m# Check Dependence\033[0m\n"

#检查依赖项
if [[ "$Relese" == 'Debian' ]] || [[ "$Relese" == 'Ubuntu' ]]; then
	if [[ "$ddMode" == '1' ]]; then
		CheckDependence iconv;
	fi
	CheckDependence wget,awk,grep,sed,cut,cat,cpio,gzip,find,dirname,basename,openssl;
elif [[ "$Relese" == 'CentOS' ]] || [[ "$Relese" == 'Fedora' ]]; then
	CheckDependence wget,awk,grep,sed,cut,cat,cpio,gzip,find,dirname,basename,file,xz,openssl;
fi

#安装的版本号
if [[ -z "$DIST" ]]; then
  if [[ "$Relese" == 'Debian' ]]; then
    SpikCheckDIST='0'
    DIST="$(echo "$tmpDIST" |sed -r 's/(.*)/\L\1/')";
    echo "$DIST" |grep -q '[0-9]';
    [[ $? -eq '0' ]] && {
      isDigital="$(echo "$DIST" |grep -o '[\.0-9]\{1,\}' |sed -n '1h;1!H;$g;s/\n//g;$p' |cut -d'.' -f1)";
      [[ -n $isDigital ]] && {
        [[ "$isDigital" == '9' ]] && DIST='stretch';
        [[ "$isDigital" == '10' ]] && DIST='buster';
        [[ "$isDigital" == '11' ]] && DIST='bullseye';
        [[ "$isDigital" == '12' ]] && DIST='bookworm';
      }
    }
    LinuxMirror=$(SelectMirror "$Relese" "$DIST" "$PLATFORM" "$tmpMirror")
  fi
  if [[ "$Relese" == 'Ubuntu' ]]; then
    SpikCheckDIST='0'
    DIST="$(echo "$tmpDIST" |sed -r 's/(.*)/\L\1/')";
    echo "$DIST" |grep -q '[0-9]';
    [[ $? -eq '0' ]] && {
      isDigital="$(echo "$DIST" |grep -o '[\.0-9]\{1,\}' |sed -n '1h;1!H;$g;s/\n//g;$p')";
      [[ -n $isDigital ]] && {
        [[ "$isDigital" == '18.04' ]] && DIST='bionic';
        [[ "$isDigital" == '20.04' ]] && DIST='focal';
        [[ "$isDigital" == '21.04' ]] && DIST='hirsute';
      }
    }
    LinuxMirror=$(SelectMirror "$Relese" "$DIST" "$PLATFORM" "$tmpMirror")
  fi
  if [[ "$Relese" == 'CentOS' ]]; then
    SpikCheckDIST='1'
    DISTCheck="$(echo "$tmpDIST" |grep -o '[\.0-9]\{1,\}')";
    LinuxMirror=$(SelectMirror "$Relese" "$DISTCheck" "$PLATFORM" "$tmpMirror")
    ListDIST="$(wget --no-check-certificate -qO- "$LinuxMirror/dir_sizes" |cut -f2 |grep '^[0-9]')"
    DIST="$(echo "$ListDIST" |grep "^$DISTCheck" |head -n1)"
    [[ -z "$DIST" ]] && {
      echo -ne '\n\033[31mError! \033[0mThe dists version not found in this mirror, Please check it! \n\n'
      bash $0 error;
      exit 1;
    }
  fi
  if [[ "$Relese" == 'Fedora' ]]; then
    SpikCheckDIST='1'
    DIST="$(echo "$tmpDIST" |sed -r 's/(.*)/\L\1/')";
    LinuxMirror=$(SelectMirror "$Relese" "$DIST" "$PLATFORM" "$tmpMirror")
  fi
fi

#网络安装检查版本号是否存在/正确性
if [[ "$SpikCheckDIST" == '0' ]]; then
	echo -e "\n\033[36mCheck DIST\033[0m";
	DistsList="$(wget --no-check-certificate -qO- "$LinuxMirror/dists/" |grep -o 'href=.*/"' |cut -d'"' -f2 |sed '/-\|old\|Debian\|experimental\|stable\|test\|sid\|devel/d' |grep '^[^/]' |sed -n '1h;1!H;$g;s/\n//g;s/\//\;/g;$p')";
	for CheckDEB in `echo "$DistsList" |sed 's/;/\n/g'`
	do
		[[ "$CheckDEB" == "$DIST" ]] && FindDists='1' && break;
	done
	[[ "$FindDists" == '0' ]] && {
		echo -ne '\n\033[31mError! \033[0mThe dists version not found, Please check it! \n\n'
		bash $0 error;
		exit 1;
	}
	echo -e "\nSuccess";
fi

GRUBDIR=""
GRUBFILE=""
GRUBVER=""
[[ -f '/boot/grub/grub.cfg' ]] && GRUBVER='0' && GRUBDIR='/boot/grub' && GRUBFILE='grub.cfg';
[[ -z "$GRUBDIR" ]] && [[ -f '/boot/grub2/grub.cfg' ]] && GRUBVER='0' && GRUBDIR='/boot/grub2' && GRUBFILE='grub.cfg';
[[ -z "$GRUBDIR" ]] && [[ -f '/boot/grub/grub.conf' ]] && GRUBVER='1' && GRUBDIR='/boot/grub' && GRUBFILE='grub.conf';
[ -z "$GRUBDIR" -o -z "$GRUBFILE" ] && echo -ne "Error! \nNot Found grub.\n" && exit 1;

[[ "$GRUBVER" == "1" ]] && [[ "$(awk '/^export linux_gfx_mode/' $GRUBDIR/$GRUBFILE)" != "" ]] && GRUBVER="0";

#Network config
DEFAULTNET=$(ip route show |grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.*' |head -n1 |sed 's/proto.*\|onlink.*//g' |awk '{print $NF}');
PASSWORD="$(openssl passwd -1 "$tmpWORD")"
[ -n "$ipAddr" ] && MAINIP="$ipAddr" || MAINIP=$(ip route get 1 | awk '{print $7;exit}')
[ -n "$ipGate" ] && GATEWAYIP="$ipGate" || GATEWAYIP=$(ip route | grep default | awk '{print $3}')
SUBNET=$(ip -o -f inet addr show | awk '/scope global/{sub(/[^.]+\//,"0/",$4);print $4}' | head -1 | awk -F '/' '{print $2}')
value=$(( 0xffffffff ^ ((1 << (32 - $SUBNET)) - 1) ))
[ -n "$ipMask" ] && NETMASK="$ipMask" || NETMASK="$(( (value >> 24) & 0xff )).$(( (value >> 16) & 0xff )).$(( (value >> 8) & 0xff )).$(( value & 0xff ))"

#DNS
NAMESERVER="8.8.8.8 8.8.4.4" #Aliyun DNS
if [[ "$CurrentRelese" == "CentOS" ]] || [[ "$CurrentRelese" == "Debian" ]]; then
	NAMESERVER=$(awk '/^nameserver/{print $2}' /etc/resolv.conf | tr "\n" " " | awk '{gsub(/^\s+|\s+$/, "");print}')
elif [[ -f /run/systemd/resolve/resolv.conf ]]; then
	NAMESERVER=$(cat /run/systemd/resolve/resolv.conf | awk '/^nameserver/{print $2}' | tr "\n" " " | awk '{gsub(/^\s+|\s+$/, "");print}')
elif [[ -f /run/systemd/resolve/stub-resolv.conf ]]; then
	NAMESERVER=$(cat /run/systemd/resolve/resolv.conf | awk '/^nameserver/{print $2}' | tr "\n" " " | awk '{gsub(/^\s+|\s+$/, "");print}')
else 
	ping -c 1 www.google.com >>/dev/null 2>&1
	if [[ $? == 0 ]];then
		NAMESERVER="8.8.8.8 8.8.4.4" #Cloudflare Google DNS
	else
		delay=$(ping -c 3 mirrors.aliyun.com | grep "min/avg/max" | awk -F '=' '{print $2}' | awk -F '/' '{print $2}' | awk '{gsub(/^\s+|\s+$/, "");print}')
		if [[ "$delay" != "" ]] && [[ $delay < 2.0 ]];then
			NAMESERVER="223.5.5.5 223.6.6.6" #Tencent cloud DNS
		fi
	fi
fi

#Disable IPv6
NOIPV6=""
ping6 -c 1 ipv6.baidu.com >>/dev/null 2>&1
if [[ $? != 0 ]];then    
	ping6 -c 1 ipv6.google.com >>/dev/null 2>&1
	if [[ $? != 0 ]];then
		NOIPV6="ipv6.disable=1"
	fi
fi

#proto
PROTO='dhcp'
PROTOStr=$(ip route show | grep  -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.*' | grep proto)
if [ "$PROTOStr" != "" ]; then
	static=$(ip route show | grep  -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.*' | grep 'proto static')
	if [ "$static" != "" ]; then
		PROTO="static"
	fi
elif [ -f /etc/sysconfig/network-scripts/ifcfg-$DEFAULTNET ]; then
	device=$(cat /etc/sysconfig/network-scripts/ifcfg-$DEFAULTNET | grep DEVICE | grep $DEFAULTNET)
	if [ "$device" != "" ]; then
		static=$(cat /etc/sysconfig/network-scripts/ifcfg-$DEFAULTNET | grep BOOTPROTO | grep static)
		if [ "$static" != "" ]; then
			PROTO="static"
		fi
	fi
elif [ -f /etc/netplan/01-netcfg.yaml ]; then
	device=$(cat /etc/netplan/01-netcfg.yaml | grep $DEFAULTNET)
	if [ "$device" != "" ]; then
		static=$(cat /etc/netplan/01-netcfg.yaml | grep "dhcp4: no")
		if [ "$static" == "" ]; then
			PROTO="static"
		fi
	fi
elif [ -f /etc/network/interfaces ]; then
	static=$(cat /etc/network/interfaces | grep "iface $DEFAULTNET inet static")
	if [ "$static" != "" ]; then
		PROTO="static"
	elif [ "`ls -A /etc/network/interfaces.d`" != "" ]; then
		for config in $(ls -A /etc/network/interfaces.d)
		do
			if [ -f /etc/network/interfaces.d/$config ]; then
				static=$(cat /etc/network/interfaces.d/$config | grep "iface $DEFAULTNET inet static");
				if [ "$static" != "" ]; then
					PROTO="static"
					break;
				fi
			fi
		done
	fi
fi

#输入IP,网关等信息
echo  -e "\n\033[36m# Network config\033[0m"
echo "hostname: $(hostname)";
echo "proto: $PROTO"
echo "ip: $MAINIP/$SUBNET";
echo "gateway: $GATEWAYIP";
echo "netmask: $NETMASK";
echo "nameserver: $NAMESERVER";
[[ "$NOIPV6" != "" ]] && echo "IPv6 is not supported";

#下载img
echo -e "\n[\033[33m$Relese\033[0m] [\033[33m$DIST\033[0m] [\033[33m$PLATFORM\033[0m] Downloading..."
[[ -d /boot/netboot ]] && rm -rf /boot/netboot
mkdir /boot/netboot && cd /boot/netboot
if [[ "$linux_relese" == 'debian' ]] || [[ "$linux_relese" == 'ubuntu' ]]; then
	inUpdate=''; [ "$linux_relese" == 'ubuntu' ] && inUpdate='-updates'
	imagesPart='images'; 
	if [[ "$DIST" == "focal" ]] || [[ "$DIST" == "hirsute" ]] ; then
		imagesPart='legacy-images'
	fi
	wget --no-check-certificate -qO 'initrd.img' "${LinuxMirror}/dists/${DIST}${inUpdate}/main/installer-${PLATFORM}/current/${imagesPart}/netboot/${linux_relese}-installer/${PLATFORM}/initrd.gz"
	[[ $? -ne '0' ]] && echo "$LinuxMirror $linux_relese $Relese $DIST $PLATFORM" && echo -ne "\033[31mError! \033[0mDownload 'initrd.img' for \033[33m$linux_relese\033[0m failed! \n" && exit 1
	wget --no-check-certificate -qO 'vmlinuz' "${LinuxMirror}/dists/${DIST}${inUpdate}/main/installer-${PLATFORM}/current/${imagesPart}/netboot/${linux_relese}-installer/${PLATFORM}/linux"
	[[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'vmlinuz' for \033[33m$linux_relese\033[0m failed! \n" && exit 1
	MirrorHost="$(echo "$LinuxMirror" |awk -F'://|/' '{print $2}')";
	MirrorFolder="$(echo "$LinuxMirror" |awk -F''${MirrorHost}'' '{print $2}')";
elif [[ "$linux_relese" == 'centos' ]]; then
	if [[ "$DIST" =~ ^8.* ]]; then
		wget --no-check-certificate -qO 'initrd.img' "${LinuxMirror}/${DIST}/BaseOS/${PLATFORM}/os/isolinux/initrd.img"
		[[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'initrd.img' for \033[33m$linux_relese\033[0m failed! \n" && exit 1
		wget --no-check-certificate -qO 'vmlinuz' "${LinuxMirror}/${DIST}/BaseOS/${PLATFORM}/os/isolinux/vmlinuz"
		[[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'vmlinuz' for \033[33m$linux_relese\033[0m failed! \n" && exit 1
	else
		wget --no-check-certificate -qO 'initrd.img' "${LinuxMirror}/${DIST}/os/${PLATFORM}/isolinux/initrd.img"
		[[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'initrd.img' for \033[33m$linux_relese\033[0m failed! \n" && exit 1
		wget --no-check-certificate -qO 'vmlinuz' "${LinuxMirror}/${DIST}/os/${PLATFORM}/isolinux/vmlinuz"
		[[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'vmlinuz' for \033[33m$linux_relese\033[0m failed! \n" && exit 1
	fi
elif [[ "$linux_relese" == 'fedora' ]]; then
	wget --no-check-certificate -qO 'initrd.img' "${LinuxMirror}/releases/${DIST}/Server/${PLATFORM}/os/isolinux/initrd.img"
	[[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'initrd.img' for \033[33m$linux_relese\033[0m failed! \n" && exit 1
	wget --no-check-certificate -qO 'vmlinuz' "${LinuxMirror}/releases/${DIST}/Server/${PLATFORM}/os/isolinux/vmlinuz"
	[[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'vmlinuz' for \033[33m$linux_relese\033[0m failed! \n" && exit 1
else
  bash $0 error;
  exit 1;
fi

[[ -d /tmp/boot ]] && rm -rf /tmp/boot;
mkdir -p /tmp/boot;
mv -f /boot/netboot/initrd.img /tmp/initrd.img;
cd /tmp/boot;

read -r -p "镜像下载完成请确认开始......[Y/n]:" input
case $input in
    [yY][eE][sS]|[yY]) ;;
    [nN][oO]|[nN])
        exit 1;;
	*) exit 1;;
esac

if [[ "$linux_relese" == 'debian' ]] || [[ "$linux_relese" == 'ubuntu' ]]; then
  COMPTYPE="gzip";
elif [[ "$linux_relese" == 'centos' ]] || [[ "$linux_relese" == 'fedora' ]]; then
  COMPTYPE="$(file ../initrd.img |grep -o ':.*compressed data' |cut -d' ' -f2 |sed -r 's/(.*)/\L\1/' |head -n1)"
  [[ -z "$COMPTYPE" ]] && echo "Detect compressed type fail." && exit 1;
fi
CompDected='0'
for COMP in `echo -en 'gzip\nlzma\nxz'`
  do
    if [[ "$COMPTYPE" == "$COMP" ]]; then
      CompDected='1'
      if [[ "$COMPTYPE" == 'gzip' ]]; then
        NewIMG="initrd.img.gz"
      else
        NewIMG="initrd.img.$COMPTYPE"
      fi
      mv -f "/tmp/initrd.img" "/tmp/$NewIMG"
      break;
    fi
  done
[[ "$CompDected" != '1' ]] && echo "Detect compressed type not support." && exit 1;
[[ "$COMPTYPE" == 'lzma' ]] && UNCOMP='xz --format=lzma --decompress';
[[ "$COMPTYPE" == 'xz' ]] && UNCOMP='xz --decompress';
[[ "$COMPTYPE" == 'gzip' ]] && UNCOMP='gzip -d';


$UNCOMP < /tmp/$NewIMG | cpio --extract --verbose --make-directories --no-absolute-filenames >>/dev/null 2>&1

if [[ "$linux_relese" == 'centos' ]] || [[ "$linux_relese" == 'fedora' ]]; then
	InstallURL=''
	if [[ "$linux_relese" == 'centos' ]]; then
		if [[ "$DIST" =~ ^8.* ]]; then
			InstallURL="${LinuxMirror}/${DIST}/BaseOS/${PLATFORM}/os/"
		else
			InstallURL="${LinuxMirror}/${DIST}/os/${PLATFORM}/"
		fi
	else
		InstallURL="${LinuxMirror}/releases/${DIST}/Server/${PLATFORM}/os/"
	fi
	cat >/tmp/boot/ks.cfg<<EOF
#platform x86, AMD64, or Intel EM64T
# Firewall configuration
firewall --enabled --ssh

# install
install

url --url="$InstallURL"

# Root password
rootpw --iscrypted "$PASSWORD"

# System authorization information
authselect --useshadow --passalgo sha512
#auth --useshadow --passalgo=sha512

# Disable system configuratio
firstboot --disable
lang en_US
keyboard us

# SELinux configuration
selinux --disabled
logging --level=info

# Reboot after installation
reboot
text

# unsupported_hardware vnc
unsupported_hardware
vnc
skipx

# System timezone
timezone --isUtc Asia/Shanghai
network --bootproto=static --ip=$MAINIP --netmask=$NETMASK --gateway=$GATEWAYIP --nameserver=$NAMESERVER --hostname=$(hostname) --onboot=on
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel 
autopart

%packages --ignoremissing
@base
bind-utils
net-tools
wget
vim
%end

%post --interpreter=/bin/bash
rm -rf /root/anaconda-ks.cfg
rm -rf /root/install.*log

sed -ri "/^#?PermitRootLogin.*/c\PermitRootLogin yes" /etc/ssh/sshd_config
sed -ri "/^#?PasswordAuthentication.*/c\PasswordAuthentication yes" /etc/ssh/sshd_config

%end
EOF

	[[ "$PROTO" -eq 'dhcp' ]] && sed -i "/^network.*/c\network --bootproto=dhcp --hostname=$(hostname) --onboot=on" /tmp/boot/ks.cfg;
	if [[ "$linux_relese" == 'centos' ]]; then
		[[ "$DIST" =~ ^7.* ]] && sed -i "/^authselect.*/c\auth --useshadow --passalgo=sha512" /tmp/boot/ks.cfg;
	fi
else
    

    cat >/tmp/boot/preseed.cfg<<EOF
# Preseeding only locale sets language, country and locale.

d-i debian-installer/locale string en_US.UTF-8
d-i console-setup/layoutcode string us

# Keyboard selection.
d-i keyboard-configuration/xkb-keymap string us

#Network console
d-i netcfg/choose_interface select auto
d-i netcfg/disable_autoconfig boolean true
d-i netcfg/dhcp_failed note
d-i netcfg/dhcp_options select Configure network manually
d-i netcfg/get_ipaddress string $MAINIP
d-i netcfg/get_netmask string $NETMASK
d-i netcfg/get_gateway string $GATEWAYIP
d-i netcfg/get_nameservers string $NAMESERVER
d-i netcfg/no_default_route boolean true
d-i netcfg/confirm_static boolean true
d-i netcfg/hostname string $(hostname)
d-i hw-detect/load_firmware boolean true

#Mirror settings
d-i mirror/country string manual
d-i mirror/http/hostname string $MirrorHost
d-i mirror/http/directory string $MirrorFolder
d-i mirror/http/proxy string
d-i apt-setup/services-select multiselect

#Account setup
d-i passwd/root-login boolean ture
d-i passwd/make-user boolean false
d-i passwd/root-password-crypted password $PASSWORD
d-i user-setup/allow-password-weak boolean true
d-i user-setup/encrypt-home boolean false

#Clock and time zone setup
d-i clock-setup/utc boolean true
d-i time/zone string US/Eastern
#d-i time/zone string Asia/Shanghai
d-i clock-setup/ntp-server string ntp.aliyun.com
d-i clock-setup/ntp boolean true

d-i preseed/early_command string anna-install libfuse2-udeb fuse-udeb ntfs-3g-udeb libcrypto1.1-udeb libpcre2-8-0-udeb libssl1.1-udeb libuuid1-udeb zlib1g-udeb wget-udeb
d-i partman/early_command string [[ -n "\$(blkid -t TYPE='vfat' -o device)" ]] && umount "\$(blkid -t TYPE='vfat' -o device)"; \

debconf-set partman-auto/disk "\$(list-devices disk |head -n1)"; \
wget -qO- '$DDURL' |gunzip -dc |/bin/dd of=\$(list-devices disk |head -n1); \
mount.ntfs-3g \$(list-devices partition |head -n1) /mnt; \
cd '/mnt/ProgramData/Microsoft/Windows/Start Menu/Programs'; \
cd Start* || cd start*; \
cp -f '/net.bat' './net.bat'; \
/sbin/reboot; \
umount /media || true; \

d-i partman/mount_style select uuid
d-i partman-auto/init_automatically_partition select Guided - use entire disk

# partman-auto  ////
d-i partman-auto/choose_recipe select All files in one partition (recommended for new users)

d-i partman-auto/method string regular
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

d-i debian-installer/allow_unauthenticated boolean true

tasksel tasksel/first multiselect minimal
d-i pkgsel/update-policy select none
d-i pkgsel/include string openssh-server net-tools
d-i pkgsel/upgrade select none

popularity-contest popularity-contest/participate boolean false

d-i grub-installer/only_debian boolean true
d-i grub-installer/bootdev  string default

# Avoid that last message about the install being complete.
d-i finish-install/reboot_in_progress note
d-i debian-installer/exit/reboot boolean true

# Verbose output and no boot splash screen.  ////
d-i debian-installer/quiet boolean false
d-i debian-installer/splash boolean false

d-i preseed/late_command string	\
sed -ri 's/^#?PermitRootLogin.*/PermitRootLogin yes/g' /target/etc/ssh/sshd_config; \
sed -ri 's/^#?PasswordAuthentication.*/PasswordAuthentication yes/g' /target/etc/ssh/sshd_config; \
apt-install wget curl net-tools;
EOF

	if [[ "$PROTO" == 'dhcp' ]]; then 
		sed -i '/netcfg\/disable_autoconfig/d' /tmp/boot/preseed.cfg
		sed -i '/netcfg\/dhcp_failed/d' /tmp/boot/preseed.cfg
		sed -i '/netcfg\/dhcp_options/d' /tmp/boot/preseed.cfg
		sed -i '/netcfg\/get_.*/d' /tmp/boot/preseed.cfg
		sed -i '/netcfg\/confirm_static/d' /tmp/boot/preseed.cfg
	fi
	
	[[ "$linux_relese" == 'debian' ]] && {
		sed -i '/user-setup\/allow-password-weak/d' /tmp/boot/preseed.cfg
		sed -i '/user-setup\/encrypt-home/d' /tmp/boot/preseed.cfg
		sed -i '/pkgsel\/update-policy/d' /tmp/boot/preseed.cfg
		sed -i 's/umount\ \/media.*true\;\ //g' /tmp/boot/preseed.cfg
	}
		
	[[ "$ddMode" == '0' ]] && {
		sed -i '/anna-install/d' /tmp/boot/preseed.cfg
		sed -i 's/wget.*\/sbin\/reboot\;\ //g' /tmp/boot/preseed.cfg
	}
	
fi

find . | cpio -H newc --create --verbose | gzip -9 > /tmp/initrd.img;
mv -f /tmp/initrd.img /boot/netboot/initrd.img;
rm -rf /tmp/boot;

cd ~
if [[ "$CurrentRelese" == "Ubuntu" ]]; then
	update-grub >>/dev/null 2>&1
elif [[ "$CurrentRelese" == "Debian" ]]; then
	grub-set-default 0 >>/dev/null 2>&1
	grub-mkconfig -o $GRUBDIR/$GRUBFILE >>/dev/null 2>&1
else
	grub2-set-default 0 >>/dev/null 2>&1
	grub2-mkconfig -o $GRUBDIR/$GRUBFILE >>/dev/null 2>&1
fi

#Backup grub config file
cp $GRUBDIR/$GRUBFILE "$GRUBDIR/$GRUBFILE.bak_$(date "+%Y%m%d%k%M%S")"

[[ -f /tmp/grub.new ]] && rm -f /tmp/grub.new
if [[ "$GRUBVER" == '0' ]]; then
	READGRUB='/tmp/grub.read'
	cat $GRUBDIR/$GRUBFILE |sed -n '1h;1!H;$g;s/\n/%%%%%%%/g;$p' |grep -om 1 'menuentry\ [^{]*{[^}]*}%%%%%%%' |sed 's/%%%%%%%/\n/g' >$READGRUB
	LoadNum="$(cat $READGRUB |grep -c 'menuentry ')"
	if [[ "$LoadNum" -eq '1' ]]; then
	cat $READGRUB |sed '/^$/d' >/tmp/grub.new;
	elif [[ "$LoadNum" -gt '1' ]]; then
	CFG0="$(awk '/menuentry /{print NR}' $READGRUB|head -n 1)";
	CFG2="$(awk '/menuentry /{print NR}' $READGRUB|head -n 2 |tail -n 1)";
	CFG1="";
	for tmpCFG in `awk '/}/{print NR}' $READGRUB`
	  do
		[ "$tmpCFG" -gt "$CFG0" -a "$tmpCFG" -lt "$CFG2" ] && CFG1="$tmpCFG";
	  done
	[[ -z "$CFG1" ]] && {
	  echo "Error! read $GRUBFILE. ";
	  exit 1;
	}

	sed -n "$CFG0,$CFG1"p $READGRUB >/tmp/grub.new;
	[[ -f /tmp/grub.new ]] && [[ "$(grep -c '{' /tmp/grub.new)" -eq "$(grep -c '}' /tmp/grub.new)" ]] || {
	  echo -ne "\033[31mError! \033[0mNot configure $GRUBFILE. \n";
	  exit 1;
	}
	fi
	[ ! -f /tmp/grub.new ] && echo "Error! $GRUBFILE. " && exit 1;
	
	sed -i "/menuentry.*/c\menuentry\ \'Install $Relese $DIST\'\ --class $linux_relese\ --class\ gnu-linux\ --class\ gnu\ --class\ os\ \{" /tmp/grub.new
	sed -i "/echo.*Loading/d" /tmp/grub.new;
	INSERTGRUB="$(awk '/menuentry /{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)"
else
	echo "GRUBVER=1"

	CFG0="$(awk '/^title[\t]/{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)";
	CFG1="$(awk '/^title[\t]/{print NR}' $GRUBDIR/$GRUBFILE|head -n 2 |tail -n 1)";
	[[ -n $CFG0 ]] && [ -z $CFG1 -o $CFG1 == $CFG0 ] && sed -n "$CFG0,$"p $GRUBDIR/$GRUBFILE >/tmp/grub.new;
	[[ -n $CFG0 ]] && [ -z $CFG1 -o $CFG1 != $CFG0 ] && sed -n "$CFG0,$[$CFG1-1]"p $GRUBDIR/$GRUBFILE >/tmp/grub.new;
	[[ ! -f /tmp/grub.new ]] && echo "Error! configure append $GRUBFILE. " && exit 1;
	sed -i "/title.*/c\title\ \'Install $Relese $DIST'" /tmp/grub.new;
	sed -i '/^#/d' /tmp/grub.new;
	INSERTGRUB="$(awk '/^title[\t]/{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)"
fi

LinuxKernel="$(grep 'linux.*/\|kernel.*/' /tmp/grub.new |awk '{print $1}' |head -n 1)";
[[ -z "$LinuxKernel" ]] && echo "Error! read grub config! " && exit 1;
LinuxIMG="$(grep 'initrd.*/' /tmp/grub.new |awk '{print $1}' |tail -n 1)";
[ -z "$LinuxIMG" ] && sed -i "/$LinuxKernel.*\//a\\\tinitrd\ \/" /tmp/grub.new && LinuxIMG='initrd';

if [[ "$linux_relese" == 'debian' ]] || [[ "$linux_relese" == 'ubuntu' ]]; then
	BOOT_OPTION="auto=true $NOIPV6 hostname=$linux_relese domain= -- quiet"
elif [[ "$linux_relese" == 'centos' ]] || [[ "$linux_relese" == 'fedora' ]]; then
	BOOT_OPTION="inst.ks=file://ks.cfg $NOIPV6 quiet";
fi

[[ -n "$(grep 'linux.*/\|kernel.*/' /tmp/grub.new |awk '{print $2}' |tail -n 1 |grep '^/boot/')" ]] && Type='InBoot' || Type='NoBoot';

[[ "$Type" == 'InBoot' ]] && {
	sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/boot\/vmlinuz $BOOT_OPTION" /tmp/grub.new;
	sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/boot\/initrd.img" /tmp/grub.new;
	mv -f /boot/netboot/vmlinuz /boot/vmlinuz;
	mv -f /boot/netboot/initrd.img /boot/initrd.img;
}

[[ "$Type" == 'NoBoot' ]] && {
	sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/vmlinuz $BOOT_OPTION" /tmp/grub.new;
	sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/initrd.img" /tmp/grub.new;
	mv -f /boot/netboot/vmlinuz /boot/vmlinuz;
	mv -f /boot/netboot/initrd.img /boot/initrd.img;
}

rm -rf /boot/netboot;

sed -i '$a\\n' /tmp/grub.new;

echo "Update $GRUBDIR/$GRUBFILE"
sed -i ''${INSERTGRUB}'i\\n' $GRUBDIR/$GRUBFILE;
sed -i ''${INSERTGRUB}'r /tmp/grub.new' $GRUBDIR/$GRUBFILE;
[[ -f  $GRUBDIR/grubenv ]] && sed -i 's/saved_entry/#saved_entry/g' $GRUBDIR/grubenv;

if [[ "$CurrentRelese" == "CentOS" ]]; then
	grub2-set-default "Install $Relese $DIST"
else
	grub-set-default "Install $Relese $DIST"
fi

chown root:root $GRUBDIR/$GRUBFILE
chmod 444 $GRUBDIR/$GRUBFILE

echo  -e "\033[33mreboot\033[0m"
reboot

exit 1;