#!/bin/bash
set -e

# ========= COLORS =========
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; N='\033[0m'

pause(){ read -p "Press Enter to continue..."; }

# ========= AUTO DETECT SYSTEM =========
AUTO_CPU=$(nproc)
AUTO_RAM=$(free -m | awk '/^Mem:/ {print int($2/2)}')
AUTO_DISK=$(df -BG / | awk 'NR==2 {print $4}')

# ========= VIRT DETECT =========
VIRT_TYPE="unknown"
if command -v systemd-detect-virt >/dev/null 2>&1; then
    DETECTED=$(systemd-detect-virt)
    echo "════════════════════════════════"
    echo "Virtualization Detect"
    echo "Detected: $DETECTED"
    echo "════════════════════════════════"
    read -p "Use this virtualization info? (Y/n): " vch
    vch=${vch:-Y}
    [[ "$vch" =~ ^[Yy]$ ]] && VIRT_TYPE="$DETECTED"
fi

# ========= HEADER =========
header(){
clear
echo -e "${C}════════════════════════════════════════════"
echo "        DOCKER MANAGER (AUTO)"
echo -e "════════════════════════════════════════════${N}"
echo -e "${Y}AUTO-DETECT STATUS${N}"
echo -e "CPU   : ${G}${AUTO_CPU} Cores${N}"
echo -e "RAM   : ${G}${AUTO_RAM} MB (50%)${N}"
echo -e "DISK  : ${G}${AUTO_DISK} Free${N}"
echo -e "VIRT  : ${G}${VIRT_TYPE}${N}"
echo -e "${C}════════════════════════════════════════════${N}"
}

# ========= AUTO INSTALL DOCKER =========
auto_install(){
header
echo -e "${Y}Installing Docker...${N}"

sudo apt update
sudo apt install -y ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
 | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo $VERSION_CODENAME) stable" \
| sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker $USER

echo -e "${G}Docker installed ✔${N}"
echo -e "${Y}Logout/Login recommended once${N}"
pause
}

# ========= CHECK =========
command -v docker >/dev/null 2>&1 || auto_install

# ========= CREATE CONTAINER =========
create_container(){
header
read -p "Container name: " name
[[ -z "$name" ]] && { echo "Name required"; pause; return; }

echo "1) Ubuntu 22.04"
echo "2) Ubuntu 24.04"
echo "3) Debian 11"
echo "4) Debian 12"
echo "5) Debian 13"
echo "6) AlmaLinux 9"
echo "7) Rocky Linux 9"
echo "8) CentOS Stream 9"
echo "9) Fedora 40"
read -p "Select OS: " os

case $os in
1) img="ubuntu:22.04" ;;
2) img="ubuntu:24.04" ;;
3) img="debian:11" ;;
4) img="debian:12" ;;
5) img="debian:13" ;;
6) img="almalinux:9" ;;
7) img="rockylinux:9" ;;
8) img="centos:stream9" ;;
9) img="fedora:40" ;;
*) echo "Invalid selection"; pause; return ;;
esac

read -p "CPU cores (Enter=auto): " cpu
read -p "RAM MB (Enter=auto): " ram
read -p "Port map (e.g. 8080:80, blank=none): " port

cpu=${cpu:-$AUTO_CPU}
ram=${ram:-$AUTO_RAM}

echo -e "${Y}Image:${N} $img"
echo -e "${Y}CPU:${N} $cpu | ${Y}RAM:${N} ${ram}MB"

cmd="docker run -dit --name $name --cpus=$cpu --memory=${ram}m"
[[ -n "$port" ]] && cmd="$cmd -p $port"
cmd="$cmd $img"

echo -e "${C}Running:${N} $cmd"
eval "$cmd"

echo -e "${G}Container '$name' created ✔${N}"
pause
}

# ========= MANAGE =========
manage_container(){
header
docker ps -a
echo
read -p "Container name: " name

while true; do
header
status=$(docker inspect -f '{{.State.Status}}' "$name" 2>/dev/null || echo "not-found")
echo -e "${Y}$name${N} | ${G}$status${N}"

echo "1) Start"
echo "2) Stop"
echo "3) Restart"
echo "4) Shell"
echo "5) Logs"
echo "6) Delete"
echo "0) Back"
read -p "Select: " c

case $c in
1) docker start "$name" ;;
2) docker stop "$name" ;;
3) docker restart "$name" ;;
4) docker exec -it "$name" bash ;;
5) docker logs --tail 50 "$name"; pause ;;
6) read -p "Confirm delete (y/N): " x
   [[ $x =~ ^[Yy]$ ]] && docker rm -f "$name" && return ;;
0) return ;;
*) ;;
esac
done
}

# ========= MENU =========
while true; do
header
echo "1) Auto Install Docker"
echo "2) Create Container"
echo "3) List Containers"
echo "4) Manage Container"
echo "0) Exit"
read -p "Select: " m

case $m in
1) auto_install ;;
2) create_container ;;
3) docker ps -a; pause ;;
4) manage_container ;;
0) exit ;;
*) ;;
esac
done
