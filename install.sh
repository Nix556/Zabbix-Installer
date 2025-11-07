#!/bin/bash
source lib/colors.sh
source lib/utils.sh
source lib/system.sh
source lib/db.sh

initialCheck

echo -e "${YELLOW}Select installation type:${NC}"
echo "1) Full Zabbix Server + Agent"
echo "2) Zabbix Agent only"
echo "3) Exit"
read -rp "Choice [1-3]: " INSTALL_CHOICE

case "$INSTALL_CHOICE" in
1)
    installDeps
    setupMariaDB
    installApachePHP
    installZabbixServer
    installZabbixAgent
    configureZabbixAPI
    ;;
2)
    installDeps
    installZabbixAgent
    ;;
3)
    exit 0
    ;;
*)
    echo -e "${RED}Invalid choice${NC}"
    exit 1
    ;;
esac

echo -e "${GREEN}Installation completed.${NC}"
