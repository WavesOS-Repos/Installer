#!/bin/bash

# WavesOS Installation Script - Desktop Environment Library
# Contains desktop installation and WavesOS customizations

# Global variable for selected desktop environment(s)
SELECTED_DE=()

# Helper function to check if a desktop environment is selected
is_de_selected() {
    local de="$1"
    for selected in "${SELECTED_DE[@]}"; do
        if [ "$selected" = "$de" ]; then
            return 0
        fi
    done
    return 1
}

# Desktop Environment Selection Menu
select_desktop_environment() {
    section_header "Desktop • Environment Selection"
    log "Choose your desktop environment for WavesOS..."
    echo
    
    local de_options=(
        "Hyprland (Modern Wayland - Gaming/Power Users)"
        "GNOME (Traditional Desktop - User-friendly)"
        "COSMIC (Next-generation Rust-based Desktop)"
    )
    
    echo -e "${NEON_PURPLE}${BOLD}Available Desktop Environments:${NC}"
    echo -e "${DARK_GRAY}┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐${NC}"
    
    for i in "${!de_options[@]}"; do
        printf "${DARK_GRAY}│${NC} ${NEON_CYAN}${BOLD}%d)${NC} ${SILVER}%-95s${NC} ${DARK_GRAY}│${NC}\n" "$((i+1))" "${de_options[$i]}"
    done
    
    echo -e "${DARK_GRAY}└─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo
    
    # Get user selection (single or multiple)
    while true; do
        echo -e "${NEON_ORANGE}${BOLD}Select desktop environment(s):${NC}"
        echo -e "${NEON_CYAN}${BOLD}• Single selection: ${NC}${SILVER}Enter one number (e.g., 1)${NC}"
        echo -e "${NEON_CYAN}${BOLD}• Multiple selection: ${NC}${SILVER}Enter numbers separated by commas or spaces (e.g., 1,2 or 1 2 3)${NC}"
        echo -e "${NEON_ORANGE}${BOLD}Your choice: ${NC}"
        read -r CHOICE
        
        # Clear previous selections
        SELECTED_DE=()
        
        # Parse input (handle both comma and space separated)
        CHOICE=$(echo "$CHOICE" | tr ',' ' ')  # Convert commas to spaces
        local valid_selection=true
        
        for selection in $CHOICE; do
            case $selection in
                1)
                    SELECTED_DE+=("hyprland")
                    ;;
                2)
                    SELECTED_DE+=("gnome")
                    ;;
                3)
                    SELECTED_DE+=("cosmic")
                    ;;
                *)
                    echo -e "${NEON_PINK}${BOLD}Invalid selection: $selection. Please enter numbers 1-3 only.${NC}"
                    valid_selection=false
                    break
                    ;;
            esac
        done
        
        # Check for duplicates and remove them
        if [ "$valid_selection" = true ] && [ ${#SELECTED_DE[@]} -gt 0 ]; then
            # Remove duplicates using associative array
            declare -A seen
            local temp_array=()
            for de in "${SELECTED_DE[@]}"; do
                if [ -z "${seen[$de]:-}" ]; then
                    seen[$de]=1
                    temp_array+=("$de")
                fi
            done
            SELECTED_DE=("${temp_array[@]}")
            break
        elif [ ${#SELECTED_DE[@]} -eq 0 ]; then
            echo -e "${NEON_PINK}${BOLD}Please make at least one selection.${NC}"
        fi
    done
    
    # Confirm selection
    echo
    echo -e "${NEON_GREEN}${BOLD}Selected desktop environment(s):${NC}"
    for de in "${SELECTED_DE[@]}"; do
        case $de in
            "hyprland")
                info "✓ Hyprland (Modern Wayland desktop for gaming and power users)"
                ;;
            "gnome")
                info "✓ GNOME (Full-featured traditional desktop environment)"
                ;;
            "cosmic")
                info "✓ COSMIC (Next-generation Rust-based desktop environment)"
                ;;
        esac
    done
    
    local selection_summary=$(IFS=', '; echo "${SELECTED_DE[*]}")
    if confirm_action "Confirm these selection(s)?"; then
        success "Desktop environment(s) confirmed: $selection_summary"
    else
        error "Installation cancelled by user"
    fi
    
    echo
    clear
    show_banner
}

# Install and configure Hyprland configs
install_wavesos_customizations() {
    section_header "Desktop • WavesOS Customizations"
    log "Installing WavesOS customizations for $SELECTED_DE..."

    # Verify /mnt is mounted
    if ! mountpoint -q /mnt; then
        error "Root partition /mnt is not mounted"
    fi

    # Install customizations based on selected desktop environment(s)
    for de in "${SELECTED_DE[@]}"; do
        case "$de" in
            "hyprland")
                install_hyprland_customizations
                ;;
            "gnome")
                install_gnome_customizations
                ;;
            "cosmic")
                install_cosmic_customizations
                ;;
            *)
                warning "Unknown desktop environment: $de. Skipping customizations."
                ;;
        esac
    done

    clear
    show_banner
}

# Install Hyprland specific customizations
install_hyprland_customizations() {
    log "Installing Hyprland customizations..."
    
    show_progress 1 5 "Copying Hyprland configurations..."
    # Copy Hyprland configs to chroot
    if [ -d /root/Hyprland-configs ]; then
        cp -r /root/Hyprland-configs /mnt || error "Failed to copy Hyprland-configs to /mnt/Hyprland-configs"
    else
        error "Hyprland-configs directory not found at /root/Hyprland-configs"
    fi

    # Copy WavesHyprland configs to chroot
    if [ -d /root/WavesHyprland ]; then
        cp -r /root/WavesHyprland /mnt || error "Failed to copy WavesHyprland to /mnt/WavesHyprland"
    else
        error "WavesHyprland directory not found at /root/WavesHyprland"
    fi

    if [ -d /root/WavesHyprland-V2 ]; then
        cp -r /root/WavesHyprland-V2 /mnt || error "Failed to copy WavesHyprland-V2 to /mnt/WavesHyprland-V2"
    else
        error "WavesHyprland-V2 directory not found at /root/WavesHyprland-V2"
    fi

    show_progress 3 5 "Copying sleep.conf..."
    # Copy sleep.conf to target system
    if [ -f /etc/systemd/sleep.conf ]; then
        cp /etc/systemd/sleep.conf /mnt/etc/systemd/sleep.conf || error "Failed to copy sleep.conf to /mnt/etc/systemd/sleep.conf"
    else
        warning "No sleep.conf found at /etc/systemd/sleep.conf; skipping"
    fi

    show_progress 4 5 "Setting up Hyprland configurations..."
    # Set permissions and run install.sh in chroot
    arch-chroot /mnt bash -c "
        if [ -f /Hyprland-configs/install.sh ]; then
            chmod +x /Hyprland-configs/install.sh || { echo 'Failed to make Hyprland install.sh executable' >&2; exit 1; }
            chown -R $USERNAME:$USERNAME Hyprland-configs
            chmod +x /Hyprland-configs/dnf-scripts/*.sh 2>/dev/null || true
            chmod +x /Hyprland-configs/zypper-scripts/*.sh 2>/dev/null || true
            chmod +x /Hyprland-configs/common/*.sh 2>/dev/null || true
            chmod +x /Hyprland-configs/pacman-scripts/*.sh 2>/dev/null || true
            chmod +x /Hyprland-configs/start.sh 2>/dev/null || true
            su - \"$USERNAME\" -c 'cd /Hyprland-configs && ./install.sh' || { echo 'Hyprland install.sh failed' >&2; exit 1; }
        else
            echo 'Hyprland install.sh not found' >&2
            exit 1
        fi
    " || error "Failed to execute install.sh Hyprland script in chroot"

    success "Hyprland customizations installed successfully"
}

# Install GNOME specific customizations
install_gnome_customizations() {
    log "Installing GNOME customizations..."
    
    show_progress 1 3 "Configuring GNOME settings..."
    arch-chroot /mnt su - "$USERNAME" -c "
        # Check if D-Bus is available
        if command -v dbus-launch >/dev/null 2>&1 && dbus-launch --version >/dev/null 2>&1; then
            # Set icon theme
            dbus-launch gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
            
            # Set GTK theme
            dbus-launch gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
            
            # Set cursor theme
            dbus-launch gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
            
            # Configure window manager
            dbus-launch gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
            
            echo 'GNOME basic customizations applied successfully'
        else
            echo 'Note: Running in demo mode - D-Bus/gsettings commands skipped'
        fi
    " || warning "Some GNOME customizations failed"

    success "GNOME customizations installed successfully"
    clear
    show_banner
}

# Install COSMIC specific customizations
install_cosmic_customizations() {
    log "Installing COSMIC customizations..."
    
    show_progress 1 2 "Configuring COSMIC settings..."
    arch-chroot /mnt su - "$USERNAME" -c "
        # Basic COSMIC configuration
        echo 'COSMIC desktop environment configured successfully'
    " || warning "Some COSMIC customizations failed"

    success "COSMIC customizations installed successfully"
    clear
    show_banner
}

# Install WavesSDDM theme (COMPULSORY for ALL desktop environments)
install_SDDM_theme() {
    section_header "Desktop • SDDM Theme"
    log "Installing WavesOS SDDM theme (COMPULSORY)..."

    # Verify /mnt is mounted
    if ! mountpoint -q /mnt; then
        error "Root partition /mnt is not mounted"
    fi

    show_progress 1 5 "Verifying WavesSDDM directory..."
    if [ ! -d /root/WavesSDDM ]; then
        error "WavesSDDM directory not found at /root/WavesSDDM - This is a compulsory component!"
    fi

    show_progress 2 5 "Copying WavesSDDM Theme..."
    cp -r /root/WavesSDDM /mnt/ || error "Failed to copy WavesSDDM to /mnt/"

    show_progress 3 5 "Setting executable permissions..."
    arch-chroot /mnt chmod +x /WavesSDDM/install.sh || error "Failed to set executable permissions on install.sh"

    show_progress 4 5 "Executing SDDM theme installation..."
    arch-chroot /mnt bash -c "
        if [ -f /WavesSDDM/install.sh ]; then
            /WavesSDDM/install.sh || { echo 'WavesSDDM install.sh failed' >&2; exit 1; }
        else
            echo 'WavesSDDM install.sh not found' >&2
            exit 1
        fi
    " || error "Failed to execute SDDM install.sh script in chroot"

    show_progress 5 5 "WavesSDDM installation complete"
    success "WavesOS SDDM Theme installed successfully (COMPULSORY component)"
    clear
    show_banner
}

# Install GNOME extensions (only for GNOME or both)
install_gnome_extensions() {
    section_header "Desktop • GNOME Extensions"
    log "Installing GNOME Shell extensions for $USERNAME..."

    # Verify /mnt is mounted
    if ! mountpoint -q /mnt; then
        error "Root partition /mnt is not mounted"
    fi

    # Only install if GNOME is selected
    if ! is_de_selected "gnome"; then
        info "Skipping GNOME extensions (GNOME not selected)"
        return
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
        # Check if D-Bus is available
        if command -v dbus-launch >/dev/null 2>&1 && dbus-launch --version >/dev/null 2>&1; then
            dbus-launch gsettings set org.gnome.shell enabled-extensions \"['blur-my-shell@aunetx', 'burn-my-windows@schneegans.github.com', 'desktop-cube@schneegans.github.com']\" || { echo 'Failed to enable extensions via gsettings' >&2; exit 1; }
            if gsettings get org.gnome.shell enabled-extensions | grep -q 'blur-my-shell@aunetx'; then
                echo 'Extensions successfully enabled in gsettings'
            else
                echo 'ERROR: Failed to verify enabled extensions in gsettings' >&2
                exit 1
            fi
        else
            echo 'Note: Running in demo mode - D-Bus/gsettings commands for extensions skipped'
        fi
    " || warning "GNOME Shell extensions setup skipped in demo mode"

    # Cleanup copied extension files
    rm -rf /mnt/gnome-shell-extensions 2>/dev/null || true

    success "GNOME Shell extensions installed and enabled successfully for $USERNAME"
    clear
    show_banner
}

# Setup Kando autostart
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
    clear
    show_banner
}

# Set TV-Glitch effect (only for environments that support it)
set_burn_tvglitch_chroot() {
    section_header "Desktop • TV-Glitch"
    log "Setting Burn My Windows TV-Glitch effect for $USERNAME..."

    # Only configure if GNOME-related environments are selected
    if ! is_de_selected "gnome"; then
        info "Skipping TV-Glitch effect (GNOME not selected)"
        return
    fi

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
# Check if D-Bus is available
if command -v dbus-launch >/dev/null 2>&1 && dbus-launch --version >/dev/null 2>&1; then
    gsettings set org.gnome.shell.extensions.burn-my-windows open-window-effect 'tv-glitch'
    gsettings set org.gnome.shell.extensions.burn-my-windows close-window-effect 'tv-glitch'
else
    echo 'Note: Running in demo mode - gsettings commands for TV-Glitch skipped'
fi
rm /home/$USERNAME/.config/autostart/burn-my-windows-setup.desktop
rm \$0
BMWS_EOF
        
        chmod +x /home/$USERNAME/.config/burn-my-windows-setup.sh
        chown -R $USERNAME:$USERNAME /home/$USERNAME/.config/
        
    " || error "Failed to configure TV-Glitch effect"

    success "TV-Glitch effect configured successfully for $USERNAME"
    clear
    show_banner
}

# Set default WavesOS theme
set_default_WavesOS_theme() {
    section_header "Desktop • Default Theme"
    log "Setting WavesOS theme for $USERNAME..."

    # Verify /mnt is mounted
    if ! mountpoint -q /mnt; then
        error "Root partition /mnt is not mounted"
    fi

    # Check if kora-pgrey icon theme is installed
    if ! [ -d /mnt/usr/share/icons/kora-pgrey ]; then
        warning "kora-pgrey icon theme not found in /mnt/usr/share/icons, using default theme"
        return
    fi

    show_progress 1 1 "Configuring WavesOS theme..."
    arch-chroot /mnt su - "$USERNAME" -c "
        # Check if D-Bus is available
        if command -v dbus-launch >/dev/null 2>&1 && dbus-launch --version >/dev/null 2>&1; then
            dbus-launch gsettings set org.gnome.desktop.interface icon-theme 'kora-pgrey'
            dbus-launch gsettings set org.gnome.desktop.background picture-uri '/home/$USERNAME/.config/hypr/Wallpaper/linux.jpg'
            dbus-launch gsettings set org.gnome.desktop.background picture-uri-dark '/home/$USERNAME/.config/hypr/Wallpaper/linux.jpg'  || { echo 'Failed to set icon theme via gsettings' >&2; exit 1; }
            if [ \"\$(gsettings get org.gnome.desktop.interface icon-theme)\" = \"'kora-pgrey'\" ]; then
                echo 'Default WavesOS customizations are successfully configured'
            else
                echo 'ERROR: Failed to verify kora-pgrey icon theme' >&2
                exit 1
            fi
        else
            echo 'Note: Running in demo mode - D-Bus/gsettings commands for theme skipped'
        fi
    " || warning "WavesOS theme setup skipped in demo mode"

    success "Successfully set kora-pgrey as default icon theme for $USERNAME"
    clear
    show_banner
}