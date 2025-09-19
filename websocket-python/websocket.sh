#!/bin/bash
clear
echo Installing Websocket-SSH Python
sleep 1
echo Sila Tunggu Sebentar...
sleep 0.5
cd
#Buat name user github dan nama folder
GitUser="none"
namafolder="websocket-python"
#wget https://github.com/NiLphreakz/main/${namafolder}/

#System Websocket
cd
cd /etc/systemd/system/
wget -O /etc/systemd/system/cdn-ssl.service https://raw.githubusercontent.com/melody97rain/beta/main/${namafolder}/cdn-ssl.service
#System Websocket-Ovpn Service
cd /etc/systemd/system/
wget -O /etc/systemd/system/cdn-ovpn.service https://raw.githubusercontent.com/melody97rain/beta/main/${namafolder}/cdn-ovpn.service
#System Websocket-Openssh Service
cd /etc/systemd/system/
wget -O /etc/systemd/system/cdn-openssh.service https://raw.githubusercontent.com/melody97rain/beta/main/${namafolder}/cdn-openssh.service

#Install WS-SSL
wget -q -O /usr/local/bin/cdn-ssl https://raw.githubusercontent.com/melody97rain/beta/main/${namafolder}/cdn-ssl.py
chmod +x /usr/local/bin/cdn-ssl
#Install WS-OpenVPN
wget -q -O /usr/local/bin/cdn-ovpn https://raw.githubusercontent.com/melody97rain/beta/main/${namafolder}/cdn-ovpn.py
chmod +x /usr/local/bin/cdn-ovpn
#Install WS-Openssh
wget -q -O /usr/local/bin/cdn-openssh https://raw.githubusercontent.com/melody97rain/beta/main/${namafolder}/cdn-openssh.py
chmod +x /usr/local/bin/cdn-openssh

#Enable & Start & Restart ws-stunnel service
systemctl daemon-reload
systemctl enable cdn-ssl
systemctl start cdn-ssl
systemctl restart cdn-ssl

#Enable & Start & Restart ws-ovpn service
systemctl daemon-reload
systemctl enable cdn-ovpn
systemctl start cdn-ovpn
systemctl restart cdn-ovpn

#Enable & Start & Restart ws-openssh service
systemctl daemon-reload
systemctl enable cdn-openssh
systemctl start cdn-openssh
systemctl restart cdn-openssh
