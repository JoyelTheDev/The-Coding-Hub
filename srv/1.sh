#!/bin/bash

# =================================================================
# VPS EDIT MENU v3.0 — AUTO-DETECT SMART VERSION
# Detects: OS, package manager, services, architecture, virtualization
# Automatically adapts commands for your specific system
# =================================================================

# ----------
# CONFIG & AUTO-DETECTION
# ----------
VERSION="3.0"
LOG_FILE="/var/log/vps-edit-menu.log"
BACKUP_DIR="/root/vps-backups"

# Auto-detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="$ID"
        OS_VERSION="$VERSION_ID"
        OS_PRETTY="$PRETTY_NAME"
    elif [ -f /etc/redhat-release ]; then
        OS_NAME="rhel"
        OS_PRETTY=$(cat /etc/redhat-release)
    elif [ -f /etc/debian_version ]; then
        OS_NAME="debian"
        OS_PRETTY="Debian $(cat /etc/debian_version)"
    else
        OS_NAME="unknown"
        OS_PRETTY="Unknown OS"
    fi
    echo "$OS_NAME"
}

# Auto-detect package manager
detect_pkg_mgr() {
    if command -v apt-get &> /dev/null; then
        PKG_MGR="apt"
        UPDATE_CMD="apt-get update"
        INSTALL_CMD="apt-get install -y"
        REMOVE_CMD="apt-get remove -y"
    elif command -v yum &> /dev/null; then
        PKG_MGR="yum"
        UPDATE_CMD="yum check-update"
        INSTALL_CMD="yum install -y"
        REMOVE_CMD="yum remove -y"
    elif command -v dnf &> /dev/null; then
        PKG_MGR="dnf"
        UPDATE_CMD="dnf check-update"
        INSTALL_CMD="dnf install -y"
        REMOVE_CMD="dnf remove -y"
    elif command -v pacman &> /dev/null; then
        PKG_MGR="pacman"
        UPDATE_CMD="pacman -Sy"
        INSTALL_CMD="pacman -S --noconfirm"
        REMOVE_CMD="pacman -R --noconfirm"
    elif command -v apk &> /dev/null; then
        PKG_MGR="apk"
        UPDATE_CMD="apk update"
        INSTALL_CMD="apk add"
        REMOVE_CMD="apk del"
    else
        PKG_MGR="unknown"
    fi
    echo "$PKG_MGR"
}

# Auto-detect init system
detect_init() {
    if [ -d /run/systemd/system ]; then
        INIT="systemd"
        SERVICE_CMD="systemctl"
    elif [ -f /sbin/initctl ]; then
        INIT="upstart"
        SERVICE_CMD="initctl"
    elif [ -f /sbin/rc-service ]; then
        INIT="openrc"
        SERVICE_CMD="rc-service"
    else
        INIT="sysv"
        SERVICE_CMD="service"
    fi
    echo "$INIT"
}

# Auto-detect virtualization
detect_virtualization() {
    if command -v systemd-detect-virt &> /dev/null; then
        VIRT=$(systemd-detect-virt 2>/dev/null)
    elif [ -f /proc/cpuinfo ] && grep -q "hypervisor" /proc/cpuinfo; then
        VIRT="kvm"
    elif [ -d /proc/vz ]; then
        VIRT="openvz"
    elif [ -f /.dockerenv ]; then
        VIRT="docker"
    else
        VIRT="baremetal"
    fi
    echo "$VIRT"
}

# Auto-detect network manager
detect_network_mgr() {
    if command -v nmcli &> /dev/null && systemctl is-active NetworkManager &> /dev/null; then
        NET_MGR="NetworkManager"
    elif command -v netplan &> /dev/null; then
        NET_MGR="netplan"
    elif [ -f /etc/network/interfaces ]; then
        NET_MGR="ifupdown"
    elif command -v wicked &> /dev/null; then
        NET_MGR="wicked"
    else
        NET_MGR="unknown"
    fi
    echo "$NET_MGR"
}

# Auto-detect firewall
detect_firewall() {
    if command -v ufw &> /dev/null && ufw status | grep -q "active"; then
        FIREWALL="ufw"
    elif command -v firewall-cmd &> /dev/null; then
        FIREWALL="firewalld"
    elif command -v iptables &> /dev/null; then
        FIREWALL="iptables"
    elif command -v nft &> /dev/null; then
        FIREWALL="nftables"
    else
        FIREWALL="none"
    fi
    echo "$FIREWALL"
}

# Run detection
OS=$(detect_os)
PKG_MGR=$(detect_pkg_mgr)
INIT=$(detect_init)
VIRT=$(detect_virtualization)
NET_MGR=$(detect_network_mgr)
FIREWALL=$(detect_firewall)
ARCH=$(uname -m)
KERNEL=$(uname -r)

# Colors
RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
BLUE='\033[0;94m'
MAGENTA='\033[0;95m'
CYAN='\033[0;96m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

# ----------
# SMART INSTALL FUNCTION
# ----------
smart_install() {
    local pkg="$1"
    echo -e "${CYAN}Installing $pkg using $PKG_MGR...${NC}"
    
    case $PKG_MGR in
        apt) apt-get update && apt-get install -y "$pkg" ;;
        yum) yum install -y "$pkg" ;;
        dnf) dnf install -y "$pkg" ;;
        pacman) pacman -S --noconfirm "$pkg" ;;
        apk) apk add "$pkg" ;;
        *) echo -e "${RED}Cannot install (unknown package manager)${NC}" ;;
    esac
}

# ----------
# SMART SERVICE FUNCTION
# ----------
smart_service() {
    local service="$1"
    local action="$2"
    
    case $INIT in
        systemd)
            case $action in
                start) systemctl start "$service" ;;
                stop) systemctl stop "$service" ;;
                restart) systemctl restart "$service" ;;
                enable) systemctl enable "$service" ;;
                disable) systemctl disable "$service" ;;
                status) systemctl status "$service" --no-pager ;;
            esac
            ;;
        sysv)
            service "$service" "$action" ;;
        openrc)
            rc-service "$service" "$action" ;;
        upstart)
            initctl "$action" "$service" ;;
    esac
}

# ----------
# SMART FIREWALL FUNCTION
# ----------
smart_firewall() {
    local action="$1"
    local port="$2"
    local ip="$3"
    
    case $FIREWALL in
        ufw)
            case $action in
                allow) ufw allow "$port" ;;
                deny) ufw deny "$port" ;;
                allow_ip) ufw allow from "$ip" ;;
                deny_ip) ufw deny from "$ip" ;;
                reset) ufw --force reset ;;
                status) ufw status numbered ;;
            esac
            ;;
        firewalld)
            case $action in
                allow) firewall-cmd --add-port="$port"/tcp --permanent ;;
                deny) firewall-cmd --remove-port="$port"/tcp --permanent ;;
                allow_ip) firewall-cmd --add-source="$ip" --permanent ;;
                reload) firewall-cmd --reload ;;
                status) firewall-cmd --list-all ;;
            esac
            ;;
        iptables)
            case $action in
                allow) iptables -A INPUT -p tcp --dport "$port" -j ACCEPT ;;
                deny) iptables -A INPUT -p tcp --dport "$port" -j DROP ;;
                save) iptables-save > /etc/iptables/rules.v4 ;;
            esac
            ;;
        none)
            echo -e "${YELLOW}No firewall detected${NC}" ;;
    esac
}

# ----------
# HEADER WITH AUTO-DETECT INFO
# ----------
show_header() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║${BOLD}                VPS EDIT MENU v3.0 — SMART AUTO-DETECT                    ${NC}${CYAN}║"
    echo "║${YELLOW}         Detected: $OS | $PKG_MGR | $INIT | $VIRT                    ${NC}${CYAN}║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}OS:${NC} $OS_PRETTY ${GREEN}•${NC} ${GREEN}Kernel:${NC} $KERNEL ${GREEN}•${NC} ${GREEN}Arch:${NC} $ARCH"
    echo -e "${GREEN}Network:${NC} $NET_MGR ${GREEN}•${NC} ${GREEN}Firewall:${NC} $FIREWALL ${GREEN}•${NC} ${GREEN}Virtual:${NC} $VIRT"
    echo -e "${GREEN}Host:${NC} $(hostname) ${GREEN}•${NC} ${GREEN}IP:${NC} $(hostname -I 2>/dev/null | awk '{print $1}')"
    echo -e "${GREEN}Uptime:${NC} $(uptime -p | sed 's/up //') ${GREEN}•${NC} ${GREEN}Load:${NC} $(uptime | awk -F'load average:' '{print $2}')"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ----------
# AUTO-DETECTED SYSTEM / IDENTITY
# ----------
system_identity_menu() {
    while true; do
        show_header
        echo -e "${BOLD}${MAGENTA}🔧 SYSTEM / IDENTITY [Auto-Detected: $OS]${NC}"
        echo ""
        
        # Auto-detect current values
        CURRENT_HOSTNAME=$(hostname)
        CURRENT_TIMEZONE=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "Unknown")
        CURRENT_LOCALE=$(locale | grep LANG= | cut -d= -f2)
        
        echo -e "${CYAN}Current:${NC} Hostname=$CURRENT_HOSTNAME | Timezone=$CURRENT_TIMEZONE | Locale=$CURRENT_LOCALE"
        echo ""
        
        echo -e "  ${GREEN}1)${NC}  Hostname change (Auto: $OS)"
        echo -e "  ${GREEN}2)${NC}  Random hostname"
        echo -e "  ${GREEN}3)${NC}  VPS tag / label"
        echo -e "  ${GREEN}4)${NC}  OS name display edit"
        echo -e "  ${GREEN}5)${NC}  MOTD / SSH banner"
        echo -e "  ${GREEN}6)${NC}  Timezone / Locale (Auto: $PKG_MGR)"
        echo -e "  ${GREEN}7)${NC}  Machine-ID reset (Auto: $INIT)"
        echo -e "  ${GREEN}8)${NC}  Auto-detect all identity"
        echo ""
        echo -e "  ${YELLOW}b)${NC}  Back to Main Menu"
        echo -e "  ${RED}0)${NC}  Exit"
        echo ""
        read -p "$(echo -e "${CYAN}Enter choice: ${NC}")" choice
        
        case $choice in
            1)
                echo -e "${CYAN}Current hostname:${NC} $CURRENT_HOSTNAME"
                read -p "New hostname: " new_host
                
                # OS-specific hostname change
                case $OS in
                    debian|ubuntu)
                        hostnamectl set-hostname "$new_host"
                        sed -i "s/127.0.1.1.*/127.0.1.1\t$new_host/g" /etc/hosts
                        ;;
                    centos|rhel|fedora)
                        hostnamectl set-hostname "$new_host"
                        sed -i "s/^HOSTNAME=.*/HOSTNAME=$new_host/" /etc/hostname
                        ;;
                    alpine)
                        echo "$new_host" > /etc/hostname
                        hostname "$new_host"
                        ;;
                    *)
                        hostnamectl set-hostname "$new_host" 2>/dev/null || \
                        echo "$new_host" > /etc/hostname
                        ;;
                esac
                echo -e "${GREEN}Hostname changed to: $new_host${NC}"
                ;;
            
            2)
                # OS-specific random naming
                case $OS in
                    ubuntu) prefix="ubuntu-" ;;
                    debian) prefix="debian-" ;;
                    centos) prefix="centos-" ;;
                    fedora) prefix="fedora-" ;;
                    alpine) prefix="alpine-" ;;
                    *) prefix="vps-" ;;
                esac
                random_name="${prefix}$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)"
                hostnamectl set-hostname "$random_name"
                echo -e "${GREEN}Random hostname set: $random_name${NC}"
                ;;
            
            6)
                # Auto-detect timezone tools
                if command -v timedatectl &> /dev/null; then
                    echo -e "${CYAN}Current timezone:${NC}"
                    timedatectl
                    read -p "New timezone (e.g., Asia/Kolkata): " tz
                    timedatectl set-timezone "$tz"
                elif [ -f /etc/localtime ]; then
                    echo -e "${YELLOW}Setting timezone manually...${NC}"
                    rm -f /etc/localtime
                    ln -sf "/usr/share/zoneinfo/$tz" /etc/localtime
                fi
                
                # Locale settings
                if command -v locale-gen &> /dev/null; then
                    locale-gen en_US.UTF-8
                    update-locale LANG=en_US.UTF-8
                fi
                echo -e "${GREEN}Timezone and locale updated${NC}"
                ;;
            
            7)
                # Init-specific machine-id reset
                case $INIT in
                    systemd)
                        rm -f /etc/machine-id /var/lib/dbus/machine-id
                        systemd-machine-id-setup
                        ;;
                    *)
                        echo -e "${YELLOW}Machine-ID reset only works with systemd${NC}"
                        ;;
                esac
                ;;
            
            8)
                echo -e "${CYAN}=== AUTO-DETECTED IDENTITY ===${NC}"
                echo -e "Hostname: $(hostname)"
                echo -e "FQDN: $(hostname -f 2>/dev/null || echo "N/A")"
                echo -e "Domain: $(hostname -d 2>/dev/null || echo "N/A")"
                echo -e "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')"
                echo -e "Kernel: $(uname -r) ($(uname -v | cut -d' ' -f1-3))"
                echo -e "Architecture: $(uname -m)"
                echo -e "Timezone: $(date +%Z) ($(date +%z))"
                echo -e "Locale: $(locale | grep LANG= | cut -d= -f2)"
                echo -e "Charset: $(locale charmap)"
                ;;
            
            b|B) break ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid choice!${NC}" ;;
        esac
        echo ""
        read -p "Press Enter to continue..."
    done
}

# ----------
# AUTO-DETECTED SSH CONTROLS
# ----------
ssh_controls_menu() {
    while true; do
        show_header
        echo -e "${BOLD}${MAGENTA}🔐 SSH CONTROLS [Auto-Detected: $INIT]${NC}"
        echo ""
        
        # Auto-detect SSH config
        SSH_CONFIG="/etc/ssh/sshd_config"
        if [ ! -f "$SSH_CONFIG" ]; then
            # Find SSH config
            if [ -f /etc/sshd_config ]; then
                SSH_CONFIG="/etc/sshd_config"
            elif [ -f /etc/ssh/ssh_config ]; then
                SSH_CONFIG="/etc/ssh/ssh_config"
            fi
        fi
        
        echo -e "${CYAN}SSH Config:${NC} $SSH_CONFIG"
        echo -e "${CYAN}SSH Service:${NC} $(smart_service ssh status 2>/dev/null | head -1)"
        echo ""
        
        echo -e "  ${GREEN}1)${NC}  Auto-detect SSH status"
        echo -e "  ${GREEN}2)${NC}  Smart SSH port change"
        echo -e "  ${GREEN}3)${NC}  Auto-toggle root login"
        echo -e "  ${GREEN}4)${NC}  Auto-toggle password auth"
        echo -e "  ${GREEN}5)${NC}  Smart SSH service restart"
        echo -e "  ${GREEN}6)${NC}  Auto-generate SSH keys"
        echo -e "  ${GREEN}7)${NC}  Auto-backup SSH config"
        echo ""
        echo -e "  ${YELLOW}b)${NC}  Back to Main Menu"
        echo -e "  ${RED}0)${NC}  Exit"
        echo ""
        read -p "$(echo -e "${CYAN}Enter choice: ${NC}")" choice
        
        case $choice in
            1)
                echo -e "${CYAN}=== SSH AUTO-DETECT ===${NC}"
                echo -e "SSH Config: $SSH_CONFIG"
                echo -e "SSH Port: $(grep -i "^Port" "$SSH_CONFIG" 2>/dev/null | awk '{print $2}' | head -1 || echo "22 (default)")"
                echo -e "Root Login: $(grep -i "^PermitRootLogin" "$SSH_CONFIG" 2>/dev/null | tail -1 || echo "Not set")"
                echo -e "Password Auth: $(grep -i "^PasswordAuthentication" "$SSH_CONFIG" 2>/dev/null | tail -1 || echo "Not set")"
                echo -e "SSH Service: $(smart_service ssh status 2>/dev/null | grep "Active:" | cut -d: -f2)"
                echo -e "SSH Version: $(ssh -V 2>&1 | head -1)"
                echo -e "Active Connections: $(ss -tn | grep :22 | wc -l)"
                ;;
            
            2)
                current_port=$(grep -i "^Port" "$SSH_CONFIG" 2>/dev/null | awk '{print $2}' | head -1)
                echo -e "${CYAN}Current SSH port:${NC} ${current_port:-22}"
                read -p "New SSH port: " new_port
                
                # Backup
                cp "$SSH_CONFIG" "$SSH_CONFIG.backup.$(date +%s)"
                
                # Update config
                if grep -q "^Port" "$SSH_CONFIG"; then
                    sed -i "s/^Port.*/Port $new_port/" "$SSH_CONFIG"
                else
                    echo "Port $new_port" >> "$SSH_CONFIG"
                fi
                
                # Update firewall automatically
                smart_firewall allow "$new_port"
                
                echo -e "${GREEN}SSH port changed to $new_port${NC}"
                echo -e "${YELLOW}Restarting SSH service...${NC}"
                smart_service ssh restart
                ;;
            
            3)
                current=$(grep -i "^PermitRootLogin" "$SSH_CONFIG" 2>/dev/null | tail -1)
                echo -e "${CYAN}Current:${NC} $current"
                
                if [[ "$current" == *"yes"* ]] || [[ "$current" == *"prohibit-password"* ]] || [[ "$current" == *"without-password"* ]]; then
                    echo -e "${GREEN}Disabling root login...${NC}"
                    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
                    new_status="no"
                else
                    echo -e "${GREEN}Enabling root login...${NC}"
                    sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' "$SSH_CONFIG"
                    new_status="yes"
                fi
                
                smart_service ssh restart
                echo -e "${GREEN}Root login set to: $new_status${NC}"
                ;;
            
            5)
                echo -e "${CYAN}Restarting SSH service ($INIT)...${NC}"
                smart_service ssh restart
                echo -e "${GREEN}SSH service restarted${NC}"
                ;;
            
            6)
                echo -e "${CYAN}Generating SSH keys...${NC}"
                if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
                    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
                fi
                if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
                    ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
                fi
                echo -e "${GREEN}SSH keys generated${NC}"
                ;;
            
            b|B) break ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid choice!${NC}" ;;
        esac
        echo ""
        read -p "Press Enter to continue..."
    done
}

# ----------
# AUTO-DETECTED SECURITY
# ----------
security_menu() {
    while true; do
        show_header
        echo -e "${BOLD}${MAGENTA}🛡️  SECURITY [Auto-Detected: $FIREWALL]${NC}"
        echo ""
        
        echo -e "  ${GREEN}1)${NC}  Auto-install & configure Fail2Ban"
        echo -e "  ${GREEN}2)${NC}  Smart firewall rules (Auto: $FIREWALL)"
        echo -e "  ${GREEN}3)${NC}  Auto-security audit"
        echo -e "  ${GREEN}4)${NC}  Auto-update system ($PKG_MGR)"
        echo -e "  ${GREEN}5)${NC}  Auto-scan for malware"
        echo -e "  ${GREEN}6)${NC}  Auto-check for rootkits"
        echo -e "  ${GREEN}7)${NC}  Auto-harden system ($OS)"
        echo -e "  ${GREEN}8)${NC}  Security status report"
        echo ""
        echo -e "  ${YELLOW}b)${NC}  Back to Main Menu"
        echo -e "  ${RED}0)${NC}  Exit"
        echo ""
        read -p "$(echo -e "${CYAN}Enter choice: ${NC}")" choice
        
        case $choice in
            1)
                echo -e "${CYAN}Installing Fail2Ban for $OS...${NC}"
                smart_install fail2ban
                
                # OS-specific config
                case $OS in
                    ubuntu|debian)
                        cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
                        ;;
                    centos|rhel|fedora)
                        cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
                        ;;
                esac
                
                smart_service fail2ban restart
                smart_service fail2ban enable
                echo -e "${GREEN}Fail2Ban installed and configured${NC}"
                ;;
            
            2)
                echo -e "${CYAN}Smart firewall configuration for $FIREWALL${NC}"
                echo -e "1) Allow SSH port"
                echo -e "2) Allow HTTP/HTTPS"
                echo -e "3) Allow custom port"
                echo -e "4) Block IP"
                echo -e "5) View rules"
                read -p "Choice: " fw_choice
                
                case $fw_choice in
                    1)
                        ssh_port=$(grep -i "^Port" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | head -1)
                        ssh_port=${ssh_port:-22}
                        smart_firewall allow "$ssh_port"
                        echo -e "${GREEN}Allowed SSH port $ssh_port${NC}"
                        ;;
                    2)
                        smart_firewall allow "80"
                        smart_firewall allow "443"
                        echo -e "${GREEN}Allowed HTTP/HTTPS${NC}"
                        ;;
                    3)
                        read -p "Port to allow: " port
                        smart_firewall allow "$port"
                        ;;
                    4)
                        read -p "IP to block: " ip
                        smart_firewall deny_ip "$ip"
                        ;;
                    5)
                        smart_firewall status
                        ;;
                esac
                ;;
            
            4)
                echo -e "${CYAN}Updating system using $PKG_MGR...${NC}"
                case $PKG_MGR in
                    apt)
                        apt-get update && apt-get upgrade -y
                        ;;
                    yum|dnf)
                        $PKG_MGR update -y
                        ;;
                    pacman)
                        pacman -Syu --noconfirm
                        ;;
                    apk)
                        apk update && apk upgrade
                        ;;
                esac
                echo -e "${GREEN}System updated${NC}"
                ;;
            
            5)
                echo -e "${CYAN}Scanning for malware...${NC}"
                # Try to install clamav if not present
                if ! command -v clamscan &> /dev/null; then
                    smart_install clamav
                fi
                
                if command -v clamscan &> /dev/null; then
                    clamscan --recursive --infected /home /etc /tmp 2>/dev/null | head -20
                else
                    echo -e "${YELLOW}Using basic malware scan...${NC}"
                    find /home /tmp /var/tmp -type f \( -name "*.php" -o -name "*.js" \) -exec grep -l "base64_decode\|eval\|shell_exec\|wget\|curl" {} \; 2>/dev/null | head -10
                fi
                ;;
            
            7)
                echo -e "${CYAN}Auto-hardening $OS system...${NC}"
                
                # Common hardening steps
                echo -e "${YELLOW}1. Disabling unnecessary services...${NC}"
                for service in cups bluetooth avahi-daemon; do
                    smart_service "$service" stop 2>/dev/null
                    smart_service "$service" disable 2>/dev/null
                done
                
                echo -e "${YELLOW}2. Securing shared memory...${NC}"
                echo "tmpfs /dev/shm tmpfs defaults,noexec,nosuid 0 0" >> /etc/fstab
                
                echo -e "${YELLOW}3. Setting kernel parameters...${NC}"
                cat >> /etc/sysctl.conf << EOF
# Security hardening
net.ipv4.tcp_syncookies = 1
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
kernel.core_uses_pid = 1
EOF
                sysctl -p
                
                echo -e "${GREEN}System hardened${NC}"
                ;;
            
            8)
                echo -e "${CYAN}=== SECURITY STATUS REPORT ===${NC}"
                echo -e "Firewall: $FIREWALL ($(smart_firewall status 2>/dev/null | head -1))"
                echo -e "Fail2Ban: $(systemctl is-active fail2ban 2>/dev/null && echo "Active" || echo "Inactive")"
                echo -e "SSH Root Login: $(grep -i "^PermitRootLogin" /etc/ssh/sshd_config 2>/dev/null | tail -1)"
                echo -e "Open Ports: $(ss -tuln | grep LISTEN | wc -l)"
                echo -e "SELinux: $(getenforce 2>/dev/null || echo "Not installed")"
                echo -e "AppArmor: $(aa-status 2>/dev/null | head -1 || echo "Not installed")"
                echo -e "Last Update: $(stat -c %y /var/lib/$PKG_MGR/lock 2>/dev/null | cut -d' ' -f1 || echo "Unknown")"
                ;;
            
            b|B) break ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid choice!${NC}" ;;
        esac
        echo ""
        read -p "Press Enter to continue..."
    done
}

# ----------
# AUTO-DETECTED NETWORK
# ----------
network_menu() {
    while true; do
        show_header
        echo -e "${BOLD}${MAGENTA}🌐 NETWORK [Auto-Detected: $NET_MGR]${NC}"
        echo ""
        
        # Auto-detect network interface
        INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
        IP_ADDR=$(ip addr show "$INTERFACE" 2>/dev/null | grep "inet " | awk '{print $2}' | head -1)
        GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)
        DNS=$(cat /etc/resolv.conf 2>/dev/null | grep nameserver | awk '{print $2}' | head -2 | tr '\n' ', ')
        
        echo -e "${CYAN}Interface:${NC} $INTERFACE | ${CYAN}IP:${NC} $IP_ADDR"
        echo -e "${CYAN}Gateway:${NC} $GATEWAY | ${CYAN}DNS:${NC} ${DNS%, }"
        echo ""
        
        echo -e "  ${GREEN}1)${NC}  Auto-network diagnostics"
        echo -e "  ${GREEN}2)${NC}  Smart DNS configuration"
        echo -e "  ${GREEN}3)${NC}  Auto-interface management"
        echo -e "  ${GREEN}4)${NC}  Smart routing table"
        echo -e "  ${GREEN}5)${NC}  Auto-speed test"
        echo -e "  ${GREEN}6)${NC}  Network manager control ($NET_MGR)"
        echo -e "  ${GREEN}7)${NC}  Auto-port scanner"
        echo -e "  ${GREEN}8)${NC}  Comprehensive network report"
        echo ""
        echo -e "  ${YELLOW}b)${NC}  Back to Main Menu"
        echo -e "  ${RED}0)${NC}  Exit"
        echo ""
        read -p "$(echo -e "${CYAN}Enter choice: ${NC}")" choice
        
        case $choice in
            1)
                echo -e "${CYAN}=== NETWORK DIAGNOSTICS ===${NC}"
                echo -e "1. Testing connectivity..."
                ping -c 2 8.8.8.8 2>/dev/null && echo "✅ Google DNS reachable" || echo "❌ Google DNS unreachable"
                
                echo -e "\n2. Testing DNS..."
                nslookup google.com 2>/dev/null && echo "✅ DNS resolution working" || echo "❌ DNS resolution failed"
                
                echo -e "\n3. Checking open ports..."
                ss -tuln | head -10
                
                echo -e "\n4. Checking routes..."
                ip route | head -5
                
                echo -e "\n5. Checking MTU..."
                ip link show "$INTERFACE" | grep mtu
                ;;
            
            2)
                echo -e "${CYAN}Smart DNS configuration${NC}"
                echo -e "1) Cloudflare (1.1.1.1)"
                echo -e "2) Google (8.8.8.8)"
                echo -e "3) Quad9 (9.9.9.9)"
                echo -e "4) Custom"
                echo -e "5) Auto-detect fastest"
                read -p "Choice: " dns_choice
                
                case $dns_choice in
                    1) dns1="1.1.1.1"; dns2="1.0.0.1" ;;
                    2) dns1="8.8.8.8"; dns2="8.8.4.4" ;;
                    3) dns1="9.9.9.9"; dns2="149.112.112.112" ;;
                    4) read -p "Primary DNS: " dns1; read -p "Secondary DNS: " dns2 ;;
                    5)
                        echo -e "${CYAN}Testing DNS speeds...${NC}"
                        dns_servers=("1.1.1.1" "8.8.8.8" "9.9.9.9" "208.67.222.222")
                        fastest=""
                        fastest_time=999
                        
                        for server in "${dns_servers[@]}"; do
                            time=$(ping -c 1 -W 1 "$server" 2>/dev/null | grep "time=" | awk -F'time=' '{print $2}' | awk '{print $1}' | sed 's/ms//')
                            if [ -n "$time" ] && [ "$time" -lt "$fastest_time" ]; then
                                fastest_time=$time
                                fastest=$server
                            fi
                            echo -e "  $server: ${time}ms"
                        done
                        
                        echo -e "${GREEN}Fastest DNS: $fastest (${fastest_time}ms)${NC}"
                        dns1=$fastest
                        dns2="1.0.0.1"
                        ;;
                esac
                
                # Apply DNS based on network manager
                case $NET_MGR in
                    NetworkManager)
                        nmcli con mod "$INTERFACE" ipv4.dns "$dns1 $dns2"
                        nmcli con up "$INTERFACE"
                        ;;
                    netplan)
                        # Find netplan config
                        config=$(ls /etc/netplan/*.yaml 2>/dev/null | head -1)
                        if [ -f "$config" ]; then
                            sed -i "/nameservers:/,/^[^ ]/d" "$config"
                            sed -i "/version:/a\  nameservers:\n    addresses: [$dns1, $dns2]" "$config"
                            netplan apply
                        fi
                        ;;
                    *)
                        echo "nameserver $dns1" > /etc/resolv.conf
                        echo "nameserver $dns2" >> /etc/resolv.conf
                        ;;
                esac
                echo -e "${GREEN}DNS updated to $dns1, $dns2${NC}"
                ;;
            
            6)
                echo -e "${CYAN}Network Manager: $NET_MGR${NC}"
                case $NET_MGR in
                    NetworkManager)
                        echo -e "1) List connections"
                        echo -e "2) Restart NetworkManager"
                        echo -e "3) Show devices"
                        read -p "Choice: " nm_choice
                        
                        case $nm_choice in
                            1) nmcli con show ;;
                            2) smart_service NetworkManager restart ;;
                            3) nmcli device status ;;
                        esac
                        ;;
                    netplan)
                        echo -e "Netplan configs:"
                        ls /etc/netplan/*.yaml 2>/dev/null
                        echo -e "\nApply netplan: netplan apply"
                        ;;
                    *)
                        echo -e "${YELLOW}Using legacy network scripts${NC}"
                        echo -e "Interface: $INTERFACE"
                        echo -e "Config: /etc/network/interfaces"
                        ;;
                esac
                ;;
            
            8)
                echo -e "${CYAN}=== COMPREHENSIVE NETWORK REPORT ===${NC}"
                echo -e "${YELLOW}Interfaces:${NC}"
                ip addr show
                echo -e "\n${YELLOW}Routing:${NC}"
                ip route
                echo -e "\n${YELLOW}DNS:${NC}"
                cat /etc/resolv.conf 2>/dev/null
                echo -e "\n${YELLOW}Open Ports:${NC}"
                ss -tuln
                echo -e "\n${YELLOW}Connections:${NC}"
                ss -t
                echo -e "\n${YELLOW}Bandwidth (last minute):${NC}"
                if command -v iftop &> /dev/null; then
                    iftop -t -s 60 2>/dev/null | tail -20
                else
                    echo "Install iftop for bandwidth monitoring"
                fi
                ;;
            
            b|B) break ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid choice!${NC}" ;;
        esac
        echo ""
        read -p "Press Enter to continue..."
    done
}

# ----------
# AUTO-DETECTED PERFORMANCE
# ----------
performance_menu() {
    while true; do
        show_header
        echo -e "${BOLD}${MAGENTA}⚡ PERFORMANCE [Auto-Detected: $OS | $ARCH]${NC}"
        echo ""
        
        # Auto-detect CPU and RAM
        CPU_CORES=$(nproc)
        CPU_MODEL=$(lscpu 2>/dev/null | grep "Model name" | cut -d: -f2 | xargs || echo "Unknown")
        RAM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
        RAM_USED=$(free -h | grep Mem | awk '{print $3}')
        SWAP_TOTAL=$(free -h | grep Swap | awk '{print $2}')
        DISK_TOTAL=$(df -h / | tail -1 | awk '{print $2}')
        DISK_USED=$(df -h / | tail -1 | awk '{print $3}')
        
        echo -e "${CYAN}CPU:${NC} $CPU_MODEL ($CPU_CORES cores)"
        echo -e "${CYAN}RAM:${NC} $RAM_USED/$RAM_TOTAL | ${CYAN}Swap:${NC} $SWAP_TOTAL"
        echo -e "${CYAN}Disk:${NC} $DISK_USED/$DISK_TOTAL used"
        echo ""
        
        echo -e "  ${GREEN}1)${NC}  Auto-optimize performance ($OS)"
        echo -e "  ${GREEN}2)${NC}  Smart swap management"
        echo -e "  ${GREEN}3)${NC}  Auto-tune kernel parameters"
        echo -e "  ${GREEN}4)${NC}  CPU/RAM monitor"
        echo -e "  ${GREEN}5)${NC}  Disk I/O optimizations"
        echo -e "  ${GREEN}6)${NC}  Network performance tuning"
        echo -e "  ${GREEN}7)${NC}  Auto-cleanup for performance"
        echo -e "  ${GREEN}8)${NC}  Performance benchmark"
        echo ""
        echo -e "  ${YELLOW}b)${NC}  Back to Main Menu"
        echo -e "  ${RED}0)${NC}  Exit"
        echo ""
        read -p "$(echo -e "${CYAN}Enter choice: ${NC}")" choice
        
        case $choice in
            1)
                echo -e "${CYAN}Auto-optimizing $OS performance...${NC}"
                
                # Common optimizations
                echo -e "${YELLOW}1. Setting swappiness...${NC}"
                echo "vm.swappiness=10" >> /etc/sysctl.conf
                
                echo -e "${YELLOW}2. Setting dirty ratios...${NC}"
                echo "vm.dirty_ratio=40" >> /etc/sysctl.conf
                echo "vm.dirty_background_ratio=10" >> /etc/sysctl.conf
                
                echo -e "${YELLOW}3. Enabling BBR congestion control...${NC}"
                echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
                echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
                
                # OS-specific optimizations
                case $OS in
                    ubuntu|debian)
                        echo -e "${YELLOW}4. Setting CPU governor to performance...${NC}"
                        apt-get install -y cpufrequtils 2>/dev/null
                        echo 'GOVERNOR="performance"' > /etc/default/cpufrequtils
                        ;;
                    centos|rhel|fedora)
                        echo -e "${YELLOW}4. Tuning for server workload...${NC}"
                        tuned-adm profile throughput-performance
                        ;;
                esac
                
                sysctl -p
                echo -e "${GREEN}Performance optimizations applied${NC}"
                ;;
            
            2)
                echo -e "${CYAN}Smart swap management${NC}"
                
                # Check current swap
                SWAP_SIZE=$(free -h | grep Swap | awk '{print $2}')
                if [ "$SWAP_SIZE" = "0B" ] || [ "$SWAP_SIZE" = "0" ]; then
                    echo -e "${YELLOW}No swap detected. Creating swap...${NC}"
                    
                    # Calculate optimal swap size (1.5x RAM for <2GB, equal to RAM for 2-8GB, 0.75x for >8GB)
                    RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
                    RAM_GB=$((RAM_KB / 1024 / 1024))
                    
                    if [ "$RAM_GB" -lt 2 ]; then
                        SWAP_GB=$((RAM_GB * 3 / 2))
                    elif [ "$RAM_GB" -le 8 ]; then
                        SWAP_GB=$RAM_GB
                    else
                        SWAP_GB=$((RAM_GB * 3 / 4))
                    fi
                    
                    echo -e "${CYAN}Creating ${SWAP_GB}GB swap file...${NC}"
                    fallocate -l ${SWAP_GB}G /swapfile
                    chmod 600 /swapfile
                    mkswap /swapfile
                    swapon /swapfile
                    echo "/swapfile none swap sw 0 0" >> /etc/fstab
                    
                    # Optimize swappiness
                    echo "vm.swappiness=10" >> /etc/sysctl.conf
                    sysctl -p
                    
                    echo -e "${GREEN}Swap created and optimized${NC}"
                else
                    echo -e "${CYAN}Current swap: $SWAP_SIZE${NC}"
                    echo -e "1) Increase swap"
                    echo -e "2) Decrease swap"
                    echo -e "3) Remove swap"
                    read -p "Choice: " swap_choice
                    
                    case $swap_choice in
                        1)
                            read -p "Additional size (e.g., 1G): " add_size
                            swapoff /swapfile
                            fallocate -l +"$add_size" /swapfile
                            mkswap /swapfile
                            swapon /swapfile
                            ;;
                        3)
                            swapoff /swapfile
                            rm -f /swapfile
                            sed -i '/swapfile/d' /etc/fstab
                            ;;
                    esac
                fi
                ;;
            
            8)
                echo -e "${CYAN}Running performance benchmarks...${NC}"
                
                # CPU benchmark
                echo -e "${YELLOW}1. CPU Benchmark (calculating pi)...${NC}"
                time echo "scale=5000; 4*a(1)" | bc -l 2>/dev/null | tail -1 || echo "bc not installed"
                
                # Disk benchmark
                echo -e "\n${YELLOW}2. Disk Write Speed...${NC}"
                dd if=/dev/zero of=/tmp/testfile bs=1M count=1024 2>/dev/null | tail -1
                rm -f /tmp/testfile
                
                # Memory benchmark
                echo -e "\n${YELLOW}3. Memory Speed...${NC}"
                if command -v memtester &> /dev/null; then
                    memtester 100M 1 2>/dev/null | tail -5
                else
                    echo "Install memtester for memory testing"
                fi
                
                # Network benchmark
                echo -e "\n${YELLOW}4. Network Speed (download test)...${NC}"
                curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 - --simple 2>/dev/null || \
                echo "Speed test failed"
                ;;
            
            b|B) break ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid choice!${NC}" ;;
        esac
        echo ""
        read -p "Press Enter to continue..."
    done
}

# ----------
# AUTO-DETECTED MONITORING
# ----------
monitoring_menu() {
    while true; do
        show_header
        echo -e "${BOLD}${MAGENTA}📊 MONITORING [Auto-Detected Metrics]${NC}"
        echo ""
        
        # Real-time metrics
        CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        RAM_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
        LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | xargs)
        DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}')
        UPTIME=$(uptime -p)
        PROCESSES=$(ps aux | wc -l)
        
        echo -e "${RED}CPU:${NC} ${CPU_USAGE}% | ${GREEN}RAM:${NC} ${RAM_USAGE}% | ${YELLOW}Load:${NC} $LOAD_AVG"
        echo -e "${BLUE}Disk:${NC} $DISK_USAGE | ${MAGENTA}Processes:${NC} $PROCESSES | ${CYAN}$UPTIME${NC}"
        echo ""
        
        echo -e "  ${GREEN}1)${NC}  Live system monitor"
        echo -e "  ${GREEN}2)${NC}  Auto-log analyzer"
        echo -e "  ${GREEN}3)${NC}  Real-time process viewer"
        echo -e "  ${GREEN}4)${NC}  Disk usage analyzer"
        echo -e "  ${GREEN}5)${NC}  Network traffic monitor"
        echo -e "  ${GREEN}6)${NC}  Auto-alert setup"
        echo -e "  ${GREEN}7)${NC}  Historical data viewer"
        echo -e "  ${GREEN}8)${NC}  Comprehensive health report"
        echo ""
        echo -e "  ${YELLOW}b)${NC}  Back to Main Menu"
        echo -e "  ${RED}0)${NC}  Exit"
        echo ""
        read -p "$(echo -e "${CYAN}Enter choice: ${NC}")" choice
        
        case $choice in
            1)
                echo -e "${CYAN}Live System Monitor (Ctrl+C to exit)${NC}"
                if command -v htop &> /dev/null; then
                    htop
                else
                    watch -n 1 "echo -e 'CPU: \$(top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | cut -d'%' -f1)%'; \
                    echo -e 'RAM: \$(free -h | grep Mem | awk '{print \$3\"/\"\$2}')'; \
                    echo -e 'Disk: \$(df -h / | tail -1 | awk '{print \$5}')'; \
                    echo -e 'Load: \$(uptime | awk -F'load average:' '{print \$2}')'; \
                    echo -e 'Top processes:'; \
                    ps aux --sort=-%cpu | head -5"
                fi
                ;;
            
            4)
                echo -e "${CYAN}Disk Usage Analyzer${NC}"
                if command -v ncdu &> /dev/null; then
                    ncdu /
                else
                    echo -e "${YELLOW}Installing ncdu for disk analysis...${NC}"
                    smart_install ncdu
                    ncdu /
                fi
                ;;
            
            5)
                echo -e "${CYAN}Network Traffic Monitor${NC}"
                if command -v iftop &> /dev/null; then
                    iftop
                elif command -v nethogs &> /dev/null; then
                    nethogs
                else
                    echo -e "${YELLOW}Installing network monitoring tools...${NC}"
                    smart_install iftop
                    iftop
                fi
                ;;
            
            8)
                echo -e "${CYAN}=== COMPREHENSIVE HEALTH REPORT ===${NC}"
                echo -e "${YELLOW}System:${NC}"
                echo -e "  Uptime: $(uptime -p)"
                echo -e "  Load: $(uptime | awk -F'load average:' '{print $2}')"
                echo -e "  Users: $(who | wc -l) logged in"
                
                echo -e "\n${YELLOW}Resources:${NC}"
                echo -e "  CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')% used"
                echo -e "  RAM: $(free -h | grep Mem | awk '{print $3"/"$2 " ("$4" free)"}')"
                echo -e "  Swap: $(free -h | grep Swap | awk '{print $3"/"$2}')"
                echo -e "  Disk: $(df -h / | tail -1 | awk '{print $3"/"$2 " ("$5" used)"}')"
                
                echo -e "\n${YELLOW}Processes:${NC}"
                echo -e "  Total: $(ps aux | wc -l)"
                echo -e "  Running: $(ps aux | grep -v grep | grep -c -E 'R\+|R')"
                echo -e "  Sleeping: $(ps aux | grep -v grep | grep -c 'S')"
                
                echo -e "\n${YELLOW}Network:${NC}"
                echo -e "  Interfaces: $(ip -o link show | wc -l)"
                echo -e "  Connections: $(ss -t | grep -v State | wc -l)"
                echo -e "  Listening ports: $(ss -tuln | grep LISTEN | wc -l)"
                
                echo -e "\n${YELLOW}Services:${NC}"
                echo -e "  SSH: $(smart_service ssh status 2>/dev/null | grep "Active:" | cut -d: -f2)"
                echo -e "  Firewall: $FIREWALL ($(smart_firewall status 2>/dev/null | head -1))"
                
                echo -e "\n${YELLOW}Security:${NC}"
                echo -e "  Failed logins (today): $(grep "$(date +%Y-%m-%d)" /var/log/auth.log 2>/dev/null | grep "Failed" | wc -l || echo 0)"
                echo -e "  Last update: $(stat -c %y /var/lib/$PKG_MGR/lock 2>/dev/null | cut -d' ' -f1 || echo "Unknown")"
                ;;
            
            b|B) break ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid choice!${NC}" ;;
        esac
        echo ""
        read -p "Press Enter to continue..."
    done
}

# ----------
# SMART MAINTENANCE
# ----------
maintenance_menu() {
    while true; do
        show_header
        echo -e "${BOLD}${MAGENTA}🔧 MAINTENANCE [Auto-Detected: $OS | $PKG_MGR]${NC}"
        echo ""
        
        # Check for updates
        if [ "$PKG_MGR" = "apt" ]; then
            UPDATES=$(apt list --upgradable 2>/dev/null | wc -l)
            UPDATES=$((UPDATES - 1))
        elif [ "$PKG_MGR" = "yum" ] || [ "$PKG_MGR" = "dnf" ]; then
            UPDATES=$(yum check-update 2>/dev/null | grep -v "^$" | wc -l)
        else
            UPDATES="Unknown"
        fi
        
        # Check reboot required
        REBOOT_REQUIRED="No"
        if [ -f /var/run/reboot-required ]; then
            REBOOT_REQUIRED="Yes"
        fi
        
        echo -e "${CYAN}Updates available:${NC} $UPDATES | ${CYAN}Reboot required:${NC} $REBOOT_REQUIRED"
        echo ""
        
        echo -e "  ${GREEN}1)${NC}  Smart system update"
        echo -e "  ${GREEN}2)${NC}  Auto-cleanup ($PKG_MGR)"
        echo -e "  ${GREEN}3)${NC}  Service health check"
        echo -e "  ${GREEN}4)${NC}  Log rotation management"
        echo -e "  ${GREEN}5)${NC}  Backup automation"
        echo -e "  ${GREEN}6)${NC}  Schedule maintenance"
        echo -e "  ${GREEN}7)${NC}  System sanity check"
        echo -e "  ${GREEN}8)${NC}  Emergency recovery tools"
        echo ""
        echo -e "  ${YELLOW}b)${NC}  Back to Main Menu"
        echo -e "  ${RED}0)${NC}  Exit"
        echo ""
        read -p "$(echo -e "${CYAN}Enter choice: ${NC}")" choice
        
        case $choice in
            1)
                echo -e "${CYAN}Smart system update for $OS...${NC}"
                case $PKG_MGR in
                    apt)
                        apt-get update
                        apt-get upgrade -y
                        apt-get dist-upgrade -y
                        apt-get autoremove -y
                        apt-get autoclean
                        ;;
                    yum|dnf)
                        $PKG_MGR update -y
                        $PKG_MGR autoremove -y
                        ;;
                    pacman)
                        pacman -Syu --noconfirm
                        pacman -Sc --noconfirm
                        ;;
                    apk)
                        apk update
                        apk upgrade
                        apk cache clean
                        ;;
                esac
                echo -e "${GREEN}System updated${NC}"
                
                # Check if reboot needed
                if [ -f /var/run/reboot-required ]; then
                    echo -e "${YELLOW}⚠️  Reboot required!${NC}"
                fi
                ;;
            
            2)
                echo -e "${CYAN}Auto-cleanup for $PKG_MGR...${NC}"
                case $PKG_MGR in
                    apt)
                        apt-get autoremove -y
                        apt-get autoclean
                        apt-get clean
                        ;;
                    yum|dnf)
                        $PKG_MGR autoremove -y
                        $PKG_MGR clean all
                        ;;
                    pacman)
                        pacman -Sc --noconfirm
                        pacman -Scc --noconfirm
                        ;;
                    apk)
                        apk cache clean
                        rm -rf /var/cache/apk/*
                        ;;
                esac
                
                # Clean temp files
                rm -rf /tmp/* /var/tmp/*
                journalctl --vacuum-time=7d 2>/dev/null
                
                echo -e "${GREEN}System cleaned${NC}"
                ;;
            
            7)
                echo -e "${CYAN}=== SYSTEM SANITY CHECK ===${NC}"
                
                # Check disk space
                echo -e "${YELLOW}1. Disk Space:${NC}"
                df -h | grep -E "^/dev/|Filesystem"
                
                # Check inodes
                echo -e "\n${YELLOW}2. Inode Usage:${NC}"
                df -i | grep -E "^/dev/|Filesystem"
                
                # Check memory
                echo -e "\n${YELLOW}3. Memory Usage:${NC}"
                free -h
                
                # Check load
                echo -e "\n${YELLOW}4. System Load:${NC}"
                uptime
                
                # Check services
                echo -e "\n${YELLOW}5. Critical Services:${NC}"
                for service in ssh crond network NetworkManager; do
                    status=$(smart_service "$service" status 2>/dev/null | grep "Active:" | cut -d: -f2)
                    echo -e "  $service: $status"
                done
                
                # Check logs for errors
                echo -e "\n${YELLOW}6. Recent Errors:${NC}"
                journalctl -p 3 -xb --no-pager | head -5 2>/dev/null || \
                grep -i "error\|fail" /var/log/syslog 2>/dev/null | head -5
                
                echo -e "\n${GREEN}Sanity check complete${NC}"
                ;;
            
            b|B) break ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid choice!${NC}" ;;
        esac
        echo ""
        read -p "Press Enter to continue..."
    done
}

# ----------
# AUTO-DETECTION REPORT
# ----------
detection_report() {
    show_header
    echo -e "${BOLD}${MAGENTA}🔍 AUTO-DETECTION REPORT${NC}"
    echo ""
    echo -e "${CYAN}=== SYSTEM DETECTION ===${NC}"
    echo -e "Operating System: $OS_PRETTY"
    echo -e "Package Manager: $PKG_MGR"
    echo -e "Init System: $INIT"
    echo -e "Architecture: $ARCH"
    echo -e "Kernel Version: $KERNEL"
    echo -e "Virtualization: $VIRT"
    
    echo -e "\n${CYAN}=== NETWORK DETECTION ===${NC}"
    echo -e "Network Manager: $NET_MGR"
    echo -e "Firewall: $FIREWALL"
    echo -e "Primary Interface: $(ip route | grep default | awk '{print $5}' | head -1)"
    echo -e "IP Address: $(hostname -I 2>/dev/null | awk '{print $1}')"
    
    echo -e "\n${CYAN}=== RESOURCE DETECTION ===${NC}"
    echo -e "CPU Cores: $(nproc)"
    echo -e "Total RAM: $(free -h | grep Mem | awk '{print $2}')"
    echo -e "Total Disk: $(df -h / | tail -1 | awk '{print $2}')"
    
    echo -e "\n${CYAN}=== SERVICE DETECTION ===${NC}"
    echo -e "SSH: $(command -v sshd >/dev/null && echo "Installed" || echo "Not found")"
    echo -e "Web Server: $(command -v apache2 >/dev/null && echo "Apache" || command -v nginx >/dev/null && echo "Nginx" || echo "None")"
    echo -e "Database: $(command -v mysql >/dev/null && echo "MySQL" || command -v psql >/dev/null && echo "PostgreSQL" || echo "None")"
    
    echo -e "\n${CYAN}=== SECURITY DETECTION ===${NC}"
    echo -e "SELinux: $(getenforce 2>/dev/null || echo "Disabled")"
    echo -e "AppArmor: $(aa-status 2>/dev/null | head -1 || echo "Not found")"
    echo -e "Fail2Ban: $(command -v fail2ban-client >/dev/null && echo "Installed" || echo "Not found")"
    
    echo ""
    read -p "Press Enter to continue..."
}

# ----------
# SMART MAIN MENU
# ----------
main_menu() {
    while true; do
        show_header
        echo -e "${BOLD}${WHITE}SMART MAIN MENU — Auto-Detected: $OS | $PKG_MGR | $INIT${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC}  🔧 System / Identity (Auto: $OS)"
        echo -e "  ${GREEN}2)${NC}  🖥️  Hardware / Fingerprint"
        echo -e "  ${GREEN}3)${NC}  🔐 SSH Controls (Auto: $INIT)"
        echo -e "  ${GREEN}4)${NC}  🛡️  Security (Auto: $FIREWALL)"
        echo -e "  ${GREEN}5)${NC}  🕵️  Privacy / Stealth"
        echo -e "  ${GREEN}6)${NC}  🌐 Network (Auto: $NET_MGR)"
        echo -e "  ${GREEN}7)${NC}  📡 Network Testing"
        echo -e "  ${GREEN}8)${NC}  ⚡ Performance (Auto: $ARCH)"
        echo -e "  ${GREEN}9)${NC}  🔄 Resource Safety"
        echo -e "  ${GREEN}10)${NC} 👥 Users / Sessions"
        echo -e "  ${GREEN}11)${NC} 📊 Monitoring (Live Metrics)"
        echo -e "  ${GREEN}12)${NC} 📝 Logs / Forensics"
        echo -e "  ${GREEN}13)${NC} 🧹 Cleanup / Hygiene"
        echo -e "  ${GREEN}14)${NC} 🔧 Maintenance (Auto: $PKG_MGR)"
        echo -e "  ${GREEN}15)${NC} 🚨 Panic / Recovery"
        echo -e "  ${GREEN}16)${NC} 📁 Files / Permissions"
        echo -e "  ${GREEN}17)${NC} 🤖 Automation"
        echo -e "  ${GREEN}18)${NC} 📈 History / Trends"
        echo -e "  ${GREEN}19)${NC} ⚙️  Presets (Auto-detected)"
        echo -e "  ${GREEN}20)${NC} 🎨 Menu / UX"
        echo -e "  ${GREEN}21)${NC} ℹ️  Meta"
        echo -e "  ${GREEN}22)${NC} 🔍 Auto-Detection Report"
        echo -e "  ${GREEN}23)${NC} 🎯 Smart VPS Score (AI Analysis)"
        echo ""
        echo -e "  ${RED}0)${NC}  Exit"
        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        read -p "$(echo -e "${CYAN}Enter choice [0-23]: ${NC}")" choice
        
        case $choice in
            1) system_identity_menu ;;
            2) hardware_fingerprint_menu ;;
            3) ssh_controls_menu ;;
            4) security_menu ;;
            5) privacy_stealth_menu ;;
            6) network_menu ;;
            7) network_testing_menu ;;
            8) performance_menu ;;
            9) resource_safety_menu ;;
            10) users_sessions_menu ;;
            11) monitoring_menu ;;
            12) logs_forensics_menu ;;
            13) cleanup_hygiene_menu ;;
            14) maintenance_menu ;;
            15) panic_recovery_menu ;;
            16) files_permissions_menu ;;
            17) automation_menu ;;
            18) history_trends_menu ;;
            19) presets_menu ;;
            20) menu_ux_menu ;;
            21) meta_menu ;;
            22) detection_report ;;
            23) smart_vps_score ;;
            0)
                echo -e "${GREEN}Exiting...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option!${NC}"
                sleep 1
                ;;
        esac
    done
}

# ----------
# SMART VPS SCORE (AI-LIKE ANALYSIS)
# ----------
smart_vps_score() {
    show_header
    echo -e "${BOLD}${MAGENTA}🧠 SMART VPS SCORE — AI Analysis${NC}"
    echo ""
    
    TOTAL_SCORE=0
    MAX_SCORE=100
    RECOMMENDATIONS=()
    
    # 1. Security Analysis (30 points)
    echo -e "${CYAN}🔒 Security Analysis...${NC}"
    SECURITY_SCORE=0
    
    # SSH security
    if grep -q "PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
        SECURITY_SCORE=$((SECURITY_SCORE + 5))
    else
        RECOMMENDATIONS+=("Disable root SSH login")
    fi
    
    if grep -q "PasswordAuthentication no" /etc/ssh/sshd_config 2>/dev/null; then
        SECURITY_SCORE=$((SECURITY_SCORE + 5))
    else
        RECOMMENDATIONS+=("Disable password authentication for SSH")
    fi
    
    # Firewall
    if [ "$FIREWALL" != "none" ]; then
        SECURITY_SCORE=$((SECURITY_SCORE + 5))
    else
        RECOMMENDATIONS+=("Install and configure a firewall")
    fi
    
    # Fail2Ban
    if systemctl is-active fail2ban &> /dev/null; then
        SECURITY_SCORE=$((SECURITY_SCORE + 5))
    else
        RECOMMENDATIONS+=("Install Fail2Ban for brute-force protection")
    fi
    
    # Updates
    if [ -f /var/run/reboot-required ]; then
        RECOMMENDATIONS+=("System updates require reboot")
    else
        SECURITY_SCORE=$((SECURITY_SCORE + 5))
    fi
    
    # SELinux/AppArmor
    if command -v getenforce &> /dev/null && [ "$(getenforce)" = "Enforcing" ]; then
        SECURITY_SCORE=$((SECURITY_SCORE + 5))
    elif command -v aa-status &> /dev/null && aa-status | grep -q "apparmor module is loaded"; then
        SECURITY_SCORE=$((SECURITY_SCORE + 5))
    else
        RECOMMENDATIONS+=("Enable SELinux or AppArmor")
    fi
    
    # 2. Performance Analysis (30 points)
    echo -e "${CYAN}⚡ Performance Analysis...${NC}"
    PERFORMANCE_SCORE=0
    
    # Load average
    LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | xargs)
    CORES=$(nproc)
    if (( $(echo "$LOAD < $CORES" | bc -l 2>/dev/null) )); then
        PERFORMANCE_SCORE=$((PERFORMANCE_SCORE + 10))
    else
        RECOMMENDATIONS+=("High load average: $LOAD")
    fi
    
    # Memory usage
    MEM_FREE=$(free | grep Mem | awk '{print $4/$2 * 100.0}')
    if (( $(echo "$MEM_FREE > 10" | bc -l 2>/dev/null) )); then
        PERFORMANCE_SCORE=$((PERFORMANCE_SCORE + 10))
    else
        RECOMMENDATIONS+=("Low memory available: $(printf "%.1f" $MEM_FREE)% free")
    fi
    
    # Swap
    if swapon --show | grep -q .; then
        PERFORMANCE_SCORE=$((PERFORMANCE_SCORE + 5))
    else
        RECOMMENDATIONS+=("Add swap space")
    fi
    
    # BBR congestion control
    if sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -q bbr; then
        PERFORMANCE_SCORE=$((PERFORMANCE_SCORE + 5))
    else
        RECOMMENDATIONS+=("Enable BBR congestion control")
    fi
    
    # 3. Maintenance Analysis (20 points)
    echo -e "${CYAN}🔧 Maintenance Analysis...${NC}"
    MAINTENANCE_SCORE=0
    
    # Disk space
    DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -lt 80 ]; then
        MAINTENANCE_SCORE=$((MAINTENANCE_SCORE + 10))
    elif [ "$DISK_USAGE" -lt 95 ]; then
        MAINTENANCE_SCORE=$((MAINTENANCE_SCORE + 5))
        RECOMMENDATIONS+=("Disk usage is high: $DISK_USAGE%")
    else
        RECOMMENDATIONS+=("⚠️  CRITICAL: Disk almost full: $DISK_USAGE%")
    fi
    
    # Inodes
    INODE_USAGE=$(df -i / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$INODE_USAGE" -lt 80 ]; then
        MAINTENANCE_SCORE=$((MAINTENANCE_SCORE + 5))
    else
        RECOMMENDATIONS+=("Inode usage high: $INODE_USAGE%")
    fi
    
    # Log rotation
    if [ -f /etc/logrotate.conf ]; then
        MAINTENANCE_SCORE=$((MAINTENANCE_SCORE + 5))
    else
        RECOMMENDATIONS+=("Configure log rotation")
    fi
    
    # 4. Configuration Analysis (20 points)
    echo -e "${CYAN}⚙️  Configuration Analysis...${NC}"
    CONFIG_SCORE=0
    
    # Timezone
    if timedatectl 2>/dev/null | grep -q "UTC\|GMT"; then
        CONFIG_SCORE=$((CONFIG_SCORE + 5))
    else
        RECOMMENDATIONS+=("Set timezone to UTC for server consistency")
    fi
    
    # Hostname
    if hostname | grep -q -E "^[a-z0-9\-]+$"; then
        CONFIG_SCORE=$((CONFIG_SCORE + 5))
    else
        RECOMMENDATIONS+=("Use lowercase hostname with hyphens only")
    fi
    
    # DNS
    if grep -q "1.1.1.1\|8.8.8.8\|9.9.9.9" /etc/resolv.conf 2>/dev/null; then
        CONFIG_SCORE=$((CONFIG_SCORE + 5))
    else
        RECOMMENDATIONS+=("Use reliable DNS (Cloudflare, Google, Quad9)")
    fi
    
    # Backup
    if [ -d "$BACKUP_DIR" ]; then
        CONFIG_SCORE=$((CONFIG_SCORE + 5))
    else
        RECOMMENDATIONS+=("Set up backup directory")
    fi
    
    # Calculate total
    TOTAL_SCORE=$((SECURITY_SCORE + PERFORMANCE_SCORE + MAINTENANCE_SCORE + CONFIG_SCORE))
    
    # Display results
    echo -e "\n${CYAN}=== SCORE BREAKDOWN ===${NC}"
    echo -e "🔒 Security: $SECURITY_SCORE/30"
    echo -e "⚡ Performance: $PERFORMANCE_SCORE/30"
    echo -e "🔧 Maintenance: $MAINTENANCE_SCORE/20"
    echo -e "⚙️  Configuration: $CONFIG_SCORE/20"
    echo -e "${BOLD}${WHITE}🎯 TOTAL SCORE: $TOTAL_SCORE/$MAX_SCORE${NC}"
    
    # Progress bar
    PERCENTAGE=$((TOTAL_SCORE * 100 / MAX_SCORE))
    BARS=$((PERCENTAGE / 2))
    echo -ne "\n${GREEN}["
    for i in $(seq 1 50); do
        if [ "$i" -le "$BARS" ]; then
            echo -ne "█"
        else
            echo -ne "░"
        fi
    done
    echo -e "] $PERCENTAGE%${NC}"
    
    # Grade
    echo -e "\n${CYAN}=== GRADE ===${NC}"
    if [ "$TOTAL_SCORE" -ge 90 ]; then
        echo -e "${GREEN}🏆 EXCELLENT — Production ready!${NC}"
    elif [ "$TOTAL_SCORE" -ge 75 ]; then
        echo -e "${GREEN}✅ GOOD — Solid configuration${NC}"
    elif [ "$TOTAL_SCORE" -ge 60 ]; then
        echo -e "${YELLOW}⚠️  FAIR — Needs improvements${NC}"
    elif [ "$TOTAL_SCORE" -ge 40 ]; then
        echo -e "${YELLOW}🔶 POOR — Requires attention${NC}"
    else
        echo -e "${RED}🚨 CRITICAL — Immediate action needed${NC}"
    fi
    
    # Recommendations
    if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
        echo -e "\n${CYAN}=== RECOMMENDATIONS (${#RECOMMENDATIONS[@]}) ===${NC}"
        for i in "${!RECOMMENDATIONS[@]}"; do
            echo -e "$((i+1)). ${RECOMMENDATIONS[$i]}"
        done
    else
        echo -e "\n${GREEN}✅ No recommendations — Excellent configuration!${NC}"
    fi
    
    # Quick fixes
    echo -e "\n${CYAN}=== QUICK FIXES ===${NC}"
    echo -e "1) Run 'Smart system update' in Maintenance"
    echo -e "2) Run 'Auto-optimize performance' in Performance"
    echo -e "3) Run 'Auto-harden system' in Security"
    
    echo ""
    read -p "Press Enter to continue..."
}

# ----------
# INITIALIZATION
# ----------
init_check() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}Please run as root!${NC}"
        exit 1
    fi
    
    # Run all detections
    OS_PRETTY=$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '"' || echo "Unknown OS")
    
    # Create directories
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$CONFIG_DIR"
    
    echo -e "${GREEN}Auto-detection complete!${NC}"
    echo -e "Detected: $OS | $PKG_MGR | $INIT | $VIRT"
    sleep 1
}

# ----------
# START SMART MENU
# ----------
init_check
main_menu
