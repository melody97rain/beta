#!/usr/bin/env bash
# dropbear-login-list.sh
# Tujuan: Papar login Dropbear (username + IP) — serasi dengan Debian 12 (auth.log atau journalctl)

set -u

# Temporary file (automatically dibuang pada exit)
TMP="$(mktemp /tmp/dropbear-log.XXXXXX)"
trap 'rm -f "$TMP"' EXIT

LOG=""
USE_JOURNAL=0

# Cari lokasi log
if [ -r /var/log/auth.log ]; then
    LOG="/var/log/auth.log"
elif [ -r /var/log/secure ]; then
    LOG="/var/log/secure"
else
    # tiada fail log tradisional — cuba journalctl
    if command -v journalctl >/dev/null 2>&1; then
        USE_JOURNAL=1
    else
        echo "Tiada /var/log/auth.log atau /var/log/secure, dan journalctl tidak ditemui."
        exit 1
    fi
fi

# Ambil baris berkaitan "Password auth succeeded"
if [ "$USE_JOURNAL" -eq 1 ]; then
    # Dapatkan semua mesej dropbear dari journal
    journalctl -t dropbear --no-pager -o cat 2>/dev/null | grep -i "Password auth succeeded" > "$TMP" || true
else
    grep -i dropbear "$LOG" | grep -i "Password auth succeeded" > "$TMP" || true
fi

# Keluarkan senarai PID Dropbear yang sedang running (jika ada)
PIDS=( $(pgrep -x dropbear 2>/dev/null || true) )

echo
echo "-----=[ Dropbear User Login ]=------"
echo "PID  |  Username  |  IP Address"
echo "------------------------------------"

# Fungsi untuk parse satu baris log dan print
# Contoh baris log:
#  hostname dropbear[1234]: Password auth succeeded for 'user' from 1.2.3.4:52422
print_from_line() {
    local line="$1"
    # dapatkan pid dari "dropbear[PID]"
    local pid user ipport ip

    pid="$(printf "%s" "$line" | sed -n "s/.*dropbear\[\([0-9]\+\)\].*/\1/p")"
    # dapatkan username antara for '...'
    user="$(printf "%s" "$line" | sed -n "s/.*Password auth succeeded for '\([^']\+\)'.*/\1/p")"
    # dapatkan substring selepas 'from '
    ipport="$(printf "%s" "$line" | sed -n "s/.*from \(.*\)$/\1/p")"

    # jika ipport bermula dengan '[', anggap IPv6 bracketed like [::1]:port
    if printf "%s" "$ipport" | grep -q '^\[' 2>/dev/null; then
        ip="$(printf "%s" "$ipport" | sed -E 's/^\[([0-9a-fA-F:]+)\].*$/\1/')"
    else
        # sqlite style: ipv4:port  OR maybe ipv6 without brackets (rare)
        # cuba ambil bahagian sebelum :port (hapus ":port" yg terakhir)
        # jika unbracketed IPv6 with port exists, ini boleh jadi ambiguiti; bracketed IPv6 lebih biasa.
        # cara selamat: hapus ":<digits>$" jika port wujud
        ip="$(printf "%s" "$ipport" | sed -E 's/:([0-9]+)$//')"
        # jika selepas itu masih ada ruang (contoh ada extra), ambil sehingga ruang pertama
        ip="$(printf "%s" "$ip" | awk '{print $1}')"
    fi

    # jika tiada user atau ip, jangan print
    if [ -n "$pid" ] && [ -n "$user" ] && [ -n "$ip" ]; then
        printf "%-4s | %-9s | %s\n" "$pid" "$user" "$ip"
    fi
}

# Jika ada PIDs: tapis mengikut PID (per baris)
if [ "${#PIDS[@]}" -gt 0 ]; then
    # Untuk setiap PID, cari baris di tmp dan paparkan
    for p in "${PIDS[@]}"; do
        # cari semua baris berkaitan PID ini
        while IFS= read -r line; do
            print_from_line "$line"
        done < <(grep -F "dropbear[$p]" "$TMP" 2>/dev/null || true)
    done
else
    # Tiada proses dropbear aktif — tunjuk semua kejayaan login terkini (jika ada)
    while IFS= read -r line; do
        print_from_line "$line"
    done < "$TMP"
fi

# Jika tiada output (tiada login ditemui), beritahu pengguna
# (memeriksa sama ada tmp kosong)
if [ ! -s "$TMP" ]; then
    echo "Tiada rekod 'Password auth succeeded' ditemui dalam log."
fi

exit 0
echo " "
echo "-----=[ OpenSSH User Login ]=-------";
echo "ID  |  Username  |  IP Address";
echo "------------------------------------";
cat $LOG | grep -i sshd | grep -i "Accepted password for" > /tmp/login-db.txt
data=( `ps aux | grep "\[priv\]" | sort -k 72 | awk '{print $2}'`);

for PID in "${data[@]}"
do
        cat /tmp/login-db.txt | grep "sshd\[$PID\]" > /tmp/login-db-pid.txt;
        NUM=`cat /tmp/login-db-pid.txt | wc -l`;
        USER=`cat /tmp/login-db-pid.txt | awk '{print $9}'`;
        IP=`cat /tmp/login-db-pid.txt | awk '{print $11}'`;
        if [ $NUM -eq 1 ]; then
                echo "$PID - $USER - $IP";
        fi
done
if [ -f "/etc/openvpn/server/openvpn-tcp.log" ]; then
        echo " "
        echo "----=[ OpenVPN TCP User Login ]=----";
        echo "Username  |  IP Address  |  Connected Since";
        echo "------------------------------------";
        cat /etc/openvpn/server/openvpn-tcp.log | grep -w "^CLIENT_LIST" | cut -d ',' -f 2,3,8 | sed -e 's/,/      /g' > /tmp/vpn-login-tcp.txt
        cat /tmp/vpn-login-tcp.txt
fi
echo "------------------------------------"

if [ -f "/etc/openvpn/server/openvpn-udp.log" ]; then
        echo " "
        echo "----=[ OpenVPN UDP User Login ]=----";
        echo "Username  |  IP Address  |  Connected Since";
        echo "------------------------------------";
        cat /etc/openvpn/server/openvpn-udp.log | grep -w "^CLIENT_LIST" | cut -d ',' -f 2,3,8 | sed -e 's/,/      /g' > /tmp/vpn-login-udp.txt
        cat /tmp/vpn-login-udp.txt
fi
echo "------------------------------------"
echo "";

