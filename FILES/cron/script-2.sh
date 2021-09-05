#!/bin/bash

apt update
apt upgrade -y

today=$(date -d +1day +%Y-%m-%d)

while read expired
do
	user=$(echo $expired | awk '{print $1}')
	uuid=$(echo $expired | awk '{print $2}')
	exp=$(echo $expired | awk '{print $3}')

	if [[ $exp < $today ]]; then
		cat /usr/local/etc/xray/config.json | jq 'del(.inbounds[0].settings.clients[] | select(.id == "'${uuid}'"))' >/usr/local/etc/xray/config_tmp.json
		mv -f /usr/local/etc/xray/config_tmp.json /usr/local/etc/xray/config.json
		cat /usr/local/etc/xray/config.json | jq 'del(.inbounds[1].settings.clients[] | select(.id == "'${uuid}'"))' >/usr/local/etc/xray/config_tmp.json
		mv -f /usr/local/etc/xray/config_tmp.json /usr/local/etc/xray/config.json
		sed -i "/\b$user\b/d" /iriszz/xray/xray-clients.txt
	fi
done < /iriszz/xray/xray-clients.txt

unset expired
while read expired
do
	user=$(echo $expired | awk '{print $1}')
	exp=$(echo $expired | awk '{print $3}')

	if [[ $exp < $today ]]; then
		sed -i "/^### Client ${user}\$/,/^$/d" /etc/wireguard/wg0.conf
		if grep -q "### Client" /etc/wireguard/wg0.conf; then
			line=$(grep -n AllowedIPs /etc/wireguard/wg0.conf | tail -1 | awk -F: '{print $1}')
			head -${line} /etc/wireguard/wg0.conf > /tmp/wg0.conf
			mv /tmp/wg0.conf /etc/wireguard/wg0.conf
		else
			head -7 /etc/wireguard/wg0.conf > /tmp/wg0.conf
			mv /tmp/wg0.conf /etc/wireguard/wg0.conf
		fi
		rm -f /iriszz/wireguard/${user}.conf
		sed -i "/\b$user\b/d" /iriszz/wireguard/wireguard-clients.txt
	fi
done < /iriszz/wireguard/wireguard-clients.txt