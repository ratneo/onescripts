#!/bin/bash
# Init script. Initialize for debian bullseye with proper apt source and prepare the tools
# Author: ratneo<https://ihost.wiki>

RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

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

apt_source() {
  cat > /etc/apt/sources.list<<-EOF
deb http://deb.debian.org/debian bullseye main
deb-src http://deb.debian.org/debian bullseye main

deb http://deb.debian.org/debian-security/ bullseye-security main
deb-src http://deb.debian.org/debian-security/ bullseye-security main

deb http://deb.debian.org/debian bullseye-updates main
deb-src http://deb.debian.org/debian bullseye-updates main

deb http://deb.debian.org/debian bullseye-backports main
deb-src http://deb.debian.org/debian bullseye-backports main
EOF
  apt update -y && apt upgrade -y
  apt install curl wget git less screen xz-utils net-tools dnsutils mtr unzip iperf3 jq nethogs iftop lsof sudo certbot python3-certbot-nginx -y
  coloredEcho $GREEN " 初始化完成"
}

fail2ban_install() {
  apt install fail2ban -y
  systemctl enable --now fail2ban

  cat > /etc/fail2ban/jail.local <<-EOF
[sshd]
enabled   = true
mode      = aggressive

bantime   = 48h
findtime  = 48h
maxretry  = 3
EOF

  fail2ban-client restart
  coloredEcho $GREEN " Fail2Ban 安装完成"
}

ssh_key_install() {
  wget --no-check-certificate https://raw.githubusercontent.com/wesleywxie/SSHKEY_Installer/master/key.sh
  bash key.sh wesleywxie

  sed -i "/#Port 22/c Port 30022" sshd_config
  sed -i "/Port 22/c Port 30022" sshd_config
  service sshd restart
  service ssh restart
  systemctl restart sshd
  systemctl restart ssh
  
  coloredEcho $GREEN " SSH Key 安装完成"
}

cloudflare_doh_install() {
  bash <(curl -sL https://github.com/wikihost-opensource/centos-init/raw/main/network/dns-over-https/cloudflare.sh)
  rm wikihost_cloudflare_doh_install.log
  chattr +i /etc/resolv.conf
  coloredEcho $GREEN " Cloudflare-DOH 安装完成"
}

besttrace_install() {
  wget -O /usr/local/bin/besttrace "https://od.okra.cf/api?path=/tools/besttrace&raw=true" && chmod +x /usr/local/bin/besttrace
  coloredEcho $GREEN " BestTrace 安装完成"
}

checkRoot
apt_source
fail2ban_install
ssh_key_install
cloudflare_doh_install
besttrace_install

read -p "系统初始化完成，建议重启后安装BBR，是否现在重启 ? [Y/n] :" yn
[ -z "${yn}" ] && yn="y"
if [[ $yn == [Yy] ]]; then
  echo -e "${Info} VPS 重启中..."
  reboot
fi