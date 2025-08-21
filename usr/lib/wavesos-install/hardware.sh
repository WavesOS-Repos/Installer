
#!/bin/bash

# WavesOS Installation Script - Hardware Detection Library
# Contains disk detection, hardware specs, and disk selection functions
# Enhanced with futuristic UI

# Enhanced disk detection with USB exclusion
detect_disks() {
    show_status "checking" "Scanning for available storage devices..."
    
    # Get all block devices that are disks
    mapfile -t ALL_DISKS < <(lsblk -d -n -o NAME,SIZE,TYPE,TRAN,HOTPLUG | grep disk)
    
    # Filter out USB drives and hot-pluggable devices
    DISK_LIST=()
    for disk_info in "${ALL_DISKS[@]}"; do
        read -r name size type tran hotplug <<<"$disk_info"
        
        # Skip if it's a USB device or hot-pluggable
        if [[ "$tran" == "usb" ]] || [[ "$hotplug" == "1" ]]; then
            warning "Excluding USB/hotplug device: /dev/$name"
            continue
        fi
        
        # Additional check: exclude if mounted under /run/archiso
        if mount | grep -q "/dev/$name.*archiso"; then
            warning "Excluding archiso device: /dev/$name"
            continue
        fi
        
        # Additional check: exclude if it's the current root device
        root_device=$(findmnt -n -o SOURCE /)
        if [[ "$root_device" == *"$name"* ]]; then
            warning "Excluding current root device: /dev/$name"
            continue
        fi
        
        DISK_LIST+=("$disk_info")
    done
    
    if [ ${#DISK_LIST[@]} -eq 0 ]; then
        error "No suitable disks found! All detected disks appear to be USB or system devices."
    fi
    
    show_status "success" "Found ${#DISK_LIST[@]} suitable disk(s) for installation"
}

# Display hardware specs with futuristic styling
show_hardware() {
    echo -e "${NEON_PURPLE}${BOLD}🔍 Hardware Specifications:${NC}"
    echo
    
    # Create a futuristic hardware info display
    echo -e "${DARK_GRAY}┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐${NC}"
    
    # CPU Info
    local cpu_info=$(lscpu | grep "Model name" | awk -F: '{print $2}' | xargs)
    echo -e "${DARK_GRAY}│${NC} ${NEON_CYAN}${BOLD}CPU:${NC} ${SILVER}$cpu_info${NC}${DARK_GRAY}${NC}"
    
    # RAM Info
    local ram_info=$(free -h | awk '/^Mem:/ {print $2}')
    echo -e "${DARK_GRAY}│${NC} ${NEON_CYAN}${BOLD}RAM:${NC} ${SILVER}$ram_info${NC}${DARK_GRAY}${NC}"
    
    # GPU Info
    local gpu_info=$(lspci | grep -i vga | cut -d: -f3 | xargs || echo 'Not detected')
    echo -e "${DARK_GRAY}│${NC} ${NEON_CYAN}${BOLD}GPU:${NC} ${SILVER}$gpu_info${NC}${DARK_GRAY}${NC}"
    
    echo -e "${DARK_GRAY}└─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo
    
    # Storage devices table
    echo -e "${NEON_GREEN}${BOLD}💾 Available Storage Devices:${NC}"
    echo -e "${DARK_GRAY}┌────────────┬────────────┬────────────┬────────────┬─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${DARK_GRAY}│${NC} ${NEON_CYAN}${BOLD}DEVICE${NC}     ${DARK_GRAY}│${NC} ${NEON_CYAN}${BOLD}SIZE${NC}       ${DARK_GRAY}│${NC} ${NEON_CYAN}${BOLD}TYPE${NC}       ${DARK_GRAY}│${NC} ${NEON_CYAN}${BOLD}TRANSPORT${NC}  ${DARK_GRAY}│${NC} ${NEON_CYAN}${BOLD}MODEL${NC}${DARK_GRAY}${NC}"
    echo -e "${DARK_GRAY}├────────────┼────────────┼────────────┼────────────┼─────────────────────────────────────────────────────────┤${NC}"
    
    for disk_info in "${DISK_LIST[@]}"; do
        read -r name size type tran hotplug <<<"$disk_info"
        model=$(lsblk -d -n -o MODEL "/dev/$name" 2>/dev/null || echo "Unknown")
        printf "${DARK_GRAY}│${NC} ${NEON_GREEN}/dev/%-8s${NC} ${DARK_GRAY}│${NC} ${SILVER}%-10s${NC} ${DARK_GRAY}│${NC} ${SILVER}%-10s${NC} ${DARK_GRAY}│${NC} ${SILVER}%-10s${NC} ${DARK_GRAY}│${NC} ${SILVER}%-65s${NC} ${DARK_GRAY}│${NC}\n" "$name" "$size" "$type" "$tran" "$model"
    done
    
    echo -e "${DARK_GRAY}└────────────┴────────────┴────────────┴────────────┴─────────────────────────────────────────────────────────┘${NC}"
    echo
    
    echo -e "${NEON_CYAN}${BOLD}Press Enter to continue...${NC}"
    read -r
}

# Disk selection with enhanced validation and futuristic UI
select_disks() {
    echo -e "${NEON_PURPLE}${BOLD}🎯 Disk Selection${NC}"
    echo
    
    # Show disk options with enhanced styling
    echo -e "${NEON_GREEN}${BOLD}Available disks for installation:${NC}"
    echo -e "${DARK_GRAY}┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐${NC}"
    
    for i in "${!DISK_LIST[@]}"; do
        read -r name size type tran hotplug <<<"${DISK_LIST[$i]}"
        model=$(lsblk -d -n -o MODEL "/dev/$name" 2>/dev/null || echo "Unknown")
        printf "${DARK_GRAY}│${NC} ${NEON_CYAN}${BOLD}%d)${NC} ${NEON_GREEN}/dev/%-8s${NC} ${DARK_GRAY}-${NC} ${SILVER}%-8s${NC} ${DARK_GRAY}(${NC}${SILVER}%s${NC} ${DARK_GRAY}via${NC} ${SILVER}%s${NC}${DARK_GRAY})${NC} ${DARK_GRAY}-${NC} ${SILVER}%-40s${NC} ${DARK_GRAY}│${NC}\n" "$i" "$name" "$size" "$type" "$tran" "$model"
    done
    
    echo -e "${DARK_GRAY}└─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo
    
    # System disk selection with enhanced validation
    while true; do
        echo -e "${NEON_ORANGE}${BOLD}Select system disk number (for root installation):${NC} "
        read -r SYS_DISK_IDX
        if [[ "$SYS_DISK_IDX" =~ ^[0-9]+$ ]] && [ "$SYS_DISK_IDX" -lt ${#DISK_LIST[@]} ]; then
            break
        fi
        echo -e "${NEON_PINK}${BOLD}Invalid system disk selection. Please enter a number between 0 and $((${#DISK_LIST[@]} - 1))${NC}"
    done
    
    SYS_DISK="/dev/$(echo "${DISK_LIST[$SYS_DISK_IDX]}" | awk '{print $1}')"
    show_status "success" "Selected system disk: $SYS_DISK"
    
    # Verify disk is not mounted
    if mount | grep -q "$SYS_DISK"; then
        error "Selected disk $SYS_DISK appears to be in use. Please unmount it first."
    fi
    
    # Remove selected disk from list
    unset 'DISK_LIST[$SYS_DISK_IDX]'
    DISK_LIST=("${DISK_LIST[@]}") # Reindex array
    
    # Storage disk selection (optional) with enhanced UI
    STORE_DISK=""
    if [ ${#DISK_LIST[@]} -gt 0 ]; then
        echo
        echo -e "${NEON_GREEN}${BOLD}Remaining disks for additional storage:${NC}"
        echo -e "${DARK_GRAY}┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐${NC}"
        
        for i in "${!DISK_LIST[@]}"; do
            read -r name size type tran hotplug <<<"${DISK_LIST[$i]}"
            model=$(lsblk -d -n -o MODEL "/dev/$name" 2>/dev/null || echo "Unknown")
            printf "${DARK_GRAY}│${NC} ${NEON_CYAN}${BOLD}%d)${NC} ${NEON_GREEN}/dev/%-8s${NC} ${DARK_GRAY}-${NC} ${SILVER}%-8s${NC} ${DARK_GRAY}(${NC}${SILVER}%s${NC} ${DARK_GRAY}via${NC} ${SILVER}%s${NC}${DARK_GRAY})${NC} ${DARK_GRAY}-${NC} ${SILVER}%-40s${NC} ${DARK_GRAY}│${NC}\n" "$i" "$name" "$size" "$type" "$tran" "$model"
        done
        
        echo -e "${DARK_GRAY}└─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘${NC}"
        echo
        
        echo -e "${NEON_ORANGE}${BOLD}Select storage disk number (or press Enter for none):${NC} "
        read -r STORE_DISK_IDX
        if [[ "$STORE_DISK_IDX" =~ ^[0-9]+$ ]] && [ "$STORE_DISK_IDX" -lt ${#DISK_LIST[@]} ]; then
            STORE_DISK="/dev/$(echo "${DISK_LIST[$STORE_DISK_IDX]}" | awk '{print $1}')"
            show_status "success" "Selected storage disk: $STORE_DISK"
        fi
    fi
}

# Enhanced boot mode detection with futuristic UI
detect_boot_mode() {
    show_status "checking" "Detecting system boot mode..."
    
    if [ -d /sys/firmware/efi ]; then
        BOOT_MODE="uefi"
        PTABLE="gpt"
        show_status "success" "UEFI system detected, using GPT partition table"
        
        # Verify EFI variables are accessible
        if ! efivar -l &>/dev/null; then
            warning "EFI variables not accessible, but UEFI detected"
        fi
    else
        BOOT_MODE="bios"
        PTABLE="msdos"
        show_status "success" "BIOS system detected, using MBR partition table"
    fi
}
