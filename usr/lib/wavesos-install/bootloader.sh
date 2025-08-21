
#!/bin/bash

# WavesOS Installation Script - Bootloader Library
# Contains GRUB bootloader installation and configuration

# CRITICAL BOOTLOADER INSTALLATION - Fixed for "Boot device not found" issue
install_bootloader() {
    log "Installing and configuring bootloader (Critical Boot Fix)..."
    
    # Create CORRECTED bootloader installation script
    cat > /mnt/install_bootloader.sh << EOF
#!/bin/bash
set -euo pipefail

BOOT_MODE="$BOOT_MODE"
SYS_DISK="$SYS_DISK"

echo "=== CRITICAL BOOTLOADER INSTALLATION ==="
echo "Installing bootloader for \$BOOT_MODE mode on \$SYS_DISK"

# CRITICAL FIX 1: Ensure EFI variables are properly mounted
if [ "\$BOOT_MODE" = "uefi" ]; then
    echo "Mounting EFI variables..."
    modprobe efivarfs 2>/dev/null || true
    mount -t efivarfs efivarfs /sys/firmware/efi/efivars 2>/dev/null || true
fi

# CRITICAL FIX 2: Configure GRUB with proper WavesOS branding
echo "Configuring GRUB defaults..."
sed -i 's/GRUB_DISTRIBUTOR="Arch"/GRUB_DISTRIBUTOR="WavesOS"/' /etc/default/grub
sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub

# Add timeout to prevent hanging
echo 'GRUB_TIMEOUT=5' >> /etc/default/grub

if [ "\$BOOT_MODE" = "uefi" ]; then
    echo "Installing GRUB for UEFI..."
    
    # CRITICAL FIX 3: Use --removable flag for better compatibility
    if grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=WavesOS --recheck --removable; then
        echo "UEFI GRUB installation successful"
    else
        echo "Primary UEFI installation failed, trying fallback method..."
        # Fallback: Install to default EFI location
        grub-install --target=x86_64-efi --efi-directory=/boot --removable || {
            echo "ERROR: Both UEFI installation methods failed"
            exit 1
        }
    fi
    
    # CRITICAL FIX 4: Create fallback EFI bootloader
    mkdir -p /boot/EFI/BOOT
    if [ -f /boot/EFI/WavesOS/grubx64.efi ]; then
        cp /boot/EFI/WavesOS/grubx64.efi /boot/EFI/BOOT/BOOTX64.EFI
        echo "Created fallback EFI bootloader"
    fi
    
else
    echo "Installing GRUB for BIOS..."
    
    # CRITICAL FIX 5: Ensure we're installing to the correct disk
    if grub-install --target=i386-pc --recheck "\$SYS_DISK"; then
        echo "BIOS GRUB installation successful"
    else
        echo "ERROR: Failed to install GRUB to \$SYS_DISK"
        exit 1
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
}
