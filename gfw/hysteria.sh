#!/bin/bash
# Install hysteria with configurations
# Author: ratneo<https://ihost.wiki>

RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

HYSTERIA_CONF_PATH="/opt/hysteria"
HYSTERIA_CONFIG_FILE="/opt/hysteria/config.yaml"
HYSTERIA_VER="v2.0.0"

coloredEcho() {
  echo -e "${1}${@:2}${PLAIN}"
}

archAffix(){
    case "$(uname -m)" in
        x86_64|amd64)
            echo 'amd64'
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
  read -p " 请输入域名：" TROJAN_DOMAIN
  DOMAIN=${TROJAN_DOMAIN,,}
  coloredEcho ${BLUE}  " trojan伪装域名(host)：$TROJAN_DOMAIN"

  echo ""
  read -p " 请设置连接密码（不输则随机生成）:" PASSWORD
  [[ -z "$PASSWORD" ]] && PASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
  coloredEcho $BLUE " 密码：$PASSWORD"
}

installHysteria() {
    rm -rf ${HYSTERIA_CONF_PATH}
    systemctl stop hysteria
    DOWNLOAD_LINK="https://github.com/apernet/hysteria/releases/download/app%2F${HYSTERIA_VER}/hysteria-linux-$(archAffix)"
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
listen: :2083

tls:
  cert: /etc/letsencrypt/live/$TROJAN_DOMAIN/fullchain.pem
  key: /etc/letsencrypt/live/$TROJAN_DOMAIN/privkey.pem

auth:
  type: password
  password: $PASSWORD

masquerade:
  type: proxy
  proxy:
    url: https://bing.gifposter.com/
    rewriteHost: true
outbounds:
  - name: outbound
    type: socks5
    socks5:
      addr: 127.0.0.1:7890 
EOF


    cat >/etc/systemd/system/hysteria.service<<-EOF
[Unit]
Description=Hysteria Server Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/hysteria server --config $HYSTERIA_CONFIG_FILE
WorkingDirectory=$HYSTERIA_CONF_PATH
User=root
Environment=HYSTERIA_LOG_LEVEL=error
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now hysteria.service
}


coloredEcho $BLUE " 安装Hysteria ${HYSTERIA_VER}"

getInput
installHysteria
