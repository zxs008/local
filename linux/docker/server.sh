#!/bin/bash

#========================================================
#   System Required: CentOS 7+ / Debian 8+ / Ubuntu 16+ /
#========================================================

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
document=''
dockerservices=''

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}未检测到系统版本，请联系脚本作者！${plain}\n" && exit 1
fi

update_service() {
    if [[ "${1}" == "true" ]]; then
        read -ep "请输入创建的文件名: " documentName
        if  [ ! -n "$documentName" ] ;then
          echo "请输入有效的文本"
          show_menu
        fi
    fi
    
    if [ -f "/docker/server/${documentName}.sh" ]; then
      document=${documentName}.sh
    else
      document=${documentName}.sh
      mkdir -p /docker/server
      touch /docker/server/${document}
      echo "sleep 30;" >> /docker/server/${document}
    fi

    read -r -p "标签是否与创建文件一致? [y/n]: " inputtag
      case $input in
        [yY][eE][sS]|[yY]) 
        dockerservices=${documentName}
        ;;
        [nN][oO]|[nN]) 
        read -ep "请输入标签: " tag 
        dockerservices=${tag}
        ;;
        *) 
        ;;
      esac
    read -ep "请输入启动服务名: " serverName
    echo "sudo docker exec ${dockerservices} ${serverName}" >> /docker/server/${document}

    read -r -p "是否继续添加? [y/n]: " input
      case $input in
        [yY][eE][sS]|[yY]) update_service "false" ;;
        *) ;;
      esac
    
    if [[ $# == 0 ]]; then
        show_menu
    fi
}

crontab_service() {
      read -ep "请输入创建的文件名: " documentName
        if  [ ! -n "$documentName" ] ;then
          echo "请输入有效的文本"
          show_menu
        fi
      touch /var/spool/cron/crontabs/root
      echo "@reboot sudo bash /docker/server/${documentName}.sh" >> /var/spool/cron/crontabs/root
      crontab -u root /var/spool/cron/crontabs/root
      
    if [[ $# == 0 ]]; then
        show_menu
    fi
}

start_service() {
      read -ep "请输入创建的文件名: " documentName
        if  [ ! -n "$documentName" ] ;then
          echo "请输入有效的文本"
          show_menu
        fi

        cd /docker/server/
        bash ${documentName}.sh 
    if [[ $# == 0 ]]; then
        show_menu
    fi
}

show_menu() {
    echo -e "
    ${green}1.${plain}  创建增加启动的服务
    ${green}2.${plain}  增加开机自启服务
    ${green}3.${plain}  启动服务
    ————————————————-
    ${green}0.${plain}  退出脚本
    "
    echo && read -ep "请输入选择 [0-13]: " num

    case "${num}" in
    0)
        exit 0
        ;;
    1)
        update_service "true"
        ;;
    2)
        crontab_service
        ;;
    3)
        start_service
        ;;
    *)
        echo -e "${red}请输入正确的数字 [0-2]${plain}"
        ;;
    esac
}

if [[ $# > 0 ]]; then
  show_menu
else
  show_menu
fi
