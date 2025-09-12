#!/bin/bash

# WavesOS Installation Script - Desktop Environment Library
# Contains desktop installation and WavesOS customizations

# Global variable for selected desktop environment
SELECTED_DE=""

# Desktop Environment Selection Menu
select_desktop_environment() {
    section_header "Desktop • Environment Selection"
    
    log "Presenting desktop environment options..."
    
    local de_options=(
        "Hyprland (Wayland - Modern/Gaming)"
        "GNOME (X11/Wayland - User-friendly)"
        "Both (Hybrid setup)"
    )
    
    # Debug information for live boot troubleshooting
    log "Terminal type: ${TERM:-unknown}"
    log "TTY check: $([ -t 0 ] && echo "stdin is tty" || echo "stdin not tty")"
    log "STTY available: $(command -v stty >/dev/null 2>&1 && echo "yes" || echo "no")"
    
    log "Calling select_option function..."
    local selection_result
    selection_result=$(select_option "Choose your desktop environment:" "${de_options[@]}")
    
    log "Selection result: $selection_result"
    
    # Validate selection result is a valid integer
    if ! [[ "$selection_result" =~ ^[0-9]+$ ]] || [ "$selection_result" -lt 0 ] || [ "$selection_result" -gt 2 ]; then
        error "Invalid selection result: '$selection_result'. Expected 0, 1, or 2."
    fi
    
    case $selection_result in
        0) SELECTED_DE="hyprland" ;;
        1) SELECTED_DE="gnome" ;;
        2) SELECTED_DE="both" ;;
        *) 
            error "Invalid desktop environment selection result: $selection_result"
            ;;
    esac
    
    log "Desktop environment set to: $SELECTED_DE"
    success "Selected desktop environment: $SELECTED_DE"
    echo
}

# [Moved to packages.sh] install_desktop_environment

# Install and configure Hyprland configs
install_hyprland_customizations() {
    section_header "Desktop • WavesOS Customizations"
    log "Installing WavesOS customizations..."

    # Verify /mnt is mounted
    if ! mountpoint -q /mnt; then
        error "Root partition /mnt is not mounted"
    fi

    show_progress 1 5 "Copying Hyprland configurations..."
    # Copy Hyprland configs to chroot
    if [ -d /root/Hyprland-configs ]; then
        cp -r /root/Hyprland-configs /mnt || error "Failed to copy Hyprland-configs to /mnt/tmp/Hyprland-configs"
    else
        error "Hyprland-configs directory not found at /root/Hyprland-configs"
    fi

    # Copy Hyprland configs to chroot
    if [ -d /root/WavesHyprland ]; then
        cp -r /root/WavesHyprland /mnt || error "Failed to copy WavesHyprland to /mnt/WavesHyprland"
    else
        error "WavesHyprland directory not found at /root/WavesHyprland"
    fi

    if [ -d /root/WavesHyprland-V2 ]; then
        cp -r /root/WavesHyprland-V2 /mnt || error "Failed to copy WavesHyprland to /mnt/WavesHyprland"
    else
        error "WavesHyprland directory not found at /root/WavesHyprland"
    fi

    show_progress 3 5 "Copying sleep.conf..."
    # Copy sleep.conf to target system
    if [ -f /etc/systemd/sleep.conf ]; then
        cp /etc/systemd/sleep.conf /mnt/etc/systemd/sleep.conf || error "Failed to copy sleep.conf to /mnt/etc/systemd/sleep.conf"
    else
        warning "No sleep.conf found at /etc/systemd/sleep.conf; skipping"
    fi

    show_progress 4 5 "Setting up configurations..."
    # Set permissions and run install.sh in chroot
  arch-chroot /mnt bash -c "
        if [ -f /Hyprland-configs/install.sh ]; then
            chmod +x /Hyprland-configs/install.sh || { echo 'Failed to make Hyprland install.sh executable' >&2; exit 1; }
           chown -R $USERNAME:$USERNAME Hyprland-configs
           chmod +x /Hyprland-configs/dnf-scripts/*.sh
           chmod +x /Hyprland-configs/zypper-scripts/*.sh
           chmod +x /Hyprland-configs/common/*.sh
           chmod +x /Hyprland-configs/pacman-scripts/*.sh
           chmod +x /Hyprland-configs/start.sh
            su - \"$USERNAME\" -c 'cd /Hyprland-configs 
            ./install.sh' || { echo 'Hyprland install.sh failed' >&2; exit 1; }
        else
            echo 'Hyprland install.sh not found' >&2
            exit 1
        fi
        " || error "Failed to execute install.sh Hyprland script in chroot"

        success "WavesOS Hyprland customizations installed successfully"
}

# Install and configure GNOME customizations
install_gnome_customizations() {
    section_header "Desktop • GNOME Customizations"
    log "Installing WavesOS GNOME customizations..."

    # Verify /mnt is mounted
    if ! mountpoint -q /mnt; then
        error "Root partition /mnt is not mounted"
    fi

    show_progress 1 5 "Configuring GNOME Shell..."
    arch-chroot /mnt su - "$USERNAME" -c "
        # Enable extensions
        dbus-launch gsettings set org.gnome.shell enabled-extensions \"['blur-my-shell@aunetx', 'burn-my-windows@schneegans.github.com', 'desktop-cube@schneegans.github.com']\"
        
        # Set icon theme
        dbus-launch gsettings set org.gnome.desktop.interface icon-theme 'kora-pgrey'
        
        # Set wallpaper
        dbus-launch gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/pixmaps/wavesos-wallpaper.jpg'
        dbus-launch gsettings set org.gnome.desktop.background picture-uri-dark 'file:///usr/share/pixmaps/wavesos-wallpaper.jpg'
        
        # Configure interface
        dbus-launch gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
        dbus-launch gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
        
        # Configure window manager
        dbus-launch gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
        
        echo 'GNOME customizations applied successfully'
    " || error "Failed to apply GNOME customizations"

    show_progress 3 5 "Setting up GNOME autostart applications..."
    arch-chroot /mnt su - "$USERNAME" -c "
        mkdir -p ~/.config/autostart
        
        # Create autostart for kando if installed
        if command -v kando >/dev/null 2>&1; then
            cat > ~/.config/autostart/kando.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Kando
Exec=kando
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
        fi
        
        echo 'GNOME autostart configured successfully'
    " || error "Failed to configure GNOME autostart"

    success "WavesOS GNOME customizations installed successfully"
}

# Install and configure WavesOS customizations based on selected DE
install_wavesos_customizations() {
    case "$SELECTED_DE" in
        "hyprland")
            install_hyprland_customizations
            ;;
        "gnome")
            install_gnome_customizations
            install_gnome_extensions
            ;;
        "both")
            install_hyprland_customizations
            install_gnome_customizations
            install_gnome_extensions
            ;;
        *)
            warning "Unknown desktop environment: $SELECTED_DE. Skipping customizations."
            ;;
    esac
}

# Install WavesSDDM (Universal for all DEs)
install_SDDM_theme() {
    section_header "Desktop • SDDM Theme"
    log "Installing WavesOS SDDM..."

    # Verify /mnt is mounted
    if ! mountpoint -q /mnt; then
        error "Root partition /mnt is not mounted"
    fi

    show_progress 2 5 "Copying WavesSDDM Theme..."
    # Copy SDDM configs to chroot
    if [ -d /root/WavesSDDM ]; then
        cp -r /root/WavesSDDM /mnt/root/ || error "Failed to copy WavesSDDM to /mnt/root/"
    else
        # Check if we're in demo mode (DEMO_MODE should be set by demo script)
        if [ "${DEMO_MODE:-false}" = "true" ]; then
            warning "WavesSDDM directory not found at /root, creating demo placeholder..."
            mkdir -p /mnt/root/WavesSDDM
            echo "#!/bin/bash" > /mnt/root/WavesSDDM/install.sh
            echo "echo 'Demo mode - SDDM theme would be installed here'" >> /mnt/root/WavesSDDM/install.sh
            echo "mkdir -p /usr/share/sddm/themes/waves" >> /mnt/root/WavesSDDM/install.sh
            echo "echo 'Demo theme created' > /usr/share/sddm/themes/waves/theme.conf" >> /mnt/root/WavesSDDM/install.sh
            chmod +x /mnt/root/WavesSDDM/install.sh
        else
            error "WavesSDDM theme directory not found at /root/WavesSDDM. Theme installation cannot proceed."
        fi
    fi
  
    show_progress 4 5 "Setting up configurations..."
    # Set permissions and run install.sh in chroot with proper error handling
    arch-chroot /mnt bash -c "
        set -e
        if [ -f /root/WavesSDDM/install.sh ]; then
            chmod +x /root/WavesSDDM/install.sh 
            /root/WavesSDDM/install.sh
            echo 'WavesSDDM theme installation completed successfully'
        else
            echo 'ERROR: WavesSDDM install.sh not found at /root/WavesSDDM/install.sh' >&2
            exit 1
        fi
        " || error "Failed to execute SDDM theme install script in chroot"
        
    # Explicitly configure SDDM theme
    show_progress 5 5 "Configuring SDDM theme settings..."
    arch-chroot /mnt bash -c "
        mkdir -p /etc/sddm.conf.d
        cat > /etc/sddm.conf.d/waves.conf << 'EOF'
[Theme]
Current=waves

[General]
Numlock=on

[Users]
MaximumUid=60513
MinimumUid=500
EOF
    " || error "Failed to configure SDDM theme settings"
    
    success "WavesOS SDDM Theme installed successfully"
}

# Configure desktop environment specific services
configure_desktop_services() {
    section_header "Desktop • Service Configuration"
    log "Configuring desktop services for $SELECTED_DE..."

    show_progress 1 4 "Enabling SDDM display manager..."
    # Enable SDDM for all desktop environments with error checking
    if ! arch-chroot /mnt systemctl enable sddm; then
        error "Failed to enable SDDM service. Ensure sddm package is installed."
    fi
    
    show_progress 2 4 "Disabling conflicting display managers..."
    case "$SELECTED_DE" in
        "hyprland")
            log "Configuring SDDM for Hyprland (Wayland)"
            # Ensure no conflicting display managers
            arch-chroot /mnt systemctl disable gdm lightdm 2>/dev/null || true
            ;;
        "gnome")
            log "Configuring SDDM for GNOME (replacing GDM)"
            # Disable GDM and other display managers
            arch-chroot /mnt systemctl disable gdm lightdm 2>/dev/null || true
            # Ensure GDM doesn't auto-start
            arch-chroot /mnt systemctl mask gdm 2>/dev/null || true
            ;;
        "both")
            log "Configuring SDDM for hybrid Hyprland/GNOME setup"
            arch-chroot /mnt systemctl disable gdm lightdm 2>/dev/null || true
            arch-chroot /mnt systemctl mask gdm 2>/dev/null || true
            ;;
    esac
    
    show_progress 3 4 "Setting SDDM as default display manager..."
    # Explicitly set SDDM as the default display manager
    arch-chroot /mnt bash -c "
        mkdir -p /etc/systemd/system/display-manager.service.d
        cat > /etc/systemd/system/display-manager.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/sddm
EOF
    " || warning "Failed to set SDDM as default display manager"
    
    show_progress 4 4 "Verifying SDDM configuration..."
    # Set default target to graphical
    arch-chroot /mnt systemctl set-default graphical.target || warning "Failed to set graphical target"
    
    # Verify SDDM is properly enabled and is the default display manager
    if arch-chroot /mnt systemctl is-enabled sddm | grep -q "enabled"; then
        # Verify display-manager service points to SDDM
        if arch-chroot /mnt systemctl status display-manager 2>/dev/null | grep -q "sddm\|Active"; then
            success "SDDM successfully configured as default display manager for $SELECTED_DE"
        else
            warning "SDDM enabled but may not be the active display manager"
        fi
    else
        error "SDDM service verification failed - service not enabled"
    fi
    
    success "Desktop services configured for $SELECTED_DE"
}

install_gnome_extensions() {
    section_header "Desktop • GNOME Extensions"
    log "Installing GNOME Shell extensions for $USERNAME..."

    # Verify /mnt is mounted
    if ! mountpoint -q /mnt; then
        error "Root partition /mnt is not mounted"
    fi

    # Ensure gnome-shell-extensions directory exists in live environment
    if [ ! -d /root/gnome-shell-extensions ]; then
        error "gnome-shell-extensions directory not found at /root/gnome-shell-extensions"
    fi

    # Copy extension ZIP files to chroot
    mkdir -p /mnt/gnome-shell-extensions || error "Failed to create /mnt/gnome-shell-extensions"
    cp /root/gnome-shell-extensions/{blur-my-shell.zip,burn-my-windows@schneegans.github.com.zip,desktop-cube@schneegans.github.com.zip} /mnt/gnome-shell-extensions/ || error "Failed to copy GNOME extension ZIP files to /mnt/gnome-shell-extensions"

    show_progress 1 4 "Installing Blur My Shell..."
    arch-chroot /mnt su - "$USERNAME" -c "
        if [ -f /gnome-shell-extensions/blur-my-shell.zip ]; then
            gnome-extensions install --force /gnome-shell-extensions/blur-my-shell.zip || { echo 'Failed to install Blur My Shell' >&2; exit 1; }
        else
            echo 'blur-my-shell.zip not found' >&2
            exit 1
        fi
    " || error "Failed to install Blur My Shell"

    show_progress 2 4 "Installing Burn My Windows..."
    arch-chroot /mnt su - "$USERNAME" -c "
        if [ -f /gnome-shell-extensions/burn-my-windows@schneegans.github.com.zip ]; then
            gnome-extensions install --force /gnome-shell-extensions/burn-my-windows@schneegans.github.com.zip || { echo 'Failed to install Burn My Windows' >&2; exit 1; }
        else
            echo 'burn-my-windows@schneegans.github.com.zip not found' >&2
            exit 1
        fi
    " || error "Failed to install Burn My Windows"

    show_progress 3 4 "Installing Desktop Cube..."
    arch-chroot /mnt su - "$USERNAME" -c "
        if [ -f /gnome-shell-extensions/desktop-cube@schneegans.github.com.zip ]; then
            gnome-extensions install --force /gnome-shell-extensions/desktop-cube@schneegans.github.com.zip || { echo 'Failed to install Desktop Cube' >&2; exit 1; }
        else
            echo 'desktop-cube@schneegans.github.com.zip not found' >&2
            exit 1
        fi
    " || error "Failed to install Desktop Cube"

    show_progress 4 4 "Enabling GNOME Shell extensions..."
    arch-chroot /mnt su - "$USERNAME" -c "
        dbus-launch gsettings set org.gnome.shell enabled-extensions \"['blur-my-shell@aunetx', 'burn-my-windows@schneegans.github.com', 'desktop-cube@schneegans.github.com']\" || { echo 'Failed to enable extensions via gsettings' >&2; exit 1; }
        if gsettings get org.gnome.shell enabled-extensions | grep -q 'blur-my-shell@aunetx'; then
            echo 'Extensions successfully enabled in gsettings'
        else
            echo 'ERROR: Failed to verify enabled extensions in gsettings' >&2
            exit 1
        fi
    " || error "Failed to enable GNOME Shell extensions"

    # Cleanup copied extension files
    rm -rf /mnt/gnome-shell-extensions 2>/dev/null || true

    success "GNOME Shell extensions installed and enabled successfully for $USERNAME"
}

setup_kando_autostart() {
    section_header "Desktop • Kando Autostart"
    log "Setting up kando-bin autostart for $USERNAME..."

    # Verify /mnt is mounted
    if ! mountpoint -q /mnt; then
        error "Root partition /mnt is not mounted"
    fi

    show_progress 1 1 "Configuring kando-bin autostart..."
    arch-chroot /mnt su - "$USERNAME" -c "
        mkdir -p ~/.config/autostart || { echo 'Failed to create autostart directory' >&2; exit 1; }
        cat > ~/.config/autostart/kando-bin.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Kando
Exec=kando
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
        if [ -f ~/.config/autostart/kando-bin.desktop ]; then
            echo 'kando-bin.desktop successfully created'
        else
            echo 'ERROR: Failed to create kando-bin.desktop' >&2
            exit 1
        fi
    " || error "Failed to configure kando-bin autostart"

    success "kando-bin autostart configured successfully for $USERNAME"
}

# Apply desktop environment specific final configurations
apply_desktop_final_config() {
    case "$SELECTED_DE" in
        "hyprland")
            set_burn_tvglitch_chroot
            configure_os_release
            set_default_WavesOS_theme
            ;;
        "gnome")
            # GNOME-specific final configurations
            configure_os_release
            ;;
        "both")
            set_burn_tvglitch_chroot
            configure_os_release
            set_default_WavesOS_theme
            ;;
    esac
}

set_burn_tvglitch_chroot() {
    section_header "Desktop • TV-Glitch"
    log "Setting Burn My Windows TV-Glitch effect for $USERNAME..."

    # Verify /mnt is mounted
    if ! mountpoint -q /mnt; then
        error "Root partition /mnt is not mounted"
    fi

    show_progress 1 1 "Configuring TV-Glitch effect..."
    arch-chroot /mnt su - "$USERNAME" -c "
        mkdir -p /home/$USERNAME/.config/burn-my-windows/profiles || { echo 'Failed to create burn-my-windows profiles directory' >&2; exit 1; }
        
        profile_dir=\"/home/$USERNAME/.config/burn-my-windows/profiles\"
        profile_file=\"\$profile_dir/\$(date +%s).conf.json\"
        
        # Create TV-Glitch profile
        cat > \"\$profile_file\" << 'EOF'
[burn-my-windows-profile]
fire-enable-effect=false
tv-glitch-enable-effect=true
EOF
        
        # Set proper ownership
        chown -R $USERNAME:$USERNAME /home/$USERNAME/.config/burn-my-windows/
        
        if [ -f \"\$profile_file\" ]; then
            echo 'TV-Glitch profile created successfully'
        else
            echo 'ERROR: Failed to create TV-Glitch profile' >&2
            exit 1
        fi
        
        # Create comprehensive setup script and autostart
        mkdir -p /home/$USERNAME/.config/autostart
        cat > /home/$USERNAME/.config/autostart/burn-my-windows-setup.desktop << 'AUTOSTART_EOF'
[Desktop Entry]
Type=Application
Name=Burn My Windows TV-Glitch Setup
Exec=bash -c \"sleep 5 && /home/$USERNAME/.config/burn-my-windows-setup.sh\"
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
StartupNotify=false
AUTOSTART_EOF
        
        # Create setup script
        cat > /home/$USERNAME/.config/burn-my-windows-setup.sh << 'BMWS_EOF'
#!/bin/bash
# Set TV-Glitch effects
sleep 10
gsettings set org.gnome.shell.extensions.burn-my-windows open-window-effect 'tv-glitch'
gsettings set org.gnome.shell.extensions.burn-my-windows close-window-effect 'tv-glitch'
rm /home/$USERNAME/.config/autostart/burn-my-windows-setup.desktop
rm \$0
BMWS_EOF
        
        chmod +x /home/$USERNAME/.config/burn-my-windows-setup.sh
        chown -R $USERNAME:$USERNAME /home/$USERNAME/.config/
        
    " || error "Failed to configure TV-Glitch effect"

    success "TV-Glitch effect configured successfully for $USERNAME"
}

set_default_WavesOS_theme() {
    section_header "Desktop • Default Theme"
    log "Setting WavesOS theme for $USERNAME..."

    # Verify /mnt is mounted
    if ! mountpoint -q /mnt; then
        error "Root partition /mnt is not mounted"
    fi

    # Check if kora-pgrey icon theme is installed
    if ! [ -d /mnt/usr/share/icons/kora-pgrey ]; then
        error "kora-pgrey icon theme not found in /mnt/usr/share/icons"
    fi

    show_progress 1 1 "Configuring WavesOS theme..."
    arch-chroot /mnt su - "$USERNAME" -c "
       dbus-launch gsettings set org.gnome.desktop.interface icon-theme 'kora-pgrey'
       dbus-launch gsettings set org.gnome.desktop.background picture-uri '/home/$USERNAME/.config/hypr/Wallpaper/linux.jpg'
       dbus-launch gsettings set org.gnome.desktop.background picture-uri-dark '/home/$USERNAME/.config/hypr/Wallpaper/linux.jpg'  || { echo 'Failed to set icon theme via gsettings' >&2; exit 1; }
        if [ \"\$(gsettings get org.gnome.desktop.interface icon-theme)\" = \"'kora-pgrey'\" ]; then
            echo 'Default WavesOS customizations are successfully configured'
        else
            echo 'ERROR: Failed to verify kora-pgrey icon theme' >&2
            exit 1
        fi
    " || error "Failed to configure kora-pgrey icon theme"

    success "Successfully set kora-pgrey as default icon theme for $USERNAME"
}
