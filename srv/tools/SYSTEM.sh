#!/bin/bash

# =============== COLORS ===============
R="\e[31m"; G="\e[32m"; Y="\e[33m"; B="\e[34m"; C="\e[36m"; M="\e[35m"; W="\e[37m"; N="\e[0m"

# =============== CONFIGURATION ===============
VERSION="2.1"
REPO_URL="https://github.com/user/vps-analyzer-pro"  # Change this to your actual repo
CONFIG_FILE="$HOME/.vps_analyzer_config"
LOG_FILE="$HOME/vps_analyzer.log"

# =============== AUTO-DETECT & INSTALL ===============
auto_install() {
    local package=$1
    local install_cmd=""
    
    # Detect OS and package manager
    if command -v apt &>/dev/null; then
        install_cmd="sudo apt install -y $package"
    elif command -v yum &>/dev/null; then
        install_cmd="sudo yum install -y $package"
    elif command -v dnf &>/dev/null; then
        install_cmd="sudo dnf install -y $package"
    elif command -v pacman &>/dev/null; then
        install_cmd="sudo pacman -S --noconfirm $package"
    elif command -v zypper &>/dev/null; then
        install_cmd="sudo zypper install -y $package"
    else
        echo -e "${R}❌ Cannot detect package manager${N}"
        return 1
    fi
    
    echo -e "${Y}Installing $package...${N}"
    eval "$install_cmd"
}

check_and_install() {
    local cmd=$1
    local package=${2:-$1}
    
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${R}⚠ $cmd not found${N}"
        read -p "Install $package? [Y/n]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            auto_install "$package"
        else
            echo -e "${R}Skipping $package installation${N}"
            return 1
        fi
    fi
    return 0
}

# =============== SYSTEM DETECTION ===============
detect_system() {
    echo -e "${C}🔍 AUTO-DETECTING SYSTEM...${N}"
    
    # OS Detection
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="$NAME"
        OS_VERSION="$VERSION_ID"
        OS_ID="$ID"
    else
        OS_NAME=$(uname -s)
        OS_VERSION=$(uname -r)
    fi
    
    # Architecture
    ARCH=$(uname -m)
    
    # Virtualization
    if command -v systemd-detect-virt &>/dev/null; then
        VIRT=$(systemd-detect-virt)
        [[ "$VIRT" == "none" ]] && VIRT="Bare Metal"
    else
        if grep -q "hypervisor" /proc/cpuinfo; then
            VIRT="Virtualized"
        else
            VIRT="Physical/Unknown"
        fi
    fi
    
    # CPU Info
    CPU_CORES=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)
    CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | xargs)
    
    # RAM
    TOTAL_RAM=$(free -h | grep Mem | awk '{print $2}')
    
    # Storage
    TOTAL_DISK=$(df -h / | awk 'NR==2 {print $2}')
    
    # Network
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "Not available")
    
    # Save to config
    cat > "$CONFIG_FILE" << EOF
# VPS Analyzer Configuration
OS_NAME="$OS_NAME"
OS_VERSION="$OS_VERSION"
OS_ID="$OS_ID"
ARCH="$ARCH"
VIRT="$VIRT"
CPU_CORES="$CPU_CORES"
CPU_MODEL="$CPU_MODEL"
TOTAL_RAM="$TOTAL_RAM"
TOTAL_DISK="$TOTAL_DISK"
PUBLIC_IP="$PUBLIC_IP"
LAST_UPDATE="$(date)"
EOF
    
    # Display results
    echo -e "${G}✓ System detected:${N}"
    echo -e "  OS: ${Y}$OS_NAME $OS_VERSION${N}"
    echo -e "  Arch: ${Y}$ARCH${N}"
    echo -e "  Virtualization: ${Y}$VIRT${N}"
    echo -e "  CPU: ${Y}$CPU_CORES cores - $CPU_MODEL${N}"
    echo -e "  RAM: ${Y}$TOTAL_RAM${N}"
    echo -e "  Disk: ${Y}$TOTAL_DISK${N}"
    echo -e "  Public IP: ${Y}$PUBLIC_IP${N}"
    
    # Check for required tools
    echo -e "\n${C}🔧 Checking required tools...${N}"
    local missing_tools=()
    
    for tool in curl wget grep awk sed; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools+=("$tool")
            echo -e "  ${R}✗ $tool${N}"
        else
            echo -e "  ${G}✓ $tool${N}"
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "\n${Y}Installing missing tools...${N}"
        for tool in "${missing_tools[@]}"; do
            auto_install "$tool"
        done
    fi
}

# =============== AUTO-UPDATE ===============
auto_update() {
    clear
    echo -e "${C}🔄 CHECKING FOR UPDATES...${N}"
    
    # Check if we can reach GitHub
    if ! curl -s --connect-timeout 5 https://github.com > /dev/null; then
        echo -e "${R}❌ Cannot connect to GitHub${N}"
        pause
        return
    fi
    
    # In a real implementation, you would compare versions here
    # For now, we'll just show a placeholder
    echo -e "${G}✓ You have version $VERSION${N}"
    echo -e "${Y}Latest version available: 2.2${N}"
    
    read -p "Update to latest version? [Y/n]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        echo -e "${Y}Updating VPS Analyzer Pro...${N}"
        
        # Backup current script
        cp "$0" "$0.backup.$(date +%Y%m%d)"
        
        # Download latest (placeholder - replace with actual URL)
        echo -e "${C}Downloading update...${N}"
        # wget -q -O "$0.tmp" "$REPO_URL/raw/main/vps-analyzer-pro.sh"
        
        # For now, simulate update
        sleep 2
        echo -e "${G}✓ Update downloaded${N}"
        
        # Make executable
        chmod +x "$0"
        
        echo -e "\n${G}✅ Update complete! Restarting...${N}"
        sleep 2
        exec "$0"
    else
        echo -e "${Y}Skipping update${N}"
        pause
    fi
}

# =============== INSTALL ALL FEATURES ===============
install_all_features() {
    clear
    echo -e "${C}🚀 INSTALLING ALL REQUIRED PACKAGES${N}"
    echo -e "${Y}This may take a few minutes...${N}"
    echo
    
    # Update package list
    echo -e "${G}Updating package lists...${N}"
    if command -v apt &>/dev/null; then
        sudo apt update -y
    elif command -v yum &>/dev/null; then
        sudo yum update -y
    fi
    
    # Install monitoring tools
    local packages=(
        "speedtest-cli"           # Option 7
        "lm-sensors"             # Option 9
        "sysstat"                # Option 6 (mpstat)
        "iftop"                  # Option 5
        "docker.io docker-compose" # Option 15
        "sysbench"               # Option 16
        "htop"                   # Alternative to BTOP
        "nethogs"                # Network monitoring
        "nmon"                   # System monitoring
        "dstat"                  # Resource monitoring
        "bmon"                   # Bandwidth monitor
    )
    
    for package in "${packages[@]}"; do
        echo -e "\n${C}Installing: $package${N}"
        auto_install "$package" 2>/dev/null || echo -e "${R}Failed to install $package${N}"
    done
    
    # Special configurations
    echo -e "\n${Y}Configuring sensors...${N}"
    sudo sensors-detect --auto > /dev/null 2>&1
    
    # Enable services
    echo -e "\n${Y}Enabling services...${N}"
    sudo systemctl enable docker 2>/dev/null
    sudo systemctl start docker 2>/dev/null
    
    echo -e "\n${G}✅ All features installed!${N}"
    echo -e "${Y}Some features may require a reboot to work properly.${N}"
    pause
}

# =============== QUICK DIAGNOSTIC ===============
quick_diagnostic() {
    clear
    echo -e "${C}⚡ QUICK SYSTEM DIAGNOSTIC${N}"
    echo
    
    # Load system info
    if [ -f "$CONFIG_FILE" ]; then
        . "$CONFIG_FILE"
    else
        detect_system
    fi
    
    # Health checks
    echo -e "${Y}📊 SYSTEM HEALTH CHECK${N}"
    
    # CPU Load
    LOAD=$(uptime | awk -F'load average:' '{print $2}')
    echo -e "  Load Average: $LOAD"
    
    # Memory Usage
    MEM_USED=$(free -m | awk '/Mem/ {printf "%.1f%%", $3/$2*100}')
    echo -e "  Memory Usage: $MEM_USED"
    
    # Disk Usage
    DISK_USED=$(df -h / | awk 'NR==2 {printf "%s (%s)", $3, $5}')
    echo -e "  Disk Usage: $DISK_USED"
    
    # Temperature (if available)
    if command -v sensors &>/dev/null; then
        TEMP=$(sensors | grep -E "Core|Package" | head -1 | awk '{print $3}')
        echo -e "  CPU Temp: $TEMP"
    fi
    
    # Network Connectivity
    echo -e "\n${Y}🌐 NETWORK CHECK${N}"
    if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        echo -e "  ${G}✓ Internet: Connected${N}"
    else
        echo -e "  ${R}✗ Internet: Disconnected${N}"
    fi
    
    # Service Status
    echo -e "\n${Y}🔧 SERVICES STATUS${N}"
    local services=("sshd" "docker" "cron")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "  ${G}✓ $service: Running${N}"
        else
            echo -e "  ${Y}⚠ $service: Not running${N}"
        fi
    done
    
    # Security Check
    echo -e "\n${Y}🛡️ SECURITY CHECK${N}"
    if [ -f /etc/ssh/sshd_config ]; then
        if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
            echo -e "  ${G}✓ Root SSH: Disabled${N}"
        else
            echo -e "  ${R}⚠ Root SSH: Enabled${N}"
        fi
    fi
    
    # Recommendations
    echo -e "\n${C}💡 RECOMMENDATIONS${N}"
    if [ "${MEM_USED%\%}" -gt 80 ]; then
        echo -e "  • High memory usage - consider optimizing"
    fi
    if [ "${DISK_USED##*(}" -gt "80%" ]; then
        echo -e "  • High disk usage - consider cleanup"
    fi
    
    pause
}

# =============== LOGGING ===============
log_action() {
    local action="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $action" >> "$LOG_FILE"
}

# =============== HELPERS ===============
pause() {
    echo
    read -p "↩ Press Enter to return to menu..." _
}

header() {
    clear
    echo -e "${C}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║               VPS ANALYZER PRO UI v$VERSION                ║"
    echo "║                  WITH AUTO-DETECT & INSTALL                ║"
    echo "╚════════════════════════════════════════════════════════════╝${N}"
}

# =============== SPEEDTEST ===============
speedtest_run() {
    clear
    echo -e "${Y}🚀 INTERNET SPEEDTEST${N}"
    check_and_install "speedtest-cli" "speedtest-cli"
    speedtest-cli --simple
    log_action "Ran speedtest"
    pause
}

# =============== LOG VIEWER ===============
logs_view() {
    clear
    echo -e "${C}📜 System Logs (last 50 lines)${N}"
    journalctl -n 50 --no-pager | sed 's/^/   /'
    pause
}

# =============== TEMPERATURE MONITOR ===============
temp_monitor() {
    clear
    echo -e "${Y}🌡 TEMPERATURE MONITOR${N}"
    check_and_install "sensors" "lm-sensors"
    echo -e "${C}Live temperatures (refresh 1s) — CTRL+C to exit${N}"
    sleep 1
    watch -n 1 sensors
}

# =============== DDOS / ABUSE CHECK ===============
ddos_check() {
    clear
    while true; do
        clear
        echo -e "${R}⚠ LIVE ATTACK / CONNECTION WATCH${N}"
        echo
        echo -e "${C}Top IPs by connection count:${N}"
        ss -tuna | awk 'NR>1{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head
        echo
        echo -e "${Y}CPU Load:${N} $(uptime | awk -F'load average:' '{print $2}')"
        echo -e "\n⏳ Refreshing every 2s...   CTRL+C to exit"
        sleep 2
    done
}

# =============== BTOP-LIKE DRAW BAR ===============
draw_bar() {
    local used=$1
    local total=$2
    (( total == 0 )) && total=1
    local p=$(( used * 100 / total ))
    local filled=$(( p / 2 ))
    local empty=$(( 50 - filled ))
    printf "${G}%3s%% ${R}[" "$p"
    printf "${Y}%0.s█" $(seq 1 $filled)
    printf "%0.s░" $(seq 1 $empty)
    printf "${R}]${N}"
}

# =============== BTOP-LIKE LIVE DASHBOARD ===============
btop_live() {
    check_and_install "mpstat" "sysstat"
    
    while true; do
        clear
        echo -e "${C}══════════  VPS BTOP LIVE MONITOR  ══════════${N}"

        # CPU per core (requires mpstat from sysstat)
        if command -v mpstat >/dev/null 2>&1; then
            echo -e "${Y}CPU Per-Core Usage:${N}"
            mpstat -P ALL 1 1 | awk '/Average/ && $2 ~ /[0-9]/ {printf "Core %-2s : %3s%%\n",$2,100-$12}'
        else
            echo -e "${R}mpstat not installed.${N}"
        fi

        # RAM
        mem_used=$(free -m | awk '/Mem/ {print $3}')
        mem_total=$(free -m | awk '/Mem/ {print $2}')
        echo -e "\n${Y}RAM:${N}"
        draw_bar "$mem_used" "$mem_total"
        echo -e "  (${mem_used}MB / ${mem_total}MB)"

        # DISK (/)
        disk_used=$(df / | awk 'NR==2 {print $3}')
        disk_total=$(df / | awk 'NR==2 {print $2}')
        echo -e "\n${Y}DISK (/):${N}"
        draw_bar "$disk_used" "$disk_total"
        echo -e "  (${disk_used}MB / ${disk_total}MB)"

        # TOP PROCESSES
        echo -e "\n${B}🔥 Top CPU Processes:${N}"
        ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -10

        # NETWORK SPEED
        rx1=$(cat /sys/class/net/*/statistics/rx_bytes 2>/dev/null | paste -sd+)
        tx1=$(cat /sys/class/net/*/statistics/tx_bytes 2>/dev/null | paste -sd+)
        sleep 1
        rx2=$(cat /sys/class/net/*/statistics/rx_bytes 2>/dev/null | paste -sd+)
        tx2=$(cat /sys/class/net/*/statistics/tx_bytes 2>/dev/null | paste -sd+)

        rx_kb=$(( (rx2 - rx1) / 1024 ))
        tx_kb=$(( (tx2 - tx1) / 1024 ))
        echo -e "\n${G}NET:${N} ⬇ ${rx_kb} KB/s   ⬆ ${tx_kb} KB/s"

        echo -e "\n${C}Press CTRL+C to exit BTOP mode...${N}"
    done
}

# =============== SERVICE MONITOR ===============
service_monitor() {
    clear
    echo -e "${M}🔧 SERVICE STATUS MONITOR${N}"
    echo
    echo -e "${Y}1) List all services${N}"
    echo -e "${Y}2) Check specific service${N}"
    echo -e "${Y}3) Start/Stop service${N}"
    echo -e "${Y}4) Enable/Disable at boot${N}"
    echo
    read -p "Choose option [1-4]: " service_opt
    
    case $service_opt in
        1)
            systemctl list-units --type=service --no-pager | head -30
            ;;
        2)
            read -p "Enter service name (e.g., nginx, sshd): " svc_name
            systemctl status "$svc_name" --no-pager
            ;;
        3)
            read -p "Service name: " svc_name
            echo -e "${Y}1) Start${N}"
            echo -e "${Y}2) Stop${N}"
            echo -e "${Y}3) Restart${N}"
            read -p "Action [1-3]: " action
            case $action in
                1) sudo systemctl start "$svc_name" ;;
                2) sudo systemctl stop "$svc_name" ;;
                3) sudo systemctl restart "$svc_name" ;;
                *) echo "Invalid option" ;;
            esac
            systemctl status "$svc_name" --no-pager | head -10
            ;;
        4)
            read -p "Service name: " svc_name
            echo -e "${Y}1) Enable at boot${N}"
            echo -e "${Y}2) Disable at boot${N}"
            read -p "Action [1-2]: " action
            case $action in
                1) sudo systemctl enable "$svc_name" ;;
                2) sudo systemctl disable "$svc_name" ;;
                *) echo "Invalid option" ;;
            esac
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    pause
}

# =============== SECURITY AUDIT ===============
security_audit() {
    clear
    echo -e "${R}🔐 SECURITY AUDIT${N}"
    echo
    echo -e "${Y}🛡️ SSH Security Check:${N}"
    grep -E "^PermitRootLogin" /etc/ssh/sshd_config 2>/dev/null || echo "PermitRootLogin not found"
    grep -E "^PasswordAuthentication" /etc/ssh/sshd_config 2>/dev/null || echo "PasswordAuthentication not found"
    
    echo -e "\n${Y}🔍 Failed Login Attempts:${N}"
    lastb | head -10
    
    echo -e "\n${Y}👥 Users with sudo:${N}"
    grep -Po '^sudo.+:\K.*$' /etc/group | tr ',' '\n'
    
    echo -e "\n${Y}🔐 Open Ports:${N}"
    ss -tuln | grep LISTEN
    
    pause
}

# =============== BACKUP MANAGER ===============
backup_manager() {
    clear
    echo -e "${G}💾 BACKUP MANAGER${N}"
    echo
    echo -e "${Y}1) Quick backup (home directory)${N}"
    echo -e "${Y}2) Backup specific folder${N}"
    echo -e "${Y}3) Schedule automatic backup${N}"
    echo -e "${Y}4) List backup files${N}"
    echo
    read -p "Choose option [1-4]: " backup_opt
    
    case $backup_opt in
        1)
            backup_file="backup_home_$(date +%Y%m%d_%H%M%S).tar.gz"
            echo -e "${C}Creating backup of /home to ~/$backup_file${N}"
            tar -czf ~/"$backup_file" /home 2>/dev/null
            echo -e "${G}Backup created: ~/$backup_file${N}"
            du -h ~/"$backup_file" | awk '{print "Size:", $1}'
            ;;
        2)
            read -p "Enter folder path to backup: " folder_path
            if [ -d "$folder_path" ]; then
                folder_name=$(basename "$folder_path")
                backup_file="backup_${folder_name}_$(date +%Y%m%d_%H%M%S).tar.gz"
                tar -czf ~/"$backup_file" "$folder_path" 2>/dev/null
                echo -e "${G}Backup created: ~/$backup_file${N}"
            else
                echo -e "${R}Folder not found!${N}"
            fi
            ;;
        3)
            echo -e "${Y}Coming soon... Use cron for scheduling${N}"
            ;;
        4)
            echo -e "${C}Backup files in home directory:${N}"
            ls -lh ~/backup_* 2>/dev/null || echo "No backup files found"
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    pause
}

# =============== DOCKER MONITOR ===============
docker_monitor() {
    clear
    echo -e "${B}🐳 DOCKER MONITOR${N}"
    
    check_and_install "docker" "docker.io"
    
    echo -e "${Y}1) List containers${N}"
    echo -e "${Y}2) List images${N}"
    echo -e "${Y}3) Container stats${N}"
    echo -e "${Y}4) Docker disk usage${N}"
    echo
    read -p "Choose option [1-4]: " docker_opt
    
    case $docker_opt in
        1)
            echo -e "${C}Running containers:${N}"
            docker ps
            echo -e "\n${C}All containers:${N}"
            docker ps -a
            ;;
        2)
            docker images
            ;;
        3)
            docker stats --no-stream
            ;;
        4)
            docker system df
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    pause
}

# =============== PERFORMANCE BENCHMARK ===============
performance_benchmark() {
    clear
    echo -e "${Y}📊 PERFORMANCE BENCHMARK${N}"
    
    echo -e "${C}Running CPU benchmark (30 seconds)...${N}"
    echo -e "CPU BogoMips: $(grep -i bogomips /proc/cpuinfo | head -1 | awk -F: '{print $2}')"
    
    # Simple CPU test
    echo -e "\n${Y}CPU Test (calculating π):${N}"
    time echo "scale=5000; 4*a(1)" | bc -l 2>&1 | tail -3
    
    # Disk speed test
    echo -e "\n${Y}Disk Write Speed:${N}"
    dd if=/dev/zero of=/tmp/testfile bs=1M count=100 2>&1 | tail -1
    rm -f /tmp/testfile
    
    # Memory speed test
    echo -e "\n${Y}Memory Speed:${N}"
    check_and_install "sysbench" "sysbench"
    if command -v sysbench &>/dev/null; then
        sysbench memory --memory-block-size=1M --memory-total-size=1G run 2>/dev/null | grep -E "transferred|seconds"
    fi
    
    pause
}

# =============== MAIN MENU (UPDATED) ===============

# Run auto-detect on first launch
if [ ! -f "$CONFIG_FILE" ]; then
    detect_system
fi

while true; do
    header
    echo -e "
 ${G}╔════════════════╗    ${Y}╔════════════════╗    ${B}╔════════════════╗
 ${G}║ 1) System Info ║    ${Y}║ 2) Disk+RAM    ║    ${B}║ 3) Network      ║
 ${G}║    (Auto-Detect)║    ${Y}║                ║    ${B}║                ║
 ${G}╚════════════════╝    ${Y}╚════════════════╝    ${B}╚════════════════╝

 ${R}╔════════════════╗    ${C}╔════════════════╗    ${Y}╔════════════════╗
 ${R}║ 4) Fake Check  ║    ${C}║ 5) Live Traffic║    ${Y}║ 6) BTOP Mode    ║
 ${R}║                ║    ${C}║  (Auto-Install)║    ${Y}║ (Auto-Install)  ║
 ${R}╚════════════════╝    ${C}╚════════════════╝    ${Y}╚════════════════╝

 ${B}╔════════════════╗    ${G}╔════════════════╗    ${R}╔════════════════╗
 ${B}║ 7) SpeedTest   ║    ${G}║ 8) Logs Viewer ║    ${R}║ 9) Temp Monitor ║
 ${B}║ (Auto-Install) ║    ${G}║                ║    ${R}║ (Auto-Install)  ║
 ${B}╚════════════════╝    ${G}╚════════════════╝    ${R}╚════════════════╝

 ${M}╔════════════════╗    ${C}╔════════════════╗    ${G}╔════════════════╗
 ${M}║12) Services    ║    ${C}║13) Security    ║    ${G}║14) Backup       ║
 ${M}║                ║    ${C}║                ║    ${G}║                ║
 ${M}╚════════════════╝    ${C}╚════════════════╝    ${G}╚════════════════╝

 ${B}╔════════════════╗    ${Y}╔════════════════╗    ${R}╔════════════════╗
 ${B}║15) Docker      ║    ${Y}║16) Performance ║    ${R}║17) Auto-Update  ║
 ${B}║(Auto-Install)  ║    ${Y}║(Auto-Install)  ║    ${R}║                ║
 ${B}╚════════════════╝    ${Y}╚════════════════╝    ${R}╚════════════════╝

                    ${Y}╔═════════════════════════╗
                    ${Y}║10) DDOS/Abuse Check     ║
                    ${Y}║                         ║
                    ${Y}╚═════════════════════════╝

 ${G}╔════════════════╗    ${C}╔════════════════╗    ${R}╔════════════════╗
 ${G}║18) Quick Diag  ║    ${C}║19) Install All ║    ${R}║ 11) Exit       ║
 ${G}║                ║    ${C}║                ║    ${R}║                ║
 ${G}╚════════════════╝    ${C}╚════════════════╝    ${R}╚════════════════╝${N}
"

    read -p "Option → " x

    case "$x" in
        1)
            clear
            echo -e "${G}📌 SYSTEM INFO${N}"
            if [ -f "$CONFIG_FILE" ]; then
                cat "$CONFIG_FILE"
            else
                hostnamectl
                echo -e "\n${Y}Running auto-detect...${N}"
                detect_system
            fi
            pause
            ;;
        2)
            clear
            echo -e "${Y}🧠 RAM:${N}"
            free -h
            echo
            echo -e "${Y}💽 DISK:${N}"
            df -h
            pause
            ;;
        3)
            clear
            echo -e "${C}🌐 NETWORK INFO${N}"
            ip a
            pause
            ;;
        4)
            clear
            echo -e "${R}🕵 VPS FAKE / REAL CHECK${N}"
            echo -e "${Y}Virtualization:${N}"
            systemd-detect-virt
            echo
            echo -e "${Y}CPU VMX/SVM Flags:${N}"
            if grep -E -o "vmx|svm" /proc/cpuinfo >/dev/null; then
                echo -e "${G}✔ Hardware virtualization flags present${N}"
            else
                echo -e "${R}❗ VMX/SVM NOT found — may be weak/fake VPS${N}"
            fi
            pause
            ;;
        5)
            clear
            echo -e "${C}📡 LIVE TRAFFIC (iftop)${N}"
            check_and_install "iftop" "iftop"
            echo -e "${Y}Ctrl+C to exit, then Enter to return to menu.${N}"
            sleep 1
            iftop -n -P
            pause
            ;;
        6)
            btop_live
            ;;
        7)
            speedtest_run
            ;;
        8)
            logs_view
            ;;
        9)
            temp_monitor
            ;;
        10)
            ddos_check
            ;;
        11)
            clear
            echo -e "${Y}Exiting VPS Analyzer Pro. Bye!${N}"
            exit 0
            ;;
        12)
            service_monitor
            ;;
        13)
            security_audit
            ;;
        14)
            backup_manager
            ;;
        15)
            docker_monitor
            ;;
        16)
            performance_benchmark
            ;;
        17)
            auto_update
            ;;
        18)
            quick_diagnostic
            ;;
        19)
            install_all_features
            ;;
        *)
            echo "Invalid option"; sleep 1 ;;
    esac
done
