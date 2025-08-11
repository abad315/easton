#!/bin/bash

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 检查是否以 root 或 sudo 运行
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}请以 root 或 sudo 运行此脚本${NC}"
  exit 1
fi

# 更新系统
echo -e "${GREEN}更新系统包...${NC}"
apt update && apt upgrade -y

# 安装 Node.js 和 npm
echo -e "${GREEN}安装 Node.js 和 npm...${NC}"
apt install -y nodejs npm
if [ $? -ne 0 ]; then
  echo -e "${RED}Node.js 安装失败，请手动检查${NC}"
  exit 1
fi

# 创建项目目录
echo -e "${GREEN}创建项目目录...${NC}"
mkdir -p /opt/discord-bot
cd /opt/discord-bot

# 初始化项目
echo -e "${GREEN}初始化 Node.js 项目...${NC}"
npm init -y

# 安装 Discord.js
echo -e "${GREEN}安装 Discord.js...${NC}"
npm install discord.js

# 获取 Bot Token（手动输入）
read -p "请输入您的 Bot Token: " BOT_TOKEN
if [ -z "$BOT_TOKEN" ]; then
  echo -e "${RED}Bot Token 不能为空${NC}"
  exit 1
fi

# 写入 Bot 代码
cat > index.js << 'EOF'
const { Client, IntentsBitField } = require('discord.js');

const client = new Client({
  intents: [
    IntentsBitField.Flags.Guilds,
    IntentsBitField.Flags.GuildMessages,
    IntentsBitField.Flags.MessageContent
  ]
});

const TOKEN = process.env.BOT_TOKEN;

client.on('ready', () => {
  console.log(`Logged in as ${client.user.tag}!`);
});

client.on('messageCreate', (message) => {
  if (message.content === '!ping') {
    message.reply('Pong!');
  }
});

client.login(TOKEN);
EOF

# 设置环境变量
echo "BOT_TOKEN=$BOT_TOKEN" > .env

# 安装 pm2
echo -e "${GREEN}安装 pm2...${NC}"
npm install -g pm2

# 启动 Bot
echo -e "${GREEN}启动 Discord Bot...${NC}"
pm2 start index.js --name "discord-bot" --env .env
pm2 save
pm2 startup

echo -e "${GREEN}部署完成！请使用 'pm2 list' 检查状态${NC}"
