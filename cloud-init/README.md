## to store scripts which help to initialize the VM

echo "export LC_CTYPE=en_US.UTF-8" >> /root/.bashrc
echo "export LC_ALL=en_US.UTF-8" >> /root/.bashrc
source /root/.bashrc

echo "Etc/UTC" > /etc/timezone 
dpkg-reconfigure -f noninteractive tzdata

apt update && apt install curl -y

bash <(curl -Ls https://raw.githubusercontent.com/ratneo/onescripts/main/cloud-init/init.sh)

apt remove linux-image* -y && apt install linux-image-cloud-amd64 -y

bash <(curl -Ls https://raw.githubusercontent.com/ratneo/onescripts/main/cloud-init/network.sh)

### SWAP
```bash
bash <(curl -sL https://www.moerats.com/usr/shell/swap.sh)
```