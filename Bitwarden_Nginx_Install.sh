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
echo "---------------------------------------------------------"
echo "                  建立Bitwarden帳戶"
echo "---------------------------------------------------------"
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
1. 輸入您的 Bitwarden 域名| 空白跳過
2. 輸入您的 Bitwarden 資料庫名稱| Bitwarden
3. 輸入您的安裝 ID| 請於Bitwarden獲取
4. 輸入您的安裝密鑰| 請於Bitwarden獲取
5. 輸入您的地區 (US/EU) [US]| US
6. 您是否有可用的 SSL 憑證? (Y/N)| N
7. 您要生成自簽名 SSL 憑證嗎? (Y/N)| N
EOF
echo "---------------------------------------------------------"
echo "※ 若安裝腳本錯誤需重新安裝，請刪除/opt/bitwarden/bwdata"
echo "---------------------------------------------------------"


# 下載腳本
sudo curl -Lso /opt/bitwarden/bitwarden.sh https://go.btwrdn.co/bw-sh && sudo chmod 777 /opt/bitwarden/bitwarden.sh

# 取消顯示管理員權限
sudo sed -i '/^if \[ "\$EUID" -eq 0 \]; then/,/^fi/c\if [ "\$EUID" -eq 0 ]; then\n    echo -e "${RED}※※※ 當前使用管理員 root 權限進行安裝 ※※※${NC}"\nfi' /opt/bitwarden/bitwarden.sh

# 安裝腳本
sudo /opt/bitwarden/bitwarden.sh install


# 修改參數並啟動
sudo sed -i 's/ssl: true/ssl: false/g' /opt/bitwarden/bwdata/config.yml
sudo sed -i 's/^http_port: 80$/http_port: 8080/' /opt/bitwarden/bwdata/config.yml
sudo sed -i 's/^https_port: 443$/https_port: 8443/' /opt/bitwarden/bwdata/config.yml
sudo /opt/bitwarden/bitwarden.sh rebuild
sudo /opt/bitwarden/bitwarden.sh start

# 使用 Nginx 反向代理
sudo rm -f /opt/bitwarden/nginx_domain.tmp
sudo touch /opt/bitwarden/nginx_domain.tmp

sudo bash -c "$(
	wget -qO- https://raw.githubusercontent.com/zz22558822/Nginx_Re_Proxy_install/main/Nginx_Re_Proxy_install.sh |
    sed 's/WordPress/Bitwarden/g' |
    sed '/sudo systemctl restart nginx/i echo "$DOMAIN" | sudo tee /opt/bitwarden/nginx_domain.tmp > /dev/null' 
)"

if [ -f /opt/bitwarden/nginx_domain.tmp ]; then
    NGINX_DOMAIN=$(sudo cat /opt/bitwarden/nginx_domain.tmp)
    # 刪除臨時檔案
    sudo rm -f /opt/bitwarden/nginx_domain.tmp
fi


echo ""
echo "=========================================================="
echo " ✅ Bitwarden 安裝完成！"
echo "=========================================================="
echo ""
echo "※※※ 若為自簽名則無法使用應用程式版本僅能使用 Web ※※※"
echo "※※※ 建議可以改用 Vaultwarden SSL 驗證較寬鬆      ※※※"
echo ""
echo "請務必執行以下重要步驟："
echo ""
echo "1. 匯入根憑證："
echo "   將 /opt/SSL/certificate.crt 檔案複製到您的所有客戶端設備，"
echo "   並且把 certificate.crt 檔案匯入為 **受信任的根憑證**。"
echo ""
echo "2. 存取位址："
echo "   🔐 Bitwarden 服務: https://$NGINX_DOMAIN"
echo ""
echo "=========================================================="