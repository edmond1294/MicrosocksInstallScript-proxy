#!/bin/bash
set -e

echo "[1/7] 安装编译环境..."
apt update
apt install -y git build-essential

echo "[2/7] 下载源码..."
cd /tmp
rm -rf microsocks
git clone https://github.speed-up.workers.dev/https://github.com/rofl0r/microsocks.git
cd microsocks

echo "[3/7] 编译..."
make

install -m 755 microsocks /usr/local/bin/microsocks

echo "[4/7] 生成账号密码..."
USER="admin"
PASS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)

echo "用户名: $USER"
echo "密码: $PASS"

echo "$PASS" >/etc/microsocks.pass
chmod 600 /etc/microsocks.pass

echo "[5/7] 创建 systemd 服务..."

cat >/etc/systemd/system/microsocks.service <<EOF
[Unit]
Description=MicroSocks SOCKS5 Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/microsocks -i 0.0.0.0 -p 1080 -u admin -P $PASS
Restart=always
RestartSec=3

NoNewPrivileges=true
PrivateTmp=true

StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
EOF

echo "[6/7] 清理编译环境..."

cd /
rm -rf /tmp/microsocks

apt purge -y git build-essential
apt autoremove -y
apt clean

echo "[7/7] 启动服务..."

systemctl daemon-reload
systemctl enable microsocks
systemctl restart microsocks

IP=$(curl -4 -s https://api.ipify.org || echo "服务器IP")

echo
echo "================================"
echo " SOCKS5 部署完成"
echo "================================"
echo "地址 : $IP"
echo "端口 : 1080"
echo "用户 : admin"
echo "密码 : $PASS"
echo "================================"

systemctl --no-pager --full status microsocks | head -10
