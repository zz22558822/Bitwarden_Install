#!/bin/bash

# 取得當前IP
ip_address=$(hostname -I | awk '{print $1}')

# 清理 Docker
sudo systemctl stop docker docker.socket containerd 2>/dev/null || true
sudo apt purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
sudo rm -rf /var/lib/docker 2>/dev/null
sudo rm -rf /var/lib/containerd 2>/dev/null
sudo rm -f /etc/apt/keyrings/docker.asc 2>/dev/null
sudo rm -f /etc/apt/keyrings/docker.gpg 2>/dev/null
sudo rm -f /etc/apt/sources.list.d/docker.list 2>/dev/null
sudo apt autoremove -y
sudo apt clean


# 安裝 Docker
sudo apt update -y
sudo apt install -y ca-certificates curl gnupg lsb-release
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
cat /etc/apt/sources.list.d/docker.list
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin



# Docker 開機啟用+群組設定
sudo systemctl start docker
sudo systemctl enable docker
sudo groupadd docker 2>/dev/null
sudo su - $USER -c "echo 'Docker 安裝完成，群組變更已生效。'"



# 帳戶權限設置 
sudo adduser --gecos "" bitwarden
sudo usermod -aG docker bitwarden
sudo mkdir -p /opt/bitwarden
sudo chmod -R 700 /opt/bitwarden
sudo chown -R bitwarden:bitwarden /opt/bitwarden



# 設置參數
echo "---------------------------------------------------------"
echo "                   請依下方順序填入"
echo "---------------------------------------------------------"
cat << EOF | column -t -s '|'
0. 您使用管理員權限運行仍要繼續嗎?| y
1. 輸入您的 Bitwarden 域名| 空白跳過
2. 輸入您的 Bitwarden 資料庫名稱| Bitwarden
3. 輸入您的安裝 ID| 請於Bitwarden獲取
4. 輸入您的安裝密鑰| 請於Bitwarden獲取
5. 輸入您的地區 (US/EU) [US]| US
6. 您是否有可用的 SSL 憑證? (Y/N)| n
7. 您要生成自簽名 SSL 憑證嗎? (Y/N)| y
EOF
echo "---------------------------------------------------------"
echo "※ 若安裝腳本錯誤需重新安裝，請刪除/opt/bitwarden/bwdata"
echo "---------------------------------------------------------"


# 下載腳本與安裝 
sudo curl -Lso /opt/bitwarden/bitwarden.sh https://go.btwrdn.co/bw-sh && sudo chmod 777 /opt/bitwarden/bitwarden.sh
sudo /opt/bitwarden/bitwarden.sh install


# 修改參數並啟動
sudo sed -i 's/ssl: true/ssl: false/g' /opt/bitwarden/bwdata/config.yml
sudo /opt/bitwarden/bitwarden.sh start


echo ""
echo "✅ Bitwarden 安裝完成！"
echo "🔐 管理後台網址: https://$ip_address"
echo ""
