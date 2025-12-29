#!/bin/bash

# ============================================
# Docker Container Manager
# Version: 2.0 - Pure Docker Edition
# Author: Nobita
# ============================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ASCII Art Banner
print_banner() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${CYAN}    ____             _               ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${CYAN}   │  _ \  ___   ___│ │ ___  _ __    ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${CYAN}   │ | | │/ _ \ / __│ │/ _ \│ '__│   ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${CYAN}   │ |_│ │ (_) │ (__│ │ (_) ││       ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${CYAN}   │____/ \___/ \___│_|\___/│_│       ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${WHITE}            Docker Container Manager              ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${YELLOW}                  Pure Docker Edition                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Function to print header
print_header() {
    print_banner
    print_color "$CYAN" "════════════════════════════════════════════════════════════"
    print_color "$WHITE" "                         $1"
    print_color "$CYAN" "════════════════════════════════════════════════════════════"
    echo ""
}

# Progress bar function
show_progress() {
    local pid=$1
    local msg=$2
    local delay=0.1
    local spinstr='|/-\'
    
    print_color "$CYAN" "$msg"
    printf "["
    
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "%c" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b"
    done
    
    printf "\b] "
    print_color "$GREEN" "✓"
}

# Enhanced Docker image database
declare -A DOCKER_IMAGES=(
    ["1"]="ubuntu:22.04|Ubuntu 22.04 Jammy|LTS, Stable"
    ["2"]="ubuntu:24.04|Ubuntu 24.04 Noble|Latest LTS"
    ["3"]="debian:12|Debian 12 Bookworm|Stable"
    ["4"]="debian:11|Debian 11 Bullseye|Old Stable"
    ["5"]="centos:9|CentOS Stream 9|Enterprise"
    ["6"]="rockylinux:9|Rocky Linux 9|RHEL Compatible"
    ["7"]="almalinux:9|AlmaLinux 9|RHEL Fork"
    ["8"]="fedora:40|Fedora 40|Latest Features"
    ["9"]="archlinux:latest|Arch Linux|Rolling Release"
    ["10"]="alpine:latest|Alpine Linux|Lightweight (5MB)"
    ["11"]="oraclelinux:9|Oracle Linux 9|Enterprise"
    ["12"]="amazonlinux:2023|Amazon Linux 2023|AWS Optimized"
    ["13"]="nginx:latest|Nginx Web Server|Production Ready"
    ["14"]="httpd:latest|Apache HTTP Server|Web Server"
    ["15"]="mysql:8.0|MySQL 8.0|Database"
    ["16"]="postgres:16|PostgreSQL 16|Database"
    ["17"]="redis:latest|Redis|In-memory Database"
    ["18"]="node:20|Node.js 20|JavaScript Runtime"
    ["19"]="python:3.12|Python 3.12|Programming Language"
    ["20"]="golang:1.21|Go 1.21|Programming Language"
    ["21"]="php:8.2|PHP 8.2|Web Development"
    ["22"]="java:21|Java 21 OpenJDK|JVM Language"
    ["23"]="ruby:3.2|Ruby 3.2|Programming Language"
    ["24"]="wordpress:latest|WordPress|CMS"
    ["25"]="jenkins/jenkins:lts|Jenkins|CI/CD"
    ["26"]="gitlab/gitlab-ce:latest|GitLab CE|DevOps Platform"
    ["27"]="portainer/portainer-ce|Portainer CE|Docker Management UI"
    ["28"]="traefik:latest|Traefik|Reverse Proxy"
    ["29"]="grafana/grafana:latest|Grafana|Monitoring"
    ["30"]="prom/prometheus:latest|Prometheus|Monitoring"
)

# Network modes
declare -A NETWORK_MODES=(
    ["1"]="bridge|Default bridge network"
    ["2"]="host|Share host's network namespace"
    ["3"]="none|No networking"
    ["4"]="container:NAME|Share network with another container"
)

# Volume types
declare -A VOLUME_TYPES=(
    ["1"]="volume|Docker managed volume"
    ["2"]="bind|Bind mount (host directory)"
    ["3"]="tmpfs|Temporary filesystem (RAM)"
)

# Restart policies
declare -A RESTART_POLICIES=(
    ["1"]="no|Do not automatically restart"
    ["2"]="always|Always restart"
    ["3"]="on-failure|Restart on failure"
    ["4"]="unless-stopped|Restart unless explicitly stopped"
)

# Check Docker installation
check_docker_installation() {
    print_color "$CYAN" "🔍 Checking Docker installation..."
    
    if ! command -v docker &> /dev/null; then
        print_color "$RED" "❌ Docker is not installed!"
        echo ""
        print_color "$YELLOW" "📦 Would you like to install Docker now?"
        read -p "   Install Docker? (Y/n): " install_choice
        
        if [[ "$install_choice" =~ ^[Yy]?$ ]]; then
            install_docker
        else
            print_color "$RED" "❌ Docker is required for this script!"
            exit 1
        fi
    fi
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        print_color "$RED" "❌ Docker daemon is not running!"
        echo ""
        print_color "$YELLOW" "💡 Try starting Docker:"
        echo "   sudo systemctl start docker"
        echo "   sudo systemctl enable docker"
        exit 1
    fi
    
    print_color "$GREEN" "✅ Docker is installed and running!"
    echo ""
}

# Install Docker
install_docker() {
    print_header "📦 Installing Docker"
    
    # Detect distribution
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_NAME=$ID
    else
        print_color "$RED" "❌ Cannot detect OS distribution!"
        exit 1
    fi
    
    print_color "$BLUE" "📊 Detected: $PRETTY_NAME"
    echo ""
    
    case $OS_NAME in
        ubuntu|debian|linuxmint|pop)
            install_docker_debian
            ;;
        fedora|centos|rhel|rocky|almalinux)
            install_docker_rhel
            ;;
        arch|manjaro)
            install_docker_arch
            ;;
        *)
            print_color "$RED" "❌ Unsupported OS: $OS_NAME"
            show_docker_manual_install
            ;;
    esac
}

# Install Docker on Debian-based systems
install_docker_debian() {
    print_color "$GREEN" "📦 Installing Docker on Debian-based system..."
    echo ""
    
    # Remove old versions
    print_color "$CYAN" "🧹 Removing old Docker versions..."
    sudo apt-get remove -y docker docker-engine docker.io containerd runc
    
    # Update packages
    print_color "$CYAN" "🔄 Updating package lists..."
    sudo apt-get update
    
    # Install dependencies
    print_color "$CYAN" "📦 Installing dependencies..."
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker GPG key
    print_color "$CYAN" "🔑 Adding Docker GPG key..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    print_color "$CYAN" "📦 Adding Docker repository..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    print_color "$CYAN" "📥 Installing Docker..."
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Add user to docker group
    print_color "$CYAN" "👤 Adding user to docker group..."
    sudo usermod -aG docker $USER
    
    print_color "$GREEN" "✅ Docker installed successfully!"
    echo ""
    print_color "$YELLOW" "⚠️  IMPORTANT: Log out and log back in for group changes to take effect!"
    echo ""
    
    read -p "📝 Press Enter to continue..."
}

# Install Docker on RHEL-based systems
install_docker_rhel() {
    print_color "$GREEN" "📦 Installing Docker on RHEL-based system..."
    echo ""
    
    # Remove old versions
    print_color "$CYAN" "🧹 Removing old Docker versions..."
    sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
    
    # Install dependencies
    print_color "$CYAN" "📦 Installing dependencies..."
    sudo yum install -y yum-utils
    
    # Add Docker repository
    print_color "$CYAN" "📦 Adding Docker repository..."
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    # Install Docker
    print_color "$CYAN" "📥 Installing Docker..."
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Start and enable Docker
    print_color "$CYAN" "▶️ Starting Docker service..."
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add user to docker group
    print_color "$CYAN" "👤 Adding user to docker group..."
    sudo usermod -aG docker $USER
    
    print_color "$GREEN" "✅ Docker installed successfully!"
    echo ""
    print_color "$YELLOW" "⚠️  IMPORTANT: Log out and log back in for group changes to take effect!"
    echo ""
    
    read -p "📝 Press Enter to continue..."
}

# Show system information
show_system_info() {
    print_header "📊 System Information"
    
    print_color "$YELLOW" "🐳 Docker Information:"
    echo "──────────────────────────────────────"
    if command -v docker &> /dev/null; then
        echo -n "📦 Docker Version: "
        docker --version
        
        echo -n "📦 Docker Compose: "
        if command -v docker-compose &> /dev/null; then
            docker-compose --version
        elif docker compose version &> /dev/null; then
            docker compose version
        else
            echo "Not installed"
        fi
        
        # Container statistics
        local total_containers=$(docker ps -a -q | wc -l)
        local running_containers=$(docker ps -q | wc -l)
        echo "📦 Containers: $running_containers running, $total_containers total"
        
        # Image statistics
        local total_images=$(docker images -q | wc -l)
        echo "📷 Images: $total_images"
        
        # Volume statistics
        local total_volumes=$(docker volume ls -q | wc -l)
        echo "💾 Volumes: $total_volumes"
        
        # Network statistics
        local total_networks=$(docker network ls -q | wc -l)
        echo "🌐 Networks: $total_networks"
    else
        echo "❌ Docker not installed"
    fi
    
    echo ""
    print_color "$YELLOW" "💻 System Information:"
    echo "──────────────────────────────────────"
    
    # OS info
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "🏷️  OS: $PRETTY_NAME"
    fi
    
    # Kernel
    echo "🐧 Kernel: $(uname -r)"
    
    # Resources
    echo "⚡ CPU: $(nproc) cores"
    echo "💾 RAM: $(free -h | awk '/^Mem:/ {print $2}') total"
    echo "💿 Disk: $(df -h / | awk 'NR==2 {print $4}') free"
    
    echo ""
    print_color "$CYAN" "🔧 Quick Commands:"
    echo "  docker ps -a                         # List all containers"
    echo "  docker images                        # List all images"
    echo "  docker volume ls                     # List all volumes"
    echo "  docker network ls                    # List all networks"
    echo "  docker stats                         # Show container stats"
    echo "  docker system df                     # Show Docker disk usage"
    
    read -p "⏎ Press Enter to continue..."
}

# Create Docker container
create_docker_container() {
    print_header "🚀 Create Docker Container"
    
    # Container name
    while true; do
        read -p "🏷️  Enter container name: " container_name
        
        if [[ -z "$container_name" ]]; then
            print_color "$RED" "❌ Container name cannot be empty!"
            continue
        fi
        
        # Check if container already exists
        if docker ps -a --format "{{.Names}}" | grep -q "^${container_name}$"; then
            print_color "$RED" "❌ Container '$container_name' already exists!"
            read -p "🔄 Use different name? (y/N): " rename_choice
            if [[ ! "$rename_choice" =~ ^[Yy]$ ]]; then
                return
            fi
            continue
        fi
        
        break
    done
    
    # Select image
    select_docker_image
    
    # Container configuration
    configure_docker_container "$container_name"
    
    # Build Docker command
    build_docker_command "$container_name"
    
    # Execute
    execute_docker_command "$container_name"
}

# Select Docker image
select_docker_image() {
    while true; do
        print_header "📦 Select Docker Image"
        
        # Categorized display
        print_color "$BLUE" "Operating Systems:"
        for key in {1..12}; do
            if [[ -n "${DOCKER_IMAGES[$key]}" ]]; then
                IFS='|' read -r image_name display_name description <<< "${DOCKER_IMAGES[$key]}"
                printf "  ${GREEN}%2d)${NC} %-25s ${CYAN}%-40s${NC}\n" "$key" "$display_name" "$description"
            fi
        done
        
        echo ""
        print_color "$BLUE" "Applications & Services:"
        for key in {13..30}; do
            if [[ -n "${DOCKER_IMAGES[$key]}" ]]; then
                IFS='|' read -r image_name display_name description <<< "${DOCKER_IMAGES[$key]}"
                printf "  ${GREEN}%2d)${NC} %-25s ${CYAN}%-40s${NC}\n" "$key" "$display_name" "$description"
            fi
        done
        
        echo ""
        print_color "$GREEN" "s) 🔍 Search Docker Hub"
        print_color "$GREEN" "c) 📝 Enter custom image"
        print_color "$RED"   "0) ↩️  Back to Main Menu"
        echo ""
        
        read -p "🎯 Select image (1-30) or option: " image_choice
        
        case $image_choice in
            0)
                return 1
                ;;
            s|S)
                search_docker_hub
                continue
                ;;
            c|C)
                read -p "📦 Enter custom Docker image (e.g., nginx:alpine): " custom_image
                if [[ -n "$custom_image" ]]; then
                    image_name="$custom_image"
                    display_name="Custom: $custom_image"
                    break
                fi
                ;;
            *)
                if [[ -n "${DOCKER_IMAGES[$image_choice]}" ]]; then
                    IFS='|' read -r image_name display_name description <<< "${DOCKER_IMAGES[$image_choice]}"
                    break
                else
                    print_color "$RED" "❌ Invalid selection!"
                    sleep 1
                fi
                ;;
        esac
    done
    return 0
}

# Search Docker Hub
search_docker_hub() {
    print_header "🔍 Search Docker Hub"
    
    read -p "🔎 Enter search term: " search_term
    if [[ -z "$search_term" ]]; then
        return
    fi
    
    print_color "$CYAN" "🔍 Searching Docker Hub for '$search_term'..."
    
    # Try to search using Docker Hub API
    local results_file="/tmp/docker_search_$$.json"
    
    # Note: Docker Hub API requires authentication for extensive searches
    # This is a simple implementation
    print_color "$YELLOW" "📡 Note: Limited search results without Docker Hub authentication"
    echo ""
    
    # Try to pull image list from local cache
    print_color "$BLUE" "📋 Local matches:"
    local found=0
    for key in "${!DOCKER_IMAGES[@]}"; do
        IFS='|' read -r img_name img_display img_desc <<< "${DOCKER_IMAGES[$key]}"
        if [[ "$img_name" =~ $search_term ]] || [[ "$img_display" =~ $search_term ]] || [[ "$img_desc" =~ $search_term ]]; then
            printf "  ${GREEN}%2d)${NC} %-25s ${CYAN}%-40s${NC}\n" "$key" "$img_display" "$img_desc"
            found=1
        fi
    done
    
    if [[ $found -eq 0 ]]; then
        print_color "$YELLOW" "⚠️  No local matches found for '$search_term'"
    fi
    
    echo ""
    print_color "$YELLOW" "💡 Tip: You can use 'docker search $search_term' in terminal"
    echo "      Or visit: https://hub.docker.com/search?q=$search_term"
    
    read -p "⏎ Press Enter to continue..."
}

# Configure Docker container
configure_docker_container() {
    local container_name=$1
    
    print_header "⚙️  Container Configuration: $container_name"
    
    # Network configuration
    print_color "$YELLOW" "🌐 Network Configuration:"
    echo "  1) Bridge (Default) - Docker internal network"
    echo "  2) Host - Share host network stack"
    echo "  3) None - No networking"
    echo "  4) Custom network"
    read -p "Select network mode (1-4, default: 1): " network_choice
    
    case $network_choice in
        1) network_mode="bridge" ;;
        2) network_mode="host" ;;
        3) network_mode="none" ;;
        4)
            echo "Available networks:"
            docker network ls
            read -p "Enter network name: " custom_network
            network_mode="$custom_network"
            ;;
        *) network_mode="bridge" ;;
    esac
    
    # Port mappings
    echo ""
    print_color "$YELLOW" "🔌 Port Mappings:"
    echo "  Format: HOST_PORT:CONTAINER_PORT (e.g., 8080:80)"
    echo "  Multiple ports: 8080:80,443:443,2222:22"
    read -p "Port mappings (leave empty for none): " port_mappings
    
    # Volume mounts
    echo ""
    print_color "$YELLOW" "💾 Volume Mounts:"
    echo "  Format: /host/path:/container/path[:ro]"
    echo "  Example: /home/user/data:/app/data"
    echo "  Add :ro for read-only (e.g., /data:/app/data:ro)"
    read -p "Volume mounts (comma separated, leave empty for none): " volume_mounts
    
    # Environment variables
    echo ""
    print_color "$YELLOW" "🔧 Environment Variables:"
    echo "  Format: VAR=value"
    echo "  Multiple: VAR1=value1,VAR2=value2"
    read -p "Environment variables (comma separated): " env_vars
    
    # Resource limits
    echo ""
    print_color "$YELLOW" "📊 Resource Limits:"
    read -p "Memory limit (e.g., 512m, 2g, leave empty for unlimited): " memory_limit
    read -p "CPU limit (e.g., 1.5, 2, leave empty for unlimited): " cpu_limit
    read -p "CPU cores (e.g., 0-3, leave empty for all): " cpu_cores
    
    # Container options
    echo ""
    print_color "$YELLOW" "⚡ Container Options:"
    read -p "Restart policy (no, always, on-failure, unless-stopped): " restart_policy
    restart_policy=${restart_policy:-unless-stopped}
    
    read -p "Container command (override default, leave empty for default): " container_command
    
    # Security options
    echo ""
    print_color "$YELLOW" "🔒 Security Options:"
    read -p "Run as privileged container? (y/N): " privileged_choice
    read -p "Add capabilities (e.g., NET_ADMIN,SYS_ADMIN): " add_capabilities
    read -p "Drop capabilities (e.g., NET_RAW): " drop_capabilities
}

# Build Docker command
build_docker_command() {
    local container_name=$1
    
    # Start building command
    docker_cmd="docker run -d"
    docker_cmd+=" --name '$container_name'"
    
    # Network
    if [[ "$network_mode" != "bridge" ]]; then
        docker_cmd+=" --network '$network_mode'"
    fi
    
    # Port mappings
    if [[ -n "$port_mappings" ]]; then
        IFS=',' read -ra PORTS <<< "$port_mappings"
        for port in "${PORTS[@]}"; do
            docker_cmd+=" -p '$port'"
        done
    fi
    
    # Volume mounts
    if [[ -n "$volume_mounts" ]]; then
        IFS=',' read -ra VOLUMES <<< "$volume_mounts"
        for volume in "${VOLUMES[@]}"; do
            docker_cmd+=" -v '$volume'"
        done
    fi
    
    # Environment variables
    if [[ -n "$env_vars" ]]; then
        IFS=',' read -ra ENVS <<< "$env_vars"
        for env in "${ENVS[@]}"; do
            docker_cmd+=" -e '$env'"
        done
    fi
    
    # Resource limits
    if [[ -n "$memory_limit" ]]; then
        docker_cmd+=" --memory '$memory_limit'"
    fi
    
    if [[ -n "$cpu_limit" ]]; then
        docker_cmd+=" --cpus '$cpu_limit'"
    fi
    
    if [[ -n "$cpu_cores" ]]; then
        docker_cmd+=" --cpuset-cpus '$cpu_cores'"
    fi
    
    # Restart policy
    docker_cmd+=" --restart '$restart_policy'"
    
    # Security options
    if [[ "$privileged_choice" =~ ^[Yy]$ ]]; then
        docker_cmd+=" --privileged"
    fi
    
    if [[ -n "$add_capabilities" ]]; then
        docker_cmd+=" --cap-add '$add_capabilities'"
    fi
    
    if [[ -n "$drop_capabilities" ]]; then
        docker_cmd+=" --cap-drop '$drop_capabilities'"
    fi
    
    # Image and command
    docker_cmd+=" '$image_name'"
    
    if [[ -n "$container_command" ]]; then
        docker_cmd+=" $container_command"
    fi
}

# Execute Docker command
execute_docker_command() {
    local container_name=$1
    
    print_header "🚀 Creating Container: $container_name"
    
    # Show summary
    print_color "$CYAN" "📋 Configuration Summary:"
    echo "──────────────────────────────────────"
    echo "🏷️  Name:          $container_name"
    echo "📦 Image:          $display_name"
    echo "🌐 Network:        $network_mode"
    [[ -n "$port_mappings" ]] && echo "🔌 Ports:          $port_mappings"
    [[ -n "$volume_mounts" ]] && echo "💾 Volumes:        $volume_mounts"
    [[ -n "$env_vars" ]] && echo "🔧 Environment:     $env_vars"
    [[ -n "$memory_limit" ]] && echo "🧠 Memory:         $memory_limit"
    [[ -n "$cpu_limit" ]] && echo "⚡ CPU Limit:       $cpu_limit"
    echo "🔄 Restart Policy: $restart_policy"
    [[ "$privileged_choice" =~ ^[Yy]$ ]] && echo "🔒 Privileged:     YES"
    echo "──────────────────────────────────────"
    echo ""
    
    print_color "$YELLOW" "📝 Docker Command:"
    echo "$docker_cmd"
    echo ""
    
    read -p "✅ Create container? (Y/n): " confirm
    if [[ "$confirm" == "n" || "$confirm" == "N" ]]; then
        print_color "$YELLOW" "⚠️  Creation cancelled."
        read -p "⏎ Press Enter to continue..."
        return
    fi
    
    # Execute command
    print_color "$CYAN" "🚀 Creating container..."
    echo ""
    
    if eval $docker_cmd; then
        print_color "$GREEN" "✅ Container '$container_name' created successfully!"
        
        # Show container info
        show_container_info "$container_name"
        
        # Post-creation options
        post_creation_options "$container_name"
    else
        print_color "$RED" "❌ Failed to create container!"
        show_docker_troubleshooting
    fi
}

# Show container information
show_container_info() {
    local container_name=$1
    
    echo ""
    print_color "$CYAN" "📊 Container Information:"
    echo "──────────────────────────────────────"
    
    # Basic info
    docker ps -a --filter "name=$container_name" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    
    # Get IP address if applicable
    if [[ "$network_mode" != "host" && "$network_mode" != "none" ]]; then
        local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name" 2>/dev/null)
        if [[ -n "$container_ip" ]]; then
            echo "🌐 IP Address:      $container_ip"
        fi
    fi
    
    # Show mounted volumes
    local volumes=$(docker inspect -f '{{range .Mounts}}{{.Source}}:{{.Destination}} ({{.Mode}})
{{end}}' "$container_name" 2>/dev/null)
    if [[ -n "$volumes" ]]; then
        echo "💾 Mounted Volumes:"
        echo "$volumes"
    fi
}

# Post-creation options
post_creation_options() {
    local container_name=$1
    
    echo ""
    print_color "$YELLOW" "🚀 Next Steps:"
    echo "──────────────────────────────────────"
    
    # Get container info for suggestions
    local image_base=$(echo "$image_name" | cut -d: -f1)
    
    case $image_base in
        ubuntu|debian|centos|rocky|almalinux|fedora|archlinux|alpine)
            echo "💻 Access container shell:"
            echo "  docker exec -it $container_name /bin/bash"
            [[ "$image_base" == "alpine" ]] && echo "  docker exec -it $container_name /bin/sh"
            ;;
        nginx|httpd)
            echo "🌐 Web server access:"
            echo "  Check if running: curl http://localhost:PORT"
            echo "  View logs: docker logs $container_name"
            ;;
        mysql|postgres)
            echo "🗄️ Database access:"
            echo "  Connect: docker exec -it $container_name mysql -u root -p"
            [[ "$image_base" == "postgres" ]] && echo "  Connect: docker exec -it $container_name psql -U postgres"
            ;;
        redis)
            echo "🗃️ Redis access:"
            echo "  Connect: docker exec -it $container_name redis-cli"
            ;;
        node|python|golang|php|ruby)
            echo "👨‍💻 Development container:"
            echo "  Shell: docker exec -it $container_name /bin/bash"
            echo "  Logs: docker logs -f $container_name"
            ;;
        wordpress)
            echo "📝 WordPress setup:"
            echo "  Open browser: http://localhost:PORT"
            echo "  Follow setup wizard"
            ;;
        portainer)
            echo "🐳 Portainer UI:"
            echo "  Open browser: http://localhost:9000"
            echo "  Create admin user"
            ;;
    esac
    
    echo ""
    print_color "$CYAN" "🔧 Common Commands:"
    echo "  View logs:        docker logs $container_name"
    echo "  Follow logs:      docker logs -f $container_name"
    echo "  Stop container:   docker stop $container_name"
    echo "  Start container:  docker start $container_name"
    echo "  Restart:          docker restart $container_name"
    echo "  Remove:           docker rm -f $container_name"
    echo "  Inspect:          docker inspect $container_name"
    
    read -p "⏎ Press Enter to continue..."
}

# List Docker containers
list_docker_containers() {
    print_header "📋 Docker Containers"
    
    if ! command -v docker &> /dev/null; then
        print_color "$RED" "❌ Docker is not installed!"
        read -p "⏎ Press Enter to continue..."
        return
    fi
    
    # Show running containers
    print_color "$GREEN" "🏃 Running Containers:"
    echo "──────────────────────────────────────"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No running containers"
    
    echo ""
    print_color "$YELLOW" "💤 Stopped Containers:"
    echo "──────────────────────────────────────"
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.CreatedAt}}" 2>/dev/null | grep -v "Up" || echo "No stopped containers"
    
    # Statistics
    echo ""
    print_color "$CYAN" "📊 Statistics:"
    local total=$(docker ps -a -q | wc -l)
    local running=$(docker ps -q | wc -l)
    local stopped=$((total - running))
    echo "  Total: $total containers"
    echo "  Running: $running containers"
    echo "  Stopped: $stopped containers"
    
    read -p "⏎ Press Enter to continue..."
}

# Manage Docker container
manage_docker_container() {
    print_header "⚙️  Docker Container Management"
    
    # Get container list
    local containers=$(docker ps -a --format "{{.Names}}")
    if [[ -z "$containers" ]]; then
        print_color "$YELLOW" "📭 No containers found!"
        read -p "⏎ Press Enter to continue..."
        return
    fi
    
    # Display containers
    print_color "$BLUE" "📋 Available Containers:"
    echo ""
    local i=1
    declare -A container_map
    for container in $containers; do
        container_map[$i]=$container
        local status=$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null || echo "unknown")
        local status_icon="❓"
        [[ "$status" == "running" ]] && status_icon="🟢"
        [[ "$status" == "exited" ]] && status_icon="🔴"
        [[ "$status" == "paused" ]] && status_icon="⏸️"
        printf "  ${GREEN}%2d)${NC} %s %s (${CYAN}%s${NC})\n" "$i" "$status_icon" "$container" "$status"
        ((i++))
    done
    
    echo ""
    read -p "🎯 Select container number: " container_num
    
    if [[ -z "${container_map[$container_num]}" ]]; then
        print_color "$RED" "❌ Invalid selection!"
        read -p "⏎ Press Enter to continue..."
        return
    fi
    
    local container_name=${container_map[$container_num]}
    docker_container_management_menu "$container_name"
}

# Docker container management menu
docker_container_management_menu() {
    local container_name=$1
    
    while true; do
        print_header "⚙️  Managing: $container_name"
        
        # Get container status
        local container_status=$(docker inspect -f '{{.State.Status}}' "$container_name" 2>/dev/null || echo "unknown")
        local container_image=$(docker inspect -f '{{.Config.Image}}' "$container_name" 2>/dev/null)
        local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name" 2>/dev/null)
        
        print_color "$BLUE" "📊 Status: $container_status"
        print_color "$BLUE" "📦 Image: $container_image"
        [[ -n "$container_ip" ]] && print_color "$GREEN" "🌐 IP: $container_ip"
        print_color "$CYAN" "════════════════════════════════════════════════════════════"
        echo ""
        
        print_color "$YELLOW" "📋 Operations:"
        echo "  1) ▶️  Start Container"
        echo "  2) ⏹️  Stop Container"
        echo "  3) 🔄 Restart Container"
        echo "  4) ⏸️  Pause Container"
        echo "  5) ⏯️  Unpause Container"
        echo "  6) 💻 Open Shell"
        echo "  7) 📝 View Logs"
        echo "  8) 📊 Show Stats"
        echo "  9) 🔍 Inspect Container"
        echo "  10) ⚙️  Configure Resources"
        echo "  11) 📦 Commit to Image"
        echo "  12) 🗑️  Delete Container"
        echo "  0) ↩️  Back"
        echo ""
        
        read -p "🎯 Select operation: " operation
        
        case $operation in
            1)
                print_color "$GREEN" "▶️  Starting container..."
                if docker start "$container_name"; then
                    print_color "$GREEN" "✅ Container started!"
                else
                    print_color "$RED" "❌ Failed to start container"
                fi
                sleep 2
                ;;
            2)
                print_color "$YELLOW" "⏹️  Stopping container..."
                if docker stop "$container_name"; then
                    print_color "$GREEN" "✅ Container stopped!"
                else
                    print_color "$RED" "❌ Failed to stop container"
                fi
                sleep 2
                ;;
            3)
                print_color "$BLUE" "🔄 Restarting container..."
                if docker restart "$container_name"; then
                    print_color "$GREEN" "✅ Container restarted!"
                else
                    print_color "$RED" "❌ Failed to restart container"
                fi
                sleep 2
                ;;
            4)
                print_color "$PURPLE" "⏸️  Pausing container..."
                if docker pause "$container_name"; then
                    print_color "$GREEN" "✅ Container paused!"
                else
                    print_color "$RED" "❌ Failed to pause container"
                fi
                sleep 2
                ;;
            5)
                print_color "$PURPLE" "⏯️  Unpausing container..."
                if docker unpause "$container_name"; then
                    print_color "$GREEN" "✅ Container unpaused!"
                else
                    print_color "$RED" "❌ Failed to unpause container"
                fi
                sleep 2
                ;;
            6)
                print_color "$CYAN" "💻 Opening shell..."
                echo "📝 Type 'exit' to return to menu"
                if ! docker exec -it "$container_name" /bin/bash; then
                    print_color "$YELLOW" "⚠️  Trying /bin/sh instead..."
                    docker exec -it "$container_name" /bin/sh
                fi
                ;;
            7)
                print_color "$BLUE" "📝 Container Logs:"
                docker logs "$container_name" | tail -50
                read -p "⏎ Press Enter to continue..."
                ;;
            8)
                print_color "$BLUE" "📊 Container Statistics (Ctrl+C to exit):"
                docker stats "$container_name"
                ;;
            9)
                print_color "$BLUE" "🔍 Container Inspection:"
                docker inspect "$container_name" | jq '.[0]' || docker inspect "$container_name"
                read -p "⏎ Press Enter to continue..."
                ;;
            10)
                configure_docker_resources "$container_name"
                ;;
            11)
                read -p "📦 New image name (e.g., myapp:v1): " new_image_name
                if [[ -n "$new_image_name" ]]; then
                    if docker commit "$container_name" "$new_image_name"; then
                        print_color "$GREEN" "✅ Image created: $new_image_name"
                    else
                        print_color "$RED" "❌ Failed to create image"
                    fi
                fi
                sleep 2
                ;;
            12)
                print_color "$RED" "⚠️  ⚠️  ⚠️  WARNING: This will delete '$container_name'!"
                read -p "🗑️  Are you sure? (type 'DELETE' to confirm): " confirm
                if [[ "$confirm" == "DELETE" ]]; then
                    print_color "$RED" "🗑️  Deleting container..."
                    if docker rm -f "$container_name"; then
                        print_color "$GREEN" "✅ Container deleted!"
                        read -p "⏎ Press Enter to continue..."
                        return
                    else
                        print_color "$RED" "❌ Failed to delete container"
                    fi
                else
                    print_color "$YELLOW" "⚠️  Deletion cancelled"
                fi
                sleep 2
                ;;
            0)
                return
                ;;
            *)
                print_color "$RED" "❌ Invalid operation!"
                sleep 1
                ;;
        esac
    done
}

# Configure Docker resources
configure_docker_resources() {
    local container_name=$1
    
    print_header "⚙️  Configure Resources: $container_name"
    
    echo "Current resource limits:"
    docker inspect "$container_name" --format '{{.HostConfig.Memory}} {{.HostConfig.NanoCpus}}' 2>/dev/null
    
    echo ""
    print_color "$YELLOW" "📊 Set New Resource Limits:"
    read -p "Memory limit (e.g., 512m, 2g): " new_memory
    read -p "CPU limit (e.g., 1.5): " new_cpu
    read -p "CPU cores (e.g., 0-3): " new_cpuset
    
    # Update container
    local update_cmd="docker update"
    
    [[ -n "$new_memory" ]] && update_cmd+=" --memory '$new_memory'"
    [[ -n "$new_cpu" ]] && update_cmd+=" --cpus '$new_cpu'"
    [[ -n "$new_cpuset" ]] && update_cmd+=" --cpuset-cpus '$new_cpuset'"
    
    update_cmd+=" '$container_name'"
    
    if eval $update_cmd; then
        print_color "$GREEN" "✅ Resources updated!"
    else
        print_color "$RED" "❌ Failed to update resources"
    fi
    
    read -p "⏎ Press Enter to continue..."
}

# Docker image management
manage_docker_images() {
    print_header "📦 Docker Image Management"
    
    # Show available images
    print_color "$GREEN" "📷 Available Images:"
    echo "──────────────────────────────────────"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}"
    
    echo ""
    print_color "$YELLOW" "📋 Operations:"
    echo "  1) 📥 Pull New Image"
    echo "  2) 🗑️  Remove Image"
    echo "  3) 🔍 Search Docker Hub"
    echo "  4) 📤 Save Image to File"
    echo "  5) 📥 Load Image from File"
    echo "  0) ↩️  Back"
    echo ""
    
    read -p "🎯 Select operation: " operation
    
    case $operation in
        1)
            read -p "📦 Image name to pull (e.g., nginx:alpine): " pull_image
            if [[ -n "$pull_image" ]]; then
                print_color "$CYAN" "📥 Pulling image..."
                docker pull "$pull_image"
            fi
            ;;
        2)
            read -p "🗑️ Image name to remove (e.g., nginx:alpine): " remove_image
            if [[ -n "$remove_image" ]]; then
                docker rmi "$remove_image"
            fi
            ;;
        3)
            search_docker_hub
            ;;
        4)
            read -p "💾 Image name to save: " save_image
            read -p "📁 Output file (e.g., image.tar): " output_file
            if [[ -n "$save_image" && -n "$output_file" ]]; then
                docker save "$save_image" -o "$output_file"
                print_color "$GREEN" "✅ Image saved to $output_file"
            fi
            ;;
        5)
            read -p "📁 Image file to load (e.g., image.tar): " input_file
            if [[ -f "$input_file" ]]; then
                docker load -i "$input_file"
            else
                print_color "$RED" "❌ File not found: $input_file"
            fi
            ;;
    esac
    
    read -p "⏎ Press Enter to continue..."
}

# Docker network management
manage_docker_networks() {
    print_header "🌐 Docker Network Management"
    
    # Show available networks
    print_color "$GREEN" "🌐 Available Networks:"
    echo "──────────────────────────────────────"
    docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"
    
    echo ""
    print_color "$YELLOW" "📋 Operations:"
    echo "  1) ➕ Create Network"
    echo "  2) 🔍 Inspect Network"
    echo "  3) 🗑️  Remove Network"
    echo "  4) 🔗 Connect Container"
    echo "  5) 🔓 Disconnect Container"
    echo "  0) ↩️  Back"
    echo ""
    
    read -p "🎯 Select operation: " operation
    
    case $operation in
        1)
            read -p "🏷️  Network name: " network_name
            read -p "🚗 Driver (bridge, overlay, macvlan): " network_driver
            read -p "🌐 Subnet (e.g., 172.20.0.0/16): " network_subnet
            if [[ -n "$network_name" ]]; then
                local create_cmd="docker network create"
                [[ -n "$network_driver" ]] && create_cmd+=" --driver '$network_driver'"
                [[ -n "$network_subnet" ]] && create_cmd+=" --subnet '$network_subnet'"
                create_cmd+=" '$network_name'"
                eval $create_cmd
            fi
            ;;
        2)
            read -p "🔍 Network name to inspect: " inspect_network
            if [[ -n "$inspect_network" ]]; then
                docker network inspect "$inspect_network"
            fi
            ;;
        3)
            read -p "🗑️  Network name to remove: " remove_network
            if [[ -n "$remove_network" ]]; then
                docker network rm "$remove_network"
            fi
            ;;
        4)
            read -p "🔗 Container name: " connect_container
            read -p "🌐 Network name: " connect_network
            if [[ -n "$connect_container" && -n "$connect_network" ]]; then
                docker network connect "$connect_network" "$connect_container"
            fi
            ;;
        5)
            read -p "🔓 Container name: " disconnect_container
            read -p "🌐 Network name: " disconnect_network
            if [[ -n "$disconnect_container" && -n "$disconnect_network" ]]; then
                docker network disconnect "$disconnect_network" "$disconnect_container"
            fi
            ;;
    esac
    
    read -p "⏎ Press Enter to continue..."
}

# Docker volume management
manage_docker_volumes() {
    print_header "💾 Docker Volume Management"
    
    # Show available volumes
    print_color "$GREEN" "💾 Available Volumes:"
    echo "──────────────────────────────────────"
    docker volume ls --format "table {{.Name}}\t{{.Driver}}\t{{.Mountpoint}}"
    
    echo ""
    print_color "$YELLOW" "📋 Operations:"
    echo "  1) ➕ Create Volume"
    echo "  2) 🔍 Inspect Volume"
    echo "  3) 🗑️  Remove Volume"
    echo "  4) 🧹 Clean Unused Volumes"
    echo "  0) ↩️  Back"
    echo ""
    
    read -p "🎯 Select operation: " operation
    
    case $operation in
        1)
            read -p "🏷️  Volume name: " volume_name
            if [[ -n "$volume_name" ]]; then
                docker volume create "$volume_name"
            fi
            ;;
        2)
            read -p "🔍 Volume name to inspect: " inspect_volume
            if [[ -n "$inspect_volume" ]]; then
                docker volume inspect "$inspect_volume"
            fi
            ;;
        3)
            read -p "🗑️  Volume name to remove: " remove_volume
            if [[ -n "$remove_volume" ]]; then
                docker volume rm "$remove_volume"
            fi
            ;;
        4)
            print_color "$YELLOW" "⚠️  This will remove all unused volumes!"
            read -p "🧹 Proceed? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                docker volume prune -f
            fi
            ;;
    esac
    
    read -p "⏎ Press Enter to continue..."
}

# Docker compose management
manage_docker_compose() {
    print_header "🎭 Docker Compose Management"
    
    # Check if Docker Compose is available
    local compose_cmd="docker compose"
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_color "$RED" "❌ Docker Compose not found!"
        echo ""
        print_color "$YELLOW" "💡 Install Docker Compose:"
        echo "  sudo apt install docker-compose  # Debian/Ubuntu"
        echo "  or use: docker compose plugin"
        read -p "⏎ Press Enter to continue..."
        return
    fi
    
    # Try to detect docker-compose.yml files
    local compose_files=$(find . -name "docker-compose*.yml" -o -name "docker-compose*.yaml" 2>/dev/null | head -5)
    
    if [[ -n "$compose_files" ]]; then
        print_color "$GREEN" "📁 Found Compose files:"
        echo "$compose_files"
        echo ""
    fi
    
    print_color "$YELLOW" "📋 Operations:"
    echo "  1) 🚀 Start Compose Project"
    echo "  2) ⏹️  Stop Compose Project"
    echo "  3) 🔄 Restart Compose Project"
    echo "  4) 📊 View Compose Status"
    echo "  5) 📝 View Compose Logs"
    echo "  6) 📁 Create New Compose File"
    echo "  0) ↩️  Back"
    echo ""
    
    read -p "🎯 Select operation: " operation
    
    case $operation in
        1)
            read -p "📁 Compose file (default: docker-compose.yml): " compose_file
            compose_file=${compose_file:-docker-compose.yml}
            if [[ -f "$compose_file" ]]; then
                docker-compose -f "$compose_file" up -d || docker compose -f "$compose_file" up -d
            else
                print_color "$RED" "❌ File not found: $compose_file"
            fi
            ;;
        2)
            read -p "📁 Compose file (default: docker-compose.yml): " compose_file
            compose_file=${compose_file:-docker-compose.yml}
            if [[ -f "$compose_file" ]]; then
                docker-compose -f "$compose_file" down || docker compose -f "$compose_file" down
            fi
            ;;
        3)
            read -p "📁 Compose file (default: docker-compose.yml): " compose_file
            compose_file=${compose_file:-docker-compose.yml}
            if [[ -f "$compose_file" ]]; then
                docker-compose -f "$compose_file" restart || docker compose -f "$compose_file" restart
            fi
            ;;
        4)
            read -p "📁 Compose file (default: docker-compose.yml): " compose_file
            compose_file=${compose_file:-docker-compose.yml}
            if [[ -f "$compose_file" ]]; then
                docker-compose -f "$compose_file" ps || docker compose -f "$compose_file" ps
            fi
            ;;
        5)
            read -p "📁 Compose file (default: docker-compose.yml): " compose_file
            compose_file=${compose_file:-docker-compose.yml}
            read -p "📝 Service name (optional): " service_name
            if [[ -f "$compose_file" ]]; then
                if [[ -n "$service_name" ]]; then
                    docker-compose -f "$compose_file" logs "$service_name" || docker compose -f "$compose_file" logs "$service_name"
                else
                    docker-compose -f "$compose_file" logs || docker compose -f "$compose_file" logs
                fi
            fi
            ;;
        6)
            create_compose_file
            ;;
    esac
    
    read -p "⏎ Press Enter to continue..."
}

# Create Docker Compose file
create_compose_file() {
    print_header "📝 Create Docker Compose File"
    
    read -p "📁 File name (default: docker-compose.yml): " compose_file
    compose_file=${compose_file:-docker-compose.yml}
    
    cat > "$compose_file" << 'EOF'
version: '3.8'

services:
  web:
    image: nginx:latest
    container_name: nginx-web
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./html:/usr/share/nginx/html
      - ./nginx.conf:/etc/nginx/nginx.conf
    networks:
      - app-network
    restart: unless-stopped

  database:
    image: postgres:15
    container_name: postgres-db
    environment:
      POSTGRES_DB: mydb
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - app-network
    restart: unless-stopped

  redis:
    image: redis:alpine
    container_name: redis-cache
    networks:
      - app-network
    restart: unless-stopped

networks:
  app-network:
    driver: bridge

volumes:
  postgres-data:
EOF
    
    print_color "$GREEN" "✅ Compose file created: $compose_file"
    echo ""
    print_color "$CYAN" "💡 Edit the file to customize services:"
    echo "  nano $compose_file"
    echo "  # or"
    echo "  vim $compose_file"
}

# Docker cleanup
docker_cleanup() {
    print_header "🧹 Docker Cleanup"
    
    print_color "$YELLOW" "⚠️  WARNING: These operations will remove Docker resources!"
    echo ""
    
    print_color "$YELLOW" "📋 Cleanup Options:"
    echo "  1) 🗑️  Remove Stopped Containers"
    echo "  2) 🗑️  Remove Dangling Images"
    echo "  3) 🗑️  Remove Unused Images"
    echo "  4) 🗑️  Remove Unused Volumes"
    echo "  5) 🗑️  Remove Unused Networks"
    echo "  6) 🧹 Full System Cleanup"
    echo "  0) ↩️  Back"
    echo ""
    
    read -p "🎯 Select operation: " operation
    
    case $operation in
        1)
            docker container prune -f
            print_color "$GREEN" "✅ Stopped containers removed"
            ;;
        2)
            docker image prune -f
            print_color "$GREEN" "✅ Dangling images removed"
            ;;
        3)
            docker image prune -a -f
            print_color "$GREEN" "✅ Unused images removed"
            ;;
        4)
            docker volume prune -f
            print_color "$GREEN" "✅ Unused volumes removed"
            ;;
        5)
            docker network prune -f
            print_color "$GREEN" "✅ Unused networks removed"
            ;;
        6)
            docker system prune -a -f --volumes
            print_color "$GREEN" "✅ Full system cleanup completed"
            ;;
    esac
    
    read -p "⏎ Press Enter to continue..."
}

# Main menu
main_menu() {
    while true; do
        print_banner
        
        # Get Docker stats
        local container_count=0
        local image_count=0
        if command -v docker &> /dev/null; then
            container_count=$(docker ps -a -q | wc -l)
            image_count=$(docker images -q | wc -l)
        fi
        
        print_color "$GREEN" "🏠 Docker Container Manager"
        print_color "$BLUE" "📦 Containers: $container_count | 📷 Images: $image_count"
        print_color "$CYAN" "════════════════════════════════════════════════════════════"
        echo ""
        
        echo "  1) 🚀 Create New Container"
        echo "  2) 📋 List Containers"
        echo "  3) ⚙️  Manage Container"
        echo "  4) 📦 Image Management"
        echo "  5) 🌐 Network Management"
        echo "  6) 💾 Volume Management"
        echo "  7) 🎭 Docker Compose"
        echo "  8) 📊 System Information"
        echo "  9) 🧹 Cleanup"
        echo "  10) ⚡ Install Docker"
        echo "  0) 👋 Exit"
        echo ""
        
        read -p "🎯 Select option: " choice
        
        case $choice in
            1) create_docker_container ;;
            2) list_docker_containers ;;
            3) manage_docker_container ;;
            4) manage_docker_images ;;
            5) manage_docker_networks ;;
            6) manage_docker_volumes ;;
            7) manage_docker_compose ;;
            8) show_system_info ;;
            9) docker_cleanup ;;
            10) install_docker ;;
            0)
                print_banner
                print_color "$GREEN" "👋 Goodbye! Happy Dockering! 🐳"
                echo ""
                exit 0
                ;;
            *)
                print_color "$RED" "❌ Invalid option!"
                sleep 1
                ;;
        esac
    done
}

# Main function
main() {
    # Check if in terminal
    if [[ ! -t 0 ]]; then
        print_color "$RED" "❌ This script must be run in a terminal!"
        exit 1
    fi
    
    # Welcome
    print_banner
    print_color "$GREEN" "🌟 Welcome to Docker Container Manager"
    print_color "$CYAN" "📦 Pure Docker Edition | Advanced Management"
    echo ""
    
    # Check Docker installation
    check_docker_installation
    
    # Start main menu
    main_menu
}

# Run main
main
