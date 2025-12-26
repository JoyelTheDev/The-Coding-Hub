# ===================== INFRA MENU =====================
infra_menu(){
while true; do banner
echo -e "${C_LINE}────────────── INFRA MENU ──────────────${NC}"
echo -e "${C_MAIN} 1) KVM + Cockpit"
echo -e " 2) CasaOS"
echo -e " 3) 1Panel"
echo -e " 4) Back${NC}"
echo -e "${C_LINE}────────────────────────────────────────${NC}"
read -p "Select → " im

case $im in
1)
  clear
  echo -e "${C_MAIN}Installing KVM + Cockpit...${NC}"
  apt update
  apt install -y cockpit cockpit-machines qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
  systemctl enable --now cockpit.socket libvirtd
  echo -e "${C_SEC}Access: https://SERVER_IP:9090${NC}"
  pause
;;
2)
  clear
  echo -e "${C_MAIN}Installing CasaOS...${NC}"
  curl -fsSL https://get.casaos.io | bash
  pause
;;
3)
  clear
  echo -e "${C_MAIN}Installing 1Panel...${NC}"
  curl -fsSL https://resource.fit2cloud.com/1panel/package/quick_start.sh | bash
  pause
;;
4)
  break
;;
*)
  echo -e "${RED}Invalid Option${NC}"
  pause
;;
esac
done
}
