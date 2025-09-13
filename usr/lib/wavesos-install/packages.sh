#!/bin/bash

# WavesOS Installation Script - Packages Library
# Contains all package installation functions consolidated from system.sh and desktop.sh

# Install base system packages
install_base_system() {
    section_header "System • Base Packages"
    log "Installing base system packages..."
    
    local base_packages=(
        base base-devel linux linux-firmware linux-headers
        networkmanager dhcpcd iwd wireless_tools wpa_supplicant
        sudo nano vim git curl wget rsync
        bash-completion man-db man-pages
        reflector pacman-contrib
    )
    
    show_progress 1 3 "Installing base system..."
    if ! pacstrap /mnt "${base_packages[@]}"; then
        error "Failed to install base system packages"
    fi
    
    success "Base system installed successfully"
}

# Install bootloader packages
install_bootloader_packages() {
    section_header "System • Bootloader"
    log "Installing bootloader packages..."
    
    if [ "$BOOT_MODE" = "uefi" ]; then
        show_progress 2 3 "Installing UEFI bootloader..."
        if ! pacstrap /mnt grub efibootmgr dosfstools; then
            error "Failed to install UEFI bootloader packages"
        fi
    else
        show_progress 2 3 "Installing BIOS bootloader..."
        if ! pacstrap /mnt grub; then
            error "Failed to install BIOS bootloader packages"
        fi
    fi
    
    success "Bootloader packages installed"
}

# Install graphics drivers
install_graphics_drivers() {
    section_header "System • Graphics"
    log "Graphics driver selection:"
    echo "1) Intel (open-source)"
    echo "2) AMD (open-source)" 
    echo "3) NVIDIA (proprietary)"
    echo "4) NVIDIA (open-source nouveau)"
    echo "5) Generic/VM (VESA)"
    
    read -p "Select graphics driver (1-5): " GPU_CHOICE
    
    case $GPU_CHOICE in
        1) gpu_packages=(xf86-video-intel intel-media-driver vulkan-intel) ;;
        2) gpu_packages=(xf86-video-amdgpu mesa vulkan-radeon libva-mesa-driver) ;;
        3) gpu_packages=(nvidia nvidia-utils nvidia-settings) ;;
        4) gpu_packages=(xf86-video-nouveau mesa) ;;
        5) gpu_packages=(xf86-video-vesa mesa) ;;
        *) gpu_packages=(xf86-video-vesa mesa) ;;
    esac
    
    show_progress 3 3 "Installing graphics drivers..."
    if ! pacstrap /mnt "${gpu_packages[@]}"; then
        warning "Some graphics packages failed to install"
    fi
    
    success "Graphics drivers installed"
}

# Install Hyprland specific packages
install_hyprland_packages() {
    section_header "Desktop • Hyprland Packages"
    log "Installing Hyprland desktop environment packages..."
    
    local hyprland_packages=(
        # Core Hyprland
        hyprland waybar wofi dunst
        xorg-xwayland qt5-wayland qt6-wayland
        
        # Hyprland ecosystem
        hypridle hyprlock hyprpaper
        xdg-desktop-portal-hyprland
        
        # Wayland utilities
        wl-clipboard grim slurp
        rofi-wayland swappy
        
        # Terminal emulators
        alacritty kitty
        
        # File manager
        thunar thunar-volman gvfs tumbler
        
        # System utilities for Hyprland
        brightnessctl playerctl
        network-manager-applet
        polkit-gnome
    )
    
    info "Installing ${#hyprland_packages[@]} Hyprland packages..."
    
    for i in "${!hyprland_packages[@]}"; do
        local current=$((i + 1))
        show_progress "$current" "${#hyprland_packages[@]}" "Installing ${hyprland_packages[$i]}..."
        
        if ! pacstrap /mnt "${hyprland_packages[$i]}" 2>/dev/null; then
            warning "Failed to install ${hyprland_packages[$i]}, continuing..."
        fi
    done
    
    success "Hyprland packages installation completed"
}

# Install GNOME specific packages
install_gnome_packages() {
    section_header "Desktop • GNOME Packages"
    log "Installing GNOME desktop environment packages..."
    
    local gnome_packages=(
        # Full GNOME suite
        gnome gnome-extra
        
        # GNOME base components
        gnome-shell gnome-session gnome-settings-daemon
        gnome-control-center gnome-terminal nautilus
        gnome-tweaks gnome-shell-extensions
        
        # GNOME applications
        eog evince file-roller gedit
        gnome-calculator gnome-calendar gnome-characters
        gnome-clocks gnome-contacts gnome-font-viewer
        gnome-logs gnome-maps gnome-photos gnome-screenshot
        gnome-system-monitor gnome-weather
        
        # Additional GNOME utilities
        dconf-editor chrome-gnome-shell
        
        # GNOME themes and icons
        adwaita-icon-theme gnome-themes-extra
        
        # Essential libraries for GNOME
        gtk3 gtk4 glib2 gvfs
        gsettings-desktop-schemas
    )
    
    info "Installing ${#gnome_packages[@]} GNOME packages..."
    
    for i in "${!gnome_packages[@]}"; do
        local current=$((i + 1))
        show_progress "$current" "${#gnome_packages[@]}" "Installing ${gnome_packages[$i]}..."
        
        if ! pacstrap /mnt "${gnome_packages[$i]}" 2>/dev/null; then
            warning "Failed to install ${gnome_packages[$i]}, continuing..."
        fi
    done
    
    success "GNOME packages installation completed"
}

# Install WavesOS specific packages (compulsory for all installations)
install_wavesos_packages() {
    section_header "System • WavesOS Packages"
    log "Installing WavesOS specific and compulsory packages..."
    
    local wavesos_packages=(
        # Audio system
        pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber
        pavucontrol
        
        # Display manager (compulsory)
        sddm
        
        # Fonts
        ttf-dejavu ttf-liberation noto-fonts noto-fonts-emoji
        ttf-fira-code ttf-opensans
        
        # Essential applications
        firefox
        
        # System monitoring and utilities
        htop neofetch btop
        zip unzip p7zip
        
        # Development tools
        code python python-pip nodejs npm
        
        # Theme and customization
        qt5ct qt6ct
        
        # Bluetooth and hardware support
        bluez bluez-utils
        
        # Multimedia codecs
        gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly
        gst-libav ffmpeg
        
        # Archive support
        unrar p7zip-plugins
    )
    
    info "Installing ${#wavesos_packages[@]} WavesOS packages..."
    
    for i in "${!wavesos_packages[@]}"; do
        local current=$((i + 1))
        show_progress "$current" "${#wavesos_packages[@]}" "Installing ${wavesos_packages[$i]}..."
        
        if ! pacstrap /mnt "${wavesos_packages[$i]}" 2>/dev/null; then
            warning "Failed to install ${wavesos_packages[$i]}, continuing..."
        fi
    done
    
    success "WavesOS packages installation completed"
}

# Install custom packages from packages.x86_64 file
install_custom_packages() {
    section_header "System • Custom Packages"
    if [ -f /root/packages.x86_64 ]; then
        log "Installing custom packages from /root/packages.x86_64..."
        mapfile -t custom_packages < <(grep -v '^#' /root/packages.x86_64 | grep -v '^\s*$')
        
        if [ ${#custom_packages[@]} -gt 0 ]; then
            for pkg in "${custom_packages[@]}"; do
                info "Installing custom package: $pkg"
                if ! pacstrap /mnt "$pkg" 2>/dev/null; then
                    warning "Failed to install custom package: $pkg"
                fi
            done
            success "Custom packages installation completed"
        else
            warning "No valid packages found in /root/packages.x86_64"
        fi
    else
        info "No custom packages file found, skipping"
    fi
}

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

# Main desktop environment installation function
install_desktop_environment() {
    section_header "Desktop • Environment Installation"
    log "Installing desktop environment based on selection: $SELECTED_DE"
    
    # Always install WavesOS packages (compulsory)
    install_wavesos_packages
    
    # Install specific packages based on selection
    case "$SELECTED_DE" in
        "hyprland")
            install_hyprland_packages
            ;;
        "gnome")
            install_gnome_packages
            ;;
        "both")
            install_hyprland_packages
            install_gnome_packages
            ;;
        *)
            error "Invalid desktop environment selection: $SELECTED_DE"
            ;;
    esac
    
    success "Desktop environment packages installed for: $SELECTED_DE"
}