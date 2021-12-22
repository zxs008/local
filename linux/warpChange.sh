#bin/bash!

#Github @luoxue-bot
#Blog https://ty.al

UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"

function MediaUnlockTest() {
while true
do
    result=$(curl -${1} --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81215567" 2>&1)
    if [[ "$result" == "404" ]];then
        echo -e "Originals Only, Changing IP..."
        systemctl restart wg-quick@wgcf
        sleep 3
	
    elif  [[ "$result" == "403" ]];then
        echo -e "No, Changing IP..."
        systemctl restart wg-quick@wgcf
        sleep 3
	
    elif  [[ "$result" == "200" ]];then
		region=`tr [:lower:] [:upper:] <<< $(curl ${1} --user-agent "${UA_Browser}" -fs --max-time 10 --write-out %{redirect_url} --output /dev/null "https://www.netflix.com/title/80018499" | cut -d '/' -f4 | cut -d '-' -f1)` ;
		if [[ ! "$region" ]];then
			region="US";
		fi
        if [[ "$region" != "$area" ]];then
            echo -e "Region: ${region} Not match, Changing IP..."
            systemctl restart wg-quick@wgcf
            sleep 3
        else
            echo -e "Region: ${region} Done, monitoring..."
            return
        fi

    elif  [[ "$result" == "000" ]];then
	echo -e "Failed, retrying..."
        systemctl restart wg-quick@wgcf
    fi
done
}

show_menu_change() {
    echo -e "
    ${green}1.${plain}  IPv4
    ${green}2.${plain}  IPv6
    ————————————————-
    ${green}0.${plain}  返回上一场
    "
    echo && read -ep "请输入选择 [0-13]: " num

    case "${num}" in
    0)
        show_menu
        ;;
    1)
        read -r -p "Input the region you want(e.g. HK,SG):" area
        echo -e " ${Font_SkyBlue}** 正在测试IPv4解锁情况${Font_Suffix} "
        MediaUnlockTest 4
        ;;
    2)
        read -r -p "Input the region you want(e.g. HK,SG):" area
        echo -e " ${Font_SkyBlue}** 正在测试IPv6解锁情况${Font_Suffix} "
        MediaUnlockTest 6
        ;;
    *)
        echo -e "${red}请输入正确的数字 [0-2]${plain}"
        ;;
    esac
}

show_menu() {
    echo -e "
    ${green}1.${plain}  wrap
    ${green}2.${plain}  自动检测
    ————————————————-
    ${green}0.${plain}  退出脚本
    "
    echo && read -ep "请输入选择 [0-13]: " num

    case "${num}" in
    0)
        exit 0
        ;;
    1)
        bash <( curl -fsSL https://zxs008.github.io/local/linux/warp.sh ) menu
        ;;
    2)
        show_menu_change
        ;;
    *)
        echo -e "${red}请输入正确的数字 [0-13]${plain}"
        ;;
    esac
}

show_menu
