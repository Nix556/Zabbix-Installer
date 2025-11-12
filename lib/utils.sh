#!/bin/bash

ask() {
    local prompt="$1"
    local default="$2"
    read -rp "$prompt" input
    echo "${input:-$default}"
}

confirm() {
    read -rp "$1 [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

check_command() {
    command -v "$1" >/dev/null 2>&1 || { error "Command $1 not found."; exit 1; }
}
