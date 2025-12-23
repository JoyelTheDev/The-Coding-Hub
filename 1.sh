#!/bin/bash

# ==============================
# Enhanced Docker Manager with UI
# ==============================

set -euo pipefail

# ===== Colors and Styles =====
BG_BLUE="\e[44m"
BG_GREEN="\e[42m"
BG_RED="\e[41m"
BG_YELLOW="\e[43m"
BG_CYAN="\e[46m"

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
BOX_T="┬"
BOX_T_INV="┴"
BOX_CROSS="┼"
BOX_ARROW_R="▶"
BOX_ARROW_L="◀"

# ===== Functions =====
print_header() {
    clear
    echo -e "${BG_CYAN}${FG_BLACK}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   🐳 DOCKER MANAGER PRO                     ║"
    echo "╚══════════════════════════════════════════════════════════════╝${RESET}"
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
    
    echo -e "${color}${BOX_VERT}${RESET} ${BOLD}${title}${RESET}"
    echo -e "${color}${BOX_VERT}${RESET}"
    
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
    echo -ne "${FG_CYAN}⏳${RESET} ${msg}"
    for i in {1..3}; do
        echo -ne "."
        sleep 0.3
    done
    echo -e "${FG_GREEN} Done!${RESET}"
}

# ===== Root Check =====
if [ "$EUID" -ne 0 ]; then
    print_header
    print_status "ERROR" "This script requires root privileges"
    echo -e "${FG_YELLOW}🔓 Please run with:${RESET} ${BOLD}sudo -i${RESET}"
    exit 1
fi

# ===== Docker Check =====
check_docker() {
    if ! command -v docker &>/dev/null; then
        print_header
        print_status "WARN" "Docker not found. Installing..."
        echo
        print_box 60 "Docker Installation" "${FG_BLUE}" "This will install Docker and Docker Compose"
        
        read -rp "$(echo -e "${FG_YELLOW}❓${RESET} Proceed with Docker installation? (y/N): ")" -n 1
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            loading "Installing Docker"
            curl -fsSL https://get.docker.com | sh
            systemctl enable --now docker
            loading "Installing Docker Compose"
            apt-get install -y docker-compose-plugin
            print_status "SUCCESS" "Docker installed successfully!"
            pause
        else
            print_status "ERROR" "Docker is required for this script"
            exit 1
        fi
    fi
}

# ===== Container Operations =====
list_containers() {
    print_header
    print_status "INFO" "Listing all containers"
    echo
    
    local running=$(docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | head -1)
    local stopped=$(docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | head -1)
    
    echo -e "${BOLD}${FG_GREEN}🚀 Running Containers:${RESET}"
    if [ $(docker ps -q | wc -l) -gt 0 ]; then
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    else
        echo -e "${DIM}No running containers${RESET}"
    fi
    
    echo
    echo -e "${BOLD}${FG_YELLOW}💤 Stopped Containers:${RESET}"
    if [ $(docker ps -a -q | wc -l) -gt $(docker ps -q | wc -l) ]; then
        docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | tail -n +2
    else
        echo -e "${DIM}No stopped containers${RESET}"
    fi
    
    echo
    echo -e "${BOLD}📊 Statistics:${RESET}"
    echo -e "  Total: $(docker ps -a -q | wc -l) containers"
    echo -e "  Running: $(docker ps -q | wc -l) containers"
    echo -e "  Stopped: $(($(docker ps -a -q | wc -l) - $(docker ps -q | wc -l))) containers"
}

start_container() {
    print_header
    print_status "INFO" "Starting a container"
    echo
    
    local containers=($(docker ps -a --format "{{.Names}}" | sort))
    if [ ${#containers[@]} -eq 0 ]; then
        print_status "WARN" "No containers found"
        pause
        return
    fi
    
    echo -e "${BOLD}Available containers:${RESET}"
    for i in "${!containers[@]}"; do
        local status=$(docker inspect -f '{{.State.Status}}' "${containers[$i]}")
        local color="${FG_RED}"
        [[ "$status" == "running" ]] && color="${FG_GREEN}"
        printf "  ${FG_CYAN}%2d)${RESET} ${color}%-20s${RESET} [%s]\n" $((i+1)) "${containers[$i]}" "$status"
    done
    
    echo
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Select container (number or name): ")" choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#containers[@]} ]; then
        local container="${containers[$((choice-1))]}"
    else
        local container="$choice"
    fi
    
    loading "Starting container: $container"
    if docker start "$container" &>/dev/null; then
        print_status "SUCCESS" "Container '$container' started successfully!"
    else
        print_status "ERROR" "Failed to start container '$container'"
    fi
}

stop_container() {
    print_header
    print_status "INFO" "Stopping a container"
    echo
    
    local containers=($(docker ps --format "{{.Names}}" | sort))
    if [ ${#containers[@]} -eq 0 ]; then
        print_status "WARN" "No running containers found"
        pause
        return
    fi
    
    echo -e "${BOLD}Running containers:${RESET}"
    for i in "${!containers[@]}"; do
        printf "  ${FG_CYAN}%2d)${RESET} %-20s\n" $((i+1)) "${containers[$i]}"
    done
    
    echo
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Select container (number or name): ")" choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#containers[@]} ]; then
        local container="${containers[$((choice-1))]}"
    else
        local container="$choice"
    fi
    
    loading "Stopping container: $container"
    if docker stop "$container" &>/dev/null; then
        print_status "SUCCESS" "Container '$container' stopped successfully!"
    else
        print_status "ERROR" "Failed to stop container '$container'"
    fi
}

restart_container() {
    print_header
    print_status "INFO" "Restarting a container"
    echo
    
    local containers=($(docker ps -a --format "{{.Names}}" | sort))
    if [ ${#containers[@]} -eq 0 ]; then
        print_status "WARN" "No containers found"
        pause
        return
    fi
    
    echo -e "${BOLD}Available containers:${RESET}"
    for i in "${!containers[@]}"; do
        local status=$(docker inspect -f '{{.State.Status}}' "${containers[$i]}")
        local color="${FG_RED}"
        [[ "$status" == "running" ]] && color="${FG_GREEN}"
        printf "  ${FG_CYAN}%2d)${RESET} ${color}%-20s${RESET} [%s]\n" $((i+1)) "${containers[$i]}" "$status"
    done
    
    echo
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Select container (number or name): ")" choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#containers[@]} ]; then
        local container="${containers[$((choice-1))]}"
    else
        local container="$choice"
    fi
    
    loading "Restarting container: $container"
    if docker restart "$container" &>/dev/null; then
        print_status "SUCCESS" "Container '$container' restarted successfully!"
    else
        print_status "ERROR" "Failed to restart container '$container'"
    fi
}

delete_container() {
    print_header
    print_status "WARN" "Deleting a container"
    echo
    
    local containers=($(docker ps -a --format "{{.Names}}" | sort))
    if [ ${#containers[@]} -eq 0 ]; then
        print_status "WARN" "No containers found"
        pause
        return
    fi
    
    echo -e "${BOLD}Available containers:${RESET}"
    for i in "${!containers[@]}"; do
        local status=$(docker inspect -f '{{.State.Status}}' "${containers[$i]}")
        local color="${FG_RED}"
        [[ "$status" == "running" ]] && color="${FG_GREEN}"
        printf "  ${FG_CYAN}%2d)${RESET} ${color}%-20s${RESET} [%s]\n" $((i+1)) "${containers[$i]}" "$status"
    done
    
    echo
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Select container (number or name): ")" choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#containers[@]} ]; then
        local container="${containers[$((choice-1))]}"
    else
        local container="$choice"
    fi
    
    echo -e "\n${FG_RED}⚠️  WARNING:${RESET} This will delete container '${BOLD}$container${RESET}'"
    read -rp "$(echo -e "${FG_YELLOW}❓${RESET} Are you sure? Type 'yes' to confirm: ")" confirm
    
    if [[ "$confirm" == "yes" ]]; then
        loading "Deleting container: $container"
        if docker rm -f "$container" &>/dev/null; then
            print_status "SUCCESS" "Container '$container' deleted successfully!"
        else
            print_status "ERROR" "Failed to delete container '$container'"
        fi
    else
        print_status "INFO" "Deletion cancelled"
    fi
}

view_logs() {
    print_header
    print_status "INFO" "Viewing container logs"
    echo
    
    local containers=($(docker ps -a --format "{{.Names}}" | sort))
    if [ ${#containers[@]} -eq 0 ]; then
        print_status "WARN" "No containers found"
        pause
        return
    fi
    
    echo -e "${BOLD}Available containers:${RESET}"
    for i in "${!containers[@]}"; do
        local status=$(docker inspect -f '{{.State.Status}}' "${containers[$i]}")
        local color="${FG_RED}"
        [[ "$status" == "running" ]] && color="${FG_GREEN}"
        printf "  ${FG_CYAN}%2d)${RESET} ${color}%-20s${RESET} [%s]\n" $((i+1)) "${containers[$i]}" "$status"
    done
    
    echo
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Select container (number or name): ")" choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#containers[@]} ]; then
        local container="${containers[$((choice-1))]}"
    else
        local container="$choice"
    fi
    
    print_status "INFO" "Showing logs for '$container' (Press Ctrl+C to exit)"
    echo -e "${DIM}══════════════════════════════════════════════════════════════${RESET}"
    
    if docker logs -f "$container"; then
        echo -e "${DIM}══════════════════════════════════════════════════════════════${RESET}"
        echo -e "${FG_CYAN}📋 Log stream ended${RESET}"
    fi
}

quick_run() {
    print_header
    print_status "INFO" "Quick Run - Auto Port Detect"
    echo
    
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Image name (e.g., nginx, redis:alpine): ")" img
    
    if [ -z "$img" ]; then
        print_status "ERROR" "Image name cannot be empty"
        pause
        return
    fi
    
    local cname="ct-$(date +%H%M%S)"
    
    print_box 60 "Quick Run Configuration" "${FG_BLUE}" \
        "Image: ${BOLD}$img${RESET}\n"\
        "Name: ${BOLD}$cname${RESET}\n"\
        "Auto-port detection: ${BOLD}Enabled${RESET}"
    
    loading "Pulling image: $img"
    if ! docker pull "$img" &>/dev/null; then
        print_status "ERROR" "Failed to pull image '$img'"
        pause
        return
    fi
    
    # Try to get exposed ports
    local ports=$(docker inspect --format='{{range $p,$v := .Config.ExposedPorts}}{{println $p}}{{end}}' "$img" 2>/dev/null | head -5)
    
    local CMD="docker run -d --name $cname --restart unless-stopped"
    
    if [ -n "$ports" ]; then
        echo -e "\n${FG_GREEN}🔍 Found exposed ports:${RESET}"
        for p in $ports; do
            local port_num=$(echo "$p" | cut -d'/' -f1)
            echo -e "  ${FG_CYAN}➜${RESET} Port $port_num"
            CMD="$CMD -p $port_num:$port_num"
        done
    else
        echo -e "\n${FG_YELLOW}⚠️  No exposed ports found, using random port mapping${RESET}"
        CMD="$CMD -P"
    fi
    
    CMD="$CMD $img"
    
    echo -e "\n${BOLD}Command to execute:${RESET}"
    echo -e "${DIM}$CMD${RESET}"
    echo
    
    read -rp "$(echo -e "${FG_YELLOW}❓${RESET} Proceed? (y/N): ")" -n 1
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        loading "Creating container: $cname"
        if eval "$CMD" &>/dev/null; then
            print_status "SUCCESS" "Container '$cname' created and started successfully!"
            echo -e "${FG_CYAN}📊 Container info:${RESET}"
            docker ps --filter "name=$cname" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
        else
            print_status "ERROR" "Failed to create container"
        fi
    else
        print_status "INFO" "Operation cancelled"
    fi
}

list_images() {
    print_header
    print_status "INFO" "Listing Docker images"
    echo
    
    echo -e "${BOLD}📦 Available Images:${RESET}"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedSince}}"
    
    echo
    echo -e "${BOLD}📊 Statistics:${RESET}"
    echo -e "  Total images: $(docker images -q | wc -l)"
    echo -e "  Total size: $(docker system df --format '{{.ImagesSize}}')"
    
    echo
    read -rp "$(echo -e "${FG_YELLOW}❓${RESET} Remove unused images? (y/N): ")" -n 1
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        loading "Cleaning up unused images"
        docker image prune -f
        print_status "SUCCESS" "Unused images cleaned up!"
    fi
}

advanced_create() {
    print_header
    print_status "INFO" "Advanced Container Creation"
    echo
    
    # Container name
    local cname="ct-$(date +%H%M%S)"
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Container Name (blank for auto: $cname): ")" input_name
    [ -n "$input_name" ] && cname="$input_name"
    
    # Image name
    while true; do
        read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Image Name (required): ")" img
        if [ -n "$img" ]; then
            break
        fi
        print_status "ERROR" "Image name cannot be empty"
    done
    
    # Volumes
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Volume mount (e.g., /host:/container): ")" vol
    
    # Environment variables
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Environment variables (e.g., KEY=value): ")" env
    
    # Network
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Network (blank for bridge): ")" network
    
    # Ports
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Port mapping (e.g., 8080:80): ")" ports
    
    # Pull image first
    loading "Pulling image: $img"
    if ! docker pull "$img" &>/dev/null; then
        print_status "ERROR" "Failed to pull image '$img'"
        pause
        return
    fi
    
    # Build command
    local CMD="docker run -d --name $cname --restart unless-stopped"
    
    [ -n "$vol" ] && CMD="$CMD -v $vol"
    [ -n "$env" ] && CMD="$CMD -e $env"
    [ -n "$network" ] && CMD="$CMD --network $network"
    [ -n "$ports" ] && CMD="$CMD -p $ports"
    
    CMD="$CMD $img"
    
    print_box 60 "Advanced Configuration" "${FG_BLUE}" \
        "Container: ${BOLD}$cname${RESET}\n"\
        "Image: ${BOLD}$img${RESET}\n"\
        "Volume: ${BOLD}${vol:-None}${RESET}\n"\
        "Env: ${BOLD}${env:-None}${RESET}\n"\
        "Network: ${BOLD}${network:-bridge}${RESET}\n"\
        "Ports: ${BOLD}${ports:-Auto}${RESET}"
    
    echo -e "\n${BOLD}Command to execute:${RESET}"
    echo -e "${DIM}$CMD${RESET}"
    echo
    
    read -rp "$(echo -e "${FG_YELLOW}❓${RESET} Create container? (y/N): ")" -n 1
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        loading "Creating container: $cname"
        if eval "$CMD" &>/dev/null; then
            print_status "SUCCESS" "Container '$cname' created successfully!"
            echo -e "${FG_CYAN}📊 Container details:${RESET}"
            docker inspect "$cname" --format '\
Name: {{.Name}}\n\
Status: {{.State.Status}}\n\
Image: {{.Config.Image}}\n\
IP: {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}\n\
Ports: {{range $p, $conf := .NetworkSettings.Ports}}{{$p}} {{end}}\n\
Created: {{.Created}}'
        else
            print_status "ERROR" "Failed to create container"
        fi
    else
        print_status "INFO" "Operation cancelled"
    fi
}

docker_stats() {
    print_header
    print_status "INFO" "Docker System Statistics"
    echo
    
    print_box 60 "System Information" "${FG_BLUE}" \
        "Docker Version: $(docker version --format '{{.Server.Version}}')\n"\
        "Containers: $(docker ps -q | wc -l) running, $(docker ps -a -q | wc -l) total\n"\
        "Images: $(docker images -q | wc -l)\n"\
        "Volumes: $(docker volume ls -q | wc -l)\n"\
        "Networks: $(docker network ls -q | wc -l)"
    
    echo
    echo -e "${BOLD}📈 Resource Usage:${RESET}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
    
    echo
    echo -e "${BOLD}🗑️  Disk Usage:${RESET}"
    docker system df --format 'table {{.Type}}\t{{.TotalCount}}\t{{.Size}}\t{{.Reclaimable}}'
}

cleanup_system() {
    print_header
    print_status "WARN" "Docker System Cleanup"
    echo
    
    print_box 60 "Cleanup Options" "${FG_YELLOW}" \
        "1) Remove stopped containers\n"\
        "2) Remove unused images\n"\
        "3) Remove unused volumes\n"\
        "4) Remove unused networks\n"\
        "5) Remove build cache\n"\
        "6) Full cleanup (everything)"
    
    echo
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Select option (1-6): ")" cleanup_opt
    
    case $cleanup_opt in
        1)
            loading "Removing stopped containers"
            docker container prune -f
            print_status "SUCCESS" "Stopped containers removed"
            ;;
        2)
            loading "Removing unused images"
            docker image prune -af
            print_status "SUCCESS" "Unused images removed"
            ;;
        3)
            loading "Removing unused volumes"
            docker volume prune -f
            print_status "SUCCESS" "Unused volumes removed"
            ;;
        4)
            loading "Removing unused networks"
            docker network prune -f
            print_status "SUCCESS" "Unused networks removed"
            ;;
        5)
            loading "Removing build cache"
            docker builder prune -f
            print_status "SUCCESS" "Build cache removed"
            ;;
        6)
            loading "Performing full cleanup"
            docker system prune -af --volumes
            print_status "SUCCESS" "Full cleanup completed"
            ;;
        *)
            print_status "ERROR" "Invalid option"
            ;;
    esac
}

# ===== Main Menu =====
main_menu() {
    while true; do
        print_header
        
        # Show quick stats
        local running=$(docker ps -q | wc -l)
        local total=$(docker ps -a -q | wc -l)
        local images=$(docker images -q | wc -l)
        
        echo -e "${FG_CYAN}📊 Quick Stats:${RESET}"
        echo -e "  🐳 Containers: ${BOLD}${FG_GREEN}$running${RESET} running / ${BOLD}$total${RESET} total"
        echo -e "  📦 Images: ${BOLD}$images${RESET}"
        echo
        
        # Menu options
        print_menu_item 1 "📋" "List Containers" "Show all containers with details"
        print_menu_item 2 "🚀" "Start Container" "Start a stopped container"
        print_menu_item 3 "🛑" "Stop Container" "Stop a running container"
        print_menu_item 4 "🔄" "Restart Container" "Restart a container"
        print_menu_item 5 "🗑️" "Delete Container" "Remove a container (with force)"
        print_menu_item 6 "📜" "View Logs" "View container logs in real-time"
        print_menu_item 7 "⚡" "Quick Run" "Auto-detect ports and run container"
        print_menu_item 8 "📦" "List Images" "Show all Docker images"
        print_menu_item 9 "🔧" "Advanced Create" "Create container with custom options"
        print_menu_item 10 "📈" "System Stats" "Show Docker system statistics"
        print_menu_item 11 "🧹" "Cleanup System" "Remove unused Docker resources"
        print_menu_item 12 "👋" "Exit" "Exit Docker Manager"
        
        echo
        read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Select option (1-12): ")" opt
        
        case $opt in
            1) list_containers; pause ;;
            2) start_container; pause ;;
            3) stop_container; pause ;;
            4) restart_container; pause ;;
            5) delete_container; pause ;;
            6) view_logs ;;
            7) quick_run; pause ;;
            8) list_images; pause ;;
            9) advanced_create; pause ;;
            10) docker_stats; pause ;;
            11) cleanup_system; pause ;;
            12)
                print_header
                echo -e "${FG_GREEN}${BOLD}"
                echo "╔══════════════════════════════════════════════════════════════╗"
                echo "║                     👋 Goodbye!                            ║"
                echo "║                 Docker Manager Pro                         ║"
                echo "╚══════════════════════════════════════════════════════════════╝"
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

# ===== Main Execution =====
check_docker
main_menu
