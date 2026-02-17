#!/bin/bash
# ============================================
# THE CODING HUB - UI LIBRARY v2.0
# ============================================

# Color Palette
declare -A COLORS=(
    [primary]='\033[38;5;75m'
    [secondary]='\033[38;5-141m'
    [accent]='\033[38;5-214m'
    [success]='\033[38;5-71m'
    [warning]='\033[38;5-220m'
    [error]='\033[38;5-196m'
    [info]='\033[38;5-51m'
    [reset]='\033[0m'
)

# Gradient Text Effect
gradient_text() {
    local text="$1"
    local colors=("\033[38;5-75m" "\033[38;5-141m" "\033[38;5-214m")
    local len=${#text}
    for ((i=0; i<len; i++)); do
        local color_idx=$((i * 3 / len))
        echo -ne "${colors[$color_idx]}${text:$i:1}"
    done
    echo -e "${COLORS[reset]}"
}

# Animated Banner
animated_banner() {
    clear
    local banner=(
        "██████╗  ██████╗ ████████╗███████╗███╗   ███╗"
        "██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝████╗ ████║"
        "██████╔╝██║   ██║   ██║   █████╗  ██╔████╔██║"
        "██╔══██╗██║   ██║   ██║   ██╔══╝  ██║╚██╔╝██║"
        "██████╔╝╚██████╔╝   ██║   ███████╗██║ ╚═╝ ██║"
        "╚═════╝  ╚═════╝    ╚═╝   ╚══════╝╚═╝     ╚═╝"
    )
    
    for line in "${banner[@]}"; do
        echo -e "${COLORS[primary]}$line${COLORS[reset]}"
        sleep 0.05
    done
    echo ""
    gradient_text "═══ THE CODING HUB v2.0 ═══"
    echo ""
}
# Progress Bar with Percentage
progress_bar() {
    local duration=$1
    local message=$2
    local steps=50
    local delay=$(echo "scale=3; $duration/$steps" | bc)
    
    echo -ne "${COLORS[info]}$message ${COLORS[reset]}"
    echo -ne "["
    
    for ((i=0; i<=steps; i++)); do
        local percent=$((i * 100 / steps))
        local filled=$((i / 2))
        local empty=$((25 - filled))
        
        printf "\r${COLORS[info]}$message ["
        printf "${COLORS[success]}"
        for ((j=0; j<filled; j++)); do printf "█"; done
        printf "${COLORS[warning]}"
        for ((j=0; j<empty; j++)); do printf "░"; done
        printf "${COLORS[info]}] %3d%%${COLORS[reset]}" $percent
        
        sleep $delay
    done
    echo ""
}

# Interactive Menu with Icons
fancy_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    echo -e "${COLORS[primary]}╔════════════════════════════════════════════╗${COLORS[reset]}"
    echo -e "${COLORS[primary]}║${COLORS[reset]}  ${COLORS[accent]}$title${COLORS[reset]}${COLORS[primary]}║${COLORS[reset]}"
    echo -e "${COLORS[primary]}╠════════════════════════════════════════════╣${COLORS[reset]}"
    
    local i=1
    for option in "${options[@]}"; do
        echo -e "${COLORS[primary]}║${COLORS[reset]}  ${COLORS[success]}[$i]${COLORS[reset]} $option${COLORS[primary]}║${COLORS[reset]}"
        ((i++))
    done
    
    echo -e "${COLORS[primary]}╚════════════════════════════════════════════╝${COLORS[reset]}"
}

# Status Indicator
status_indicator() {
    local status=$1
    local message=$2    
    case $status in
        "success")
            echo -e "${COLORS[success]}✓${COLORS[reset]} $message"
            ;;
        "error")
            echo -e "${COLORS[error]}✗${COLORS[reset]} $message"
            ;;
        "warning")
            echo -e "${COLORS[warning]}⚠${COLORS[reset]} $message"
            ;;
        "info")
            echo -e "${COLORS[info]}ℹ${COLORS[reset]} $message"
            ;;
    esac
}

# Loading Spinner
spinner() {
    local pid=$1
    local message=$2
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r${COLORS[info]}$message ${spinstr:0:1}${COLORS[reset]}"
        local spinstr=$temp${spinstr%"$temp"}
        sleep 0.1
    done
    printf "\r${COLORS[success]}✓${COLORS[reset]} $message${COLORS[reset]}    \n"
}

# Boxed Message
boxed_message() {
    local message="$1"
    local color="${2:-${COLORS[info]}}"
    local width=60
    local padding=$(( (width - ${#message} - 2) / 2 ))
    
    echo -e "${color}┌$(printf '─%.0s' $(seq 1 $((width-2))))┐${COLORS[reset]}"
    printf "${color}│%*s%s%*s│${COLORS[reset]}\n" $padding "" "$message" $((padding - ((${#message} % 2) ? 1 : 0))) ""
    echo -e "${color}└$(printf '─%.0s' $(seq 1 $((width-2))))┘${COLORS[reset]}"
}

# Confirmation Dialog
confirm_dialog() {
    local message="$1"
    local default="${2:-n}"
        echo -ne "${COLORS[warning]}⚠ $message ${COLORS[success]}[Y/n]${COLORS[reset]} "
    read -r confirm
    
    if [[ -z "$confirm" ]]; then
        confirm=$default
    fi
    
    [[ "$confirm" =~ ^[Yy]$ ]]
}

# Export Functions
export -f gradient_text animated_banner progress_bar fancy_menu
export -f status_indicator spinner boxed_message confirm_dialog
