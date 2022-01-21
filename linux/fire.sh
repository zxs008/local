#!/bin/bash

#======================================================
#   System Required: CentOS 7+ / Debian 8+ / Ubuntu 16+
#   Description: Manage v2-ui
#   Author: sprov
#======================================================

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 必须使用root用户运行此脚本！\n" && exit 1

firewalld_install() {
    yum -y install firewalld
	yum -y install firewall-config
	if [[ $# == 0 ]]; then
        before_show_menu_firewalld
    fi
}

firewalld_uninstall() {
    systemctl disable firewalld.service
    systemctl stop firewalld.service
    systemctl mask firewalld.service
	yum -y remove firewalld.service
	if [[ $# == 0 ]]; then
        before_show_menu_firewalld
    fi
}

firewalld_initiated() {
    systemctl enable firewalld.service
	if [[ $# == 0 ]]; then
        before_show_menu_firewalld
    fi
}

firewalld_uninitiated() {
    systemctl disable firewalld.service
	if [[ $# == 0 ]]; then
        before_show_menu_firewalld
    fi
}

firewalld_status() {
    systemctl status firewalld.service
	if [[ $# == 0 ]]; then
        before_show_menu_firewalld
    fi
}

firewalld_start() {
    systemctl start firewalld.service
	systemctl enable firewalld.service
	if [[ $# == 0 ]]; then
        before_show_menu_firewalld
    fi
}

firewalld_stop() {
    systemctl stop firewalld.service
	systemctl disable firewalld.service
	if [[ $# == 0 ]]; then
        before_show_menu_firewalld
    fi
}

firewalld_reload() {
    firewall-cmd --reload
	if [[ $# == 0 ]]; then
        before_show_menu_firewalld
    fi
}

firewalld_list() {
    firewall-cmd --list-all
	if [[ $# == 0 ]]; then
        before_show_menu_firewalld
    fi
}

firewalld_list_ports() {
    firewall-cmd --list-ports
	if [[ $# == 0 ]]; then
        before_show_menu_firewalld
    fi
}

firewalld_list_port() {
    echo && echo -n -e "请输入端口: " && read port
	if [[ -z "${port}" ]]; then
        echo -e "${yellow}已取消${plain}"
        before_show_menu_firewalld
    else
	    echo && echo -n -e "请输入协议: " && read protocol
		if [[ -z "${protocol}" ]]; then
            echo -e "${yellow}已取消${plain}"
            before_show_menu_firewalld
        else
            firewall-cmd --query-port=${port}/${protocol}
		fi
    fi
	
	if [[ $# == 0 ]]; then
        before_show_menu_firewalld
    fi
}

firewalld_openport() {
    echo && echo -n -e "请输入端口: " && read port
	
	if [[ -z "${port}" ]]; then
        echo -e "${yellow}已取消${plain}"
        before_show_menu_firewalld
    else
	    echo && echo -n -e "请输入协议: " && read protocol
		if [[ -z "${protocol}" ]]; then
            firewall-cmd --zone=public --add-port=${port}/tcp --permanent
			firewall-cmd --zone=public --add-port=${port}/udp --permanent
			firewall-cmd --reload
        else
            firewall-cmd --zone=public --add-port=${port}/${protocol} --permanent
			firewall-cmd --reload
		fi
    fi
	
	if [[ $# == 0 ]]; then
        before_show_menu_firewalld
    fi
}

firewalld_closeport() {
    echo && echo -n -e "请输入端口: " && read port
	if [[ -z "${port}" ]]; then
        echo -e "${yellow}已取消${plain}"
        before_show_menu_firewalld
    else
	    echo && echo -n -e "请输入协议: " && read protocol
		if [[ -z "${protocol}" ]]; then
            firewall-cmd --zone=public --remove-port=${port}/tcp --permanent
			firewall-cmd --zone=public --remove-port=${port}/udp --permanent
			firewall-cmd --reload
        else
            firewall-cmd --zone=public --remove-port=${port}/${protocol} --permanent
			firewall-cmd --reload
	   fi
   fi
	
    if [[ $# == 0 ]]; then
        before_show_menu_firewalld
    fi
}

firewalld_openipport() {
    echo && echo -n -e "请输入端口: " && read port
	if [[ -z "${port}" ]]; then
        echo -e "${yellow}已取消${plain}"
        before_show_menu_firewalld
    else
	    echo && echo -n -e "请输入IP地址: " && read address
	    if [[ -z "${address}" ]]; then
            echo -e "${yellow}已取消${plain}"
            before_show_menu_firewalld
		else
	       echo && echo -n -e "请输入协议: " && read protocol
		   if [[ -z "${protocol}" ]]; then
		       firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="${address}" port protocol="tcp" port="${port}" accept"
			   firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="${address}" port protocol="udp" port="${port}" accept"
			   firewall-cmd --reload
           else
		       firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="${address}" port protocol="${protocol}" port="${port}" accept"
               #firewall-cmd --zone=public --source=${address} --add-port=${port}/${protocol} --permanent
			   firewall-cmd --reload
		   fi
	    fi
   fi
	
	if [[ $# == 0 ]]; then
        before_show_menu_firewalld
    fi
}

firewalld_closeipport() {
    echo && echo -n -e "请输入端口: " && read port
	if [[ -z "${port}" ]]; then
        echo -e "${yellow}已取消${plain}"
        before_show_menu_firewalld
    else
	    echo && echo -n -e "请输入IP地址: " && read address
	    if [[ -z "${address}" ]]; then
            echo -e "${yellow}已取消${plain}"
            before_show_menu_firewalld
		else
	       echo && echo -n -e "请输入协议: " && read protocol
		   if [[ -z "${protocol}" ]]; then
		       firewall-cmd --permanent --remove-rich-rule="rule family="ipv4" source address="${address}" port protocol="tcp" port="${port}" accept"
			   firewall-cmd --permanent --remove-rich-rule="rule family="ipv4" source address="${address}" port protocol="udp" port="${port}" accept"
			   firewall-cmd --reload
           else
		       firewall-cmd --permanent --remove-rich-rule="rule family="ipv4" source address="${address}" port protocol="${protocol}" port="${port}" accept"
               #firewall-cmd --zone=public --source=${address} --remove-port=${port}/${protocol} --permanent
			   firewall-cmd --reload
		   fi
	    fi
   fi
	
    if [[ $# == 0 ]]; then
        before_show_menu_firewalld
    fi
}

firewalld_openping() {
    grep "net.ipv4.icmp_echo_ignore_all" /etc/sysctl.conf >/dev/null
    if [ $? -eq 0 ]; then
      sed -i 's/net.ipv4.icmp_echo_ignore_all = 1/net.ipv4.icmp_echo_ignore_all = 0/g' /etc/sysctl.conf
    else
      echo -e "net.ipv4.icmp_echo_ignore_all = 0" >> /etc/sysctl.conf
    fi
    
    sysctl -p
    
    if [[ $# == 0 ]]; then
        before_show_menu_firewalld
    fi
}

firewalld_closeping() {
    grep "net.ipv4.icmp_echo_ignore_all" /etc/sysctl.conf >/dev/null
    if [ $? -eq 0 ]; then
      sed -i 's/net.ipv4.icmp_echo_ignore_all = 0/net.ipv4.icmp_echo_ignore_all = 1/g' /etc/sysctl.conf
    else
      echo "net.ipv4.icmp_echo_ignore_all = 1" >> /etc/sysctl.conf
    fi
    
    sysctl -p
    
    if [[ $# == 0 ]]; then
        before_show_menu_firewalld
    fi
}

before_show_menu_firewalld() {
    echo && echo -n -e "${yellow}按回车返回主菜单: ${plain}" && read temp
    show_menu_firewalld
}

show_menu_firewalld() {
  echo -e "
  ${green}0.${plain} 退出脚本
————————————————
  ${green}1.${plain} Firewalld安装
  ${green}2.${plain} Firewalld卸载
  ${green}3.${plain} Firewalld开起自启
  ${green}4.${plain} Firewalld关闭自启
————————————————
  ${green}5.${plain} 查看防火墙状态
  ${green}6.${plain} 开启命令
  ${green}7.${plain} 停止命令
  ${green}8.${plain} 重启防火墙
————————————————
  ${green}11.${plain} 查看端口
  ${green}12.${plain} 查看单个端口
  ${green}13.${plain} 查看规则
  ${green}14.${plain} 开启端口
  ${green}15.${plain} 关闭端口
  ${green}16.${plain} 开启IP+端口
  ${green}17.${plain} 关闭IP+端口
  ${green}18.${plain} 开启ping
  ${green}19.${plain} 关闭ping
————————————————
 "
    echo && read -p "请输入选择 [0-14]: " num

    case "${num}" in
        0) exit 0
        ;;
		1) firewalld_install
        ;;
		2) firewalld_uninstall
        ;;
		3) firewalld_initiated
        ;;
		4) firewalld_uninitiated
        ;;
          5) firewalld_status
        ;;
		6) firewalld_start
        ;;
		7) firewalld_stop
        ;;
		8) firewalld_reload
        ;;
		11) firewalld_list_ports
        ;;
		12) firewalld_list_port
        ;;
		13) firewalld_list
		;;
		14) firewalld_openport
        ;;
		15) firewalld_closeport
        ;;
		16) firewalld_openipport
        ;;
		17) firewalld_closeipport
        ;;
          18) firewalld_openping
        ;;
		19) firewalld_closeping
        ;;
        *) echo -e "${red}请输入正确的数字 [0-14]${plain}"
        ;;
    esac
}

ufw_install() {
    apt -y install ufw
	if [[ $# == 0 ]]; then
        show_menu_ufw
    fi
}

ufw_uninstall() {
    systemctl disable firewalld.service
    systemctl stop firewalld.service
    systemctl mask firewalld.service
    apt -y remove firewalld.service
	if [[ $# == 0 ]]; then
        show_menu_ufw
    fi
}

ufw_initiated() {
    sudo systemctl enable ufw
	if [[ $# == 0 ]]; then
        show_menu_ufw
    fi
}

ufw_uninitiated() {
    sudo systemctl disable ufw
	if [[ $# == 0 ]]; then
        show_menu_ufw
    fi
}

ufw_status() {
    sudo ufw status
	if [[ $# == 0 ]]; then
        show_menu_ufw
    fi
}

ufw_start() {
    sudo ufw enable
	sudo systemctl enable ufw
	if [[ $# == 0 ]]; then
        show_menu_ufw
    fi
}

ufw_stop() {
    sudo ufw disable
	sudo systemctl disable ufw
	if [[ $# == 0 ]]; then
        show_menu_ufw
    fi
}

ufw_reload() {
    sudo ufw reload
	if [[ $# == 0 ]]; then
        show_menu_ufw
    fi
}

ufw_reset() {
    sudo ufw reset
	if [[ $# == 0 ]]; then
        show_menu_ufw
    fi
}

ufw_list_ports() {
    sudo ufw status numbered
	
	if [[ $# == 0 ]]; then
        show_menu_ufw
    fi
}

ufw_delete() {
    echo && echo -n -e "请输入编号: " && read num
	if [[ -z "${num}" ]]; then
        echo -e "${yellow}已取消${plain}"
        show_menu_ufw
    else
        sudo ufw delete ${num}
    fi
	
	if [[ $# == 0 ]]; then
        show_menu_ufw
    fi
}

ufw_openport() {
    echo && echo -n -e "请输入端口: " && read port
	
	if [[ -z "${port}" ]]; then
        echo -e "${yellow}已取消${plain}"
        show_menu_ufw
    else
	    echo && echo -n -e "请输入协议: " && read protocol
		if [[ -z "${protocol}" ]]; then
            sudo ufw allow ${port}
			sudo ufw reload
        else
            sudo ufw allow ${port}/${protocol}
			sudo ufw reload
		fi
    fi
	
	if [[ $# == 0 ]]; then
        show_menu_ufw
    fi
}

ufw_closeport() {
    echo && echo -n -e "请输入端口: " && read port
	
	if [[ -z "${port}" ]]; then
        echo -e "${yellow}已取消${plain}"
        show_menu_ufw
    else
	    echo && echo -n -e "请输入协议: " && read protocol
		if [[ -z "${protocol}" ]]; then
            sudo ufw delete allow ${port}
			sudo ufw reload
        else
            sudo ufw delete allow ${port}/${protocol}
			sudo ufw reload
		fi
    fi
	
	if [[ $# == 0 ]]; then
        show_menu_ufw
    fi
}

ufw_openipport() {
    echo && echo -n -e "请输入端口: " && read port
	if [[ -z "${port}" ]]; then
        echo -e "${yellow}已取消${plain}"
        show_menu_ufw
    else
	    echo && echo -n -e "请输入IP地址: " && read address
	    if [[ -z "${address}" ]]; then
            echo -e "${yellow}已取消${plain}"
            show_menu_ufw
		else
	       echo && echo -n -e "请输入协议: " && read protocol
		   if [[ -z "${protocol}" ]]; then
              sudo ufw allow from ${address} to any port ${port}
			  sudo ufw reload
           else
		       sudo ufw allow from ${address} to any port ${port} proto ${protocol}
			   sudo ufw reload
		   fi
	    fi
   fi
	
	if [[ $# == 0 ]]; then
        show_menu_ufw
    fi
}

ufw_closeipport() {
   echo && echo -n -e "请输入端口: " && read port
	if [[ -z "${port}" ]]; then
        echo -e "${yellow}已取消${plain}"
        show_menu_ufw
    else
	    echo && echo -n -e "请输入IP地址: " && read address
	    if [[ -z "${address}" ]]; then
            echo -e "${yellow}已取消${plain}"
            show_menu_ufw
		else
	       echo && echo -n -e "请输入协议: " && read protocol
		   if [[ -z "${protocol}" ]]; then
              sudo ufw delete allow from ${address} to any port ${port}
			  sudo ufw reload
           else
		       sudo ufw delete allow from ${address} to any port ${port} proto ${protocol}
			   sudo ufw reload
		   fi
	    fi
   fi
   
   if [[ $# == 0 ]]; then
        show_menu_ufw
    fi
}

ufw_closeping() {
   #sed -i 's/-A ufw-before-input -p icmp --icmp-type destination-unreachable -j ACCEPT/-A ufw-before-input -p icmp --icmp-type destination-unreachable -j DROP/g' /etc/ufw/before.rules
   #sed -i 's/-A ufw-before-input -p icmp --icmp-type time-exceeded -j ACCEPT/-A ufw-before-input -p icmp --icmp-type time-exceeded -j DROP/g' /etc/ufw/before.rules
   #sed -i 's/-A ufw-before-input -p icmp --icmp-type parameter-problem -j ACCEPT/-A ufw-before-input -p icmp --icmp-type parameter-problem -j DROP/g' /etc/ufw/before.rules
   sed -i 's/-A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT/-A ufw-before-input -p icmp --icmp-type echo-request -j DROP/g' /etc/ufw/before.rules

   sudo ufw reload
   
   if [[ $# == 0 ]]; then
        show_menu_ufw
   fi
}

ufw_openping() {
   #sed -i 's/-A ufw-before-input -p icmp --icmp-type destination-unreachable -j DROP/-A ufw-before-input -p icmp --icmp-type destination-unreachable -j ACCEPT/g' /etc/ufw/before.rules
   #sed -i 's/-A ufw-before-input -p icmp --icmp-type time-exceeded -j DROP/-A ufw-before-input -p icmp --icmp-type time-exceeded -j ACCEPT/g' /etc/ufw/before.rules
   #sed -i 's/-A ufw-before-input -p icmp --icmp-type parameter-problem -j DROP/-A ufw-before-input -p icmp --icmp-type parameter-problem -j ACCEPT/g' /etc/ufw/before.rules
   sed -i 's/-A ufw-before-input -p icmp --icmp-type echo-request -j DROP/-A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT/g' /etc/ufw/before.rules

   sudo ufw reload
   
   if [[ $# == 0 ]]; then
        show_menu_ufw
   fi
}

show_menu_ufw() {
  echo -e "
  ${green}0.${plain} 退出脚本
————————————————
  ${green}1.${plain} Ufw安装
  ${green}2.${plain} Ufw卸载
  ${green}3.${plain} Ufw开起自启
  ${green}4.${plain} Ufw关闭自启
————————————————
  ${green}5.${plain} 查看防火墙状态
  ${green}6.${plain} 开启命令
  ${green}7.${plain} 停止命令
  ${green}8.${plain} 重启防火墙
  ${green}9.${plain} 防火墙重置
————————————————
  ${green}11.${plain} 查看规则状态
  ${green}12.${plain} 删除规格
  ${green}13.${plain} 开启端口
  ${green}14.${plain} 拒绝端口
  ${green}15.${plain} 开启端口+IP
  ${green}16.${plain} 拒绝端口+IP
  ${green}17.${plain} 开启ping
  ${green}18.${plain} 关闭ping
————————————————
 "
    echo && read -p "请输入选择 [0-14]: " num

    case "${num}" in
        0) exit 0
        ;;
		1) ufw_install
        ;;
		2) ufw_uninstall
        ;;
		3) ufw_initiated
        ;;
		4) ufw_uninitiated
        ;;
          5) ufw_status
        ;;
		6) ufw_start
        ;;
		7) ufw_stop
        ;;
		8) ufw_reload
        ;;
		9) ufw_reset
        ;;
		11) ufw_list_ports
        ;;
		12) ufw_delete
        ;;
		13) ufw_openport
        ;;
		14) ufw_rejectport
        ;;
		15) ufw_openipport
        ;;
		16) ufw_rejectipport
        ;;
          17) ufw_openping
        ;;
          18) ufw_closeping
        ;;
        *) echo -e "${red}请输入正确的数字${plain}"
        ;;
    esac
}

show_menu(){
echo -e "
  ${green}0.${plain} 退出脚本
————————————————
  ${green}1.${plain} Firewalld防火墙
  ${green}2.${plain} Ufw防火墙
————————————————
 "
    echo && read -p "请输入选择 [0-2]: " num

    case "${num}" in
        0) exit 0
        ;;
		1) show_menu_firewalld
        ;;
		2) show_menu_ufw
        ;;
        *) echo -e "${red}请输入正确的数字 [0-14]${plain}"
        ;;
    esac
}

if [[ 1 > 0 ]]; then
    show_menu
fi
