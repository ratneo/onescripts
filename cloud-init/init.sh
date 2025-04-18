#!/bin/bash
# Init script. Initialize for debian bullseye with proper apt source and prepare the tools
# Author: ratneo<https://yezim.com>

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
deb http://deb.debian.org/debian bookworm main contrib
#deb-src http://deb.debian.org/debian bookworm main contrib

deb http://deb.debian.org/debian-security/ bookworm-security main contrib
#deb-src http://deb.debian.org/debian-security/ bookworm-security main contrib

deb http://deb.debian.org/debian bookworm-updates main contrib
#deb-src http://deb.debian.org/debian bookworm-updates main contrib

deb http://deb.debian.org/debian bookworm-backports main contrib
#deb-src http://deb.debian.org/debian bookworm-backports main contrib
EOF
  apt update -y && apt upgrade -y
  apt install curl wget bash-completion emacs-nox git less screen nftables vnstat xz-utils net-tools dnsutils mtr unzip iperf3 jq nethogs iftop lsof sudo systemd-timesyncd certbot python3-certbot-nginx -y
  coloredEcho $GREEN " 初始化完成"
}

fail2ban_install() {
  apt install fail2ban -y
  systemctl enable --now fail2ban
  
  mkdir -p /etc/nftables/
  
  # Configure nftables for fail2ban, nftables is the default for Debian 11+
  cat > /etc/nftables/fail2ban.conf <<-EOF
#!/usr/sbin/nft -f
table ip fail2ban {
        chain input {
                type filter hook input priority 100;
        }
}
EOF

  echo "include \"/etc/nftables/fail2ban.conf\"" >> /etc/nftables.conf
  nft -f /etc/nftables/fail2ban.conf

  cat > /etc/fail2ban/action.d/nftables-common.local <<-EOF
[Init]
# Definition of the table used
nftables_family = ip
nftables_table  = fail2ban

# Drop packets 
blocktype       = drop

# Remove nftables prefix. Set names are limited to 15 char so we want them all
nftables_set_prefix =
EOF

  cat > /etc/fail2ban/jail.local <<-EOF
[sshd]
enabled   = true
mode      = aggressive

bantime   = 48h
findtime  = 48h
maxretry  = 3

port    = 30022
logpath = /var/log/auth.log

banaction = nftables-multiport
chain     = input
EOF



  fail2ban-client restart
  coloredEcho $GREEN " Fail2Ban 安装完成"
}

ssh_key_install() {
  wget --no-check-certificate https://raw.githubusercontent.com/wesleywxie/SSHKEY_Installer/master/key.sh
  bash key.sh wesleywxie

  sed -i "/#Port 22/c Port 30022" /etc/ssh/sshd_config
  sed -i "/Port 22/c Port 30022" /etc/ssh/sshd_config
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

dnscrypt_proxy_install() {
  apt install dnscrypt-proxy
  sudo sed -i "s/server_names = \['cloudflare'\]/server_names = \['cloudflare', 'google'\]/" /etc/dnscrypt-proxy/dnscrypt-proxy.toml
  echo "nameserver 127.0.2.1" | sudo tee /etc/resolv.conf
  chattr +i /etc/resolv.conf
  systemctl restart dnscrypt-proxy
  coloredEcho $GREEN " dnscrypt-proxy 安装完成"
}

smartdns_install() {
  wget -O smartdns-debian-all.deb "https://github.com/pymumu/smartdns/releases/download/Release43/smartdns.1.2023.08.11-1937.x86-debian-all.deb"
  dpkg -i smartdns-debian-all.deb && rm smartdns-debian-all.deb
  sudo sed -i "s/bind \[::\]:53/bind 127.0.0.1:53/" /etc/smartdns/smartdns.conf

  cat >> /etc/smartdns/smartdns.conf <<-EOF

# Cloudflare DoH
server-https https://1.1.1.1/dns-query
# Google DoH
server-https https://8.8.4.4/dns-query

EOF
  echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf
  chattr +i /etc/resolv.conf
  systemctl restart smartdns
  systemctl enable smartdns
  coloredEcho $GREEN " smartdns 安装完成"
}

checkRoot
apt_source
fail2ban_install
ssh_key_install
#cloudflare_doh_install
#dnscrypt_proxy_install
smartdns_install

coloredEcho $GREEN " 系统初始化完成，有些安装配置重启后生效"
