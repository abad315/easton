#!/bin/bash

set -euo pipefail

echo "====== 🚀 小技提示：ActivePieces + Traefik 自动部署开始 ======"

# 获取用户输入
read -p "🌐 请输入你的域名（例如 activepieces.example.com，当前默认 www.tdindicator.top）: " DOMAIN
DOMAIN=${DOMAIN:-"www.tdindicator.top"}  # 默认使用 www.tdindicator.top
read -p "📧 请输入你的邮箱（用于 Let's Encrypt 申请证书，当前默认 eastabcd@gmail.com）: " EMAIL
EMAIL=${EMAIL:-"eastabcd@gmail.com"}  # 默认使用 eastabcd@gmail.com

# 生成随机 Postgres 密码
AP_POSTGRES_PASSWORD=$(openssl rand -hex 16)

# 安装 Docker（如未安装）
if ! command -v docker &> /dev/null; then
    echo "🔧 小技提示：安装 Docker 中..."
    curl -fsSL https://get.docker.com | bash
fi

# 安装 Docker Compose Plugin（适配新版）
if ! docker compose version &> /dev/null; then
    echo "🔧 小技提示：安装 Docker Compose 插件中..."
    apt-get update
    apt-get install -y docker-compose-plugin
fi

# 创建工作目录
mkdir -p ~/activepieces-docker && cd ~/activepieces-docker

# 创建 Traefik 配置文件夹
mkdir -p traefik

# 写入 Traefik 配置
cat <<EOF > traefik/traefik.yml
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

providers:
  docker:
    exposedByDefault: false

certificatesResolvers:
  letsencrypt:
    acme:
      email: "$EMAIL"
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
EOF

# 创建 acme.json 并设置权限
touch traefik/acme.json
chmod 600 traefik/acme.json

# 创建 .env 文件
cat <<EOF > .env
AP_POSTGRES_DATABASE=activepieces_db
AP_POSTGRES_USERNAME=activepieces_user
AP_POSTGRES_PASSWORD=$AP_POSTGRES_PASSWORD
EOF

# 写入 docker-compose 配置
cat <<EOF > docker-compose.yml
version: '3.0'

services:
  traefik:
    image: traefik:v2.9
    restart: always
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge=true"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.letsencrypt.acme.email=$EMAIL"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "./traefik/traefik.yml:/traefik.yml:ro"
      - "./traefik/acme.json:/letsencrypt/acme.json"

  activepieces:
    image: activepieces/activepieces:latest
    restart: always
    depends_on:
      - postgres
      - redis
    env_file: .env
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.activepieces.rule=Host(\`$DOMAIN\`)"
      - "traefik.http.routers.activepieces.entrypoints=websecure"
      - "traefik.http.routers.activepieces.tls.certresolver=letsencrypt"
      - "traefik.http.services.activepieces.loadbalancer.server.port=80"
    volumes:
      - "/etc/timezone:/etc/timezone:ro"
      - "/etc/localtime:/etc/localtime:ro"

  postgres:
    image: postgres:14.10
    restart: always
    environment:
      - 'POSTGRES_DB=${AP_POSTGRES_DATABASE}'
      - 'POSTGRES_PASSWORD=${AP_POSTGRES_PASSWORD}'
      - 'POSTGRES_USER=${AP_POSTGRES_USERNAME}'
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7.0.7
    restart: always
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
EOF

# 启动服务
echo "🚀 启动 ActivePieces 和 Traefik..."
docker compose up -d

echo ""
echo "🎉 部署成功！请访问 👉 https://$DOMAIN"
echo "📁 项目目录：~/activepieces-docker"
echo "🔑 Postgres 密码: $AP_POSTGRES_PASSWORD (请保存好，用于备份)"
echo "👤 首次登录时创建账号和密码"