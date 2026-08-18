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
| **Swaylock / SDDM** | Lock and login styled from the same ramp. The lock screen composites your *sharp* wallpaper under a blurred snapshot of the desktop — see below. |
| **Clipboard manager** | GTK4 app (`sway/scripts/clipboard-gui.py`). Thumbnails for copied images, paste-on-select, per-row delete. |
| **Network manager** | GTK4 app (`sway/scripts/network-gui.py`). Signal meters, Wi-Fi switch, connect/forget, hidden networks. |
| **btop / fastfetch** | Matching theme; fastfetch uses the custom ASCII logo in `fastfetch/cachyos_cyber.txt`. |

### The two GTK apps

The clipboard and network pickers are real GTK4 applications rather than `wofi`
menus, because a dmenu cannot express what they need: a header bar, per-row
buttons, or any click target smaller than a whole row. As menus, their actions
had to be listed *as entries*, sitting below hundreds of real rows where nothing
could scroll to them.

Both start hidden at login (`--daemon`) and are woken over D-Bus by
`sway/scripts/open-app.sh`. A Python GTK4 process needs ~1.45 s to reach its
first frame — interpreter, pygobject and GTK init, measured with an empty window
— so paying that per click made them feel broken. Woken instead, the clipboard
opens in ~26 ms and the network app in ~200 ms.

They also pin `GSK_RENDERER=cairo`. On a hybrid-graphics laptop GTK's GPU
renderer setup cost 3.2 s against 0.2 s in software, and a search box over a list
of rows has no use for a GPU.

`clipboard.sh` and `networkmanager-dmenu` remain as wofi fallbacks: the apps need
`python-gobject`/`gtk4`/`libadwaita`, and on a rolling release those can break on
an update.

### SwayFX

Rounded corners, blur and drop shadows are **SwayFX** features — they are hard
config errors on upstream Sway, which is why they can't simply be listed in
`appearance.conf`. `sway/scripts/swayfx-effects.sh` probes the running compositor
and applies them only when supported, so the same config works on both. On
upstream Sway it is a silent no-op.

**As of Sway 1.12, SwayFX cannot be installed on Arch/CachyOS.** Sway 1.12 is
built against `wlroots0.20`; `swayfx` 0.6 still requires `wlroots0.19`, which has
been dropped from the repositories, so the dependency is unsatisfiable:

```
:: unable to satisfy dependency 'wlroots0.19' required by swayfx
```

Nothing here is wasted by that — the effects script probes rather than assumes,
so if SwayFX catches up to current wlroots it becomes a no-op-no-longer with no
config changes. Until then this is an upstream-Sway setup, and the translucency
in the Waybar and Mako styling is plain alpha compositing rather than real blur.

---

## Install

```bash
git clone https://github.com/aviinyou07/saway_cachyostheme.git && cd saway_cachyostheme/dotfiles
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

`CORE_PKGS` in `install.sh` is the authoritative dependency list. Worth knowing
that `imagemagick` (lock-screen blur and clipboard thumbnails), `wtype`
(paste-on-select) and `gtk4`/`libadwaita`/`python-gobject` (the two apps) are in
it — each was missing at some point, and because they happened to be installed on
the author's machine the breakage only ever appeared on a *fresh* install.

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
│       ├── clipboard-gui.py    #   GTK4 clipboard manager
│       ├── network-gui.py      #   GTK4 network manager
│       ├── open-app.sh         #   wake a resident app over D-Bus
│       ├── clipboard.sh        #   wofi fallback picker
│       ├── lock.sh             #   lock screen (blur composite)
│       ├── screenshot.sh       #   full / region / copy, month folders
│       ├── desktop-theme.sh    #   GTK/icon/cursor resolution
│       ├── idle-daemon.sh      #   swayidle supervisor
│       ├── idle-suspend.sh     #   suspend on idle, battery only
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
| `$mod+Shift+v` / `$mod+y` | Clipboard manager |
| `$mod+Shift+w` | Wallpaper menu |
| `$mod+Alt+w` | Next wallpaper |
| `$mod+m` | Toggle Do-Not-Disturb |
| `$mod+Ctrl+l` | Lock |
| `$mod+Shift+p` / power button | Power menu (lock / logout / suspend / reboot / off) |
| `Print` | Screenshot — whole desktop → file + clipboard |
| `$mod+Print` | Screenshot — region → file + clipboard |
| `$mod+Shift+s` | Screenshot — region → clipboard only |

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
ignore the key, and `bindings.conf` §6b binds it to the power menu. A ~5s
long-press (systemd's threshold) is still a real poweroff, so a wedged session
stays recoverable.

Installing the drop-in is only half of it: logind reads its configuration once,
at startup, so until it is reloaded the old in-memory `poweroff` stays live and
the button keeps killing the machine. `install.sh` reloads it — `systemd-logind`
is `Type=notify-reload`, so this costs no sessions.

**`swaylock/config` targets upstream swaylock, not swaylock-effects.** swaylock
reads each config line as a long CLI option and *aborts* on anything it does not
recognise — it does not warn and continue. So one stray line disables locking
everywhere at once: the keybinding, the power menu, swayidle's idle timer and the
lock-before-suspend hook all silently do nothing. `blur`, `clock`, `timestr` and
`datestr` are swaylock-effects options and were removed for that reason; a bare
`indicator` line was too, since upstream only has longer flags sharing that prefix
and getopt rejected it as ambiguous.

The blur comes from `scripts/lock.sh` instead, which hands stock swaylock a
plain `-i` image. Check an edit without locking yourself out:

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

**The lock screen puts the wallpaper back, rather than blurring what it grabbed.**
`grim` returns the frame the compositor already flattened, so with a translucent
terminal the wallpaper is baked into the very pixels the text sits on — there is
no layer left to separate, and "blur the text but not the wallpaper" cannot be
done to a screenshot. `scripts/lock.sh` reads swaybg's current image, draws it
sharp, and blends the blurred capture over it. Window shapes survive as a ghost;
nothing readable does. The resized wallpaper and vignette are cached in
`XDG_RUNTIME_DIR` (tmpfs, so a wallpaper swapped while logged out can never serve
a stale frame), and a `--prewarm` at login keeps the first lock as fast as the
rest.

**Clearing the clipboard is permanent, deliberately.** An earlier version
snapshotted the store before wiping and offered a restore. That is right for a
document and wrong for a clipboard: everything you copy lands in this history,
passwords included, so "I cleared it" has to mean the data is gone — not sitting
in a backup file anyone reading the disk can recover. A clear that can be undone
is worse than none, because it looks safe. Individual entries can be deleted the
same way, from the row itself.

**Idle suspend is gated on being unplugged.** swayidle measures *input*
idleness, not work — a long compile involves no keystrokes — so an unconditional
timer would suspend the machine mid-build. On battery that trade is worth making;
on mains there is nothing to save and a real job to lose. Before this the chain
ended at `dpms off`: the screen went black and the machine stayed fully awake,
which is indistinguishable from sleep until the battery is flat.

**Caches and backups are bounded.** cliphist stores whole images, so entries
average ~1 MB and its 750-item default projected to ~700 MB — the store here
reached 260 MB before it was cleared. The watchers run with `-max-items 150`.
`install.sh` keeps the newest three backup vaults *and always the oldest*: the
naive "keep newest N" deletes the pristine pre-theme configuration first, which
is the one thing that can undo the very first install. Screenshots go into
per-month folders; `screenshot.sh tidy` and `screenshot.sh prune <days>` exist
but only run when asked.

**Waybar scripts report nothing rather than something plausible.** `git_branch.sh`
shows the focused window's branch or an empty string — it does not fall back to
scanning your home directory, which made the bar display a branch unrelated to
what you were looking at.

Collapsing an optional module means removing its *styling*, not just its text.
An empty `format` still leaves the widget realised, so shared pill rules
(background, border, padding) keep painting a small blank capsule that highlights
on hover and does nothing when clicked — which is what `mpris` did whenever a
browser kept its MPRIS interface registered after playback stopped. The pill is
attached to `.playing`/`.paused` instead. Bluetooth and Wi-Fi go the other way:
when switched off they stay visible but dimmed, because that is exactly when you
want the control.

---

## License

MIT — see [LICENSE](LICENSE).
