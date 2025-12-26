#!/bin/bash

# ===================== COLORS =====================
RED="\e[31m"
C_MAIN="\e[36m"
C_SEC="\e[32m"
C_LINE="\e[90m"
NC="\e[0m"

# ===================== PAUSE =====================
pause() {
  read -rp "Press Enter to continue..."
}

# ===================== 1PANEL MENU =====================
onepanel_menu() {
  while true; do
    clear
    echo -e "${C_LINE}────────────── 1PANEL MENU ──────────────${NC}"
    echo -e "${C_MAIN} 1) Install 1Panel"
    echo -e " 2) Uninstall 1Panel"
    echo -e " 3) Exit${NC}"
    echo -e "${C_LINE}────────────────────────────────────────${NC}"
    read -rp "Select → " op

    case "$op" in
      1)
        clear
        echo -e "${C_MAIN}🚀 Installing 1Panel (Official Script)...${NC}"
        curl -fsSL https://resource.fit2cloud.com/1panel/package/quick_start.sh | bash
        echo
        echo -e "${C_SEC}✅ 1Panel Installed Successfully${NC}"
        echo -e "${C_SEC}🌐 Access: http://SERVER_IP:10086${NC}"
        pause
        ;;
      2)
        clear
        echo -e "${C_MAIN}🧹 Uninstalling 1Panel (Official)...${NC}"

        if command -v 1pctl >/dev/null 2>&1; then
          1pctl uninstall
          echo -e "${C_SEC}✅ 1Panel Uninstalled Successfully${NC}"
        else
          echo -e "${RED}❌ 1Panel is not installed or 1pctl not found${NC}"
        fi
        pause
        ;;
      3)
        clear
        exit 0
        ;;
      *)
        echo -e "${RED}Invalid Option${NC}"
        pause
        ;;
    esac
  done
}

# ===================== START =====================
onepanel_menu
