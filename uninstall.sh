
#!/bin/bash
# Install xray with configurations
# Author: ratneo<https://ihost.wiki>

RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

coloredEcho() {
  echo -e "${1}${@:2}${PLAIN}"
}

uninstall(){
  systemctl stop nginx xray
  systemctl disable nginx xray
  rm -rf /etc/systemd/system/xray.service
  rm -rf /usr/local/bin/xray
  rm -rf /usr/local/etc/xray
  apt remove nginx nginx-common -y
  rm -rf /etc/nginx/nginx.conf
  rm -rf /etc/nginx/conf.d/*
}

read -p "确定要全部卸载吗 :" yn
[ -z "${yn}" ] && yn="y"
if [[ $yn == [Yy] ]]; then
  uninstall
fi
