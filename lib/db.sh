source colors.sh

create_zabbix_db() {
    local DB_NAME="$1"
    local DB_USER="$2"
    local DB_PASS="$3"
    local ROOT_PASS="$4"

    [[ -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASS" || -z "$ROOT_PASS" ]] && { error "Missing args for create_zabbix_db"; return 1; }

    info "Creating Zabbix database and user..."
    mysql -u root -p"$ROOT_PASS" -e "
    CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
    CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
    GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
    FLUSH PRIVILEGES;"
}

drop_zabbix_db() {
    local DB_NAME="$1"
    local DB_USER="$2"
    local ROOT_PASS="$3"

    [[ -z "$DB_NAME" || -z "$DB_USER" || -z "$ROOT_PASS" ]] && { error "Missing args for drop_zabbix_db"; return 1; }

    info "Dropping Zabbix database and user..."
    mysql -u root -p"$ROOT_PASS" -e "
    DROP DATABASE IF EXISTS \`$DB_NAME\`;
    DROP USER IF EXISTS '$DB_USER'@'localhost';
    FLUSH PRIVILEGES;"
}
