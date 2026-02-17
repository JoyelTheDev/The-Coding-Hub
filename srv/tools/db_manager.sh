#!/bin/bash
# ===================== COLORS =====================
GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

print_header() { clear; echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"; echo -e "${CYAN}║      🗄️  CENTRAL DATABASE MANAGER            ║${NC}"; echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"; echo; }

create_db() {
    print_header
    read -rp "Database Name: " DB
    read -rp "Username: " USER
    read -rsp "Password: " PASS; echo
    mysql -e "CREATE DATABASE IF NOT EXISTS $DB;"
    mysql -e "CREATE USER IF NOT EXISTS '$USER'@'localhost' IDENTIFIED BY '$PASS';"
    mysql -e "GRANT ALL PRIVILEGES ON $DB.* TO '$USER'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
    echo -e "${GREEN}✅ Database Created${NC}"
    read -rp "Press Enter..."
}

list_db() {
    print_header
    echo -e "${CYAN}📋 Existing Databases:${NC}"
    mysql -e "SHOW DATABASES;"
    read -rp "Press Enter..."
}

while true; do
    print_header
    echo -e "${GREEN}1)${NC} Create New Database"
    echo -e "${GREEN}2)${NC} List Databases"
    echo -e "${GREEN}3)${NC} Repair All Tables"
    echo -e "${RED}0)${NC} Exit"
    echo
    read -rp "Select → " opt
    case $opt in
        1) create_db ;;
        2) list_db ;;
        3) mysqlcheck --all-databases --auto-repair -u root; read -rp "Press Enter..." ;;
        0) exit 0 ;;
        *) echo -e "${RED}Invalid${NC}"; sleep 1 ;;
    esac
done
