#!/bin/bash
# ===================== COLORS =====================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
# ===================== FUNCTIONS =====================
print_header() { clear; echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"; echo -e "${CYAN}║      🔒 SECURITY HARDENING SUITE           ║${NC}"; echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"; echo; }
pause() { read -rp "Press Enter to continue..."; }

# Feature: SSH Hardening
harden_ssh() {
    print_header
    echo -e "${YELLOW}🔧 Configuring SSH Security...${NC}"
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    sed -i 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^Port.*/Port 2222/' /etc/ssh/sshd_config
    systemctl restart ssh
    echo -e "${GREEN}✅ SSH Hardened (Port 2222, Key Only)${NC}"
    echo -e "${RED}⚠️  DO NOT CLOSE THIS SESSION UNTIL YOU TEST NEW SSH PORT${NC}"
    pause
}

# Feature: Fail2Ban Setup
setup_fail2ban() {
    print_header
    echo -e "${YELLOW}🛡️  Installing Fail2Ban...${NC}"
    apt update && apt install -y fail2ban
    systemctl enable --now fail2ban
    echo -e "${GREEN}✅ Fail2Ban Active${NC}"
    pause
}

# Feature: UFW Firewall Preset
setup_ufw() {
    print_header
    echo -e "${YELLOW}🔥 Configuring UFW Firewall...${NC}"
    apt install -y ufw
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 2222/tcp # SSH
    ufw allow 80/tcp
    ufw allow 443/tcp
    echo "y" | ufw enable
    echo -e "${GREEN}✅ UFW Enabled (Basic Web + SSH)${NC}"
    pause
}

# ===================== MENU =====================
while true; do
    print_header
    echo -e "${GREEN}1)${NC} Harden SSH Configuration"
    echo -e "${GREEN}2)${NC} Install & Configure Fail2Ban"
    echo -e "${GREEN}3)${NC} Setup UFW Firewall"
    echo -e "${GREEN}4)${NC} Run Full Security Audit"
    echo -e "${RED}0)${NC} Exit"
    echo
    read -rp "Select → " opt
    case $opt in
        1) harden_ssh ;;
        2) setup_fail2ban ;;
        3) setup_ufw ;;
        4) bash <(curl -s https://raw.githubusercontent.com/nobita329/The-Coding-Hub/main/srv/tools/SYSTEM.sh) ;; # Reuse existing
        0) exit 0 ;;
        *) echo -e "${RED}Invalid${NC}"; sleep 1 ;;
    esac
done
