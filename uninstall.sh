#!/bin/bash
source lib/colors.sh
source lib/utils.sh
source lib/system.sh
source lib/db.sh

echo -e "${RED}This will uninstall Zabbix and remove all configurations.${NC}"
read -rp "Are you sure? [y/N]: " CONFIRM
[[ "$CONFIRM" != "y" ]] && exit 0

systemctl stop zabbix-server zabbix-agent apache2 mysql 2>/dev/null
apt-get remove --purge -y zabbix-server-mysql zabbix-frontend-php zabbix-agent apache2 mariadb-server mariadb-client
rm -rf /etc/zabbix /var/lib/mysql /var/log/zabbix /var/www/html/zabbix config/zabbix_api.conf

echo -e "${GREEN}Uninstallation complete.${NC}"
