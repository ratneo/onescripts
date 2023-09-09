#!/bin/bash
# Init script. Initialize for debian bullseye with proper apt source and prepare the tools
# Author: ratneo<https://yezim.com>

apt install restic -y

curl https://rclone.org/install.sh | bash
mkdir -p /root/.config/rclone/
touch /root/.config/rclone/rclone.conf

echo ""
read -p " Please fillin your rclone conf:" RCLONE_CONF
read -p " Please fillin your restic repository name (will skip if empty):" RESTIC_REPOSITORY
read -p " Please fillin your restic repository password (will skip if empty):" RESTIC_PASSWORD

echo "${RCLONE_CONF}" >> /root/.config/rclone/rclone.conf

if [[ -n "$RESTIC_REPOSITORY" ]] then
  echo "export RESTIC_REPOSITORY=${RESTIC_REPOSITORY}" >> /root/.bashrc
  source /root/.bashrc
fi
if [[ -n "$RESTIC_PASSWORD" ]] then
  echo "export RESTIC_PASSWORD=${RESTIC_PASSWORD}" >> /root/.bashrc
  source /root/.bashrc
fi
