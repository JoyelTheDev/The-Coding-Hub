#!/bin/bash
# ===================== COLORS =====================
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
BACKUP_DIR="/root/backups"
mkdir -p "$BACKUP_DIR"

print_header() { clear; echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"; echo -e "${CYAN}║      💾 UNIVERSAL BACKUP MANAGER           ║${NC}"; echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"; echo; }

backup_panel() {
    print_header
    read -rp "Enter Panel Name (pterodactyl/jexactyl/etc): " pname
    read -rp "Enter DB Name: " dbname
    read -rp "Enter DB User: " dbuser
    TIMESTAMP=$(date +%F_%H-%M)
    FILE="${BACKUP_DIR}/${pname}_${TIMESTAMP}.sql"
    
    echo -e "${CYAN}📦 Dumping Database...${NC}"
    mysqldump -u "$dbuser" -p "$dbname" > "$FILE"
    echo -e "${GREEN}✅ Backup Saved: $FILE${NC}"
    pause
}

backup_vm() {
    print_header
    echo -e "${CYAN}📦 Backing up VM Configs...${NC}"
    tar -czf "${BACKUP_DIR}/vms_config_$(date +%F).tar.gz" -C $HOME vms 2>/dev/null
    echo -e "${GREEN}✅ VM Configs Backed Up${NC}"
    pause
}

cleanup_old() {
    print_header
    echo -e "${YELLOW}🧹 Removing backups older than 7 days...${NC}"
    find "$BACKUP_DIR" -type f -mtime +7 -delete
    echo -e "${GREEN}✅ Cleanup Complete${NC}"
    pause
}

while true; do
    print_header
    echo -e "${GREEN}1)${NC} Backup Panel Database"
    echo -e "${GREEN}2)${NC} Backup VM Configs"
    echo -e "${GREEN}3)${NC} Cleanup Old Backups"
    echo -e "${RED}0)${NC} Exit"
    echo
    read -rp "Select → " opt
    case $opt in
        1) backup_panel ;;
        2) backup_vm ;;
        3) cleanup_old ;;
        0) exit 0 ;;
        *) echo -e "${RED}Invalid${NC}"; sleep 1 ;;
    esac
done
