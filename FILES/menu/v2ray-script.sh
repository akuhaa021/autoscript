#!/bin/bash

function add-user() {
	clear
	echo -e "Add V2Ray User"
	echo -e "--------------"
	read -p "Username : " user
	if grep -qw "$user" /donb/v2ray/v2ray-clients.txt; then
		echo -e ""
		echo -e "User '$user' already exist."
		echo -e ""
		exit 0
	fi
	read -p "Duration (day) : " duration

	uuid=$(uuidgen)
	exp=$(date -d +${duration}days +%Y-%m-%d)
	expired=$(date -d "${exp}" +"%d %b %Y")
	domain=$(cat /usr/local/etc/v2ray/domain)
	email=${user}@${domain}
	echo -e "${user}\t${uuid}\t${exp}" >> /donb/v2ray/v2ray-clients.txt

	cat /usr/local/etc/v2ray/ws-tls.json | jq '.inbounds[0].settings.clients += [{"id": "'${uuid}'","alterId": 2,"email": "'${email}'"}]' > /usr/local/etc/v2ray/ws-tls_tmp.json
	mv -f /usr/local/etc/v2ray/ws-tls_tmp.json /usr/local/etc/v2ray/ws-tls.json
	cat /usr/local/etc/v2ray/ws.json | jq '.inbounds[0].settings.clients += [{"id": "'${uuid}'","alterId": 2,"email": "'${email}'"}]' > /usr/local/etc/v2ray/ws_tmp.json
	mv -f /usr/local/etc/v2ray/ws_tmp.json /usr/local/etc/v2ray/ws.json
	service v2ray@ws-tls restart
	service v2ray@ws restart

	clear
	echo -e "V2Ray User Information"
	echo -e "----------------------"
	echo -e "Username : $user"
	echo -e "Expired date : $expired"
	echo -e ""
}

function delete-user() {
	clear
	echo -e "Delete V2Ray User"
	echo -e "-----------------"
	read -p "Username : " user
	echo -e ""
	if ! grep -qw "$user" /donb/v2ray/v2ray-clients.txt; then
		echo -e ""
		echo -e "User '$user' does not exist."
		echo -e ""
		exit 0
	fi
	uuid="$(cat /donb/v2ray/v2ray-clients.txt | grep -w "$user" | awk '{print $2}')"

	cat /usr/local/etc/v2ray/ws-tls.json | jq 'del(.inbounds[0].settings.clients[] | select(.id == "'${uuid}'"))' > /usr/local/etc/v2ray/ws-tls_tmp.json
	mv -f /usr/local/etc/v2ray/ws-tls_tmp.json /usr/local/etc/v2ray/ws-tls.json
	cat /usr/local/etc/v2ray/ws.json | jq 'del(.inbounds[0].settings.clients[] | select(.id == "'${uuid}'"))' > /usr/local/etc/v2ray/ws_tmp.json
	mv -f /usr/local/etc/v2ray/ws_tmp.json /usr/local/etc/v2ray/ws.json
	sed -i "/\b$user\b/d" /donb/v2ray/v2ray-clients.txt
	service v2ray@ws-tls restart
	service v2ray@ws restart

	echo -e "User '$user' deleted successfully."
	echo -e ""
}

function extend-user() {
	clear
	echo -e "Extend V2Ray User"
	echo -e "-----------------"
	read -p "Username : " user
	if ! grep -qw "$user" /donb/v2ray/v2ray-clients.txt; then
		echo -e ""
		echo -e "User '$user' does not exist."
		echo -e ""
		exit 0
	fi
	read -p "Duration (day) : " extend

	uuid=$(cat /donb/v2ray/v2ray-clients.txt | grep -w $user | awk '{print $2}')
	exp_old=$(cat /donb/v2ray/v2ray-clients.txt | grep -w $user | awk '{print $3}')
	diff=$((($(date -d "${exp_old}" +%s)-$(date +%s))/(86400)))
	duration=$(expr $diff + $extend + 1)
	exp_new=$(date -d +${duration}days +%Y-%m-%d)
	exp=$(date -d "${exp_new}" +"%d %b %Y")

	sed -i "/\b$user\b/d" /donb/v2ray/v2ray-clients.txt
	echo -e "$user\t$uuid\t$exp_new" >> /donb/v2ray/v2ray-clients.txt

	clear
	echo -e "V2Ray User Information"
	echo -e "----------------------"
	echo -e "Username : $user"
	echo -e "Expired date : $exp"
	echo -e ""
}

function user-list() {
	clear
	echo -e ""
	echo -e "==============================="
	echo -e "Username          Exp. Date"
	echo -e "-------------------------------"
	while read expired
	do
		user=$(echo $expired | awk '{print $1}')
		exp=$(echo $expired | awk '{print $3}')
		exp_date=$(date -d"${exp}" "+%d %b %Y")
		printf "%-17s %2s\n" "$user" "$exp_date"
	done < /donb/v2ray/v2ray-clients.txt
	total=$(wc -l /donb/v2ray/v2ray-clients.txt | awk '{print $1}')
	echo -e "-------------------------------"
	echo -e "Total accounts: $total"
	echo -e "==============================="
	echo -e ""
}

function user-monitor() {
	data=($(cat /donb/v2ray/v2ray-clients.txt | awk '{print $1}'))
	data2=($(netstat -anp | grep ESTABLISHED | grep tcp6 | grep v2ray | grep -w '80\|443' | awk '{print $5}' | cut -d: -f1 | sort | uniq))
	domain=$(cat /usr/local/etc/v2ray/domain)
	clear
	echo -e ""
	echo -e "========================="
	echo -e "   V2Ray Login Monitor"
	echo -e "-------------------------"
	for user in "${data[@]}"
	do
		touch /tmp/ipv2ray.txt
		for ip in "${data2[@]}"
		do
			total=$(cat /var/log/v2ray/access.log | grep -w ${user}@${domain} | awk '{print $3}' | cut -d: -f1 | grep -w $ip | sort | uniq)
			if [[ "$total" == "$ip" ]]; then
				echo -e "$total" >> /tmp/ipv2ray.txt
			fi
		done
		total=$(cat /tmp/ipv2ray.txt)
		if [[ -n "$total" ]]; then
			total2=$(cat /tmp/ipv2ray.txt | nl)
			echo -e "$user :"
			echo -e "$total2"
		fi
		rm -f /tmp/ipv2ray.txt
	done
	echo -e "========================="
	echo -e ""
}

function show-config() {
	echo -e "V2Ray Config"
	echo -e "------------"
	read -p "User : " user
	if ! grep -qw "$user" /donb/v2ray/v2ray-clients.txt; then
		echo -e ""
		echo -e "User '$user' does not exist."
		echo -e ""
		exit 0
	fi
	uuid=$(cat /donb/v2ray/v2ray-clients.txt | grep -w "$user" | awk '{print $2}')
	domain=$(cat /usr/local/etc/v2ray/domain)
	exp=$(cat /donb/v2ray/v2ray-clients.txt | grep -w "$user" | awk '{print $3}')
	exp_date=$(date -d"${exp}" "+%d %b %Y")

	cat> /tmp/v2ray_ws_tls_client.json << END
{
  "v": "2",
  "ps": "V2RAY_WS_TLS-${user}",
  "add": "${domain}",
  "port": "443",
  "id": "${uuid}",
  "aid": "2",
  "host": "${domain}",
  "path": "/v2ray",
  "net": "ws",
  "security": "auto",
  "tls": "tls",
  "sni": "${domain}"
}
END
	cat> /tmp/v2ray_ws_client.json << END
{
  "v": "2",
  "ps": "V2RAY_WS-${user}",
  "add": "${domain}",
  "port": "80",
  "id": "${uuid}",
  "aid": "2",
  "host": "${domain}",
  "path": "/v2ray",
  "net": "ws",
  "security": "auto"
}
END

	vmess_ws_tls="vmess://$(base64 -w 0 /tmp/v2ray_ws_tls_client.json)"
	vmess_ws="vmess://$(base64 -w 0 /tmp/v2ray_ws_client.json)"
	rm -f /tmp/{v2ray_ws_tls_client.json,v2ray_ws_client.json}

	echo -e "Expired : $exp_date"
	echo -e ""
	echo -e "VMESS + WebSocket + TLS"
	echo -e "-----------------------"
	echo -e "Address : ${domain}"
	echo -e "Port : 443"
	echo -e "ID : ${uuid}"
	echo -e "alterID : 2"
	echo -e "Security : auto"
	echo -e "Network : ws"
	echo -e "Path : /v2ray"
	echo -e "TLS : tls"
	echo -e ""
	echo -e "Link : $vmess_ws_tls"
	echo -e ""
	echo -e "QR : https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=$vmess_ws_tls"
	echo -e ""
	echo -e "VMESS + WebSocket"
	echo -e "-----------------"
	echo -e "Address : ${domain}"
	echo -e "Port : 80"
	echo -e "ID : ${uuid}"
	echo -e "alterID : 2"
	echo -e "Security : auto"
	echo -e "Network : ws"
	echo -e "Path : /v2ray"
	echo -e ""
	echo -e "Link : $vmess_ws"
	echo -e ""
	echo -e "QR : https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=$vmess_ws"
	echo -e ""
}

clear
echo -e "=========[ V2Ray Menu ]========="
echo -e ""
echo -e "  [1] Add V2Ray user"
echo -e "  [2] Delete V2Ray user"
echo -e "  [3] Extend V2Ray user"
echo -e "  [4] V2Ray user list"
echo -e "  [5] V2Ray user monitor"
echo -e "  [6] Show V2Ray configuration"
echo -e "  [7] Exit"
echo -e ""
until [[ ${option} =~ ^[1-7]$ ]]; do
	read -rp "Select an option [1-7]: " option
done
case "${option}" in
1)
	add-user
	;;
2)
	delete-user
	;;
3)
	extend-user
	;;
4)
	user-list
	;;
5)
	user-monitor
	;;
6)
	clear
	show-config
	;;
7)
	clear
	exit 0
	;;
esac