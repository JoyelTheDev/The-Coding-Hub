#!/bin/bash

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION_ID=${VERSION_ID%%.*}  # Get major version only
    elif [ -f /etc/centos-release ]; then
        OS="centos"
        VERSION_ID=$(grep -oP '(?<=release )\d+' /etc/centos-release)
    elif [ -f /etc/rocky-release ]; then
        OS="rocky"
        VERSION_ID=$(grep -oP '(?<=release )\d+' /etc/rocky-release)
    elif [ -f /etc/almalinux-release ]; then
        OS="almalinux"
        VERSION_ID=$(grep -oP '(?<=release )\d+' /etc/almalinux-release)
    else
        echo "Unsupported OS"
        exit 1
    fi
    echo "Detected OS: $OS $VERSION_ID"
}

# Install packages based on OS
install_packages() {
    local os=$1
    local version=$2
    
    case $os in
        "fedora")
            echo "Installing for Fedora..."
            sudo dnf install -y qemu-kvm qemu-img wget lsof cloud-utils-growpart genisoimage
            sudo dnf install -y epel-release
            sudo dnf install -y cloud-utils
            ;;
            
        "centos"|"rocky"|"almalinux"|"rhel")
            if [ "$version" = "8" ] || [ "$version" = "9" ]; then
                echo "Installing for $os $version..."
                sudo dnf install -y qemu-kvm qemu-img wget lsof cloud-utils-growpart genisoimage
                
                # Install EPEL
                if ! rpm -q epel-release > /dev/null 2>&1; then
                    echo "Installing EPEL repository..."
                    case $version in
                        "8")
                            sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
                            ;;
                        "9")
                            sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
                            ;;
                    esac
                fi
                
                sudo dnf install -y epel-release
                sudo dnf install -y cloud-utils
            else
                echo "Unsupported version: $version"
                echo "Only CentOS/Rocky/AlmaLinux 8/9 are supported"
                exit 1
            fi
            ;;
            
        "ubuntu"|"debian")
            echo "Installing for Ubuntu/Debian..."
            sudo apt-get update
            sudo apt-get install -y qemu-kvm qemu-utils wget lsof cloud-guest-utils genisoimage
            sudo apt-get install -y cloud-image-utils
            ;;
            
        *)
            echo "Unsupported OS: $os"
            exit 1
            ;;
    esac
}

# Setup symbolic links and cloud-localds
setup_links() {
    echo "Setting up symbolic links..."
    
    # QEMU link
    if [ -f /usr/libexec/qemu-kvm ]; then
        sudo ln -sf /usr/libexec/qemu-kvm /usr/bin/qemu-system-x86_64 2>/dev/null || true
    elif [ -f /usr/bin/qemu-system-x86_64 ]; then
        echo "qemu-system-x86_64 already exists"
    fi
    
    # cloud-localds setup
    if command -v cloud-localds > /dev/null 2>&1; then
        # If cloud-localds exists in /usr/bin, link it
        if [ -f /usr/bin/cloud-localds ]; then
            sudo ln -sf /usr/bin/cloud-localds /usr/local/bin/cloud-localds 2>/dev/null || true
        fi
    else
        echo "Downloading cloud-localds from GitHub..."
        sudo curl -L -o /usr/local/bin/cloud-localds \
            https://raw.githubusercontent.com/canonical/cloud-utils/main/bin/cloud-localds
        
        if [ $? -ne 0 ]; then
            echo "Trying alternative download method..."
            sudo wget -O /usr/local/bin/cloud-localds \
                https://raw.githubusercontent.com/canonical/cloud-utils/main/bin/cloud-localds \
                --no-check-certificate
        fi
        
        sudo chmod +x /usr/local/bin/cloud-localds
    fi
    
    # Verify cloud-localds
    if ! [ -x "/usr/local/bin/cloud-localds" ]; then
        sudo chmod +x /usr/local/bin/cloud-localds 2>/dev/null || true
    fi
}

# Main execution
main() {
    echo "========================================="
    echo "Auto VM Tools Installer"
    echo "========================================="
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        echo "Warning: Running as root. Please run as normal user with sudo privileges."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Detect OS
    detect_os
    
    # Install packages
    install_packages "$OS" "$VERSION_ID"
    
    # Setup links
    setup_links
    
    # Refresh hash
    hash -r
    
    # Verify installation
    echo ""
    echo "========================================="
    echo "Verification:"
    echo "========================================="
    
    # Check QEMU
    if command -v qemu-system-x86_64 > /dev/null 2>&1; then
        echo "✓ qemu-system-x86_64: $(which qemu-system-x86_64)"
    else
        echo "✗ qemu-system-x86_64 not found"
    fi
    
    # Check cloud-localds
    if command -v cloud-localds > /dev/null 2>&1; then
        echo "✓ cloud-localds: $(which cloud-localds)"
        echo "Testing cloud-localds..."
        /usr/local/bin/cloud-localds --help > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "✓ cloud-localds working correctly"
        else
            echo "✗ cloud-localds has issues"
        fi
    else
        echo "✗ cloud-localds not found"
    fi
    
    # Check other tools
    for tool in qemu-img wget lsof growpart genisoimage; do
        if command -v $tool > /dev/null 2>&1; then
            echo "✓ $tool: $(which $tool)"
        else
            echo "✗ $tool not found"
        fi
    done
    
    echo ""
    echo "========================================="
    echo "Installation complete for $OS $VERSION_ID"
    echo "========================================="
}

# Run main function
main "$@"
