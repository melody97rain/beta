#!/bin/bash
# initializing var
export DEBIAN_FRONTEND=noninteractive
MYIP=$(wget -qO- icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";
NET=$(ip -o $ANU -4 route show to default | awk '{print $5}');
source /etc/os-release
ver=$VERSION_ID

#detail nama perusahaan
country="MY"
state="none"
locality="none"
organization="@none"
organizationalunit="@none"
commonname="none"
email="none@none.com"

# simple password minimal
wget -O /etc/pam.d/common-password "https://raw.githubusercontent.com/melody97rain/beta/main/password"
chmod +x /etc/pam.d/common-password

# go to root
cd

# Edit file /etc/systemd/system/rc-local.service
cat > /etc/systemd/system/rc-local.service <<-END
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
END

# nano /etc/rc.local
cat > /etc/rc.local <<-END
#!/bin/sh -e
# rc.local
# By default this script does nothing.
exit 0
END

# Ubah izin akses
chmod +x /etc/rc.local

# enable rc local
systemctl enable rc-local
systemctl start rc-local.service

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

#update
apt update -y
apt upgrade -y
apt dist-upgrade -y
apt-get remove --purge ufw firewalld -y
apt-get remove --purge exim4 -y

# install wget and curl
apt -y install wget curl

# set time GMT +8
ln -fs /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config

# install
apt-get --reinstall --fix-missing install -y bzip2 gzip coreutils wget screen rsyslog iftop htop net-tools zip unzip wget net-tools curl nano sed screen gnupg gnupg1 bc apt-transport-https build-essential dirmngr libxml-parser-perl neofetch git lsof
echo "clear" >> .profile
echo "menu" >> .profile

# install webserver
apt -y install nginx
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/melody97rain/beta/main/nginx.conf"
mkdir -p /home/vps/public_html
wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/melody97rain/beta/main/vps.conf"
/etc/init.d/nginx restart

# install badvpn
cd
wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/melody97rain/beta/main/badvpn-udpgw64"
chmod +x /usr/bin/badvpn-udpgw
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500' /etc/rc.local
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500' /etc/rc.local
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500' /etc/rc.local
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7400 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7500 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7600 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7700 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7800 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7900 --max-clients 500

apt-get -y update
apt -y install netfilter-persistent
# setting port ssh
cd
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g'
# /etc/ssh/sshd_config
sed -i '/Port 22/a Port 500' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 40000' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 51443' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 58080' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 200' /etc/ssh/sshd_config
sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
/etc/init.d/ssh restart

# install dropbear
apt update -y
apt install -y dropbear

# tulis ulang konfigurasi dropbear
cat > /etc/default/dropbear <<'EOF'
NO_START=0
DROPBEAR_PORT=143
DROPBEAR_BANNER=""
EOF

# pastikan shell dibatasi untuk user tertentu (jika diperlukan)
grep -qxF "/bin/false" /etc/shells || echo "/bin/false" >> /etc/shells
grep -qxF "/usr/sbin/nologin" /etc/shells || echo "/usr/sbin/nologin" >> /etc/shells

# Systemd Dropbear Service
tee /etc/systemd/system/dropbear.service > /dev/null <<'EOF'
[Unit]
Description=Lightweight SSH server
Documentation=man:dropbear(8)
After=network.target

[Service]
Environment=DROPBEAR_PORT=143 DROPBEAR_RECEIVE_WINDOW=65536
EnvironmentFile=-/etc/default/dropbear

# Clear previous ExecStart and set new one that includes banner
ExecStart=/usr/sbin/dropbear -EF -p "$DROPBEAR_PORT" -W "$DROPBEAR_RECEIVE_WINDOW" -b "$DROPBEAR_BANNER"

KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# enable & restart dropbear
systemctl enable dropbear
systemctl restart dropbear

# install squid for debian & ubuntu
apt -y install squid3
# install squid for debian 11
apt -y install squid
wget -O /etc/squid/squid.conf "https://raw.githubusercontent.com/melody97rain/beta/main/squid3.conf"
sed -i $MYIP2 /etc/squid/squid.conf

# setting vnstat
apt -y install vnstat
/etc/init.d/vnstat restart
apt -y install libsqlite3-dev
wget https://humdi.net/vnstat/vnstat-2.6.tar.gz
tar zxvf vnstat-2.6.tar.gz
cd vnstat-2.6
./configure --prefix=/usr --sysconfdir=/etc && make && make install
cd
vnstat -u -i $NET
sed -i 's/Interface "'""eth0""'"/Interface "'""$NET""'"/g' /etc/vnstat.conf
chown vnstat:vnstat /var/lib/vnstat -R
systemctl enable vnstat
/etc/init.d/vnstat restart
rm -f /root/vnstat-2.6.tar.gz
rm -rf /root/vnstat-2.6

# install stunnel
apt install stunnel4 -y
cat > /etc/stunnel/stunnel.conf <<-END
pid = /var/run/stunnel4.pid
cert = /etc/stunnel/stunnel.pem

[dropbear]
accept = 737
connect = 127.0.0.1:143
END

# make a certificate
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1095 \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem

# konfigurasi stunnel
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
/lib/systemd/systemd-sysv-install enable stunnel4
systemctl start stunnel4
/etc/init.d/stunnel4 restart

#OpenVPN
wget https://raw.githubusercontent.com/melody97rain/beta/main/vpn.sh &&  chmod +x vpn.sh && ./vpn.sh

# install lolcat
wget https://raw.githubusercontent.com/melody97rain/beta/main/lolcat.sh &&  chmod +x lolcat.sh && ./lolcat.sh

# install fail2ban
apt -y install fail2ban

# Instal DDOS Flate
if [ -d '/usr/local/ddos' ]; then
	echo; echo; echo "Please un-install the previous version first"
	exit 0
else
	mkdir /usr/local/ddos
fi
clear
echo; echo 'Installing DOS-Deflate 0.6'; echo
echo; echo -n 'Downloading source files...'
wget -q -O /usr/local/ddos/ddos.conf http://www.inetbase.com/scripts/ddos/ddos.conf
echo -n '.'
wget -q -O /usr/local/ddos/LICENSE http://www.inetbase.com/scripts/ddos/LICENSE
echo -n '.'
wget -q -O /usr/local/ddos/ignore.ip.list http://www.inetbase.com/scripts/ddos/ignore.ip.list
echo -n '.'
wget -q -O /usr/local/ddos/ddos.sh http://www.inetbase.com/scripts/ddos/ddos.sh
chmod 0755 /usr/local/ddos/ddos.sh
cp -s /usr/local/ddos/ddos.sh /usr/local/sbin/ddos
echo '...done'
echo; echo -n 'Creating cron to run script every minute.....(Default setting)'
/usr/local/ddos/ddos.sh --cron > /dev/null 2>&1
echo '.....done'
echo; echo 'Installation has completed.'
echo 'Config file is at /usr/local/ddos/ddos.conf'
echo 'Please send in your comments and/or suggestions to zaf@vsnl.com'

# banner /etc/issue.net
wget -O /etc/issue.net "https://raw.githubusercontent.com/melody97rain/beta/main/banner/bannerssh.conf"
echo "Banner /etc/issue.net" >>/etc/ssh/sshd_config
sed -i 's@DROPBEAR_BANNER=""@DROPBEAR_BANNER="/etc/issue.net"@g' /etc/default/dropbear

cat << 'EOF' > /usr/local/bin/xray-usage.sh
#!/bin/bash

DB_PATH="/var/lib/xray3"
mkdir -p "$DB_PATH"

convert_unit() {
    local bytes=$1
    if [ "$bytes" -lt 1024 ]; then
        printf "%d B" "$bytes"
    elif [ "$bytes" -lt 1048576 ]; then
        printf "%.2f KB" "$(echo "$bytes/1024" | bc -l)"
    elif [ "$bytes" -lt 1073741824 ]; then
        printf "%.2f MB" "$(echo "$bytes/1048576" | bc -l)"
    elif [ "$bytes" -lt 1099511627776 ]; then
        printf "%.2f GB" "$(echo "$bytes/1073741824" | bc -l)"
    else
        printf "%.2f TB" "$(echo "$bytes/1099511627776" | bc -l)"
    fi
}

# Cari expired untuk user vless dan vmess
find_expired_for_user() {
    local user="$1"
    local config="$2"
    local expired=""
    for f in "$config" /usr/local/etc/xray/config.json /usr/local/etc/xray/none.json; do
        [ -n "$f" ] || continue
        [ -f "$f" ] || continue
        expired=$(grep -E "^#vms[[:space:]]+$user[[:space:]]+" "$f" 2>/dev/null | awk '{print $3}' | tail -n1 || true)
        [ -n "$expired" ] && { printf '%s' "$expired"; return 0; }
        expired=$(grep -E "^#vls[[:space:]]+$user[[:space:]]+" "$f" 2>/dev/null | awk '{print $3}' | tail -n1 || true)
        [ -n "$expired" ] && { printf '%s' "$expired"; return 0; }
    done
    printf ''
    return 1
}

# get stat value helper (safe even if xray/jq missing)
get_stat_value() {
    local server="$1"; shift
    local pattern="$*"
    if command -v xray >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        xray api statsquery --server="$server" -pattern "$pattern" 2>/dev/null | jq -r '.stat[0].value // 0' 2>/dev/null || echo 0
    else
        echo 0
    fi
}

# === TOTAL USAGE ===
show_usage_total() {
    local CONFIG_LIST=("${!1}")
    local SERVER="$2"
    local DB="$3"
    local TYPE="$4"

    touch "$DB"
    tmpfile=$(mktemp)

    for entry in "${CONFIG_LIST[@]}"; do
        IFS='|' read -r config LABEL <<< "$entry"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📊 $TYPE Total Usage ($LABEL)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        emails=$(grep -oP '"email":\s*"\K[^"]+' "$config")

        for email in $emails; do
            uplink=$(xray api statsquery --server=$SERVER -pattern "user>>>$email>>>traffic>>>uplink" | jq -r '.stat[0].value // 0')
            downlink=$(xray api statsquery --server=$SERVER -pattern "user>>>$email>>>traffic>>>downlink" | jq -r '.stat[0].value // 0')

            db_line=$(grep "^$email:" "$DB")
            if [ -n "$db_line" ]; then
                old_uplink=$(echo "$db_line" | cut -d':' -f3)
                old_downlink=$(echo "$db_line" | cut -d':' -f4)
            else
                old_uplink=0
                old_downlink=0
            fi

            if [ "$uplink" -lt "$old_uplink" ] || [ "$downlink" -lt "$old_downlink" ]; then
                saved_uplink=$((old_uplink + uplink))
                saved_downlink=$((old_downlink + downlink))
            else
                saved_uplink=$uplink
                saved_downlink=$downlink
            fi
            saved_total=$((saved_uplink + saved_downlink))

            grep -v "^$email:" "$DB" > "$DB.tmp"
            echo "$email:$saved_total:$saved_uplink:$saved_downlink" >> "$DB.tmp"
            mv "$DB.tmp" "$DB"

             expired=$(find_expired_for_user "$email" "$config" || true)
			 
            echo "$saved_total|$saved_uplink|$saved_downlink|$email|$expired" >> "$tmpfile"
        done

        sort -t"|" -k1,1nr "$tmpfile" | while IFS="|" read -r total uplink downlink email expired; do
            uplink_h=$(convert_unit $uplink)
            downlink_h=$(convert_unit $downlink)
            total_h=$(convert_unit $total)

            echo "👤 $email"
            echo "   ↓ Download : $downlink_h"
            echo "   ↑ Upload   : $uplink_h"
            echo "   Σ Total    : $total_h"
            [ -n "$expired" ] && echo "   📅 Expired  : $expired"
            echo "--------------------------------"
        done

        > "$tmpfile"
    done

    rm -f "$tmpfile"
}

# === DAILY USAGE ===
show_usage_daily() {
    local CONFIG_LIST=("${!1}")
    local SERVER="$2"
    local TYPE="$3"
    local DATE=$(date +%F)
    local DB="$DB_PATH/daily-${TYPE,,}.db"

    # kalau tarikh berubah -> reset DB
    if [ -f "$DB" ]; then
        db_date=$(head -n1 "$DB" | cut -d':' -f5)
        if [ "$db_date" != "$DATE" ]; then
            > "$DB"
        fi
    fi

    touch "$DB"
    tmpfile=$(mktemp)

    for entry in "${CONFIG_LIST[@]}"; do
        IFS='|' read -r config LABEL <<< "$entry"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📊 $TYPE Daily Usage ($LABEL)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        emails=$(grep -oP '"email":\s*"\K[^"]+' "$config")

        for email in $emails; do
            uplink=$(xray api statsquery --server=$SERVER -pattern "user>>>$email>>>traffic>>>uplink" | jq -r '.stat[0].value // 0')
            downlink=$(xray api statsquery --server=$SERVER -pattern "user>>>$email>>>traffic>>>downlink" | jq -r '.stat[0].value // 0')

            db_line=$(grep "^$email:" "$DB")
            if [ -n "$db_line" ]; then
                old_uplink=$(echo "$db_line" | cut -d':' -f3)
                old_downlink=$(echo "$db_line" | cut -d':' -f4)
                old_date=$(echo "$db_line" | cut -d':' -f5)
            else
                old_uplink=0
                old_downlink=0
                old_date=$DATE
            fi

            if [ "$uplink" -lt "$old_uplink" ] || [ "$downlink" -lt "$old_downlink" ]; then
                saved_uplink=$((old_uplink + uplink))
                saved_downlink=$((old_downlink + downlink))
            else
                saved_uplink=$uplink
                saved_downlink=$downlink
            fi
            saved_total=$((saved_uplink + saved_downlink))

            grep -v "^$email:" "$DB" > "$DB.tmp"
            echo "$email:$saved_total:$saved_uplink:$saved_downlink:$DATE" >> "$DB.tmp"
            mv "$DB.tmp" "$DB"

             expired=$(find_expired_for_user "$email" "$config" || true)
			 
            echo "$saved_total|$saved_uplink|$saved_downlink|$email|$expired" >> "$tmpfile"
        done

        sort -t"|" -k1,1nr "$tmpfile" | while IFS="|" read -r total uplink downlink email expired; do
            uplink_h=$(convert_unit $uplink)
            downlink_h=$(convert_unit $downlink)
            total_h=$(convert_unit $total)

            echo "👤 $email"
            echo "   ↓ Download : $downlink_h"
            echo "   ↑ Upload   : $uplink_h"
            echo "   📦 Today   : $total_h"
            [ -n "$expired" ] && echo "   📅 Expired  : $expired"
            echo "--------------------------------"
        done

        > "$tmpfile"
    done

    rm -f "$tmpfile"
}

# === MENU + AUTO TOP5 VLESS NTLS ===
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TOP 5 VLess Daily Usage (NTLS)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

CONFIG_LIST_VLESS_NTLS=(
    "/usr/local/etc/xray/none.json|NTLS"
)

# Papar top 5 daily VLess NTLS sahaja
show_usage_daily CONFIG_LIST_VLESS_NTLS[@] "127.0.0.1:10085" "VLess" | head -n 35

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 1) Total Usage VMess"
echo " 2) Total Usage VLess"
echo " 3) Daily Usage VMess"
echo " 4) Daily Usage VLess"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -p "Pilih menu [1-4]: " choice

case $choice in
    1)
        CONFIG_LIST_VMESS=(
            "/usr/local/etc/xray/none.json|NTLS"
            "/usr/local/etc/xray/config.json|TLS"
        )
        show_usage_total CONFIG_LIST_VMESS[@] "127.0.0.1:10086" "$DB_PATH/usage-vmess.db" "VMess"
        ;;
    2)
        CONFIG_LIST_VLESS=(
            "/usr/local/etc/xray/none.json|NTLS"
            "/usr/local/etc/xray/config.json|TLS"
        )
        show_usage_total CONFIG_LIST_VLESS[@] "127.0.0.1:10085" "$DB_PATH/usage-vless.db" "VLess"
        ;;
    3)
        CONFIG_LIST_VMESS=(
            "/usr/local/etc/xray/none.json|NTLS"
            "/usr/local/etc/xray/config.json|TLS"
        )
        show_usage_daily CONFIG_LIST_VMESS[@] "127.0.0.1:10086" "VMess"
        ;;
    4)
        CONFIG_LIST_VLESS=(
            "/usr/local/etc/xray/none.json|NTLS"
            "/usr/local/etc/xray/config.json|TLS"
        )
        show_usage_daily CONFIG_LIST_VLESS[@] "127.0.0.1:10085" "VLess"
        ;;
    *)
        echo "Pilihan tak sah!"
        ;;
esac
EOF

apt install -y jq bc
chmod +x /usr/local/bin/xray-usage.sh
mv /usr/local/bin/xray-usage.sh /usr/bin/xray-usage
chmod +x /usr/bin/xray-usage

#Bannerku menu
wget -O /usr/bin/bannerku https://raw.githubusercontent.com/melody97rain/beta/main/banner/bannerku && chmod +x /usr/bin/bannerku

# blockir torrent
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
iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload

# download script
cd /usr/bin
wget -O add-host "https://raw.githubusercontent.com/melody97rain/beta/main/system/add-host.sh"
wget -O about "https://raw.githubusercontent.com/melody97rain/beta/main/system/about.sh"
wget -O menu "https://raw.githubusercontent.com/melody97rain/beta/main/menu.sh"
wget -O add-ssh "https://raw.githubusercontent.com/melody97rain/beta/main/add-user/add-ssh.sh"
wget -O trial "https://raw.githubusercontent.com/melody97rain/beta/main/add-user/trial.sh"
wget -O del-ssh "https://raw.githubusercontent.com/melody97rain/beta/main/delete-user/del-ssh.sh"
wget -O member "https://raw.githubusercontent.com/melody97rain/beta/main/member.sh"
wget -O delete "https://raw.githubusercontent.com/melody97rain/beta/main/delete-user/delete.sh"
wget -O cek-ssh "https://raw.githubusercontent.com/melody97rain/beta/main/cek-user/cek-ssh.sh"
wget -O restart "https://raw.githubusercontent.com/melody97rain/beta/main/system/restart.sh"
wget -O speedtest "https://raw.githubusercontent.com/melody97rain/beta/main/system/speedtest_cli.py"
wget -O info "https://raw.githubusercontent.com/melody97rain/beta/main/system/info.sh"
wget -O ram "https://raw.githubusercontent.com/melody97rain/beta/main/system/ram.sh"
wget -O renew-ssh "https://raw.githubusercontent.com/melody97rain/beta/main/renew-user/renew-ssh.sh"
wget -O autokill "https://raw.githubusercontent.com/melody97rain/beta/main/autokill.sh"
wget -O ceklim "https://raw.githubusercontent.com/melody97rain/beta/main/cek-user/ceklim.sh"
wget -O tendang "https://raw.githubusercontent.com/melody97rain/beta/main/tendang.sh"
wget -O clear-log "https://raw.githubusercontent.com/melody97rain/beta/main/clear-log.sh"
wget -O change-port "https://raw.githubusercontent.com/melody97rain/beta/main/change.sh"
wget -O port-ovpn "https://raw.githubusercontent.com/melody97rain/beta/main/change-port/port-ovpn.sh"
wget -O port-ssl "https://raw.githubusercontent.com/melody97rain/beta/main/change-port/port-ssl.sh"
wget -O port-squid "https://raw.githubusercontent.com/melody97rain/beta/main/change-port/port-squid.sh"
wget -O port-websocket "https://raw.githubusercontent.com/melody97rain/beta/main/change-port/port-websocket.sh"
wget -O wbmn "https://raw.githubusercontent.com/melody97rain/beta/main/webmin.sh"
wget -O xp "https://raw.githubusercontent.com/melody97rain/beta/main/xp.sh"
wget -O kernel-updt "https://raw.githubusercontent.com/melody97rain/beta/main/kernel.sh"
wget -O user-list "https://raw.githubusercontent.com/melody97rain/beta/main/more-option/user-list.sh"
wget -O user-lock "https://raw.githubusercontent.com/melody97rain/beta/main/more-option/user-lock.sh"
wget -O user-unlock "https://raw.githubusercontent.com/melody97rain/beta/main/more-option/user-unlock.sh"
wget -O user-password "https://raw.githubusercontent.com/melody97rain/beta/main/more-option/user-password.sh"
wget -O antitorrent "https://raw.githubusercontent.com/melody97rain/beta/main/more-option/antitorrent.sh"
wget -O cfa "https://raw.githubusercontent.com/melody97rain/beta/main/cloud/cfa.sh"
wget -O cfd "https://raw.githubusercontent.com/melody97rain/beta/main/cloud/cfd.sh"
wget -O cfp "https://raw.githubusercontent.com/melody97rain/beta/main/cloud/cfp.sh"
wget -O swap "https://raw.githubusercontent.com/melody97rain/beta/main/swapkvm.sh"
wget -O check-sc "https://raw.githubusercontent.com/melody97rain/beta/main/system/running.sh"
wget -O ssh "https://raw.githubusercontent.com/melody97rain/beta/main/menu/ssh.sh"
wget -O autoreboot "https://raw.githubusercontent.com/melody97rain/beta/main/system/autoreboot.sh"
wget -O bbr "https://raw.githubusercontent.com/melody97rain/beta/main/system/bbr.sh"
wget -O port-ohp "https://raw.githubusercontent.com/melody97rain/beta/main/change-port/port-ohp.sh"
wget -O port-xray "https://raw.githubusercontent.com/melody97rain/beta/main/change-port/port-xray.sh"
wget -O panel-domain "https://raw.githubusercontent.com/melody97rain/beta/main/menu/panel-domain.sh"
wget -O system "https://raw.githubusercontent.com/melody97rain/beta/main/menu/system.sh"
wget -O themes "https://raw.githubusercontent.com/melody97rain/beta/main/menu/themes.sh"
chmod +x add-host
chmod +x menu
chmod +x add-ssh
chmod +x trial
chmod +x del-ssh
chmod +x member
chmod +x delete
chmod +x cek-ssh
chmod +x restart
chmod +x speedtest
chmod +x info
chmod +x about
chmod +x autokill
chmod +x tendang
chmod +x ceklim
chmod +x ram
chmod +x renew-ssh
chmod +x clear-log
chmod +x change-port
chmod +x restore
chmod +x port-ovpn
chmod +x port-ssl
chmod +x port-squid
chmod +x port-websocket
chmod +x wbmn
chmod +x xp
chmod +x kernel-updt
chmod +x user-list
chmod +x user-lock
chmod +x user-unlock
chmod +x user-password
chmod +x antitorrent
chmod +x cfa
chmod +x cfd
chmod +x cfp
chmod +x swap
chmod +x check-sc
chmod +x ssh
chmod +x autoreboot
chmod +x bbr
chmod +x port-ohp
chmod +x port-xray
chmod +x panel-domain
chmod +x system
chmod +x themes
echo "0 5 * * * root clear-log && reboot" >> /etc/crontab
echo "0 0 * * * root xp" >> /etc/crontab
echo "0 0 * * * root delete" >> /etc/crontab
# remove unnecessary files
cd
apt autoclean -y
apt -y remove --purge unscd
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove bind9*;
apt-get -y remove sendmail*
apt autoremove -y
# finishing
cd
chown -R www-data:www-data /home/vps/public_html
/etc/init.d/nginx restart
/etc/init.d/openvpn restart
/etc/init.d/cron restart
/etc/init.d/ssh restart
/etc/init.d/dropbear restart
/etc/init.d/fail2ban restart
/etc/init.d/vnstat restart
/etc/init.d/stunnel4 restart
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7400 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7500 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7600 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7700 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7800 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7900 --max-clients 500
history -c
echo "unset HISTFILE" >> /etc/profile

cd
rm -f /root/key.pem
rm -f /root/cert.pem
rm -f /root/ssh-vpn.sh

# finihsing
clear
