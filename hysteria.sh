#!/bin/bash
# Install hysteria with configurations
# Author: ratneo<https://ihost.wiki>

RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

HYSTERIA_CONF_PATH="/opt/hysteria"
HYSTERIA_CONFIG_FILE="/opt/hysteria/config.json"
HYSTERIA_VER="v1.3.5"

coloredEcho() {
  echo -e "${1}${@:2}${PLAIN}"
}

installHysteria() {
    rm -rf ${HYSTERIA_CONF_PATH}
    systemctl stop hysteria
    DOWNLOAD_LINK="https://github.com/HyNetwork/hysteria/releases/download/${HYSTERIA_VER}/hysteria-linux-amd64"
    coloredEcho $BLUE " 下载Hysteria: ${DOWNLOAD_LINK}"
    curl -L -H "Cache-Control: no-cache" -o /usr/local/bin/hysteria ${DOWNLOAD_LINK}
    if [ $? != 0 ];then
        coloredEcho $RED " 下载Hysteria执行文件失败，请检查服务器网络设置"
        exit 1
    fi
    chmod +x /usr/local/bin/hysteria || {
        coloredEcho $RED " Hysteria安装失败"
        exit 1
    }


    mkdir -p ${HYSTERIA_CONF_PATH}
    cat > $HYSTERIA_CONFIG_FILE<<-EOF
{
  "listen": ":2083",
  "cert": "/etc/letsencrypt/live/$TROJAN_DOMAIN/fullchain.pem",
  "key": "/etc/letsencrypt/live/$TROJAN_DOMAIN/privkey.pem",
  "obfs": "$PASSWORD",
  "alpn": "h3",
  "up_mbps": 500,
  "down_mbps": 500,
  "recv_window_conn": 15728640,
  "recv_window_client": 67108864,
  "max_conn_client": 4096,
  "resolver": "udp://127.0.0.1:53",
  "resolve_preference": "4"
}
EOF


    cat >/etc/systemd/system/hysteria.service<<-EOF
[Unit]
Description=Hysteria is a feature-packed proxy & relay utility powered by a customized QUIC protocol.
Documentation=https://github.com/HyNetwork/hysteria/wiki
After=network.target nss-lookup.target
[Service]
User=root
NoNewPrivileges=true
ExecStart=/usr/local/bin/hysteria -c /opt/hysteria/config.json server
Restart=on-failure
RestartPreventExitStatus=23
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now hysteria.service
}


coloredEcho $BLUE " 安装Hysteria ${HYSTERIA_VER}"
installHysteria
