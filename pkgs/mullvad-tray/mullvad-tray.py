"""Mullvad VPN systray indicator using raw StatusNotifierItem D-Bus protocol.

Registers as an SNI item so tray hosts (ironbar, waybar, etc.) can display it.
Left-click calls Activate which toggles connect/disconnect.
Right-click menu shows status, location switching, and LAN sharing toggle.
"""

import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import subprocess, os, signal, json, re

SNI_INTERFACE = "org.kde.StatusNotifierItem"
SNI_PATH = "/StatusNotifierItem"
MENU_INTERFACE = "com.canonical.dbusmenu"
MENU_PATH = "/MenuBar"

STATE_DIR = os.path.expanduser("~/.local/state/mullvad-tray")
RECENT_FILE = os.path.join(STATE_DIR, "recent.json")
MAX_RECENT = 8


class MullvadState:
    def __init__(self):
        self.connected = False
        self.connecting = False
        self.relay = ""
        self.country = ""
        self.city = ""
        self.lan_allowed = True
        self.recent = []
        self.city_labels = {}  # (country_code, city_code) -> (country_name, city_name)
        self.countries = []  # [(code, name), ...] in relay list order
        self._parse_relay_list()
        self._load_recent()

    def _parse_relay_list(self):
        try:
            r = subprocess.run(["mullvad", "relay", "list"], capture_output=True, text=True)
            current_country = ("", "")
            for line in r.stdout.splitlines():
                m = re.match(r'^(\S.+?) \((\w+)\)', line)
                if m:
                    current_country = (m.group(2), m.group(1))
                    self.countries.append(current_country)
                    continue
                m = re.match(r'^\t(\S.+?) \((\w+)\)', line)
                if m:
                    city_code, city_name = m.group(2), m.group(1)
                    self.city_labels[(current_country[0], city_code)] = (current_country[1], city_name)
        except Exception:
            pass

    def _load_recent(self):
        try:
            with open(RECENT_FILE) as f:
                self.recent = json.load(f)
        except Exception:
            self.recent = []

    def _save_recent(self):
        os.makedirs(STATE_DIR, exist_ok=True)
        with open(RECENT_FILE, "w") as f:
            json.dump(self.recent, f)

    def _add_recent(self, country_code, city_code):
        entry = [country_code, city_code]
        if entry in self.recent:
            self.recent.remove(entry)
        self.recent.insert(0, entry)
        self.recent = self.recent[:MAX_RECENT]
        self._save_recent()

    def sync(self):
        try:
            r = subprocess.run(["mullvad", "status"], capture_output=True, text=True)
            self._parse_status(r.stdout)
        except Exception:
            pass
        try:
            r = subprocess.run(["mullvad", "lan", "get"], capture_output=True, text=True)
            self.lan_allowed = "allow" in r.stdout
        except Exception:
            pass

    def _parse_status(self, text):
        lines = text.strip().splitlines()
        if not lines:
            return
        first = lines[0].strip()
        if first.startswith("Connected"):
            self.connected = True
            self.connecting = "Reconnecting" in first
        elif first.startswith("Connecting"):
            self.connected = False
            self.connecting = True
        elif first.startswith("Disconnected"):
            self.connected = False
            self.connecting = False
            self.relay = ""
            self.country = ""
            self.city = ""
            return
        else:
            return  # ignore non-status lines (e.g. "Changed local network sharing setting")

        for line in lines[1:]:
            line = line.strip()
            if line.startswith("Relay:"):
                self.relay = line.split(":", 1)[1].strip()
            elif line.startswith("Visible location:"):
                loc = line.split(":", 1)[1].strip()
                loc = loc.split(". ")[0]  # strip "IPv4: ..." suffix
                parts = [p.strip() for p in loc.split(",", 1)]
                self.country = parts[0] if parts else ""
                self.city = parts[1] if len(parts) > 1 else ""

    def _current_location_codes(self):
        """Derive country/city codes from relay name (e.g. nl-ams-wg-003 -> nl, ams)."""
        if self.relay:
            parts = self.relay.split("-")
            if len(parts) >= 2:
                return parts[0], parts[1]
        return None, None

    def toggle(self):
        if self.connected or self.connecting:
            self.disconnect()
        else:
            self.connect()

    def connect(self):
        subprocess.Popen(["mullvad", "connect"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def disconnect(self):
        subprocess.Popen(["mullvad", "disconnect"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def set_location(self, country_code, city_code=None):
        cmd = ["mullvad", "relay", "set", "location", country_code]
        if city_code:
            cmd.append(city_code)
        subprocess.run(cmd, capture_output=True)
        if city_code:
            self._add_recent(country_code, city_code)
        self.connect()

    def toggle_lan(self):
        new = "block" if self.lan_allowed else "allow"
        subprocess.run(["mullvad", "lan", "set", new], capture_output=True)
        self.lan_allowed = not self.lan_allowed

    @property
    def icon_name(self):
        if self.connected and not self.connecting:
            return "mullvad-connected"
        elif self.connecting:
            return "mullvad-connecting"
        return "mullvad-disconnected"

    @property
    def tooltip(self):
        if self.connected:
            s = f"Mullvad: Connected ({self.relay})" if self.relay else "Mullvad: Connected"
            if self.country:
                loc = self.country
                if self.city:
                    loc += f", {self.city}"
                s += f"\n{loc}"
            return s
        elif self.connecting:
            return "Mullvad: Connecting..."
        return "Mullvad: Disconnected"

    def location_label(self, country_code, city_code):
        key = (country_code, city_code)
        if key in self.city_labels:
            country_name, city_name = self.city_labels[key]
            return f"{city_name}, {country_name}"
        return f"{city_code}, {country_code}"


class StatusNotifierItem(dbus.service.Object):
    def __init__(self, bus, state, notify_cb):
        self._state = state
        self._notify = notify_cb
        super().__init__(bus, SNI_PATH)

    @dbus.service.method(SNI_INTERFACE, in_signature="ii")
    def Activate(self, x, y):
        self._state.toggle()
        self._notify()

    @dbus.service.method(SNI_INTERFACE, in_signature="ii")
    def SecondaryActivate(self, x, y):
        pass

    @dbus.service.method(SNI_INTERFACE, in_signature="is")
    def ContextMenu(self, x, y):
        pass

    @dbus.service.method(SNI_INTERFACE, in_signature="io")
    def Scroll(self, delta, orientation):
        pass

    @dbus.service.signal(SNI_INTERFACE, signature="")
    def NewIcon(self):
        pass

    @dbus.service.signal(SNI_INTERFACE, signature="")
    def NewTooltip(self):
        pass

    @dbus.service.signal(SNI_INTERFACE, signature="")
    def NewStatus(self, status):
        pass

    @dbus.service.method(dbus.PROPERTIES_IFACE, in_signature="ss", out_signature="v")
    def Get(self, interface, prop):
        return self._get_prop(prop)

    @dbus.service.method(dbus.PROPERTIES_IFACE, in_signature="s", out_signature="a{sv}")
    def GetAll(self, interface):
        props = [
            "Category", "Id", "Title", "Status", "IconName",
            "IconThemePath", "ToolTip", "ItemIsMenu", "Menu",
        ]
        return {p: self._get_prop(p) for p in props}

    def _get_prop(self, prop):
        if prop == "Category":
            return "SystemServices"
        elif prop == "Id":
            return "mullvad-tray"
        elif prop == "Title":
            return "Mullvad VPN"
        elif prop == "Status":
            return "Active"
        elif prop == "IconName":
            return self._state.icon_name
        elif prop == "IconThemePath":
            return os.environ.get("ICON_THEME_PATH", "")
        elif prop == "IconPixmap":
            return dbus.Array([], signature="(iiay)")
        elif prop == "ToolTip":
            return ("", dbus.Array([], signature="(iiay)"),
                    self._state.tooltip, "")
        elif prop == "ItemIsMenu":
            return False
        elif prop == "Menu":
            return dbus.ObjectPath(MENU_PATH)
        return ""


class MullvadMenu(dbus.service.Object):
    TOGGLE = 1
    SEP1 = 10
    STATUS = 11
    LOCATION = 12
    SEP2 = 20
    SWITCH_LOCATION = 30
    LAN_TOGGLE = 40
    RECENT_BASE = 100
    RECENT_SEP = 99
    COUNTRY_BASE = 1000

    def __init__(self, bus, state, notify_cb):
        self._state = state
        self._notify = notify_cb
        self._revision = 1
        self._country_id_map = {}  # item_id -> country_code
        for i, (code, _) in enumerate(self._state.countries):
            self._country_id_map[self.COUNTRY_BASE + i] = code
        super().__init__(bus, MENU_PATH)

    def _bump(self):
        self._revision += 1
        self.LayoutUpdated(self._revision, 0)

    def _make_item(self, item_id, label, extra=None, children=None):
        props = dbus.Dictionary({
            "label": dbus.String(label),
            "visible": dbus.Boolean(True),
            "enabled": dbus.Boolean(True),
        }, signature="sv")
        if extra:
            props.update(extra)
        kids = dbus.Array(children or [], signature="v")
        return dbus.Struct(
            (dbus.Int32(item_id), props, kids),
            signature=None)

    def _make_separator(self, item_id):
        props = dbus.Dictionary({
            "type": dbus.String("separator"),
            "enabled": dbus.Boolean(True),
        }, signature="sv")
        return dbus.Struct(
            (dbus.Int32(item_id), props, dbus.Array([], signature="v")),
            signature=None)

    @dbus.service.method(MENU_INTERFACE, in_signature="iias", out_signature="u(ia{sv}av)")
    def GetLayout(self, parent_id, recursion_depth, property_names):
        s = self._state

        toggle_label = "Disconnect" if s.connected else "Connect"
        toggle = self._make_item(self.TOGGLE, toggle_label)
        sep1 = self._make_separator(self.SEP1)

        if s.connected:
            status_label = f"Status: Connected ({s.relay})" if s.relay else "Status: Connected"
        elif s.connecting:
            status_label = "Status: Connecting..."
        else:
            status_label = "Status: Disconnected"
        status = self._make_item(self.STATUS, status_label, {"enabled": dbus.Boolean(False)})

        loc_parts = []
        if s.country:
            loc_parts.append(s.country)
        if s.city:
            loc_parts.append(s.city)
        loc_label = "Location: " + ", ".join(loc_parts) if loc_parts else "Location: \u2014"
        location = self._make_item(self.LOCATION, loc_label, {"enabled": dbus.Boolean(False)})
        sep2 = self._make_separator(self.SEP2)

        switch_children = []
        for i, entry in enumerate(s.recent):
            label = s.location_label(entry[0], entry[1])
            switch_children.append(self._make_item(self.RECENT_BASE + i, label))
        if s.recent:
            switch_children.append(self._make_separator(self.RECENT_SEP))
        for ci, (country_code, country_name) in enumerate(s.countries):
            switch_children.append(self._make_item(self.COUNTRY_BASE + ci, country_name))
        switch_loc = self._make_item(
            self.SWITCH_LOCATION, "Switch Location",
            {"children-display": dbus.String("submenu")}, switch_children)

        lan_label = "LAN Sharing: Allowed" if s.lan_allowed else "LAN Sharing: Blocked"
        lan_toggle = self._make_item(self.LAN_TOGGLE, lan_label)

        children = dbus.Array([toggle, sep1, status, location, sep2, switch_loc, lan_toggle], signature="v")
        root = dbus.Struct(
            (dbus.Int32(0), dbus.Dictionary({}, signature="sv"), children),
            signature=None)
        return (dbus.UInt32(self._revision), root)

    @dbus.service.method(MENU_INTERFACE, in_signature="aias", out_signature="a(ia{sv})")
    def GetGroupProperties(self, ids, property_names):
        return dbus.Array([], signature="(ia{sv})")

    @dbus.service.method(MENU_INTERFACE, in_signature="isvu", out_signature="")
    def Event(self, item_id, event_id, data, timestamp):
        if event_id != "clicked":
            return
        if item_id == self.TOGGLE:
            self._state.toggle()
            self._notify()
            self._bump()
        elif item_id == self.LAN_TOGGLE:
            self._state.toggle_lan()
            self._notify()
            self._bump()
        elif self.RECENT_BASE <= item_id < self.RECENT_BASE + len(self._state.recent):
            idx = item_id - self.RECENT_BASE
            entry = self._state.recent[idx]
            self._state.set_location(entry[0], entry[1])
            self._notify()
            self._bump()
        elif item_id in self._country_id_map:
            self._state.set_location(self._country_id_map[item_id])
            self._notify()
            self._bump()

    @dbus.service.signal(MENU_INTERFACE, signature="ui")
    def LayoutUpdated(self, revision, parent):
        pass


class StatusListener:
    """Watches `mullvad status listen` for real-time state updates."""

    def __init__(self, state, notify_cb, menu):
        self._state = state
        self._notify = notify_cb
        self._menu = menu
        self._proc = None
        self._buf = ""
        self._block = []
        self._debounce = None
        self._start()

    def _start(self):
        self._proc = subprocess.Popen(
            ["mullvad", "status", "listen"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
        self._buf = ""
        GLib.io_add_watch(
            self._proc.stdout.fileno(),
            GLib.IO_IN | GLib.IO_HUP | GLib.IO_ERR,
            self._on_data,
        )

    def _on_data(self, fd, condition):
        if condition & GLib.IO_IN:
            data = os.read(fd, 4096)
            if data:
                self._buf += data.decode(errors="replace")
                self._process_lines()
                return True
        self._proc.wait()
        GLib.timeout_add_seconds(1, self._restart)
        return False

    def _restart(self):
        self._start()
        return False

    def _process_lines(self):
        lines = self._buf.split("\n")
        if not self._buf.endswith("\n"):
            self._buf = lines[-1]
            lines = lines[:-1]
        else:
            self._buf = ""

        for line in lines:
            if not line.strip():
                continue
            # Non-indented line = new status block start
            if not line.startswith(" ") and not line.startswith("\t"):
                if self._block:
                    self._flush()
                self._block = [line]
            else:
                self._block.append(line)

        # Debounce: wait for detail lines that may arrive in next chunk
        if self._block:
            if self._debounce:
                GLib.source_remove(self._debounce)
            self._debounce = GLib.timeout_add(150, self._flush)

    def _flush(self):
        self._debounce = None
        if self._block:
            self._handle_block(self._block)
            self._block = []
        return False

    def _handle_block(self, lines):
        self._state._parse_status("\n".join(lines))
        # Track current location in recents when connected
        if self._state.connected and self._state.relay:
            cc, city = self._state._current_location_codes()
            if cc and city:
                self._state._add_recent(cc, city)
        self._notify()
        self._menu._bump()


def register_sni(bus_name):
    try:
        watcher = dbus.SessionBus().get_object(
            "org.kde.StatusNotifierWatcher",
            "/StatusNotifierWatcher",
        )
        watcher.RegisterStatusNotifierItem(
            bus_name,
            dbus_interface="org.kde.StatusNotifierWatcher",
        )
    except dbus.DBusException as e:
        print(f"Warning: could not register with SNI watcher: {e}")


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    bus_name = dbus.service.BusName("org.kde.StatusNotifierItem-mullvad-tray", bus)

    state = MullvadState()
    state.sync()

    def notify():
        sni.NewIcon()
        sni.NewTooltip()

    sni = StatusNotifierItem(bus, state, notify)
    menu = MullvadMenu(bus, state, notify)
    register_sni(bus_name.get_name())

    bus.add_signal_receiver(
        lambda name, old, new: (
            register_sni(bus_name.get_name()) if new else None
        ),
        signal_name="NameOwnerChanged",
        dbus_interface="org.freedesktop.DBus",
        arg0="org.kde.StatusNotifierWatcher",
    )

    listener = StatusListener(state, notify, menu)

    loop = GLib.MainLoop()

    def shutdown(*_):
        if listener._proc:
            listener._proc.terminate()
        loop.quit()

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    loop.run()


if __name__ == "__main__":
    main()
