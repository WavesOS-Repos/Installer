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
NEON_RED='\033[38;5;196m'

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

# Truecolor detection and helpers
supports_truecolor() {
    if [ "${COLORTERM-}" = "truecolor" ] || [ "${COLORTERM-}" = "24bit" ]; then
        return 0
    fi
    case "${TERM-}" in
        *xterm-truecolor*|*24bit*) return 0 ;;
        *) return 1 ;;
    esac
}

print_rgb() {
    # Usage: print_rgb R G B text...
    local r=$1 g=$2 b=$3; shift 3
    if supports_truecolor; then
        echo -ne "\033[38;2;${r};${g};${b}m$*${NC}"
    else
        echo -ne "${BOLD}$*${NC}"
    fi
}

gradient_text() {
    # Center and print a neon gradient line
    local text="$1"
    local len=${#text}
    local pad=$(( (TERM_WIDTH - len) / 2 ))
    [ $pad -lt 0 ] && pad=0
    printf "%*s" "$pad" ""
    local i r g b char
    for (( i=0; i<len; i++ )); do
        r=$(( 120 + (135 * i / (len>1?len-1:1)) ))
        g=$((  10 + (  0 * i / (len>1?len-1:1)) ))
        b=$(( 200 - ( 80 * i / (len>1?len-1:1)) ))
        char=${text:i:1}
        print_rgb "$r" "$g" "$b" "$char"
    done
    echo
}

set_terminal_title() {
    echo -ne "\033]0;WavesOS Installer • Neon Horizon\007"
}

section_header() {
    # Decorative header used across modules (purely visual)
    local title="$1"
    get_terminal_size
    echo -e "${CLEAR_LINE}"
    gradient_text "════════════════════════════════════════════════════════════════════════════"
    gradient_text "  ✨  ${title}  ✨  "
    gradient_text "════════════════════════════════════════════════════════════════════════════"
    # Quick scanline shimmer (very short, non-blocking feel)
    local width=$(( TERM_WIDTH > 80 ? 80 : TERM_WIDTH ))
    local i
    for (( i=1; i<=width; i+=8 )); do
        printf "\r${DARK_GRAY}%*s${NC}" "$i" "▌"
        sleep 0.01
    done
    printf "\r${CLEAR_LINE}"
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
    
    # Animated progress bar (breathing head)
    printf "${NEON_CYAN}[${NC}"
    if [ "$filled" -gt 0 ]; then
        local head_char="█"
        [ $((current % 2)) -eq 0 ] && head_char="▓"
        if [ "$filled" -gt 1 ]; then
            printf "%*s" "$((filled-1))" | tr ' ' '█'
            printf "%s" "$head_char"
        else
            printf "%s" "$head_char"
        fi
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
    set_terminal_title
    
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

# Futuristic selection menu with live boot compatibility
select_option() {
    local prompt="$1"
    local options=("${@:2}")
    local selected=0
    local count=${#options[@]}
    
    echo -e "${NEON_PURPLE}${BOLD}$prompt${NC}" >&2
    echo >&2
    
    # Check if we can use interactive mode (test terminal capabilities)
    if ! [[ -t 0 ]] || ! command -v stty >/dev/null 2>&1; then
        warning "Interactive terminal not available, using fallback menu" >&2
        select_option_fallback "$prompt" "${options[@]}"
        return $?
    fi
    
    # Test if we can read from terminal properly
    local old_stty_cfg
    if ! old_stty_cfg=$(stty -g 2>/dev/null); then
        warning "Terminal control not available, using fallback menu" >&2
        select_option_fallback "$prompt" "${options[@]}"
        return $?
    fi
    
    # Set up terminal for interactive mode
    stty raw -echo 2>/dev/null || {
        warning "Cannot configure terminal, using fallback menu" >&2
        select_option_fallback "$prompt" "${options[@]}"
        return $?
    }
    
    local menu_active=true
    while $menu_active; do
        # Clear previous menu
        for ((i=0; i<count+2; i++)); do
            echo -en "\033[A\033[K" >&2
        done
        
        # Show current selection
        for ((i=0; i<count; i++)); do
            if [ $i -eq $selected ]; then
                echo -e "${NEON_CYAN}${BOLD}  ▶ ${NEON_GREEN}${options[$i]}${NC}" >&2
            else
                echo -e "${DARK_GRAY}    ${options[$i]}${NC}" >&2
            fi
        done
        
        # Read key with timeout and error handling
        local key
        if ! key=$(timeout 30 dd bs=1 count=1 2>/dev/null); then
            warning "Input timeout or error, using fallback menu" >&2
            stty "$old_stty_cfg" 2>/dev/null
            select_option_fallback "$prompt" "${options[@]}"
            return $?
        fi
        
        case "$key" in
            $'\x1b') # Escape sequence
                local key2 key3
                if key2=$(timeout 1 dd bs=1 count=1 2>/dev/null) && key3=$(timeout 1 dd bs=1 count=1 2>/dev/null); then
                    case "$key2$key3" in
                        "[A") # Up arrow
                            selected=$((selected - 1))
                            [ $selected -lt 0 ] && selected=$((count - 1))
                            ;;
                        "[B") # Down arrow
                            selected=$((selected + 1))
                            [ $selected -ge $count ] && selected=0
                            ;;
                    esac
                fi
                ;;
            $'\n'|$'\r') # Enter
                stty "$old_stty_cfg" 2>/dev/null
                echo >&2
                echo "$selected"
                return 0
                ;;
            $'\x03') # Ctrl+C
                stty "$old_stty_cfg" 2>/dev/null
                echo >&2
                error "Installation cancelled by user"
                ;;
            [1-9]) # Number keys for quick selection
                local num=$(($(printf '%d' "'$key") - 49)) # Convert to 0-based index
                if [ $num -ge 0 ] && [ $num -lt $count ]; then
                    selected=$num
                    stty "$old_stty_cfg" 2>/dev/null
                    echo >&2
                    echo -e "${NEON_GREEN}Selected: ${options[$selected]}${NC}" >&2
                    echo "$selected"
                    return 0
                fi
                ;;
        esac
    done
    
    # Restore terminal settings
    stty "$old_stty_cfg" 2>/dev/null
}

# Fallback selection menu for environments where interactive mode fails
select_option_fallback() {
    local prompt="$1"
    local options=("${@:2}")
    local count=${#options[@]}
    
    echo -e "${NEON_ORANGE}${BOLD}Using fallback selection mode${NC}" >&2
    echo -e "${NEON_PURPLE}${BOLD}$prompt${NC}" >&2
    echo >&2
    
    # Display numbered options
    for ((i=0; i<count; i++)); do
        echo -e "${NEON_CYAN}${BOLD}$(($i + 1)).${NC} ${options[$i]}" >&2
    done
    echo >&2
    
    local choice
    while true; do
        echo -en "${NEON_GREEN}${BOLD}Enter your choice (1-$count): ${NC}" >&2
        if read -r choice; then
            # Validate input
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
                echo -e "${NEON_GREEN}Selected: ${options[$((choice - 1))]}${NC}" >&2
                echo "$((choice - 1))"
                return 0
            else
                echo -e "${NEON_RED}Invalid choice. Please enter a number between 1 and $count.${NC}" >&2
            fi
        else
            # Handle read failure gracefully
            echo -e "${NEON_RED}Input error. Please try again.${NC}" >&2
        fi
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
    # Micro pulse animation for step transition
    local pulse=("⟡" "✧" "✦" "✧")
    local p
    for p in "${pulse[@]}"; do
        printf "\r${NEON_CYAN}${BOLD}%s${NC} Preparing step %s/%s..." "$p" "$CURRENT_STEP" "$TOTAL_STEPS"
        sleep 0.05
    done
    printf "\r${CLEAR_LINE}"
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
