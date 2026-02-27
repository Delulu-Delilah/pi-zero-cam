#!/usr/bin/env bash
# ============================================================================
#  Pi Zero Cam — Uninstaller
#  Cleanly removes everything installed by install.sh
# ============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; BOLD='\033[1m'
DIM='\033[2m'; RESET='\033[0m'

info()  { echo -e "  ${CYAN}${BOLD}ℹ${RESET}  $*"; }
ok()    { echo -e "  ${GREEN}✅${RESET}  $*"; }
warn()  { echo -e "  ${YELLOW}⚠️${RESET}  $*"; }

echo ""
echo -e "${MAGENTA}${BOLD}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║       🗑️  Pi Zero Cam — Uninstaller              ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${RESET}"

if [[ $EUID -ne 0 ]]; then
    echo -e "  ${RED}❌${RESET}  Must be run as root.  Try: ${BOLD}sudo ./uninstall.sh${RESET}"
    exit 1
fi

echo -e "  This will remove Pi Zero Cam and restore your boot configuration."
echo ""
read -rp "  Are you sure? [y/N] " yn
[[ "$yn" =~ ^[Yy]$ ]] || { echo "  Aborted."; exit 0; }
echo ""

# ── Stop and disable service ───────────────────────────────────────────────
info "Stopping webcam service..."
systemctl stop piwebcam.service 2>/dev/null || true
systemctl disable piwebcam.service 2>/dev/null || true
ok "Service stopped and disabled"

# ── Remove installed files ─────────────────────────────────────────────────
info "Removing installed files..."
rm -f /usr/local/bin/piwebcam
rm -f /usr/local/bin/uvc-gadget
rm -f /etc/systemd/system/piwebcam.service
systemctl daemon-reload 2>/dev/null || true
ok "Binaries and service file removed"

# ── Restore boot config ───────────────────────────────────────────────────
info "Restoring boot configuration..."

if [[ -f /boot/firmware/config.txt ]]; then
    BOOT_DIR="/boot/firmware"
else
    BOOT_DIR="/boot"
fi

CONFIG_TXT="${BOOT_DIR}/config.txt"
CMDLINE_TXT="${BOOT_DIR}/cmdline.txt"

# Remove our additions from config.txt
if [[ -f "$CONFIG_TXT" ]]; then
    sed -i '/^dtoverlay=dwc2$/d' "$CONFIG_TXT"
    ok "Removed dtoverlay=dwc2 from config.txt"
fi

# Remove modules-load from cmdline.txt
if [[ -f "$CMDLINE_TXT" ]]; then
    sed -i 's/ modules-load=dwc2,libcomposite//' "$CMDLINE_TXT"
    ok "Removed modules-load from cmdline.txt"
fi

# ── Optional: remove uvc-gadget source ─────────────────────────────────────
if [[ -d /opt/uvc-gadget ]]; then
    echo ""
    read -rp "  Remove uvc-gadget source code from /opt/uvc-gadget? [y/N] " yn
    if [[ "$yn" =~ ^[Yy]$ ]]; then
        rm -rf /opt/uvc-gadget
        ok "Source code removed"
    else
        info "Source code kept at /opt/uvc-gadget"
    fi
fi

# ── Done ────────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
echo -e "  ${GREEN}${BOLD}║       ✅ Pi Zero Cam uninstalled successfully    ║${RESET}"
echo -e "  ${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
echo ""
info "Reboot to fully restore your system: ${BOLD}sudo reboot${RESET}${DIM}${RESET}"
echo ""
