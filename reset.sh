#!/bin/bash

# ===================== CONFIG =====================
BASE_DIR="/root/resettunnel"
BIN_NAME="Waterwall"
ZIP_NAME="Waterwall-linux-64.zip"
DOWNLOAD_URL="https://github.com/radkesvat/WaterWall/releases/download/v1.32/Waterwall-linux-64.zip"
SERVICE_NAME="resettunnel"
# ==================================================

# --------------------- UTILS ----------------------
require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root"
        exit 1
    fi
}

get_server_ip() {
    SERVER_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
    [[ -z "$SERVER_IP" ]] && SERVER_IP="UNKNOWN"
}

show_banner() {
    clear
    get_server_ip
    echo "================================================"
    echo "            RESET TUNNEL - MEYSAM            "
    echo "================================================"
    echo " Server IP : $SERVER_IP"
    echo "================================================"
    echo
}
# -------------------------------------------------

# ------------------ FILES -------------------------
create_core_json() {
cat > "$BASE_DIR/core.json" << 'EOF'
{
    "log": {
        "path": "log/",
        "core": {
            "loglevel": "DEBUG",
            "file": "core.log",
            "console": true
        },
        "network": {
            "loglevel": "DEBUG",
            "file": "network.log",
            "console": true
        },
        "dns": {
            "loglevel": "SILENT",
            "file": "dns.log",
            "console": false
        }
    },
    "dns": {},
    "misc": {
        "workers": 0,
        "ram-profile": "server",
        "libs-path": "libs/"
    },
    "configs": [
        "config.json"
    ]
}
EOF
}

create_config_iran() {
    CONFIG_URL="https://raw.githubusercontent.com/logi443/reset/refs/heads/main/config.json"
    curl -sL "$CONFIG_URL" -o "$BASE_DIR/config.json"

    # جایگزینی IP ها
    sed -i "s/\$KHAREJ_IP/$KHAREJ_IP/g" "$BASE_DIR/config.json"
    sed -i "s/\$IRAN_IP/$IRAN_IP/g" "$BASE_DIR/config.json"
}

create_config_kharej() {
    CONFIG_URL="https://raw.githubusercontent.com/logi443/reset/refs/heads/main/configkh.json"
    curl -sL "$CONFIG_URL" -o "$BASE_DIR/config.json"

    # جایگزینی IP ها
    sed -i "s/\$KHAREJ_IP/$KHAREJ_IP/g" "$BASE_DIR/config.json"
    sed -i "s/\$IRAN_IP/$IRAN_IP/g" "$BASE_DIR/config.json"
}
# -------------------------------------------------

# ---------------- INSTALL -------------------------
download_and_install() {
    cd "$BASE_DIR" || exit 1
    apt update && apt install -y curl unzip
    curl -L -o "$ZIP_NAME" "$DOWNLOAD_URL"
    unzip -o "$ZIP_NAME"
    chmod +x Waterwall*
    mv -f Waterwall "$BIN_NAME"
}

create_service() {
cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=Reset Tunnel WaterWall
After=network.target

[Service]
WorkingDirectory=/root/resettunnel
ExecStart=/root/resettunnel/Waterwall
Restart=always
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable $SERVICE_NAME
    systemctl restart $SERVICE_NAME
}
# -------------------------------------------------

# ---------------- ACTIONS -------------------------
install_menu() {
    read -p "Enter IRAN server IP: " IRAN_IP
    read -p "Enter KHAREJ server IP: " KHAREJ_IP

    mkdir -p "$BASE_DIR"

    create_core_json

    if [[ "$1" == "iran" ]]; then
        create_config_iran
    else
        create_config_kharej
    fi

    download_and_install
    create_service

    echo
    echo "Installation completed successfully"
}

remove_service() {
    systemctl stop $SERVICE_NAME
    systemctl disable $SERVICE_NAME
    rm -f /etc/systemd/system/$SERVICE_NAME.service
    rm -rf "$BASE_DIR"
    systemctl daemon-reload
    echo "Service removed successfully"
}

status_service() {
    systemctl status $SERVICE_NAME --no-pager
}
# -------------------------------------------------

# ==================== MAIN ========================
require_root
show_banner

echo "1) Install"
echo "2) Remove"
echo "3) Status"
read -p "Select option: " ACTION

case "$ACTION" in
1)
    echo "1) Iran Server"
    echo "2) Kharej Server"
    read -p "Select server type: " LOC
    [[ "$LOC" == "1" ]] && install_menu iran
    [[ "$LOC" == "2" ]] && install_menu kharej
    ;;
2) remove_service ;;
3) status_service ;;
*) echo "Invalid option" ;;
esac
# =================================================
