#!/bin/sh
set -e

echo "[1/6] 安装依赖..."
apk update
apk add --no-cache git gcc make musl-dev linux-headers openssl-dev curl

echo "[2/6] 编译 microsocks..."
cd /tmp
rm -rf microsocks
git clone https://github.com/rofl0r/microsocks.git
cd microsocks
make
install -m 755 microsocks /usr/local/bin/microsocks

echo "[3/6] 生成账号密码..."
USER="admin"
PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)

echo "USER=$USER"
echo "PASS=$PASS"

echo "[4/6] 写启动脚本（双栈）..."

cat >/usr/local/bin/microsocks-run.sh <<EOF
#!/bin/sh

PORT=1080
USER=admin
PASS=$PASS

/usr/local/bin/microsocks -i 0.0.0.0 -p \$PORT -u \$USER -P \$PASS &

if ip -6 addr show scope global >/dev/null 2>&1; then
  /usr/local/bin/microsocks -i :: -p \$PORT -u \$USER -P \$PASS &
fi

wait
EOF

chmod +x /usr/local/bin/microsocks-run.sh

echo "[5/6] 尝试 systemd（没有就 fallback）..."

if command -v systemctl >/dev/null 2>&1; then
cat >/etc/systemd/system/microsocks.service <<EOF
[Unit]
Description=Microsocks Alpine Dual Stack
After=network.target

[Service]
ExecStart=/usr/local/bin/microsocks-run.sh
Restart=always
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable microsocks
systemctl restart microsocks

else
  nohup /usr/local/bin/microsocks-run.sh >/dev/null 2>&1 &
fi

echo "[6/6] 清理环境..."
apk del git gcc make musl-dev linux-headers openssl-dev

echo ""
echo "=========================="
echo "Microsocks Alpine 部署完成"
echo "IPV4: $(curl -4 -s ifconfig.me || echo N/A)"
echo "IPV6: $(curl -6 -s ifconfig.me || echo N/A)"
echo "PORT: 1080"
echo "USER: admin"
echo "PASS: $PASS"
echo "=========================="