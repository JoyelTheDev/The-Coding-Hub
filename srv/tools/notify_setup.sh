#!/bin/bash
# ===================== COLORS =====================
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
CONFIG_FILE="/root/.notify_config"

print_header() { clear; echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"; echo -e "${CYAN}║      📡 NOTIFICATION BOT SETUP             ║${NC}"; echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"; echo; }

setup_discord() {
    print_header
    read -rp "Enter Discord Webhook URL: " WEBHOOK
    echo "WEBHOOK=$WEBHOOK" > "$CONFIG_FILE"
    echo -e "${GREEN}✅ Discord Webhook Saved${NC}"
    
    # Test Message
    curl -X POST -H "Content-Type: application/json" -d "{\"content\":\"🚀 The-Coding-Hub Bot Connected!\"}" "$WEBHOOK"
    echo -e "${CYAN}📩 Test message sent${NC}"
    read -rp "Press Enter..."
}

send_alert() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        MESSAGE="⚠️ Alert from $(hostname): $1"
        curl -X POST -H "Content-Type: application/json" -d "{\"content\":\"$MESSAGE\"}" "$WEBHOOK" > /dev/null
    fi
}

while true; do
    print_header
    echo -e "${GREEN}1)${NC} Setup Discord Webhook"
    echo -e "${GREEN}2)${NC} Send Test Alert"
    echo -e "${RED}0)${NC} Exit"
    echo
    read -rp "Select → " opt
    case $opt in
        1) setup_discord ;;
        2) send_alert "Test Alert" ;;
        0) exit 0 ;;
        *) echo -e "${RED}Invalid${NC}"; sleep 1 ;;
    esac
done
