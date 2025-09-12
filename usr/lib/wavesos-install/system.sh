
#!/bin/bash

# WavesOS Installation Script - System Configuration Library
# Contains system installation, configuration, and user management functions

# Update mirrorlist
update_mirrorlist() {
    section_header "System • Mirrors"
    log "Updating mirrorlist for optimal download speeds..."
    echo "Select your country for optimal mirrors:"
    echo "1) United States    2) United Kingdom   3) Germany"
    echo "4) France          5) Canada           6) Australia"
    echo "7) India           8) Japan            9) Custom"
    
    read -p "Select country (1-9): " COUNTRY_CHOICE
    case $COUNTRY_CHOICE in
        1) COUNTRY="US" ;;
        2) COUNTRY="GB" ;;
        3) COUNTRY="DE" ;;
        4) COUNTRY="FR" ;;
        5) COUNTRY="CA" ;;
        6) COUNTRY="AU" ;;
        7) COUNTRY="IN" ;;
        8) COUNTRY="JP" ;;
        9) read -p "Enter country code (e.g., SE for Sweden): " COUNTRY ;;
        *) COUNTRY="US" ;;
    esac
    
    info "Updating mirrors for country: $COUNTRY"
    reflector --country "$COUNTRY" --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist || {
        warning "Failed to update mirrorlist, using default"
    }
    success "Mirrorlist updated"
}

# [Moved to packages.sh] install_base_system
# [Moved to packages.sh] install_bootloader_packages
# [Moved to packages.sh] install_graphics_drivers
# [Moved to packages.sh] install_custom_packages

# Copy custom repository
copy_custom_repo() {
    section_header "System • Custom Repository"
    if [ -d /custom-repo ] && [ -f /custom-repo/custom-repo.db ]; then
        log "Copying custom repository to installed system..."
        mkdir -p /mnt/custom-repo
        if cp -r /custom-repo/* /mnt/custom-repo/; then
            success "Custom repository copied successfully"
        else
            warning "Failed to copy some custom repository files"
        fi
    else
        info "No custom repository found, skipping"
    fi
}

# Generate fstab
generate_fstab() {
    section_header "System • fstab"
    log "Generating filesystem table (fstab)..."
    if genfstab -U /mnt >> /mnt/etc/fstab; then
        success "fstab generated successfully"
    else
        error "Failed to generate fstab"
    fi
}

# Configure system settings
configure_system() {
    section_header "System • Configure"
    log "Configuring system settings..."
    
    # Locale configuration
    echo "Select system locale:"
    echo "1) en_US.UTF-8 (English - United States)"
    echo "2) en_GB.UTF-8 (English - United Kingdom)"
    echo "3) de_DE.UTF-8 (German - Germany)"
    echo "4) fr_FR.UTF-8 (French - France)"
    echo "5) es_ES.UTF-8 (Spanish - Spain)"
    echo "6) Custom locale"
    
    read -p "Select locale (1-6): " LOCALE_CHOICE
    case $LOCALE_CHOICE in
        1) LOCALE="en_US.UTF-8 UTF-8" ;;
        2) LOCALE="en_GB.UTF-8 UTF-8" ;;
        3) LOCALE="de_DE.UTF-8 UTF-8" ;;
        4) LOCALE="fr_FR.UTF-8 UTF-8" ;;
        5) LOCALE="es_ES.UTF-8 UTF-8" ;;
        6) read -p "Enter locale (e.g., ja_JP.UTF-8): " LOCALE ;;
        *) LOCALE="en_US.UTF-8 UTF-8" ;;
    esac
    
    # Timezone configuration
    echo
    echo "Select timezone:"
    echo "1) America/New_York    2) America/Los_Angeles"
    echo "3) Europe/London       4) Europe/Berlin"
    echo "5) Asia/Tokyo          6) Asia/Kolkata"
    echo "7) Australia/Sydney    8) Custom timezone"
    
    read -p "Select timezone (1-8): " TZ_CHOICE
    case $TZ_CHOICE in
        1) TIMEZONE="America/New_York" ;;
        2) TIMEZONE="America/Los_Angeles" ;;
        3) TIMEZONE="Europe/London" ;;
        4) TIMEZONE="Europe/Berlin" ;;
        5) TIMEZONE="Asia/Tokyo" ;;
        6) TIMEZONE="Asia/Kolkata" ;;
        7) TIMEZONE="Australia/Sydney" ;;
        8) read -p "Enter timezone (e.g., Europe/Stockholm): " TIMEZONE ;;
        *) TIMEZONE="UTC" ;;
    esac
    
    # Hostname
    echo
    read -p "Enter hostname for this system (default: wavesos): " HOSTNAME
    HOSTNAME=${HOSTNAME:-wavesos}
    
    # User configuration
    echo
    read -p "Enter username for the main user account: " USERNAME
    while [[ -z "$USERNAME" || "$USERNAME" = "root" ]]; do
        warning "Invalid username. Please enter a valid username (not root):"
        read -p "Username: " USERNAME
    done
    
    success "System configuration collected"
}

# Apply system configuration in chroot
apply_chroot_config() {
    section_header "System • Apply Config"
    log "Applying system configuration..."
    
    # Create chroot script
    cat > /mnt/setup_system.sh << 'EOF'
#!/bin/bash
set -euo pipefail

# Configure locale
echo "$1" > /etc/locale.gen
locale-gen
echo "LANG=${1%% *}" > /etc/locale.conf

# Configure timezone
ln -sf "/usr/share/zoneinfo/$2" /etc/localtime
hwclock --systohc

# Configure hostname
echo "$3" > /etc/hostname

# Configure hosts file
cat > /etc/hosts << HOSTS_EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $3.localdomain $3
HOSTS_EOF

# Enable essential services
systemctl enable NetworkManager
systemctl enable sddm
systemctl enable bluetooth

# Configure pacman
sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

# Create user
useradd -m -G wheel,audio,video,optical,storage -s /bin/bash "$4"
echo "Set password for user $4:"
passwd "$4"

echo "Set password for root:"
passwd

# Configure sudo
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel

# Configure mkinitcpio
mkinitcpio -P

echo "System configuration completed successfully"
EOF

    chmod +x /mnt/setup_system.sh
    
    # Execute in chroot
    if arch-chroot /mnt /setup_system.sh "$LOCALE" "$TIMEZONE" "$HOSTNAME" "$USERNAME"; then
        success "System configuration applied successfully"
    else
        error "Failed to apply system configuration"
    fi
    
    # Cleanup
    rm /mnt/setup_system.sh
}

# Configure OS release
configure_os_release() {
    section_header "System • os-release"
    log "Configuring /etc/os-release for WavesOS..."

    # Verify /mnt is mounted
    if ! mountpoint -q /mnt; then
        error "Root partition /mnt is not mounted"
    fi

    # Check if /etc/os-release exists in live environment
    if [ ! -f /etc/os-release ]; then
        error "/etc/os-release not found in live environment"
    fi

    show_progress 1 1 "Copying /etc/os-release to installed system..."
    cp /etc/os-release /mnt/etc/os-release || error "Failed to copy /etc/os-release to /mnt/etc/os-release"
    chmod 644 /mnt/etc/os-release || error "Failed to set permissions on /mnt/etc/os-release"

    # Verify the copied file
    if [ -f /mnt/etc/os-release ] && grep -q '^NAME="WavesOS"$' /mnt/etc/os-release; then
        echo "/etc/os-release successfully copied and configured"
    else
        error "Failed to verify /etc/os-release content"
    fi

    success "Successfully configured /etc/os-release for WavesOS"
}

# Final system verification
verify_installation() {
    section_header "System • Verification"
    log "Performing final system verification..."
    
    local checks_passed=0
    local total_checks=6
    
    # Check 1: Root partition mounted
    if mountpoint -q /mnt; then
        success "✓ Root partition properly mounted"
        ((checks_passed++))
    else
        error "✗ Root partition not mounted"
    fi
    
    # Check 2: Boot partition (UEFI only)
    if [ "$BOOT_MODE" = "uefi" ]; then
        if mountpoint -q /mnt/boot; then
            success "✓ EFI boot partition properly mounted"
            ((checks_passed++))
        else
            error "✗ EFI boot partition not mounted"
        fi
    else
        success "✓ BIOS boot configuration verified"
        ((checks_passed++))
    fi
    
    # Check 3: Bootloader files
    if [ "$BOOT_MODE" = "uefi" ]; then
        if [ -f /mnt/boot/EFI/WavesOS/grubx64.efi ]; then
            success "✓ UEFI bootloader files present"
            ((checks_passed++))
        else
            warning "✗ UEFI bootloader files missing"
        fi
    else
        if [ -f /mnt/boot/grub/grub.cfg ]; then
            success "✓ BIOS bootloader configuration present"
            ((checks_passed++))
        else
            warning "✗ BIOS bootloader configuration missing"
        fi
    fi
    
    # Check 4: User account
    if arch-chroot /mnt id "$USERNAME" &>/dev/null; then
        success "✓ User account '$USERNAME' created"
        ((checks_passed++))
    else
        error "✗ User account '$USERNAME' not found"
    fi
    
    # Check 5: Essential services
    if arch-chroot /mnt systemctl is-enabled NetworkManager &>/dev/null; then
        success "✓ NetworkManager service enabled"
        ((checks_passed++))
    else
        warning "✗ NetworkManager service not enabled"
    fi
    
    # Check 6: Hyprland installation
    if arch-chroot /mnt which hyprland &>/dev/null; then
        success "✓ Hyprland desktop environment installed"
        ((checks_passed++))
    else
        warning "✗ Hyprland not found"
    fi
    
    echo
    info "Installation verification: $checks_passed/$total_checks checks passed"
    
    if [ $checks_passed -ge 4 ]; then
        success "System verification passed! Installation should be bootable."
        return 0
    else
        error "System verification failed! Installation may not boot properly."
        return 1
    fi
}
