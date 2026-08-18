#!/usr/bin/env python3
# =============================================================================
# CYBER NOIR // CLIPBOARD MANAGER  (GTK4 + libadwaita)
# =============================================================================
# Replaces the wofi picker.
#
# Why a real application instead of more wofi styling
# -----------------------------------------------------------------------------
# wofi is a dmenu: a search box and a flat list of rows. It has no header bar,
# no per-row widgets, and the only click target is an entire row. "Put the
# actions in the top right" and "give every row its own delete button" are not
# theming problems there -- they are outside what the tool can express at all.
# So the actions stopped being list entries, which is what they always were:
# rows that looked like clipboard history but were not.
#
# Everything the wofi version learned is preserved: paste on select with the
# right shortcut per application, backup before any destructive action, bounded
# and cached thumbnails, and focus sampled before this window ever maps.
# =============================================================================
import os, re, shutil, subprocess, sys, threading, time
from datetime import datetime
from pathlib import Path

import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gdk, GLib, Gtk, Pango

CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
DB = CACHE / "cliphist" / "db"
BACKUPS = CACHE / "cliphist" / "backups"
THUMBS = CACHE / "cyber-noir-clipthumbs"
THUMB_PX = 44
THUMB_LIMIT = 40          # newest N image rows get a preview; see build note below
BACKUP_KEEP = 5

# Terminals bind Ctrl+Shift+V; everything else uses Ctrl+V. Sending the wrong one
# does nothing at best and fires an unrelated binding at worst.
TERMINALS = {
    "kitty", "foot", "Alacritty", "alacritty", "org.wezfurlong.wezterm",
    "com.mitchellh.ghostty", "ghostty", "xterm", "URxvt", "st",
    "org.kde.konsole", "dev.warp.Warp",
}

BINARY_RE = re.compile(r"binary data .*(png|jpe?g|gif|webp|bmp)", re.I)


def sh(cmd, **kw):
    """Run a command, returning stdout as text. Never raises on failure."""
    try:
        return subprocess.run(cmd, capture_output=True, text=True, **kw).stdout
    except Exception:
        return ""


def notify(title, body=""):
    if shutil.which("notify-send"):
        subprocess.Popen(["notify-send", "-t", "2500", title, body])


def focused_app():
    """The app that had focus BEFORE this window mapped -- that is what a paste
    has to be aimed at. Called at startup for exactly that reason."""
    if not shutil.which("jq"):
        return ""
    out = sh(["swaymsg", "-t", "get_tree"])
    if not out:
        return ""
    try:
        import json
        def walk(n):
            yield n
            for k in ("nodes", "floating_nodes"):
                for c in n.get(k, []) or []:
                    yield from walk(c)
        for n in walk(json.loads(out)):
            if n.get("focused"):
                return n.get("app_id") or (n.get("window_properties") or {}).get("class") or ""
    except Exception:
        pass
    return ""


def cliphist_list():
    """[(id, preview_text, raw_line)] newest first."""
    rows = []
    for line in sh(["cliphist", "-preview-width", "160", "list"]).splitlines():
        if "\t" not in line:
            continue
        cid, preview = line.split("\t", 1)
        if cid.isdigit():
            rows.append((cid, preview, line))
    return rows


def backup_db():
    """A copy of the single db file is a complete backup. Returns its path."""
    if not DB.exists() or DB.stat().st_size == 0:
        return None
    BACKUPS.mkdir(parents=True, exist_ok=True)
    dest = BACKUPS / f"db-{datetime.now():%Y%m%d-%H%M%S}"
    try:
        shutil.copyfile(DB, dest)
    except OSError:
        return None
    keep = sorted(BACKUPS.glob("db-*"), key=lambda p: p.stat().st_mtime, reverse=True)
    for old in keep[BACKUP_KEEP:]:
        old.unlink(missing_ok=True)
    return dest


def latest_backup():
    b = sorted(BACKUPS.glob("db-*"), key=lambda p: p.stat().st_mtime, reverse=True)
    return b[0] if b else None


class Row(Gtk.ListBoxRow):
    def __init__(self, cid, preview, raw, on_delete):
        super().__init__()
        self.cid, self.preview, self.raw = cid, preview, raw
        self.search_text = preview.lower()

        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        box.set_margin_top(6); box.set_margin_bottom(6)
        box.set_margin_start(10); box.set_margin_end(8)

        # Fixed-size slot whether or not a thumbnail ever arrives, so the id
        # column cannot shift between image and text rows.
        self.thumb = Gtk.Image()
        self.thumb.set_pixel_size(THUMB_PX)
        self.thumb.set_size_request(THUMB_PX, THUMB_PX)
        box.append(self.thumb)

        lbl_id = Gtk.Label(label=cid, xalign=0.0)
        lbl_id.add_css_class("entry-id")
        lbl_id.set_size_request(52, -1)
        box.append(lbl_id)

        lbl = Gtk.Label(label=preview.strip() or "(empty)", xalign=0.0)
        lbl.set_ellipsize(Pango.EllipsizeMode.END)
        lbl.set_hexpand(True)
        lbl.add_css_class("entry-text")
        box.append(lbl)

        # Per-row delete. Everything copied lands in this store, passwords
        # included; removing one should not mean destroying the rest.
        btn = Gtk.Button(icon_name="user-trash-symbolic")
        btn.add_css_class("flat")
        btn.add_css_class("row-delete")
        btn.set_valign(Gtk.Align.CENTER)
        btn.set_tooltip_text("Delete this entry")
        btn.connect("clicked", lambda *_: on_delete(self))
        box.append(btn)

        self.set_child(box)

    def set_thumb(self, path):
        self.thumb.set_from_file(str(path))


class Window(Adw.ApplicationWindow):
    def __init__(self, app, target_app):
        super().__init__(application=app, title="Clipboard")
        self.target_app = target_app
        self.set_default_size(900, 620)

        header = Adw.HeaderBar()
        header.set_title_widget(Adw.WindowTitle(title="Clipboard"))

        def hbtn(icon, tip, cb, *classes):
            b = Gtk.Button(icon_name=icon)
            b.set_tooltip_text(tip)
            b.connect("clicked", cb)
            for c in classes:
                b.add_css_class(c)
            return b

        # Top-right actions, in ascending order of consequence.
        header.pack_end(hbtn("user-trash-full-symbolic", "Clear all history",
                             self.on_clear, "destructive-action"))
        header.pack_end(hbtn("edit-undo-symbolic", "Restore last backup", self.on_restore))
        header.pack_end(hbtn("camera-photo-symbolic", "Screenshot a region to clipboard",
                             self.on_shot))

        self.search = Gtk.SearchEntry(placeholder_text="Search clipboard…")
        self.search.set_margin_top(10); self.search.set_margin_bottom(6)
        self.search.set_margin_start(12); self.search.set_margin_end(12)
        self.search.connect("search-changed", lambda *_: self.listbox.invalidate_filter())

        self.listbox = Gtk.ListBox()
        self.listbox.set_selection_mode(Gtk.SelectionMode.BROWSE)
        self.listbox.add_css_class("clip-list")
        self.listbox.set_filter_func(self._filter)
        self.listbox.connect("row-activated", self.on_activate)

        scroller = Gtk.ScrolledWindow(vexpand=True)
        scroller.set_child(self.listbox)
        scroller.set_margin_start(12); scroller.set_margin_end(12)
        scroller.set_margin_bottom(12)

        self.status = Gtk.Label(label="")
        self.status.add_css_class("status")
        self.status.set_margin_bottom(8)

        body = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        body.append(self.search); body.append(scroller); body.append(self.status)

        view = Adw.ToolbarView()
        view.add_top_bar(header)
        view.set_content(body)
        self.set_content(view)

        esc = Gtk.EventControllerKey()
        esc.connect("key-pressed", self._on_key)
        self.add_controller(esc)

        self.reload()

    # -- data ---------------------------------------------------------------
    def reload(self):
        self.listbox.remove_all()
        self.rows = []
        entries = cliphist_list()
        for cid, preview, raw in entries:
            r = Row(cid, preview, raw, self.delete_row)
            self.rows.append(r)
            self.listbox.append(r)
        self.status.set_label(f"{len(entries)} entr" + ("y" if len(entries)==1 else "ies"))
        if self.rows:
            self.listbox.select_row(self.rows[0])
        # Thumbnails are decoded off the main loop: ~47ms each means a full
        # history would freeze the window for half a minute before it drew.
        threading.Thread(target=self._thumbs, args=(list(self.rows),), daemon=True).start()

    def _thumbs(self, rows):
        if not shutil.which("magick"):
            return
        THUMBS.mkdir(parents=True, exist_ok=True)
        made = 0
        for r in rows:
            if made >= THUMB_LIMIT:
                break
            if not BINARY_RE.search(r.preview):
                continue
            path = THUMBS / f"{r.cid}.png"
            if not path.exists() or path.stat().st_size == 0:
                try:
                    # BYTES, not text. These entries are PNG/JPEG payloads, and
                    # decoding them as UTF-8 either mangles the image or throws,
                    # which is why no thumbnail ever appeared.
                    dec = subprocess.run(["cliphist", "decode"],
                                         input=r.raw.encode(), capture_output=True)
                    if not dec.stdout:
                        continue
                    subprocess.run(["magick", "-", "-thumbnail",
                                    f"{THUMB_PX}x{THUMB_PX}", str(path)],
                                   input=dec.stdout, capture_output=True)
                except Exception:
                    continue
            if path.exists() and path.stat().st_size:
                made += 1
                GLib.idle_add(r.set_thumb, path)

    def _filter(self, row):
        q = self.search.get_text().strip().lower()
        return q in row.search_text if q else True

    def _on_key(self, _c, keyval, *_):
        if keyval == Gdk.KEY_Escape:
            self.close()
            return True
        return False

    # -- actions ------------------------------------------------------------
    def on_activate(self, _lb, row):
        # Binary-safe end to end: an image entry has to reach wl-copy byte for
        # byte, and its MIME type has to be declared or it lands as garbled text.
        dec = subprocess.run(["cliphist", "decode"], input=row.raw.encode(),
                             capture_output=True)
        payload = dec.stdout
        if not payload:
            self.close(); return
        args = ["wl-copy"]
        if BINARY_RE.search(row.preview):
            m = re.search(r"(png|jpe?g|gif|webp|bmp)", row.preview, re.I)
            fmt = m.group(1).lower() if m else "png"
            args += ["--type", f"image/{'jpeg' if fmt in ('jpg','jpeg') else fmt}"]
        subprocess.run(args, input=payload)
        self.close()
        if shutil.which("wtype"):
            # Let sway hand focus back before typing into a surface that is
            # still being torn down.
            def paste():
                time.sleep(0.18)
                if self.target_app in TERMINALS:
                    subprocess.run(["wtype", "-M", "ctrl", "-M", "shift", "-k", "v",
                                    "-m", "shift", "-m", "ctrl"])
                elif self.target_app:
                    subprocess.run(["wtype", "-M", "ctrl", "-k", "v", "-m", "ctrl"])
            threading.Thread(target=paste, daemon=True).start()

    def delete_row(self, row):
        subprocess.run(["cliphist", "delete"], input=row.raw, text=True,
                       capture_output=True)
        (THUMBS / f"{row.cid}.png").unlink(missing_ok=True)
        self.listbox.remove(row)
        self.rows = [r for r in self.rows if r is not row]
        self.status.set_label(f"{len(self.rows)} entr" + ("y" if len(self.rows)==1 else "ies"))

    def _confirm(self, heading, body, verb, cb, destructive=True):
        d = Adw.AlertDialog(heading=heading, body=body)
        d.add_response("cancel", "Cancel")
        d.add_response("go", verb)
        d.set_response_appearance("go", Adw.ResponseAppearance.DESTRUCTIVE
                                  if destructive else Adw.ResponseAppearance.SUGGESTED)
        # The safe answer is the default and the escape route, so neither Enter
        # nor Escape can destroy anything.
        d.set_default_response("cancel")
        d.set_close_response("cancel")
        d.connect("response", lambda _d, resp: cb() if resp == "go" else None)
        d.present(self)

    def on_clear(self, *_):
        n = len(self.rows)
        if not n:
            notify("Clipboard", "History is already empty")
            return
        def go():
            b = backup_db()
            subprocess.run(["cliphist", "wipe"], capture_output=True)
            for f in THUMBS.glob("*.png"):
                f.unlink(missing_ok=True)
            self.reload()
            notify("Clipboard", f"Cleared {n} entries" +
                   (" — restorable" if b else " (backup failed)"))
        self._confirm("Clear clipboard history?",
                      f"All {n} entries will be removed. A backup is saved first "
                      f"and can be restored from this window.", "Clear all", go)

    def on_restore(self, *_):
        b = latest_backup()
        if not b:
            notify("Clipboard", "No backup to restore")
            return
        when = b.name.removeprefix("db-")
        def go():
            backup_db()          # restoring is itself reversible
            try:
                shutil.copyfile(b, DB)
            except OSError:
                notify("Clipboard", "Restore failed"); return
            self.reload()
            notify("Clipboard", f"Restored {len(self.rows)} entries")
        self._confirm("Restore clipboard backup?",
                      f"Replaces the current history with the backup from {when}. "
                      f"The current history is backed up first.",
                      "Restore", go, destructive=False)

    def on_shot(self, *_):
        self.close()
        subprocess.Popen([str(Path.home() / ".config/sway/scripts/screenshot.sh"), "copy"])


CSS = b"""
window { background-color: #090C14; }
headerbar { background-color: #0F172A; border-bottom: 1px solid #1E293B; }
entry { background-color: #0F172A; color: #F8FAFC; border-radius: 10px; }
.clip-list { background: transparent; }
.clip-list > row {
    background: transparent;
    border-left: 3px solid transparent;
    border-radius: 8px;
    margin: 1px 0;
}
.clip-list > row:hover { background-color: rgba(30,41,59,0.55); }
.clip-list > row:selected {
    background-color: #172033;
    border-left-color: #38BDF8;
}
.entry-id   { color: #475569; font-family: monospace; font-size: 12px; }
.entry-text { color: #94A3B8; font-family: monospace; font-size: 13px; }
.clip-list > row:selected .entry-text { color: #F8FAFC; font-weight: 600; }
/* Visible on every row, not only the hovered one -- a delete you have to
   discover by hovering is a delete most people never find. Dimmed at rest so a
   column of them does not compete with the content. */
.row-delete { opacity: 0.38; min-width: 28px; min-height: 28px; }
.clip-list > row:hover .row-delete,
.clip-list > row:selected .row-delete { opacity: 0.85; }
.row-delete:hover { opacity: 1; color: #EF4444; }
.status { color: #475569; font-size: 11px; }
"""


class App(Adw.Application):
    def __init__(self):
        super().__init__(application_id="dev.cybernoir.Clipboard")
        self.target_app = focused_app()

    def do_activate(self):
        Adw.StyleManager.get_default().set_color_scheme(Adw.ColorScheme.FORCE_DARK)
        prov = Gtk.CssProvider()
        prov.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), prov, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        Window(self, self.target_app).present()


if __name__ == "__main__":
    sys.exit(App().run(None))
