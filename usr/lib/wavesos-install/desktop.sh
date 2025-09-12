
#!/bin/bash

# WavesOS Installation Script - Desktop Environment Library
# Contains desktop installation and WavesOS customizations

# [Moved to packages.sh] install_desktop_environment

# Install and configure Hyprland configs
install_wavesos_customizations() {
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

# Install WavesSDDM
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
        cp -r /root/WavesSDDM /mnt/ || error "Failed to copy WavesSDDM to /mnt/"
    else
        error "WavesSDDM directory not found at /mnt"
    fi
  
       show_progress 4 5 "Setting up configurations..."
    # Set permissions and run install.sh in chroot
    arch-chroot /mnt bash -c "
        [ -f WavesSDDM/install.sh ] 
        chmod +x WavesSDDM/install.sh 
        WavesSDDM//install.sh || echo 'WavesSDDM  install.sh not found or failed' >&2
        " || error "Failed to execute install.sh script in chroot"
        success "WavesOS SDDM Theme installed successfully"
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
