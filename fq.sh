#!/bin/bash
# Install xray with configurations
# Author: ratneo<https://ihost.wiki>

RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

XRAY_CONFIG_FILE="/usr/local/etc/xray/config.json"
NGINX_CONF_PATH="/etc/nginx/conf.d/"
NGINX_SERVICE_FILE="/lib/systemd/system/nginx.service"
XRAY_VER="v1.5.2"

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
        i686|i386)
            echo '32'
        ;;
        x86_64|amd64)
            echo '64'
        ;;
        armv5tel)
            echo 'arm32-v5'
        ;;
        armv6l)
            echo 'arm32-v6'
        ;;
        armv7|armv7l)
            echo 'arm32-v7a'
        ;;
        armv8|aarch64)
            echo 'arm64-v8a'
        ;;
        mips64le)
            echo 'mips64le'
        ;;
        mips64)
            echo 'mips64'
        ;;
        mipsle)
            echo 'mips32le'
        ;;
        mips)
            echo 'mips32'
        ;;
        ppc64le)
            echo 'ppc64le'
        ;;
        ppc64)
            echo 'ppc64'
        ;;
        ppc64le)
            echo 'ppc64le'
        ;;
        riscv64)
            echo 'riscv64'
        ;;
        s390x)
            echo 's390x'
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
  read -p " 请输入trojan伪装域名：" TROJAN_DOMAIN
  DOMAIN=${TROJAN_DOMAIN,,}
  coloredEcho ${BLUE}  " trojan伪装域名(host)：$TROJAN_DOMAIN"

  echo ""
  read -p " 请输入grpc伪装域名：" GRPC_DOMAIN
  DOMAIN=${GRPC_DOMAIN,,}
  coloredEcho ${BLUE}  " trojan伪装域名(host)：$GRPC_DOMAIN"

  echo ""
  read -p " 请设置连接密码（不输则随机生成）:" PASSWORD
  [[ -z "$PASSWORD" ]] && PASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
  coloredEcho $BLUE " 密码：$PASSWORD"
  
  echo ""
  read -p " 请输入伪装路径，以/开头(不懂请直接回车)：" WSPATH
  if [[ -z "${WSPATH}" ]]; then
      len=`shuf -i5-12 -n1`
      ws=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $len | head -n 1`
      WSPATH="/$ws"
  fi
  coloredEcho ${BLUE}  " ws路径：$WSPATH"

  PROXY_URL="https://bing.imeizi.me"
  REMOTE_HOST=`echo ${PROXY_URL} | cut -d/ -f3`
  ALLOW_SPIDER="n"
  coloredEcho ${BLUE}  " 伪装域名：$REMOTE_HOST"
  coloredEcho ${BLUE}  " 是否允许爬虫：$ALLOW_SPIDER"
}

getCert() {
  certbot certonly --nginx -d $TROJAN_DOMAIN
  certbot certonly --nginx -d $GRPC_DOMAIN
}

configNginx() {
  mkdir -p /usr/share/nginx/html;
  if [[ "$ALLOW_SPIDER" = "n" ]]; then
    echo 'User-Agent: *' > /usr/share/nginx/html/robots.txt
    echo 'Disallow: /' >> /usr/share/nginx/html/robots.txt
    ROBOT_CONFIG="    location = /robots.txt {}"
  else
    ROBOT_CONFIG=""
  fi

  if [[ ! -f /etc/nginx/nginx.conf.bak ]]; then
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
  fi
  res=`id nginx 2>/dev/null`
  if [[ "$?" != "0" ]]; then
    user="www-data"
  else
    user="nginx"
  fi
  cat > /etc/nginx/nginx.conf<<-EOF
user $user;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
load_module /usr/lib/nginx/modules/ngx_stream_module.so;
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 65535;
}

http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;
    server_tokens off;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;
    gzip                on;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;
}
stream {
    map \$ssl_preread_server_name \$sni {
        ${TROJAN_DOMAIN}  trojan;
        ${GRPC_DOMAIN}   grpc;
    }
    upstream trojan {
        server 127.0.0.1:10443;
    }
    upstream grpc {
        server 127.0.0.1:10445;
    }
    server {
        listen 443      reuseport;
        listen [::]:443 reuseport;
        proxy_pass      \$sni;
        ssl_preread     on;
    }
    server {
        listen 2053      reuseport;
        listen [::]:2053 reuseport;
        proxy_pass      \$sni;
        ssl_preread     on;
    }
}
EOF

  mkdir -p ${NGINX_CONF_PATH}

  if [[ "$PROXY_URL" = "" ]]; then
    action=""
  else
    action="proxy_ssl_server_name on;
    proxy_pass $PROXY_URL;
    proxy_set_header Accept-Encoding '';
    sub_filter \"$REMOTE_HOST\" \"$TROJAN_DOMAIN\";
    sub_filter_once off;"
  fi

  cat > ${NGINX_CONF_PATH}${TROJAN_DOMAIN}.conf<<-EOF
server {
    listen 80;
    listen [::]:80;
    listen 81 http2;
    server_name ${TROJAN_DOMAIN};
    root /usr/share/nginx/html;
    location / {
        $action
    }
    $ROBOT_CONFIG
}
EOF
  if [[ "$PROXY_URL" = "" ]]; then
    action=""
  else
    action="proxy_ssl_server_name on;
    proxy_pass $PROXY_URL;
    proxy_set_header Accept-Encoding '';
    sub_filter \"$REMOTE_HOST\" \"$GRPC_DOMAIN\";
    sub_filter_once off;"
  fi
  cat > ${NGINX_CONF_PATH}${GRPC_DOMAIN}.conf<<-EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${GRPC_DOMAIN};
    location ${WSPATH} {
      proxy_redirect off;
      proxy_pass http://127.0.0.1:44635;
      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host \$host;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    location / {
        $action
    }
    $ROBOT_CONFIG
}

server {
    listen 2095;
    listen [::]:2095;
    server_name ${GRPC_DOMAIN};
    location ${WSPATH} {
      proxy_redirect off;
      proxy_pass http://127.0.0.1:44635;
      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host \$host;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    location / {
        $action
    }
    $ROBOT_CONFIG
}

server {
    listen 10445 ssl http2;
    listen [::]:10445 ssl http2;
    server_name ${GRPC_DOMAIN}; #修改成自己的域名

    ssl_certificate /etc/letsencrypt/live/${GRPC_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${GRPC_DOMAIN}/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location /grpc {
        grpc_pass grpc://127.0.0.1:2010;
    }

    location ${WSPATH} {
      proxy_redirect off;
      proxy_pass http://127.0.0.1:44635;
      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host \$host;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location / {
        $action
    }
    $ROBOT_CONFIG

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
}
EOF
cat > ${NGINX_SERVICE_FILE}<<-EOF
# Stop dance for nginx
# =======================
#
# ExecStop sends SIGSTOP (graceful stop) to the nginx process.
# If, after 5s (--retry QUIT/5) nginx is still running, systemd takes control
# and sends SIGTERM (fast shutdown) to the main process.
# After another 5s (TimeoutStopSec=5), and if nginx is alive, systemd sends
# SIGKILL to all the remaining processes in the process group (KillMode=mixed).
#
# nginx signals reference doc:
# http://nginx.org/en/docs/control.html
#
[Unit]
Description=A high performance web server and a reverse proxy server
Documentation=man:nginx(8)
After=network.target nss-lookup.target
StartLimitIntervalSec=0

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx.pid
TimeoutStopSec=5
KillMode=mixed
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl restart nginx
}

installXray() {
    rm -rf /tmp/xray
    mkdir -p /tmp/xray
    DOWNLOAD_LINK="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/Xray-linux-$(archAffix).zip"
    coloredEcho $BLUE " 下载Xray: ${DOWNLOAD_LINK}"
    curl -L -H "Cache-Control: no-cache" -o /tmp/xray/xray.zip ${DOWNLOAD_LINK}
    if [ $? != 0 ];then
        coloredEcho $RED " 下载Xray文件失败，请检查服务器网络设置"
        exit 1
    fi
    systemctl stop xray
    mkdir -p /usr/local/etc/xray /usr/local/share/xray && \
    unzip /tmp/xray/xray.zip -d /tmp/xray
    cp /tmp/xray/xray /usr/local/bin
    cp /tmp/xray/geo* /usr/local/share/xray
    chmod +x /usr/local/bin/xray || {
        coloredEcho $RED " Xray安装失败"
        exit 1
    }

    cat >/etc/systemd/system/xray.service<<-EOF
[Unit]
Description=Xray Service
After=network.target nss-lookup.target

[Service]
User=root
#User=nobody
#CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
#AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable xray.service
}


configXray() {
    mkdir -p /usr/local/xray
   cat > $XRAY_CONFIG_FILE<<-EOF
{
  "log": {
    "loglevel": "none"
  },
  "inbounds": [
    {
      "port": 10443,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$PASSWORD",
            "flow": "xtls-rprx-direct"
          }
        ],
        "fallbacks": [
          {
            "alpn": "http/1.1",
            "dest": 80
          },
          {
            "alpn": "h2",
            "dest": 81
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "xtls",
        "xtlsSettings": {
          "serverName": "$TROJAN_DOMAIN",
          "alpn": ["http/1.1", "h2"],
          "certificates": [
            {
              "certificateFile": "/etc/letsencrypt/live/$TROJAN_DOMAIN/fullchain.pem",
              "keyFile": "/etc/letsencrypt/live/$TROJAN_DOMAIN/privkey.pem"
            }
          ]
        }
      }
    },
    {
      "port": 2010,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password":"$PASSWORD"
          }
        ]
      },
      "streamSettings": {
        "network": "grpc",
        "security": "none",
        "grpcSettings": {
          "serviceName": "grpc",
          "multiMode": false,
          "idle_timeout": 10,
          "health_check_timeout": 20,
          "permit_without_stream": false,
          "initial_windows_size": 524288
        }
      }
    },
    {
      "port": 44635,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "4fe457b3-6584-4648-a473-66f5e33000dd",
            "level": 1,
            "alterId": 0
          }
        ],
        "disableInsecureEncryption": false
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "$WSPATH"
        }
      }
    },
    {
      "port": 61481,
      "protocol": "shadowsocks",
      "settings": {
        "clients": [
          {
            "method": "chacha20-poly1305",
            "password": "$PASSWORD",
            "level": 0
          }
        ],
        "network": "tcp,udp"
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {}
    },
    {
      "tag": "blackhole",
      "protocol": "blackhole",
      "settings": {}
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "protocol": [
          "bittorrent"
        ],
        "outboundTag": "blackhole"
      },
      {
        "type": "field",
        "ip": [
          "127.0.0.1/32",
          "10.0.0.0/8",
          "fc00::/7",
          "fe80::/10",
          "172.16.0.0/12"
        ],
        "outboundTag": "blackhole"
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": [
          "google.com",
          "googlevideo.com",
          "gstatic.com",
          "youtube.com"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": [
          "geosite:netflix",
          "geosite:disney",
          "us-west-2.amazonaws.com"
        ]
      }
    ]
  }
}
EOF
}

install() {
  apt clean all
  apt update -y
  apt install wget vim unzip tar gcc openssl net-tools libssl-dev g++ -y

  echo ""
  coloredEcho $BLUE " 安装nginx..."
  apt install nginx -y
  systemctl enable nginx

  coloredEcho $BLUE " 申请证书..."
  getCert

  configNginx
  coloredEcho $BLUE " 证书和Nginx配置完毕..."

  coloredEcho $BLUE " 安装Xray ${XRAY_VER} ，架构$(archAffix)"
  installXray
  configXray

  nginx -s stop
  systemctl start nginx
  systemctl restart xray
  sleep 2
  coloredEcho $BLUE " 安装完成"
}

checkRoot
getInput
install
