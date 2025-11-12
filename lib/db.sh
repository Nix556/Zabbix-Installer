#!/bin/bash

create_zabbix_db() {
    local db_name="$1"
    local db_user="$2"
    local db_pass="$3"
    local root_pass="$4"

    info "Creating MariaDB database $db_name and user $db_user..."
    mysql -uroot -p"$root_pass" <<EOF
CREATE DATABASE IF NOT EXISTS $db_name CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass';
GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';
FLUSH PRIVILEGES;
EOF
    success "Database $db_name created."
}
