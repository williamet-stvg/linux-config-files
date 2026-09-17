#!/usr/bin/env bash
#
# linux-config-files — environment bootstrap for Ubuntu (native or WSL2).
#
# Usage:
#   ./init.sh                                  # packages + dotfiles
#   ./init.sh --dotfiles-only                  # skip apt entirely
#   ./init.sh --no-yocto                       # skip Yocto build dependencies
#   ./init.sh --copy                           # copy dotfiles, don't symlink
#
# Git identity — pick which of your accounts this machine uses:
#   ./init.sh --email you@example.com
#   ./init.sh --email you@example.com --name "Your Name"
#   ./init.sh --email you@work.com --ssh-key id_ed25519_work
#   ./init.sh --git                            # prompt for both interactively
#
#   --email EMAIL     git user.email, and the SSH key comment. Implies --git.
#   --name NAME       git user.name. Implies --git. Prompted if omitted.
#   --ssh-key NAME    key filename under ~/.ssh (default: id_ed25519). Use it
#                     to keep one key per GitHub account; an ssh config Host
#                     alias is written so you can clone with it.
#   --no-ssh-key      set the git identity only, generate no key.
#
# Both "--email you@x.com" and "--email=you@x.com" are accepted.
#
# DO NOT run as root. It writes into $HOME and calls sudo only where needed.
# Running it as root puts your dotfiles in /root and leaves root-owned files
# in your home directory.
 
set -euo pipefail
 
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export DEBIAN_FRONTEND=noninteractive
 
# ---------------------------------------------------------------------------
# helpers  (defined before argument parsing so die() is available there)
# ---------------------------------------------------------------------------
log()  { printf '\n\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
 
usage() { awk 'NR>1 && /^#/ {sub(/^# ?/,""); print; next} NR>1 {exit}' "${BASH_SOURCE[0]}"; }
 
# ---------------------------------------------------------------------------
# arguments
# ---------------------------------------------------------------------------
DO_APT=1
DO_YOCTO=1
DO_GIT=0
DO_SSH_KEY=1
LINK_MODE="symlink"
GIT_EMAIL=""
GIT_NAME=""
SSH_KEY_NAME="id_ed25519"
 
# Pull the value for --opt VALUE, erroring out if it is missing or looks like
# another flag. Echoes the value; the caller shifts.
need_arg() {
    local opt="$1" val="${2-}"
    [[ -n "$val" && "$val" != -* ]] || die "$opt requires a value"
    printf '%s' "$val"
}
 
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dotfiles-only) DO_APT=0 ;;
        --no-yocto)      DO_YOCTO=0 ;;
        --copy)          LINK_MODE="copy" ;;
        --git)           DO_GIT=1 ;;
        --no-ssh-key)    DO_SSH_KEY=0 ;;
 
        --email)         GIT_EMAIL="$(need_arg --email "${2-}")";       DO_GIT=1; shift ;;
        --email=*)       GIT_EMAIL="${1#*=}";                           DO_GIT=1 ;;
        --name)          GIT_NAME="$(need_arg --name "${2-}")";         DO_GIT=1; shift ;;
        --name=*)        GIT_NAME="${1#*=}";                            DO_GIT=1 ;;
        --ssh-key)       SSH_KEY_NAME="$(need_arg --ssh-key "${2-}")";  DO_GIT=1; shift ;;
        --ssh-key=*)     SSH_KEY_NAME="${1#*=}";                        DO_GIT=1 ;;
 
        -h|--help)       usage; exit 0 ;;
        *)               printf 'unknown option: %s\n\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done
 
# Validate early — before any apt work — so a typo fails in a second rather
# than twenty minutes in.
if [[ -n "$GIT_EMAIL" ]]; then
    [[ "$GIT_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]] \
        || die "--email does not look like an address: $GIT_EMAIL"
fi
 
# The key name lands in a path and in an ssh config Host alias; keep it boring.
[[ "$SSH_KEY_NAME" =~ ^[A-Za-z0-9._-]+$ ]] \
    || die "--ssh-key must be a bare filename (letters, digits, . _ -), not a path: $SSH_KEY_NAME"
 
have() { command -v "$1" >/dev/null 2>&1; }
 
is_wsl() { [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null; }
 
# Pick the first package name apt actually knows about. Package names drift
# between Ubuntu releases (libegl1-mesa -> libegl1, etc.).
pick_pkg() {
    local candidate
    for candidate in "$@"; do
        if apt-cache show "$candidate" >/dev/null 2>&1; then
            printf '%s' "$candidate"
            return 0
        fi
    done
    return 1
}
 
# Symlink (default) or copy repo file -> $HOME, backing up anything real that
# is already there. Idempotent: re-running does not stack up backups.
install_dotfile() {
    local src="$REPO_DIR/$1" dest="$HOME/$1"
 
    [[ -f "$src" ]] || die "missing $src"
 
    if [[ "$LINK_MODE" == "symlink" ]]; then
        if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
            printf '    %-20s already linked\n' "$1"
            return 0
        fi
    fi
 
    if [[ -e "$dest" && ! -L "$dest" ]]; then
        local backup
        backup="$dest.bak.$(date +%Y%m%d%H%M%S)"
        mv -- "$dest" "$backup"
        printf '    %-20s existing file backed up to %s\n' "$1" "$(basename "$backup")"
    fi
 
    if [[ "$LINK_MODE" == "symlink" ]]; then
        ln -sfn -- "$src" "$dest"
        printf '    %-20s linked\n' "$1"
    else
        install -m 0644 -- "$src" "$dest"
        printf '    %-20s copied\n' "$1"
    fi
}
 
# ---------------------------------------------------------------------------
# preflight
# ---------------------------------------------------------------------------
[[ ${EUID:-$(id -u)} -ne 0 ]] || die "do not run this as root — run it as your normal user
  (it calls sudo itself where it needs to)"
 
have apt-get || die "this script targets Debian/Ubuntu (no apt-get found)"
 
# shellcheck disable=SC1091
. /etc/os-release
PLATFORM="native"
is_wsl && PLATFORM="wsl"
 
log "Host: ${PRETTY_NAME:-unknown}  |  platform: $PLATFORM  |  repo: $REPO_DIR"
 
if [[ $DO_APT -eq 1 ]]; then
    sudo -v || die "sudo authentication failed"
fi
 
# ---------------------------------------------------------------------------
# packages
# ---------------------------------------------------------------------------
if [[ $DO_APT -eq 1 ]]; then
    log "Updating package lists"
    sudo apt-get update
    sudo apt-get upgrade -y
 
    BASE_PKGS=(
        build-essential
        ca-certificates
        clang
        curl
        git
        manpages-dev
        openssh-client
        tmux
        tree
        valgrind
        vim
        wget
    )
 
    # Clipboard + open helpers used by .bash_aliases.
    if [[ "$PLATFORM" == "wsl" ]]; then
        # clip.exe / powershell.exe come from Windows via interop — nothing to
        # install. wslu provides wslview but is not in every release's repos,
        # so it is best-effort only.
        if pkg=$(pick_pkg wslu); then
            BASE_PKGS+=("$pkg")
        else
            warn "wslu not available in this release's repos; 'open' will fall back to explorer.exe"
        fi
    else
        BASE_PKGS+=(xclip dconf-cli)
    fi
 
    log "Installing base tools"
    sudo apt-get install -y "${BASE_PKGS[@]}"
 
    # Chromium: skipped on WSL. apt's chromium-browser is a snap shim and snapd
    # needs systemd, which is off by default under WSL.
    if [[ "$PLATFORM" == "native" ]]; then
        if pkg=$(pick_pkg chromium-browser chromium); then
            log "Installing $pkg"
            sudo apt-get install -y "$pkg" || warn "$pkg failed to install; continuing"
        fi
    else
        log "Skipping chromium (use your Windows browser from WSL)"
    fi
fi
 
# ---------------------------------------------------------------------------
# Yocto build dependencies
# ---------------------------------------------------------------------------
if [[ $DO_APT -eq 1 && $DO_YOCTO -eq 1 ]]; then
    YOCTO_PKGS=(
        chrpath cpio debianutils diffstat gawk gcc iputils-ping
        libssl-dev mesa-common-dev python3 python3-git python3-jinja2
        python3-pexpect python3-pip python3-subunit socat texinfo
        unzip xterm xz-utils zstd
    )
 
    # Renamed / dropped across releases — resolve at runtime.
    for group in "libegl1 libegl1-mesa" \
                 "libsdl1.2-compat-dev libsdl1.2-dev" \
                 "lz4 liblz4-tool"; do
        # shellcheck disable=SC2086
        if pkg=$(pick_pkg $group); then
            YOCTO_PKGS+=("$pkg")
        else
            warn "none of [$group] available; skipping"
        fi
    done
 
    log "Installing Yocto build dependencies"
    sudo apt-get install -y "${YOCTO_PKGS[@]}"
fi
 
# ---------------------------------------------------------------------------
# dotfiles
# ---------------------------------------------------------------------------
log "Installing dotfiles ($LINK_MODE)"
install_dotfile .terminal_settings
install_dotfile .bash_aliases
install_dotfile .tmux.conf
install_dotfile .vimrc
 
# ---------------------------------------------------------------------------
# .bashrc hook (idempotent)
# ---------------------------------------------------------------------------
BASHRC="$HOME/.bashrc"
MARKER='# >>> linux-config-files >>>'
 
if grep -qF "$MARKER" "$BASHRC" 2>/dev/null; then
    log ".bashrc hook already present"
else
    log "Adding .bashrc hook"
    # Quoted delimiter: nothing inside is expanded at write time.
    cat >> "$BASHRC" << 'EOT'
 
# >>> linux-config-files >>>
if [ -f ~/.terminal_settings ]; then
    . ~/.terminal_settings
fi
# <<< linux-config-files <<<
EOT
fi
 
# ---------------------------------------------------------------------------
# terminal appearance
# ---------------------------------------------------------------------------
if [[ "$PLATFORM" == "wsl" ]]; then
    log "Terminal appearance: WSL uses Windows Terminal, not dconf"
    cat << 'EOT'
    Merge the profile + scheme from windows-terminal/settings-fragment.jsonc
    into your Windows Terminal settings (Ctrl+, then "Open JSON file"), or:
      %LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
EOT
elif have dconf && [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    PROFILE_ID="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d \"\' || true)"
    if [[ -n "$PROFILE_ID" ]]; then
        log "Loading gnome-terminal config into profile $PROFILE_ID"
        dconf load "/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/" < "$REPO_DIR/dconf/terminal_design.dconf"
        dconf load "/org/gnome/terminal/legacy/keybindings/" < "$REPO_DIR/dconf/keys.dconf"
    else
        warn "could not resolve the default gnome-terminal profile; skipping dconf load"
    fi
else
    warn "no dconf or no D-Bus session bus; skipping terminal appearance"
fi
 
# ---------------------------------------------------------------------------
# optional: git + ssh
# ---------------------------------------------------------------------------
if [[ $DO_GIT -eq 1 ]]; then
    log "git configuration"
 
    # Fall back to prompting only for what was not passed as an argument.
    # Non-interactive (CI, a provisioning script) must supply --email.
    if [[ -z "$GIT_EMAIL" ]]; then
        if [[ -t 0 ]]; then
            current_mail="$(git config --global user.email 2>/dev/null || true)"
            read -rp "  git user.email${current_mail:+ [$current_mail]}: " GIT_EMAIL
            GIT_EMAIL="${GIT_EMAIL:-$current_mail}"
        fi
        [[ -n "$GIT_EMAIL" ]] || die "no email given — pass --email you@example.com"
        [[ "$GIT_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]] \
            || die "that does not look like an address: $GIT_EMAIL"
    fi
 
    if [[ -z "$GIT_NAME" ]]; then
        if [[ -t 0 ]]; then
            current_name="$(git config --global user.name 2>/dev/null || true)"
            read -rp "  git user.name${current_name:+ [$current_name]}: " GIT_NAME
            GIT_NAME="${GIT_NAME:-$current_name}"
        fi
        [[ -n "$GIT_NAME" ]] || die "no name given — pass --name \"Your Name\""
    fi
 
    git config --global user.name  "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global core.editor vim
    git config --global init.defaultBranch main
    git config --global pull.rebase true
 
    printf '    user.name  = %s\n' "$(git config --global user.name)"
    printf '    user.email = %s\n' "$(git config --global user.email)"
 
    # -----------------------------------------------------------------------
    # SSH key
    # -----------------------------------------------------------------------
    if [[ $DO_SSH_KEY -eq 0 ]]; then
        log "Skipping SSH key (--no-ssh-key)"
    elif ! have ssh-keygen; then
        warn "ssh-keygen not found — install it with:  sudo apt-get install -y openssh-client
  then re-run:  ./init.sh --dotfiles-only --email $GIT_EMAIL${SSH_KEY_NAME:+ --ssh-key $SSH_KEY_NAME}"
    else
        KEY="$HOME/.ssh/$SSH_KEY_NAME"
        mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
 
        if [[ -f "$KEY" ]]; then
            # Warn if this key belongs to a different identity rather than
            # silently reusing it for the account being set up.
            existing_id=""
            [[ -f "$KEY.pub" ]] && existing_id="$(cut -d' ' -f3- < "$KEY.pub" || true)"
 
            if [[ -n "$existing_id" && "$existing_id" != "$GIT_EMAIL" ]]; then
                warn "$KEY already exists but was created for '$existing_id', not '$GIT_EMAIL'.
  Reusing it as-is — no key was generated or overwritten.
  For a separate key per account, re-run with e.g.:
      ./init.sh --email $GIT_EMAIL --ssh-key id_ed25519_${GIT_EMAIL%%@*}"
            else
                log "SSH key already exists at $KEY"
            fi
        else
            log "Generating SSH key at $KEY"
            ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$KEY"
        fi
 
        # -------------------------------------------------------------------
        # ssh config Host alias — only for a non-default key name, since that
        # is the case where ssh would not find the key on its own.
        # -------------------------------------------------------------------
        if [[ "$SSH_KEY_NAME" != "id_ed25519" ]]; then
            SSH_CONFIG="$HOME/.ssh/config"
            ALIAS="github.com-${SSH_KEY_NAME#id_ed25519_}"
            MARKER="# >>> linux-config-files: $ALIAS >>>"
 
            touch "$SSH_CONFIG" && chmod 600 "$SSH_CONFIG"
 
            if grep -qF "$MARKER" "$SSH_CONFIG"; then
                log "ssh config alias '$ALIAS' already present"
            else
                log "Adding ssh config alias '$ALIAS'"
                cat >> "$SSH_CONFIG" << EOT
 
$MARKER
Host $ALIAS
    HostName github.com
    User git
    IdentityFile ~/.ssh/$SSH_KEY_NAME
    IdentitiesOnly yes
# <<< linux-config-files: $ALIAS <<<
EOT
            fi
 
            cat << EOT
 
    Clone with this account using the alias in place of github.com:
        git clone git@$ALIAS:<owner>/<repo>.git
 
    For an existing clone:
        git remote set-url origin git@$ALIAS:<owner>/<repo>.git
 
    Verify:
        ssh -T git@$ALIAS
EOT
        fi
 
        printf '\n  Public key — add it at https://github.com/settings/keys\n'
        printf '  (make sure you are signed in as the account for %s)\n\n' "$GIT_EMAIL"
        cat "$KEY.pub"
        printf '\n'
    fi
fi
 
# ---------------------------------------------------------------------------
# done
# ---------------------------------------------------------------------------
# Deliberately NOT sourcing ~/.bashrc: it would run in this script's subshell
# and die with it, and Ubuntu's .bashrc returns early for non-interactive
# shells regardless.
cat << 'EOT'
 
==> Done. Open a new shell (or: exec bash -l) to pick up the new config.
 
EOT
 
