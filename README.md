<div align="center">

```
  ██████╗  ██╗   ██╗ ██████╗  ███████╗ ██████╗      ███████╗ ████████╗ ██╗   ██╗ ██████╗  ██╗  ██████╗
 ██╔════╝  ╚██╗ ██╔╝ ██╔══██╗ ██╔════╝ ██╔══██╗     ██╔════╝ ╚══██╔══╝ ██║   ██║ ██╔══██╗ ██║ ██╔═══██╗
 ██║        ╚████╔╝  ██████╔╝ █████╗   ██████╔╝     ███████╗    ██║    ██║   ██║ ██║  ██║ ██║ ██║   ██║
 ██║         ╚██╔╝   ██╔══██╗ ██╔══╝   ██╔══██╗     ╚════██║    ██║    ██║   ██║ ██║  ██║ ██║ ██║   ██║
 ╚██████╗     ██║    ██████╔╝ ███████╗ ██║  ██║     ███████║    ██║    ╚██████╔╝ ██████╔╝ ██║ ╚██████╔╝
  ╚═════╝     ╚═╝    ╚═════╝  ╚══════╝ ╚═╝  ╚═╝     ╚══════╝    ╚═╝     ╚═════╝  ╚═════╝  ╚═╝  ╚═════╝
```

# CYBER STUDIO WORKSTATION

**A Sway/Wayland desktop for CachyOS, built around one design system.**

![OS](https://img.shields.io/badge/OS-CachyOS%20%2F%20Arch-38BDF8?style=for-the-badge&logo=archlinux&logoColor=090C14&labelColor=111827)
![Compositor](https://img.shields.io/badge/Compositor-Sway%201.12-22C55E?style=for-the-badge&logo=wayland&logoColor=090C14&labelColor=111827)
![Shell](https://img.shields.io/badge/Shell-Zsh%20%2B%20Starship-A78BFA?style=for-the-badge&logo=zsh&logoColor=090C14&labelColor=111827)
[![License](https://img.shields.io/badge/License-MIT-CBD5E1?style=for-the-badge&labelColor=111827)](LICENSE)

*Every surface — bar, launcher, notifications, terminal, editor, lock screen, login —
draws from a single token file. No component invents its own colours.*

</div>

---

## Design system

All colours live in **[PALETTE.md](PALETTE.md)**. If a hex appears in a config file
and not in that table, it's a bug.

| | Token | Hex | Role |
|---|---|---|---|
| ![](https://img.shields.io/badge/-090C14-090C14?style=flat-square) | `bg`      | `#090C14` | Base canvas |
| ![](https://img.shields.io/badge/-0F172A-0F172A?style=flat-square) | `surface` | `#0F172A` | Raised surface, inputs |
| ![](https://img.shields.io/badge/-111827-111827?style=flat-square) | `card`    | `#111827` | Pills, panels, tooltips |
| ![](https://img.shields.io/badge/-1E293B-1E293B?style=flat-square) | `border`  | `#1E293B` | Hairlines, idle borders |
| ![](https://img.shields.io/badge/-38BDF8-38BDF8?style=flat-square) | `accent`  | `#38BDF8` | Focus, active workspace, selection |
| ![](https://img.shields.io/badge/-22C55E-22C55E?style=flat-square) | `ok`      | `#22C55E` | Success, connected, healthy |
| ![](https://img.shields.io/badge/-A78BFA-A78BFA?style=flat-square) | `alt`     | `#A78BFA` | Git, CPU, clipboard |
| ![](https://img.shields.io/badge/-2DD4BF-2DD4BF?style=flat-square) | `info`    | `#2DD4BF` | Network, virtualenv |
| ![](https://img.shields.io/badge/-FBBF24-FBBF24?style=flat-square) | `warn`    | `#FBBF24` | Warning states |
| ![](https://img.shields.io/badge/-EF4444-EF4444?style=flat-square) | `err`     | `#EF4444` | Critical, errors, power |
| ![](https://img.shields.io/badge/-F8FAFC-F8FAFC?style=flat-square) | `text`    | `#F8FAFC` | Primary text |

**One deliberate exception:** GTK application chrome uses *Catppuccin Mocha Blue*.
Its `#89B4FA` accent is the nearest match among packaged GTK themes, and writing a
full GTK stylesheet is out of scope here. This is a knowing approximation, and
`sway/scripts/desktop-theme.sh` falls back to `Adwaita-dark` if it isn't installed.

---

## What's in it

| Component | Notes |
|---|---|
| **Sway 1.12** | Config split across ten files by responsibility. Focused-window border is `accent`, matching the bar's active-workspace indicator. |
| **Waybar** | Island-grouped modules. Optional modules collapse to zero width when they have nothing to say, so the bar never shows an empty capsule. Battery and network interface are auto-detected, not pinned. |
| **Wofi** | Centred 640×460 launcher. GTK3-valid CSS only. |
| **Mako** | Top-right cards, 1px `accent` border, 10px radius, urgency tiers that recolour the border. DND on `$mod+m`. |
| **Kitty** | 0.75 background opacity, 15,000-line scrollback, 16-colour ANSI mapped onto the palette. |
| **Neovim** | `lazy.nvim` + Catppuccin used as a highlight scaffold, palette fully overridden onto the tokens. Transparent background. |
| **Starship** | Two-line prompt. Colours are named by role (`accent`, `ok`, `err`) so a retheme touches one block. |
| **Swaylock / SDDM** | Lock and login styled from the same ramp. |
| **btop / fastfetch** | Matching theme; fastfetch uses the custom ASCII logo in `fastfetch/cachyos_cyber.txt`. |

### SwayFX

Rounded corners, blur and drop shadows are **SwayFX** features — they are hard
config errors on upstream Sway, which is why they can't simply be listed in
`appearance.conf`. `sway/scripts/swayfx-effects.sh` probes the running compositor
and applies them only when supported, so the same config works on both. On
upstream Sway it is a silent no-op; install `swayfx` to get the glass look.

---

## Install

```bash
git clone <your-fork-url> cyber-studio && cd cyber-studio/dotfiles
./install.sh
```

The installer is idempotent. It backs up any existing config to
`~/.config/cyber_noir_backup_<timestamp>/` before writing, and

```bash
./install.sh --uninstall
```

restores the most recent backup. System-level items (SDDM theme, session entry,
`/usr/local/bin` helpers) are listed for manual removal rather than deleted
automatically.

**Requires:** CachyOS or Arch, an AUR helper (`paru`/`yay` — installed if absent).
Two packages come from the AUR: `bibata-cursor-theme` and `catppuccin-gtk-theme-mocha`.

---

## Layout

```
dotfiles/
├── PALETTE.md                  # design tokens — the source of truth
├── install.sh                  # install / --uninstall
├── LICENSE
│
├── sway/                       # compositor, split by responsibility
│   ├── config                  #   entrypoint: variables + includes
│   ├── theme.conf              #   tokens + window decoration
│   ├── appearance.conf         #   gaps, borders, SwayFX hook
│   ├── bindings.conf           #   keybindings
│   ├── input.conf              #   keyboard, touchpad, pointer
│   ├── output.conf             #   displays (wallpaper is NOT set here)
│   ├── windowrules.conf        #   floating rules, idle inhibit
│   ├── idle.conf               #   swayidle supervisor hook
│   ├── notifications.conf      #   mako lifecycle + bindings
│   ├── autostart.conf          #   daemons, portals, theme sync
│   └── scripts/
│       ├── desktop-theme.sh    #   GTK/icon/cursor resolution
│       ├── idle-daemon.sh      #   swayidle supervisor
│       ├── swayfx-effects.sh   #   conditional visual effects
│       ├── wallpaper_rotator.sh#   wallpaper daemon (sole owner of swaybg)
│       └── wallpaper-switch.sh #   wallpaper client
│
├── waybar/                     # bar + JSON telemetry scripts
├── wofi/  mako/  kitty/  swaylock/  btop/  starship/  fastfetch/  nvim/
├── system/            # /etc drop-ins: logind power keys, swaylock PAM
├── gtk/                        # gtk-3.0 + gtk-4.0 settings.ini
├── xdg-desktop-portal/         # portal backend preference for sway
└── sddm/cyber-noir/            # Qt Quick login theme + telemetry generator
```

---

## Keybindings

`$mod` is **Super**.

| Key | Action |
|---|---|
| `$mod+Return` / `$mod+t` | Terminal |
| `$mod+d` / `$mod+space` | Launcher |
| `$mod+Shift+q` | Close window |
| `$mod+h/j/k/l` | Focus (Vim directions) |
| `$mod+Shift+h/j/k/l` | Move window |
| `$mod+1..0` | Switch workspace |
| `$mod+f` | Fullscreen |
| `$mod+Shift+space` | Toggle floating |
| `$mod+r` | Resize mode |
| `$mod+Shift+v` / `$mod+y` | Clipboard history |
| `$mod+Shift+w` | Wallpaper menu |
| `$mod+Alt+w` | Next wallpaper |
| `$mod+m` | Toggle Do-Not-Disturb |
| `$mod+Ctrl+l` | Lock |
| `$mod+Shift+p` / power button | Power menu (lock / logout / suspend / reboot / off) |
| `Print` / `$mod+Shift+s` | Screenshot (full / region) |

---

## Notes on a few design decisions

**The wallpaper daemon owns `swaybg` exclusively.** `wallpaper-switch.sh` is a pure
client: it writes desired state and signals the daemon. Two independent processes
setting the wallpaper is what caused manual picks to be overwritten seconds later.
Runtime state lives in `${XDG_STATE_HOME:-~/.local/state}/cyber-studio/`, never in
`~/.config`, so machine-local state can't be committed back to the repo.

**`killall X` and `X` must share one shell.** Sway spawns each `exec` asynchronously
and does not wait, so `exec_always killall -q mako` followed by `exec_always mako`
is a race the kill frequently wins. Anything restarted on reload goes through a
single `sh -c` or a supervisor script.

**The power button opens a menu instead of cutting the power.** Sway bound
nothing to `XF86PowerOff`, so the keypress fell through to systemd-logind, whose
default is `HandlePowerKey=poweroff` — an instant, unprompted shutdown. Fixing it
needs both halves: `system/logind.conf.d/90-cyber-noir-power.conf` tells logind to
ignore the key, and `bindings.conf` §6b binds it to the power menu. A ~2s
long-press is still a hardware-level poweroff, so a wedged session stays
recoverable.

**`swaylock/config` targets upstream swaylock, not swaylock-effects.** swaylock
reads each config line as a long CLI option and *aborts* on anything it does not
recognise — it does not warn and continue. So one stray line disables locking
everywhere at once: the keybinding, the power menu, swayidle's idle timer and the
lock-before-suspend hook all silently do nothing. `blur`, `clock`, `timestr` and
`datestr` are swaylock-effects options and were removed for that reason; a bare
`indicator` line was too, since upstream only has longer flags sharing that prefix
and getopt rejected it as ambiguous. Check an edit without locking yourself out:

```sh
WAYLAND_DISPLAY=nonexistent swaylock --config ~/.config/swaylock/config
# "Unable to connect to the compositor" == the config parsed cleanly
```

**Menus use `wofi/dmenu.conf`, launchers use `wofi/config`.** wofi activates an
entry on a *double* click by default (`single_click`), which is what made the
Waybar power menu look completely dead — a single click selected a row, wofi
exited printing nothing, and the calling script fell through to its no-op branch.
The dmenu profile sets `single_click=true` and, unlike the launcher profile,
declares `mode=dmenu` and disables image/pango escape parsing, so a script reads
back exactly the bytes it wrote.

**Fingerprint is `sufficient`, never `required`.** `system/pam.d/swaylock` tries
`pam_fprintd.so` first and falls through to the password stack when the reader is
absent, busy, unenrolled or times out, so a broken sensor can never lock you out.
Enrol before expecting it to do anything: `fprintd-enroll && fprintd-verify`.

**Waybar scripts report nothing rather than something plausible.** `git_branch.sh`
shows the focused window's branch or an empty string — it does not fall back to
scanning your home directory, which made the bar display a branch unrelated to
what you were looking at.

---

## License

MIT — see [LICENSE](LICENSE).
