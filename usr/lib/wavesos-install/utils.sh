
#!/bin/bash

# WavesOS Installation Script - Utilities Library
# Contains logging, UI, and basic utility functions

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

success() {
    echo -e "${CYAN}[SUCCESS] $1${NC}"
}

# Progress indicator
show_progress() {
    local current=$1
    local total=$2
    local desc="$3"
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r${PURPLE}[%3d%%]${NC} [" "$percent"
    printf "%*s" "$filled" | tr ' ' '='
    printf "%*s" "$empty" | tr ' ' '-'
    printf "] %s" "$desc"
    
    if [ "$current" -eq "$total" ]; then
        echo
    fi
}

# Banner
show_banner() {
    clear
    echo -e "${CYAN}"
       echo "

██╗    ██╗ █████╗ ██╗   ██╗███████╗███████╗ ██████╗ ███████╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ███████╗██████╗ 
██║    ██║██╔══██╗██║   ██║██╔════╝██╔════╝██╔═══██╗██╔════╝    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔════╝██╔══██╗
██║ █╗ ██║███████║██║   ██║█████╗  ███████╗██║   ██║███████╗    ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     █████╗  ██████╔╝
██║███╗██║██╔══██║╚██╗ ██╔╝██╔══╝  ╚════██║██║   ██║╚════██║    ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██╔══╝  ██╔══██╗
╚███╔███╔╝██║  ██║ ╚████╔╝ ███████╗███████║╚██████╔╝███████║    ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗███████╗██║  ██║
 ╚══╝╚══╝ ╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚══════╝ ╚═════╝ ╚══════╝    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝
                                                                                                                                      

"
    echo -e "${NC}"
    echo
}

# Check if run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Please run as root with sudo"
    fi
}

# Check if running in live environment
check_live_env() {
    if ! grep -q "archiso" /proc/cmdline 2>/dev/null; then
        warning "This script is designed to run from Arch Linux live environment"
        read -p "Continue anyway? (y/N): " continue_anyway
        [[ "${continue_anyway,,}" != "y" ]] && error "Installation cancelled"
    fi
}

# Ensure required tools are available
check_tools() {
    local tools=(parted mkfs.fat mkfs.ext4 pacstrap arch-chroot genfstab grub-install reflector lsblk blkid rsync git efibootmgr)
    
    log "Checking required tools..."
    for cmd in "${tools[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            error "$cmd is required but not installed"
        fi
    done
    success "All required tools are available"
}

# Check network connectivity
check_network() {
    log "Checking network connectivity..."
    if ! ping -c 3 -W 5 archlinux.org &>/dev/null; then
        error "No internet connection detected. Please connect to a network and try again."
    fi
    success "Network connectivity confirmed"
}

# Update system clock
update_clock() {
    log "Updating system clock..."
    timedatectl set-ntp true
    sleep 2
    success "System clock updated"
}

# Cleanup and unmount
cleanup_installation() {
    log "Cleaning up and unmounting filesystems..."
    
    # Disable swap if enabled
    if [ "${SWAP_SIZE:-0}" -gt 0 ]; then
        swapoff "$SWAP_PART" 2>/dev/null || true
    fi
    
    # Unmount in reverse order
    umount /mnt/home/storage 2>/dev/null || true
    umount /mnt/boot 2>/dev/null || true
    umount /mnt 2>/dev/null || true
    
    success "Cleanup completed"
}

# Installation summary
show_installation_summary() {
    echo
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                   INSTALLATION COMPLETE                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo
    success "WavesOS has been installed successfully!"
    echo
    info "Installation Summary:"
    info "• System disk: $SYS_DISK"
    info "• Boot mode: $BOOT_MODE"
    info "• Hostname: $HOSTNAME"
    info "• Username: $USERNAME"
    info "• Desktop: Hyprland with WavesOS configs"
    [ -n "${STORE_DISK:-}" ] && info "• Storage disk: $STORE_DISK"
    echo
    info "Next steps:"
    info "1. Remove the installation media"
    info "2. Reboot the system"
    info "3. Log in with your user credentials"
    info "4. Enjoy WavesOS with Hyprland!"
    echo
    warning "IMPORTANT: Please remove the USB installation media before rebooting!"
    echo
    read -p "Press Enter to reboot now, or Ctrl+C to exit to shell: "
    reboot
}
