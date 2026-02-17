#!/bin/bash
# ===================== COLORS =====================
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

print_header() { clear; echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"; echo -e "${CYAN}║      🌐 AUTO SSL (LET'S ENCRYPT)           ║${NC}"; echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"; echo; }

install_ssl() {
    print_header
    read -rp "Enter Domain (panel.example.com): " DOMAIN
    echo -e "${YELLOW}📦 Installing Certbot...${NC}"
    apt update && apt install -y certbot python3-certbot-nginx
    
    echo -e "${YELLOW}🔐 Requesting Certificate...${NC}"
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email admin@"${DOMAIN#*.}"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ SSL Installed Successfully${NC}"
        echo -e "${CYAN}🔄 Auto-renewal enabled${NC}"
    else
        echo -e "${RED}❌ Failed. Check DNS settings.${NC}"
    fi
    read -rp "Press Enter..."
}

force_renew() {
    print_header
    echo -e "${YELLOW}🔄 Force Renewing All Certs...${NC}"
    certbot renew --force-renewal
    read -rp "Press Enter..."
}

while true; do
    print_header
    echo -e "${GREEN}1)${NC} Install SSL on Domain"
    echo -e "${GREEN}2)${NC} Force Renew Certs"
    echo -e "${RED}0)${NC} Exit"
    echo
    read -rp "Select → " opt
    case $opt in
        1) install_ssl ;;
        2) force_renew ;;
        0) exit 0 ;;
        *) echo -e "${RED}Invalid${NC}"; sleep 1 ;;
    esac
done
