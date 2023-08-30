#!/bin/bash
# Install xray with configurations
# Author: ratneo<https://ihost.wiki>

RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

SBOX_CONFIG_FILE="/opt/singbox/config.json"
SBOX_VER="1.4.0"

coloredEcho() {
  echo -e "${1}${@:2}${PLAIN}"
}

checkRoot() {
  result=$(id | awk '{print $1}')
  if [[ $result != "uid=0(root)" ]]; then
    coloredEcho $YELLOW " 请以root身份执行该脚本"
    exit 1
  fi
}

archAffix(){
    case "$(uname -m)" in
        x86_64|amd64)
            echo 'amd64'
        ;;
        armv7|armv7l)
            echo 'armv7'
        ;;
        armv8|aarch64)
            echo 'arm64'
        ;;
        *)
            coloredEcho $RED " 不支持的CPU架构！"
            exit 1
        ;;
    esac

	return 0
}

getInput() {
  echo ""
  read -p " 请设置连接密码（不输则随机生成）:" PASSWORD
  [[ -z "$PASSWORD" ]] && PASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
  coloredEcho $BLUE " 密码：$PASSWORD"
}

installSBox() {
    rm -rf /tmp/sbox
    mkdir -p /tmp/sbox
    DOWNLOAD_LINK="https://github.com/SagerNet/sing-box/releases/download/v${SBOX_VER}/sing-box-${SBOX_VER}-linux-$(archAffix).tar.gz"
    coloredEcho $BLUE " 下载Sing-Box: ${DOWNLOAD_LINK}"
    curl -L -H "Cache-Control: no-cache" -o /tmp/sbox/sbox.tar.gz ${DOWNLOAD_LINK}
    if [ $? != 0 ];then
        coloredEcho $RED " 下载Sing-Box文件失败，请检查服务器网络设置"
        exit 1
    fi
    systemctl stop sbox
    tar -xvf /tmp/sbox/sbox.tar.gz
    mv ./sing-box-${SBOX_VER}-linux-$(archAffix)/sing-box /usr/local/bin
    chmod +x /usr/local/bin/sing-box || {
        coloredEcho $RED " Sing-Box安装失败"
        exit 1
    }

    cat >/etc/systemd/system/sbox.service<<-EOF
[Unit]
Description=sing-box service
Documentation=https://sing-box.sagernet.org
After=network.target nss-lookup.target

[Service]
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
ExecStart=/usr/local/bin/sing-box -D /var/lib/sing-box -C /opt/singbox run
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=10s
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable sbox.service
}


configSBox() {
    mkdir -p /opt/singbox
   cat > $SBOX_CONFIG_FILE<<-EOF
{
  "log": {
    "disabled": true
  },
  "inbounds": [
    {
      "type": "shadowsocks",
      "listen": "::",
      "listen_port": 61481,
      "method": "chacha20-ietf-poly1305",
      "password": "$PASSWORD"
    }
  ],
  "outbounds": [
    {
      "type": "direct"
    }
  ],
  "route": {
    "rules": [
    ]
  }
}
EOF
}

install() {
  apt clean all
  apt update -y
  apt install wget tar openssl net-tools -y

  coloredEcho $BLUE " 安装Sing-Box ${SBOX_VER} ，架构$(archAffix)"
  installSBox
  configSBox

  systemctl restart sbox
  sleep 2
  coloredEcho $BLUE " 安装完成"
}

checkRoot
getInput
install
