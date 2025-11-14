#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/colors.sh"
source "$SCRIPT_DIR/utils.sh"

detect_os() {
    if [[ -f /etc/debian_version ]]; then
        OS_NAME="Debian"
        OS_VERSION=$(cut -d. -f1 /etc/debian_version)
        PM="apt"
    elif [[ -f /etc/lsb-release ]]; then
        OS_NAME="Ubuntu"
        OS_VERSION=$(lsb_release -rs)
        PM="apt"
    else
        error "Unsupported OS"
        exit 1
    fi
    success "Detected OS: $OS_NAME $OS_VERSION"
}

update_system() {
    info "Updating system packages..."
    if [[ $EUID -eq 0 ]]; then
        $PM update -y
    else
        sudo $PM update -y
    fi
    success "System packages updated"
}

start_service() {
    local service=$1
    systemctl start "$service"
    systemctl enable "$service"
    success "$service started and enabled"
}

stop_service() {
    local service=$1
    systemctl stop "$service"
    success "$service stopped"
}
