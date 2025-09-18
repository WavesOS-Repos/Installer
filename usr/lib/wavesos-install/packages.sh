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
	bluez bluez-utils
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
        swww
	waybar
	wayland
	wayland-protocols
	wl-clipboard
	xdg-desktop-portal-hyprland
	xorg-xwayland
	qt5-wayland
	qt6-wayland
	rofi-wayland
	slurp
	swaync
	hyprcursor
	hyprgraphics
	hypridle
	hyprland
	hyprland-qt-support
	hyprland-qtutils
	hyprlang
	hyprlock
	hyprpolkitagent
	hyprsunset
	hyprutils
	hyprwayland-scanner
	egl-wayland
	grim
	grimblast-git
	sweet-cursors-hyprcursor-git
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
        gnome 
	gnome-extra
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

# Install COSMIC specific packages
install_cosmic_packages() {
    section_header "Desktop • COSMIC Packages"
    log "Installing COSMIC desktop environment packages..."
    
    local cosmic_packages=(
        # COSMIC desktop environment
        cosmic
    )
    
    info "Installing ${#cosmic_packages[@]} COSMIC packages..."
    
    for i in "${!cosmic_packages[@]}"; do
        local current=$((i + 1))
        show_progress "$current" "${#cosmic_packages[@]}" "Installing ${cosmic_packages[$i]}..."
        
        if ! pacstrap /mnt "${cosmic_packages[$i]}" 2>/dev/null; then
            warning "Failed to install ${cosmic_packages[$i]}, continuing..."
        fi
    done
    
    success "COSMIC packages installation completed"
}

# Install WavesOS specific packages (compulsory for all installations)
install_wavesos_packages() {
    section_header "System • WavesOS Packages"
    log "Installing WavesOS specific and compulsory packages..."
    
    local wavesos_packages=(

        alsa-utils
	amd-ucode
	arch-install-scripts
	archinstall
	b43-fwcutter
	base
	bcachefs-tools
	bind
	bolt
	brltty
	broadcom-wl
	btrfs-progs
	clonezilla
	cloud-init
	cryptsetup
	darkhttpd
	ddrescue
	dhcpcd
	diffutils
	dmidecode
	dmraid
	dnsmasq
	dosfstools
	e2fsprogs
	edk2-shell
	efibootmgr
	espeakup
	ethtool
	exfatprogs
	f2fs-tools
	fatresize
	foot-terminfo
	fsarchiver
	gpart
	gpm
	gptfdisk
	grml-zsh-config
	grub
	hdparm
	hyperv
	intel-ucode
	irssi
	iw
	iwd
	jfsutils
	kitty-terminfo
	ldns
	less
	lftp
	libfido2
	libusb-compat
	linux
	linux-atm
	linux-firmware
	linux-firmware-marvell
	livecd-sounds
	lsscsi
	lvm2
	lynx
	man-db
	man-pages
	mc
	mdadm
	memtest86+
	memtest86+-efi
	mkinitcpio
	mkinitcpio-archiso
	mkinitcpio-nfs-utils
	modemmanager
	mtools
	nano
	nbd
	ndisc6
	nfs-utils
	nilfs-utils
	nmap
	ntfs-3g
	nvme-cli
	open-iscsi
	open-vm-tools
	openconnect
	openpgp-card-tools
	openssh
	openvpn
	partclone
	parted
	partimage
	pcsclite
	ppp
	pptpclient
	pv
	qemu-guest-agent
	refind
	reflector
	rp-pppoe
	rsync
	rxvt-unicode-terminfo
	screen
	sdparm
	sequoia-sq
	sg3_utils
	smartmontools
	sof-firmware
	squashfs-tools
	sudo
	syslinux
	systemd-resolvconf
	tcpdump
	terminus-font
	testdisk
	tmux
	tpm2-tools
	tpm2-tss
	udftools
	usb_modeswitch
	usbmuxd
	usbutils
	vim
	vpnc
	wireless-regdb
	wireless_tools
	wpa_supplicant
	wvdial
	xfsprogs
	yazi
	yelp
	yelp-xsl
	yyjson
	zbar
	zeromq
	zimg
	zip
	zix
	zlib
	zlib-ng
	zoxide
	zram-generator
	zsh
	zstd
	zvbi
	zxing-cpp
	swtpm
	syndication
	syntax-highlighting
	sysfsutils
	syslinux
	systemd
	systemd-libs
	systemd-sysvcompat
	taglib
	talloc
	tar
	tdb
	telepathy-glib
	telepathy-idle
	telepathy-logger
	telepathy-mission-control
	template-glib
	tevent
	texinfo
	thefuck
	thin-provisioning-tools
	thunar
	thunar-archive-plugin
	thunar-volman
	tinysparql
	tomlplusplus
	totem-pl-parser
	tpm2-tss
	tree-sitter
	tree-sitter-c
	tree-sitter-lua
	tree-sitter-markdown
	tree-sitter-query
	tree-sitter-vim
	tree-sitter-vimdoc
	tslib
	ttf-cascadia-code
	ttf-font-awesome
	ttf-jetbrains-mono-nerd
	ttf-liberation
	ttf-meslo-nerd
	ttf-nerd-fonts-symbols
	ttf-nerd-fonts-symbols-common
	tumbler
	tuned
	twolame
	tzdata
	uchardet
	udisks2
	unibilium
	unzip
	upower
	usbredir
	util-linux
	util-linux-libs
	v4l-utils
	vala
	vapoursynth
	vde2
	vid.stab
	vim
	vim-runtime
	virglrenderer
	vmaf
	volume_key
	vte-common
	vte3
	vte4
	vulkan-icd-loader
	wavpack
	webkit2gtk-4.1
	webkitgtk-6.0
	webp-pixbuf-loader
	webrtc-audio-processing-1
	wget
	which
	wildmidi
	wireless_tools
	wireplumber
	woff2
	wolfssl
	wpa_supplicant
	x264
	x265
	xcb-imdkit
	xcb-proto
	xcb-util
	xcb-util-cursor
	xcb-util-errors
	xcb-util-image
	xcb-util-keysyms
	xcb-util-renderutil
	xcb-util-wm
	xcur2png
	xdg-dbus-proxy
	xdg-desktop-portal
	xdg-desktop-portal-gtk
	xdg-utils
	xf86-input-libinput
	xfconf
	xfsprogs
	xkeyboard-config
	xorg-fonts-encodings
	xorg-server
	xorg-server-common
	xorg-setxkbmap
	xorg-xauth
	xorg-xinit
	xorg-xkbcomp
	xorg-xmodmap
	xorg-xprop
	xorg-xrandr
	xorg-xrdb
	xorg-xset
	xorgproto
	xvidcore
	xxhash
	xz
	yara
	python
	python-aiofiles
	python-argcomplete
	python-asttokens
	python-atspi
	python-attrs
	python-autocommand
	python-babel
	python-build
	python-cachecontrol
	python-cachy
	python-cairo
	python-cffi
	python-charset-normalizer
	python-cleo
	python-colorama
	python-configobj
	python-crashtest
	python-cryptography
	python-dbus
	python-decorator
	python-distlib
	python-docutils
	python-dulwich
	python-executing
	python-fastjsonschema
	python-filelock
	python-findpython
	python-gobject
	python-html5lib
	python-idna
	python-imagesize
	python-installer
	python-ipython-pygments-lexers
	python-jaraco.classes
	python-jaraco.collections
	python-jaraco.context
	python-jaraco.functools
	python-jaraco.text
	python-jedi
	python-jeepney
	python-jinja
	python-jsonschema
	python-jsonschema-specifications
	python-keyring
	python-lark-parser
	python-linux-procfs
	python-lockfile
	python-lxml
	python-markupsafe
	python-matplotlib-inline
	python-more-itertools
	python-msgpack
	python-packaging
	python-parso
	python-pbs-installer
	python-pexpect
	python-pkginfo
	python-platformdirs
	python-poetry
	python-poetry-core
	python-poetry-plugin-export
	python-prompt_toolkit
	python-psutil
	python-ptyprocess
	python-pure-eval
	python-pycparser
	python-pygments
	python-pyproject-hooks
	python-pyte
	python-pytz
	python-pyudev
	python-pywal
	python-pyxdg
	python-rapidfuzz
	python-referencing
	python-requests
	python-requests-toolbelt
	python-roman-numerals-py
	python-rpds-py
	python-secretstorage
	python-setuptools
	python-shellingham
	python-six
	python-snowballstemmer
	python-sphinx
	python-sphinx-alabaster-theme
	python-sphinxcontrib-applehelp
	python-sphinxcontrib-devhelp
	python-sphinxcontrib-htmlhelp
	python-sphinxcontrib-jsmath
	python-sphinxcontrib-qthelp
	python-sphinxcontrib-serializinghtml
	python-stack-data
	python-tomlkit
	python-tqdm
	python-traitlets
	python-trove-classifiers
	python-typing_extensions
	python-urllib3
	python-virtualenv
	python-wcwidth
	python-webencodings
	python-wheel
	qca-qt6
	qqwing
	qrencode
	qt5-base
	qt5-declarative
	qt5-graphicaleffects
	qt5-quickcontrols2
	qt5-svg
	qt5-translations
	qt5-x11extras
	qt5ct
	qt6-5compat
	qt6-base
	qt6-declarative
	qt6-multimedia
	qt6-multimedia-ffmpeg
	qt6-shadertools
	qt6-speech
	qt6-svg
	qt6-translations
	qt6ct
	raptor
	rav1e
	re2
	readline
	retro-gtk
	ripgrep
	ripgrep-all
	rpcbind
	rsync
	rtkit
	rtmpdump
	rubberband
	rutabaga-ffi
	sbc
	scdoc
	sdbus-cpp
	sddm
	sdl2-compat
	sdl2_image
	sdl3
	seabios
	seatd
	sed
	semver
	serd
	shaderc
	shadow
	shared-mime-info
	simdjson
	slang
	sleuthkit
	smartmontools
	smbclient
	snappy
	sndio
	solid
	sonnet
	sord
	sound-theme-freedesktop
	soundtouch
	spandsp
	spdlog
	speex
	speexdsp
	spice
	spice-gtk
	spice-protocol
	spirv-tools
	sqlite
	squashfs-tools
	sratom
	srt
	startup-notification
	strace
	sudo
	suitesparse
	supermin
	svt-av1
	svt-hevc
	swappy
	licenses
	lilv
	linux
	linux-api-headers
	linux-firmware
	linux-firmware-whence
	linux-headers
	llhttp
	llvm-libs
	lm_sensors
	lmdb
	localsearch
	lrzip
	lsof
	lsscsi
	lua
	lua51-lpeg
	luajit
	lv2
	lvm2
	lxappearance
	lz4
	lzo
	lzop
	m4
	make
	md4c
	mdadm
	media-player-info
	mesa
	meson
	minizip
	mjpegtools
	mkinitcpio
	mkinitcpio-busybox
	mobile-broadband-provider-info
	mpdecimal
	mpfr
	mpg123
	mpv
	mpv-mpris
	msgpack-c
	mtdev
	mtools
	mujs
	multipath-tools
	nano
	ncurses
	ndctl
	neon
	neovim
	netpbm
	nettle
	network-manager-applet
	networkmanager
	nftables
	nilfs-utils
	ninja
	nm-connection-editor
	node-gyp
	nodejs
	nodejs-nopt
	noto-fonts
	noto-fonts-emoji
	npm
	npth
	nspr
	nss
	ntfs-3g
	numactl
	nwg-look
	ocl-icd
	oniguruma
	openal
	opencore-amr
	openexr
	openh264
	openjpeg2
	openssh
	openssl
	opus
	orc
	os-prober
	osinfo-db
	ostree
	p11-kit
	pacman
	pacman-contrib
	pacman-mirrorlist
	pahole
	pam
	pambase
	pamixer
	pango
	pangomm
	pangomm-2.48
	parallel
	parted
	patch
	pavucontrol
	pciutils
	pcre
	pcre2
	pcsclite
	perf
	perl
	perl-error
	perl-libintl-perl
	perl-mailtools
	perl-timedate
	phodav
	phonon-qt6
	pinentry
	pipewire
	pipewire-alsa
	pipewire-audio
	pipewire-jack
	pipewire-pulse
	pixman
	pkgconf
	plasma-activities
	playerctl
	polkit
	polkit-kde-agent
	polkit-qt6
	poppler
	poppler-data
	poppler-glib
	poppler-qt6
	popt
	portaudio
	power-profiles-daemon
	procps-ng
	protobuf
	psmisc
	pugixml
	groff
	grub
	gsettings-desktop-schemas
	gsettings-system-schemas
	gsfonts
	gsm
	gsound
	gspell
	gssdp
	gst-plugin-pipewire
	gst-plugins-bad
	gst-plugins-bad-libs
	gst-plugins-base
	gst-plugins-base-libs
	gst-plugins-good
	gstreamer
	gtest
	gtk-doc
	gtk-layer-shell
	gtk-update-icon-cache
	gtk-vnc
	gtk2
	gtk3
	gtk4
	gtkmm-4.0
	gtkmm3
	gtksourceview4
	gtksourceview5
	gts
	guestfs-tools
	guile
	gum
	gupnp
	gupnp-av
	gupnp-dlna
	gupnp-igd
	gzip
	harfbuzz
	harfbuzz-icu
	hdparm
	hicolor-icon-theme
	hidapi
	highway
	hivex
	htop
	hwdata
	hyphen
	iana-etc
	icu
	ijs
	imagemagick
	imath
	imlib2
	iniparser
	intel-ucode
	iproute2
	iptables
	iputils
	ipython
	iso-codes
	iwd
	jansson
	jasper
	jbig2dec
	jbigkit
	jfsutils
	jq
	js128
	json-c
	json-glib
	jsoncpp
	jsonrpc-glib
	karchive
	kauth
	kbd
	kbookmarks
	kcmutils
	kcodecs
	kcolorscheme
	kcompletion
	kconfig
	kconfigwidgets
	kcoreaddons
	kcrash
	kdbusaddons
	kdnssd
	kdsoap-qt6
	kdsoap-ws-discovery-client
	keyutils
	kfilemetadata
	kglobalaccel
	kguiaddons
	ki18n
	kiconthemes
	kidletime
	kio
	kio-extras
	kirigami
	kitemviews
	kitty
	kitty-shell-integration
	kitty-terminfo
	kjobwidgets
	kmod
	knewstuff
	knotifications
	kpackage
	kparts
	krb5
	kservice
	ktextwidgets
	kuserfeedback
	kvantum
	kvantum-qt5
	kwallet
	kwidgetsaddons
	kwindowsystem
	kxmlgui
	l-smash
	lame
	lapack
	lcms2
	ldb
	leancrypto
	lensfun
	less
	capstone
	cava
	cdparanoia
	cdrtools
	chromaprint
	chromium
	cifs-utils
	clang
	cliphist
	clutter
	clutter-gst
	clutter-gtk
	cmark
	cogl
	compiler-rt
	composefs
	convertlit
	coreutils
	cpio
	cracklib
	cryptsetup
	ctags
	curl
	dav1d
	db5.3
	dbus
	dbus-broker
	dbus-broker-units
	dbus-glib
	dbus-units
	dconf
	debootstrap
	default-cursors
	desktop-file-utils
	device-mapper
	dhcpcd
	dialog
	diffutils
	distro-info
	distro-info-data
	dkms
	dleyna
	dnsmasq
	docbook-xml
	docbook-xsl
	dosfstools
	double-conversion
	dtc
	duktape
	e2fsprogs
	ebook-tools
	editorconfig-core-c
	edk2-aarch64
	edk2-arm
	edk2-ovmf
	efibootmgr
	efivar
	egl-gbm
	egl-x11
	eglexternalplatform
	elfutils
	ell
	enchant
	erofs-utils
	ethtool
	evolution-data-server
	exempi
	exfatprogs
	exiv2
	exo
	expat
	eza
	f2fs-tools
	faac
	faad2
	fakeroot
	fastfetch
	ffmpeg
	ffmpegthumbnailer
	ffnvcodec-headers
	fftw
	figlet
	file
	filesystem
	findutils
	flac
	flatpak
	flex
	fluidsynth
	fmt
	folks
	fontconfig
	freeglut
	freetype2
	frei0r-plugins
	fribidi
	fuse-common
	fuse2
	fuse3
	fzf
	gawk
	gc
	gcc
	gcc-libs
	gcr
	gcr-4
	gd
	gdbm
	gdk-pixbuf2
	gegl
	geocode-glib-2
	geocode-glib-common
	gettext
	gfxstream
	ghostscript
	giflib
	git
	gjs
	glib-networking
	glib2
	glib2-docs
	glibc
	glibmm
	glibmm-2.68
	glm
	glslang
	glu
	glusterfs
	gmime3
	gmp
	gnu-free-fonts
	gnulib-l10n
	gnupg
	gnutls
	go
	gobject-introspection-runtime
	gom
	gperftools
	gpgme
	gpgmepp
	gpm
	gptfdisk
	granite
	graphene
	graphite
	graphviz
	grep
	grilo
	aalib
	abseil-cpp
	acl
	adwaita-cursors
	adwaita-fonts
	adwaita-icon-theme
	adwaita-icon-theme-legacy
	alsa-card-profiles
	alsa-lib
	alsa-topology-conf
	alsa-ucm-conf
	aom
	appstream
	aquamarine
	arch-install-scripts
	archiso
	archlinux-keyring
	at-spi2-core
	atkmm
	attica
	attr
	audit
	augeas
	autoconf
	autoconf-archive
	automake
	avahi
	babl
	baloo
	baloo-widgets
	base
	base-devel
	bash
	bat
	binutils
	bison
	blas
	bluez-libs
	breeze-icons
	brltty
	brotli
	btop
	btrfs-progs
	bubblewrap
	bzip2
	c-ares
	ca-certificates
	ca-certificates-mozilla
	ca-certificates-utils
	cairo
	cairomm
	cairomm-1.16
	pyprland
	yay
	wvkbd
	zen-browser-bin
	kando-bin
	kora-icon-theme
	aura

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
        "cosmic")
            install_cosmic_packages
            ;;
        *)
            error "Invalid desktop environment selection: $SELECTED_DE"
            ;;
    esac
    
    success "Desktop environment packages installed for: $SELECTED_DE"
}
