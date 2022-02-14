#bin/bash!

#Github @luoxue-bot
#Blog https://ty.al
ipp="4"
test='
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"

function MediaUnlockTest() {
echo -e " ${Font_SkyBlue}** 正在测试IPv${ip},${area}地区解锁情况${Font_Suffix} 设定时间为${time}"
while true
do
    result=$(curl -${ip} --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81215567" 2>&1)
    IPV4=$(curl -s${ip}m8 https://api64.ipify.org?format=json)
    echo -e "${IPV4}"
    if [[ "$result" == "404" ]];then
        echo -e "Originals Only, Changing IP..."
        systemctl restart wg-quick@wgcf
        sleep 3
	
    elif  [[ "$result" == "403" ]];then
        echo -e "No, Changing IP..."
        systemctl restart wg-quick@wgcf
        sleep 3
	
    elif  [[ "$result" == "200" ]];then
		region=`tr [:lower:] [:upper:] <<< $(curl -${ip} --user-agent "${UA_Browser}" -fs --max-time 10 --write-out %{redirect_url} --output /dev/null "https://www.netflix.com/title/80018499" | cut -d '/' -f4 | cut -d '-' -f1)` ;
		if [[ ! "$region" ]];then
			region="US";
		fi
        if [[ "$region" != "$area" ]];then
            echo -e "Region: ${region} Not match, Changing IP..."
            systemctl restart wg-quick@wgcf
            sleep 3
        else
            echo -e "Region: ${region} Done, monitoring..."
            sleep ${time}
        fi

    elif  [[ "$result" == "000" ]];then
	echo -e "Failed, retrying..."
        systemctl restart wg-quick@wgcf
    fi
done
}

MediaUnlockTest
'

show_menu_change() {
    echo -e "
    ${green}1.${plain}  配置warp
    ${green}2.${plain}  后台运行
    ${green}3.${plain}  销毁运行
    ————————————————-
    ${green}0.${plain}  返回上一场
    "
    echo && read -ep "请输入选择 [0-13]: " num

    case "${num}" in
    0)
        show_menu
        ;;
    1)
        rm -rf /root/warpAuto.sh
        read -r -p "想要解锁的地区(e.g. HK,SG):" area
        read -r -p "设置刷新时间秒为单位:" time
        echo "ip='"${ipp}"'" >> /root/warpAuto.sh
        echo "area='"${area}"'" >> /root/warpAuto.sh
        echo "time='"${time}"'" >> /root/warpAuto.sh
        echo "${test}" >> /root/warpAuto.sh
        ;;
    2)
       screen -L -dmS warp;
       screen -S warp -p 0 -X stuff "bash warpAuto.sh";
       screen -S warp -p 0 -X stuff $'\n';
       ;;
    3)
       screen -X -S warp quit;
       ;;
    *)
        echo -e "${red}请输入正确的数字 [0-2]${plain}"
        ;;
    esac
}

show_menu_change
