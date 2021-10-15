#!/bin/sh

if [[ $EUID -ne 0 ]]; then
    clear
    echo "Error: This script must be run as root!" 1>&2
    exit 1
fi

export tmpPassWord='Pwd@Linux'

function CopyRight() {
  clear
  echo "########################################################"
  echo "#                                                      #"
  echo "#  Auto Reinstall Script                               #"
  echo "#                                                      #"
  echo "#  Author: hiCasper                                    #"
  echo "#  Blog: https://blog.hicasper.com/post/135.html       #"
  echo "#  Feedback: https://github.com/hiCasper/Shell/issues  #"
  echo "#  Last Modified: 2021-01-13                           #"
  echo "#                                                      #"
  echo "#  Supported by MoeClub                                #"
  echo "#                                                      #"
  echo "########################################################"
  echo -e "\n"
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

function SetNetwork() {
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
  CopyRight

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

function Start() {
  CopyRight

  isCN='0'
  geoip=$(wget --no-check-certificate -qO- https://api.ip.sb/geoip -T 10 | grep "\"country_code\":\"CN\"")
  if [[ "$geoip" != "" ]];then
    isCN='1'
  fi

  if [ "$isAuto" == '0' ]; then
    echo "Using DHCP mode."
  else
    echo "IP: $MAINIP"
    echo "Gateway: $GATEWAYIP"
    echo "Netmask: $NETMASK"
  fi

  if [ -f "/root/installdd.sh" ]; then
    chmod 777 /root/installdd.sh
  fi
  
  CMIRROR=''
  DMIRROR=''
  UMIRROR=''
  
  if [[ "$isCN" == '1' ]];then
    CMIRROR="--mirror https://mirrors.aliyun.com/centos/"
    DMIRROR="--mirror https://mirrors.aliyun.com/debian/"
    UMIRROR="--mirror https://mirrors.aliyun.com/ubuntu/"
  fi

  sed -i 's/$1$4BJZaD0A$y1QykUnJ6mXprENfwpseH0/$1$7R4IuxQb$J8gcq7u9K0fNSsDNFEfr90/' /root/installdd.sh

  echo -e "\nPlease select an OS:"
  echo "PassWord: $tmpPassWord"
  echo "  1) CentOS 7.9 (DD Image)"
  echo "  2) CentOS 7.6 (DD Image, ServerSpeeder Avaliable)"
  echo "  3) CentOS 6"
  echo "  4) Debian 9"
  echo "  5) Debian 10"
  echo "  6) Debian 11"
  echo "  7) Ubuntu 16.04"
  echo "  8) Ubuntu 18.04"
  echo "  9) Ubuntu 20.04"
  echo "  10) Custom image"
  echo "  0) Exit"
  echo -ne "\nYour option: "
  read N
  case $N in
    1) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash /root/installdd.sh $NETSTR -p $tmpPassWord -dd 'https://api.moetools.net/get/centos-7-image' $DMIRROR ;;
    2) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash /root/installdd.sh $NETSTR -p $tmpPassWord -dd 'https://api.moetools.net/get/centos-76-image' $DMIRROR ;;
    3) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash /root/installdd.sh -c 6.10 -v 64 -p $tmpPassWord -a $NETSTR $CMIRROR ;;
    4) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash /root/installdd.sh -d 9 -v 64 -p $tmpPassWord -a $NETSTR $DMIRROR ;;
    5) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash /root/installdd.sh -d 10 -v 64 -p $tmpPassWord -a $NETSTR $DMIRROR ;;
    6) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash /root/installdd.sh -d 11 -v 64 -p $tmpPassWord -a $NETSTR $DMIRROR ;;
    7) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash /root/installdd.sh -u 16.04 -v 64 -p $tmpPassWord -a $NETSTR $UMIRROR ;;
    8) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash /root/installdd.sh -u 18.04 -v 64 -p $tmpPassWord -a $NETSTR $UMIRROR ;;
    9) echo -e "\nPassword: $tmpPassWord\n"; read -s -n1 -p "Press any key to continue..." ; bash /root/installdd.sh -u 20.04 -v 64 -p $tmpPassWord -a $NETSTR $UMIRROR ;;
    10)
      echo -e "\n"
      read -r -p "Custom image URL: " imgURL
      echo -e "\n"
      read -r -p "Are you sure start reinstall? [y/N]: " input
      case $input in
        [yY][eE][sS]|[yY]) bash /root/installdd.sh $NETSTR -dd $imgURL $DMIRROR ;;
        *) clear; echo "Canceled by user!"; exit 1;;
      esac
      ;;
    0) exit 0;;
    *) echo "Wrong input!"; exit 1;;
  esac
}

SetNetwork
NetMode
SetPassWord
Start