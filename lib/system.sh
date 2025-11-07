detectOS() { source /etc/os-release; OS=$ID; VER=$VERSION_ID; }
installDeps() { detectOS; apt-get update; apt-get install -y curl jq apache2 php php-mysql mariadb-client mariadb-server }
installApachePHP() { systemctl enable apache2; systemctl start apache2; }
