#!/bin/bash
# Remove omarchy-branding-text and restore the stock Omarchy branding.

set -euo pipefail

SRC=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROG=omarchy-branding-text
HELPER=omarchy-branding-text-system
USER_NAME=$(id -un)
USER_HOME=$HOME

CONFIG_DIR=${XDG_CONFIG_HOME:-$USER_HOME/.config}/omarchy-branding-text
STATE_DIR=${XDG_STATE_HOME:-$USER_HOME/.local/state}/omarchy-branding-text
MENU_FILE=$USER_HOME/.config/omarchy/extensions/omarchy-menu.jsonc

PURGE=false
KEEP_BRANDING=false

fail() {
  printf '\nuninstall: %s\n' "$*" >&2
  exit 1
}
say() { printf '\n==> %s\n' "$*"; }
note() { printf '    %s\n' "$*"; }

while (( $# > 0 )); do
  case $1 in
  --purge) PURGE=true ;;
  --keep-branding) KEEP_BRANDING=true ;;
  --help | -h)
    cat <<'EOF'
Usage: bash uninstall.sh [--purge] [--keep-branding]

  --purge          Also delete the configuration and per-theme overrides
  --keep-branding  Remove the tool only; leave the installed branding in place
EOF
    exit 0
    ;;
  *) fail "unknown option: $1" ;;
  esac
  shift
done

(( EUID != 0 )) || fail "run this as your normal user, not with sudo"

if ! sudo -n true 2>/dev/null; then
  say "Sudo is needed to restore the login screen and boot splash"
  sudo -v || fail "sudo authorization failed"
fi

if ! $KEEP_BRANDING; then
  if [[ -x $USER_HOME/.local/bin/$PROG ]]; then
    say "Restoring the stock branding"
    "$USER_HOME/.local/bin/$PROG" reset || note "reset reported a problem; continuing"
  elif [[ -x /usr/local/sbin/$HELPER ]]; then
    say "Restoring the stock branding"
    sudo -n "/usr/local/sbin/$HELPER" reset || note "reset reported a problem; continuing"
  fi
fi

say "Removing the menu entries"
if [[ -f $MENU_FILE ]]; then
  python3 "$SRC/share/menu.py" remove "$MENU_FILE" || note "could not update $MENU_FILE"
fi

say "Removing the command, helper and hook"
sudo rm -f "/usr/local/sbin/$HELPER"
sudo rm -f /etc/sudoers.d/omarchy-branding-text
sudo rm -rf /usr/local/share/omarchy-branding-text
if [[ -L /usr/share/omarchy/bin/$PROG ]]; then
  sudo rm -f "/usr/share/omarchy/bin/$PROG"
fi
rm -f "$USER_HOME/.local/bin/$PROG"
rm -f "$USER_HOME/.config/omarchy/hooks/theme-set.d/50-omarchy-branding-text"
rm -rf "$STATE_DIR"

if $PURGE; then
  say "Removing the configuration"
  rm -rf "$CONFIG_DIR"
else
  note "kept $CONFIG_DIR (use --purge to delete it)"
fi

say "Uninstalled"
note "backups left behind: /boot/limine.conf.bak.omarchy-branding"
note "                     /etc/plymouth/plymouthd.conf.bak.omarchy-branding"
note "                     ~/.config/omarchy/branding/*.bak.omarchy-branding"
