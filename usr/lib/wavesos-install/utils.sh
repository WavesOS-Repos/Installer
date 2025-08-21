
#!/bin/bash

# WavesOS Installation Script - Utilities Library
# Contains logging, UI, and basic utility functions
# Enhanced with futuristic CLI interface

# Advanced color palette for futuristic UI
# Primary colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Futuristic color palette
NEON_BLUE='\033[38;5;39m'
NEON_GREEN='\033[38;5;46m'
NEON_PURPLE='\033[38;5;99m'
NEON_PINK='\033[38;5;213m'
NEON_ORANGE='\033[38;5;208m'
NEON_CYAN='\033[38;5;51m'
DARK_GRAY='\033[38;5;240m'
LIGHT_GRAY='\033[38;5;248m'
GOLD='\033[38;5;220m'
SILVER='\033[38;5;252m'

# Terminal effects
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
REVERSE='\033[7m'
HIDDEN='\033[8m'

# Cursor control
SAVE_CURSOR='\033[s'
RESTORE_CURSOR='\033[u'
CLEAR_LINE='\033[K'
CLEAR_SCREEN='\033[2J'
HOME_CURSOR='\033[H'

# Animation characters
SPINNER_CHARS=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
PROGRESS_CHARS=("█" "▓" "▒" "░")
WAVE_CHARS=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" "▇" "▆" "▅" "▄" "▃" "▂" "▁")

# Global variables for UI state
CURRENT_STEP=0
TOTAL_STEPS=0
ANIMATION_PID=""
UI_MODE="futuristic"

# Terminal size detection
get_terminal_size() {
    TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
    TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
}

# Initialize terminal for enhanced UI
init_terminal() {
    get_terminal_size
    # Enable cursor positioning
    echo -en "\033[?25h"
    # Clear screen
    clear
}

# Advanced logging functions with futuristic styling
log() {
    local timestamp=$(date +'%H:%M:%S')
    echo -e "${NEON_CYAN}${BOLD}[${timestamp}]${NC} ${NEON_GREEN}${BOLD}➤${NC} $1"
}

error() {
    local timestamp=$(date +'%H:%M:%S')
    echo -e "${NEON_PINK}${BOLD}[${timestamp}]${NC} ${RED}${BOLD}✗${NC} $1" >&2
    exit 1
}

warning() {
    local timestamp=$(date +'%H:%M:%S')
    echo -e "${NEON_ORANGE}${BOLD}[${timestamp}]${NC} ${YELLOW}${BOLD}⚠${NC} $1"
}

info() {
    local timestamp=$(date +'%H:%M:%S')
    echo -e "${NEON_BLUE}${BOLD}[${timestamp}]${NC} ${BLUE}${BOLD}ℹ${NC} $1"
}

success() {
    local timestamp=$(date +'%H:%M:%S')
    echo -e "${NEON_GREEN}${BOLD}[${timestamp}]${NC} ${GREEN}${BOLD}✓${NC} $1"
}

# Futuristic progress bar with wave animation
show_progress() {
    local current=$1
    local total=$2
    local desc="$3"
    local percent=$((current * 100 / total))
    local bar_width=$((TERM_WIDTH - 20))
    local filled=$((bar_width * current / total))
    local empty=$((bar_width - filled))
    
    # Save cursor position
    echo -en "$SAVE_CURSOR"
    
    # Clear line and show progress
    printf "\r${CLEAR_LINE}"
    printf "${NEON_PURPLE}${BOLD}[%3d%%]${NC} " "$percent"
    
    # Animated progress bar
    printf "${NEON_CYAN}[${NC}"
    if [ "$filled" -gt 0 ]; then
        printf "%*s" "$filled" | tr ' ' '█'
    fi
    if [ "$empty" -gt 0 ]; then
        printf "%*s" "$empty" | tr ' ' '░'
    fi
    printf "${NEON_CYAN}]${NC} "
    
    # Wave animation for description
    local wave_idx=$((current % ${#WAVE_CHARS[@]}))
    printf "${NEON_GREEN}${WAVE_CHARS[$wave_idx]}${NC} ${desc}"
    
    if [ "$current" -eq "$total" ]; then
        echo
        echo -en "$RESTORE_CURSOR"
    fi
}

# Spinning animation
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    local i=0
    
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r${NEON_CYAN}${BOLD}[%c]${NC} Processing..." "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\r${CLEAR_LINE}"
}

# Futuristic banner with animated elements
show_banner() {
    clear
    init_terminal
    
    # Animated color cycling banner
    local colors=("$NEON_BLUE" "$NEON_PURPLE" "$NEON_CYAN" "$NEON_GREEN" "$NEON_PINK")
    local color_idx=0
    
    echo -e "${colors[$color_idx]}${BOLD}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                                      ║
║  ██╗    ██╗ █████╗ ██╗   ██╗███████╗███████╗ ██████╗ ███████╗    ██╗███╗   ██╗███████╗████████╗    ║
║  ██║    ██║██╔══██╗██║   ██║██╔════╝██╔════╝██╔═══██╗██╔════╝    ██║████╗  ██║██╔════╝╚══██╔══╝    ║
║  ██║ █╗ ██║███████║██║   ██║█████╗  ███████╗██║   ██║███████╗    ██║██╔██╗ ██║███████╗   ██║       ║
║  ██║███╗██║██╔══██║╚██╗ ██╔╝██╔══╝  ╚════██║██║   ██║╚════██║    ██║██║╚██╗██║╚════██║   ██║       ║
║  ╚███╔███╔╝██║  ██║ ╚████╔╝ ███████╗███████║╚██████╔╝███████║    ██║██║ ╚████║███████║   ██║       ║
║   ╚══╝╚══╝ ╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚══════╝ ╚═════╝ ╚══════╝    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝       ║
║                                                                                                      ║
║                                    ════════════════════════════════                                    ║
║                                    🚀 FUTURISTIC INSTALLER v3.0 🚀                                    ║
║                                    ════════════════════════════════                                    ║
╚══════════════════════════════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Animated subtitle
    echo -e "${NEON_CYAN}${BOLD}${ITALIC}    Preparing to unlock the future of computing...${NC}"
    echo -e "${DARK_GRAY}    Terminal: ${TERM_WIDTH}x${TERM_HEIGHT} | Mode: ${UI_MODE^^} | Time: $(date +'%H:%M:%S')${NC}"
    echo
}

# Futuristic selection menu
select_option() {
    local prompt="$1"
    local options=("${@:2}")
    local selected=0
    local count=${#options[@]}
    
    echo -e "${NEON_PURPLE}${BOLD}$prompt${NC}"
    echo
    
    while true; do
        # Clear previous menu
        for ((i=0; i<count+2; i++)); do
            echo -en "\033[A\033[K"
        done
        
        # Show current selection
        for ((i=0; i<count; i++)); do
            if [ $i -eq $selected ]; then
                echo -e "${NEON_CYAN}${BOLD}  ▶ ${NEON_GREEN}${options[$i]}${NC}"
            else
                echo -e "${DARK_GRAY}    ${options[$i]}${NC}"
            fi
        done
        
        # Read key
        read -rsn1 key
        case "$key" in
            $'\x1b')
                read -rsn2 key
                case "$key" in
                    "[A") # Up arrow
                        selected=$((selected - 1))
                        [ $selected -lt 0 ] && selected=$((count - 1))
                        ;;
                    "[B") # Down arrow
                        selected=$((selected + 1))
                        [ $selected -ge $count ] && selected=0
                        ;;
                esac
                ;;
            "") # Enter
                echo
                return $selected
                ;;
        esac
    done
}

# Futuristic confirmation dialog
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    echo -e "${NEON_ORANGE}${BOLD}⚠  $message${NC}"
    echo -e "${DARK_GRAY}    [${NEON_GREEN}y${DARK_GRAY}/${NEON_RED}N${DARK_GRAY}]${NC} "
    
    read -r response
    if [[ "${response,,}" =~ ^(y|yes)$ ]] || [[ "$default" == "y" && -z "$response" ]]; then
        return 0
    else
        return 1
    fi
}

# Animated status display
show_status() {
    local status="$1"
    local message="$2"
    local icon=""
    
    case "$status" in
        "checking") icon="${NEON_BLUE}🔍${NC}" ;;
        "installing") icon="${NEON_GREEN}⚡${NC}" ;;
        "configuring") icon="${NEON_PURPLE}⚙️${NC}" ;;
        "success") icon="${NEON_GREEN}✅${NC}" ;;
        "error") icon="${NEON_PINK}❌${NC}" ;;
        "warning") icon="${NEON_ORANGE}⚠️${NC}" ;;
        *) icon="${NEON_CYAN}ℹ️${NC}" ;;
    esac
    
    echo -e "$icon ${BOLD}$message${NC}"
}

# Step counter with visual progress
init_steps() {
    TOTAL_STEPS=$1
    CURRENT_STEP=0
    echo -e "${NEON_PURPLE}${BOLD}📋 Total Steps: $TOTAL_STEPS${NC}"
    echo
}

next_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo -e "${NEON_CYAN}${BOLD}🔄 Step $CURRENT_STEP/$TOTAL_STEPS${NC}"
}

# Enhanced check functions with futuristic UI
check_root() {
    show_status "checking" "Verifying root privileges..."
    if [ "$EUID" -ne 0 ]; then
        error "Please run as root with sudo"
    fi
    show_status "success" "Root privileges confirmed"
}

check_live_env() {
    show_status "checking" "Detecting live environment..."
    if ! grep -q "archiso" /proc/cmdline 2>/dev/null; then
        warning "This script is designed to run from Arch Linux live environment"
        if ! confirm_action "Continue anyway?"; then
            error "Installation cancelled"
        fi
    fi
    show_status "success" "Live environment detected"
}

check_tools() {
    local tools=(parted mkfs.fat mkfs.ext4 pacstrap arch-chroot genfstab grub-install reflector lsblk blkid rsync git efibootmgr)
    
    show_status "checking" "Verifying required tools..."
    for cmd in "${tools[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            error "$cmd is required but not installed"
        fi
    done
    show_status "success" "All required tools are available"
}

check_network() {
    show_status "checking" "Testing network connectivity..."
    if ! ping -c 3 -W 5 archlinux.org &>/dev/null; then
        error "No internet connection detected. Please connect to a network and try again."
    fi
    show_status "success" "Network connectivity confirmed"
}

update_clock() {
    show_status "configuring" "Synchronizing system clock..."
    timedatectl set-ntp true
    sleep 2
    show_status "success" "System clock synchronized"
}

# Enhanced cleanup with visual feedback
cleanup_installation() {
    show_status "configuring" "Cleaning up and unmounting filesystems..."
    
    # Disable swap if enabled
    if [ "${SWAP_SIZE:-0}" -gt 0 ]; then
        swapoff "$SWAP_PART" 2>/dev/null || true
    fi
    
    # Unmount in reverse order
    umount /mnt/home/storage 2>/dev/null || true
    umount /mnt/boot 2>/dev/null || true
    umount /mnt 2>/dev/null || true
    
    show_status "success" "Cleanup completed"
}

# Futuristic installation summary
show_installation_summary() {
    echo
    echo -e "${NEON_CYAN}${BOLD}╔══════════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${NEON_CYAN}${BOLD}║                                    🎉 INSTALLATION COMPLETE 🎉                                    ║${NC}"
    echo -e "${NEON_CYAN}${BOLD}╚══════════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Animated success message
    local success_msg="WavesOS has been installed successfully!"
    for ((i=0; i<${#success_msg}; i++)); do
        echo -en "${NEON_GREEN}${BOLD}${success_msg:$i:1}${NC}"
        sleep 0.05
    done
    echo
    echo
    
    # Installation details in a futuristic table
    echo -e "${NEON_PURPLE}${BOLD}📊 Installation Summary:${NC}"
    echo -e "${DARK_GRAY}┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${DARK_GRAY}│${NC} ${NEON_CYAN}${BOLD}System Disk:${NC} ${SILVER}$SYS_DISK${NC}${DARK_GRAY}${NC}"
    echo -e "${DARK_GRAY}│${NC} ${NEON_CYAN}${BOLD}Boot Mode:${NC}   ${SILVER}$BOOT_MODE${NC}${DARK_GRAY}${NC}"
    echo -e "${DARK_GRAY}│${NC} ${NEON_CYAN}${BOLD}Hostname:${NC}    ${SILVER}$HOSTNAME${NC}${DARK_GRAY}${NC}"
    echo -e "${DARK_GRAY}│${NC} ${NEON_CYAN}${BOLD}Username:${NC}    ${SILVER}$USERNAME${NC}${DARK_GRAY}${NC}"
    echo -e "${DARK_GRAY}│${NC} ${NEON_CYAN}${BOLD}Desktop:${NC}     ${SILVER}Hyprland with WavesOS configs${NC}${DARK_GRAY}${NC}"
    [ -n "${STORE_DISK:-}" ] && echo -e "${DARK_GRAY}│${NC} ${NEON_CYAN}${BOLD}Storage:${NC}    ${SILVER}$STORE_DISK${NC}${DARK_GRAY}${NC}"
    echo -e "${DARK_GRAY}└─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo
    
    # Next steps with icons
    echo -e "${NEON_GREEN}${BOLD}🚀 Next Steps:${NC}"
    echo -e "${DARK_GRAY}   1.${NC} ${SILVER}Remove the installation media${NC}"
    echo -e "${DARK_GRAY}   2.${NC} ${SILVER}Reboot the system${NC}"
    echo -e "${DARK_GRAY}   3.${NC} ${SILVER}Log in with your user credentials${NC}"
    echo -e "${DARK_GRAY}   4.${NC} ${SILVER}Enjoy WavesOS with Hyprland!${NC}"
    echo
    
    # Important warning with animation
    echo -e "${NEON_ORANGE}${BOLD}⚠️  IMPORTANT:${NC} ${SILVER}Please remove the USB installation media before rebooting!${NC}"
    echo
    
    # Futuristic reboot prompt
    echo -e "${NEON_CYAN}${BOLD}🔄 Press Enter to reboot now, or Ctrl+C to exit to shell:${NC} "
    read -r
    echo -e "${NEON_GREEN}${BOLD}🚀 Rebooting in 3...${NC}"
    sleep 1
    echo -e "${NEON_GREEN}${BOLD}🚀 Rebooting in 2...${NC}"
    sleep 1
    echo -e "${NEON_GREEN}${BOLD}🚀 Rebooting in 1...${NC}"
    sleep 1
    echo -e "${NEON_GREEN}${BOLD}🚀 Rebooting now!${NC}"
    reboot
}
