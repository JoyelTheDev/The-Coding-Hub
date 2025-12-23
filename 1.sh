#!/bin/bash

# ==============================
# Enhanced Docker Manager with AI Auto-Detect
# ==============================

set -euo pipefail

# ===== Colors and Styles =====
BG_BLUE="\e[44m"
BG_GREEN="\e[42m"
BG_RED="\e[41m"
BG_YELLOW="\e[43m"
BG_CYAN="\e[46m"
BG_MAGENTA="\e[45m"
BG_BLACK="\e[40m"

FG_BLACK="\e[30m"
FG_WHITE="\e[97m"
FG_GREEN="\e[32m"
FG_RED="\e[31m"
FG_YELLOW="\e[33m"
FG_CYAN="\e[36m"
FG_MAGENTA="\e[35m"
FG_BLUE="\e[34m"

BOLD="\e[1m"
DIM="\e[2m"
ITALIC="\e[3m"
UNDERLINE="\e[4m"
BLINK="\e[5m"
REVERSE="\e[7m"
HIDDEN="\e[8m"

RESET="\e[0m"

# Box drawing characters
BOX_HORIZ="─"
BOX_VERT="│"
BOX_CORNER_TL="┌"
BOX_CORNER_TR="┐"
BOX_CORNER_BL="└"
BOX_CORNER_BR="┘"

# AI Emojis
AI_ICON="🤖"
AUTO_ICON="⚡"
DETECT_ICON="🔍"
SUGGEST_ICON="💡"
SMART_ICON="🧠"
ANALYZE_ICON="📊"
OPTIMIZE_ICON="⚙️"
OS_ICON="🐧"
LINUX_ICON="💻"
CONTAINER_ICON="📦"

# ===== Functions =====
print_header() {
    clear
    echo -e "${BG_CYAN}${FG_BLACK}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                  🐳 DOCKER MANAGER PRO v4.0 - AI Auto-Detect                ║"
    echo "║               ${AI_ICON} Multi-OS Detection | Smart Analysis | Auto Optimization         ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo
}

print_box() {
    local width=$1
    local title=$2
    local color=$3
    local content=$4
    
    echo -e "${color}${BOX_CORNER_TL}"
    for ((i=0; i<width-2; i++)); do echo -n "${BOX_HORIZ}"; done
    echo "${BOX_CORNER_TR}${RESET}"
    
    if [ -n "$title" ]; then
        echo -e "${color}${BOX_VERT}${RESET} ${BOLD}${title}${RESET}"
        echo -e "${color}${BOX_VERT}${RESET}"
    fi
    
    echo -e "${color}${BOX_VERT}${RESET} ${content}"
    
    echo -e "${color}${BOX_VERT}${RESET}"
    echo -e "${color}${BOX_CORNER_BL}"
    for ((i=0; i<width-2; i++)); do echo -n "${BOX_HORIZ}"; done
    echo "${BOX_CORNER_BR}${RESET}"
}

print_status() {
    local type=$1
    local message=$2
    
    case $type in
        "INFO") echo -e "${FG_CYAN}📋 [INFO]${RESET} $message" ;;
        "WARN") echo -e "${FG_YELLOW}⚠️  [WARN]${RESET} $message" ;;
        "ERROR") echo -e "${FG_RED}❌ [ERROR]${RESET} $message" ;;
        "SUCCESS") echo -e "${FG_GREEN}✅ [SUCCESS]${RESET} $message" ;;
        "INPUT") echo -e "${FG_MAGENTA}🎯 [INPUT]${RESET} $message" ;;
        "TITLE") echo -e "${BOLD}${FG_BLUE}📌${RESET} ${FG_CYAN}${message}${RESET}" ;;
        "AI") echo -e "${FG_MAGENTA}${AI_ICON} [AI]${RESET} $message" ;;
        "AUTO") echo -e "${FG_BLUE}${AUTO_ICON} [AUTO]${RESET} $message" ;;
        "DETECT") echo -e "${FG_CYAN}${DETECT_ICON} [DETECT]${RESET} $message" ;;
        "OS") echo -e "${FG_GREEN}${OS_ICON} [OS]${RESET} $message" ;;
        "LINUX") echo -e "${FG_BLUE}${LINUX_ICON} [LINUX]${RESET} $message" ;;
        *) echo "[$type] $message" ;;
    esac
}

print_menu_item() {
    local number=$1
    local icon=$2
    local text=$3
    local desc=$4
    
    printf "${FG_CYAN}%2d)${RESET} ${BOLD}${icon} ${text}${RESET}\n" "$number"
    printf "     ${DIM}${desc}${RESET}\n"
}

pause() {
    echo
    read -rp "$(echo -e "${FG_CYAN}⏎${RESET} Press ${BOLD}Enter${RESET} to continue... ")" -n1
    echo
}

loading() {
    local msg=$1
    local ai_mode=${2:-false}
    
    if [ "$ai_mode" = true ]; then
        echo -ne "${FG_MAGENTA}${AI_ICON}${RESET} ${msg}"
        local dots=("🤔" "🧠" "💡" "⚡")
    else
        echo -ne "${FG_CYAN}⏳${RESET} ${msg}"
        local dots=("." "." ".")
    fi
    
    for dot in "${dots[@]}"; do
        echo -ne "$dot"
        sleep 0.3
    done
    echo -e "${FG_GREEN} ✓${RESET}"
}

# ===== Multi-OS Linux Detection - SIMPLIFIED =====
detect_linux_distribution() {
    print_status "OS" "Detecting Linux distribution..."
    
    local distro_name="Unknown"
    local distro_version="Unknown"
    local distro_id=""
    local package_manager=""
    local distro_logo="${OS_ICON}"
    
    # Simple OS detection
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        distro_name="$NAME"
        distro_version="$VERSION_ID"
        distro_id="$ID"
        
        # Set package manager based on OS
        case $ID in
            ubuntu|debian|pop|raspbian|kali)
                package_manager="apt"
                distro_logo="🟠"
                ;;
            fedora|rhel|centos)
                package_manager="dnf"
                distro_logo="🔴"
                ;;
            arch|manjaro)
                package_manager="pacman"
                distro_logo="🔵"
                ;;
            alpine)
                package_manager="apk"
                distro_logo="🏔️"
                ;;
            opensuse|suse)
                package_manager="zypper"
                distro_logo="🟢"
                ;;
            *)
                package_manager="unknown"
                ;;
        esac
    elif [ -f /etc/debian_version ]; then
        distro_name="Debian"
        distro_version=$(cat /etc/debian_version)
        package_manager="apt"
        distro_logo="🟠"
    elif [ -f /etc/redhat-release ]; then
        distro_name="Red Hat"
        distro_version=$(grep -o '[0-9]*' /etc/redhat-release)
        package_manager="dnf"
        distro_logo="🔴"
    elif [ -f /etc/arch-release ]; then
        distro_name="Arch Linux"
        distro_version="Rolling"
        package_manager="pacman"
        distro_logo="🔵"
    elif [ -f /etc/alpine-release ]; then
        distro_name="Alpine Linux"
        distro_version=$(cat /etc/alpine-release)
        package_manager="apk"
        distro_logo="🏔️"
    fi
    
    # Detect kernel
    local kernel_version=$(uname -r)
    local architecture=$(uname -m)
    
    # Detect system resources
    local total_memory=$(free -m | awk '/^Mem:/{print $2}')
    local cpu_cores=$(nproc)
    
    # Return as simple variables
    OS_NAME="$distro_name"
    OS_VERSION="$distro_version"
    OS_ID="$distro_id"
    OS_PACKAGE_MANAGER="$package_manager"
    OS_LOGO="$distro_logo"
    OS_KERNEL="$kernel_version"
    OS_ARCH="$architecture"
    OS_MEMORY="$total_memory"
    OS_CORES="$cpu_cores"
}

display_os_info() {
    print_header
    print_status "OS" "Linux Distribution Analysis"
    echo
    
    detect_linux_distribution
    
    echo -e "${BOLD}${FG_BLUE}${OS_LOGO} ${OS_NAME} ${OS_VERSION}${RESET}\n"
    
    print_box 70 "📊 OS Information" "${FG_BLUE}" \
        "Distribution: ${BOLD}${OS_NAME} ${OS_VERSION}${RESET}\n"\
        "Distro ID: ${BOLD}${OS_ID}${RESET}\n"\
        "Package Manager: ${BOLD}${OS_PACKAGE_MANAGER}${RESET}\n"\
        "Kernel: ${BOLD}${OS_KERNEL}${RESET}\n"\
        "Architecture: ${BOLD}${OS_ARCH}${RESET}"
    
    echo
    
    # Resource information
    print_box 70 "💾 Hardware Resources" "${FG_MAGENTA}" \
        "CPU Cores: ${BOLD}${OS_CORES}${RESET}\n"\
        "Total Memory: ${BOLD}${OS_MEMORY}MB${RESET}\n"\
        "Uptime: ${BOLD}$(uptime -p | sed 's/up //')${RESET}"
    
    echo
    
    # Docker detection
    if command -v docker &>/dev/null; then
        local docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "Unknown")
        local total_containers=$(docker ps -aq 2>/dev/null | wc -l)
        local running_containers=$(docker ps -q 2/dev/null | wc -l)
        local total_images=$(docker images -q 2>/dev/null | wc -l)
        
        print_box 70 "🐳 Docker Environment" "${FG_GREEN}" \
            "Docker Version: ${BOLD}${docker_version}${RESET}\n"\
            "Containers: ${BOLD}${running_containers} running / ${total_containers} total${RESET}\n"\
            "Images: ${BOLD}${total_images}${RESET}"
    else
        print_box 70 "🐳 Docker Status" "${FG_YELLOW}" \
            "Status: ${BOLD}Docker not installed${RESET}\n"\
            "Recommendation: ${BOLD}Install Docker for container management${RESET}"
    fi
    
    echo
    
    # OS-specific recommendations
    print_status "AI" "OS-specific recommendations..."
    
    case $OS_ID in
        ubuntu|debian)
            echo -e "${BOLD}🎯 For ${OS_NAME}:${RESET}"
            echo -e "  • Use apt for package management"
            echo -e "  • Ubuntu/Debian images work best"
            echo -e "  • Consider LTS versions for stability"
            ;;
        fedora|centos|rhel)
            echo -e "${BOLD}🎯 For ${OS_NAME}:${RESET}"
            echo -e "  • Use dnf/yum for package management"
            echo -e "  • SELinux may need configuration"
            echo -e "  • Enterprise-focused distributions"
            ;;
        arch)
            echo -e "${BOLD}🎯 For ${OS_NAME}:${RESET}"
            echo -e "  • Use pacman for package management"
            echo -e "  • Rolling release - always up-to-date"
            echo -e "  • Great for development environments"
            ;;
        alpine)
            echo -e "${BOLD}🎯 For ${OS_NAME}:${RESET}"
            echo -e "  • Use apk for package management"
            echo -e "  • Lightweight and security-focused"
            echo -e "  • Perfect for containers"
            ;;
    esac
}

auto_detect_os_images() {
    print_status "OS" "Detecting optimal images for your OS..."
    
    detect_linux_distribution
    
    echo -e "${BOLD}${FG_BLUE}${OS_LOGO} ${OS_NAME}-Compatible Images${RESET}\n"
    
    # OS-specific image suggestions
    case $OS_ID in
        ubuntu|debian)
            echo -e "${BOLD}🎯 Ubuntu/Debian Images:${RESET}"
            echo -e "  📦 ubuntu:latest (Official Ubuntu)"
            echo -e "  📦 debian:bullseye-slim (Lightweight Debian)"
            echo -e "  📦 python:3.11-slim (Python on Debian)"
            echo -e "  📦 node:18-bullseye (Node.js LTS)"
            ;;
        fedora|centos|rhel)
            echo -e "${BOLD}🎯 RedHat Family Images:${RESET}"
            echo -e "  📦 fedora:latest (Latest Fedora)"
            echo -e "  📦 centos:7 (CentOS 7)"
            echo -e "  📦 rockylinux:9 (Rocky Linux)"
            echo -e "  📦 python:3.11 (Python on Fedora)"
            ;;
        arch)
            echo -e "${BOLD}🎯 Arch Linux Images:${RESET}"
            echo -e "  📦 archlinux:latest (Base Arch)"
            echo -e "  📦 python:3.11 (Python on Arch)"
            echo -e "  📦 node:current (Latest Node.js)"
            ;;
        alpine)
            echo -e "${BOLD}🎯 Alpine Linux Images:${RESET}"
            echo -e "  📦 alpine:latest (Base Alpine)"
            echo -e "  📦 nginx:alpine (Nginx on Alpine)"
            echo -e "  📦 python:3.11-alpine (Python Alpine)"
            echo -e "  📦 node:18-alpine (Node.js Alpine)"
            ;;
        *)
            echo -e "${BOLD}🎯 Universal Images:${RESET}"
            echo -e "  📦 alpine:latest (Lightweight)"
            echo -e "  📦 ubuntu:latest (General purpose)"
            echo -e "  📦 busybox:latest (Minimal)"
            ;;
    esac
    
    echo
    echo -e "${BOLD}💡 Smart Suggestions:${RESET}"
    
    if [ $OS_MEMORY -lt 2048 ]; then
        echo -e "  ⚠️  Low memory system (${OS_MEMORY}MB) - Use Alpine-based images"
        echo -e "  ✅ Recommended: nginx:alpine, python:alpine, node:alpine"
    elif [ $OS_MEMORY -gt 8192 ]; then
        echo -e "  💪 High memory system (${OS_MEMORY}MB) - Can run heavy images"
        echo -e "  ✅ Recommended: Full Ubuntu, databases, IDEs"
    else
        echo -e "  ⚡ Balanced system (${OS_MEMORY}MB) - Use slim variants"
        echo -e "  ✅ Recommended: *-slim tags, moderate workloads"
    fi
}

auto_detect_multios_compatibility() {
    print_status "DETECT" "Analyzing multi-OS compatibility..."
    
    detect_linux_distribution
    
    echo -e "${BOLD}${FG_BLUE}🌍 Multi-OS Container Compatibility${RESET}\n"
    
    echo -e "${BOLD}🏗️  Host System:${RESET}"
    echo -e "  OS: ${OS_NAME} ${OS_VERSION}"
    echo -e "  Arch: ${OS_ARCH}"
    echo -e "  Kernel: ${OS_KERNEL}"
    echo
    
    echo -e "${BOLD}📦 Supported Container OS Types:${RESET}"
    echo -e "  ✅ Linux (amd64, arm64, armv7)"
    echo -e "  ✅ Windows Server (via Linux containers)"
    echo -e "  ✅ macOS (via Docker Desktop)"
    echo
    
    echo -e "${BOLD}🔧 Architecture Support:${RESET}"
    case $OS_ARCH in
        x86_64)
            echo -e "  ✅ amd64 (Native)"
            echo -e "  ✅ i386 (32-bit)"
            echo -e "  ⚠️  arm64 (via QEMU emulation)"
            ;;
        aarch64|arm64)
            echo -e "  ✅ arm64 (Native)"
            echo -e "  ✅ armv7 (Compatible)"
            echo -e "  ⚠️  amd64 (via emulation, slow)"
            ;;
        armv7l)
            echo -e "  ✅ armv7 (Native)"
            echo -e "  ✅ armhf (Compatible)"
            echo -e "  ❌ amd64 (Not supported)"
            ;;
    esac
    
    echo
    echo -e "${BOLD}🌐 Multi-Arch Images Available:${RESET}"
    echo -e "  • docker.io/library/nginx:latest"
    echo -e "  • docker.io/library/ubuntu:latest"
    echo -e "  • docker.io/library/alpine:latest"
    echo -e "  • docker.io/library/node:lts"
    echo -e "  • docker.io/library/postgres:latest"
    
    echo
    echo -e "${BOLD}💡 Tips:${RESET}"
    echo -e "  • Use 'docker pull --platform' for specific architectures"
    echo -e "  • Build multi-arch images with Buildx"
    echo -e "  • Test compatibility with different base images"
}

auto_detect_development_stacks() {
    print_status "DETECT" "Auto-detecting development stacks..."
    
    echo -e "${BOLD}${FG_BLUE}🔧 Development Stack Detection${RESET}\n"
    
    local detected=()
    
    # Check for programming languages
    if command -v python3 &>/dev/null || [ -f "requirements.txt" ]; then
        detected+=("Python $(python3 --version 2>/dev/null | awk '{print $2}')")
    fi
    
    if command -v node &>/dev/null || [ -f "package.json" ]; then
        detected+=("Node.js $(node --version 2>/dev/null)")
    fi
    
    if command -v java &>/dev/null || [ -f "pom.xml" ]; then
        detected+=("Java")
    fi
    
    if command -v php &>/dev/null || [ -f "composer.json" ]; then
        detected+=("PHP $(php --version 2>/dev/null | head -1 | awk '{print $2}')")
    fi
    
    if command -v go &>/dev/null || [ -f "go.mod" ]; then
        detected+=("Go $(go version 2>/dev/null | awk '{print $3}')")
    fi
    
    if command -v ruby &>/dev/null || [ -f "Gemfile" ]; then
        detected+=("Ruby $(ruby --version 2>/dev/null | awk '{print $2}')")
    fi
    
    # Databases
    if command -v mysql &>/dev/null; then
        detected+=("MySQL")
    fi
    
    if command -v psql &>/dev/null; then
        detected+=("PostgreSQL")
    fi
    
    # Web servers
    if command -v nginx &>/dev/null; then
        detected+=("Nginx")
    fi
    
    if command -v apache2 &>/dev/null || command -v httpd &>/dev/null; then
        detected+=("Apache")
    fi
    
    # Display results
    if [ ${#detected[@]} -gt 0 ]; then
        echo -e "${BOLD}✅ Detected:${RESET}"
        for item in "${detected[@]}"; do
            echo -e "  🛠️  $item"
        done
    else
        echo -e "${BOLD}ℹ️  No development stacks detected${RESET}"
        echo -e "  Try navigating to a project directory"
    fi
    
    echo
    echo -e "${BOLD}📦 Suggested Docker Images:${RESET}"
    
    # Suggest images based on detected stacks
    for item in "${detected[@]}"; do
        case $item in
            Python*)
                echo -e "  💡 python:3.11-slim - Lightweight Python"
                echo -e "  💡 python:3.11-alpine - Minimal Python"
                ;;
            Node*)
                echo -e "  💡 node:18-alpine - Node.js LTS"
                echo -e "  💡 node:current - Latest Node.js"
                ;;
            Java*)
                echo -e "  💡 openjdk:17-jdk-slim - Java 17"
                echo -e "  💡 openjdk:11-jre-slim - Java 11 Runtime"
                ;;
            PHP*)
                echo -e "  💡 php:8.2-apache - PHP with Apache"
                echo -e "  💡 php:8.2-fpm - PHP-FPM"
                ;;
            Go*)
                echo -e "  💡 golang:1.20-alpine - Go on Alpine"
                ;;
            MySQL*)
                echo -e "  💡 mysql:8.0 - MySQL Database"
                ;;
            PostgreSQL*)
                echo -e "  💡 postgres:15-alpine - PostgreSQL"
                ;;
            Nginx*)
                echo -e "  💡 nginx:alpine - Lightweight web server"
                ;;
            Apache*)
                echo -e "  💡 httpd:alpine - Apache on Alpine"
                ;;
        esac
    done | head -10  # Limit suggestions
}

auto_suggest_os_specific_commands() {
    detect_linux_distribution
    
    echo -e "${BOLD}${FG_BLUE}${OS_LOGO} ${OS_NAME}-Specific Commands${RESET}\n"
    
    case $OS_PACKAGE_MANAGER in
        apt)
            echo -e "${BOLD}📦 Install Docker:${RESET}"
            echo -e "  sudo apt update"
            echo -e "  sudo apt install docker.io docker-compose"
            echo -e "  sudo systemctl start docker"
            echo -e "  sudo usermod -aG docker \$USER"
            ;;
        dnf|yum)
            echo -e "${BOLD}📦 Install Docker:${RESET}"
            echo -e "  sudo dnf install docker docker-compose"
            echo -e "  sudo systemctl start docker"
            echo -e "  sudo systemctl enable docker"
            ;;
        pacman)
            echo -e "${BOLD}📦 Install Docker:${RESET}"
            echo -e "  sudo pacman -S docker docker-compose"
            echo -e "  sudo systemctl start docker"
            echo -e "  sudo systemctl enable docker"
            ;;
        apk)
            echo -e "${BOLD}📦 Install Docker:${RESET}"
            echo -e "  sudo apk add docker docker-compose"
            echo -e "  sudo service docker start"
            echo -e "  sudo rc-update add docker boot"
            ;;
        zypper)
            echo -e "${BOLD}📦 Install Docker:${RESET}"
            echo -e "  sudo zypper install docker docker-compose"
            echo -e "  sudo systemctl start docker"
            echo -e "  sudo systemctl enable docker"
            ;;
        *)
            echo -e "${BOLD}📦 Universal Installation:${RESET}"
            echo -e "  curl -fsSL https://get.docker.com | sh"
            echo -e "  sudo systemctl start docker"
            echo -e "  sudo usermod -aG docker \$USER"
            ;;
    esac
    
    echo
    echo -e "${BOLD}🔧 Common Docker Commands:${RESET}"
    echo -e "  docker ps                          # List containers"
    echo -e "  docker images                      # List images"
    echo -e "  docker run -it ubuntu bash        # Run Ubuntu container"
    echo -e "  docker build -t myapp .           # Build image"
}

# ===== Detection Menu =====
detection_menu() {
    while true; do
        print_header
        
        detect_linux_distribution
        
        echo -e "${BOLD}${FG_BLUE}${AI_ICON} AI Auto-Detection Center${RESET}"
        echo -e "${DIM}${OS_LOGO} Running on: ${OS_NAME} ${OS_VERSION}${RESET}\n"
        
        print_menu_item 1 "🐧" "Complete OS Analysis" "Detailed system analysis"
        print_menu_item 2 "📦" "OS-Specific Images" "Optimal images for your OS"
        print_menu_item 3 "🌍" "Multi-OS Compatibility" "Cross-platform support"
        print_menu_item 4 "🛠️" "Development Stack Detect" "Auto-detect dev tools"
        print_menu_item 5 "💻" "OS-Specific Commands" "${OS_NAME}-specific Docker commands"
        print_menu_item 6 "🏠" "Back to Main Menu" "Return to main menu"
        
        echo
        read -rp "$(print_status "INPUT" "Select option (1-6): ")" detect_opt
        
        case $detect_opt in
            1) display_os_info; pause ;;
            2) auto_detect_os_images; pause ;;
            3) auto_detect_multios_compatibility; pause ;;
            4) auto_detect_development_stacks; pause ;;
            5) auto_suggest_os_specific_commands; pause ;;
            6) return ;;
            *)
                print_status "ERROR" "Invalid option!"
                sleep 1
                ;;
        esac
    done
}

# ===== Docker Check =====
check_docker() {
    if ! command -v docker &>/dev/null; then
        print_header
        print_status "ERROR" "Docker not found!"
        echo
        
        detect_linux_distribution
        
        echo -e "${BOLD}${FG_BLUE}${OS_LOGO} Detected: ${OS_NAME} ${OS_VERSION}${RESET}"
        echo -e "${BOLD}Package Manager: ${OS_PACKAGE_MANAGER}${RESET}\n"
        
        auto_suggest_os_specific_commands
        
        echo -e "\n${FG_YELLOW}⚠️  After installing Docker, logout and login again${RESET}"
        echo -e "${FG_YELLOW}   or run: newgrp docker${RESET}"
        
        exit 1
    fi
}

# ===== Main Menu =====
main_menu() {
    check_docker
    
    while true; do
        print_header
        
        detect_linux_distribution
        
        # Get Docker stats
        local running=$(docker ps -q 2>/dev/null | wc -l)
        local total=$(docker ps -aq 2>/dev/null | wc -l)
        local images=$(docker images -q 2>/dev/null | wc -l)
        
        echo -e "${BOLD}${FG_CYAN}${OS_LOGO} ${OS_NAME} ${OS_VERSION}${RESET} ${DIM}| ${AI_ICON} AI Auto-Detect${RESET}"
        echo -e "${DIM}══════════════════════════════════════════════════════════════════════════════${RESET}\n"
        
        echo -e "${BOLD}📊 Quick Stats:${RESET}"
        echo -e "  🐳 Containers: ${BOLD}${FG_GREEN}$running${RESET} running / ${BOLD}$total${RESET} total"
        echo -e "  📦 Images: ${BOLD}$images${RESET}"
        echo -e "  💻 OS: ${BOLD}${OS_NAME}${RESET}"
        echo -e "  🏗️  Arch: ${BOLD}${OS_ARCH}${RESET}"
        echo
        
        # Menu options
        print_menu_item 1 "${AI_ICON}" "AI Auto-Detection Center" "Smart analysis & OS detection"
        print_menu_item 2 "📋" "List Containers" "Show all containers"
        print_menu_item 3 "🚀" "Start Container" "Start a container"
        print_menu_item 4 "🛑" "Stop Container" "Stop a container"
        print_menu_item 5 "🔄" "Restart Container" "Restart a container"
        print_menu_item 6 "🗑️" "Delete Container" "Delete a container"
        print_menu_item 7 "📜" "View Logs" "View container logs"
        print_menu_item 8 "⚡" "Quick Run" "Auto-run container"
        print_menu_item 9 "📦" "Image Manager" "Manage Docker images"
        print_menu_item 10 "🔧" "Advanced Create" "Create container"
        print_menu_item 11 "📈" "System Stats" "Docker statistics"
        print_menu_item 12 "🧹" "Cleanup System" "Clean Docker system"
        print_menu_item 13 "👋" "Exit" "Exit program"
        
        echo
        read -rp "$(print_status "INPUT" "Select option (1-13): ")" opt
        
        case $opt in
            1) detection_menu ;;
            2) 
                print_status "INFO" "Listing containers..."
                docker ps -a
                pause
                ;;
            3)
                read -rp "$(print_status "INPUT" "Container name to start: ")" container
                docker start "$container"
                pause
                ;;
            4)
                read -rp "$(print_status "INPUT" "Container name to stop: ")" container
                docker stop "$container"
                pause
                ;;
            5)
                read -rp "$(print_status "INPUT" "Container name to restart: ")" container
                docker restart "$container"
                pause
                ;;
            6)
                read -rp "$(print_status "INPUT" "Container name to delete: ")" container
                docker rm -f "$container"
                pause
                ;;
            7)
                read -rp "$(print_status "INPUT" "Container name for logs: ")" container
                docker logs -f "$container"
                ;;
            8)
                read -rp "$(print_status "INPUT" "Image to run (e.g., nginx): ")" image
                docker run -d --name "ct-$(date +%H%M%S)" "$image"
                pause
                ;;
            9)
                print_status "INFO" "Listing images..."
                docker images
                pause
                ;;
            10)
                read -rp "$(print_status "INPUT" "Image name: ")" image
                read -rp "$(print_status "INPUT" "Container name: ")" name
                docker run -d --name "$name" "$image"
                pause
                ;;
            11)
                print_status "INFO" "Docker system info..."
                docker system df
                pause
                ;;
            12)
                print_status "INFO" "Cleaning up..."
                docker system prune -f
                pause
                ;;
            13)
                print_header
                echo -e "${FG_GREEN}${BOLD}"
                echo "╔══════════════════════════════════════════════════════════════════════════════╗"
                echo "║                     👋 Goodbye!                                           ║"
                echo "║                 Docker Manager Pro v4.0                                   ║"
                echo "║                 ${AI_ICON} AI Auto-Detect System                               ║"
                echo "╚══════════════════════════════════════════════════════════════════════════════╝"
                echo -e "${RESET}"
                exit 0
                ;;
            *)
                print_status "ERROR" "Invalid option!"
                sleep 1
                ;;
        esac
    done
}

# ===== Start Application =====
main_menu
