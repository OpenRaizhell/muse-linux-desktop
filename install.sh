#!/usr/bin/env bash
# Install the muse-linux-desktop helpers.
# Run as your normal desktop user. Parts of it will ask for sudo.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== muse-linux-desktop installer ==="
echo

# --- who is the desktop user? ---
default_user="${SUDO_USER:-$USER}"
read -rp "Desktop username [$default_user]: " DESKTOP_USER
DESKTOP_USER="${DESKTOP_USER:-$default_user}"

if ! id "$DESKTOP_USER" >/dev/null 2>&1; then
  echo "error: user '$DESKTOP_USER' does not exist" >&2
  exit 1
fi

DESKTOP_UID="$(id -u "$DESKTOP_USER")"
DESKTOP_HOME="$(eval echo "~$DESKTOP_USER")"
echo "Using: user=$DESKTOP_USER uid=$DESKTOP_UID home=$DESKTOP_HOME"
echo

# --- staging area for templated scripts ---
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

template() {
  # $1 = source file, $2 = destination path (inside $stage)
  sed -e "s/@DESKTOP_USER@/$DESKTOP_USER/g" \
      -e "s/@DESKTOP_UID@/$DESKTOP_UID/g" \
      -e "s|@DESKTOP_HOME@|$DESKTOP_HOME|g" \
      "$1" > "$stage/$2"
}

template "$REPO_DIR/bin/muse"               "muse"
template "$REPO_DIR/bin/muse-morning-open"  "muse-morning-open"
template "$REPO_DIR/sbin/cosmic-wallpaper"  "cosmic-wallpaper"
template "$REPO_DIR/sbin/as-desktop"        "as-desktop"

# assistant username is chosen at install time too
default_assistant="candy"
read -rp "Assistant SSH username [$default_assistant]: " ASSISTANT_USER
ASSISTANT_USER="${ASSISTANT_USER:-$default_assistant}"
sed -e "s/@DESKTOP_USER@/$DESKTOP_USER/g" \
    -e "s/@DESKTOP_UID@/$DESKTOP_UID/g" \
    -e "s/@ASSISTANT_USER@/$ASSISTANT_USER/g" \
    "$REPO_DIR/sbin/assistant-desktop-access" > "$stage/assistant-desktop-access"
template "$REPO_DIR/lib/muse/desktop-env.sh" "desktop-env.sh"
cp "$REPO_DIR/lib/muse/apply-wallpaper" "$stage/apply-wallpaper"

# --- install user binaries ---
mkdir -p "$DESKTOP_HOME/.local/bin"
install -m 0755 "$stage/muse" "$stage/muse-morning-open" "$DESKTOP_HOME/.local/bin/"
echo "Installed: $DESKTOP_HOME/.local/bin/muse, muse-morning-open"

# --- install system helpers (needs sudo) ---
sudo install -m 0755 "$stage/cosmic-wallpaper" "$stage/as-desktop" \
  "$stage/assistant-desktop-access" /usr/local/bin/
sudo mkdir -p /usr/local/lib/muse
sudo install -m 0755 "$stage/apply-wallpaper" /usr/local/lib/muse/
sudo install -m 0644 "$stage/desktop-env.sh" /usr/local/lib/muse/
echo "Installed: /usr/local/bin/{cosmic-wallpaper,as-desktop,assistant-desktop-access}"
echo "Installed: /usr/local/lib/muse/{apply-wallpaper,desktop-env.sh}"

# --- morning crontab ---
echo
read -rp "Add the 10:00 AM auto-open to $DESKTOP_USER's crontab? [Y/n]: " answer
answer="${answer:-Y}"
if [[ "$answer" =~ ^[Yy]$ ]]; then
  cron_line="0 10 * * * $DESKTOP_HOME/.local/bin/muse-morning-open"
  if sudo -u "$DESKTOP_USER" crontab -l 2>/dev/null | grep -qF "muse-morning-open"; then
    echo "Crontab entry already present, skipping."
  else
    (sudo -u "$DESKTOP_USER" crontab -l 2>/dev/null; echo "$cron_line") | \
      sudo -u "$DESKTOP_USER" crontab -
    echo "Crontab entry added: $cron_line"
  fi
  echo "Make sure the cron service is running: sudo systemctl enable --now cron"
fi

echo
echo "Done. Next steps:"
echo "  1. Follow docs/assistant-ssh.md to create the '$ASSISTANT_USER' login."
echo "  2. Run: sudo /usr/local/bin/assistant-desktop-access"
echo "  3. Test: as-desktop echo hello-from-the-desktop"
