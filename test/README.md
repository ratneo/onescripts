# to store scripts which perform the benchmark and performance tests


## Media unlock check 

### lmc999/RegionRestrictionCheck

```bash
bash <(curl -L -s check.unlock.media)
```

### nkeonkeo/MediaUnlockTest

```bash
bash <(curl -Ls unlock.moe) -m 4
```

## Trace route tools

### NextTrace

```bash
bash -c "$(curl http://nexttrace-io-leomoe-api-a0.shop/nt_install_v1.sh)"
echo "alias 'besttrace=nexttrace -M --data-provider IPInfo'" >> /root/.bashrc
source /root/.bashrc
```

### BestTrace

```bash
wget https://cdn.ipip.net/17mon/besttrace4linux.zip
unzip -d /usr/local/bin/ besttrace4linux.zip "besttrace"
rm besttrace4linux.zip
chmod +x /usr/local/bin/besttrace
alias 'besttrace=besttrace -q 1'
echo "alias 'besttrace=besttrace -q 1'" >> /root/.bashrc
```

## Performance test

### yabs

```bash
curl -sL yabs.sh | bash -s -- -5 -i
```

### 融合怪

```bash
echo 1 | bash <(wget -qO- bash.spiritlhl.net/ecs)
```

### SuperBench.sh 网络带宽及硬盘读写速率（国内三网+speedtest+fast）
```bash
wget -qO- --no-check-certificate https://raw.githubusercontent.com/oooldking/script/master/superbench.sh | bash
```

### Speedtest
```bash
curl -fsSL git.io/speedtest-cli.sh | bash && speedtest
```

### hyperspeed 三网测速（未开源）
```bash
bash <(curl -Lso- https://bench.im/hyperspeed)
```

### AutoTrace 三网回程线路显示
```bash
wget -N --no-check-certificate https://raw.githubusercontent.com/Chennhaoo/Shell_Bash/master/AutoTrace.sh && chmod +x AutoTrace.sh && bash AutoTrace.sh
```
