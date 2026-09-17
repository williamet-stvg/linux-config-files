# shellcheck shell=bash
#
# Sourced automatically by Ubuntu's stock ~/.bashrc.
#
# The clipboard and "open" helpers are defined as FUNCTIONS, not aliases,
# because they need to dispatch on what is actually available at runtime
# (WSL interop vs. X11 vs. Wayland) and because aliases cannot take pipes.
 
# ---------------------------------------------------------------------------
# ls
# ---------------------------------------------------------------------------
alias ll='ls -alFh'
alias la='ls -A'
alias l='ls -CF'
alias lt='ls -alFht'          # newest first
 
# ---------------------------------------------------------------------------
# clipboard
# ---------------------------------------------------------------------------
# Original was:  alias clipboard="tr -d '\n' | xclip -sel clip"
#   * xclip is X11-only — it does nothing useful under WSL, and it was never
#     in the install list anyway.
#   * tr -d '\n' strips EVERY newline, so piping multi-line output through it
#     joins all the lines together. Only the trailing newline should go.
clipcopy() {
    if command -v clip.exe >/dev/null 2>&1; then
        clip.exe
    elif command -v wl-copy >/dev/null 2>&1; then
        wl-copy
    elif command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard
    elif command -v xsel >/dev/null 2>&1; then
        xsel --clipboard --input
    else
        printf 'clipcopy: no clipboard backend (need clip.exe, wl-copy, xclip or xsel)\n' >&2
        return 1
    fi
}
 
clippaste() {
    if command -v powershell.exe >/dev/null 2>&1; then
        # Strip the CRs Windows hands back.
        powershell.exe -NoProfile -Command Get-Clipboard | tr -d '\r'
    elif command -v wl-paste >/dev/null 2>&1; then
        wl-paste
    elif command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard -o
    elif command -v xsel >/dev/null 2>&1; then
        xsel --clipboard --output
    else
        printf 'clippaste: no clipboard backend\n' >&2
        return 1
    fi
}
 
# Pipe anything into the clipboard, dropping only the trailing newline.
# $(cat) strips trailing newlines; printf '%s' adds none back.
clipboard() {
    local data
    data=$(cat)
    printf '%s' "$data" | clipcopy
}
 
# Current directory to clipboard.
pwdc() { printf '%s' "$PWD" | clipcopy; }
 
# Current directory as a Windows path, for pasting into Explorer etc.
if command -v wslpath >/dev/null 2>&1; then
    pwdw() { wslpath -w "$PWD"; }
    pwdwc() { printf '%s' "$(wslpath -w "$PWD")" | clipcopy; }
fi
 
# ---------------------------------------------------------------------------
# open
# ---------------------------------------------------------------------------
# xdg-open is meaningless on WSL without a desktop session. Dispatch instead.
# Note: explorer.exe exits non-zero even when it succeeds, hence the `|| true`.
open() {
    local target="${1:-.}"
    if command -v wslview >/dev/null 2>&1; then
        wslview "$target"
    elif command -v explorer.exe >/dev/null 2>&1; then
        if [ -e "$target" ]; then
            explorer.exe "$(wslpath -w "$(readlink -f "$target")")" || true
        else
            explorer.exe "$target" || true
        fi
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$target" >/dev/null 2>&1 &
    else
        printf 'open: no handler available\n' >&2
        return 1
    fi
}
 
# ---------------------------------------------------------------------------
# safety
# ---------------------------------------------------------------------------
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -I'              # -I prompts once for bulk, unlike -i per file
alias mkdir='mkdir -p'
 
# ---------------------------------------------------------------------------
# git
# ---------------------------------------------------------------------------
alias gs='git status -sb'
alias gd='git diff'
alias gdc='git diff --cached'
alias gl='git log --oneline --graph --decorate -20'
alias gb='git branch -vv'
alias gco='git checkout'
 
# ---------------------------------------------------------------------------
# misc
# ---------------------------------------------------------------------------
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ip='ip -color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias t='tmux attach || tmux new'
alias reload='exec bash -l'
 
