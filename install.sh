#!/usr/bin/env bash
# ============================================================================
#  Pi Zero Cam — Automated USB Webcam Installer
#  https://github.com/Delulu-Delilah/pi-zero-cam
#
#  Turns a Raspberry Pi Zero into a plug-and-play USB webcam.
#  Run:  sudo ./install.sh
# ============================================================================
set -euo pipefail

# ── Colours & helpers ───────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; BOLD='\033[1m'
DIM='\033[2m'; RESET='\033[0m'

ICON_OK="✅"; ICON_WARN="⚠️ "; ICON_FAIL="❌"; ICON_CAM="📷"; ICON_GEAR="⚙️ "
ICON_ROCKET="🚀"; ICON_PLUG="🔌"; ICON_PI="🍓"

banner() {
    echo ""
    echo -e "${MAGENTA}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════╗"
    echo "  ║        ${ICON_CAM}  Pi Zero Cam — USB Webcam Setup        ║"
    echo "  ╚══════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

info()  { echo -e "  ${CYAN}${BOLD}ℹ${RESET}  $*"; }
ok()    { echo -e "  ${GREEN}${ICON_OK}${RESET}  $*"; }
warn()  { echo -e "  ${YELLOW}${ICON_WARN}${RESET} $*"; }
fail()  { echo -e "  ${RED}${ICON_FAIL}${RESET}  $*"; }
step()  { echo -e "\n  ${MAGENTA}${BOLD}━━━ $* ━━━${RESET}"; }
bullet(){ echo -e "     ${DIM}•${RESET} $*"; }

die() { fail "$*"; echo ""; exit 1; }

spin() {
    local pid=$1 msg=$2
    local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while kill -0 "$pid" 2>/dev/null; do
        for (( i=0; i<${#chars}; i++ )); do
            printf "\r  ${CYAN}%s${RESET}  %s" "${chars:$i:1}" "$msg"
            sleep 0.08
        done
    done
    printf "\r"
}

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && { DRY_RUN=true; warn "DRY-RUN mode — no changes will be made."; }

REPO_RAW="https://raw.githubusercontent.com/Delulu-Delilah/pi-zero-cam/main"

run_or_dry() {
    if $DRY_RUN; then
        bullet "${DIM}(dry-run) $*${RESET}"
    else
        "$@"
    fi
}

# ── Pre-flight ──────────────────────────────────────────────────────────────
banner

step "${ICON_GEAR} Pre-flight checks"

# Root check
if [[ $EUID -ne 0 ]] && ! $DRY_RUN; then
    die "This script must be run as root.  Try:  ${BOLD}sudo ./install.sh${RESET}"
fi
ok "Running as root"

# ── Detect Pi model ────────────────────────────────────────────────────────
step "${ICON_PI} Detecting Raspberry Pi model"

detect_pi_model() {
    if [[ ! -f /proc/cpuinfo ]]; then
        echo "unknown"
        return
    fi

    local revision
    revision=$(awk '/^Revision/ {print $3}' /proc/cpuinfo | sed 's/^1000//')

    local model="unknown"
    case "$revision" in
        # Pi Zero (original)
        900092|900093|920093)
            model="Pi Zero"
            ;;
        # Pi Zero W
        9000c1)
            model="Pi Zero W"
            ;;
        # Pi Zero 2 W
        902120)
            model="Pi Zero 2 W"
            ;;
        *)
            # Fallback: check model name string
            if grep -qi "Pi Zero 2" /proc/device-tree/model 2>/dev/null; then
                model="Pi Zero 2 W"
            elif grep -qi "Pi Zero W" /proc/device-tree/model 2>/dev/null; then
                model="Pi Zero W"
            elif grep -qi "Pi Zero" /proc/device-tree/model 2>/dev/null; then
                model="Pi Zero"
            elif grep -qi "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
                model=$(tr -d '\0' < /proc/device-tree/model)
            fi
            ;;
    esac
    echo "$model"
}

PI_MODEL=$(detect_pi_model)

if [[ "$PI_MODEL" == "unknown" ]]; then
    if $DRY_RUN; then
        warn "Cannot detect Pi model (not running on a Pi?). Continuing in dry-run."
        PI_MODEL="Pi Zero W (assumed — dry-run)"
    else
        die "This does not appear to be a Raspberry Pi. Aborting."
    fi
fi

ok "Detected: ${BOLD}${PI_MODEL}${RESET}"

# Warn if not a Zero variant
case "$PI_MODEL" in
    *"Zero"*)
        ;;
    *)
        warn "This script is designed for Pi Zero models."
        warn "Detected ${BOLD}${PI_MODEL}${RESET} — USB gadget mode may not work."
        read -rp "  Continue anyway? [y/N] " yn
        [[ "$yn" =~ ^[Yy]$ ]] || die "Aborted by user."
        ;;
esac

# ── Detect camera ──────────────────────────────────────────────────────────
step "${ICON_CAM} Detecting camera"

CAMERA_DETECTED=false
CAMERA_INFO=""

detect_camera() {
    # Method 1: libcamera (modern stack — Bullseye+)
    if command -v libcamera-hello &>/dev/null; then
        info "Probing via libcamera..."
        local lc_output
        if lc_output=$(libcamera-hello --list-cameras 2>&1); then
            if echo "$lc_output" | grep -q "Available cameras"; then
                local cam_count
                cam_count=$(echo "$lc_output" | grep -c "^[0-9]" || true)
                if [[ "$cam_count" -gt 0 ]]; then
                    CAMERA_DETECTED=true
                    CAMERA_INFO=$(echo "$lc_output" | grep "^[0-9]" | head -1)
                    ok "libcamera found camera: ${BOLD}${CAMERA_INFO}${RESET}"
                fi
            fi
        fi
    fi

    # Method 2: V4L2 devices
    if [[ "$CAMERA_DETECTED" == false ]]; then
        info "Probing V4L2 devices..."
        local v4l_devs
        v4l_devs=$(ls /dev/video* 2>/dev/null || true)
        if [[ -n "$v4l_devs" ]]; then
            for dev in $v4l_devs; do
                if v4l2-ctl --device="$dev" --all 2>/dev/null | grep -qi "capture"; then
                    CAMERA_DETECTED=true
                    CAMERA_INFO=$(v4l2-ctl --device="$dev" -D 2>/dev/null | grep "Card" | sed 's/.*: //' || echo "$dev")
                    ok "V4L2 camera found: ${BOLD}${CAMERA_INFO}${RESET} on ${dev}"
                    break
                fi
            done
        fi
    fi

    # Method 3: Check if CSI camera is physically connected (vcgencmd)
    if [[ "$CAMERA_DETECTED" == false ]] && command -v vcgencmd &>/dev/null; then
        info "Probing via vcgencmd..."
        if vcgencmd get_camera 2>/dev/null | grep -q "detected=1"; then
            CAMERA_DETECTED=true
            CAMERA_INFO="CSI Camera (legacy detected)"
            ok "Legacy CSI camera detected"
        fi
    fi

    # Method 4: Check device tree for camera
    if [[ "$CAMERA_DETECTED" == false ]]; then
        if [[ -d /proc/device-tree/soc/i2c@7e205000 ]] || \
           [[ -d /proc/device-tree/soc/i2c0mux/i2c@1 ]]; then
            info "CSI bus found but no camera detected yet."
            info "Camera may need a reboot to be detected after boot config changes."
        fi
    fi
}

if $DRY_RUN; then
    warn "Camera detection skipped in dry-run mode."
    CAMERA_DETECTED=true
    CAMERA_INFO="(dry-run — skipped)"
else
    detect_camera
fi

if [[ "$CAMERA_DETECTED" == false ]]; then
    warn "No camera detected right now."
    warn "Make sure a camera is connected, then reboot after install."
    echo ""
    read -rp "  Continue installation anyway? [Y/n] " yn
    [[ "$yn" =~ ^[Nn]$ ]] && die "Aborted by user."
fi

# ── Install dependencies ───────────────────────────────────────────────────
step "${ICON_GEAR} Installing dependencies"

install_deps() {
    info "Updating package lists..."
    apt-get update -qq &>/dev/null &
    spin $! "Updating package lists..."
    ok "Package lists updated"

    local pkgs=(
        git
        build-essential
        cmake
        pkg-config
        v4l-utils
        libjpeg-dev
        libudev-dev
    )

    # Add libcamera tools if available in repos
    if apt-cache show libcamera-tools &>/dev/null 2>&1; then
        pkgs+=(libcamera-tools)
    fi

    info "Installing packages: ${pkgs[*]}"
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${pkgs[@]}" &>/dev/null &
    spin $! "Installing packages..."
    ok "All dependencies installed"
}

run_or_dry install_deps

# ── Patch boot configuration ───────────────────────────────────────────────
step "${ICON_GEAR} Configuring boot settings"

# Determine boot config path (Bookworm uses /boot/firmware/, older uses /boot/)
if [[ -f /boot/firmware/config.txt ]]; then
    BOOT_DIR="/boot/firmware"
else
    BOOT_DIR="/boot"
fi

CONFIG_TXT="${BOOT_DIR}/config.txt"
CMDLINE_TXT="${BOOT_DIR}/cmdline.txt"

info "Boot config directory: ${BOLD}${BOOT_DIR}${RESET}"

patch_config() {
    # ── config.txt ──
    # Enable dwc2 overlay for USB gadget mode (peripheral mode required)
    # Remove any existing dwc2 overlay lines (they might be under [cm5] or have host mode)
    sed -i '/^dtoverlay=dwc2/d' "$CONFIG_TXT"
    # Append to the end of the file under an explicit [all] block
    echo "" >> "$CONFIG_TXT"
    echo "[all]" >> "$CONFIG_TXT"
    echo "dtoverlay=dwc2,dr_mode=peripheral" >> "$CONFIG_TXT"
    ok "Added dtoverlay=dwc2,dr_mode=peripheral to config.txt"

    # Enable automatic camera detection
    if ! grep -q "^camera_auto_detect=1" "$CONFIG_TXT" 2>/dev/null; then
        # Remove any existing camera_auto_detect line
        sed -i '/^camera_auto_detect=/d' "$CONFIG_TXT"
        echo "camera_auto_detect=1" >> "$CONFIG_TXT"
        ok "Enabled camera_auto_detect=1"
    else
        ok "camera_auto_detect=1 already present"
    fi

    # Enable legacy camera support as fallback
    if ! grep -q "^start_x=1" "$CONFIG_TXT" 2>/dev/null; then
        sed -i '/^start_x=/d' "$CONFIG_TXT"
        echo "start_x=1" >> "$CONFIG_TXT"
        ok "Enabled start_x=1 (legacy camera fallback)"
    else
        ok "start_x=1 already present"
    fi

    # Allocate GPU memory for camera
    if ! grep -q "^gpu_mem=" "$CONFIG_TXT" 2>/dev/null; then
        echo "gpu_mem=128" >> "$CONFIG_TXT"
        ok "Set gpu_mem=128"
    else
        ok "gpu_mem already configured"
    fi

    # ── cmdline.txt ──
    if ! grep -q "modules-load=dwc2,libcomposite" "$CMDLINE_TXT" 2>/dev/null; then
        # Append to the single line (cmdline.txt is one line)
        sed -i 's/$/ modules-load=dwc2,libcomposite/' "$CMDLINE_TXT"
        ok "Added modules-load=dwc2,libcomposite to cmdline.txt"
    else
        ok "modules-load already present in cmdline.txt"
    fi

    # Load modules now (if not already loaded)
    modprobe dwc2 2>/dev/null || true
    modprobe libcomposite 2>/dev/null || true
}

run_or_dry patch_config

# ── Build uvc-gadget ────────────────────────────────────────────────────────
step "${ICON_GEAR} Building uvc-gadget"

UVC_SRC="/opt/uvc-gadget"

build_uvc_gadget() {
    if [[ -f /usr/local/bin/uvc-gadget ]]; then
        ok "uvc-gadget binary already exists — skipping build"
        return 0
    fi

    if [[ -d "$UVC_SRC" ]]; then
        info "Source directory exists. Pulling latest..."
        cd "$UVC_SRC" && git pull --quiet
    else
        info "Cloning uvc-gadget..."
        git clone --quiet https://github.com/climberhunt/uvc-gadget.git "$UVC_SRC"
    fi

    cd "$UVC_SRC"
    info "Compiling..."
    make clean &>/dev/null 2>&1 || true
    make -j"$(nproc)" &>/dev/null &
    spin $! "Compiling uvc-gadget..."

    cp uvc-gadget /usr/local/bin/uvc-gadget
    chmod +x /usr/local/bin/uvc-gadget
    ok "uvc-gadget installed to /usr/local/bin/"
}

run_or_dry build_uvc_gadget

# ── Install piwebcam launcher ──────────────────────────────────────────────
step "${ICON_PLUG} Installing piwebcam launcher"

# Detect whether we were run from a local clone or piped from curl
if [[ -n "${BASH_SOURCE[0]:-}" ]] && [[ -f "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR=""  # running via curl pipe — will download files
fi

install_launcher() {
    if [[ -n "$SCRIPT_DIR" ]] && [[ -f "${SCRIPT_DIR}/piwebcam" ]]; then
        cp "${SCRIPT_DIR}/piwebcam" /usr/local/bin/piwebcam
    else
        info "Downloading piwebcam launcher from GitHub..."
        curl -sSL "$REPO_RAW/piwebcam" -o /usr/local/bin/piwebcam
    fi
    chmod +x /usr/local/bin/piwebcam
    ok "piwebcam installed to /usr/local/bin/"
}

run_or_dry install_launcher

# ── Install systemd service ────────────────────────────────────────────────
step "${ICON_GEAR} Setting up systemd service"

install_service() {
    if [[ -n "$SCRIPT_DIR" ]] && [[ -f "${SCRIPT_DIR}/piwebcam.service" ]]; then
        cp "${SCRIPT_DIR}/piwebcam.service" /etc/systemd/system/piwebcam.service
    else
        info "Downloading piwebcam.service from GitHub..."
        curl -sSL "$REPO_RAW/piwebcam.service" -o /etc/systemd/system/piwebcam.service
    fi
    systemctl daemon-reload
    systemctl enable piwebcam.service
    ok "piwebcam.service enabled (starts on boot)"
}

run_or_dry install_service

# ── Done! ───────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
echo -e "  ${GREEN}${BOLD}║       ${ICON_ROCKET} Installation Complete!                  ║${RESET}"
echo -e "  ${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
echo ""

info "${BOLD}Hardware detected:${RESET}"
bullet "Pi model : ${PI_MODEL}"
bullet "Camera   : ${CAMERA_INFO:-not detected yet}"
echo ""

info "${BOLD}What was installed:${RESET}"
bullet "/usr/local/bin/uvc-gadget   — UVC gadget binary"
bullet "/usr/local/bin/piwebcam     — Launcher script"
bullet "/etc/systemd/system/piwebcam.service"
echo ""

info "${BOLD}Next steps:${RESET}"
echo -e "     ${YELLOW}1.${RESET} Reboot the Pi:  ${BOLD}sudo reboot${RESET}"
echo -e "     ${YELLOW}2.${RESET} Connect the ${BOLD}data${RESET} micro-USB port to your computer"
echo -e "     ${YELLOW}3.${RESET} Open any camera app — your Pi is now a webcam! ${ICON_CAM}"
echo ""
echo -e "  ${DIM}To uninstall:  sudo ./uninstall.sh${RESET}"
echo -e "  ${DIM}Service log:   journalctl -u piwebcam -f${RESET}"
echo ""