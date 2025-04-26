#!/bin/bash

# Konfigurasi
TELEGRAM_API_URL="https://api.telegram.org/botYOUR_BOT_TOKEN/sendMessage"
CHAT_ID="YOUR_CHAT_ID"
VPS_IP="123.123.123.123"
DOMAIN="yourdomain.com"
ADMIN_NAME="Admin"
GITHUB_REPO="https://github.com/YOUR_USERNAME/YOUR_REPO.git"
LOCAL_REPO_DIR="/path/to/your/repository"

# Fungsi kirim Telegram
send_telegram() {
    curl -s -X POST "$TELEGRAM_API_URL" -d chat_id="$CHAT_ID" -d text="$1" > /dev/null
}

# Fungsi buat akun SSH
create_ssh() {
    read -p "Username SSH: " username
    read -p "Password SSH: " password
    read -p "Masa aktif (hari): " days
    read -p "Limit IP: " iplimit

    useradd -e $(date -d "$days days" +"%Y-%m-%d") -s /bin/false -M $username
    echo "$username:$password" | chpasswd

    # IP Tables limit (optional)
    if [ ! -z "$iplimit" ]; then
        iptables -A INPUT -s $iplimit -j ACCEPT
    fi

    exp=$(chage -l $username | grep "Account expires" | awk -F": " '{print $2}')
    echo -e "### SSH $username $exp" >> /etc/akun-ssh

    send_telegram "Akun SSH berhasil dibuat\nUsername: $username\nPassword: $password\nExpired: $exp"
    echo "Akun SSH berhasil dibuat!"
}

# Fungsi buat akun VMess
create_vmess() {
    read -p "Username VMess: " username
    read -p "Masa aktif (hari): " days

    uuid=$(cat /proc/sys/kernel/random/uuid)
    exp=$(date -d "$days days" +"%Y-%m-%d")

    cat >> /etc/xray/vmess.json <<EOF
{
  "id": "$uuid",
  "alterId": 0,
  "email": "$username@$DOMAIN",
  "exp": "$exp"
},
EOF

    systemctl restart xray
    send_telegram "Akun VMess dibuat\nUsername: $username\nUUID: $uuid\nExpired: $exp"
    echo "Akun VMess berhasil dibuat!"
}

# Fungsi buat akun VLESS
create_vless() {
    read -p "Username VLESS: " username
    read -p "Masa aktif (hari): " days

    uuid=$(cat /proc/sys/kernel/random/uuid)
    exp=$(date -d "$days days" +"%Y-%m-%d")

    cat >> /etc/xray/vless.json <<EOF
{
  "id": "$uuid",
  "email": "$username@$DOMAIN",
  "exp": "$exp"
},
EOF

    systemctl restart xray
    send_telegram "Akun VLESS dibuat\nUsername: $username\nUUID: $uuid\nExpired: $exp"
    echo "Akun VLESS berhasil dibuat!"
}

# Fungsi buat akun Trojan
create_trojan() {
    read -p "Username Trojan: " username
    read -p "Masa aktif (hari): " days

    password=$(cat /proc/sys/kernel/random/uuid)
    exp=$(date -d "$days days" +"%Y-%m-%d")

    cat >> /etc/xray/trojan.json <<EOF
{
  "password": "$password",
  "email": "$username@$DOMAIN",
  "exp": "$exp"
},
EOF

    systemctl restart xray
    send_telegram "Akun Trojan dibuat\nUsername: $username\nPassword: $password\nExpired: $exp"
    echo "Akun Trojan berhasil dibuat!"
}

# Fungsi hapus akun
delete_account() {
    read -p "Username yang mau dihapus: " username
    userdel $username
    sed -i "/### SSH $username/d" /etc/akun-ssh
    systemctl restart xray
    send_telegram "Akun $username berhasil dihapus."
    echo "Akun $username berhasil dihapus!"
}

# Fungsi update script dari GitHub
update_script() {
    cd $LOCAL_REPO_DIR
    git pull origin main
    send_telegram "Script berhasil diupdate dari GitHub!"
}

# Fungsi status server
server_status() {
    clear
    echo "Nama Admin: $ADMIN_NAME"
    echo "IP VPS: $VPS_IP"
    echo "Domain: $DOMAIN"
    echo "ISP: $(curl -s https://ipinfo.io/org)"
    echo "Lokasi: $(curl -s https://ipinfo.io/country)"
    echo "Runtime: $(uptime -p)"
}

# Menu utama
menu() {
    clear
    echo "======================================="
    echo "        VPN Management Script"
    echo "Admin: $ADMIN_NAME | Domain: $DOMAIN"
    echo "======================================="
    echo "1. Buat Akun SSH"
    echo "2. Buat Akun VMess"
    echo "3. Buat Akun VLESS"
    echo "4. Buat Akun Trojan"
    echo "5. Hapus Akun VPN"
    echo "6. Update Script dari GitHub"
    echo "7. Status Server"
    echo "8. Detail VPS"
    echo "9. Exit"
    echo "======================================="
    read -p "Pilih menu: " menu

    case $menu in
        1) create_ssh ;;
        2) create_vmess ;;
        3) create_vless ;;
        4) create_trojan ;;
        5) delete_account ;;
        6) update_script ;;
        7) server_status ;;
        8) server_status ;;
        9) exit ;;
        *) echo "Pilihan tidak valid!" && sleep 1 && menu ;;
    esac
}

# Start
menu
