#!/bin/bash
# Zabbix API management tool

CONFIG_FILE="config/zabbix_api.conf"
LIB_DIR="lib"
source "$LIB_DIR/colors.sh"
source "$LIB_DIR/utils.sh"

[[ ! -f $CONFIG_FILE ]] && { error "API config not found! Run install.sh first."; exit 1; }
source "$CONFIG_FILE"

API_LOGIN=$(curl -s -X POST -H 'Content-Type: application/json-rpc' \
    -d "{\"jsonrpc\":\"2.0\",\"method\":\"user.login\",\"params\":{\"user\":\"$ZABBIX_USER\",\"password\":\"$ZABBIX_PASS\"},\"id\":1}" \
    "$ZABBIX_URL/api_jsonrpc.php" | jq -r '.result')

# Spinner wrapper
show_spinner() { local pid=$1; local msg=$2; ...; }

# Interactive prompts & validation
prompt_interfaces() { ... }
prompt_templates() { ... }
add_host() { ... }  # interactive/CLI with JSON validation, IP, port, template IDs, summary
remove_host() { ... }  # interactive/CLI confirmation
list_hosts() { curl -s ... | jq; }

case "$1" in
    list-hosts) list_hosts ;;
    add-host) shift; add_host "$@" ;;
    remove-host) shift; remove_host "$@" ;;
    *) echo "Usage: $0 {list-hosts|add-host|remove-host}" ;;
esac
