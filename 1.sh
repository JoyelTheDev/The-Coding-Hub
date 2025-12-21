#!/bin/bash

# Colors
G="\e[32m"; R="\e[31m"; Y="\e[33m"; C="\e[36m"; W="\e[97m"; B="\e[34m"; M="\e[35m"; N="\e[0m"

# Function to print section headers
section() {
    echo -e "\n${B}════════════ $1 ════════════${N}"
}

# Function to print status messages
status() {
    echo -e "${C}[*]${N} $1"
}

success() {
    echo -e "${G}[✓]${N} $1"
}

error() {
    echo -e "${R}[✗]${N} $1"
}

warning() {
    echo -e "${Y}[!]${N} $1"
}

# Root check
[ "$EUID" -ne 0 ] && echo -e "${R}Run as root${N}" && exit 1

# All supported distributions and their images
declare -A DISTRO_IMAGES=(
    # Ubuntu/Debian family
    ["ubuntu:latest"]="Ubuntu Latest"
    ["ubuntu:22.04"]="Ubuntu 22.04 Jammy"
    ["ubuntu:20.04"]="Ubuntu 20.04 Focal"
    ["ubuntu:18.04"]="Ubuntu 18.04 Bionic"
    ["debian:latest"]="Debian Latest"
    ["debian:11"]="Debian 11 Bullseye"
    ["debian:10"]="Debian 10 Buster"
    
    # RHEL/CentOS family
    ["centos:7"]="CentOS 7"
    ["centos:stream8"]="CentOS Stream 8"
    ["centos:stream9"]="CentOS Stream 9"
    ["rockylinux:8"]="Rocky Linux 8"
    ["rockylinux:9"]="Rocky Linux 9"
    ["almalinux:8"]="AlmaLinux 8"
    ["almalinux:9"]="AlmaLinux 9"
    
    # Fedora
    ["fedora:latest"]="Fedora Latest"
    ["fedora:38"]="Fedora 38"
    ["fedora:37"]="Fedora 37"
    
    # Arch Linux
    ["archlinux:latest"]="Arch Linux Latest"
    
    # OpenSUSE
    ["opensuse/leap:latest"]="openSUSE Leap"
    ["opensuse/tumbleweed:latest"]="openSUSE Tumbleweed"
    
    # Alpine
    ["alpine:latest"]="Alpine Linux Latest"
    ["alpine:3.18"]="Alpine 3.18"
    
    # Oracle Linux
    ["oraclelinux:8"]="Oracle Linux 8"
    ["oraclelinux:9"]="Oracle Linux 9"
    
    # Amazon Linux
    ["amazonlinux:2023"]="Amazon Linux 2023"
    ["amazonlinux:2"]="Amazon Linux 2"
    
    # Specialized
    ["photon:latest"]="VMware Photon OS"
    ["clearlinux:latest"]="Clear Linux"
    ["gentoo/stage3:latest"]="Gentoo Linux"
)

# Default configuration
DEFAULT_IMAGE="ubuntu:22.04"
DEFAULT_PREFIX="sys_container"

# Detect systemd init system for image
detect_systemd_init() {
    local image=$1
    # Most modern distros use systemd, but Alpine uses OpenRC
    if [[ "$image" == *"alpine"* ]]; then
        echo "openrc"
    else
        echo "systemd"
    fi
}

# Get init command for image
get_init_command() {
    local image=$1
    local init_system=$(detect_systemd_init "$image")
    
    case $init_system in
        "systemd")
            echo "/sbin/init"
            ;;
        "openrc")
            echo "/sbin/init"
            ;;
        *)
            echo "/sbin/init"
            ;;
    esac
}

# Get package manager for image
get_package_manager() {
    local image=$1
    
    if [[ "$image" == *"ubuntu"* ]] || [[ "$image" == *"debian"* ]]; then
        echo "apt"
    elif [[ "$image" == *"centos"* ]] || [[ "$image" == *"rockylinux"* ]] || 
         [[ "$image" == *"almalinux"* ]] || [[ "$image" == *"oraclelinux"* ]] || 
         [[ "$image" == *"amazonlinux"* ]]; then
        echo "yum"
    elif [[ "$image" == *"fedora"* ]]; then
        echo "dnf"
    elif [[ "$image" == *"arch"* ]]; then
        echo "pacman"
    elif [[ "$image" == *"alpine"* ]]; then
        echo "apk"
    elif [[ "$image" == *"opensuse"* ]]; then
        echo "zypper"
    elif [[ "$image" == *"photon"* ]]; then
        echo "tdnf"
    else
        echo "apt"  # Default
    fi
}

# Auto-detect existing containers
detect_existing_containers() {
    echo -e "\n${B}🔍 Detecting existing containers...${N}"
    
    # Find all containers
    existing_containers=$(docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' | tail -n +2)
    
    if [ -n "$existing_containers" ]; then
        echo -e "${C}Found existing containers:${N}"
        echo "-------------------------------------------------------------------------------"
        printf "%-25s %-25s %-20s %s\n" "NAME" "IMAGE" "STATUS" "PORTS"
        echo "-------------------------------------------------------------------------------"
        echo "$existing_containers" | while IFS= read -r line; do
            if [ -n "$line" ]; then
                name=$(echo "$line" | awk '{print $1}')
                image=$(echo "$line" | awk '{print $2}')
                status=$(echo "$line" | awk '{print $3}')
                ports=$(echo "$line" | cut -d' ' -f4-)
                printf "%-25s %-25s %-20s %s\n" "$name" "$image" "$status" "$ports"
            fi
        done
        echo "-------------------------------------------------------------------------------"
        return 0
    else
        echo -e "${Y}No existing containers found${N}"
        return 1
    fi
}

# Auto-select or create container name
auto_select_container() {
    detect_existing_containers
    
    if [ $? -eq 0 ] && [ -n "$existing_containers" ]; then
        echo -e "\n${C}Select an option:${N}"
        echo -e "${G}1)${N} Use existing container"
        echo -e "${Y}2)${N} Create new container"
        echo -e "${M}3)${N} Clone existing container"
        echo -e "${R}4)${N} Exit"
        
        read -p "Choice [1-4]: " choice
        
        case $choice in
            1)
                read -p "Enter existing container name: " existing_name
                if docker inspect "$existing_name" &>/dev/null; then
                    CONTAINER_NAME="$existing_name"
                    IMAGE_NAME=$(docker inspect -f '{{.Config.Image}}' "$existing_name")
                    success "Using existing container: $CONTAINER_NAME ($IMAGE_NAME)"
                    return 0
                else
                    error "Container '$existing_name' not found"
                    return 1
                fi
                ;;
            2)
                # Continue with new container creation
                return 2
                ;;
            3)
                read -p "Enter container name to clone: " clone_name
                if docker inspect "$clone_name" &>/dev/null; then
                    read -p "Enter new container name: " new_name
                    if docker ps -a --format '{{.Names}}' | grep -q "^${new_name}$"; then
                        error "Container '$new_name' already exists"
                        return 1
                    fi
                    status "Cloning container $clone_name to $new_name..."
                    docker commit "$clone_name" "clone_${new_name}:latest"
                    CONTAINER_NAME="$new_name"
                    IMAGE_NAME="clone_${new_name}:latest"
                    return 2
                else
                    error "Container '$clone_name' not found"
                    return 1
                fi
                ;;
            4)
                exit 0
                ;;
            *)
                error "Invalid choice"
                return 1
                ;;
        esac
    fi
    
    return 2  # Default to create new
}

# Generate unique container name
generate_container_name() {
    local base_name="$1"
    local counter=1
    local new_name="$base_name"
    
    while docker ps -a --format '{{.Names}}' | grep -q "^${new_name}$"; do
        new_name="${base_name}_${counter}"
        ((counter++))
        if [ $counter -gt 20 ]; then
            new_name="${base_name}_$(date +%s)"
            break
        fi
    done
    
    echo "$new_name"
}

# Display available images with categories
display_image_categories() {
    section "AVAILABLE DISTRIBUTIONS"
    
    echo -e "${C}Select a distribution category:${N}"
    echo -e "${G}1)${N} Ubuntu/Debian Family"
    echo -e "${Y}2)${N} RHEL/CentOS Family"
    echo -e "${M}3)${N} Fedora"
    echo -e "${B}4)${N} Arch Linux"
    echo -e "${C}5)${N} openSUSE"
    echo -e "${G}6)${N} Alpine Linux"
    echo -e "${Y}7)${N} Enterprise Linux (Oracle, Amazon)"
    echo -e "${R}8)${N} Specialized Distros"
    echo -e "${W}9)${N} Custom Image"
    echo -e "${C}10)${N} View All"
    
    read -p "Choose category [1-10]: " category
    
    case $category in
        1)
            # Ubuntu/Debian
            images=(
                "ubuntu:latest" "ubuntu:22.04" "ubuntu:20.04" "ubuntu:18.04"
                "debian:latest" "debian:11" "debian:10"
            )
            ;;
        2)
            # RHEL/CentOS
            images=(
                "centos:7" "centos:stream8" "centos:stream9"
                "rockylinux:8" "rockylinux:9"
                "almalinux:8" "almalinux:9"
            )
            ;;
        3)
            # Fedora
            images=(
                "fedora:latest" "fedora:38" "fedora:37"
            )
            ;;
        4)
            # Arch
            images=(
                "archlinux:latest"
            )
            ;;
        5)
            # openSUSE
            images=(
                "opensuse/leap:latest" "opensuse/tumbleweed:latest"
            )
            ;;
        6)
            # Alpine
            images=(
                "alpine:latest" "alpine:3.18"
            )
            ;;
        7)
            # Enterprise
            images=(
                "oraclelinux:8" "oraclelinux:9"
                "amazonlinux:2023" "amazonlinux:2"
            )
            ;;
        8)
            # Specialized
            images=(
                "photon:latest" "clearlinux:latest" "gentoo/stage3:latest"
            )
            ;;
        9)
            # Custom
            read -p "Enter custom image name (e.g., nginx:latest): " custom_image
            if [ -n "$custom_image" ]; then
                IMAGE_NAME="$custom_image"
                return 0
            else
                error "No image specified"
                return 1
            fi
            ;;
        10)
            # All images
            images=($(echo ${!DISTRO_IMAGES[@]} | tr ' ' '\n' | sort))
            ;;
        *)
            error "Invalid category"
            return 1
            ;;
    esac
    
    # Display images in selected category
    echo -e "\n${G}Available images in this category:${N}"
    echo "------------------------------------------------"
    for i in "${!images[@]}"; do
        img="${images[$i]}"
        desc="${DISTRO_IMAGES[$img]}"
        if [ -n "$desc" ]; then
            printf "${G}%2d)${N} %-30s %s\n" "$((i+1))" "$img" "$desc"
        else
            printf "${G}%2d)${N} %s\n" "$((i+1))" "$img"
        fi
    done
    echo "------------------------------------------------"
    
    # Let user select
    read -p "Select image [1-${#images[@]}], or enter custom: " img_choice
    
    if [[ "$img_choice" =~ ^[0-9]+$ ]] && [ "$img_choice" -ge 1 ] && [ "$img_choice" -le "${#images[@]}" ]; then
        IMAGE_NAME="${images[$((img_choice-1))]}"
        success "Selected: $IMAGE_NAME"
    else
        # Treat as custom image
        IMAGE_NAME="$img_choice"
        warning "Using custom image: $IMAGE_NAME"
    fi
    
    return 0
}

# Check if image exists locally, pull if not
ensure_image_exists() {
    if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
        warning "Image $IMAGE_NAME not found locally"
        echo -e "${Y}Options:${N}"
        echo -e "${G}1)${N} Pull image now"
        echo -e "${Y}2)${N} Select different image"
        echo -e "${R}3)${N} Exit"
        
        read -p "Choice [1-3]: " pull_choice
        
        case $pull_choice in
            1)
                status "Pulling $IMAGE_NAME..."
                docker pull "$IMAGE_NAME"
                if [ $? -eq 0 ]; then
                    success "Image pulled successfully"
                    return 0
                else
                    error "Failed to pull image"
                    return 1
                fi
                ;;
            2)
                display_image_categories
                ensure_image_exists
                ;;
            3)
                exit 0
                ;;
            *)
                error "Invalid choice"
                return 1
                ;;
        esac
    else
        success "Image found locally: $IMAGE_NAME"
        return 0
    fi
}

# Get container creation command based on distro
get_container_create_command() {
    local image=$1
    local name=$2
    local pkg_mgr=$(get_package_manager "$image")
    local init_cmd=$(get_init_command "$image")
    
    # Base command
    local cmd="docker run -dit \
        --name '$name' \
        --hostname '$name' \
        --cap-add=SYS_ADMIN \
        --cap-add=NET_ADMIN \
        --tmpfs /run \
        --tmpfs /run/lock \
        --tmpfs /tmp \
        --cgroupns=host \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        -v '${name}-data:/data' \
        -e container=docker"
    
    # Distro-specific adjustments
    if [[ "$image" == *"alpine"* ]]; then
        # Alpine uses OpenRC, adjust mounts
        cmd="$cmd \
            -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
            --privileged"
    elif [[ "$image" == *"arch"* ]]; then
        # Arch Linux may need additional capabilities
        cmd="$cmd \
            --cap-add=IPC_LOCK \
            --security-opt seccomp=unconfined"
    elif [[ "$image" == *"opensuse"* ]]; then
        # openSUSE adjustments
        cmd="$cmd \
            --cap-add=SYS_PTRACE \
            --security-opt apparmor=unconfined"
    fi
    
    # Add image and init command
    cmd="$cmd '$image' '$init_cmd'"
    
    echo "$cmd"
}

# Install tools based on package manager
install_container_tools() {
    local container=$1
    local image=$2
    local pkg_mgr=$(get_package_manager "$image")
    
    status "Installing basic tools using $pkg_mgr..."
    
    case $pkg_mgr in
        "apt")
            docker exec "$container" bash -c '
                apt update && apt install -y \
                curl wget nano vim htop net-tools iputils-ping \
                dnsutils procps lsof strace less sudo \
                systemd-sysv dbus 2>/dev/null || true
            ' &>/dev/null
            ;;
        "yum"|"dnf")
            docker exec "$container" bash -c '
                yum install -y \
                curl wget nano vim htop net-tools iputils \
                bind-utils procps-ng lsof strace less sudo \
                systemd dbus 2>/dev/null || \
                dnf install -y \
                curl wget nano vim htop net-tools iputils \
                bind-utils procps-ng lsof strace less sudo \
                systemd dbus 2>/dev/null || true
            ' &>/dev/null
            ;;
        "pacman")
            docker exec "$container" bash -c '
                pacman -Sy --noconfirm \
                curl wget nano vim htop net-tools iputils \
                bind procps-ng lsof strace less sudo \
                systemd dbus 2>/dev/null || true
            ' &>/dev/null
            ;;
        "apk")
            docker exec "$container" bash -c '
                apk add --no-cache \
                curl wget nano vim htop net-tools iputils \
                bind-tools procps lsof strace less sudo \
                openrc dbus 2>/dev/null || true
            ' &>/dev/null
            ;;
        "zypper")
            docker exec "$container" bash -c '
                zypper -n install \
                curl wget nano vim htop net-tools iputils \
                bind-utils procps lsof strace less sudo \
                systemd dbus 2>/dev/null || true
            ' &>/dev/null
            ;;
        "tdnf")
            docker exec "$container" bash -c '
                tdnf install -y \
                curl wget nano vim htop net-tools iputils \
                bind-utils procps-ng lsof strace less sudo \
                systemd dbus 2>/dev/null || true
            ' &>/dev/null
            ;;
    esac
    
    success "Basic tools installation attempted"
}

# Cleanup function
cleanup() {
    echo -e "\n${Y}Cleaning up...${N}"
    if [ "$REMOVE_ON_EXIT" = "true" ] && [ -n "$CONTAINER_NAME" ]; then
        docker stop "$CONTAINER_NAME" 2>/dev/null
        docker rm "$CONTAINER_NAME" 2>/dev/null
        success "Container removed"
    fi
    exit 0
}

trap cleanup SIGINT SIGTERM

# Main script starts here
section "UNIVERSAL DOCKER CONTAINER MANAGER"
echo -e "${W}Supports all major Linux distributions with systemd/init${N}"

# Docker installation check
section "DOCKER CHECK"
if ! command -v docker &>/dev/null; then
    warning "Docker not found. Installing..."
    
    # Detect package manager
    if command -v apt &>/dev/null; then
        apt update && apt install -y docker.io docker-compose
        systemctl enable --now docker
    elif command -v yum &>/dev/null; then
        yum install -y docker docker-compose
        systemctl enable --now docker
    elif command -v dnf &>/dev/null; then
        dnf install -y docker docker-compose
        systemctl enable --now docker
    elif command -v pacman &>/dev/null; then
        pacman -Sy docker docker-compose --noconfirm
        systemctl enable --now docker
    elif command -v zypper &>/dev/null; then
        zypper -n install docker docker-compose
        systemctl enable --now docker
    else
        error "Cannot detect package manager. Please install Docker manually."
        exit 1
    fi
    
    # Verify installation
    if command -v docker &>/dev/null; then
        success "Docker installed successfully"
    else
        error "Docker installation failed"
        exit 1
    fi
else
    success "Docker is already installed"
    docker_version=$(docker --version | cut -d' ' -f3 | tr -d ',')
    echo -e "${C}Version:${N} $docker_version"
fi

# Check Docker service status
if ! systemctl is-active --quiet docker 2>/dev/null; then
    warning "Docker service is not running. Starting..."
    systemctl start docker 2>/dev/null || service docker start 2>/dev/null
    sleep 2
fi

# Container selection
section "CONTAINER SELECTION"
auto_select_container
selection_result=$?

if [ $selection_result -eq 0 ]; then
    # Using existing container
    NEW_CONTAINER=false
    success "Using existing container: $CONTAINER_NAME"
elif [ $selection_result -eq 2 ]; then
    # Create new container
    NEW_CONTAINER=true
    
    # Image selection
    display_image_categories || exit 1
    
    # Ensure image exists
    ensure_image_exists || exit 1
    
    # Generate container name
    CONTAINER_NAME=$(generate_container_name "$DEFAULT_PREFIX")
    
    # Ask for custom name
    read -p "Container name [$CONTAINER_NAME]: " custom_name
    if [ -n "$custom_name" ]; then
        CONTAINER_NAME="$custom_name"
        # Re-check uniqueness
        if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            CONTAINER_NAME=$(generate_container_name "$CONTAINER_NAME")
            warning "Name exists, using: $CONTAINER_NAME"
        fi
    fi
    
    # Get package manager for the image
    PKG_MGR=$(get_package_manager "$IMAGE_NAME")
    INIT_SYSTEM=$(detect_systemd_init "$IMAGE_NAME")
    
    echo -e "\n${C}Container Configuration:${N}"
    echo -e "  Name: $CONTAINER_NAME"
    echo -e "  Image: $IMAGE_NAME"
    echo -e "  Package Manager: $PKG_MGR"
    echo -e "  Init System: $INIT_SYSTEM"
    
    # Ask for removal preference
    echo -e "\n${Y}Container cleanup policy:${N}"
    echo -e "${G}1)${N} Keep container after exit (default)"
    echo -e "${Y}2)${N} Remove container after exit"
    echo -e "${M}3)${N} Ask at exit"
    read -p "Choice [1-3]: " cleanup_choice
    case $cleanup_choice in
        2) REMOVE_ON_EXIT="true" ;;
        3) REMOVE_ON_EXIT="ask" ;;
        *) REMOVE_ON_EXIT="false" ;;
    esac
    
    # Additional options
    echo -e "\n${C}Additional options:${N}"
    read -p "Add port mapping (e.g., 80:80) [Enter to skip]: " port_map
    read -p "Add volume mount (e.g., /host:/container) [Enter to skip]: " volume_map
    read -p "Set environment variables (e.g., KEY=value) [Enter to skip]: " env_vars
else
    exit 1
fi

# Create new container if needed
if [ "$NEW_CONTAINER" = true ]; then
    section "CONTAINER CREATION"
    status "Creating container: $CONTAINER_NAME from $IMAGE_NAME"
    
    # Build docker command
    CREATE_CMD="docker run -dit \
        --name '$CONTAINER_NAME' \
        --hostname '$CONTAINER_NAME' \
        --cap-add=SYS_ADMIN \
        --cap-add=NET_ADMIN \
        --tmpfs /run \
        --tmpfs /run/lock \
        --tmpfs /tmp \
        --cgroupns=host \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        -v '${CONTAINER_NAME}-data:/data' \
        -e container=docker"
    
    # Add optional port mapping
    if [ -n "$port_map" ]; then
        CREATE_CMD="$CREATE_CMD -p '$port_map'"
    fi
    
    # Add optional volume mount
    if [ -n "$volume_map" ]; then
        CREATE_CMD="$CREATE_CMD -v '$volume_map'"
    fi
    
    # Add optional environment variables
    if [ -n "$env_vars" ]; then
        CREATE_CMD="$CREATE_CMD -e '$env_vars'"
    fi
    
    # Distro-specific adjustments
    if [[ "$IMAGE_NAME" == *"alpine"* ]]; then
        CREATE_CMD="$CREATE_CMD --privileged"
    elif [[ "$IMAGE_NAME" == *"arch"* ]]; then
        CREATE_CMD="$CREATE_CMD --cap-add=IPC_LOCK --security-opt seccomp=unconfined"
    fi
    
    # Add image and init command
    INIT_CMD=$(get_init_command "$IMAGE_NAME")
    CREATE_CMD="$CREATE_CMD '$IMAGE_NAME' '$INIT_CMD'"
    
    # Show and execute command
    echo -e "${Y}Command:${N}"
    echo "$CREATE_CMD" | sed 's/--/\n  --/g'
    echo
    
    eval "$CREATE_CMD"
    
    if [ $? -eq 0 ]; then
        success "Container created successfully"
        sleep 3  # Wait for init system to initialize
    else
        error "Failed to create container"
        exit 1
    fi
fi

# Ensure container is running
if ! docker ps --format '{{.Names}}' | grep -qw "$CONTAINER_NAME"; then
    status "Starting container..."
    docker start "$CONTAINER_NAME"
    sleep 2
fi

# Get container info
section "CONTAINER INFO"
CONTAINER_ID=$(docker inspect -f '{{.Id}}' "$CONTAINER_NAME" | cut -c1-12)
CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CONTAINER_NAME" 2>/dev/null || echo 'N/A')
CONTAINER_STATUS=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME")
CONTAINER_IMAGE=$(docker inspect -f '{{.Config.Image}}' "$CONTAINER_NAME")
CONTAINER_CREATED=$(docker inspect -f '{{.Created}}' "$CONTAINER_NAME" | cut -d'T' -f1)
CONTAINER_PORTS=$(docker port "$CONTAINER_NAME" 2>/dev/null || echo 'None')

echo -e "${G}Container ID:${N} $CONTAINER_ID"
echo -e "${G}Name:${N} $CONTAINER_NAME"
echo -e "${G}Image:${N} $CONTAINER_IMAGE"
echo -e "${G}Status:${N} $CONTAINER_STATUS"
echo -e "${G}Created:${N} $CONTAINER_CREATED"
echo -e "${G}IP Address:${N} $CONTAINER_IP"
echo -e "${G}Ports:${N} $CONTAINER_PORTS"
echo -e "${G}Hostname:${N} $(docker exec "$CONTAINER_NAME" hostname 2>/dev/null)"

# Check init system
status "Checking init system..."
if docker exec "$CONTAINER_NAME" ps -p 1 -o comm= 2>/dev/null | grep -q "systemd\|init"; then
    INIT_PROC=$(docker exec "$CONTAINER_NAME" ps -p 1 -o comm=)
    success "Init system: $INIT_PROC"
else
    warning "Could not determine init system"
fi

# Install basic tools
if [ "$NEW_CONTAINER" = true ]; then
    install_container_tools "$CONTAINER_NAME" "$IMAGE_NAME"
fi

# Generate distribution-specific menu
generate_distro_menu() {
    local image=$1
    local pkg_mgr=$(get_package_manager "$image")
    
    case $pkg_mgr in
        "apt")
            INSTALL_CMD="apt update && apt install -y"
            UPDATE_CMD="apt update && apt upgrade -y"
            SEARCH_CMD="apt search"
            LIST_CMD="dpkg -l"
            ;;
        "yum"|"dnf")
            INSTALL_CMD="yum install -y"
            UPDATE_CMD="yum update -y"
            SEARCH_CMD="yum search"
            LIST_CMD="rpm -qa"
            ;;
        "pacman")
            INSTALL_CMD="pacman -S --noconfirm"
            UPDATE_CMD="pacman -Syu --noconfirm"
            SEARCH_CMD="pacman -Ss"
            LIST_CMD="pacman -Q"
            ;;
        "apk")
            INSTALL_CMD="apk add --no-cache"
            UPDATE_CMD="apk update && apk upgrade"
            SEARCH_CMD="apk search"
            LIST_CMD="apk info"
            ;;
        "zypper")
            INSTALL_CMD="zypper -n install"
            UPDATE_CMD="zypper -n update"
            SEARCH_CMD="zypper search"
            LIST_CMD="rpm -qa"
            ;;
        *)
            INSTALL_CMD="apt update && apt install -y"
            UPDATE_CMD="apt update && apt upgrade -y"
            SEARCH_CMD="apt search"
            LIST_CMD="dpkg -l"
            ;;
    esac
    
    cat <<EOF
#!/bin/bash

# Colors
G="\e[32m"; R="\e[31m"; Y="\e[33m"; C="\e[36m"; W="\e[97m"; B="\e[34m"; M="\e[35m"; N="\e[0m"

# Distribution info
DISTRO_NAME="\$(source /etc/os-release 2>/dev/null && echo \$PRETTY_NAME || echo 'Unknown')"
PKG_MGR="$pkg_mgr"
INSTALL_CMD="$INSTALL_CMD"
UPDATE_CMD="$UPDATE_CMD"

# Function to display header
header() {
    clear
    echo -e "\${B}╔══════════════════════════════════════════════════════════════════╗\${N}"
    echo -e "\${B}║\${W}   🖥️  CONTAINER SYSTEM MANAGER                                 \${B}║\${N}"
    echo -e "\${B}║\${C}   Distro: \${W}\$DISTRO_NAME \${C} | Package Manager: \${W}\$PKG_MGR          \${B}║\${N}"
    echo -e "\${B}╠══════════════════════════════════════════════════════════════════╣\${N}"
}

# Function to display container info
show_container_info() {
    echo -e "\${G}Container: \${W}\$(hostname)\${N}"
    echo -e "\${G}IP: \${W}\$(hostname -I 2>/dev/null | tr -d '\n' || echo 'N/A')\${N}"
    echo -e "\${G}Uptime: \${W}\$(uptime -p | sed 's/up //')\${N}"
    echo -e "\${G}Load: \${W}\$(uptime | awk -F'load average:' '{print \$2}')\${N}"
}

while true; do
header
show_container_info
echo -e "\${B}╠══════════════════════════════════════════════════════════════════╣\${N}"
echo -e "\${B}║\${G} 1️⃣  System Information & Resources                             \${B}║\${N}"
echo -e "\${B}║\${Y} 2️⃣  Package Management (\$PKG_MGR)                            \${B}║\${N}"
echo -e "\${B}║\${C} 3️⃣  Service Control                                         \${B}║\${N}"
echo -e "\${B}║\${W} 4️⃣  Network & Connectivity                                   \${B}║\${N}"
echo -e "\${B}║\${M} 5️⃣  Process & Resource Monitoring                             \${B}║\${N}"
echo -e "\${B}║\${G} 6️⃣  Storage & Filesystem                                      \${B}║\${N}"
echo -e "\${B}║\${Y} 7️⃣  User & Security Management                                \${B}║\${N}"
echo -e "\${B}║\${C} 8️⃣  Logs & Diagnostics                                        \${B}║\${N}"
echo -e "\${B}║\${W} 9️⃣  Run Custom Command / Shell                                \${B}║\${N}"
echo -e "\${B}║\${R} 🔟  Exit to Host                                              \${B}║\${N}"
echo -e "\${B}╚══════════════════════════════════════════════════════════════════╝\${N}"
echo

read -p "Select [1-10]: " ch

case \$ch in
1)
  clear
  echo -e "\${B}════════════ SYSTEM INFORMATION ════════════\${N}"
  echo -e "\${G}System Overview:\${N}"
  echo -e "  Hostname: \$(hostname)"
  echo -e "  OS: \$DISTRO_NAME"
  echo -e "  Kernel: \$(uname -r)"
  echo -e "  Architecture: \$(uname -m)"
  
  echo -e "\n\${G}Resource Usage:\${N}"
  echo -e "  CPU Cores: \$(nproc)"
  echo -e "  Load Average: \$(uptime | awk -F'load average:' '{print \$2}')"
  echo -e "  Memory: \$(free -h | awk '/^Mem:/ {print \$3 "/" \$2 " used"}')"
  echo -e "  Swap: \$(free -h | awk '/^Swap:/ {print \$3 "/" \$2 " used"}')"
  
  echo -e "\n\${G}Storage:\${N}"
  df -h -x tmpfs -x devtmpfs | head -10
  
  echo -e "\n\${G}Uptime:\${N}"
  uptime
  ;;
2)
  clear
  echo -e "\${B}════════════ PACKAGE MANAGEMENT ════════════\${N}"
  echo -e "\${C}Using: \$PKG_MGR\${N}"
  echo -e "\${Y}1) Install package    2) Remove package\${N}"
  echo -e "\${Y}3) Update system      4) Search package\${N}"
  echo -e "\${Y}5) List installed     6) Clean cache\${N}"
  read -p "Choice [1-6]: " pkg_choice
  
  case \$pkg_choice in
    1)
      read -p "Package name: " pkg
      eval "\$INSTALL_CMD \$pkg"
      ;;
    2)
      read -p "Package name: " pkg
      case \$PKG_MGR in
        apt) apt remove -y "\$pkg" ;;
        yum|dnf) yum remove -y "\$pkg" ;;
        pacman) pacman -R --noconfirm "\$pkg" ;;
        apk) apk del "\$pkg" ;;
        zypper) zypper -n remove "\$pkg" ;;
      esac
      ;;
    3)
      eval "\$UPDATE_CMD"
      ;;
    4)
      read -p "Search term: " term
      case \$PKG_MGR in
        apt) apt search "\$term" ;;
        yum|dnf) yum search "\$term" ;;
        pacman) pacman -Ss "\$term" ;;
        apk) apk search "\$term" ;;
        zypper) zypper search "\$term" ;;
      esac
      ;;
    5)
      eval "\$LIST_CMD" | head -30
      ;;
    6)
      case \$PKG_MGR in
        apt) apt clean ;;
        yum|dnf) yum clean all ;;
        pacman) pacman -Sc --noconfirm ;;
        apk) apk cache clean ;;
        zypper) zypper clean ;;
      esac
      ;;
  esac
  ;;
3)
  clear
  echo -e "\${B}════════════ SERVICE CONTROL ════════════\${N}"
  # Check init system
  if ps -p 1 -o comm= | grep -q systemd; then
    echo -e "\${G}Init System: systemd\${N}"
    echo -e "\${C}Available services (first 15):\${N}"
    systemctl list-units --type=service --no-legend | head -15 | awk '{print \$1}'
    echo
    read -p "Service name: " svc
    if [[ -n "\$svc" ]]; then
      echo -e "\${W}1) Start    2) Stop     3) Restart\${N}"
      echo -e "\${W}4) Status   5) Enable   6) Disable\${N}"
      read -p "Action [1-6]: " act
      case \$act in
        1) systemctl start "\$svc" ;;
        2) systemctl stop "\$svc" ;;
        3) systemctl restart "\$svc" ;;
        4) systemctl status "\$svc" ;;
        5) systemctl enable "\$svc" ;;
        6) systemctl disable "\$svc" ;;
      esac
    fi
  elif [ -f /etc/init.d/\$svc ] || command -v rc-service >/dev/null 2>&1; then
    echo -e "\${G}Init System: OpenRC/init.d\${N}"
    read -p "Service name: " svc
    if [[ -n "\$svc" ]]; then
      echo -e "\${W}1) Start    2) Stop     3) Restart\${N}"
      echo -e "\${W}4) Status   5) Enable   6) Disable\${N}"
      read -p "Action [1-6]: " act
      case \$act in
        1) service "\$svc" start 2>/dev/null || rc-service "\$svc" start 2>/dev/null || /etc/init.d/\$svc start ;;
        2) service "\$svc" stop 2>/dev/null || rc-service "\$svc" stop 2>/dev/null || /etc/init.d/\$svc stop ;;
        3) service "\$svc" restart 2>/dev/null || rc-service "\$svc" restart 2>/dev/null || /etc/init.d/\$svc restart ;;
        4) service "\$svc" status 2>/dev/null || rc-service "\$svc" status 2>/dev/null || /etc/init.d/\$svc status ;;
        5) rc-update add "\$svc" 2>/dev/null || update-rc.d "\$svc" enable 2>/dev/null || chkconfig "\$svc" on ;;
        6) rc-update del "\$svc" 2>/dev/null || update-rc.d "\$svc" disable 2>/dev/null || chkconfig "\$svc" off ;;
      esac
    fi
  else
    echo -e "\${Y}Unknown init system\${N}"
  fi
  ;;
4)
  clear
  echo -e "\${B}════════════ NETWORK & CONNECTIVITY ════════════\${N}"
  echo -e "\${W}1) Show interfaces    2) Show routing\${N}"
  echo -e "\${W}3) Show connections   4) Test connectivity\${N}"
  echo -e "\${W}5) DNS resolution     6) Network stats\${N}"
  read -p "Choice [1-6]: " net_choice
  
  case \$net_choice in
    1)
      echo -e "\${G}IP Addresses:\${N}"
      ip -br addr show
      echo -e "\n\${G}Network Links:\${N}"
      ip -br link show
      ;;
    2)
      echo -e "\${G}Routing Table:\${N}"
      ip route show
      ;;
    3)
      echo -e "\${G}Active Connections:\${N}"
      ss -tulpn
      ;;
    4)
      read -p "Host to ping: " host
      ping -c 4 "\$host"
      ;;
    5)
      read -p "Domain to resolve: " domain
      dig "\$domain" +short
      ;;
    6)
      echo -e "\${G}Network Statistics:\${N}"
      netstat -i
      ;;
  esac
  ;;
5)
  clear
  echo -e "\${B}════════════ PROCESS MONITORING ════════════\${N}"
  echo -e "\${M}1) Show all processes   2) Show by user\${N}"
  echo -e "\${M}3) Show tree view       4) Kill process\${N}"
  echo -e "\${M}5) Resource top         6) Process search\${N}"
  read -p "Choice [1-6]: " proc_choice
  
  case \$proc_choice in
    1)
      ps aux --sort=-%cpu | head -20
      ;;
    2)
      read -p "Username: " user
      ps -u "\$user"
      ;;
    3)
      pstree -p
      ;;
    4)
      read -p "Process ID: " pid
      kill -9 "\$pid" 2>/dev/null && echo "Process \$pid killed" || echo "Failed to kill process"
      ;;
    5)
      top -n 1 -b | head -30
      ;;
    6)
      read -p "Process name to search: " pname
      pgrep -l "\$pname"
      ;;
  esac
  ;;
6)
  clear
  echo -e "\${B}════════════ STORAGE & FILESYSTEM ════════════\${N}"
  echo -e "\${G}1) Disk usage      2) Inode usage\${N}"
  echo -e "\${G}3) Mount points    4) Find large files\${N}"
  echo -e "\${G}5) Disk space by dir 6) Check disk health\${N}"
  read -p "Choice [1-6]: " disk_choice
  
  case \$disk_choice in
    1)
      df -h
      ;;
    2)
      df -i
      ;;
    3)
      mount | column -t
      ;;
    4)
      read -p "Directory [/]: " dir
      echo -e "\${Y}Searching for files > 100MB...\${N}"
      find "\${dir:-/}" -type f -size +100M 2>/dev/null | head -20
      ;;
    5)
      read -p "Directory [/]: " dir
      du -h --max-depth=1 "\${dir:-/}" 2>/dev/null | sort -hr | head -20
      ;;
    6)
      echo -e "\${Y}Disk Health (requires smartctl):\${N}"
      which smartctl >/dev/null && smartctl -a /dev/sda 2>/dev/null | head -20 || echo "smartctl not installed"
      ;;
  esac
  ;;
7)
  clear
  echo -e "\${B}════════════ USER & SECURITY ════════════\${N}"
  echo -e "\${C}1) List users       2) List groups\${N}"
  echo -e "\${C}3) Add user         4) Change password\${N}"
  echo -e "\${C}5) Who is logged in 6) Check sudo access\${N}"
  read -p "Choice [1-6]: " user_choice
  
  case \$user_choice in
    1)
      cat /etc/passwd | cut -d: -f1,3,4,6,7 | column -t -s:
      ;;
    2)
      cat /etc/group | cut -d: -f1,3 | column -t -s:
      ;;
    3)
      read -p "Username: " newuser
      useradd -m "\$newuser"
      ;;
    4)
      read -p "Username: " user
      passwd "\$user"
      ;;
    5)
      who -a
      ;;
    6)
      echo -e "\${Y}Users with sudo access:\${N}"
      grep -Po '^sudo.+:\K.*$' /etc/group | tr ',' '\n'
      ;;
  esac
  ;;
8)
  clear
  echo -e "\${B}════════════ LOGS & DIAGNOSTICS ════════════\${N}"
  echo -e "\${Y}1) System logs      2) Service logs\${N}"
  echo -e "\${Y}3) Auth logs        4) Kernel logs\${N}"
  echo -e "\${Y}5) Real-time logs   6) Custom log file\${N}"
  read -p "Choice [1-6]: " log_choice
  
  case \$log_choice in
    1)
      if command -v journalctl >/dev/null; then
        journalctl -xe --no-pager | tail -50
      else
        tail -50 /var/log/syslog 2>/dev/null || tail -50 /var/log/messages 2>/dev/null
      fi
      ;;
    2)
      read -p "Service name: " svc
      if command -v journalctl >/dev/null; then
        journalctl -u "\$svc" --no-pager | tail -50
      else
        echo "Service logs not available without journalctl"
      fi
      ;;
    3)
      tail -50 /var/log/auth.log 2>/dev/null || tail -50 /var/log/secure 2>/dev/null
      ;;
    4)
      dmesg | tail -50
      ;;
    5)
      if command -v journalctl >/dev/null; then
        journalctl -f
      else
        tail -f /var/log/syslog 2>/dev/null || tail -f /var/log/messages 2>/dev/null
      fi
      exit 0
      ;;
    6)
      read -p "Log file path: " logfile
      if [ -f "\$logfile" ]; then
        tail -50 "\$logfile"
      else
        echo -e "\${R}File not found\${N}"
      fi
      ;;
  esac
  ;;
9)
  clear
  echo -e "\${B}════════════ CUSTOM COMMAND ════════════\${N}"
  echo -e "\${C}Enter any Linux command to execute:\${N}"
  echo -e "\${Y}Tip: Type 'bash' for interactive shell, 'exit' to return\${N}"
  read -p "Command: " cmd
  if [[ -n "\$cmd" ]]; then
    if [[ "\$cmd" == "bash" ]] || [[ "\$cmd" == "sh" ]]; then
      echo -e "\${G}Starting interactive shell... Type 'exit' to return\${N}"
      \$cmd
    else
      echo -e "\n\${G}Output:\${N}"
      eval "\$cmd"
    fi
  fi
  ;;
10)
  echo -e "\${G}Exiting to host...\${N}"
  sleep 1
  exit 0
  ;;
*)
  echo -e "\${R}Invalid option\${N}"
  sleep 1
  continue
  ;;
esac

echo
read -p "Press Enter to continue..."
done
EOF
}

# Deploy menu to container
section "MENU DEPLOYMENT"
status "Generating distribution-specific menu..."

# Generate and deploy menu
generate_distro_menu "$IMAGE_NAME" | docker exec -i "$CONTAINER_NAME" bash -c 'cat > /root/container-system.sh'

# Make menu executable
docker exec "$CONTAINER_NAME" chmod +x /root/container-system.sh
success "Menu deployed to /root/container-system.sh"

# Enter the container menu
section "ENTERING CONTAINER"
echo -e "${G}Launching management menu...${N}"
echo -e "${Y}Press Ctrl+C to exit and return to host${N}"
echo -e "${C}Use option 10 in the menu for clean exit${N}"
echo -e "${M}Container: $CONTAINER_NAME | Image: $IMAGE_NAME${N}"
echo

sleep 2
docker exec -it "$CONTAINER_NAME" bash /root/container-system.sh

# Post-menu handling
section "SESSION ENDED"

if [ "$NEW_CONTAINER" = true ]; then
    case "$REMOVE_ON_EXIT" in
        "true")
            cleanup
            ;;
        "ask")
            echo -e "${Y}What would you like to do with the container?${N}"
            echo -e "${G}1)${N} Keep running"
            echo -e "${Y}2)${N} Stop container"
            echo -e "${R}3)${N} Remove container"
            read -p "Choice [1-3]: " final_choice
            
            case $final_choice in
                2)
                    docker stop "$CONTAINER_NAME"
                    success "Container stopped"
                    ;;
                3)
                    cleanup
                    ;;
                *)
                    success "Container kept running"
                    ;;
            esac
            ;;
        *)
            success "Container kept running"
            ;;
    esac
fi

# Display management commands
echo -e "\n${C}════════════ MANAGEMENT COMMANDS ════════════${N}"
echo -e "${G}To re-enter this menu:${N}"
echo -e "  docker exec -it $CONTAINER_NAME bash /root/container-system.sh"
echo -e "${G}To get a shell:${N}"
echo -e "  docker exec -it $CONTAINER_NAME bash"
echo -e "${G}Management commands:${N}"
echo -e "  Status:  docker ps -f name=$CONTAINER_NAME"
echo -e "  Stop:    docker stop $CONTAINER_NAME"
echo -e "  Start:   docker start $CONTAINER_NAME"
echo -e "  Restart: docker restart $CONTAINER_NAME"
echo -e "  Remove:  docker rm -f $CONTAINER_NAME"
echo -e "  Logs:    docker logs $CONTAINER_NAME"
echo -e "  Inspect: docker inspect $CONTAINER_NAME"

echo -e "\n${C}Container details:${N}"
echo -e "  Name:    $CONTAINER_NAME"
echo -e "  Image:   $IMAGE_NAME"
echo -e "  IP:      $CONTAINER_IP"
echo -e "  Status:  $(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME")"

success "Script completed successfully!"
