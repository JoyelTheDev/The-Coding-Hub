#!/bin/bash

# ============================================
# LXC/LXD Management Script
# Version: 2.0
# Author: LXC Manager
# ============================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print header
print_header() {
    clear
    echo "==========================================="
    echo "      LXC/LXD Management Script"
    echo "==========================================="
    echo
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_color "$YELLOW" "Warning: Running as root. Some operations might require user permissions."
        return 0
    fi
    return 1
}

# Function to install dependencies for Ubuntu/Debian
install_dependencies() {
    print_header
    print_color "$CYAN" "Installing Dependencies..."
    echo "==========================================="
    
    # Detect distribution
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_NAME=$ID
        OS_VERSION=$VERSION_ID
    else
        print_color "$RED" "Cannot detect OS distribution!"
        exit 1
    fi
    
    print_color "$BLUE" "Detected: $PRETTY_NAME"
    
    case $OS_NAME in
        ubuntu|debian)
            print_color "$GREEN" "Installing for Ubuntu/Debian..."
            
            # Update system
            print_color "$CYAN" "Updating package lists..."
            sudo apt update
            
            # Install basic dependencies
            print_color "$CYAN" "Installing LXC and utilities..."
            sudo apt install -y lxc lxc-utils bridge-utils uidmap
            
            # Install snapd if not present
            if ! command -v snap &> /dev/null; then
                print_color "$CYAN" "Installing snapd..."
                sudo apt install -y snapd
                sudo systemctl enable --now snapd.socket
                sudo ln -s /var/lib/snapd/snap /snap 2>/dev/null || true
            fi
            
            # Install LXD via snap
            print_color "$CYAN" "Installing LXD via snap..."
            sudo snap install lxd
            
            # Add user to lxd group
            print_color "$CYAN" "Adding user to lxd group..."
            sudo usermod -aG lxd $USER
            
            # Initialize LXD
            print_color "$CYAN" "Initializing LXD..."
            sudo lxd init --auto
            
            # Install additional tools
            print_color "$CYAN" "Installing additional tools..."
            sudo apt install -y lxc-templates lxcfs
            
            print_color "$GREEN" "Dependencies installed successfully!"
            ;;
        *)
            print_color "$RED" "Unsupported OS: $OS_NAME"
            print_color "$YELLOW" "Please install manually:"
            echo "For Ubuntu/Debian:"
            echo "  sudo apt install lxc lxc-utils bridge-utils snapd"
            echo "  sudo snap install lxd"
            echo "  sudo usermod -aG lxd \$USER"
            echo "  sudo lxd init"
            exit 1
            ;;
    esac
    
    echo
    print_color "$GREEN" "Please log out and log back in for group changes to take effect!"
    read -p "Press Enter to continue..."
}

# Function to check LXC/LXD installation status
check_installation() {
    print_header
    print_color "$CYAN" "Checking Installation Status..."
    echo "==========================================="
    
    local all_ok=true
    
    # Check LXC
    if command -v lxc &> /dev/null; then
        print_color "$GREEN" "✓ LXC is installed"
    else
        print_color "$RED" "✗ LXC is NOT installed"
        all_ok=false
    fi
    
    # Check LXD
    if command -v lxd &> /dev/null; then
        print_color "$GREEN" "✓ LXD is installed"
    else
        print_color "$RED" "✗ LXD is NOT installed"
        all_ok=false
    fi
    
    # Check LXC version
    if command -v lxc-version &> /dev/null; then
        lxc-version | head -1
    fi
    
    # Check if user is in lxd group
    if groups $USER | grep -q '\blxd\b'; then
        print_color "$GREEN" "✓ User is in lxd group"
    else
        print_color "$YELLOW" "⚠ User is NOT in lxd group"
        all_ok=false
    fi
    
    # Check LXD service status
    if systemctl is-active --quiet lxd; then
        print_color "$GREEN" "✓ LXD service is running"
    else
        print_color "$RED" "✗ LXD service is NOT running"
        all_ok=false
    fi
    
    echo
    if $all_ok; then
        print_color "$GREEN" "All checks passed! LXC/LXD is ready to use."
    else
        print_color "$YELLOW" "Some components are missing or not configured properly."
    fi
    
    read -p "Press Enter to continue..."
}

# Function to list all containers
list_containers() {
    print_header
    print_color "$CYAN" "Listing All Containers..."
    echo "==========================================="
    
    # Check if LXC is available
    if ! command -v lxc &> /dev/null; then
        print_color "$RED" "LXC is not installed!"
        read -p "Press Enter to continue..."
        return
    fi
    
    # List all containers
    lxc list
    
    echo
    print_color "$YELLOW" "Container States:"
    echo "  RUNNING: Container is active"
    echo "  STOPPED: Container is not running"
    echo "  FROZEN: Container is paused"
    echo "  ERROR: Container has an error"
    
    read -p "Press Enter to continue..."
}

# Function to create a new container
create_container() {
    print_header
    print_color "$CYAN" "Create New Container"
    echo "==========================================="
    
    # Get container name
    read -p "Enter container name: " container_name
    if [[ -z "$container_name" ]]; then
        print_color "$RED" "Container name cannot be empty!"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Check if container already exists
    if lxc list -c n --format csv | grep -q "^$container_name$"; then
        print_color "$RED" "Container '$container_name' already exists!"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Show available images
    print_color "$BLUE" "Fetching available images..."
    echo "This may take a moment..."
    
    # List remote images
    echo
    print_color "$YELLOW" "Available remote images:"
    lxc remote list
    
    # Default to images: alias
    read -p "Enter image remote (default: images): " image_remote
    image_remote=${image_remote:-images}
    
    # List images from remote
    print_color "$BLUE" "Available images from $image_remote:"
    lxc image list $image_remote: | head -20
    
    # Get image name
    read -p "Enter image name (e.g.: ubuntu/22.04): " image_name
    if [[ -z "$image_name" ]]; then
        print_color "$RED" "Image name cannot be empty!"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Get container type
    echo
    print_color "$YELLOW" "Container types:"
    echo "  1) Container (default)"
    echo "  2) Virtual Machine"
    read -p "Select container type (1-2, default: 1): " container_type
    container_type=${container_type:-1}
    
    case $container_type in
        1) type_flag="" ;;
        2) type_flag="--vm" ;;
        *) type_flag="" ;;
    esac
    
    # Get container resources
    echo
    print_color "$YELLOW" "Container Resources (leave blank for defaults):"
    read -p "CPU cores (default: 1): " cpu_count
    read -p "Memory in MB (default: 1024): " memory
    read -p "Disk size in GB (default: 10): " disk_size
    
    # Create container
    print_color "$GREEN" "Creating container '$container_name'..."
    
    # Build command
    create_cmd="lxc launch $type_flag $image_remote:$image_name $container_name"
    
    # Add resource limits if specified
    if [[ -n "$cpu_count" ]]; then
        create_cmd="$create_cmd --config limits.cpu=$cpu_count"
    fi
    
    if [[ -n "$memory" ]]; then
        create_cmd="$create_cmd --config limits.memory=${memory}MB"
    fi
    
    if [[ -n "$disk_size" ]]; then
        create_cmd="$create_cmd --config limits.disk=${disk_size}GB"
    fi
    
    # Execute command
    print_color "$CYAN" "Command: $create_cmd"
    echo
    eval $create_cmd
    
    if [[ $? -eq 0 ]]; then
        print_color "$GREEN" "Container '$container_name' created successfully!"
        
        # Show container info
        echo
        print_color "$BLUE" "Container Information:"
        lxc list $container_name
        
        # Ask if user wants to start shell
        read -p "Open shell in container? (y/N): " open_shell
        if [[ "$open_shell" =~ ^[Yy]$ ]]; then
            lxc exec $container_name -- /bin/bash
        fi
    else
        print_color "$RED" "Failed to create container!"
    fi
    
    read -p "Press Enter to continue..."
}

# Function to manage container operations
manage_container() {
    print_header
    print_color "$CYAN" "Manage Container"
    echo "==========================================="
    
    # List containers
    containers=$(lxc list -c n --format csv)
    if [[ -z "$containers" ]]; then
        print_color "$YELLOW" "No containers found!"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Show container list
    echo "Available containers:"
    i=1
    declare -A container_map
    for container in $containers; do
        container_map[$i]=$container
        echo "  $i) $container"
        ((i++))
    done
    
    echo
    read -p "Select container number: " container_num
    
    if [[ -z "${container_map[$container_num]}" ]]; then
        print_color "$RED" "Invalid selection!"
        read -p "Press Enter to continue..."
        return
    fi
    
    container_name=${container_map[$container_num]}
    
    # Container operations menu
    while true; do
        print_header
        print_color "$CYAN" "Managing Container: $container_name"
        echo "==========================================="
        
        # Get container status
        container_status=$(lxc list $container_name -c s --format csv)
        
        print_color "$BLUE" "Status: $container_status"
        echo
        
        print_color "$YELLOW" "Operations:"
        echo "  1) Start Container"
        echo "  2) Stop Container"
        echo "  3) Restart Container"
        echo "  4) Freeze/Pause Container"
        echo "  5) Unfreeze/Resume Container"
        echo "  6) Open Shell"
        echo "  7) Show Info"
        echo "  8) View Logs"
        echo "  9) Configure Container"
        echo "  10) Delete Container"
        echo "  0) Back to Main Menu"
        echo
        
        read -p "Select operation: " operation
        
        case $operation in
            1)
                print_color "$GREEN" "Starting container..."
                lxc start $container_name
                read -p "Press Enter to continue..."
                ;;
            2)
                print_color "$YELLOW" "Stopping container..."
                lxc stop $container_name
                read -p "Press Enter to continue..."
                ;;
            3)
                print_color "$BLUE" "Restarting container..."
                lxc restart $container_name
                read -p "Press Enter to continue..."
                ;;
            4)
                print_color "$PURPLE" "Freezing container..."
                lxc freeze $container_name
                read -p "Press Enter to continue..."
                ;;
            5)
                print_color "$PURPLE" "Unfreezing container..."
                lxc unfreeze $container_name
                read -p "Press Enter to continue..."
                ;;
            6)
                print_color "$CYAN" "Opening shell..."
                lxc exec $container_name -- /bin/bash
                ;;
            7)
                print_color "$BLUE" "Container Information:"
                lxc info $container_name
                read -p "Press Enter to continue..."
                ;;
            8)
                print_color "$BLUE" "Container Logs:"
                lxc info $container_name --show-log
                read -p "Press Enter to continue..."
                ;;
            9)
                configure_container $container_name
                ;;
            10)
                print_color "$RED" "WARNING: This will delete the container!"
                read -p "Are you sure? (y/N): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    lxc delete $container_name --force
                    print_color "$GREEN" "Container deleted!"
                    read -p "Press Enter to continue..."
                    return
                fi
                ;;
            0)
                return
                ;;
            *)
                print_color "$RED" "Invalid operation!"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Function to configure container
configure_container() {
    local container_name=$1
    
    while true; do
        print_header
        print_color "$CYAN" "Configure Container: $container_name"
        echo "==========================================="
        
        print_color "$YELLOW" "Configuration Options:"
        echo "  1) Set CPU Limits"
        echo "  2) Set Memory Limits"
        echo "  3) Set Disk Limits"
        echo "  4) Add/Remove Devices"
        echo "  5) Network Configuration"
        echo "  6) Security Policies"
        echo "  7) View All Config"
        echo "  0) Back"
        echo
        
        read -p "Select option: " config_option
        
        case $config_option in
            1)
                read -p "Enter CPU limit (e.g., 2 or 0-4): " cpu_limit
                lxc config set $container_name limits.cpu "$cpu_limit"
                print_color "$GREEN" "CPU limit set to: $cpu_limit"
                read -p "Press Enter to continue..."
                ;;
            2)
                read -p "Enter memory limit (e.g., 2GB or 512MB): " memory_limit
                lxc config set $container_name limits.memory "$memory_limit"
                print_color "$GREEN" "Memory limit set to: $memory_limit"
                read -p "Press Enter to continue..."
                ;;
            3)
                read -p "Enter disk limit (e.g., 20GB): " disk_limit
                lxc config device set $container_name root size="$disk_limit"
                print_color "$GREEN" "Disk limit set to: $disk_limit"
                read -p "Press Enter to continue..."
                ;;
            4)
                echo "Current devices:"
                lxc config device list $container_name
                echo
                echo "1) Add device"
                echo "2) Remove device"
                read -p "Select: " device_op
                
                case $device_op in
                    1)
                        read -p "Device name: " device_name
                        read -p "Device type (disk, nic, unix-char, etc.): " device_type
                        read -p "Source path: " device_source
                        read -p "Destination path: " device_dest
                        lxc config device add $container_name $device_name $device_type source=$device_source path=$device_dest
                        ;;
                    2)
                        read -p "Device name to remove: " device_name
                        lxc config device remove $container_name $device_name
                        ;;
                esac
                read -p "Press Enter to continue..."
                ;;
            5)
                echo "Network interfaces:"
                lxc network list
                echo
                read -p "Enter network name to attach (default: lxdbr0): " network_name
                network_name=${network_name:-lxdbr0}
                lxc network attach $network_name $container_name eth0
                print_color "$GREEN" "Attached to network: $network_name"
                read -p "Press Enter to continue..."
                ;;
            6)
                echo "Security options:"
                echo "1) Enable/disable nesting"
                echo "2) Set security.privileged"
                read -p "Select: " security_op
                
                case $security_op in
                    1)
                        current=$(lxc config get $container_name security.nesting)
                        echo "Current nesting: $current"
                        read -p "Enable nesting? (true/false): " nesting_val
                        lxc config set $container_name security.nesting $nesting_val
                        ;;
                    2)
                        current=$(lxc config get $container_name security.privileged)
                        echo "Current privileged: $current"
                        read -p "Set privileged? (true/false): " priv_val
                        lxc config set $container_name security.privileged $priv_val
                        ;;
                esac
                read -p "Press Enter to continue..."
                ;;
            7)
                print_color "$BLUE" "Container Configuration:"
                lxc config show $container_name
                read -p "Press Enter to continue..."
                ;;
            0)
                return
                ;;
            *)
                print_color "$RED" "Invalid option!"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Function to manage storage pools
manage_storage() {
    print_header
    print_color "$CYAN" "Storage Management"
    echo "==========================================="
    
    while true; do
        echo "Storage Operations:"
        echo "  1) List Storage Pools"
        echo "  2) Create Storage Pool"
        echo "  3) Delete Storage Pool"
        echo "  4) List Volumes"
        echo "  5) Create Volume"
        echo "  6) Delete Volume"
        echo "  0) Back"
        echo
        
        read -p "Select operation: " storage_op
        
        case $storage_op in
            1)
                print_color "$BLUE" "Storage Pools:"
                lxc storage list
                read -p "Press Enter to continue..."
                ;;
            2)
                read -p "Enter pool name: " pool_name
                read -p "Enter pool driver (dir, btrfs, lvm, zfs): " pool_driver
                read -p "Enter source (path or device): " pool_source
                
                if [[ -n "$pool_source" ]]; then
                    lxc storage create $pool_name $pool_driver source=$pool_source
                else
                    lxc storage create $pool_name $pool_driver
                fi
                read -p "Press Enter to continue..."
                ;;
            3)
                read -p "Enter pool name to delete: " pool_name
                print_color "$RED" "WARNING: This will delete ALL data in the pool!"
                read -p "Are you sure? (y/N): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    lxc storage delete $pool_name
                fi
                read -p "Press Enter to continue..."
                ;;
            4)
                print_color "$BLUE" "Storage Volumes:"
                lxc storage volume list
                read -p "Press Enter to continue..."
                ;;
            5)
                read -p "Enter pool name: " pool_name
                read -p "Enter volume name: " volume_name
                read -p "Enter volume size (e.g., 10GB): " volume_size
                
                lxc storage volume create $pool_name $volume_name size=$volume_size
                read -p "Press Enter to continue..."
                ;;
            6)
                read -p "Enter pool name: " pool_name
                read -p "Enter volume name: " volume_name
                
                lxc storage volume delete $pool_name $volume_name
                read -p "Press Enter to continue..."
                ;;
            0)
                return
                ;;
            *)
                print_color "$RED" "Invalid operation!"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Function to manage networks
manage_networks() {
    print_header
    print_color "$CYAN" "Network Management"
    echo "==========================================="
    
    while true; do
        echo "Network Operations:"
        echo "  1) List Networks"
        echo "  2) Show Network Info"
        echo "  3) Create Network"
        echo "  4) Delete Network"
        echo "  5) Attach Container to Network"
        echo "  6) Detach Container from Network"
        echo "  0) Back"
        echo
        
        read -p "Select operation: " network_op
        
        case $network_op in
            1)
                print_color "$BLUE" "Available Networks:"
                lxc network list
                read -p "Press Enter to continue..."
                ;;
            2)
                read -p "Enter network name: " network_name
                lxc network show $network_name
                read -p "Press Enter to continue..."
                ;;
            3)
                read -p "Enter network name: " network_name
                read -p "Network type (bridge, ovn, etc.): " network_type
                read -p "IPv4 address (e.g., 10.10.10.1/24): " ipv4_addr
                read -p "IPv6 address (leave empty for none): " ipv6_addr
                
                lxc network create $network_name type=$network_type
                
                if [[ -n "$ipv4_addr" ]]; then
                    lxc network set $network_name ipv4.address "$ipv4_addr"
                fi
                
                if [[ -n "$ipv6_addr" ]]; then
                    lxc network set $network_name ipv6.address "$ipv6_addr"
                fi
                
                read -p "Press Enter to continue..."
                ;;
            4)
                read -p "Enter network name to delete: " network_name
                print_color "$RED" "WARNING: Containers using this network will be affected!"
                read -p "Are you sure? (y/N): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    lxc network delete $network_name
                fi
                read -p "Press Enter to continue..."
                ;;
            5)
                read -p "Enter container name: " container_name
                read -p "Enter network name: " network_name
                read -p "Enter interface name (default: eth0): " iface_name
                iface_name=${iface_name:-eth0}
                
                lxc network attach $network_name $container_name $iface_name
                read -p "Press Enter to continue..."
                ;;
            6)
                read -p "Enter container name: " container_name
                read -p "Enter interface name (e.g., eth0): " iface_name
                
                lxc network detach $network_name $container_name $iface_name
                read -p "Press Enter to continue..."
                ;;
            0)
                return
                ;;
            *)
                print_color "$RED" "Invalid operation!"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Function to show system information
show_system_info() {
    print_header
    print_color "$CYAN" "System Information"
    echo "==========================================="
    
    echo "LXC/LXD Information:"
    echo "-------------------"
    
    # LXC version
    if command -v lxc-version &> /dev/null; then
        echo -n "LXC Version: "
        lxc-version | head -1
    fi
    
    # LXD version
    if command -v lxd &> /dev/null; then
        echo -n "LXD Version: "
        lxd --version
    fi
    
    # LXC info
    if command -v lxc &> /dev/null; then
        echo
        echo "LXC Info:"
        lxc info
        
        echo
        echo "Storage Pools:"
        lxc storage list
        
        echo
        echo "Networks:"
        lxc network list
        
        echo
        echo "Container Count:"
        lxc list --format csv | wc -l
    fi
    
    echo
    echo "System Information:"
    echo "------------------"
    
    # OS info
    echo -n "OS: "
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$PRETTY_NAME"
    fi
    
    # Kernel
    echo -n "Kernel: "
    uname -r
    
    # Memory
    echo -n "Memory: "
    free -h | awk '/^Mem:/ {print $2}'
    
    # CPU
    echo -n "CPU: "
    nproc
    echo -n "CPU Model: "
    grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//'
    
    # Disk
    echo -n "Disk Space: "
    df -h / | awk 'NR==2 {print $4}'
    
    echo
    read -p "Press Enter to continue..."
}

# Function to show quick commands
show_quick_commands() {
    print_header
    print_color "$CYAN" "Quick LXC/LXD Commands"
    echo "==========================================="
    
    print_color "$YELLOW" "Container Operations:"
    echo "  lxc list                   # List all containers"
    echo "  lxc launch image name      # Create and start container"
    echo "  lxc start name             # Start container"
    echo "  lxc stop name              # Stop container"
    echo "  lxc restart name           # Restart container"
    echo "  lxc delete name            # Delete container"
    echo "  lxc exec name -- command   # Execute command in container"
    echo "  lxc exec name -- bash      # Open shell in container"
    echo "  lxc info name              # Show container info"
    
    print_color "$YELLOW" "Image Operations:"
    echo "  lxc image list             # List available images"
    echo "  lxc image copy src dst     # Copy image"
    echo "  lxc image delete name      # Delete image"
    
    print_color "$YELLOW" "Network Operations:"
    echo "  lxc network list           # List networks"
    echo "  lxc network create name    # Create network"
    echo "  lxc network attach net container # Attach network"
    
    print_color "$YELLOW" "Storage Operations:"
    echo "  lxc storage list           # List storage pools"
    echo "  lxc storage create name    # Create storage pool"
    echo "  lxc storage volume list    # List volumes"
    
    print_color "$YELLOW" "Configuration:"
    echo "  lxc config set name key=value  # Set config"
    echo "  lxc config show name       # Show config"
    echo "  lxc config edit name       # Edit config in editor"
    
    print_color "$YELLOW" "Snapshot Operations:"
    echo "  lxc snapshot name snap     # Create snapshot"
    echo "  lxc restore name snap      # Restore snapshot"
    echo "  lxc copy name/snap newname # Copy snapshot to new container"
    
    echo
    read -p "Press Enter to continue..."
}

# Function to show advanced features
show_advanced_features() {
    print_header
    print_color "$CYAN" "Advanced LXC/LXD Features"
    echo "==========================================="
    
    echo "1) Container Migration"
    echo "   lxc copy name remote:name  # Copy container to remote"
    echo "   lxc move name new-name     # Rename container"
    echo "   lxc publish name           # Create image from container"
    
    echo
    echo "2) Resource Limits"
    echo "   lxc config set name limits.cpu=2"
    echo "   lxc config set name limits.memory=2GB"
    echo "   lxc config set name limits.disk=20GB"
    
    echo
    echo "3) Device Management"
    echo "   lxc config device add name disk1 disk source=/path path=/mnt"
    echo "   lxc config device add name gpu gpu"
    echo "   lxc config device add name usb usb vendorid=1234"
    
    echo
    echo "4) Profiles"
    echo "   lxc profile list           # List profiles"
    echo "   lxc profile create name    # Create profile"
    echo "   lxc profile copy src dst   # Copy profile"
    echo "   lxc profile apply name profile # Apply profile to container"
    
    echo
    echo "5) Remote Servers"
    echo "   lxc remote list            # List remotes"
    echo "   lxc remote add name IP     # Add remote server"
    echo "   lxc remote switch name     # Switch default remote"
    
    echo
    echo "6) Clustering"
    echo "   lxc cluster list           # List cluster members"
    echo "   lxc cluster enable         # Enable clustering"
    echo "   lxc cluster add node       # Add node to cluster"
    
    echo
    read -p "Press Enter to continue..."
}

# Function to create container from backup
container_backup() {
    print_header
    print_color "$CYAN" "Container Backup/Restore"
    echo "==========================================="
    
    while true; do
        echo "Backup Operations:"
        echo "  1) Create Backup"
        echo "  2) Restore from Backup"
        echo "  3) List Backups"
        echo "  4) Delete Backup"
        echo "  0) Back"
        echo
        
        read -p "Select operation: " backup_op
        
        case $backup_op in
            1)
                read -p "Enter container name: " container_name
                read -p "Enter backup name: " backup_name
                lxc export $container_name $backup_name
                print_color "$GREEN" "Backup created: $backup_name"
                read -p "Press Enter to continue..."
                ;;
            2)
                read -p "Enter backup file: " backup_file
                read -p "Enter new container name: " new_name
                lxc import $backup_file $new_name
                read -p "Press Enter to continue..."
                ;;
            3)
                echo "Available backups:"
                ls -la *.tar.gz 2>/dev/null || echo "No backups found"
                read -p "Press Enter to continue..."
                ;;
            4)
                read -p "Enter backup file to delete: " backup_file
                rm -i $backup_file
                read -p "Press Enter to continue..."
                ;;
            0)
                return
                ;;
            *)
                print_color "$RED" "Invalid operation!"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Function to create profiles
manage_profiles() {
    print_header
    print_color "$CYAN" "Profile Management"
    echo "==========================================="
    
    while true; do
        echo "Profile Operations:"
        echo "  1) List Profiles"
        echo "  2) Create Profile"
        echo "  3) Edit Profile"
        echo "  4) Delete Profile"
        echo "  5) Apply Profile to Container"
        echo "  0) Back"
        echo
        
        read -p "Select operation: " profile_op
        
        case $profile_op in
            1)
                print_color "$BLUE" "Available Profiles:"
                lxc profile list
                read -p "Press Enter to continue..."
                ;;
            2)
                read -p "Enter profile name: " profile_name
                lxc profile create $profile_name
                print_color "$GREEN" "Profile '$profile_name' created"
                read -p "Press Enter to continue..."
                ;;
            3)
                read -p "Enter profile name to edit: " profile_name
                lxc profile edit $profile_name
                read -p "Press Enter to continue..."
                ;;
            4)
                read -p "Enter profile name to delete: " profile_name
                lxc profile delete $profile_name
                read -p "Press Enter to continue..."
                ;;
            5)
                read -p "Enter container name: " container_name
                read -p "Enter profile name: " profile_name
                lxc profile apply $container_name $profile_name
                read -p "Press Enter to continue..."
                ;;
            0)
                return
                ;;
            *)
                print_color "$RED" "Invalid operation!"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Main menu function
main_menu() {
    while true; do
        print_header
        
        print_color "$GREEN" "Main Menu:"
        echo "  1) 📦 Install Dependencies"
        echo "  2) ✅ Check Installation"
        echo "  3) 📋 List Containers"
        echo "  4) 🆕 Create Container"
        echo "  5) ⚙️  Manage Container"
        echo "  6) 💾 Storage Management"
        echo "  7) 🌐 Network Management"
        echo "  8) 📊 System Information"
        echo "  9) ⚡ Quick Commands"
        echo "  10) 🚀 Advanced Features"
        echo "  11) 💾 Backup/Restore"
        echo "  12) 👤 Profile Management"
        echo "  0) 👋 Exit"
        echo
        
        read -p "Select option: " choice
        
        case $choice in
            1) install_dependencies ;;
            2) check_installation ;;
            3) list_containers ;;
            4) create_container ;;
            5) manage_container ;;
            6) manage_storage ;;
            7) manage_networks ;;
            8) show_system_info ;;
            9) show_quick_commands ;;
            10) show_advanced_features ;;
            11) container_backup ;;
            12) manage_profiles ;;
            0)
                print_color "$GREEN" "Goodbye!"
                exit 0
                ;;
            *)
                print_color "$RED" "Invalid option! Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Check if LXC is available, if not show warning
check_lxc_availability() {
    if ! command -v lxc &> /dev/null; then
        print_header
        print_color "$YELLOW" "⚠️  LXC/LXD is not installed!"
        echo "==========================================="
        echo
        print_color "$CYAN" "Would you like to install dependencies now?"
        echo "This will install LXC, LXD, and required packages."
        echo
        
        read -p "Install dependencies? (Y/n): " install_choice
        install_choice=${install_choice:-Y}
        
        if [[ "$install_choice" =~ ^[Yy]$ ]]; then
            install_dependencies
        else
            print_color "$YELLOW" "You can install manually with option 1 from the main menu."
            read -p "Press Enter to continue..."
        fi
    fi
}

# Main execution
main() {
    # Check if we're in a terminal
    if [[ ! -t 0 ]]; then
        print_color "$RED" "This script must be run in a terminal!"
        exit 1
    fi
    
    # Welcome message
    print_header
    print_color "$GREEN" "Welcome to LXC/LXD Management Script"
    echo
    
    # Check LXC availability
    check_lxc_availability
    
    # Start main menu
    main_menu
}

# Run main function
main
