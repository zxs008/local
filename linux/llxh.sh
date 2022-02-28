#bin/bash!

#Github @luoxue-bot
#Blog https://ty.al

url=""

function MediaUnlockTest() {
  echo -e "${url}"
  while true
  do
    timeData=$(TZ=UTC-8 date "+%Y-%m-%d %H:%M:%S")
    echo -e "${timeData}"
    wget ${url} -O ll.test
    rm -rf ll.test
  done
}

show_menu() {
    echo -e "Vultr测试文件"
    echo -e "
    ${green}1.${plain}  日本东京
    ${green}2.${plain}  新加披
    ${green}3.${plain}  首尔
    ${green}4.${plain}  英国伦敦
    ${green}5.${plain}  德国法兰克福
    ${green}6.${plain}  法国巴黎
    ${green}7.${plain}  荷兰阿姆斯特丹
    ${green}8.${plain}  美国迈阿密
    ${green}9.${plain}  美国亚特兰大
    ${green}10.${plain}  美国芝加哥
    ${green}11.${plain}  美国硅谷
    ${green}12.${plain}  美国达拉斯
    ${green}13.${plain}  美国洛杉矶
    ${green}14.${plain}  美国新泽西
    ${green}15.${plain}  美国西雅图
    ${green}16.${plain}  澳大利亚悉尼
    ————————————————-
    ${green}0.${plain}  退出脚本
    "
    echo && read -ep "请输入选择 [0-13]: " num

    case "${num}" in
    0)
        exit 0
        ;;
    1)
        url="https://hnd-jp-ping.vultr.com/vultr.com.1000MB.bin";
        MediaUnlockTest
        ;;
    2)
        url="https://sgp-ping.vultr.com/vultr.com.1000MB.bin";
        MediaUnlockTest
        ;;
    3)
        url="https://sel-kor-ping.vultr.com/vultr.com.1000MB.bin";
        MediaUnlockTest
        ;;
    4)
        url="https://lon-gb-ping.vultr.com/vultr.com.1000MB.bin";
        MediaUnlockTest
        ;;
    5)
        url="https://fra-de-ping.vultr.com/vultr.com.1000MB.bin";
        MediaUnlockTest
        ;;
    6)
        url="https://par-fr-ping.vultr.com/vultr.com.1000MB.bin";
        MediaUnlockTest
        ;;
    7)
        url="https://ams-nl-ping.vultr.com/vultr.com.1000MB.bin";
        MediaUnlockTest
        ;;
    8)
        url="https://fl-us-ping.vultr.com/vultr.com.1000MB.bin";
        MediaUnlockTest
        ;;
    9)
        url="https://ga-us-ping.vultr.com/vultr.com.1000MB.bin";
        MediaUnlockTest
        ;;
    10)
        url="https://il-us-ping.vultr.com/vultr.com.1000MB.bin";
        MediaUnlockTest
        ;;
    11)
        url="https://sjo-ca-us-ping.vultr.com/vultr.com.1000MB.bin";
        MediaUnlockTest
        ;;
    12)
        url="https://tx-us-ping.vultr.com/vultr.com.1000MB.bin";
        MediaUnlockTest
        ;;
    13)
        url="https://lax-ca-us-ping.vultr.com/vultr.com.1000MB.bin";
        MediaUnlockTest
        ;;
    14)
        url="https://nj-us-ping.vultr.com/vultr.com.1000MB.bin";
        MediaUnlockTest
        ;;
    15)
        url="https://wa-us-ping.vultr.com/vultr.com.1000MB.bin";
        MediaUnlockTest
        ;;
    16)
        url="https://syd-au-ping.vultr.com/vultr.com.1000MB.bin";
        MediaUnlockTest
        ;;
    *)
        echo -e "${red}请输入正确的数字 [0-13]${plain}"
        ;;
    esac
}

show_menu
