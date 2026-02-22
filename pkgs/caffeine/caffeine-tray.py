"""Caffeine systray indicator using raw StatusNotifierItem D-Bus protocol.

Registers as an SNI item so tray hosts (ironbar, waybar, etc.) can display it.
Left-click calls Activate which toggles caffeine on/off.
"""

import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import subprocess, socket, os, threading, signal

SOCK_PATH = f"/run/user/{os.getuid()}/caffeine.sock"
SNI_INTERFACE = "org.kde.StatusNotifierItem"
SNI_PATH = "/StatusNotifierItem"
MENU_INTERFACE = "com.canonical.dbusmenu"
MENU_PATH = "/MenuBar"

class CaffeineState:
    def __init__(self):
        self.active = False
        self.timer_source = None
        self.timer_remaining = 0

    def sync(self):
        try:
            r = subprocess.run(
                ["systemctl", "--user", "is-active", "hypridle"],
                capture_output=True, text=True,
            )
            self.active = r.returncode != 0
        except Exception:
            self.active = False

    def enable(self):
        self.cancel_timer()
        subprocess.run(["systemctl", "--user", "stop", "hypridle"], capture_output=True)
        self.active = True

    def disable(self):
        self.cancel_timer()
        subprocess.run(["systemctl", "--user", "start", "hypridle"], capture_output=True)
        self.active = False

    def toggle(self):
        if self.active:
            self.disable()
        else:
            self.enable()

    def timed(self, minutes):
        self.enable()
        self.timer_remaining = minutes
        self.timer_source = GLib.timeout_add_seconds(60, self._tick)

    def _tick(self):
        self.timer_remaining -= 1
        if self.timer_remaining <= 0:
            self.disable()
            self.timer_source = None
            return False
        return True

    def cancel_timer(self):
        if self.timer_source is not None:
            GLib.source_remove(self.timer_source)
            self.timer_source = None
        self.timer_remaining = 0

    @property
    def icon_name(self):
        return "caffeine-on" if self.active else "caffeine-off"

    @property
    def tooltip(self):
        if self.active:
            s = "Caffeine: ON"
            if self.timer_remaining > 0:
                s += f" ({self.timer_remaining}m left)"
            return s
        return "Caffeine: OFF"


class StatusNotifierItem(dbus.service.Object):
    def __init__(self, bus, state, notify_cb):
        self._state = state
        self._notify = notify_cb
        super().__init__(bus, SNI_PATH)

    # --- Methods ---
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

    # --- Signals ---
    @dbus.service.signal(SNI_INTERFACE, signature="")
    def NewIcon(self):
        pass

    @dbus.service.signal(SNI_INTERFACE, signature="")
    def NewTooltip(self):
        pass

    @dbus.service.signal(SNI_INTERFACE, signature="")
    def NewStatus(self, status):
        pass

    # --- Properties ---
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
            return "ApplicationStatus"
        elif prop == "Id":
            return "caffeine"
        elif prop == "Title":
            return "Caffeine"
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


class CaffeineMenu(dbus.service.Object):
    """Dbusmenu with toggle and timer options."""

    TIMERS = [(2, "15 minutes", 15), (3, "30 minutes", 30),
              (4, "1 hour", 60), (5, "2 hours", 120)]

    def __init__(self, bus, state, notify_cb):
        self._state = state
        self._notify = notify_cb
        self._revision = 1
        super().__init__(bus, MENU_PATH)

    def _bump(self):
        self._revision += 1
        self.LayoutUpdated(self._revision, 0)

    def _make_item(self, item_id, label, extra=None):
        props = dbus.Dictionary({
            "label": dbus.String(label),
            "visible": dbus.Boolean(True),
            "enabled": dbus.Boolean(True),
        }, signature="sv")
        if extra:
            props.update(extra)
        return dbus.Struct(
            (dbus.Int32(item_id), props, dbus.Array([], signature="v")),
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
        toggle_label = "Disable" if self._state.active else "Enable"
        toggle = self._make_item(1, toggle_label)
        sep = self._make_separator(10)
        timers = [self._make_item(tid, lbl) for tid, lbl, _ in self.TIMERS]
        children = dbus.Array([toggle, sep] + timers, signature="v")
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
        if item_id == 1:
            self._state.toggle()
            self._notify()
            self._bump()
        else:
            for tid, _, mins in self.TIMERS:
                if item_id == tid:
                    self._state.timed(mins)
                    self._notify()
                    self._bump()
                    break

    @dbus.service.signal(MENU_INTERFACE, signature="ui")
    def LayoutUpdated(self, revision, parent):
        pass


def register_sni(bus_name):
    """Register with the StatusNotifierWatcher."""
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


def socket_server(state, sni):
    """CLI command server."""
    try:
        os.unlink(SOCK_PATH)
    except FileNotFoundError:
        pass
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.bind(SOCK_PATH)
    sock.listen(5)
    while True:
        conn, _ = sock.accept()
        try:
            data = conn.recv(256).decode().strip()
            if data == "on":
                GLib.idle_add(lambda: (state.enable(), sni._notify()) and False)
                conn.sendall(b"OK\n")
            elif data == "off":
                GLib.idle_add(lambda: (state.disable(), sni._notify()) and False)
                conn.sendall(b"OK\n")
            elif data == "toggle":
                GLib.idle_add(lambda: (state.toggle(), sni._notify()) and False)
                conn.sendall(b"OK\n")
            elif data == "status":
                conn.sendall((state.tooltip + "\n").encode())
            elif data.isdigit():
                mins = int(data)
                GLib.idle_add(lambda: (state.timed(mins), sni._notify()) and False)
                conn.sendall(b"OK\n")
            else:
                conn.sendall(b"ERR\n")
        except Exception:
            pass
        finally:
            conn.close()


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    bus_name = dbus.service.BusName("org.kde.StatusNotifierItem-caffeine", bus)

    state = CaffeineState()
    state.sync()

    def notify():
        sni.NewIcon()
        sni.NewTooltip()

    sni = StatusNotifierItem(bus, state, notify)
    menu = CaffeineMenu(bus, state, notify)
    register_sni(bus_name.get_name())

    # Re-register when StatusNotifierWatcher reappears (e.g., tray host restart)
    bus.add_signal_receiver(
        lambda name, old, new: (
            register_sni(bus_name.get_name()) if new else None
        ),
        signal_name="NameOwnerChanged",
        dbus_interface="org.freedesktop.DBus",
        arg0="org.kde.StatusNotifierWatcher",
    )

    # Socket server for CLI
    t = threading.Thread(target=socket_server, args=(state, sni), daemon=True)
    t.start()

    # Clean shutdown
    loop = GLib.MainLoop()
    def shutdown(*_):
        try:
            os.unlink(SOCK_PATH)
        except FileNotFoundError:
            pass
        loop.quit()

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    loop.run()


if __name__ == "__main__":
    main()
