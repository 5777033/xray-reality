#!/bin/bash
set -e

echo "=== Xray Reality VLESS 一键部署脚本 ==="

# 当前目录
DEPLOY_DIR=$(pwd)
CONFIG_FILE="$DEPLOY_DIR/config.json"
COMPOSE_FILE="$DEPLOY_DIR/docker-compose.yml"
LOG_DIR="$DEPLOY_DIR/logs"

# 输入公网IP
read -rp "请输入服务器公网IP（必须手动输入）: " SERVER_IP
if [[ -z "$SERVER_IP" ]]; then
  echo "错误：公网IP不能为空！"
  exit 1
fi

# 输入端口号，默认5000
read -rp "请输入监听端口（默认5000）: " PORT
PORT=${PORT:-5000}

SNI="www.microsoft.com"
FP="chrome"
REMARK="RealityServer"

echo "部署目录: $DEPLOY_DIR"
echo "日志目录: $LOG_DIR"
echo "公网IP: $SERVER_IP"
echo "端口: $PORT"

echo "==> 创建目录和日志文件夹..."
mkdir -p "$LOG_DIR"

echo "==> 生成 Reality 密钥对..."
KEYPAIR=$(docker run --rm teddysun/xray xray x25519)
PRIVATE_KEY=$(echo "$KEYPAIR" | grep 'Private key:' | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEYPAIR" | grep 'Public key:' | awk '{print $3}')
echo "Private key: $PRIVATE_KEY"
echo "Public key:  $PUBLIC_KEY"

echo "==> 生成 UUID..."
UUID=$(docker run --rm teddysun/xray xray uuid)
echo "UUID:        $UUID"

echo "==> 生成 ShortID (8位十六进制)..."
SHORTID=$(openssl rand -hex 4)
echo "ShortID:     $SHORTID"

echo "==> 写入配置文件 $CONFIG_FILE ..."
cat > "$CONFIG_FILE" <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [{
    "port": $PORT,
    "protocol": "vless",
    "settings": {
      "clients": [{
        "id": "$UUID",
        "flow": "xtls-rprx-vision"
      }],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "dest": "$SNI:443",
        "serverNames": ["$SNI"],
        "privateKey": "$PRIVATE_KEY",
        "shortIds": ["$SHORTID"]
      }
    }
  }],
  "outbounds": [{
    "protocol": "freedom"
  }]
}
EOF

echo "==> 写入 docker-compose.yml 文件 $COMPOSE_FILE ..."
cat > "$COMPOSE_FILE" <<EOF
version: '3.8'
services:
  xray:
    image: teddysun/xray:latest
    container_name: xray
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./config.json:/etc/xray/config.json
      - ./logs:/var/log/xray
EOF

echo "==> 启动容器..."
docker compose up -d

echo
echo "部署完成！"
echo "客户端配置参数："
echo "协议：VLESS"
echo "地址：$SERVER_IP"
echo "端口：$PORT"
echo "UUID：$UUID"
echo "流控：xtls-rprx-vision"
echo "传输层：TCP + Reality"
echo "公钥：$PUBLIC_KEY"
echo "SNI：$SNI"
echo "ShortID：$SHORTID"
echo

LINK="vless://$UUID@$SERVER_IP:$PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$SNI&fp=$FP&pbk=$PUBLIC_KEY&sid=$SHORTID&type=tcp#$REMARK"

echo "==== VLESS Reality 连接链接 ===="
echo "$LINK"
echo

if ! command -v qrencode &>/dev/null; then
  echo "未检测到 qrencode，尝试安装（需 apt 支持）..."
  sudo apt update && sudo apt install -y qrencode
fi

echo "==== 二维码 ===="
qrencode -t UTF8 "$LINK"
echo

echo "查看日志："
echo "  docker compose logs -f"
echo "  或"
echo "  docker exec -it xray tail -f /var/log/xray/error.log"
