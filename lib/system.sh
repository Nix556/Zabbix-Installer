detect_os() {
    if [[ -f /etc/debian_version ]]; then
        OS="debian"
        VER=$(cut -d. -f1 /etc/debian_version)
        PM="apt"
    elif [[ -f /etc/lsb-release ]]; then
        OS="ubuntu"
        VER=$(lsb_release -rs)
        PM="apt"
    else
        error "Unsupported OS"
        exit 1
    fi
}

update_system() {
    sudo $PM update -y
}
