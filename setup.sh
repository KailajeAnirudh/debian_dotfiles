#!/usr/bin/env bash
# ============================================================================
#  debian_dotfiles :: setup.sh
#  Target: Debian 13 (trixie), i3 desktop
#  Idempotent — safe to re-run. Installs packages, third-party repos,
#  flatpaks, and deploys dotfiles.
# ============================================================================
set -euo pipefail

# ---- helpers ---------------------------------------------------------------
BUILDDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_NAME="$(id -un 1000)"
USER_HOME="/home/${USER_NAME}"
log()  { printf '\n\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[skip]\033[0m %s\n' "$*"; }

# Use nala if present, else apt. First run bootstraps nala.
PKG() { if command -v nala >/dev/null 2>&1; then sudo nala "$@"; else sudo apt-get "$@"; fi; }

# ---- 0. base + nala --------------------------------------------------------
log "Base update + nala"
sudo apt-get update
sudo apt-get install -y nala ca-certificates curl wget gpg apt-transport-https \
                        software-properties-common
sudo nala update

# ============================================================================
#  1. Third-party APT repositories (guarded — added only once)
# ============================================================================
add_repo() {  # add_repo <name> <list-file-content> ; key handled separately
  local name="$1" content="$2"
  local list="/etc/apt/sources.list.d/${name}.list"
  if [ ! -f "$list" ]; then
    echo "$content" | sudo tee "$list" >/dev/null
    log "Added repo: $name"
  else
    warn "repo $name already present"
  fi
}

# Brave
if [ ! -f /usr/share/keyrings/brave-browser-archive-keyring.gpg ]; then
  sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
fi
add_repo brave-browser-release \
  "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"

# VS Code (Microsoft repo)
if [ ! -f /usr/share/keyrings/microsoft.gpg ]; then
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
fi
add_repo vscode \
  "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main"

# Claude Desktop
if [ ! -f /usr/share/keyrings/claude-desktop-archive-keyring.asc ]; then
  sudo curl -fsSLo /usr/share/keyrings/claude-desktop-archive-keyring.asc \
    https://downloads.claude.ai/claude-desktop/key.asc
fi
add_repo claude-desktop \
  "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main"

# Tailscale (trixie)
if [ ! -f /usr/share/keyrings/tailscale-archive-keyring.gpg ]; then
  curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.noarmor.gpg \
    | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
fi
add_repo tailscale \
  "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/debian trixie main"

sudo nala update

# ============================================================================
#  2. APT packages
# ============================================================================
log "i3 desktop + window-manager dependencies"
# NOTE: pulseaudio-utils(pactl), light, network-manager-gnome(nm-applet),
# rofi, maim were referenced by the i3 config but never installed before.
PKG install -y \
  i3 i3blocks picom feh rofi dmenu i3lock dex alacritty \
  pulseaudio-utils light network-manager-gnome maim slop imagemagick libnotify-bin \
  xclip xdotool blueman arandr pavucontrol fonts-font-awesome

log "CLI + system tools"
PKG install -y fzf unzip htop fastfetch flatpak filelight \
  gnome-software-plugin-flatpak plasma-discover-backend-flatpak

log "GUI applications"
# kicad now from Debian repos (the old Ubuntu PPA does not work on Debian)
PKG install -y vlc gimp darktable simplescreenrecorder gedit \
  gnome-clocks gnome-calendar nautilus kicad

log "Editors + services (VS Code, Claude Desktop, Tailscale, Brave)"
PKG install -y code claude-desktop tailscale brave-browser

# rquickshare — install bundled .deb if present
RQ_DEB="$(ls -1 "$BUILDDIR"/r-quick-share_*_amd64.deb 2>/dev/null | head -n1 || true)"
if [ -n "$RQ_DEB" ]; then
  log "Installing rquickshare from $RQ_DEB"
  PKG install -y "$RQ_DEB"
else
  warn "no r-quick-share .deb in repo"
fi

# ============================================================================
#  3. Flatpak apps
# ============================================================================
log "Flathub + flatpak apps"
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
for app in \
  com.discordapp.Discord \
  com.slack.Slack \
  com.tencent.WeChat \
  com.logseq.Logseq \
  com.obsproject.Studio \
  com.github.eneshecan.WhatsAppForLinux ; do
  sudo flatpak install -y flathub "$app"
done

# CLI launcher stubs (so `discord`, `slack`, `wechat`, `whatsapp-for-linux` work)
sudo install -m755 "$BUILDDIR/discord" /usr/local/bin/discord
sudo install -m755 "$BUILDDIR/slack"   /usr/local/bin/slack
sudo install -m755 "$BUILDDIR/wechat"  /usr/local/bin/wechat
printf '#!/usr/bin/bash\nflatpak run com.github.eneshecan.WhatsAppForLinux "$@"\n' \
  | sudo tee /usr/local/bin/whatsapp-for-linux >/dev/null
sudo chmod 755 /usr/local/bin/whatsapp-for-linux

# ============================================================================
#  4. Deploy dotfiles
# ============================================================================
log "Deploying config files"
mkdir -p "$USER_HOME/.config" "$USER_HOME/.tmux" "$USER_HOME/.screenlayout"
cp -R "$BUILDDIR"/.config/*      "$USER_HOME/.config/"
cp -R "$BUILDDIR"/.tmux/*        "$USER_HOME/.tmux/"
cp -R "$BUILDDIR"/.screenlayout/* "$USER_HOME/.screenlayout/"

# Personal scripts -> ~/.local/bin (e.g. screenshot-region.sh, bound in i3)
if compgen -G "$BUILDDIR/.local/bin/*" >/dev/null; then
  mkdir -p "$USER_HOME/.local/bin"
  cp -R "$BUILDDIR"/.local/bin/. "$USER_HOME/.local/bin/"
  chmod +x "$USER_HOME"/.local/bin/*.sh 2>/dev/null || true
else
  warn ".local/bin empty — add screenshot-region.sh so the \$mod+Shift+s bind works"
fi
sudo cp -R "$BUILDDIR"/fonts/opentype/* /usr/share/fonts/opentype/
sudo cp -R "$BUILDDIR"/fonts/truetype/* /usr/share/fonts/truetype/
fc-cache -vf

# VS Code user settings (VS Code is installed above, so this dir now exists)
mkdir -p "$USER_HOME/.config/Code/User"
cp "$BUILDDIR/settings.json" "$USER_HOME/.config/Code/User/"

# Wallpaper (i3 references /usr/share/backgrounds/Mangalore.jpg)
if [ -f "$BUILDDIR/Mangalore.jpg" ]; then
  sudo cp "$BUILDDIR/Mangalore.jpg" /usr/share/backgrounds/
elif [ -f /usr/share/backgrounds/Mangalore.jpg ]; then
  warn "Mangalore.jpg already in /usr/share/backgrounds"
else
  warn "Mangalore.jpg not in repo — add it or i3 wallpaper will be blank"
fi

# ============================================================================
#  5. auto-cpufreq (from bundled checkout)
# ============================================================================
if ! command -v auto-cpufreq >/dev/null 2>&1; then
  log "Installing auto-cpufreq"
  ( cd "$BUILDDIR/auto-cpufreq" && sudo ./auto-cpufreq-installer )
else
  warn "auto-cpufreq already installed"
fi

# ============================================================================
#  6. Desktop theming
# ============================================================================
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' || true
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true

log "Done. Log out / restart i3 (\$mod+Shift+r) to pick up changes."
