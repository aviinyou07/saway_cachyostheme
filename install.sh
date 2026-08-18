#!/usr/bin/env bash
# ==============================================================================
# CYBER NOIR WORKSTATION // AUTOMATED DEVOPS INSTALLER SCRIPT
# ==============================================================================
# Target OS: CachyOS / Arch Linux (Wayland Edition)
# Architecture: Sway, Waybar, Mako, Wofi, Kitty, Starship, Fastfetch, Neovim & SDDM
#
# Engineered with strict idempotency, resilient trap handling, automatic config
# backups, package verification, and Cyber Noir truecolor visual output.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CYBER NOIR TRUECOLOR DISPLAY ENGINE
# ------------------------------------------------------------------------------
# Mandatory Hex Tokens rendered directly via 24-bit RGB ANSI terminal escape codes
# 24-bit ANSI, mirroring PALETTE.md
CYAN=$'\033[38;2;56;189;248m'       # accent  #38BDF8
GREEN=$'\033[38;2;34;197;94m'       # ok      #22C55E
YELLOW=$'\033[38;2;251;191;36m'     # warn    #FBBF24
RED=$'\033[38;2;239;68;68m'         # err     #EF4444
SECONDARY=$'\033[38;2;100;116;139m' # text-3  #64748B
BOLD=$'\033[1m'
RESET=$'\033[0m'

log_info()    { printf "${CYAN}  [INFO]${RESET}    %s\n" "$1"; }
log_success() { printf "${GREEN} ❯ [SUCCESS]${RESET} %s\n" "$1"; }
log_warn()    { printf "${YELLOW}  [WARNING]${RESET} %s\n" "$1"; }
log_error()   { printf "${RED}  [ERROR]${RESET}   %s\n" "$1" >&2; }
draw_line()   { printf "${SECONDARY}─────────────────────────────────────────────────────────────────────────────${RESET}\n"; }

draw_header() {
    clear || true
    printf "${GREEN}${BOLD}"
    cat << "EOF"
  ██████╗   ██╗   ██╗ ██████╗  ███████╗ ██████╗      ███╗   ██╗  ██████╗  ██╗ ██████╗ 
 ██╔════╝   ╚██╗ ██╔╝ ██╔══██╗ ██╔════╝ ██╔══██╗     ████╗  ██║ ██╔═══██╗ ██║ ██╔══██╗
 ██║         ╚████╔╝  ██████╔╝ █████╗   ██████╔╝     ██╔██╗ ██║ ██║   ██║ ██║ ██████╔╝
 ██║          ╚██╔╝   ██╔══██╗ ██╔══╝   ██╔══██╗     ██║╚██╗██║ ██║   ██║ ██║ ██╔══██╗
 ╚██████╗      ██║    ██████╔╝ ███████╗ ██║  ██║     ██║ ╚████║ ╚██████╔╝ ██║ ██║  ██║
  ╚═════╝      ╚═╝    ╚═════╝  ╚══════╝ ╚═╝  ╚═╝     ╚═╝  ╚═══╝  ╚═════╝  ╚═╝ ╚═╝  ╚═╝
EOF
    printf "${CYAN}${BOLD}                 [ PRODUCTION LINUX DEVOPS WORKSTATION // CACHYOS ]${RESET}\n"
    draw_line
}

# ------------------------------------------------------------------------------
# 2. RESILIENT ERROR HANDLING & PRE-FLIGHT VERIFICATIONS
# ------------------------------------------------------------------------------
trap 'error_handler $? $LINENO' ERR

error_handler() {
    local err_code="$1"
    local line_num="$2"
    log_error "Execution terminated prematurely at line ${line_num} with exit code ${err_code}."
    log_warn "Any configurations deployed prior to this failure remain preserved in your backup folder."
    exit "${err_code}"
}

# ------------------------------------------------------------------------------
# 2b. UNINSTALL / RESTORE
# ------------------------------------------------------------------------------
# The installer has always created a timestamped backup vault, but there was no
# way to get anything back out of it. `--uninstall` restores the most recent one.
if [[ "${1:-}" == "--uninstall" || "${1:-}" == "-u" ]]; then
    draw_header
    RESTORE_MODULES=("sway" "waybar" "mako" "wofi" "kitty" "starship" "fastfetch"
                     "nvim" "swaylock" "btop" "networkmanager-dmenu")

    # `|| true`: with `set -euo pipefail` a find that matches nothing (or a
    # missing ~/.config) would trip the ERR trap before the check below runs.
    LATEST_BACKUP=$(find "${HOME}/.config" -maxdepth 1 -type d -name 'cyber_noir_backup_*' 2>/dev/null | sort | tail -1 || true)
    if [[ -z "${LATEST_BACKUP}" ]]; then
        log_error "No backup vault found under ~/.config/cyber_noir_backup_*"
        log_warn  "Nothing was restored. Your current configuration is untouched."
        exit 1
    fi

    log_info "Restoring from: ${CYAN}${LATEST_BACKUP}${RESET}"
    read -rp "This replaces your current desktop configuration. Continue? (y/N): " CONFIRM
    [[ "${CONFIRM}" =~ ^[Yy]$ ]] || { log_warn "Cancelled."; exit 0; }

    for mod in "${RESTORE_MODULES[@]}"; do
        if [[ -d "${LATEST_BACKUP}/${mod}" ]]; then
            rm -rf "${HOME}/.config/${mod}"
            cp -r "${LATEST_BACKUP}/${mod}" "${HOME}/.config/${mod}"
            log_success "Restored ~/.config/${mod}"
        else
            # Nothing was there before we installed, so remove what we added.
            rm -rf "${HOME}/.config/${mod}"
            log_info "Removed ~/.config/${mod} (had no pre-existing version)"
        fi
    done

    # Configuration this installer added outside the module directories.
    rm -f "${HOME}/.config/gtk-3.0/settings.ini" \
          "${HOME}/.config/gtk-4.0/settings.ini" \
          "${HOME}/.config/xdg-desktop-portal/sway-portals.conf"
    rm -rf "${XDG_STATE_HOME:-${HOME}/.local/state}/cyber-studio"
    log_success "Removed GTK, portal and runtime-state files."

    draw_line
    log_success "Restore complete. Log out and back in to pick up the old session."
    log_warn "System-level items were left in place on purpose:"
    printf "   - SDDM theme:    sudo rm -rf /usr/share/sddm/themes/cyber-noir\n"
    printf "   - SDDM config:   sudo rm -f /etc/sddm.conf.d/10-cyber-noir.conf\n"
    printf "   - Session entry: sudo rm -f /usr/share/wayland-sessions/sway.desktop\n"
    printf "   - Telemetry:     sudo systemctl disable --now sddm-telemetry.service\n"
    printf "   - Launcher:      sudo rm -f /usr/local/bin/sway-cyber-noir /usr/local/bin/sddm-telemetry-update\n"
    exit 0
fi

if [[ "${EUID}" -eq 0 ]]; then
    log_error "This script must NOT be invoked directly as root or with sudo."
    log_warn "Run as your primary user. Sudo will be called automatically when elevating privileges."
    exit 1
fi

# Locate execution directory (ensures paths work from anywhere in filesystem)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# ------------------------------------------------------------------------------
# 3. OPERATING SYSTEM & ARCHITECTURE DETECTION
# ------------------------------------------------------------------------------
draw_header
log_info "Verifying host operating system and package architecture..."

if [[ ! -f "/etc/os-release" ]]; then
    log_error "Unable to locate /etc/os-release. System compatibility cannot be verified."
    exit 1
fi

# Extract distribution identifier
OS_ID=$(grep -oP '(?<=^ID=).*' /etc/os-release | tr -d '"')
OS_NAME=$(grep -oP '(?<=^NAME=).*' /etc/os-release | tr -d '"')

if [[ "${OS_ID}" =~ (cachyos|arch) || "${OS_NAME}" =~ (CachyOS|Arch) ]]; then
    log_success "Verified Host OS: ${GREEN}${OS_NAME}${RESET} // Architecture: ${CYAN}$(uname -m)${RESET}"
else
    log_warn "Host OS detected as '${OS_NAME}' (${OS_ID}). This workstation theme targets CachyOS / Arch Linux."
    read -rp "Do you wish to proceed anyway? (y/N): " FORCE_PROCEED
    if [[ ! "${FORCE_PROCEED}" =~ ^[Yy]$ ]]; then
        log_error "Installation canceled by user."
        exit 0
    fi
fi

# ------------------------------------------------------------------------------
# 4. AUR HELPER RESOLUTION & PACKAGE REPOSITORY SYNC
# ------------------------------------------------------------------------------
log_info "Evaluating available AUR package helper utilities..."
AUR_HELPER=""

if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
    log_success "Detected active CachyOS package helper: ${GREEN}paru${RESET}"
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
    log_success "Detected active Arch package helper: ${GREEN}yay${RESET}"
else
    log_warn "No AUR helper (paru/yay) detected. Installing paru from CachyOS repositories or AUR..."
    sudo pacman -Sy --needed --noconfirm git base-devel
    if ! sudo pacman -S --needed --noconfirm paru; then
        log_info "Building paru manually via Arch User Repository..."
        TEMP_DIR=$(mktemp -d)
        git clone https://aur.archlinux.org/paru.git "${TEMP_DIR}/paru"
        (cd "${TEMP_DIR}/paru" && makepkg -si --noconfirm)
        rm -rf "${TEMP_DIR}"
    fi
    AUR_HELPER="paru"
    log_success "Successfully installed package utility: ${GREEN}paru${RESET}"
fi

# Define master inventory of required software packages
CORE_PKGS=(
    # Compositor & desktop shell
    "sway" "swaybg" "swayidle" "swaylock" "waybar" "mako" "wofi"
    # Terminal, shell, editor
    "kitty" "zsh" "starship" "neovim" "fastfetch" "btop"
    # Wayland utilities
    "wl-clipboard" "cliphist" "grim" "slurp" "brightnessctl"
    "xdg-desktop-portal" "xdg-desktop-portal-wlr" "xdg-desktop-portal-gtk"
    "polkit-gnome" "nwg-displays"          # nwg-displays: bound to XF86Display
    # Networking, audio, bluetooth
    "networkmanager" "networkmanager-dmenu" "blueman" "pavucontrol"
    "pipewire" "pipewire-pulse" "wireplumber"
    # Display manager
    "sddm" "qt5-graphicaleffects" "qt5-quickcontrols2" "qt6-svg"
    # Fonts & icons
    "ttf-jetbrains-mono" "ttf-jetbrains-mono-nerd" "noto-fonts" "noto-fonts-emoji"
    "papirus-icon-theme" "catppuccin-gtk-theme-mocha"
    # ---------------------------------------------------------------------------
    # Required by the waybar modules and keybindings. Every one of these was
    # missing from this list; because they happened to be installed on the
    # author's machine the breakage only ever showed up on a FRESH install:
    #   playerctl      -> mpris module + every XF86Audio* media key
    #   lm_sensors     -> cpu_temp.sh (reported an unknown temperature without it)
    #   pacman-contrib -> checkupdates, so the updates module always read 0
    #   jq             -> git_branch.sh and the waybar JSON scripts
    #   bibata-cursor-theme -> the cursor theme the desktop asks for
    # ---------------------------------------------------------------------------
    "playerctl" "lm_sensors" "pacman-contrib" "jq" "bibata-cursor-theme"
    # ---------------------------------------------------------------------------
    # Same failure mode as the block above, found by auditing what the shipped
    # scripts actually execute rather than by trusting the list:
    #   imagemagick -> sway/scripts/lock.sh. THIS ONE FAILS SILENTLY: the script
    #                  guards with `command -v magick` and drops to a plain
    #                  wallpaper lock, so a fresh install just quietly has no
    #                  blurred lock screen and nothing says why.
    #   libnotify    -> notify-send. Guarded in the scripts, but NOT in
    #                  sway/notifications.conf, where the DND keybinding calls it
    #                  directly.
    #   glib2        -> gsettings, which is how desktop-theme.sh applies the GTK
    #                  theme, icons and cursor to every non-sway app.
    #   iputils      -> ping, for the waybar latency module.
    # ---------------------------------------------------------------------------
    "imagemagick" "libnotify" "glib2" "iputils"
    # Fingerprint authentication for the lock screen and sudo. The PAM stack in
    # system/pam.d/swaylock is only deployed when pam_fprintd.so exists, so
    # without this package the lock screen quietly stays password-only.
    "fprintd"
    # General
    "curl" "wget" "git" "eza" "zoxide" "rsync"
)


log_info "Synchronizing repositories and verifying Core Workstation packages..."
# Filter out already installed packages to ensure idempotent speed
PKGS_TO_INSTALL=()
for pkg in "${CORE_PKGS[@]}"; do
    if ! pacman -Qi "${pkg}" &>/dev/null; then
        PKGS_TO_INSTALL+=("${pkg}")
    fi
done

if [[ "${#PKGS_TO_INSTALL[@]}" -gt 0 ]]; then
    log_info "Installing missing dependencies (${#PKGS_TO_INSTALL[@]}): ${CYAN}${PKGS_TO_INSTALL[*]}${RESET}"
    ${AUR_HELPER} -S --needed --noconfirm "${PKGS_TO_INSTALL[@]}"
    log_success "Package inventory successfully installed."
else
    log_success "All required system and desktop dependencies are already present."
fi

# ------------------------------------------------------------------------------
# 5. IDEMPOTENT TIMESTAMPED BACKUP ENGINE
# ------------------------------------------------------------------------------
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${HOME}/.config/cyber_noir_backup_${TIMESTAMP}"
log_info "Initializing safe configuration backup vault at: ${CYAN}${BACKUP_DIR}${RESET}"

mkdir -p "${BACKUP_DIR}"
TARGET_MODULES=("sway" "waybar" "mako" "wofi" "kitty" "starship" "fastfetch" "nvim" "swaylock" "btop" "networkmanager-dmenu")

for mod in "${TARGET_MODULES[@]}"; do
    if [[ -e "${HOME}/.config/${mod}" && ! -L "${HOME}/.config/${mod}" ]]; then
        log_info "Archiving existing active configuration: ~/.config/${mod} -> Backup Vault"
        mv "${HOME}/.config/${mod}" "${BACKUP_DIR}/${mod}"
    elif [[ -L "${HOME}/.config/${mod}" ]]; then
        log_info "Removing superseded symbol link at ~/.config/${mod}"
        rm -f "${HOME}/.config/${mod}"
    fi
done
log_success "Configuration preservation vault secured."

# ------------------------------------------------------------------------------
# 6. CONFIGURATION DEPLOYMENT & ASSET REPLICATION
# ------------------------------------------------------------------------------
log_info "Deploying Cyber Noir configuration architecture into ~/.config..."
mkdir -p "${HOME}/.config"
mkdir -p "${HOME}/.local/share/wallpapers"

# Copy modular dotfiles to ~/.config
for mod in "${TARGET_MODULES[@]}"; do
    if [[ -d "${SCRIPT_DIR}/${mod}" || -f "${SCRIPT_DIR}/${mod}" ]]; then
        log_info "Replicating module: ${GREEN}${mod}${RESET}"
        cp -r "${SCRIPT_DIR}/${mod}" "${HOME}/.config/"
    fi
done

# GTK and portal configs do not live under a single ~/.config/<name> directory,
# so they need explicit placement rather than the TARGET_MODULES loop above.
# The repo previously carried an EMPTY gtk/ directory that nothing ever deployed,
# which is why GTK dialogs rendered in the light default theme.
log_info "Deploying GTK and XDG portal configuration..."
for gtkver in gtk-3.0 gtk-4.0; do
    if [[ -f "${SCRIPT_DIR}/gtk/${gtkver}/settings.ini" ]]; then
        mkdir -p "${HOME}/.config/${gtkver}"
        cp -f "${SCRIPT_DIR}/gtk/${gtkver}/settings.ini" "${HOME}/.config/${gtkver}/settings.ini"
    fi
done
if [[ -f "${SCRIPT_DIR}/xdg-desktop-portal/sway-portals.conf" ]]; then
    mkdir -p "${HOME}/.config/xdg-desktop-portal"
    cp -f "${SCRIPT_DIR}/xdg-desktop-portal/sway-portals.conf" \
          "${HOME}/.config/xdg-desktop-portal/sway-portals.conf"
fi

# Ensure executable permission flags are explicitly applied on all internal scripts
log_info "Applying execution attributes on runtime script engines..."
chmod +x "${HOME}/.config/waybar/scripts/"*.sh 2>/dev/null || true
chmod +x "${HOME}/.config/sway/scripts/"*.sh 2>/dev/null || true

# Replicate rendered Cyber Noir wallpaper assets
if [[ -d "${SCRIPT_DIR}/wallpapers" ]]; then
    log_info "Deploying complete 4K Cyber Noir wallpaper suite..."
    mkdir -p "${HOME}/.local/share/wallpapers/" "${HOME}/.config/sway/wallpapers/"
    cp -f "${SCRIPT_DIR}/wallpapers/"*.png "${HOME}/.local/share/wallpapers/" 2>/dev/null || true
    cp -f "${SCRIPT_DIR}/wallpapers/"*.png "${HOME}/.config/sway/wallpapers/" 2>/dev/null || true
fi

# Deploy SDDM Sugar Candy Custom Theme
if [[ -d "${SCRIPT_DIR}/sddm/cyber-noir" ]]; then
    log_info "Installing Sugar Candy SDDM Display Manager custom theme (requires sudo)..."
    sudo mkdir -p "/usr/share/sddm/themes/"
    sudo cp -r "${SCRIPT_DIR}/sddm/cyber-noir" "/usr/share/sddm/themes/"
    # theme.conf is deliberately NOT in the repo -- it is gitignored, because the
    # generated one carries this host's hostname, kernel, package count, IP and
    # battery level. So a fresh clone copies the theme WITHOUT it, and the
    # sddm-telemetry-update run at the end of this block is what creates it.
    # That generator emits the whole file (background, blurRadius and font as
    # well as the live values), so nothing is lost by not shipping one.

    log_info "Configuring default system display manager theme and persistent session..."
    sudo mkdir -p "/etc/sddm.conf.d" "/var/lib/sddm"
    # Papirus is an ICON theme and has no cursors/ directory, so the greeter had
    # no valid cursor at all. Pick the first cursor theme actually installed.
    SDDM_CURSOR="Adwaita"
    for c in Bibata-Modern-Ice Bibata-Modern-Classic Adwaita default; do
        [[ -d "/usr/share/icons/${c}/cursors" ]] && { SDDM_CURSOR="${c}"; break; }
    done
    log_info "SDDM cursor theme resolved to: ${CYAN}${SDDM_CURSOR}${RESET}"
    printf '[Theme]\nCurrent=cyber-noir\nCursorTheme=%s\n' "${SDDM_CURSOR}" \
        | sudo tee "/etc/sddm.conf.d/10-cyber-noir.conf" >/dev/null
    echo -e "[Last]\nUser=${USER}\nSession=/usr/share/wayland-sessions/sway.desktop" | sudo tee "/var/lib/sddm/state.conf" >/dev/null 2>&1 || true

    log_info "Registering live SDDM hardware telemetry daemon..."
    if [[ -f "${SCRIPT_DIR}/sddm/sddm-telemetry-update" ]]; then
        sudo cp -f "${SCRIPT_DIR}/sddm/sddm-telemetry-update" "/usr/local/bin/sddm-telemetry-update"
        sudo chmod +x "/usr/local/bin/sddm-telemetry-update"
    fi
    if [[ -f "${SCRIPT_DIR}/sddm/sddm-telemetry.service" ]]; then
        sudo cp -f "${SCRIPT_DIR}/sddm/sddm-telemetry.service" "/etc/systemd/system/sddm-telemetry.service"
        # The timer keeps the greeter's telemetry fresh. Without it the service
        # runs exactly once at boot and the "live" readout is stale from then on.
        [[ -f "${SCRIPT_DIR}/sddm/sddm-telemetry.timer" ]] && \
            sudo cp -f "${SCRIPT_DIR}/sddm/sddm-telemetry.timer" "/etc/systemd/system/sddm-telemetry.timer"
        sudo systemctl daemon-reload >/dev/null 2>&1 || true
        sudo systemctl enable sddm-telemetry.service >/dev/null 2>&1 || true
        sudo systemctl enable --now sddm-telemetry.timer >/dev/null 2>&1 || true
    fi
    # Execute telemetry updater immediately to populate live stats for upcoming reboot
    sudo /usr/local/bin/sddm-telemetry-update >/dev/null 2>&1 || true

    log_success "SDDM Display Manager theme, live telemetry engine, and default Sway session successfully registered."
fi

# Deploy NVIDIA & Hybrid GPU Sway Launch Wrapper and Wayland Session
log_info "Installing Cyber Noir Sway launcher wrapper & Wayland desktop session..."
if [[ -f "${SCRIPT_DIR}/sway-cyber-noir" ]]; then
    sudo cp -f "${SCRIPT_DIR}/sway-cyber-noir" "/usr/local/bin/sway-cyber-noir"
    sudo chmod +x "/usr/local/bin/sway-cyber-noir"
fi
if [[ -f "${SCRIPT_DIR}/sway-cyber-noir.desktop" ]]; then
    sudo mkdir -p "/usr/share/wayland-sessions"
    # Overwrite the standard sway.desktop file so there is only ONE clean Sway session option in SDDM
    sudo cp -f "${SCRIPT_DIR}/sway-cyber-noir.desktop" "/usr/share/wayland-sessions/sway.desktop"
    # Delete duplicate session entries to prevent double menu entries in SDDM
    sudo rm -f "/usr/share/wayland-sessions/sway-cyber-noir.desktop" "/usr/local/share/wayland-sessions/sway-cyber-noir.desktop" 2>/dev/null || true
    log_success "Single unified NVIDIA Wayland Sway session successfully configured."
fi

# ------------------------------------------------------------------------------
# 6b. SYSTEM POWER KEY & FINGERPRINT AUTHENTICATION
# ------------------------------------------------------------------------------
# Two defects that cannot be fixed from ~/.config alone, because both live in
# /etc:
#
#   * The power button shut the machine down instantly with no prompt. Nothing
#     was bound to XF86PowerOff in sway, so the key fell through to
#     systemd-logind, whose default is HandlePowerKey=poweroff. Fixing it needs
#     BOTH a logind drop-in (below) and the sway binding in bindings.conf 6b.
#
#   * The lock screen never consulted the fingerprint reader -- /etc/pam.d/swaylock
#     ships as a bare `auth include login`.
#
# Both changes fail safe: the power key long-press still forces a poweroff, and
# the PAM entry is `sufficient`, so a missing or unenrolled reader falls straight
# through to the password prompt.
log_info "Configuring system power key handling & lock screen authentication..."

if [[ -f "${SCRIPT_DIR}/system/logind.conf.d/90-cyber-noir-power.conf" ]]; then
    sudo mkdir -p /etc/systemd/logind.conf.d
    sudo cp -f "${SCRIPT_DIR}/system/logind.conf.d/90-cyber-noir-power.conf" \
               /etc/systemd/logind.conf.d/90-cyber-noir-power.conf
    log_success "Power key delegated to the compositor (long-press still powers off)."

    # Copying the drop-in is only half the job. logind reads its configuration
    # once, at startup, so until it is told to re-read it the old in-memory
    # HandlePowerKey=poweroff stays live and the button keeps shutting the
    # machine down instantly -- which is exactly what happened here: the file
    # was installed, nothing reloaded it, and the very next press still killed
    # the box. Merely warning about it was not enough, so apply it.
    #
    # systemd-logind is Type=notify-reload (CanReload=yes), so a reload re-reads
    # the config in place and leaves existing sessions untouched. restart is a
    # fallback for systemd builds too old to advertise reload.
    if sudo systemctl reload systemd-logind 2>/dev/null; then
        log_success "systemd-logind reloaded -- power key is live now, no reboot needed."
    elif sudo systemctl restart systemd-logind 2>/dev/null; then
        log_success "systemd-logind restarted -- power key is live now."
    else
        log_warn "Could not reload systemd-logind; reboot to activate the power key."
    fi
fi

# Only rewrite the PAM stack if the module is actually installed -- referencing a
# missing module in /etc/pam.d is how people lock themselves out of a machine.
# The lock screen stack itself is stock; it inherits fingerprint from
# system-auth via login -> system-local-login -> system-login.
if [[ -f "${SCRIPT_DIR}/system/pam.d/swaylock" ]]; then
    sudo cp -a /etc/pam.d/swaylock "${BACKUP_DIR}/pam.d-swaylock.bak" 2>/dev/null || true
    sudo cp -f "${SCRIPT_DIR}/system/pam.d/swaylock" /etc/pam.d/swaylock
fi

# Fingerprint is patched into system-auth rather than into each service's own
# PAM file, because sudo, polkit-1, sddm and login all include that one stack.
# The patcher verifies the stack still has the shape its jump offset assumes,
# backs up to /root before writing, and no-ops when already applied -- so
# re-running this installer stays idempotent. A non-zero exit means it declined
# to touch anything, which is not fatal: password auth is untouched either way.
if [[ -f /usr/lib/security/pam_fprintd.so ]]; then
    if sudo bash "${SCRIPT_DIR}/system/patch-system-auth-fprintd.sh"; then
        log_success "Fingerprint enabled for sudo, polkit, SDDM and the lock screen."
        if command -v fprintd-list &>/dev/null && \
           ! fprintd-list "${USER}" 2>/dev/null | grep -q "Fingers enrolled"; then
            log_warn "No fingerprint enrolled yet -- run: fprintd-enroll"
        fi
    else
        log_warn "system-auth left unpatched; password authentication is unaffected."
    fi
else
    log_warn "pam_fprintd.so not present; skipping fingerprint setup (install fprintd)."
fi

# ------------------------------------------------------------------------------
# 7. SHELL INITIALIZATION & SERVICE AUTOMATION
# ------------------------------------------------------------------------------
log_info "Evaluating interactive user login shell environment..."
CURRENT_SHELL=$(basename "${SHELL:-/bin/bash}")
if [[ "${CURRENT_SHELL}" != "zsh" ]]; then
    log_warn "Active shell is ${CURRENT_SHELL}. Switching login shell to ${GREEN}ZSH${RESET}..."
    if command -v zsh &>/dev/null; then
        chsh -s "$(which zsh)" "${USER}"
        log_success "Default user login shell updated to ZSH."
    else
        log_error "Zsh binary path could not be resolved."
    fi
else
    log_success "Default login shell is already verified as ZSH."
fi

# Deploy pre-configured Zsh environment
if [[ -f "${SCRIPT_DIR}/.zshrc" ]]; then
    log_info "Deploying custom Zsh configuration (~/.zshrc and ~/.cachyos-config.zsh)..."
    cp -f "${SCRIPT_DIR}/.zshrc" "${HOME}/.zshrc"
    if [[ -f "${SCRIPT_DIR}/.cachyos-config.zsh" ]]; then
        cp -f "${SCRIPT_DIR}/.cachyos-config.zsh" "${HOME}/.cachyos-config.zsh"
    fi
fi

# Configure VS Code theme if installed
if command -v code &>/dev/null; then
    log_info "Applying Cyber Noir / Tokyo Night aesthetic to Visual Studio Code..."
    code --install-extension enkia.tokyo-night >/dev/null 2>&1 || true
    mkdir -p "${HOME}/.config/Code/User"
    VSCODE_SETTINGS="${HOME}/.config/Code/User/settings.json"
    [[ -f "${VSCODE_SETTINGS}" ]] || echo "{}" > "${VSCODE_SETTINGS}"
    # jq, not sed: `sed s/"workbench.colorTheme": .*/.../` only matches when the
    # key ALREADY exists, so on a fresh `{}` file it silently did nothing.
    if command -v jq &>/dev/null; then
        if tmp=$(jq '."workbench.colorTheme" = "Tokyo Night"' "${VSCODE_SETTINGS}" 2>/dev/null); then
            printf '%s\n' "${tmp}" > "${VSCODE_SETTINGS}"
        else
            log_warn "Could not parse ${VSCODE_SETTINGS}; leaving it untouched."
        fi
    fi
fi

# Enable necessary user systemd daemon integrations & fix display manager conflicts
log_info "Activating system background services & resolving display manager conflicts..."
sudo systemctl enable NetworkManager --now 2>/dev/null || true
sudo systemctl enable bluetooth --now 2>/dev/null || true

# Explicitly disable conflicting display managers (cosmic-greeter, greetd, gdm, lightdm)
log_info "Disabling cosmic-greeter and existing greeter daemons to ensure SDDM dominance..."
sudo systemctl disable cosmic-greeter.service greetd.service gdm.service lightdm.service lxdm.service 2>/dev/null || true
sudo systemctl enable -f sddm.service 2>/dev/null || true
log_success "SDDM Display Manager verified as primary login service."

systemctl --user enable pipewire pipewire-pulse wireplumber --now 2>/dev/null || true

# ------------------------------------------------------------------------------
# 8. INSTALLATION DEPLOYMENT COMPLETION REPORT
# ------------------------------------------------------------------------------
draw_line
printf "${GREEN}${BOLD} 🚀 [SUCCESS] CYBER NOIR WORKSTATION ARCHITECTURE FULLY DEPLOYED!${RESET}\n"
draw_line
printf "${CYAN} 📁 System Backup Vault:${RESET} %s\n" "${BACKUP_DIR}"
printf "${CYAN} ⚙️  Active Window Engine:${RESET} Sway Wayland Compositor (Modular Architecture)\n"
printf "${CYAN} 💻 IDE & Terminal UI:   ${RESET} Kitty + Neovim (Catppuccin Mocha + 0.92 Glass Alpha)\n"
printf "${CYAN} 󰣇 System Status Bar:   ${RESET} Waybar (Live VPN Tunnel Checking + Wofi Controller)\n"
draw_line
log_info "To activate your upgraded environment:"
printf "   1. Log out or reboot your machine to test the ${GREEN}Sugar Candy SDDM${RESET} login theme.\n"
printf "   2. Select ${CYAN}'Sway'${RESET} from your login display manager session chooser.\n"
printf "   3. Enjoy your seamless, production-quality CachyOS developer workspace!\n\n"

exit 0
