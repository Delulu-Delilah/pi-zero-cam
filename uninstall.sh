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

echo -e "  This will remove the Pi Zero IP Camera service and binaries."
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
rm -f /usr/local/bin/mediamtx
rm -f /etc/systemd/system/piwebcam.service
systemctl daemon-reload 2>/dev/null || true
ok "Binaries and service file removed"

# ── Done ────────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
echo -e "  ${GREEN}${BOLD}║       ✅ Pi Zero Cam uninstalled successfully    ║${RESET}"
echo -e "  ${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
echo ""
info "Uninstallation complete!"
echo ""
