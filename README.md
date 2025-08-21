# 🚀 WavesOS Futuristic CLI Installer

A stunning, futuristic command-line interface installer for WavesOS - a custom Arch Linux distribution with Hyprland.

## ✨ Features

### 🎨 Futuristic UI/UX
- **Neon Color Palette**: Advanced 256-color terminal support with neon blues, greens, purples, and pinks
- **Animated Elements**: Wave animations, spinning indicators, and smooth transitions
- **Dynamic Progress Bars**: Real-time progress tracking with wave animations
- **Interactive Menus**: Arrow-key navigation with visual feedback
- **Status Indicators**: Emoji-based status icons for different operations
- **Responsive Design**: Adapts to terminal size automatically

### 🔧 Enhanced Functionality
- **Step-by-Step Progress**: Visual step counter with 25 major installation phases
- **Real-time Status Updates**: Live feedback for all operations
- **Error Handling**: Graceful error recovery with futuristic styling
- **Hardware Detection**: Beautiful hardware specification display
- **Disk Selection**: Interactive disk selection with detailed information
- **Boot Mode Detection**: Automatic UEFI/BIOS detection with visual confirmation

### 🎯 Installation Features
- **Modular Architecture**: Clean separation of concerns across multiple modules
- **Comprehensive Checks**: Pre-installation validation with visual feedback
- **Disk Management**: Advanced partitioning with safety checks
- **System Configuration**: Automated system setup and customization
- **Desktop Environment**: Hyprland installation with WavesOS configurations
- **Bootloader Setup**: Automatic GRUB configuration for UEFI/BIOS

## 🎨 UI Components

### Color Scheme
```bash
# Primary Colors
NEON_BLUE='\033[38;5;39m'    # Bright cyan blue
NEON_GREEN='\033[38;5;46m'   # Electric green
NEON_PURPLE='\033[38;5;99m'  # Deep purple
NEON_PINK='\033[38;5;213m'   # Hot pink
NEON_ORANGE='\033[38;5;208m' # Bright orange
NEON_CYAN='\033[38;5;51m'    # Cyan
```

### Visual Elements
- **Progress Bars**: `█▓▒░` characters with wave animations
- **Status Icons**: 🔍⚡⚙️✅❌⚠️ for different operations
- **Borders**: Unicode box-drawing characters for clean tables
- **Animations**: Spinning indicators and wave effects

### Interactive Components
- **Selection Menus**: Arrow-key navigation with visual highlighting
- **Confirmation Dialogs**: Enhanced yes/no prompts with styling
- **Input Validation**: Real-time validation with error messages
- **Step Tracking**: Visual progress through installation phases

## 🚀 Usage

### Basic Installation
```bash
sudo ./wavesos-install
```

### Features in Action

1. **Futuristic Banner**: Animated WavesOS logo with system information
2. **Hardware Detection**: Beautiful tables showing CPU, RAM, GPU, and storage
3. **Interactive Disk Selection**: Visual disk selection with detailed information
4. **Progress Tracking**: Real-time progress bars with wave animations
5. **Status Updates**: Live status indicators for all operations
6. **Installation Summary**: Comprehensive completion report with next steps

## 📁 Project Structure

```
wavesos-install/
├── wavesos-install          # Main installer script
└── usr/lib/wavesos-install/
    ├── utils.sh             # UI utilities and logging
    ├── hardware.sh          # Hardware detection and disk selection
    ├── partitioning.sh      # Disk partitioning logic
    ├── system.sh            # System installation
    ├── desktop.sh           # Desktop environment setup
    └── bootloader.sh        # Bootloader configuration
```

## 🎯 Installation Phases

1. **Pre-installation Checks** (5 steps)
   - Root privileges verification
   - Live environment detection
   - Required tools validation
   - Network connectivity test
   - System clock synchronization

2. **Disk Preparation** (6 steps)
   - Disk detection and filtering
   - Hardware specification display
   - Interactive disk selection
   - Boot mode detection
   - Partition configuration
   - Partitioning confirmation

3. **System Installation** (8 steps)
   - Mirror list optimization
   - Base system installation
   - Bootloader package installation
   - Graphics driver installation
   - Desktop environment setup
   - Custom package installation
   - Repository configuration
   - Filesystem table generation

4. **System Configuration** (6 steps)
   - System configuration
   - Chroot environment setup
   - Bootloader installation
   - WavesOS customizations
   - Theme installations
   - Autostart configuration

## 🔧 Technical Details

### Terminal Requirements
- **256-color support** for full neon color palette
- **Unicode support** for special characters and emojis
- **Minimum terminal size**: 80x24 characters
- **ANSI escape sequences** for cursor control

### Compatibility
- **Arch Linux Live Environment**
- **UEFI and BIOS systems**
- **Modern terminal emulators**
- **SSH connections** (with color support)

### Performance
- **Lightweight**: Minimal overhead from UI enhancements
- **Responsive**: Real-time updates without blocking operations
- **Efficient**: Optimized for smooth animations and transitions

## 🎨 Customization

### Color Themes
The installer supports custom color schemes by modifying the color variables in `utils.sh`:

```bash
# Custom neon colors
CUSTOM_NEON_RED='\033[38;5;196m'
CUSTOM_NEON_YELLOW='\033[38;5;226m'
```

### Animation Speed
Adjust animation timing by modifying delay values:

```bash
# Faster animations
local delay=0.05  # Default is 0.1
```

### UI Elements
Customize visual elements by modifying character arrays:

```bash
# Custom progress characters
PROGRESS_CHARS=("█" "▓" "▒" "░" "▄" "▀")
```

## 🚀 Future Enhancements

- **Sound Effects**: Terminal bell integration for important events
- **3D Effects**: ASCII art 3D elements for depth
- **Dynamic Themes**: Automatic theme switching based on time
- **Advanced Animations**: More complex animation sequences
- **Accessibility**: High contrast mode and screen reader support

## 📝 License

This project is part of the WavesOS distribution and follows the same licensing terms.

---

**Experience the future of CLI installation with WavesOS!** 🚀✨
