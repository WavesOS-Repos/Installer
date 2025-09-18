
#!/bin/bash

# WavesOS Installation Script - Partitioning Library
# Contains partitioning, formatting, and mounting functions

# Partition configuration
configure_partitions() {
    section_header "Partitioning • Plan Layout"
    # Get disk size for validation
    TOTAL_SIZE_BYTES=$(blockdev --getsize64 "$SYS_DISK")
    TOTAL_SIZE_GB=$((TOTAL_SIZE_BYTES / 1024 / 1024 / 1024))
    log "Total disk size: ${TOTAL_SIZE_GB}GB"
    
    # Partition size configuration
    if [ "$BOOT_MODE" = "uefi" ]; then
        while true; do
            read -p "Enter EFI partition size in MB (default: 512): " EFI_SIZE
            EFI_SIZE=${EFI_SIZE:-512}
            if [[ "$EFI_SIZE" =~ ^[0-9]+$ ]] && [ "$EFI_SIZE" -ge 256 ] && [ "$EFI_SIZE" -le 2048 ]; then
                break
            fi
            warning "EFI partition size must be between 256MB and 2048MB"
        done
    else
        EFI_SIZE=0
    fi
    
    # Swap configuration
    RAM_SIZE_GB=$(free -g | awk '/^Mem:/ {print $2}')
    RECOMMENDED_SWAP=$((RAM_SIZE_GB <= 8 ? RAM_SIZE_GB * 2 : RAM_SIZE_GB))
    
    echo
    info "RAM detected: ${RAM_SIZE_GB}GB"
    info "Recommended swap: ${RECOMMENDED_SWAP}GB"
    read -p "Enter swap partition size in GB (recommended: ${RECOMMENDED_SWAP}GB, 0 for none): " SWAP_SIZE
    SWAP_SIZE=${SWAP_SIZE:-$RECOMMENDED_SWAP}
    
    if ! [[ "$SWAP_SIZE" =~ ^[0-9]+$ ]]; then
        warning "Invalid swap size, using recommended: ${RECOMMENDED_SWAP}GB"
        SWAP_SIZE=$RECOMMENDED_SWAP
    fi
    
    # Root partition size
    USED_SPACE=$((EFI_SIZE / 1024 + SWAP_SIZE))
    AVAILABLE_SPACE=$((TOTAL_SIZE_GB - USED_SPACE))
    
    if [ "$AVAILABLE_SPACE" -le 0 ]; then
        error "Not enough disk space. Need at least $((USED_SPACE + 20))GB"
    fi
    
    read -p "Enter root partition size in GB (0 for remaining ${AVAILABLE_SPACE}GB): " ROOT_SIZE
    ROOT_SIZE=${ROOT_SIZE:-0}
    
    if [ "$ROOT_SIZE" -eq 0 ]; then
        ROOT_SIZE=$AVAILABLE_SPACE
    elif [ "$ROOT_SIZE" -gt "$AVAILABLE_SPACE" ]; then
        warning "Root size too large, using available space: ${AVAILABLE_SPACE}GB"
        ROOT_SIZE=$AVAILABLE_SPACE
    fi
    
    if [ "$ROOT_SIZE" -lt 20 ]; then
        error "Root partition must be at least 20GB for WavesOS"
    fi
}

# Confirm partitioning
confirm_partitioning() {
    section_header "Partitioning • Confirmation"
    echo
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                    PARTITIONING SUMMARY                   ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
    echo
    info "Target disk: $SYS_DISK (${TOTAL_SIZE_GB}GB)"
    [ "$BOOT_MODE" = "uefi" ] && info "EFI partition: ${EFI_SIZE}MB"
    [ "$SWAP_SIZE" -gt 0 ] && info "Swap partition: ${SWAP_SIZE}GB"
    info "Root partition: ${ROOT_SIZE}GB (ext4)"
    [ -n "${STORE_DISK:-}" ] && info "Storage disk: $STORE_DISK (full disk, ext4)"
    echo
    warning "⚠️  THIS WILL PERMANENTLY DESTROY ALL DATA ON THE SELECTED DISK(S)! ⚠️"
    echo
    
    read -p "Type 'YES' to confirm and proceed with installation: " CONFIRM
    if [ "$CONFIRM" != "YES" ]; then
        error "Installation cancelled by user"
    fi
}

# Enhanced partitioning with better error handling
create_partitions() {
    section_header "Partitioning • Create"
    log "Creating partitions on $SYS_DISK..."
    
    # Unmount any mounted partitions from target disk
    umount "$SYS_DISK"* 2>/dev/null || true
    
    # Wipe filesystem signatures
    wipefs -af "$SYS_DISK" || error "Failed to wipe filesystem signatures"
    
    # Create partition table
    parted "$SYS_DISK" --script mklabel "$PTABLE" || error "Failed to create partition table"
    
    PART_NUM=1
    if [ "$BOOT_MODE" = "uefi" ]; then
        # Create EFI partition
        parted "$SYS_DISK" --script mkpart primary fat32 1MiB ${EFI_SIZE}MiB || error "Failed to create EFI partition"
        parted "$SYS_DISK" --script set $PART_NUM esp on || error "Failed to set ESP flag"
        EFI_PART="${SYS_DISK}${PART_NUM}"
        PART_NUM=$((PART_NUM + 1))
        START_POS="${EFI_SIZE}MiB"
    else
        # Create BIOS boot partition
        parted "$SYS_DISK" --script mkpart primary 1MiB 2MiB || error "Failed to create BIOS boot partition"
        
        # Try to set bios_grub flag with fallback
        if ! parted "$SYS_DISK" --script set $PART_NUM bios_grub on 2>/dev/null; then
            warning "Could not set bios_grub flag, trying alternative approach..."
            # Alternative: Create a larger boot partition and set boot flag instead
            parted "$SYS_DISK" --script rm $PART_NUM 2>/dev/null || true
            parted "$SYS_DISK" --script mkpart primary ext2 1MiB 256MiB || error "Failed to create alternative boot partition"
            parted "$SYS_DISK" --script set $PART_NUM boot on || warning "Could not set boot flag"
            START_POS="256MiB"
        else
            START_POS="2MiB"
        fi
        
        BIOS_BOOT_PART="${SYS_DISK}${PART_NUM}"
        PART_NUM=$((PART_NUM + 1))
    fi
    
    # Create swap partition
    if [ "$SWAP_SIZE" -gt 0 ]; then
        END_POS="$((${START_POS%MiB} + SWAP_SIZE * 1024))MiB"
        parted "$SYS_DISK" --script mkpart primary linux-swap "$START_POS" "$END_POS" || error "Failed to create swap partition"
        SWAP_PART="${SYS_DISK}${PART_NUM}"
        PART_NUM=$((PART_NUM + 1))
        START_POS="$END_POS"
    fi
    
    # Create root partition
    parted "$SYS_DISK" --script mkpart primary ext4 "$START_POS" 100% || error "Failed to create root partition"
    ROOT_PART="${SYS_DISK}${PART_NUM}"
    
    # Handle NVMe drives partition naming
    if [[ "$SYS_DISK" == *"nvme"* ]]; then
        if [ "$BOOT_MODE" = "uefi" ]; then
            EFI_PART="${SYS_DISK}p1"
            if [ "$SWAP_SIZE" -gt 0 ]; then
                SWAP_PART="${SYS_DISK}p2"
                ROOT_PART="${SYS_DISK}p3"
            else
                ROOT_PART="${SYS_DISK}p2"
            fi
        else
            BIOS_BOOT_PART="${SYS_DISK}p1"
            if [ "$SWAP_SIZE" -gt 0 ]; then
                SWAP_PART="${SYS_DISK}p2"
                ROOT_PART="${SYS_DISK}p3"
            else
                ROOT_PART="${SYS_DISK}p2"
            fi
        fi
    fi
    
    # Handle storage disk
    if [ -n "${STORE_DISK:-}" ]; then
        log "Partitioning storage disk $STORE_DISK..."
        umount "$STORE_DISK"* 2>/dev/null || true
        wipefs -af "$STORE_DISK" || error "Failed to wipe storage disk"
        parted "$STORE_DISK" --script mklabel "$PTABLE" || error "Failed to create storage partition table"
        parted "$STORE_DISK" --script mkpart primary ext4 1MiB 100% || error "Failed to create storage partition"
        
        if [[ "$STORE_DISK" == *"nvme"* ]]; then
            STORAGE_PART="${STORE_DISK}p1"
        else
            STORAGE_PART="${STORE_DISK}1"
        fi
    fi
    
    # Wait for partitions to be created and refresh
    sleep 3
    partprobe "$SYS_DISK" || error "Failed to refresh partition table"
    [ -n "${STORE_DISK:-}" ] && partprobe "$STORE_DISK"
    
    # Verify partitions exist
    for i in {1..10}; do
        if [ -b "$ROOT_PART" ]; then
            break
        fi
        sleep 1
    done
    
    [ ! -b "$ROOT_PART" ] && error "Root partition $ROOT_PART was not created"
    success "Partitions created successfully"
}

# Format partitions with enhanced error handling
format_partitions() {
    section_header "Partitioning • Format"
    log "Formatting partitions..."
    
    if [ "$BOOT_MODE" = "uefi" ]; then
        show_progress 1 4 "Formatting EFI partition..."
        mkfs.fat -F32 -n "EFI" "$EFI_PART" || error "Failed to format EFI partition"
    fi
    
    if [ "$SWAP_SIZE" -gt 0 ]; then
        show_progress 2 4 "Formatting swap partition..."
        mkswap -L "SWAP" "$SWAP_PART" || error "Failed to format swap partition"
    fi
    
    show_progress 3 4 "Formatting root partition..."
    mkfs.ext4 -F -L "ROOT" "$ROOT_PART" || error "Failed to format root partition"
    
    if [ -n "${STORE_DISK:-}" ]; then
        show_progress 4 4 "Formatting storage partition..."
        mkfs.ext4 -F -L "STORAGE" "$STORAGE_PART" || error "Failed to format storage partition"
    fi
    
    show_progress 4 4 "Partition formatting complete"
    success "All partitions formatted successfully"
}

# Mount partitions with verification
mount_partitions() {
    section_header "Partitioning • Mount"
    log "Mounting partitions..."
    
    # Mount root
    mount "$ROOT_PART" /mnt || error "Failed to mount root partition"
    
    # Create and mount boot/EFI
    if [ "$BOOT_MODE" = "uefi" ]; then
        mkdir -p /mnt/boot
        mount "$EFI_PART" /mnt/boot || error "Failed to mount EFI partition"
    fi
    
    # Enable swap
    if [ "$SWAP_SIZE" -gt 0 ]; then
        swapon "$SWAP_PART" || error "Failed to enable swap"
    fi
    
    # Mount storage
    if [ -n "${STORE_DISK:-}" ]; then
        mkdir -p /mnt/home/storage
        mount "$STORAGE_PART" /mnt/home/storage || error "Failed to mount storage partition"
    fi
    
    success "All partitions mounted successfully"
}
