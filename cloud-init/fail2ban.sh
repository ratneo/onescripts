  #!/bin/bash
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
