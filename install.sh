#!/bin/bash
# Zabbix 7.4 installer for Debian 12 and Ubuntu 22.04

set -euo pipefail
IFS=$'\n\t'

# Detect OS 
echo "[INFO] Detecting OS..."
OS=$(lsb_release -si)
VER=$(lsb_release -sr)

if [[ "$OS" == "Debian" && "$VER" == "12"* ]]; then
    REPO_URL="https://repo.zabbix.com/zabbix/7.4/release/debian/pool/main/z/zabbix-release/zabbix-release_latest_7.4+debian12_all.deb"
elif [[ "$OS" == "Ubuntu" && "$VER" == "22.04"* ]]; then
    REPO_URL="https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu22.04_all.deb"
else
    echo "[ERROR] Only Debian 12 and Ubuntu 22.04 are supported."
    exit 1
fi
echo "[OK] OS detected: $OS $VER"

# User input
read -rp "Enter Zabbix Server IP [127.0.0.1]: " ZABBIX_IP
ZABBIX_IP=${ZABBIX_IP:-127.0.0.1}
read -rp "Enter Zabbix DB name [zabbix]: " DB_NAME
DB_NAME=${DB_NAME:-zabbix}
read -rp "Enter Zabbix DB user [zabbix]: " DB_USER
DB_USER=${DB_USER:-zabbix}
while true; do read -rsp "Enter Zabbix DB password: " DB_PASS; echo; [[ -n "$DB_PASS" ]] && break; done
while true; do read -rsp "Enter MariaDB root password: " ROOT_PASS; echo; [[ -n "$ROOT_PASS" ]] && break; done
read -rp "Enter Zabbix Admin password (frontend) [zabbix]: " ZABBIX_ADMIN_PASS
ZABBIX_ADMIN_PASS=${ZABBIX_ADMIN_PASS:-zabbix}

echo "[INFO] Config summary:"
echo "  DB: $DB_NAME / $DB_USER"
echo "  Zabbix IP: $ZABBIX_IP"
echo "  Frontend Admin password: $ZABBIX_ADMIN_PASS"

# Install packages 
echo "[INFO] Installing dependencies..."
apt update -y
apt install -y wget curl gnupg2 lsb-release jq apt-transport-https \
php php-mysql php-xml php-bcmath php-mbstring php-ldap php-json php-gd php-zip php-curl \
mariadb-server mariadb-client rsync socat ssl-cert fping snmpd

# Add Zabbix repo 
echo "[INFO] Adding Zabbix repository..."
wget -qO /tmp/zabbix-release.deb "$REPO_URL"
dpkg -i /tmp/zabbix-release.deb
apt update -y

# Install Zabbix components 
echo "[INFO] Installing Zabbix server, frontend, and agent..."
DEBIAN_FRONTEND=noninteractive apt install -y \
    zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

# Fix agent config if missing
AGENT_CONF="/etc/zabbix/zabbix_agentd.conf"
if [[ ! -f "$AGENT_CONF" ]]; then
    echo "[WARN] zabbix_agentd.conf not found. Creating default..."
    mkdir -p /etc/zabbix
    cat > "$AGENT_CONF" <<EOF
PidFile=/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=$ZABBIX_IP
ServerActive=$ZABBIX_IP
Hostname=$(hostname)
Include=/etc/zabbix/zabbix_agentd.d/*.conf
EOF
fi
chown root:root "$AGENT_CONF"
chmod 644 "$AGENT_CONF"

# Configure MariaDB 
echo "[INFO] Configuring MariaDB..."
mysql -uroot -p"$ROOT_PASS" <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
SET GLOBAL log_bin_trust_function_creators = 1;
EOF

# Import Zabbix schema 
echo "[INFO] Importing initial Zabbix schema..."
zcat /usr/share/zabbix/sql-scripts/mysql/server.sql.gz | \
mysql --default-character-set=utf8mb4 -u"$DB_USER" -p"$DB_PASS" "$DB_NAME"

# Disable log_bin_trust_function_creators again
mysql -uroot -p"$ROOT_PASS" -e "SET GLOBAL log_bin_trust_function_creators = 0;"

# Configure Zabbix server 
sed -i "s|^# DBPassword=.*|DBPassword=$DB_PASS|" /etc/zabbix/zabbix_server.conf

# Set PHP timezone 
echo "[INFO] Setting PHP timezone..."
PHP_INI=$(php --ini | grep "Loaded Configuration" | awk -F: '{print $2}' | xargs)
if [[ -f "$PHP_INI" ]]; then
    sed -i "s|^;*date.timezone =.*|date.timezone = UTC|" "$PHP_INI"
fi

# Frontend config
echo "[INFO] Creating frontend config..."
FRONTEND_CONF="/etc/zabbix/web/zabbix.conf.php"
cat > "$FRONTEND_CONF" <<EOF
<?php
\$DB['TYPE']     = 'MYSQL';
\$DB['SERVER']   = 'localhost';
\$DB['PORT']     = '0';
\$DB['DATABASE'] = '$DB_NAME';
\$DB['USER']     = '$DB_USER';
\$DB['PASSWORD'] = '$DB_PASS';
\$ZBX_SERVER     = '$ZABBIX_IP';
\$ZBX_SERVER_PORT= '10051';
\$ZBX_SERVER_NAME= 'Zabbix Server';
\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
EOF
chown www-data:www-data "$FRONTEND_CONF"
chmod 640 "$FRONTEND_CONF"

# Enable + start services
echo "[INFO] Enabling and starting services..."
systemctl enable zabbix-server zabbix-agent apache2
systemctl restart apache2 zabbix-server zabbix-agent

# Verify agent
echo "[INFO] Checking Zabbix Agent status..."
if systemctl is-active --quiet zabbix-agent; then
    echo "[OK] Zabbix Agent running."
else
    echo "[ERROR] Zabbix Agent failed. Check: journalctl -xeu zabbix-agent"
fi

# Done
echo "[OK] Zabbix installation complete!"
echo "Access frontend at: http://$ZABBIX_IP/zabbix"
echo "Username: Admin"
echo "Password: $ZABBIX_ADMIN_PASS"
