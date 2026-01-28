#!/bin/sh
stty erase '^H'
if [[ $EUID -ne 0 ]]; then
    clear
    echo "Error: This script must be run as root!" 1>&2
    exit 1
fi

export tmpPassWord='Pwd@Linux'
export hostName=''
export territory=''
export downInstall='0'

function CopyRight() {

  echo "########################################################"
  echo "#                    Hello Word!                       #"
  echo "#                        DD                            #"
  echo "########################################################"
  #echo -e "\n"
}

function isValidIp() {
  local ip=$1
  local ret=1
  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    ip=(${ip//\./ })
    [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
    ret=$?
  fi
  return $ret
}

function ipCheck() {
  isLegal=0
  for add in $MAINIP $GATEWAYIP $NETMASK; do
    isValidIp $add
    if [ $? -eq 1 ]; then
      isLegal=1
    fi
  done
  return $isLegal
}

function GetIp() {
  MAINIP=$(ip route get 1 | awk -F 'src ' '{print $2}' | awk '{print $1}')
  GATEWAYIP=$(ip route | grep default | awk '{print $3}' | head -1)
  SUBNET=$(ip -o -f inet addr show | awk '/scope global/{sub(/[^.]+\//,"0/",$4);print $4}' | head -1 | awk -F '/' '{print $2}')
  value=$(( 0xffffffff ^ ((1 << (32 - $SUBNET)) - 1) ))
  NETMASK="$(( (value >> 24) & 0xff )).$(( (value >> 16) & 0xff )).$(( (value >> 8) & 0xff )).$(( value & 0xff ))"
}

function UpdateIp() {
  read -r -p "Your IP: " MAINIP
  read -r -p "Your Gateway: " GATEWAYIP
  read -r -p "Your Netmask: " NETMASK
}

function Territory() {
  echo -e "\n please choose:"
  echo "  1) cn"
  read N
  case $N in
    1) territory='cn' ;;
    *) territory='' ;;
  esac
}

function SetNetwork() {
  echo -e "Error ${isAuto}"
  isAuto='0'
  if [[ -f '/etc/network/interfaces' ]];then
    [[ ! -z "$(sed -n '/iface.*inet static/p' /etc/network/interfaces)" ]] && isAuto='1'
    [[ -d /etc/network/interfaces.d ]] && {
      cfgNum="$(find /etc/network/interfaces.d -name '*.cfg' |wc -l)" || cfgNum='0'
      [[ "$cfgNum" -ne '0' ]] && {
        for netConfig in `ls -1 /etc/network/interfaces.d/*.cfg`
        do 
          [[ ! -z "$(cat $netConfig | sed -n '/iface.*inet static/p')" ]] && isAuto='1'
        done
      }
    }
  fi
  
  if [[ -d '/etc/sysconfig/network-scripts' ]];then
    cfgNum="$(find /etc/network/interfaces.d -name '*.cfg' |wc -l)" || cfgNum='0'
    [[ "$cfgNum" -ne '0' ]] && {
      for netConfig in `ls -1 /etc/sysconfig/network-scripts/ifcfg-* | grep -v 'lo$' | grep -v ':[0-9]\{1,\}'`
      do 
        [[ ! -z "$(cat $netConfig | sed -n '/BOOTPROTO.*[sS][tT][aA][tT][iI][cC]/p')" ]] && isAuto='1'
      done
    }
  fi
}

function NetMode() {
  if [ "$isAuto" == '0' ]; then
    read -r -p "Using DHCP to configure network automatically? [Y/n]:" input
    case $input in
      [yY][eE][sS]|[yY]) NETSTR='' ;;
      [nN][oO]|[nN]) isAuto='1' ;;
      *) NETSTR='' ;;
    esac
  fi

  if [ "$isAuto" == '1' ]; then
    GetIp
    ipCheck
    if [ $? -ne 0 ]; then
      echo -e "Error occurred when detecting ip. Please input manually.\n"
      UpdateIp
    else
      CopyRight
      echo "IP: $MAINIP"
      echo "Gateway: $GATEWAYIP"
      echo "Netmask: $NETMASK"
      echo -e "\n"
      read -r -p "Confirm? [Y/n]:" input
      case $input in
        [yY][eE][sS]|[yY]) ;;
        [nN][oO]|[nN])
          echo -e "\n"
          UpdateIp
          ipCheck
          [[ $? -ne 0 ]] && {
            clear
            echo -e "Input error!\n"
            exit 1
          }
        ;;
        *) ;;
      esac
    fi
    NETSTR="--ip-addr ${MAINIP} --ip-gate ${GATEWAYIP} --ip-mask ${NETMASK}"
  fi
}

function SetPassWord() {
    read -r -p "SetPassWord:" input
    tmpPassWord=$input;
}

function SetHostName(){
     read -r -p "SetHostName:" input
    hostName=$input;
}

function Automatically() {
  read -r -p "Automatically obtain domestic and foreign mirrors? [Y/n]:" input
    case $input in
      [yY][eE][sS]|[yY]) ;;
      [nN][oO]|[nN])
          echo -e "\n"
          Territory ;;
        *) ;;
    esac
}

function install_down() {
  read -r -p "dowload install ? [Y/n]:" input
    case $input in
      [yY][eE][sS]|[yY]) ;;
      [nN][oO]|[nN])
          downInstall='1' ;;
        *) ;;
    esac
}

function Start() {
  isCN='0'
  
  if [[ ${territory} == "cn" ]]; then
    isCN='1'
  else 
    local geoip=$(curl -m 10 -s https://api.ip.sb/geoip | grep 'China');
    if [[ ${geoip} == "" ]]; then
      geoip=$(curl -m 10 -s https://ipinfo.io | grep 'CN');
    fi
    
    if [[ "$geoip" != "" ]];then
      echo "当前IP可能在中国"
      isCN='1'
    fi
  fi
  if [ "$isAuto" == '0' ]; then
    echo "Using DHCP mode."
  else
    if [[ "$isAuto" == "" ]]; then
       GetIp
       ipCheck
    fi
    echo "IP: $MAINIP"
    echo "Gateway: $GATEWAYIP"
    echo "Netmask: $NETMASK"
  fi
  install_down;
  if [[ ${downInstall} == "0" ]]; then
     if [ -f "/root/installdds.sh" ]; then
      rm -f /root/installdds.sh
     fi
  fi

  if [ ! -f "/root/installdds.sh" ]; then
     if [[ "$isCN" == '1' ]];then
        wget --no-check-certificate -qO installdds.sh "https://git.dyna.eu.org/linux/dd/installdds.sh" && chmod +x installdds.sh
     else
        wget --no-check-certificate -qO installdds.sh "https://zxs008.github.io/local/linux/dd/installdds.sh" && chmod +x installdds.sh
     fi
   fi
  
  CMIRROR=''
  DMIRROR=''
  UMIRROR=''
  
  if [[ "$isCN" == '1' ]];then
    CMIRROR="--mirror https://mirrors.ustc.edu.cn/centos"
    DMIRROR="--mirror https://mirrors.ustc.edu.cn/debian"
    UMIRROR="--mirror https://mirrors.ustc.edu.cn/ubuntu"
  fi

  SYSRROR=''
  if [[ "$hostName" != "" ]];then
    SYSRROR="-h ${hostName}"
  fi  

  echo -e "\nPlease select an OS:"
  echo "  1) Ubuntu 16.04 LTS (Xenial) 用户名：root 密码：$tmpPassWord"
  echo "  2) Ubuntu 18.04 LTS (Bionic) 用户名：root 密码：$tmpPassWord"
  echo "  3) Ubuntu 20.04 LTS (Focal) 用户名：root 密码：$tmpPassWord"
  echo "  4) Ubuntu 22.04 LTS (Jammy) 用户名：root 密码：$tmpPassWord"
  echo "  5) Ubuntu 24.04 LTS (Noble) 用户名：root 密码：$tmpPassWord"
  echo "  6) Ubuntu 25.10 LTS (Questing) 用户名：root 密码：$tmpPassWord"
  echo "  11) Debian 9（Stretch） 用户名：root 密码：$tmpPassWord"
  echo "  12) Debian 10（Buster） 用户名：root 密码：$tmpPassWord"
  echo "  13) Debian 11（Bullseye）用户名：root 密码：$tmpPassWord"
  echo "  14) Debian 12（Bookworm）用户名：root 密码：$tmpPassWord"
  echo "  15) Debian 13（Trixie）用户名：root 密码：$tmpPassWord"
  echo "  27) CentOS 6.9 x64 用户名：root 密码：$tmpPassWord"
  echo "  28) CentOS 6.10 x64 用户名：root 密码：$tmpPassWord"
  echo "  29) CentOS 7 用户名：root 密码：$tmpPassWord, 要求2G RAM以上才能使用"
  echo "  31) CentOS 7.6 x64 (DD) 用户名：root 密码：Pwd@CentOS"
  echo "  32) CentOS 7.7 x64 (DD) 失效 用户名：root 密码：Pwd@CentOS"
  echo "  33) CentOS 7.8 x64 (DD) 用户名：root 密码：Pwd@CentOS" 
  echo "  34) CentOS 7.9 x64 (DD) 用户名：root 密码：Pwd@CentOS"  
  echo "  99) Custom image"
  echo "  0) Exit"
  echo -ne "\nYour option: "
  read N
  case $N in
    1) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash <(wget --no-check-certificate -qO- 'https://zxs008.github.io/local/linux/dd/cxthhhhh.sh') -u 16.04 -v 64 -p $tmpPassWord $SYSRROR $UMIRROR ;;
    2) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash installdds.sh -u 18.04 -v 64 -p $tmpPassWord $SYSRROR  $UMIRROR ;;
    3) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash installdds.sh -u 20.04 -v 64 -p $tmpPassWord $SYSRROR $UMIRROR ;;
    4) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash installdds.sh -u 22.04 -v 64 -p $tmpPassWord $SYSRROR $UMIRROR ;;
    5) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash installdds.sh -u 24.04 -v 64 -p $tmpPassWord $SYSRROR $UMIRROR ;;
    6) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash installdds.sh -u 25.10 -v 64 -p $tmpPassWord $SYSRROR $UMIRROR ;;
    11) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash installdds.sh -d 9 -v 64 -p $tmpPassWord $SYSRROR $DMIRROR ;;
    12) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash installdds.sh -d 10 -v 64 -p $tmpPassWord $SYSRROR $DMIRROR ;;
    13) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash installdds.sh -d 11 -v 64 -p $tmpPassWord $SYSRROR $DMIRROR ;;
    14) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash installdds.sh -d 12 -v 64 -p $tmpPassWord $SYSRROR $DMIRROR ;;
    27) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash installdds.sh -c 6.9 -v 64 -p $tmpPassWord $SYSRROR $CMIRROR ;;
    28) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash installdds.sh -c 6.10 -v 64 -p $tmpPassWord $SYSRROR $CMIRROR ;;
    29) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash installdds.sh -c 7 -v 64 -p $tmpPassWord $SYSRROR $CMIRROR ;;
    31) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash installdds.sh -dd 'https://api.moetools.net/get/centos-76-image' ;;
    32) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash installdds.sh -dd 'https://api.moetools.net/get/centos-77-image' ;;
    33) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash installdds.sh -dd 'https://api.moetools.net/get/centos-78-image' ;;
    34) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash installdds.sh -dd 'https://api.moetools.net/get/centos-79-image' ;; 
    99)
      echo -e "\n"
      read -r -p "Custom image URL: " imgURL
      echo -e "\n"
      read -r -p "Are you sure start reinstall? [y/N]: " input
      case $input in
        [yY][eE][sS]|[yY]) bash /root/installdds.sh $NETSTR -dd $imgURL $DMIRROR ;;
        *) clear; echo "Canceled by user!"; exit 1;;
      esac
      ;;
    0) exit 0;;
    *) echo "Wrong input!"; exit 1;;
  esac
}
# 设置网络暂时不用
#SetNetwork
CopyRight
NetMode
Automatically
SetPassWord
SetHostName
Start
