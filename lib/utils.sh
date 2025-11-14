ask() { 
    local prompt=$1
    local default=$2
    read -rp "$prompt [$default]: " answer
    echo "${answer:-$default}"
}

confirm() {
    read -rp "$1 [y/N]: " ans
    [[ $ans =~ ^[Yy]$ ]]
}

validate_ip() {
    local ip=$1
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        for i in $(echo $ip | tr '.' ' '); do
            (( i >= 0 && i <= 255 )) || return 1
        done
        return 0
    else
        return 1
    fi
}

validate_port() {
    [[ "$1" =~ ^[0-9]+$ ]] && (( $1 >= 1 && $1 <= 65535 ))
}

show_spinner() {
    local pid=$1
    local msg=$2
    local delay=0.1
    local spinstr='|/-\'
    echo -n "$msg "
    while kill -0 $pid 2>/dev/null; do
        for i in $(seq 0 3); do
            printf "\b${spinstr:$i:1}"
            sleep $delay
        done
    done
    wait $pid
    echo -e "\b[OK] $msg"
}
