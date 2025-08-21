
#!/bin/bash

# WavesOS Installation Script - Hardware Detection Library
# Contains disk detection, hardware specs, and disk selection functions

# Enhanced disk detection with USB exclusion
detect_disks() {
    log "Detecting available disks (excluding USB drives)..."
    
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
    
    success "Found ${#DISK_LIST[@]} suitable disk(s) for installation"
}

# Display hardware specs
show_hardware() {
    log "Hardware Specifications:"
    info "CPU: $(lscpu | grep "Model name" | awk -F: '{print $2}' | xargs)"
    info "RAM: $(free -h | awk '/^Mem:/ {print $2}')"
    info "GPU: $(lspci | grep -i vga | cut -d: -f3 | xargs || echo 'Not detected')"
    echo
    info "Available storage devices:"
    printf "%-10s %-10s %-10s %-10s %s\n" "DEVICE" "SIZE" "TYPE" "TRANSPORT" "MODEL"
    printf "%-10s %-10s %-10s %-10s %s\n" "------" "----" "----" "---------" "-----"
    
    for disk_info in "${DISK_LIST[@]}"; do
        read -r name size type tran hotplug <<<"$disk_info"
        model=$(lsblk -d -n -o MODEL "/dev/$name" 2>/dev/null || echo "Unknown")
        printf "%-10s %-10s %-10s %-10s %s\n" "/dev/$name" "$size" "$type" "$tran" "$model"
    done
    echo
    read -p "Press Enter to continue..."
}

# Disk selection with enhanced validation
select_disks() {
    # Show disk options
    echo "Available disks for installation:"
    for i in "${!DISK_LIST[@]}"; do
        read -r name size type tran hotplug <<<"${DISK_LIST[$i]}"
        model=$(lsblk -d -n -o MODEL "/dev/$name" 2>/dev/null || echo "Unknown")
        echo "$i) /dev/$name - $size ($type via $tran) - $model"
    done
    echo
    
    # System disk selection
    while true; do
        read -p "Select system disk number (for root installation): " SYS_DISK_IDX
        if [[ "$SYS_DISK_IDX" =~ ^[0-9]+$ ]] && [ "$SYS_DISK_IDX" -lt ${#DISK_LIST[@]} ]; then
            break
        fi
        error "Invalid system disk selection. Please enter a number between 0 and $((${#DISK_LIST[@]} - 1))"
    done
    
    SYS_DISK="/dev/$(echo "${DISK_LIST[$SYS_DISK_IDX]}" | awk '{print $1}')"
    log "Selected system disk: $SYS_DISK"
    
    # Verify disk is not mounted
    if mount | grep -q "$SYS_DISK"; then
        error "Selected disk $SYS_DISK appears to be in use. Please unmount it first."
    fi
    
    # Remove selected disk from list
    unset 'DISK_LIST[$SYS_DISK_IDX]'
    DISK_LIST=("${DISK_LIST[@]}") # Reindex array
    
    # Storage disk selection (optional)
    STORE_DISK=""
    if [ ${#DISK_LIST[@]} -gt 0 ]; then
        echo
        echo "Remaining disks for additional storage:"
        for i in "${!DISK_LIST[@]}"; do
            read -r name size type tran hotplug <<<"${DISK_LIST[$i]}"
            model=$(lsblk -d -n -o MODEL "/dev/$name" 2>/dev/null || echo "Unknown")
            echo "$i) /dev/$name - $size ($type via $tran) - $model"
        done
        read -p "Select storage disk number (or press Enter for none): " STORE_DISK_IDX
        if [[ "$STORE_DISK_IDX" =~ ^[0-9]+$ ]] && [ "$STORE_DISK_IDX" -lt ${#DISK_LIST[@]} ]; then
            STORE_DISK="/dev/$(echo "${DISK_LIST[$STORE_DISK_IDX]}" | awk '{print $1}')"
            log "Selected storage disk: $STORE_DISK"
        fi
    fi
}

# Enhanced boot mode detection
detect_boot_mode() {
    if [ -d /sys/firmware/efi ]; then
        BOOT_MODE="uefi"
        PTABLE="gpt"
        log "UEFI system detected, using GPT partition table"
        
        # Verify EFI variables are accessible
        if ! efivar -l &>/dev/null; then
            warning "EFI variables not accessible, but UEFI detected"
        fi
    else
        BOOT_MODE="bios"
        PTABLE="msdos"
        log "BIOS system detected, using MBR partition table"
    fi
}
