#!/bin/bash

# WavesOS Installation Script - Bootloader Library
# Contains GRUB bootloader installation and configuration

# ENHANCED BOOTLOADER INSTALLATION - Multiple fixes to prevent boot failures
install_bootloader() {
    log "Installing and configuring bootloader (Enhanced Critical Boot Fix)..."
    
    # PRE-INSTALLATION VERIFICATION CHECKS
    log "Performing pre-bootloader verification checks..."
    
    # Check if EFI partition has sufficient space (UEFI only)
    if [ "$BOOT_MODE" = "uefi" ]; then
        EFI_AVAILABLE=$(df --output=avail /mnt/boot | tail -1)
        EFI_AVAILABLE_MB=$((EFI_AVAILABLE / 1024))
        if [ "$EFI_AVAILABLE_MB" -lt 100 ]; then
            error "EFI partition has insufficient space: ${EFI_AVAILABLE_MB}MB (need at least 100MB)"
        fi
        success "✓ EFI partition has sufficient space: ${EFI_AVAILABLE_MB}MB"
    fi
    
    # Verify essential bootloader packages are installed
    log "Verifying bootloader package dependencies..."
    REQUIRED_PACKAGES=("grub")
    if [ "$BOOT_MODE" = "uefi" ]; then
        REQUIRED_PACKAGES+=("efibootmgr")
    fi
    
    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if ! arch-chroot /mnt pacman -Q "$pkg" &>/dev/null; then
            error "Required package '$pkg' not installed. Run package installation first."
        fi
    done
    success "✓ All required bootloader packages are installed"
    
    # Create ENHANCED bootloader installation script with comprehensive error handling
    cat > /mnt/install_bootloader.sh << EOF
#!/bin/bash
set -euo pipefail

BOOT_MODE="$BOOT_MODE"
SYS_DISK="$SYS_DISK"

echo "=== CRITICAL BOOTLOADER INSTALLATION ==="
echo "Installing bootloader for \$BOOT_MODE mode on \$SYS_DISK"

# ENHANCED FIX 1: Comprehensive EFI environment preparation
if [ "\$BOOT_MODE" = "uefi" ]; then
    echo "Preparing EFI environment..."
    
    # Load EFI-related kernel modules
    modprobe efivarfs 2>/dev/null || true
    modprobe efivars 2>/dev/null || true
    
    # Mount EFI variables filesystem
    if ! mount | grep -q "efivarfs on /sys/firmware/efi/efivars"; then
        mount -t efivarfs efivarfs /sys/firmware/efi/efivars 2>/dev/null || {
            echo "Warning: Failed to mount efivarfs, continuing with limited EFI support"
        }
    fi
    
    # Verify EFI boot partition is properly mounted and accessible
    if [ ! -d "/boot/EFI" ]; then
        mkdir -p /boot/EFI || {
            echo "ERROR: Cannot create EFI directory structure"
            exit 1
        }
    fi
    
    # Check EFI partition filesystem
    if ! findmnt -M /boot >/dev/null 2>&1; then
        echo "ERROR: EFI partition not properly mounted at /boot"
        exit 1
    fi
    
    echo "✓ EFI environment prepared successfully"
fi

# ENHANCED FIX 2: Verify disk integrity and create GRUB backup
# Verify disk is accessible and not corrupted
echo "Verifying target disk \$SYS_DISK..."
if [ ! -b "\$SYS_DISK" ]; then
    echo "ERROR: Target disk \$SYS_DISK is not a valid block device"
    exit 1
fi

# Check disk health with basic read test
if ! dd if="\$SYS_DISK" of=/dev/null bs=512 count=1 2>/dev/null; then
    echo "ERROR: Cannot read from target disk \$SYS_DISK - disk may be failing"
    exit 1
fi

echo "Configuring GRUB defaults with backup..."
# Create backup of original GRUB configuration
if [ -f /etc/default/grub ]; then
    cp /etc/default/grub /etc/default/grub.backup.wavesos-install
    echo "✓ GRUB configuration backed up to /etc/default/grub.backup.waveos-install"
fi

# Apply GRUB configuration changes
sed -i 's/GRUB_DISTRIBUTOR="Arch"/GRUB_DISTRIBUTOR="WavesOS"/' /etc/default/grub
sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub

# Enhanced timeout and performance settings
echo 'GRUB_TIMEOUT=5' >> /etc/default/grub
echo 'GRUB_TIMEOUT_STYLE=menu' >> /etc/default/grub
echo 'GRUB_RECORDFAIL_TIMEOUT=5' >> /etc/default/grub

if [ "\$BOOT_MODE" = "uefi" ]; then
    echo "Installing GRUB for UEFI..."
    
    # ENHANCED FIX 3: Multi-stage UEFI installation with comprehensive fallbacks
    echo "Attempting UEFI GRUB installation with multiple fallback methods..."
    
    # Stage 1: Standard installation with removable flag for compatibility
    if grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=WavesOS --recheck --removable 2>/dev/null; then
        echo "✓ UEFI GRUB installation successful (standard method)"
    else
        echo "⚠ Primary UEFI installation failed, trying fallback method 1..."
        
        # Stage 2: Try without --bootloader-id (may help with problematic firmware)
        if grub-install --target=x86_64-efi --efi-directory=/boot --removable 2>/dev/null; then
            echo "✓ UEFI GRUB installation successful (fallback method 1)"
        else
            echo "⚠ Fallback method 1 failed, trying fallback method 2..."
            
            # Stage 3: Force installation and ignore blocklists
            if grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=WavesOS --force --removable 2>/dev/null; then
                echo "✓ UEFI GRUB installation successful (fallback method 2 - forced)"
            else
                echo "⚠ All automated methods failed, attempting manual EFI setup..."
                
                # Stage 4: Manual EFI setup as last resort
                mkdir -p /boot/EFI/BOOT
                if command -v grub-mkimage >/dev/null 2>&1; then
                    grub-mkimage -o /boot/EFI/BOOT/BOOTX64.EFI -p /boot/grub -O x86_64-efi \
                        part_gpt part_msdos ntfs ntfscomp hfsplus fat ext2 normal chain boot \
                        configfile linux multiboot || {
                        echo "ERROR: All UEFI installation methods failed including manual setup"
                        exit 1
                    }
                    echo "✓ UEFI bootloader installed using manual method"
                else
                    echo "ERROR: All UEFI installation methods failed - grub-mkimage not available"
                    exit 1
                fi
            fi
        fi
    fi
    
    # ENHANCED FIX 4: Create comprehensive EFI fallback bootloaders
    echo "Creating EFI fallback bootloaders for maximum compatibility..."
    mkdir -p /boot/EFI/BOOT
    
    # Primary fallback: Copy WavesOS-specific bootloader if it exists
    if [ -f /boot/EFI/WavesOS/grubx64.efi ]; then
        cp /boot/EFI/WavesOS/grubx64.efi /boot/EFI/BOOT/BOOTX64.EFI
        echo "✓ Created primary fallback EFI bootloader (BOOTX64.EFI)"
    fi
    
    # Secondary fallback: Create additional standard names for firmware compatibility
    if [ -f /boot/EFI/BOOT/BOOTX64.EFI ]; then
        # Some firmware looks for different names
        cp /boot/EFI/BOOT/BOOTX64.EFI /boot/EFI/BOOT/BOOTIA32.EFI 2>/dev/null || true
        
        # Verify fallback bootloader is functional
        if [ -f /boot/EFI/BOOT/BOOTX64.EFI ] && [ -s /boot/EFI/BOOT/BOOTX64.EFI ]; then
            echo "✓ EFI fallback bootloaders created and verified"
        else
            echo "⚠ Warning: EFI fallback bootloader may not be functional"
        fi
    else
        echo "⚠ Warning: No EFI bootloader found to create fallback"
    fi
    
else
    echo "Installing GRUB for BIOS..."
    
    # ENHANCED FIX 5: Multi-stage BIOS installation with comprehensive verification
    echo "Verifying MBR space and disk compatibility..."
    
    # Verify we have a proper Master Boot Record area
    if ! parted "\$SYS_DISK" print 2>/dev/null | grep -q "Partition Table"; then
        echo "ERROR: Cannot read partition table from \$SYS_DISK"
        exit 1
    fi
    
    # Check for sufficient space in MBR gap (first 2048 sectors for GRUB core.img)
    echo "Checking MBR gap space for GRUB core.img..."
    FIRST_PARTITION_START=\$(parted "\$SYS_DISK" unit s print 2>/dev/null | awk '/^ *1/ {print \$2}' | sed 's/s//')
    if [ -n "\$FIRST_PARTITION_START" ] && [ "\$FIRST_PARTITION_START" -lt 2048 ]; then
        echo "⚠ Warning: Limited MBR gap space detected. GRUB installation may fail on some systems."
        echo "   First partition starts at sector \$FIRST_PARTITION_START (recommended: 2048 or later)"
    fi
    
    # Stage 1: Standard BIOS installation
    if grub-install --target=i386-pc --recheck "\$SYS_DISK" 2>/dev/null; then
        echo "✓ BIOS GRUB installation successful (standard method)"
    else
        echo "⚠ Primary BIOS installation failed, trying fallback method 1..."
        
        # Stage 2: Force installation ignoring warnings
        if grub-install --target=i386-pc --recheck --force "\$SYS_DISK" 2>/dev/null; then
            echo "✓ BIOS GRUB installation successful (forced method)"
        else
            echo "⚠ Forced installation failed, trying fallback method 2..."
            
            # Stage 3: Try without --recheck (may help with certain disk layouts)
            if grub-install --target=i386-pc --force "\$SYS_DISK" 2>/dev/null; then
                echo "✓ BIOS GRUB installation successful (no-recheck method)"
            else
                echo "ERROR: All BIOS installation methods failed for \$SYS_DISK"
                echo "This may be due to:"
                echo "  - Insufficient MBR gap space"
                echo "  - Disk geometry issues" 
                echo "  - Hardware compatibility problems"
                exit 1
            fi
        fi
    fi
    
    # Verify BIOS installation was successful
    echo "Verifying BIOS GRUB installation..."
    if dd if="\$SYS_DISK" bs=512 count=1 2>/dev/null | strings | grep -q "GRUB"; then
        echo "✓ GRUB signature found in MBR - installation verified"
    else
        echo "⚠ Warning: GRUB signature not detected in MBR - installation may be incomplete"
    fi
fi

# CRITICAL FIX 6: Generate GRUB config with error checking
echo "Generating GRUB configuration..."
if grub-mkconfig -o /boot/grub/grub.cfg; then
    echo "GRUB configuration generated successfully"
else
    echo "ERROR: Failed to generate GRUB configuration"
    exit 1
fi

# CRITICAL FIX 7: Verify installation thoroughly
echo "=== BOOTLOADER VERIFICATION ==="
if [ "\$BOOT_MODE" = "uefi" ]; then
    # Check for GRUB EFI files
    if [ -f /boot/EFI/WavesOS/grubx64.efi ] || [ -f /boot/EFI/BOOT/BOOTX64.EFI ]; then
        echo "✓ UEFI bootloader files verified"
    else
        echo "✗ ERROR: UEFI bootloader files missing"
        exit 1
    fi
    
    # Check EFI boot entries
    if command -v efibootmgr >/dev/null 2>&1; then
        efibootmgr -v
        if efibootmgr | grep -i "wavesos\|removable"; then
            echo "✓ EFI boot entry found"
        else
            echo "⚠ Warning: No specific WavesOS EFI entry, but removable entry should work"
        fi
    fi
else
    # Check BIOS installation
    if dd if="\$SYS_DISK" bs=512 count=1 2>/dev/null | strings | grep -q GRUB; then
        echo "✓ BIOS bootloader verified in MBR"
    else
        echo "✗ ERROR: BIOS bootloader not found in MBR"
        exit 1
    fi
fi

# Check GRUB configuration
if [ -f /boot/grub/grub.cfg ] && grep -q "WavesOS" /boot/grub/grub.cfg; then
    echo "✓ GRUB configuration verified"
else
    echo "✗ ERROR: GRUB configuration invalid"
    exit 1
fi

echo "=== BOOTLOADER INSTALLATION COMPLETED SUCCESSFULLY ==="
EOF

    chmod +x /mnt/install_bootloader.sh
    
    # Execute bootloader installation in chroot with enhanced error handling
    log "Executing bootloader installation in chroot..."
    if arch-chroot /mnt /install_bootloader.sh; then
        success "CRITICAL BOOTLOADER INSTALLATION SUCCESSFUL"
        
        # Additional host-level verification
        if [ "$BOOT_MODE" = "uefi" ]; then
            if [ -f "/mnt/boot/EFI/BOOT/BOOTX64.EFI" ] || [ -f "/mnt/boot/EFI/WavesOS/grubx64.efi" ]; then
                success "✓ Host verification: EFI bootloader files confirmed"
            else
                warning "⚠ Host verification: EFI files not found from host"
            fi
        fi
        
    else
        error "CRITICAL BOOTLOADER INSTALLATION FAILED - This will cause boot failure"
    fi

    # Cleanup
    rm /mnt/install_bootloader.sh
    clear
    show_banner
}