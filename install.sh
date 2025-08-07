#!/bin/bash
apt update && apt upgrade -y
apt install -y git python3-venv python3-pip
git clone https://github.com/ertugrul59/tradingview-chart-mcp.git
cd tradingview-chart-mcp
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt install -y ./google-chrome-stable_current_amd64.deb
CHROME_VERSION=$(google-chrome --version | grep -o '[0-9]*\.[0-9]*\.[0-9]*')
wget https://chromedriver.storage.googleapis.com/$CHROME_VERSION/chromedriver_linux64.zip
unzip chromedriver_linux64.zip
mv chromedriver /usr/local/bin/
chmod +x /usr/local/bin/chromedriver
cp .env.example .env
echo "TRADINGVIEW_SESSION_ID=m4gyrgsdj56tl9o26sybtldqhk6n5fjq" >> .env
echo "TRADINGVIEW_SESSION_ID_SIGN=v3:5S95PPfuVubh64QLxCR/KEJt6liAY6br/OuHbCyeOo0=" >> .env
