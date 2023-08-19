#!/bin/bash
# Install Realm to forward traffic
# Author: ratneo<https://yezim.com>

RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

REALM_CONFIG_FOLDER="/opt/realm/"
REALM_CONFIG_FILE="/opt/realm/config.toml"
REALM_VER="v2.4.6"

coloredEcho() {
  echo -e "${1}${@:2}${PLAIN}"
}

checkRoot() {
  result=$(id | awk '{print $1}')
  if [[ $result != "uid=0(root)" ]]; then
    coloredEcho $RED " 请以root身份执行该脚本"
    exit 1
  fi
}

archAffix(){
    case "$(uname -m)" in
        x86_64|amd64)
            echo 'x86_64'
        ;;
        armv8|aarch64)
            echo 'aarch64'
        ;;
        *)
            coloredEcho $RED " 不支持的CPU架构！"
            exit 1
        ;;
    esac

	return 0
}

install() {
    rm -rf /tmp/realm && mkdir -p /tmp/realm
    DOWNLOAD_LINK="https://github.com/zhboner/realm/releases/download/${REALM_VER}/realm-$(archAffix)-unknown-linux-gnu.tar.gz"
    coloredEcho $BLUE " 下载Realm: ${DOWNLOAD_LINK}"
    curl -L -H "Cache-Control: no-cache" -o /tmp/realm/realm.tar.gz ${DOWNLOAD_LINK}
    if [ $? != 0 ];then
        coloredEcho $RED " 下载Realm文件失败，请检查服务器网络设置"
        exit 1
    fi
    tar -xvf /tmp/realm/realm.tar.gz
    mv realm /usr/local/bin
    chmod +x /usr/local/bin/realm || {
        coloredEcho $RED " Realm安装失败"
        exit 1
    }
    
    cat > /etc/systemd/system/realm.service <<EOF
[Unit]
Description=A simple, high performance relay server written in rust.
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Type=simple
User=root
Restart=always
RestartSec=5
#DynamicUser=true
ExecStart=/usr/local/bin/realm -c /opt/realm/config.toml

[Install]
WantedBy=multi-user.target
EOF


    mkdir -p ${REALM_CONFIG_FOLDER}
    cat > ${REALM_CONFIG_FILE} <<EOF
[log]
level = "warn"
output = "/var/log/realm.log"

[network]
no_tcp = false
use_udp = true


#[[endpoints]]
#listen = "0.0.0.0:2053"
#remote = "0.0.0.0:2053"
EOF

    systemctl daemon-reload
    systemctl enable realm
    sleep 2
    coloredEcho $BLUE " 安装完成"
}

checkRoot
install
