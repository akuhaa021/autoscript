#!/bin/bash

today=$(date +%Y-%m-%d)

while read expired
do
	account=$(echo $expired | cut -d: -f1)
	id=$(echo $expired | grep -v nobody | cut -d: -f3)
	exp=$(chage -l $account | grep "Account expires" | awk -F": " '{print $2}')
	if [[ $id -ge 1000 ]]; then
		read mon day year <<< $exp
		exp_date="$(date -d "$mon $day $year" "+%Y-%m-%d")"
		if [[ $exp_date < $today ]]; then
			userdel $account
		fi
	fi
done < /etc/passwd

# Block Torrent
iptables -A FORWARD -m string --string "get_peers" --algo bm -j DROP
iptables -A FORWARD -m string --string "announce_peer" --algo bm -j DROP
iptables -A FORWARD -m string --string "find_node" --algo bm -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -A FORWARD -m string --algo bm --string "peer_id=" -j DROP
iptables -A FORWARD -m string --algo bm --string ".torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -A FORWARD -m string --algo bm --string "torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce" -j DROP
iptables -A FORWARD -m string --algo bm --string "info_hash" -j DROP