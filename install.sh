
# Get domain
clear
echo -e ""
read -p "Please enter your domain : " domain
echo -e ""
ip=$(wget -qO- ipv4.icanhazip.com)
domain_ip=$(ping "${domain}" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
if [[ ${domain_ip} == "${ip}" ]]; then
	echo -e "IP matched with the server. The installation will continue."
	sleep 2
	clear
else
	echo -e "IP does not match with the server. Make sure to point A record to your server."
	echo -e ""
	exit 1
fi

# Update & Upgrade
apt update
apt upgrade -y

# Remove unused dependencies
apt autoremove -y

# Set timezone
ln -sf /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime

# Disable IPv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
echo -e "net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf

# Install BBR+FQ
echo -e "net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

# Configure UFW
apt install -y ufw
sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/g' /etc/default/ufw
sed -i "s/IPV6=yes/IPV6=no/g" /etc/default/ufw
ufw allow 22
ufw allow 85
ufw allow 465
ufw allow 8080
ufw allow 1194
ufw allow 80
ufw allow 443
ufw allow 51820
ufw allow 7300
ufw allow 8000
ufw allow 3128
ufw allow 3646
ufw reload
echo -e "y" | ufw enable

# Install tools
apt install -y net-tools vnstat unzip curl screen

# Install screenfetch
wget -qO /usr/bin/screenfetch "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/screenfetch.sh"
chmod +x /usr/bin/screenfetch
echo -e "clear
screenfetch
echo" >> .profile

# Configure SSH
echo -e "AllowUsers root" >> /etc/ssh/sshd_config
wget -qO /etc/issue.net "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/issue.net"
sed -i "s/#Banner none/Banner \/etc\/issue.net/g" /etc/ssh/sshd_config
service ssh restart

# Install Dropbear
apt install -y dropbear
sed -i "s/NO_START=1/NO_START=0/g" /etc/default/dropbear
sed -i "s/DROPBEAR_PORT=22/DROPBEAR_PORT=85/g" /etc/default/dropbear
echo -e "/bin/false" >> /etc/shells
wget -qO /etc/dropbear_issue.net "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/dropbear_issue.net"
sed -i 's|DROPBEAR_BANNER=""|DROPBEAR_BANNER="/etc/dropbear_issue.net"|g' /etc/default/dropbear
service dropbear restart

# Install Stunnel
apt install -y stunnel4
sed -i "s/ENABLED=0/ENABLED=1/g" /etc/default/stunnel4
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -sha256 -subj "/CN=Don/emailAddress=jeromelaliag685@gmail.com/O=Don VPN/OU=Don VPN Premium/C=MY" -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem
wget -qO /etc/stunnel/stunnel.conf "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/stunnel.conf"
service stunnel4 restart

# Install Squid3
apt install -y squid3
wget -qO /etc/squid/squid.conf "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/squid.conf"
sed -i "s/xx/$domain/g" /etc/squid/squid.conf
sed -i "s/ip/$ip/g" /etc/squid/squid.conf
service squid restart

# Install OpenVPN
apt install -y openvpn
wget -q "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/openvpn/EasyRSA-3.0.8.tgz"
tar xvf EasyRSA-3.0.8.tgz
rm EasyRSA-3.0.8.tgz
mv EasyRSA-3.0.8 /etc/openvpn/easy-rsa
cp /etc/openvpn/easy-rsa/vars.example /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_REQ_COUNTRY\t"US"/set_var EASYRSA_REQ_COUNTRY\t"MY"/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_REQ_PROVINCE\t"California"/set_var EASYRSA_REQ_PROVINCE\t"Kedah"/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_REQ_CITY\t"San Francisco"/set_var EASYRSA_REQ_CITY\t"Bandar Baharu"/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_REQ_ORG\t"Copyleft Certificate Co"/set_var EASYRSA_REQ_ORG\t\t"Don VPN"/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_REQ_EMAIL\t"me@example.net"/set_var EASYRSA_REQ_EMAIL\t"jeromelaliag685@gmail.com"/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_REQ_OU\t\t"My Organizational Unit"/set_var EASYRSA_REQ_OU\t\t"Don VPN Premium"/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_CA_EXPIRE\t3650/set_var EASYRSA_CA_EXPIRE\t3650/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_CERT_EXPIRE\t825/set_var EASYRSA_CERT_EXPIRE\t3650/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_REQ_CN\t\t"ChangeMe"/set_var EASYRSA_REQ_CN\t\t"Don VPN"/g' /etc/openvpn/easy-rsa/vars
cd /etc/openvpn/easy-rsa
./easyrsa --batch init-pki
./easyrsa --batch build-ca nopass
./easyrsa gen-dh
./easyrsa build-server-full server nopass
cd
mkdir /etc/openvpn/key
cp /etc/openvpn/easy-rsa/pki/issued/server.crt /etc/openvpn/key/
cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn/key/
cp /etc/openvpn/easy-rsa/pki/dh.pem /etc/openvpn/key/
cp /etc/openvpn/easy-rsa/pki/private/server.key /etc/openvpn/key/
wget -qO /etc/openvpn/server-udp.conf "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/openvpn/server-udp.conf"
wget -qO /etc/openvpn/server-tcp.conf "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/openvpn/server-tcp.conf"
sed -i "s/#AUTOSTART="all"/AUTOSTART="all"/g" /etc/default/openvpn
echo -e "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p
echo -e "\n# START OPENVPN RULES
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Allow traffic from OpenVPN client to eth0
-I POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
-I POSTROUTING -s 10.9.0.0/24 -o eth0 -j MASQUERADE
COMMIT
# END OPENVPN RULES" >> /etc/ufw/before.rules
ufw reload
systemctl start openvpn@server-udp
systemctl start openvpn@server-tcp
systemctl enable openvpn@server-udp
systemctl enable openvpn@server-tcp

# Configure OpenVPN client configuration
mkdir -p /donboyage/openvpn
wget -qO /donboyage/openvpn/client-udp.ovpn "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/openvpn/client-udp.ovpn"
wget -qO /donboyage/openvpn/client-tcp.ovpn "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/openvpn/client-tcp.ovpn"
sed -i "s/xx/$ip/g" /donboyage/openvpn/client-udp.ovpn
sed -i "s/xx/$ip/g" /donboyage/openvpn/client-tcp.ovpn
echo -e "\n<ca>" >> /donboyage/openvpn/client-tcp.ovpn
cat "/etc/openvpn/key/ca.crt" >> /donboyage/openvpn/client-tcp.ovpn
echo -e "</ca>" >> /donboyage/openvpn/client-tcp.ovpn
echo -e "\n<ca>" >> /donboyage/openvpn/client-udp.ovpn
cat "/etc/openvpn/key/ca.crt" >> /donboyage/openvpn/client-udp.ovpn
echo -e "</ca>" >> /donboyage/openvpn/client-udp.ovpn

# Install Xray
apt-get install -y lsb-release gnupg2 wget lsof tar unzip curl libpcre3 libpcre3-dev zlib1g-dev openssl libssl-dev jq nginx uuid-runtime
curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh | bash -s -- install
echo $domain > /usr/local/etc/xray/domain
wget -qO /usr/local/etc/xray/config.json "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/xray/xray_tls_ws_mix-rprx-direct.json"
wget -qO /etc/nginx/conf.d/${domain}.conf "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/xray/web.conf"
sed -i "s/xxx/${domain}/g" /etc/nginx/conf.d/${domain}.conf
sed -i "s/x.x.x.x/${ip}/g" /etc/nginx/conf.d/${domain}.conf
wget -qO web.tar.gz "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/web.tar.gz"
rm -rf /var/www/html/*
tar xzf web.tar.gz -C /var/www/html
rm -f web.tar.gz
mkdir /donboyage/xray
curl -L get.acme.sh | bash
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
sed -i "6s/^/#/" /etc/nginx/conf.d/${domain}.conf
sed -i "6a\\\troot /var/www/html/;" /etc/nginx/conf.d/${domain}.conf
systemctl restart nginx
/root/.acme.sh/acme.sh --issue -d "${domain}" --webroot "/var/www/html/" -k ec-256 --force
/root/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath /donboyage/xray/xray.crt --keypath /donboyage/xray/xray.key --reloadcmd "systemctl restart xray" --ecc --force
sed -i "7d" /etc/nginx/conf.d/${domain}.conf
sed -i "6s/#//" /etc/nginx/conf.d/${domain}.conf
chown -R nobody.nogroup /donboyage/xray/xray.crt
chown -R nobody.nogroup /donboyage/xray/xray.key
touch /donboyage/xray/xray-clients.txt
sed -i "s/\tinclude \/etc\/nginx\/sites-enabled\/\*;/\t# include \/etc\/nginx\/sites-enabled\/\*;asd/g" /etc/nginx/nginx.conf
mkdir /etc/systemd/system/nginx.service.d
printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" | tee /etc/systemd/system/nginx.service.d/override.conf
systemctl daemon-reload
systemctl restart nginx
systemctl restart xray

# Install WireGuard
echo -e "deb http://ftp.debian.org/debian buster-backports main" >> /etc/apt/sources.list.d/buster-backports.list
apt update
apt install -y wireguard iptables resolvconf qrencode
server_priv_key=$(wg genkey)
server_pub_key=$(echo "${server_priv_key}" | wg pubkey)
echo -e "ip=${ip}
server_priv_key=${server_priv_key}
server_pub_key=${server_pub_key}" > /etc/wireguard/params
source /etc/wireguard/params
echo -e "[Interface]
Address = 10.66.66.1/24
ListenPort = 51820
PrivateKey = ${server_priv_key}
PostUp = iptables -A FORWARD -i eth0 -o wg0 -j ACCEPT; iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i eth0 -o wg0 -j ACCEPT; iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE" >> /etc/wireguard/wg0.conf
systemctl start "wg-quick@wg0"
systemctl enable "wg-quick@wg0"
mkdir /donboyage/wireguard
touch /donboyage/wireguard/wireguard-clients.txt

# Install OHP
wget -qO /usr/bin/ohpserver "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/ohpserver"
chmod +x /usr/bin/ohpserver
screen -AmdS ohp-dropbear ohpserver -port 3128 -proxy 127.0.0.1:8080 -tunnel 127.0.0.1:85
screen -AmdS ohp-openvpn ohpserver -port 8000 -proxy 127.0.0.1:8080 -tunnel 127.0.0.1:1194

# Install BadVPN UDPGw
cd
apt install -y cmake
wget -qO badvpn.zip "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/badvpn.zip"
unzip badvpn.zip
cd badvpn-master
mkdir build-badvpn
cd build-badvpn
cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
make install
cd
rm -r badvpn-master
rm badvpn.zip
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300

# Install Speedtest cli
curl -s https://install.speedtest.net/app/cli/install.deb.sh | bash
apt install speedtest

# Install fail2ban
apt install -y fail2ban
service fail2ban restart

# Install DDoS Deflate
apt install -y dnsutils tcpdump dsniff grepcidr
wget -qO ddos.zip "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/ddos-deflate.zip"
unzip ddos.zip
cd ddos-deflate
chmod +x install.sh
./install.sh
cd
rm -rf ddos.zip ddos-deflate

# Configure script
wget -qO /usr/bin/menu "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/menu/menu.sh"
wget -qO /usr/bin/ssh-vpn-script "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/menu/ssh-vpn-script.sh"
wget -qO /usr/bin/xray-script "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/menu/xray-script.sh"
wget -qO /usr/bin/wireguard-script "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/menu/wireguard-script.sh"
wget -qO /usr/bin/script-info "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/menu/script-info.sh"
wget -qO /usr/bin/script-1 "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/cron/script-1.sh"
wget -qO /usr/bin/script-2 "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/cron/script-2.sh"
wget -qO /usr/bin/script-3 "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/cron/script-3.sh"
chmod +x /usr/bin/{menu,ssh-vpn-script,xray-script,wireguard-script,script-info,script-1,script-2,script-3}

# Configure rc.local
wget -qO /etc/rc.local "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/rc.local"
chmod +x /etc/rc.local

# Configure crontab
echo "0 0 * * * root reboot" >> /etc/crontab
echo "55 23 * * * root script-2" >> /etc/crontab

# Configure lock Dropbear multi-login
wget -qO /etc/systemd/system/script-3.service "https://raw.githubusercontent.com/akuhaa021/autoscript/main/FILES/cron/script-3.service"
mkdir /donboyage/script-3
touch /donboyage/script-3/{multi-login.log,user-lock.log}
echo 2 > /donboyage/script-3/limit
systemctl daemon-reload
service script-3 start
systemctl enable script-3.

# Configure block all connections
echo off >> /donboyage/block-status

# Cleanup and reboot
clear
echo -e ""
echo -e "Script executed succesfully."
echo -e ""
read -n 1 -r -s -p $"Press enter to reboot..."
echo -e ""
rm -f /root/install.sh
cp /dev/null /root/.bash_history
reboot
