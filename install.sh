#!/bin/bash
# Install omarchy-branding-text: the `omarchy branding text` plugin.
#
# Run as your normal user (not root); the installer calls sudo itself for the
# parts that touch /usr and /etc.

set -euo pipefail

SRC=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROG=omarchy-branding-text
HELPER=omarchy-branding-text-system
USER_NAME=$(id -un)
USER_HOME=$HOME

CONFIG_DIR=${XDG_CONFIG_HOME:-$USER_HOME/.config}/omarchy-branding-text
CONFIG_FILE=$CONFIG_DIR/config.conf
DATA_DIR=${XDG_DATA_HOME:-$USER_HOME/.local/share}/omarchy-branding-text
MENU_FILE=$USER_HOME/.config/omarchy/extensions/omarchy-menu.jsonc

QUICK=false
NO_APPLY=false

fail() {
  printf '\ninstall: %s\n' "$*" >&2
  exit 1
}

say() { printf '\n==> %s\n' "$*"; }
note() { printf '    %s\n' "$*"; }

while (( $# > 0 )); do
  case $1 in
  --quick) QUICK=true ;;
  --no-apply) NO_APPLY=true ;;
  --help | -h)
    cat <<'EOF'
Usage: bash install.sh [--quick] [--no-apply]

  --quick      Apply branding without rebuilding the initramfs
  --no-apply   Install only; run `omarchy branding text apply` yourself
EOF
    exit 0
    ;;
  *) fail "unknown option: $1" ;;
  esac
  shift
done

(( EUID != 0 )) || fail "run this as your normal user, not with sudo"
[[ $USER_NAME != root ]] || fail "run this as your normal user, not as root"

for command in magick omarchy-transcode-ascii python3 sudo limine-mkinitcpio gum; do
  command -v "$command" >/dev/null || fail "required command missing: $command"
done

for file in bin/$PROG system/$HELPER share/Main.qml share/menu.py share/menu-entries.jsonc \
  hooks/theme-set.d/50-omarchy-branding-text config/config.conf; do
  [[ -f $SRC/$file ]] || fail "missing installer file: $file"
done

bash -n "$SRC/bin/$PROG" || fail "CLI has a syntax error"
bash -n "$SRC/system/$HELPER" || fail "helper has a syntax error"
bash -n "$SRC/hooks/theme-set.d/50-omarchy-branding-text" || fail "hook has a syntax error"

if ! sudo -n true 2>/dev/null; then
  say "Sudo is needed to install the login screen, boot splash and boot menu"
  sudo -v || fail "sudo authorization failed"
fi

# ---------------------------------------------------------------- user files

say "Installing the command"
install -d -m 0755 "$USER_HOME/.local/bin"
install -m 0755 "$SRC/bin/$PROG" "$USER_HOME/.local/bin/$PROG"
note "$USER_HOME/.local/bin/$PROG"

say "Installing the configuration"
install -d -m 0755 "$CONFIG_DIR/themes"
if [[ -f $CONFIG_FILE ]]; then
  note "keeping existing $CONFIG_FILE"
  # Add keys introduced after the first install, without touching any value.
  for key in IMAGE IMAGE_TINT ART_THRESHOLD; do
    if ! grep -q "^[[:space:]]*$key=" "$CONFIG_FILE"; then
      case $key in
      IMAGE) printf '\n# Image wordmark (png, svg, jpg, webp); empty uses TEXT.\nIMAGE=""\n' >>"$CONFIG_FILE" ;;
      IMAGE_TINT) printf '# Recolour IMAGE with the accent.\nIMAGE_TINT="false"\n' >>"$CONFIG_FILE" ;;
      ART_THRESHOLD) printf '# Brightness cut-off (percent) for image art.\nART_THRESHOLD=50\n' >>"$CONFIG_FILE" ;;
      esac
      note "added $key to the configuration"
    fi
  done
else
  install -m 0644 "$SRC/config/config.conf" "$CONFIG_FILE"
  note "$CONFIG_FILE"
fi

say "Installing the theme-set hook"
install -d -m 0755 "$USER_HOME/.config/omarchy/hooks/theme-set.d"
install -m 0755 "$SRC/hooks/theme-set.d/50-omarchy-branding-text" \
  "$USER_HOME/.config/omarchy/hooks/theme-set.d/50-omarchy-branding-text"
note "repaints the login screen and boot menu when the theme changes"

# ---------------------------------------------------------------- /usr files

say "Installing the root helper"
sudo install -d -m 0755 /usr/local/share/omarchy-branding-text
sudo install -m 0644 -o root -g root "$SRC/share/Main.qml" \
  /usr/local/share/omarchy-branding-text/Main.qml
sudo install -m 0755 -o root -g root "$SRC/system/$HELPER" "/usr/local/sbin/$HELPER"
note "/usr/local/sbin/$HELPER"

say "Granting passwordless sudo for that helper only"
suder_tmp=$(mktemp)
trap 'rm -f "$suder_tmp"' EXIT
printf '%s ALL=(root) NOPASSWD: /usr/local/sbin/%s\n' "$USER_NAME" "$HELPER" >"$suder_tmp"
sudo install -m 0440 -o root -g root "$suder_tmp" /etc/sudoers.d/omarchy-branding-text
sudo visudo -cf /etc/sudoers.d/omarchy-branding-text >/dev/null || fail "sudoers rule did not validate"
note "/etc/sudoers.d/omarchy-branding-text"

say "Registering the command with the omarchy CLI"
if [[ -e /usr/share/omarchy/bin/$PROG && ! -L /usr/share/omarchy/bin/$PROG ]]; then
  note "/usr/share/omarchy/bin/$PROG already exists; leaving it alone"
else
  sudo ln -sfn "$USER_HOME/.local/bin/$PROG" "/usr/share/omarchy/bin/$PROG"
  note "omarchy branding text"
fi

# ---------------------------------------------------------------- menu

say "Adding the Appearance > Branding menu"
install -d -m 0755 "$(dirname "$MENU_FILE")"
python3 "$SRC/share/menu.py" add "$MENU_FILE" "$SRC/share/menu-entries.jsonc" ||
  fail "could not update $MENU_FILE"
note "$MENU_FILE"

# ---------------------------------------------------------------- apply

if $NO_APPLY; then
  say "Skipping the first apply"
  note "run: omarchy branding text apply"
  exit 0
fi

say "Applying the branding"
apply_args=()
$QUICK && apply_args+=(--no-rebuild)
"$USER_HOME/.local/bin/$PROG" apply "${apply_args[@]}"

say "Installed"
note "omarchy branding text status"
note "omarchy branding text preview"
note "uninstall: bash $SRC/uninstall.sh"
