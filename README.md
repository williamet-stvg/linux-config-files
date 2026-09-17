# linux-config-files

Dotfiles and bootstrap for a fresh Ubuntu environment, native or WSL2.

```
.
├── init.sh                              # bootstrap: packages + dotfiles
├── .terminal_settings                   # prompt, history, shell options
├── .bash_aliases                        # aliases + clipboard/open helpers
├── .vimrc
├── .tmux.conf
├── dconf/
│   ├── terminal_design.dconf            # gnome-terminal — NATIVE ONLY
│   └── keys.dconf                       # gnome-terminal — NATIVE ONLY
└── windows-terminal/
    └── settings-fragment.jsonc          # the WSL equivalent of dconf/
```

## Setup on a new machine

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/<you>/linux-config-files.git ~/linux-config-files
cd ~/linux-config-files
chmod +x init.sh
./init.sh
```

Then open a new shell, or `exec bash -l`.

> **Do not run `init.sh` as root** — not with `sudo`, not as the root user.
> The script calls `sudo` itself for the handful of steps that need it. Running
> the whole thing as root installs the dotfiles into `/root` instead of your
> home directory and leaves root-owned files scattered in `$HOME`. `init.sh`
> refuses to start as root for this reason.

### Options

| Flag | Effect |
|---|---|
| `--dotfiles-only` | Skip `apt` entirely — just install the dotfiles |
| `--no-yocto` | Skip the Yocto build dependencies |
| `--copy` | Copy dotfiles instead of symlinking them |
| `--email EMAIL` | Set `git user.email` and the SSH key comment. Implies `--git` |
| `--name NAME` | Set `git user.name`. Implies `--git`. Prompted if omitted |
| `--ssh-key NAME` | Key filename under `~/.ssh` (default `id_ed25519`) |
| `--no-ssh-key` | Set the git identity only, generate no key |
| `--git` | Run the git + SSH setup, prompting for anything not passed |

`--opt VALUE` and `--opt=VALUE` are both accepted. The email is validated
before any `apt` work starts, so a typo fails in a second rather than twenty
minutes in.

By default dotfiles are **symlinked** into `$HOME`, so editing a file in this
repo takes effect immediately and `git status` shows your changes. Use
`--copy` if you'd rather have independent copies. Either way, an existing real
file is moved aside to `<name>.bak.<timestamp>` before anything is written.

`init.sh` is idempotent — re-running it will not duplicate the `.bashrc` hook
or pile up backups.

## Terminal appearance

This is the one thing that genuinely differs between the two platforms.

**WSL** has no gnome-terminal and no D-Bus session bus, so `dconf load` does
nothing useful there. Merge `windows-terminal/settings-fragment.jsonc` into
your Windows Terminal settings instead (`Ctrl+,` → *Open JSON file*). Merge the
individual keys; don't replace the whole file.

**Native Ubuntu** uses the files in `dconf/`, which `init.sh` loads
automatically. It resolves your actual default profile UUID at runtime rather
than assuming one.

## Git and SSH setup

Pass the identity you want this machine set up with:

```bash
./init.sh --email william.kjaer@me.com --name "William Kjær"
```

`--email` implies `--git`, so that one flag is enough. Anything you leave out
is prompted for interactively, defaulting to whatever is already in your
global config. Non-interactively (CI, a provisioning script) `--email` is
required — the script errors out rather than hanging on a prompt.

Just the git identity, no key:

```bash
./init.sh --dotfiles-only --email william.kjaer@me.com --name "William Kjær" --no-ssh-key
```

### More than one GitHub account

`--ssh-key` gives each account its own key, and writes an `~/.ssh/config`
`Host` alias so ssh picks the right one:

```bash
./init.sh --email william.kjaer@me.com  --name "William Kjær"                             # ~/.ssh/id_ed25519
./init.sh --email william.kjar@unitech.no --name "William Kjær" --ssh-key id_ed25519_work # ~/.ssh/id_ed25519_work
```

The second call appends:

```
Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_work
    IdentitiesOnly yes
```

Then use the alias in place of `github.com` for that account's repos:

```bash
git clone git@github.com-work:<owner>/<repo>.git
git remote set-url origin git@github.com-work:<owner>/<repo>.git   # existing clone
ssh -T git@github.com-work                                         # verify
```

The alias name comes from the key name: `id_ed25519_work` → `github.com-work`.
No alias is written for the default `id_ed25519`, since ssh finds that one on
its own.

If a key file already exists but was generated for a *different* address, the
script warns and reuses it untouched rather than overwriting — an ed25519
private key you've already registered with GitHub is not something to silently
regenerate. It suggests the `--ssh-key` invocation to use instead.

Remember the per-account git identity is still global here. If you want the
identity to switch automatically by directory rather than per machine, add a
conditional include to `~/.gitconfig`:

```
[includeIf "gitdir:~/work/"]
    path = ~/.gitconfig-work
```

…with `user.email` in `~/.gitconfig-work`. `init.sh` deliberately doesn't do
this for you, since it depends on how you lay out your directories.

### ssh-agent

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519          # note the ~/ — a bare .ssh/... only works from $HOME
```

Clone over **HTTPS** the first time, as above — cloning this repo over SSH
before the key exists is a chicken-and-egg problem. Switch the remote
afterwards if you prefer SSH:

```bash
git remote set-url origin git@github.com:<you>/linux-config-files.git
```

`eval "$(ssh-agent -s)"` only affects the current shell. For a persistent
agent, either let WSL's systemd handle it, or add to `.terminal_settings`:

```bash
if ! pgrep -u "$USER" ssh-agent >/dev/null; then
    ssh-agent -t 12h > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi
[ -f "$XDG_RUNTIME_DIR/ssh-agent.env" ] && . "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
```

## What's installed

**Base** — `build-essential`, `clang`, `git`, `vim`, `tmux`, `tree`,
`valgrind`, `manpages-dev`, `curl`, `wget`, plus `xclip` + `dconf-cli` on
native or `wslu` on WSL.

**Yocto build host dependencies** — the set from the Yocto Project Reference
Manual. Skip with `--no-yocto`. Several package names have moved across Ubuntu
releases (`libegl1-mesa` → `libegl1`, `libsdl1.2-dev` →
`libsdl1.2-compat-dev`, `liblz4-tool` → `lz4`); `init.sh` resolves whichever
name the local `apt` actually knows, so it works on 22.04 through 26.04.

### Deliberately not installed

- **VS Code (the Linux `.deb`)** — under WSL, install VS Code on *Windows* and
  add the WSL extension. It injects a `code` shim into your WSL `PATH`
  automatically. The Linux deb gives you a second, GUI-launching `code` that
  shadows the shim and pulls in a large GTK dependency tree for nothing. The
  install block is still in `init.sh`, commented out, if you want it on a
  native machine.
- **Chromium** — `apt install chromium-browser` on 22.04+ installs a snap
  shim, and snapd needs systemd, which is off by default under WSL. Installed
  on native only.

## Python

Ubuntu's system Python is a dependency of `apt` itself — don't repoint
`python3` at another version with `update-alternatives`, and don't
`sudo make install` a source build (use `make altinstall`). For per-project
interpreters:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
uv python install 3.13
uv venv --python 3.13
```

On 24.04+, system-wide `pip install` is blocked by PEP 668. Use a venv or `uv`.

## Notes on the shell config

- The prompt shows the git branch via `git symbolic-ref`, not
  `git branch | sed`. The latter enumerates every local ref, and you pay that
  cost on every prompt — noticeable in a large repo like a Yocto tree.
- `PS1` is set, not exported. It's a shell-local setting; exporting it leaks
  into child processes.
- Clipboard and `open` are functions that dispatch at runtime across
  `clip.exe` (WSL), `wl-copy` (Wayland), `xclip`/`xsel` (X11), so the same
  file works everywhere.
- `.vimrc` uses `colorcolumn=120` rather than `textwidth=120`. `textwidth`
  inserts real newlines into your source as you type, which you do not want
  in code.

