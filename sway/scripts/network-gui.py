#!/usr/bin/env python3
# =============================================================================
# CYBER NOIR // NETWORK MANAGER  (GTK4 + libadwaita)
# =============================================================================
# Replaces networkmanager_dmenu, for the same reason the clipboard picker was
# replaced: a dmenu cannot express this UI. Its list mixed networks with
# actions ("Disable WiFi", "Delete a Connection") as sibling rows, appended
# signal bars after variable-length text so they landed at random x positions,
# and showed hidden networks as a bare security label with no name at all.
#
# nmcli is used rather than libnm. networkmanager_dmenu talks to libnm through
# python-gobject and spews G_IS_OBJECT assertion failures on every run here;
# nmcli is a stable, parseable interface that does not have that problem.
# =============================================================================
import os

# -----------------------------------------------------------------------------
# Keep this off the discrete GPU
# -----------------------------------------------------------------------------
# This machine is hybrid: Intel Alder Lake iGPU plus an NVIDIA RTX 2050 that sits
# in D3cold whenever it is idle. GTK4 initialises its renderer through the glvnd
# EGL vendor list, which prefers the NVIDIA ICD -- so opening this window WOKE
# the discrete GPU, and the wake alone cost ~2.5s. Measured cold: 3.5s to first
# frame, against ~1.0s once the card was already awake, which is exactly why
# launching it felt intermittently broken rather than uniformly slow.
#
# Pinning the EGL vendor to Mesa keeps everything on the iGPU, which is more than
# enough for a list of rows and never spins the dGPU up. Set before `import gi`,
# because the vendor list is read when EGL is first loaded.
_MESA = "/usr/share/glvnd/egl_vendor.d/50_mesa.json"
if os.path.exists(_MESA):
    os.environ.setdefault("__EGL_VENDOR_LIBRARY_FILENAMES", _MESA)

# And render in software. Measured on this machine, Gtk.Window.present() cost
# 3223ms with the default GPU renderer and 236ms with cairo -- a 13x difference,
# and the single largest component of "why does this take so long to open".
# Pinning the EGL vendor to Mesa alone did not fix it; the GPU context setup is
# slow here regardless of which vendor serves it.
#
# Nothing here needs a GPU: these windows are a search box and a list of text
# rows. Software rendering is not a compromise for this UI, it is the correct
# tool -- and it removes the whole class of hybrid-graphics startup stalls.
os.environ.setdefault("GSK_RENDERER", "cairo")

import os, re, shutil, subprocess, sys, threading
from pathlib import Path

import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gdk, Gio, GLib, Gtk, Pango


def nmcli(*args, timeout=25):
    try:
        r = subprocess.run(["nmcli", *args], capture_output=True, text=True, timeout=timeout)
        return r.returncode, r.stdout.strip(), r.stderr.strip()
    except Exception as e:
        return 1, "", str(e)


def split_t(line):
    """Split an `nmcli -t` row. Literal colons inside a field are backslash
    escaped, so a naive split() mangles any SSID containing one."""
    out, cur, esc = [], "", False
    for ch in line:
        if esc:
            cur += ch; esc = False
        elif ch == "\\":
            esc = True
        elif ch == ":":
            out.append(cur); cur = ""
        else:
            cur += ch
    out.append(cur)
    return out


def notify(title, body=""):
    if shutil.which("notify-send"):
        subprocess.Popen(["notify-send", "-t", "3000", title, body])


def signal_markup(pct):
    """A four-bar meter drawn with block characters.

    The obvious approach -- network-wireless-signal-{excellent,good,ok,weak}
    -symbolic -- is a dead end here: all five names resolve in Papirus-Dark, and
    all five render as the same filled cone, so a 22% network looked identical
    to a 75% one. Drawing the level explicitly is the only way it actually
    reads."""
    bars = 4 if pct >= 75 else 3 if pct >= 50 else 2 if pct >= 25 else 1 if pct > 0 else 0
    glyphs = "▂▄▆█"
    lit = GLib.markup_escape_text(glyphs[:bars])
    dim = GLib.markup_escape_text(glyphs[bars:])
    return (f'<span foreground="#38BDF8">{lit}</span>'
            f'<span foreground="#334155">{dim}</span>')


class NetRow(Gtk.ListBoxRow):
    def __init__(self, ap, saved, on_forget):
        super().__init__()
        self.ap = ap
        self.search_text = ap["ssid"].lower()

        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        box.set_margin_top(8); box.set_margin_bottom(8)
        box.set_margin_start(12); box.set_margin_end(10)

        if ap["kind"] == "wifi":
            meter = Gtk.Label()
            meter.set_markup(signal_markup(ap["signal"]))
            meter.add_css_class("net-meter")
            meter.set_size_request(34, -1)
            box.append(meter)
        else:
            icon = Gtk.Image.new_from_icon_name("network-wired-symbolic")
            icon.set_pixel_size(20)
            icon.set_size_request(34, -1)
            box.append(icon)

        names = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=1)
        names.set_hexpand(True)

        title = Gtk.Label(label=ap["label"], xalign=0.0)
        title.set_ellipsize(Pango.EllipsizeMode.END)
        title.add_css_class("net-name")
        if ap["active"]:
            title.add_css_class("net-active")
        names.append(title)

        bits = []
        if ap["active"]:
            bits.append("Connected")
        elif saved:
            bits.append("Saved")
        if ap["kind"] == "wifi":
            bits.append(ap["security"] or "Open")
            bits.append(f"{ap['signal']}%")
        sub = Gtk.Label(label="  ·  ".join(bits), xalign=0.0)
        sub.add_css_class("net-sub")
        names.append(sub)
        box.append(names)

        if ap["active"]:
            chk = Gtk.Image.new_from_icon_name("emblem-ok-symbolic")
            chk.add_css_class("net-check")
            box.append(chk)

        # Forget is offered only where it means something -- a network with no
        # stored profile has nothing to forget.
        if saved:
            btn = Gtk.Button(icon_name="user-trash-symbolic")
            btn.add_css_class("flat"); btn.add_css_class("row-forget")
            btn.set_valign(Gtk.Align.CENTER)
            btn.set_tooltip_text(f"Forget “{ap['ssid']}”")
            btn.connect("clicked", lambda *_: on_forget(ap))
            box.append(btn)

        self.set_child(box)


class Window(Adw.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="Networks")
        self.set_default_size(720, 620)
        self.busy = False

        header = Adw.HeaderBar()
        header.set_title_widget(Adw.WindowTitle(title="Networks"))

        self.wifi_switch = Gtk.Switch(valign=Gtk.Align.CENTER)
        self.wifi_switch.set_tooltip_text("Wi-Fi on/off")
        self.wifi_handler = self.wifi_switch.connect("state-set", self.on_wifi_toggle)
        header.pack_start(self.wifi_switch)

        self.rescan_btn = Gtk.Button(icon_name="view-refresh-symbolic")
        self.rescan_btn.set_tooltip_text("Rescan networks")
        self.rescan_btn.connect("clicked", lambda *_: self.rescan())
        header.pack_end(self.rescan_btn)

        editor = Gtk.Button(icon_name="preferences-system-symbolic")
        editor.set_tooltip_text("Open connection editor")
        editor.connect("clicked", self.on_editor)
        header.pack_end(editor)

        self.search = Gtk.SearchEntry(placeholder_text="Search networks…")
        self.search.set_margin_top(10); self.search.set_margin_bottom(6)
        self.search.set_margin_start(12); self.search.set_margin_end(12)
        self.search.connect("search-changed", lambda *_: self.listbox.invalidate_filter())

        self.listbox = Gtk.ListBox()
        self.listbox.set_selection_mode(Gtk.SelectionMode.BROWSE)
        self.listbox.add_css_class("net-list")
        self.listbox.set_filter_func(self._filter)
        self.listbox.connect("row-activated", self.on_activate)

        scroller = Gtk.ScrolledWindow(vexpand=True)
        scroller.set_child(self.listbox)
        scroller.set_margin_start(12); scroller.set_margin_end(12); scroller.set_margin_bottom(8)

        self.status = Gtk.Label(label="", xalign=0.5)
        self.status.add_css_class("status")
        self.status.set_margin_bottom(8)

        body = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        body.append(self.search); body.append(scroller); body.append(self.status)

        view = Adw.ToolbarView()
        view.add_top_bar(header)
        view.set_content(body)
        self.set_content(view)

        # Hide rather than destroy, so the resident process can show it again
        # instantly instead of rebuilding the whole widget tree.
        self.connect("close-request", lambda *_: (self.set_visible(False), True)[1])

        k = Gtk.EventControllerKey()
        k.connect("key-pressed", self._on_key)
        self.add_controller(k)

        self.reload()
        self.kick_rescan()

    # -- data ---------------------------------------------------------------
    def saved_names(self):
        _, out, _ = nmcli("-t", "-f", "NAME", "connection", "show")
        return {split_t(l)[0] for l in out.splitlines() if l}

    def reload(self):
        saved = self.saved_names()
        aps = []

        _, wifi_state, _ = nmcli("-t", "-f", "WIFI", "general")
        wifi_on = wifi_state.strip() == "enabled"
        self.wifi_switch.handler_block(self.wifi_handler)
        self.wifi_switch.set_active(wifi_on)
        self.wifi_switch.handler_unblock(self.wifi_handler)

        # Wired first: it is the connection you want when it exists.
        _, dev, _ = nmcli("-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device")
        for line in dev.splitlines():
            f = split_t(line)
            if len(f) >= 4 and f[1] == "ethernet" and f[2].startswith("connected"):
                aps.append(dict(kind="wired", ssid=f[3] or f[0], label=f[3] or f[0],
                                signal=0, security="", active=True, conn=f[3]))

        if wifi_on:
            # --rescan no reads NetworkManager's cache and returns in ~25ms;
            # letting nmcli decide makes it trigger a scan and BLOCK on it for
            # ~3.7s, which is what made opening this from the bar feel broken.
            #
            # The cache alone is not enough though: when it has gone stale this
            # returns almost nothing (one network, in testing). So the window
            # paints instantly from cache and kick_rescan() refreshes it a
            # moment later -- fast to appear, and correct shortly after.
            _, out, _ = nmcli("-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY",
                              "device", "wifi", "list", "--rescan", "no")
            seen = {}
            for line in out.splitlines():
                f = split_t(line)
                if len(f) < 4:
                    continue
                inuse, ssid, sig, sec = f[0], f[1], f[2], f[3]
                try:
                    sig = int(sig)
                except ValueError:
                    sig = 0
                # A blank SSID is a hidden network. The dmenu version rendered
                # these as a bare "WPA2" row with no name, which reads as a bug.
                label = ssid if ssid else "Hidden network"
                # Same SSID on 2.4 and 5GHz appears twice; keep the stronger.
                # Every hidden network collapses to ONE row: they are
                # indistinguishable by definition, so listing four of them is
                # four ways to open the same "type the SSID" dialog.
                key = ssid or "__hidden__"
                if key in seen and seen[key]["signal"] >= sig:
                    continue
                seen[key] = dict(kind="wifi", ssid=ssid, label=label, signal=sig,
                                 security=sec, active=(inuse == "*"), conn=ssid)
            aps.extend(sorted(seen.values(),
                              key=lambda a: (not a["active"], -a["signal"])))

        self.listbox.remove_all()
        self.rows = []
        for ap in aps:
            r = NetRow(ap, ap["ssid"] in saved, self.on_forget)
            self.rows.append(r); self.listbox.append(r)
        if self.rows:
            self.listbox.select_row(self.rows[0])

        active = next((a for a in aps if a["active"]), None)
        self.status.set_label(
            f"Connected to {active['label']}" if active
            else ("Wi-Fi is off" if not wifi_on else "Not connected"))

    def kick_rescan(self):
        """Refresh the AP list in the background, without blocking the window.

        Deliberately does NOT disable the list the way the Rescan button does:
        this fires on every open, and greying out the rows the user is reaching
        for would be worse than showing a slightly stale list for two seconds."""
        def work():
            nmcli("device", "wifi", "rescan", timeout=30)
            GLib.idle_add(self._quiet_reload)
        threading.Thread(target=work, daemon=True).start()

    def _quiet_reload(self):
        # Keep whatever the user has typed and whichever row they are on.
        row = self.listbox.get_selected_row()
        keep = row.ap["ssid"] if row else None
        self.reload()
        if keep:
            for r in self.rows:
                if r.ap["ssid"] == keep:
                    self.listbox.select_row(r); break
        return False

    def rescan(self):
        self.set_busy(True, "Scanning…")
        def work():
            nmcli("device", "wifi", "rescan", timeout=30)
            GLib.idle_add(self.after_work, None)
        threading.Thread(target=work, daemon=True).start()

    def after_work(self, msg):
        self.set_busy(False)
        self.reload()
        if msg:
            self.status.set_label(msg)
        return False

    def set_busy(self, on, text=""):
        self.busy = on
        self.rescan_btn.set_sensitive(not on)
        self.listbox.set_sensitive(not on)
        if text:
            self.status.set_label(text)

    def _filter(self, row):
        q = self.search.get_text().strip().lower()
        return q in row.search_text if q else True

    def _on_key(self, _c, keyval, *_):
        if keyval == Gdk.KEY_Escape:
            self.close(); return True
        return False

    # -- actions ------------------------------------------------------------
    def on_wifi_toggle(self, _sw, state):
        threading.Thread(target=lambda: (
            nmcli("radio", "wifi", "on" if state else "off"),
            GLib.idle_add(self.after_work, None)), daemon=True).start()
        return False

    def on_editor(self, *_):
        for cmd in (["nm-connection-editor"], ["kitty", "-e", "nmtui"]):
            if shutil.which(cmd[0]):
                subprocess.Popen(cmd); self.close(); return
        notify("Networks", "No connection editor found")

    def on_activate(self, _lb, row):
        ap = row.ap
        if ap["active"] or self.busy:
            return
        if ap["kind"] == "wired":
            return
        saved = ap["ssid"] in self.saved_names()
        secured = bool(ap["security"].strip())
        if ap["ssid"] and (saved or not secured):
            self.connect_to(ap, None)
        else:
            self.ask_password(ap)

    def ask_password(self, ap):
        d = Adw.AlertDialog(heading=f"Connect to {ap['label']}",
                            body=f"{ap['security'] or 'Open'} network")
        # placeholder-text must be set as a PROPERTY. Gtk.PasswordEntry has no
        # set_placeholder_text() -- unlike Gtk.Entry -- so calling it raised
        # AttributeError inside the row-activated handler. GTK swallows the
        # traceback into stderr and carries on, which is why clicking a network
        # appeared to do nothing at all rather than showing an error.
        entry = Gtk.PasswordEntry(show_peek_icon=True, placeholder_text="Password")
        entry.set_margin_top(8)
        ssid_entry = None
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        if not ap["ssid"]:
            ssid_entry = Gtk.Entry(placeholder_text="Network name (SSID)")
            box.append(ssid_entry)
        box.append(entry)
        d.set_extra_child(box)
        d.add_response("cancel", "Cancel")
        d.add_response("go", "Connect")
        d.set_response_appearance("go", Adw.ResponseAppearance.SUGGESTED)
        d.set_default_response("go")
        d.set_close_response("cancel")
        def resp(_d, r):
            if r != "go":
                return
            target = dict(ap)
            if ssid_entry and ssid_entry.get_text().strip():
                target["ssid"] = target["label"] = ssid_entry.get_text().strip()
            self.connect_to(target, entry.get_text())
        d.connect("response", resp)
        d.present(self)

    def connect_to(self, ap, password):
        if not ap["ssid"]:
            notify("Networks", "A network name is required"); return
        self.set_busy(True, f"Connecting to {ap['label']}…")
        def work():
            args = ["device", "wifi", "connect", ap["ssid"]]
            if password:
                args += ["password", password]
            rc, _, err = nmcli(*args, timeout=45)
            # nmcli prints the real reason (bad password, out of range) on
            # stderr; surfacing it beats a generic failure message.
            msg = f"Connected to {ap['label']}" if rc == 0 else (err.splitlines()[-1] if err else "Connection failed")
            if rc != 0:
                notify("Networks", msg)
            GLib.idle_add(self.after_work, msg)
        threading.Thread(target=work, daemon=True).start()

    def on_forget(self, ap):
        d = Adw.AlertDialog(heading=f"Forget {ap['label']}?",
                            body="The saved password and settings for this network are deleted.")
        d.add_response("cancel", "Cancel")
        d.add_response("go", "Forget")
        d.set_response_appearance("go", Adw.ResponseAppearance.DESTRUCTIVE)
        d.set_default_response("cancel")
        d.set_close_response("cancel")
        def resp(_d, r):
            if r != "go":
                return
            nmcli("connection", "delete", "id", ap["ssid"])
            self.reload()
        d.connect("response", resp)
        d.present(self)


CSS = b"""
window { background-color: #090C14; }
headerbar { background-color: #0F172A; border-bottom: 1px solid #1E293B; }
entry, passwordentry { background-color: #0F172A; color: #F8FAFC; border-radius: 10px; }
.net-list { background: transparent; }
.net-list > row {
    background: transparent;
    border-left: 3px solid transparent;
    border-radius: 8px;
    margin: 1px 0;
}
.net-list > row:hover { background-color: rgba(30,41,59,0.55); }
.net-list > row:selected { background-color: #172033; border-left-color: #38BDF8; }
.net-name   { color: #E2E8F0; font-size: 14px; }
.net-active { color: #38BDF8; font-weight: 700; }
.net-sub    { color: #64748B; font-size: 11px; }
.net-meter  { font-family: monospace; font-size: 15px; }
.net-check  { color: #22C55E; }
.row-forget { opacity: 0.38; min-width: 28px; min-height: 28px; }
.net-list > row:hover .row-forget,
.net-list > row:selected .row-forget { opacity: 0.85; }
.row-forget:hover { opacity: 1; color: #EF4444; }
.status { color: #475569; font-size: 11px; }
"""



# -----------------------------------------------------------------------------
# Resident mode
# -----------------------------------------------------------------------------
# A Python GTK4 process needs ~1.45s just to reach its first frame here -- that
# is the interpreter plus pygobject plus GTK init, measured with an empty
# window, so no amount of tuning inside this file removes it. Paying it on every
# click is what made the window feel like it opened "very very late".
#
# So the app is started once at login with --daemon: it registers on the bus,
# builds nothing, and waits. Opening it afterwards is
#   gapplication activate dev.cybernoir.X
# which costs ~119ms because it never starts a second interpreter.
#
# Closing the window hides it rather than quitting, so the second open is as
# fast as the first.
class App(Adw.Application):
    def __init__(self):
        super().__init__(application_id="dev.cybernoir.Networks")

    def do_startup(self):
        Adw.Application.do_startup(self)
        # A dedicated "open" action, rather than reusing activation.
        #
        # Activation cannot distinguish "start the daemon" from "show the
        # window": every launch of this script activates the primary instance,
        # so a plain `sway reload` -- which re-runs the autostart line -- would
        # have popped both windows open on screen. Separating them means the
        # daemon start is idempotent and only an explicit `open` shows anything.
        act = Gio.SimpleAction.new("open", None)
        act.connect("activate", lambda *_: self.show_window())
        self.add_action(act)

    def do_activate(self):
        if "--daemon" in sys.argv:
            self.hold()          # stay resident, show nothing
            return
        self.show_window()

    def show_window(self):
        Adw.StyleManager.get_default().set_color_scheme(Adw.ColorScheme.FORCE_DARK)
        prov = Gtk.CssProvider(); prov.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), prov, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        # See the note in clipboard-gui.py: without this, each activation built
        # a new window and repeated clicks stacked copies of the app.
        win = self.props.active_window
        if win is None:
            win = Window(self)
        else:
            # Clear the filter before reshowing. The window is hidden rather than
            # destroyed, so whatever was last typed survives -- and reopening to
            # a list filtered by a forgotten search term looks exactly like the
            # app failing to find anything.
            win.search.set_text("")
            win.reload()          # signal levels and state move constantly
        win.present()
        win.search.grab_focus()


if __name__ == "__main__":
    sys.exit(App().run(None))
