# Design Tokens

Single source of truth for every colour in this repo. If a hex value appears in a
config file, it must appear in the table below. Anything else is a bug.

## Core ramp

| Token      | Hex       | Role |
| ---------- | --------- | ---- |
| `bg`       | `#090C14` | Base canvas — bar, launcher, notification and lock backgrounds |
| `surface`  | `#0F172A` | Raised surface — input fields, focused wells |
| `card`     | `#111827` | Pills, panels, tooltips, floating cards |
| `border`   | `#1E293B` | Hairline separators and idle module borders |
| `accent`   | `#38BDF8` | Primary accent (sky). **Every focus/selection signal**: window focus, active workspace, selected launcher row, input focus ring |
| `ok`       | `#22C55E` | Success, connected, healthy. **Not** used for selection — that is always `accent` |
| `alt`      | `#A78BFA` | Secondary accent (purple). Git, CPU, clipboard |
| `info`     | `#2DD4BF` | Tertiary accent (teal). Network, virtualenv |
| `warn`     | `#FBBF24` | Warning states |
| `err`      | `#EF4444` | Critical states, errors, power |
| `text`     | `#F8FAFC` | Primary text |
| `text-2`   | `#CBD5E1` | Body text |
| `text-3`   | `#64748B` | Muted / secondary text |
| `text-4`   | `#475569` | Disabled / de-emphasised text |

## Extended shades

Interpolations within the ramp. Used where a surface needs to sit *between* two
core tokens — chiefly the Neovim theme, which needs more steps than desktop
chrome does. Not for new UI; reach for a core token first.

| Token       | Hex       | Sits between        |
| ----------- | --------- | ------------------- |
| `bg-deep`   | `#060911` | below `bg`          |
| `border-2`  | `#334155` | `border` / `text-4` |
| `text-2.5`  | `#94A3B8` | `text-2` / `text-3` |
| `text-3.5`  | `#556074` | `text-3` / `text-4` |
| `warn-2`    | `#FB923C` | `warn` / `err`      |
| `alt-2`     | `#818CF8` | indigo; RAM vs CPU  |
| `ok-tint`   | `#A9F5C2` | text on `ok` fills  |
| `err-tint`  | `#FCA5A5` | text on `err` fills |

## Terminal ANSI mapping

Kitty (`kitty/cyber_studio.conf`) and the Neovim theme both map onto this ramp so
that TUI programs, `ls` output and editor syntax agree.

| Slot | Normal    | Bright    | Role    |
| ---- | --------- | --------- | ------- |
| 0/8  | `#1E293B` | `#475569` | black   |
| 1/9  | `#EF4444` | `#F87171` | red     |
| 2/10 | `#22C55E` | `#4ADE80` | green   |
| 3/11 | `#FBBF24` | `#FCD34D` | yellow  |
| 4/12 | `#38BDF8` | `#7DD3FC` | blue    |
| 5/13 | `#A78BFA` | `#C4B5FD` | magenta |
| 6/14 | `#2DD4BF` | `#5EEAD4` | cyan    |
| 7/15 | `#CBD5E1` | `#F8FAFC` | white   |

## Deliberate exception: GTK

GTK application chrome uses **Catppuccin Mocha Blue**, not the ramp above.
Its `#89B4FA` accent is the closest match to `accent` among packaged GTK themes,
and hand-authoring a full GTK stylesheet is out of scope for this repo. This is a
knowing approximation, not an oversight — `sway/scripts/desktop-theme.sh` picks it
by preference and falls back to `Adwaita-dark` when it is not installed.

## History

This repo previously carried two unreconciled palettes: the slate set above
(waybar, wofi, mako, swaylock, sddm, btop) and a neon set — `#0A0A0A` /
`#00E5FF` / `#39FF14` — in kitty, sway borders, nvim and starship. The most
visible symptom was neon-green window borders against a sky-blue bar. Everything
now converges on slate.
