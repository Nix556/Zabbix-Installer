create_zabbix_db() {
    local db_name=$1
    local db_user=$2
    local db_pass=$3
    local root_pass=$4
    sudo mysql -uroot -p"$root_pass" -e "CREATE DATABASE IF NOT EXISTS \`$db_name\` CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
    sudo mysql -uroot -p"$root_pass" -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass';"
    sudo mysql -uroot -p"$root_pass" -e "GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'localhost'; FLUSH PRIVILEGES;"
}
