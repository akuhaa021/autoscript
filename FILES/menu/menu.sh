#!/bin/bash

function login-limit() {
	clear
	limit=$(cat /iriszz/script-3/limit)
	echo -e ""
	echo -e "Current Dropbear multi-login limit: $limit"
	echo -e ""
	read -p "New Dropbear multi-login limit: " new_limit
	echo $new_limit > /iriszz/script-3/limit
	service script-3 restart
	clear
	echo -e ""
	echo -e "Dropbear multi-login limit has been changed from '$limit' to '$new_limit'."
	echo -e ""
}

function block-conn() {
	clear
	status=$(cat /iriszz/block-status)
	if [ "$status" == on ]; then
		echo -e "Do you want to allow all connections?"
		echo -e "  [1] Yes"
		echo -e "  [2] No"
		echo -e ""
		until [[ ${option} =~ ^[1-2]$ ]]; do
			read -rp "Select an option [1-2]: " option
		done
		if [ $option -eq 1 ]; then
			ufw allow 85 > /dev/null 2>&1
			ufw allow 465 > /dev/null 2>&1
			ufw allow 8080 > /dev/null 2>&1
			ufw allow 1194 > /dev/null 2>&1
			ufw allow 80 > /dev/null 2>&1
			ufw allow 443 > /dev/null 2>&1
			ufw allow 51820 > /dev/null 2>&1
			ufw allow 7300 > /dev/null 2>&1
			ufw allow 8000 > /dev/null 2>&1
			ufw allow 3128 > /dev/null 2>&1
			echo off > /iriszz/block-status
		elif [ $option -eq 2 ]; then
			clear
			exit 0
		fi
		clear
		echo -e ""
		echo -e "All connections to the VPS is allowed."
		echo -e ""
	elif [ "$status" == off ]; then
		echo -e "Do you want to block all connections?"
		echo -e "  [1] Yes"
		echo -e "  [2] No"
		echo -e ""
		until [[ ${option} =~ ^[1-2]$ ]]; do
			read -rp "Select an option [1-2]: " option
		done
		if [ $option -eq 1 ]; then
			ufw delete allow 85 > /dev/null 2>&1
			ufw delete allow 465 > /dev/null 2>&1
			ufw delete allow 8080 > /dev/null 2>&1
			ufw delete allow 1194 > /dev/null 2>&1
			ufw delete allow 80 > /dev/null 2>&1
			ufw delete allow 443 > /dev/null 2>&1
			ufw delete allow 51820 > /dev/null 2>&1
			ufw delete allow 7300 > /dev/null 2>&1
			ufw delete allow 8000 > /dev/null 2>&1
			ufw delete allow 3128 > /dev/null 2>&1
			echo on > /iriszz/block-status
		elif [ $option -eq 2 ]; then
			clear
			exit 0
		fi
		clear
		echo -e ""
		echo -e "All connections to the VPS is blocked, except SSH (22)."
		echo -e ""
	else
		echo -e "Error!"
	fi
}

limit=$(cat /iriszz/script-3/limit)
status=$(cat /iriszz/block-status)

clear
echo -e "===========[ Script Menu ]==========="
echo -e ""
echo -e "VPN Services"
echo -e "------------"
echo -e "  [1] SSH & OVPN Menu"
echo -e "  [2] Xray (Vless) Menu"
echo -e "  [3] WireGuard Menu"
echo -e ""
echo -e "Server Tools"
echo -e "------------"
echo -e "  [4] Server Speedtest"
echo -e "  [5] Server Benchmark"
echo -e ""
echo -e "Script Settings"
echo -e "---------------"
echo -e "  [6] Set Dropbear multi-login limit"
echo -e "      + Current limit: $limit"
echo -e "  [7] Block all connections"
echo -e "      + Current status: $status"
echo -e "  [8] Script info"
echo -e ""
echo -e "  [9] Exit"
echo -e ""
until [[ ${option} =~ ^[1-9]$ ]]; do
	read -rp "Select an option [1-9]: " option
done

case "${option}" in
	1)
		ssh-vpn-script
		exit
		;;
	2)
		xray-script
		exit
		;;
	3)
		wireguard-script
		exit
		;;
	4)
		clear
		speedtest
		echo -e ""
		exit
		;;
	5)
		clear
		echo -e ""
		wget -qO- wget.racing/nench.sh | bash
		exit
		;;
	6)
		login-limit
		exit
		;;
	7)
		block-conn
		exit
		;;
	8)
		script-info
		exit
		;;
	9)
		clear
		exit 0
		;;
esac