#!/bin/bash
source ../lib/ui.sh

quick_status() {
    clear
    boxed_message "🚀 SYSTEM STATUS REPORT" "${COLORS[primary]}"
    echo ""
    
    # Quick checks
    local checks=(
        "docker:docker --version"
        "nginx:nginx -v"
        "mysql:mysql --version"
        "php:php -v"
        "git:git --version"
    )
    
    for check in "${checks[@]}"; do
        IFS=':' read -r name cmd <<< "$check"
        if command -v $name &>/dev/null; then
            local version=$($cmd 2>&1 | head -1)
            status_indicator "success" "$name: $version"
        else
            status_indicator "error" "$name: Not installed"
        fi
    done
    
    echo ""
    boxed_message "Press Enter to continue" "${COLORS[info]}"
    read
}

quick_status
