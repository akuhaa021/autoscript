#!/bin/bash

function add-user() {
	clear
	echo -e "Add SSH & VPN User"
	echo -e "------------------"
	read -p "Username : " user
	if getent passwd $user > /dev/null 2>&1; then
		echo ""
		echo "User '$user' already exist."
		echo ""
		exit 0
	fi
	read -p "Password : " pass
	read -p "Duration (day) : " duration
	useradd -e $(date -d +${duration}days +%Y-%m-%d) -s /bin/false -M $user
	echo -e "$pass\n$pass\n"|passwd $user &> /dev/null

	exp=$(date -d +${duration}days +"%d %b %Y")

	clear
	echo -e "SSH & VPN User Information"
	echo -e "--------------------------"
	echo -e "Username : $user "
	echo -e "Password : $pass"
	echo -e "Expired date : $exp"
	echo -e ""
}

function delete-user() {
	clear
	echo -e "Delete SSH & VPN User"
	echo -e "---------------------"
	read -p "Username : " user
	echo -e ""
	if getent passwd $user > /dev/null 2>&1; then
		userdel $user
		echo -e "User '$user' deleted successfully."
		echo -e ""
	else
		echo -e "User '$user' does not exist."
		echo -e ""
	fi
}

function extend-user() {
	clear
	echo -e "Extend SSH & VPN User"
	echo -e "---------------------"
	read -p "Username : " user
	if ! getent passwd $user > /dev/null 2>&1; then
		echo -e "User '$user' does not exist."
		echo -e ""
		exit 0
	fi
	read -p "Duration (day) : " extend

	exp_old=$(chage -l $user | grep "Account expires" | awk -F": " '{print $2}')
	diff=$((($(date -d "${exp_old}" +%s)-$(date +%s))/(86400)))
	duration=$(expr $diff + $extend + 1)

	chage -E $(date -d +${duration}days +%Y-%m-%d) $user
	exp_new=$(chage -l $user | grep "Account expires" | awk -F": " '{print $2}')
	exp=$(date -d "${exp_new}" +"%d %b %Y")

	clear
	echo -e "SSH & VPN User Information"
	echo -e "--------------------------"
	echo -e "Username : $user "
	echo -e "Expired date : $exp"
	echo -e ""
}

function user-list() {
	clear
	echo -e ""
	echo -e "==============================="
	echo -e "Username          Exp. Date"
	echo -e "-------------------------------"
	while read expired; do
		account=$(echo $expired | cut -d: -f1)
		id=$(echo $expired | grep -v nobody | cut -d: -f3)
		exp=$(chage -l $account | grep "Account expires" | awk -F": " '{print $2}')

		if [[ $id -ge 1000 ]]; then
			exp_date=$(date -d "${exp}" +"%d %b %Y")
			printf "%-17s %2s\n" "$account" "$exp_date"
		fi
	done < /etc/passwd
	total=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)
	echo -e "-------------------------------"
	echo -e "Total accounts : $total"
	echo -e "==============================="
	echo -e ""
}

function user-monitor() {
	data=($(ps aux | grep -i dropbear | awk '{print $2}'))
	clear
	echo -e ""
	echo -e "=========================="
	echo -e "  Dropbear Login Monitor"
	echo -e "--------------------------"
	for pid in "${data[@]}"
	do
		num=$(cat /var/log/auth.log | grep -i dropbear | grep -i "Password auth succeeded" | grep "dropbear\[$pid\]" | wc -l)
		user=$(cat /var/log/auth.log | grep -i dropbear | grep -i "Password auth succeeded" | grep "dropbear\[$pid\]" | awk '{print $10}')
		ip=$(cat /var/log/auth.log | grep -i dropbear | grep -i "Password auth succeeded" | grep "dropbear\[$pid\]" | awk '{print $12}')
		if [ $num -eq 1 ]; then
			echo -e "$pid - $user - $ip"
		fi
	done
	echo -e "=========================="
	echo -e ""
	echo -e "==============================="
	echo -e "  OpenVPN (TCP) Login Monitor"
	echo -e "-------------------------------"
	a=$(grep -n "Common Name,Real Address,Bytes Received,Bytes Sent,Connected Since" /var/log/openvpn/server-tcp-status.log | awk -F":" '{print $1}')
	b=$(expr $(grep -n "ROUTING TABLE" /var/log/openvpn/server-tcp-status.log | awk -F":" '{print $1}') - 1)
	c=$(expr ${b} - ${a})
	cat /var/log/openvpn/server-tcp-status.log | head -n $b | tail -n $c | sed -e 's/,/\t/g' > /tmp/openvpn-tcp-login.txt
	while read login; do
		user=$(echo $login | awk '{print $1}')
		ip=$(echo $login | awk '{print $2}')
		echo -e "$user - $ip"
	done < /tmp/openvpn-tcp-login.txt
	echo -e "==============================="
	echo -e ""
	echo -e "==============================="
	echo -e "  OpenVPN (UDP) Login Monitor"
	echo -e "-------------------------------"
	a=$(grep -n "Common Name,Real Address,Bytes Received,Bytes Sent,Connected Since" /var/log/openvpn/server-udp-status.log | awk -F":" '{print $1}')
	b=$(expr $(grep -n "ROUTING TABLE" /var/log/openvpn/server-udp-status.log | awk -F":" '{print $1}') - 1)
	c=$(expr ${b} - ${a})
	cat /var/log/openvpn/server-udp-status.log | head -n $b | tail -n $c | sed -e 's/,/\t/g' > /tmp/openvpn-udp-login.txt
	while read login; do
		user=$(echo $login | awk '{print $1}')
		ip=$(echo $login | awk '{print $2}')
		echo -e "$user - $ip"
	done < /tmp/openvpn-udp-login.txt
	echo -e "==============================="
	echo -e ""
}

function ovpn-config() {
	clear
	echo -e "OpenVPN Config"
	echo -e "--------------"
	echo -e "  [1] Config TCP"
	echo -e "  [2] Config UDP"
	echo -e "  [3] Exit"
	echo -e ""
	until [[ ${option} =~ ^[1-3]$ ]]; do
		read -rp "Select an option [1-3]: " option
	done

	case "${option}" in
	1)
		clear
		echo -e "OpenVPN Config - TCP"
		echo -e "--------------------"
		echo -e ""
		cat /donboyage/openvpn/client-tcp.ovpn
		echo -e ""
		exit
		;;
	2)
		clear
		echo -e "OpenVPN Config - UDP"
		echo -e "--------------------"
		echo -e ""
		cat /donboyage/openvpn/client-udp.ovpn
		echo -e ""
		exit
		;;
	3)
		clear
		exit 0
		;;
	esac
}

clear
echo -e "====[ SSH & VPN Menu ]===="
echo -e ""
echo -e "  [1] Add user"
echo -e "  [2] Delete user"
echo -e "  [3] Extend user"
echo -e "  [4] User list"
echo -e "  [5] User monitor"
echo -e "  [6] OVPN config"
echo -e "  [7] Exit"
echo -e ""
until [[ ${option} =~ ^[1-7]$ ]]; do
	read -rp "Select an option [1-7]: " option
done

case "${option}" in
	1)
		add-user
		exit
		;;
	2)
		delete-user
		exit
		;;
	3)
		extend-user
		exit
		;;
	4)
		user-list
		exit
		;;
	5)
		user-monitor
		exit
		;;
	6)
		ovpn-config
		exit
		;;
	7)
		clear
		exit 0
		;;
esac