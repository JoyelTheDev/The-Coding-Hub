#!/bin/bash
source ../lib/ui.sh

real_time_dashboard() {
    trap 'echo -e "\n${COLORS[success]}Dashboard closed${COLORS[reset]}"; exit 0' INT
    
    while true; do
        clear
        animated_banner
        
        # CPU Usage
        local cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        local cpu_bar=$(printf '%0.s█' $(seq 1 $((cpu / 5))))
        echo -e "${COLORS[info]}CPU Usage:${COLORS[reset]} [$cpu_bar] ${cpu}%"
        
        # Memory Usage
        local mem=$(free | awk '/Mem/ {printf("%.1f", $3/$2 * 100)}')
        local mem_bar=$(printf '%0.s█' $(seq 1 $((mem / 5))))
        echo -e "${COLORS[info]}Memory:${COLORS[reset]}   [$mem_bar] ${mem}%"
        
        # Disk Usage
        local disk=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
        local disk_bar=$(printf '%0.s█' $(seq 1 $((disk / 5))))
        echo -e "${COLORS[info]}Disk:${COLORS[reset]}     [$disk_bar] ${disk}%"
        
        # Network
        local rx=$(cat /sys/class/net/*/statistics/rx_bytes 2>/dev/null | awk '{sum+=$1} END {print sum/1024/1024}')
        local tx=$(cat /sys/class/net/*/statistics/tx_bytes 2>/dev/null | awk '{sum+=$1} END {print sum/1024/1024}')
        echo -e "${COLORS[info]}Network:${COLORS[reset]}   ↓ ${rx}MB ↑ ${tx}MB"
        
        # Active Services
        echo -e "\n${COLORS[accent]}Active Services:${COLORS[reset]}"
        for svc in nginx mysql redis docker; do
            if systemctl is-active --quiet $svc 2>/dev/null; then
                echo -e "  ${COLORS[success]}●${COLORS[reset]} $svc"
            else
                echo -e "  ${COLORS[error]}○${COLORS[reset]} $svc"
            fi
        done
        
        # Uptime
        echo -e "\n${COLORS[info]}System Uptime:${COLORS[reset]} $(uptime -p)"
        
        echo -e "\n${COLORS[warning]}Press Ctrl+C to exit${COLORS[reset]}"
        sleep 2
    done
}

real_time_dashboard
