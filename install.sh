#!/bin/bash
# Full Zabbix 7.4 installer (Debian 12 / Ubuntu 22.04)

export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin
set -euo pipefail
IFS=$'\n\t'

LIB_DIR="lib"
CONFIG_DIR="config"
source "$LIB_DIR/colors.sh"
source "$LIB_DIR/utils.sh"
source "$LIB_DIR/db.sh"
source "$LIB_DIR/system.sh"

wait_spinner() {
    local pid=$!
    local delay=0.2
    local spinstr='|/-\'
    printf "Working... "
    while kill -0 $pid 2>/dev/null; do
        for i in $(seq 0 3); do
            printf "\b${spinstr:$i:1}"
            sleep $delay
        done
    done
    wait $pid
    echo -e "\b[OK]"
}

detect_os

ZABBIX_IP=$(ask "Enter Zabbix Server IP" "127.0.0.1")
DB_NAME=$(ask "Enter Zabbix DB name" "zabbix")
DB_USER=$(ask "Enter Zabbix DB user" "zabbix")
while true; do
    read -rsp "Enter Zabbix DB password: " DB_PASS; echo
    [[ -n "$DB_PASS" ]] && break
done
while true; do
    read -rsp "Enter MariaDB root password: " ROOT_PASS; echo
    [[ -n "$ROOT_PASS" ]] && break
done
ZABBIX_ADMIN_PASS=$(ask "Enter Zabbix Admin password (frontend)" "zabbix")

echo -e "${BLUE}Configuration Summary:${NC}"
echo -e "${YELLOW}DB Name:${NC} $DB_NAME"
echo -e "${YELLOW}DB User:${NC} $DB_USER"
echo -e "${YELLOW}Zabbix Server IP:${NC} $ZABBIX_IP"
echo -e "${YELLOW}Frontend Admin:${NC} $ZABBIX_ADMIN_PASS"
confirm "Proceed with installation?" || { warn "Installation cancelled"; exit 1; }

# Install prerequisites
update_system & wait_spinner
info "Installing required packages..."
apt install -y wget curl gnupg2 lsb-release jq apt-transport-https \
php php-mysql php-xml php-bcmath php-mbstring php-ldap php-json php-gd php-zip php-curl \
mariadb-server mariadb-client rsync socat ssl-cert fping snmpd apache2 & wait_spinner

# Zabbix repo
case "$OS_NAME-$OS_VERSION" in
Debian-12*) REPO_URL="https://repo.zabbix.com/zabbix/7.4/release/debian/pool/main/z/zabbix-release/zabbix-release_latest_7.4+debian12_all.deb";;
Ubuntu-22.04*) REPO_URL="https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu22.04_all.deb";;
*) error "Unsupported OS"; exit 1;;
esac

info "Adding Zabbix repository..."
wget -qO /tmp/zabbix-release.deb "$REPO_URL" & wait_spinner
dpkg -i /tmp/zabbix-release.deb & wait_spinner
apt update -y & wait_spinner

info "Installing Zabbix server, frontend, agent..."
DEBIAN_FRONTEND=noninteractive apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-agent & wait_spinner

create_zabbix_db "$DB_NAME" "$DB_USER" "$DB_PASS" "$ROOT_PASS"
info "Importing initial Zabbix schema..."
zcat /usr/share/zabbix/sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" & wait_spinner

# Configure server and agent
sed -i "s|^# DBPassword=.*|DBPassword=$DB_PASS|" /etc/zabbix/zabbix_server.conf
mkdir -p /etc/zabbix/zabbix_agentd.d
cat > /etc/zabbix/zabbix_agentd.d/agent.conf <<EOF
Server=$ZABBIX_IP
ServerActive=$ZABBIX_IP
Hostname=$(hostname)
EOF
chmod 644 /etc/zabbix/zabbix_agentd.d/agent.conf

# PHP timezone
PHP_INI=$(php --ini | grep "Loaded Configuration" | awk -F: '{print $2}' | xargs)
[[ -f "$PHP_INI" ]] && sed -i "s|^;*date.timezone =.*|date.timezone = UTC|" "$PHP_INI"

# Create frontend config
mkdir -p "$CONFIG_DIR"
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

# Enable Apache
if command -v a2enconf >/dev/null 2>&1; then
    a2enconf zabbix & wait_spinner
else
    ln -sf /etc/apache2/conf-available/zabbix.conf /etc/apache2/conf-enabled/zabbix.conf
fi
systemctl reload apache2

# Enable and start services
systemctl daemon-reload
systemctl restart zabbix-server zabbix-agent apache2 & wait_spinner
systemctl enable zabbix-server zabbix-agent apache2

# Create API config
cat > "$CONFIG_DIR/zabbix_api.conf" <<EOF
ZABBIX_URL="http://$ZABBIX_IP/zabbix"
ZABBIX_USER="Admin"
ZABBIX_PASS="$ZABBIX_ADMIN_PASS"
EOF
success "Created API config at $CONFIG_DIR/zabbix_api.conf"

# Cleanup
rm -f /tmp/zabbix-release.deb
apt autoremove -y & wait_spinner

success "Zabbix installation complete!"
echo "Access frontend at: http://$ZABBIX_IP/zabbix"
echo "Username: Admin"
echo "Password: $ZABBIX_ADMIN_PASS"
