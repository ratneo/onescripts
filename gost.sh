#!/bin/bash
# Install Gost to forward traffic
# Author: ratneo<https://yezim.com>

RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

GOST_CONFIG_FOLDER="/opt/gost/"
GOST_CONFIG_FILE="/opt/gost/config.toml"
GOST_VER="2.11.5"

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
            echo 'amd64'
        ;;
        armv5tel)
            echo 'armv5'
        ;;
        armv6l)
            echo 'armv6'
        ;;
        armv7|armv7l)
            echo 'armv7'
        ;;
        armv8|aarch64)
            echo 'armv8'
        ;;
        *)
            coloredEcho $RED " 不支持的CPU架构！"
            exit 1
        ;;
    esac

	return 0
}


install() {
    rm -rf /tmp/gost && mkdir -p /tmp/gost
    DOWNLOAD_LINK="https://github.com/ginuerzh/gost/releases/download/v${GOST_VER}/gost-linux-$(archAffix)-${GOST_VER}.gz"
    coloredEcho $BLUE " 下载Realm: ${DOWNLOAD_LINK}"
    curl -L -H "Cache-Control: no-cache" -o /tmp/gost/gost.gz ${DOWNLOAD_LINK}
    if [ $? != 0 ];then
        coloredEcho $RED " 下载GOST文件失败，请检查服务器网络设置"
        exit 1
    fi
    gunzip /tmp/gost/gost.gz
    mv /tmp/gost/gost /usr/local/bin
    chmod +x /usr/local/bin/gost || {
        coloredEcho $RED " GOST安装失败"
        exit 1
    }
    
    cat > /etc/systemd/system/gost.service <<EOF
[Unit]
Description=A simple security tunnel written in Golang
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Type=simple
User=root
Restart=always
RestartSec=5
DynamicUser=true
ExecStart=/usr/local/bin/gost -C $GOST_CONFIG_FILE

[Install]
WantedBy=multi-user.target
EOF


    mkdir -p ${GOST_CONFIG_FOLDER}
    cat > ${GOST_CONFIG_FILE} <<EOF
{
    "Debug": true,
    "Retries": 0,
    "ServeNodes": [
        "udp://127.0.0.1:65532"
    ]
}
EOF

    cat > ${GOST_CONFIG_FILE}.example <<EOF
{
    "Debug": true,
    "Retries": 0,
    // 端口转发
    "ServeNodes": [
        "tcp://:10024/1.1.1.1:10024",
        "udp://:10024/1.1.1.1:10024"
    ],
    "Routes": [
        // CDN转发
        {
            "Retries": 0,
            "ServeNodes": [
                "tcp://:10025",
                "udp://:10025"
            ],
            "ChainNodes": [
                "relay+ws://1.1.1.1:2095?host=a.b.c"
            ]
        },
        // WS隧道加密转发
        {
            "Retries": 0,
            "ServeNodes": [
                "tcp://:10021",
                "udp://:10021"
            ],
            "ChainNodes": [
                "relay+ws://1.1.1.1:10021"
            ]
        },
        // WS隧道解密
        {
            "Retries": 0,
            "ServeNodes": [
                "relay+ws://:10022/1.1.1.1:10022"
            ]
        }
    ]
}
EOF


    systemctl daemon-reload
    systemctl enable gost
    systemctl start gost
    sleep 2
    coloredEcho $BLUE " 安装完成"
}

checkRoot
install
