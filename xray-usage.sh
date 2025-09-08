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

            expired=$(grep -E "### $email " "$config" | awk '{print $3}')
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

            expired=$(grep -E "### $email " "$config" | awk '{print $3}')
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

chmod +x /usr/local/bin/xray-usage.sh