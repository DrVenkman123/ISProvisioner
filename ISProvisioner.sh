#!/usr/bin/env bash
set -euo pipefail

# --- Self-heal permissions (in case GitHub removed +x) ---
if [ ! -x "$0" ]; then
  echo "==> Fixing execute permissions for $(basename "$0")"
  chmod +x "$0" || {
    echo "Failed to chmod self; please run manually: chmod +x $0"
    exit 1
  }
fi

# === EDIT THESE FOR YOUR RELEASE ===
ZIP_URL="https://github.com/DrVenkman123/ISProvisioner/releases/download/v3.0.0-beta.1/ISProvisionerV3.zip"
APP_DIR="/opt/isp-provisioner"
SERVICE_NAME="isp-provisioner"   # optional systemd/pm2 name
SHA256=""                        # optional: paste expected sha256 to verify; leave blank to skip

# --- helpers ---
log(){ printf "\033[1;34m==>\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33mWARN:\033[0m %s\n" "$*"; }
die(){ printf "\033[1;31mERR:\033[0m %s\n" "$*" >&2; exit 1; }

# --- deps ---
log "Installing dependencies (curl, unzip, rsync)"
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y >/dev/null
  sudo apt-get install -y curl unzip rsync >/dev/null
elif command -v yum >/dev/null 2>&1; then
  sudo yum install -y curl unzip rsync >/dev/null
fi

# --- fetch zip ---
WORK="/tmp/isprov.$(date +%s)"
mkdir -p "$WORK"
ZIP_FILE="$WORK/pkg.zip"

log "Downloading package"
if command -v curl >/dev/null 2>&1; then
  curl -fL "$ZIP_URL" -o "$ZIP_FILE"
else
  wget -O "$ZIP_FILE" "$ZIP_URL"
fi

# --- optional checksum ---
if [ -n "$SHA256" ]; then
  echo "$SHA256  $ZIP_FILE" | sha256sum -c - || die "SHA256 mismatch"
fi

# --- stop service if present (systemd/pm2 best-effort) ---
if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
  log "Stopping systemd service: $SERVICE_NAME"
  sudo systemctl stop "$SERVICE_NAME" || true
elif command -v pm2 >/dev/null 2>&1 && pm2 list | grep -q "$SERVICE_NAME"; then
  log "Stopping PM2 process: $SERVICE_NAME"
  pm2 stop "$SERVICE_NAME" || true
fi

# --- backup current ---
if [ -d "$APP_DIR" ]; then
  BK="${APP_DIR}.bak-$(date +%F-%H%M%S)"
  log "Backing up existing install to $BK"
  sudo rsync -a --delete "$APP_DIR"/ "$BK"/
fi

# --- deploy ---
log "Unzipping to staging"
STAGE="$WORK/stage"
mkdir -p "$STAGE"
unzip -q "$ZIP_FILE" -d "$STAGE"

# If the zip contains a top-level folder, flatten it
TOP="$(find "$STAGE" -mindepth 1 -maxdepth 1 -type d | head -n1 || true)"
SRC="$STAGE"
[ -n "$TOP" ] && SRC="$TOP"

log "Syncing to $APP_DIR"
sudo mkdir -p "$APP_DIR"
sudo rsync -a "$SRC"/ "$APP_DIR"/

# --- permissions (non-root run at runtime is ideal; adjust as needed) ---
sudo chown -R "$USER":"$USER" "$APP_DIR" || true

# --- run install.sh if present ---
if [ -x "$APP_DIR/install.sh" ]; then
  log "Running install.sh"
  (cd "$APP_DIR" && bash ./install.sh)
elif [ -f "$APP_DIR/install.sh" ]; then
  log "Running install.sh (not executable)"
  (cd "$APP_DIR" && bash ./install.sh)
else
  warn "install.sh not found in $APP_DIR — skipping."
fi

# --- start service again ---
if systemctl list-unit-files | grep -q "^$SERVICE_NAME\.service"; then
  log "Starting systemd service: $SERVICE_NAME"
  sudo systemctl enable "$SERVICE_NAME" >/dev/null 2>&1 || true
  sudo systemctl start "$SERVICE_NAME" || true
elif command -v pm2 >/dev/null 2>&1 && pm2 list | grep -q "$SERVICE_NAME"; then
  log "Starting PM2 process: $SERVICE_NAME"
  pm2 start "$SERVICE_NAME" || true
fi

log "Done. Installed to $APP_DIR"
EOF
