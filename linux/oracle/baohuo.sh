#!/bin/bash
LANG=en_US.UTF-8

arch=$(arch)
if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
  arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
  arch="arm64"
fi

echo "架构: ${arch}"

download() {
    if [ -f "/root/NeverIdle" ]; then
      rm -f /root/NeverIdle
    fi

    wget https://github.com/layou233/NeverIdle/releases/download/0.1/NeverIdle-linux-${arch} -O NeverIdle && chmod 777 NeverIdle
}

show_menu_change() {
    echo -e "
	
	  ${green}1.${plain}  下载文件
    ${green}2.${plain}  后台运行
    ${green}3.${plain}  销毁运行
    ————————————————-
    ${green}0.${plain}  返回上一场
    "
    echo && read -ep "请输入选择 [0-13]: " num

    case "${num}" in
    0)
        show_menu_change
        ;;
    1)  
	    download
		show_menu_change
	    ;;
    2)
	   read -r -p "设置CPU时间:" cpu
       read -r -p "设置内存(GB):" memory
	   read -r -p "设置网络消耗:" network
       screen -L -dmS baohuo;
       screen -S baohuo -p 0 -X stuff "./NeverIdle -c ${cpu} -m ${memory} -n ${network}";
       screen -S baohuo -p 0 -X stuff $'\n';
       ;;
    3)
       screen -X -S baohuo quit;
       rm -rf /root/screenlog.0;
       ;;
    *)
        echo -e "${red}请输入正确的数字 [0-2]${plain}"
        ;;
    esac
}

show_menu_change
