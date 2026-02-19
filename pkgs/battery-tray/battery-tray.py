"""Power menu systray applet using StatusNotifierItem D-Bus protocol.

Shows a power icon in the tray with right-click menu for Lock, Suspend,
Reboot, and Shutdown.
"""

import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import signal, subprocess

SNI_INTERFACE = "org.kde.StatusNotifierItem"
SNI_PATH = "/StatusNotifierItem"
MENU_INTERFACE = "com.canonical.dbusmenu"
MENU_PATH = "/MenuBar"


class StatusNotifierItem(dbus.service.Object):
    def __init__(self, bus):
        super().__init__(bus, SNI_PATH)

    @dbus.service.method(SNI_INTERFACE, in_signature="ii")
    def Activate(self, x, y):
        pass

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
    def NewTitle(self):
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
            "ToolTip", "ItemIsMenu", "Menu",
        ]
        return {p: self._get_prop(p) for p in props}

    def _get_prop(self, prop):
        if prop == "Category":
            return "SystemServices"
        elif prop == "Id":
            return "power-menu"
        elif prop == "Title":
            return "Power"
        elif prop == "Status":
            return "Active"
        elif prop == "IconName":
            return "power"
        elif prop == "IconPixmap":
            return dbus.Array([], signature="(iiay)")
        elif prop == "ToolTip":
            return ("", dbus.Array([], signature="(iiay)"),
                    "Power actions", "")
        elif prop == "ItemIsMenu":
            return False
        elif prop == "Menu":
            return dbus.ObjectPath(MENU_PATH)
        return ""


class PowerMenu(dbus.service.Object):
    ITEMS = [
        (1, "Lock"),
        (2, "Suspend"),
        (10, None),  # separator
        (3, "Reboot"),
        (4, "Shutdown"),
    ]

    def __init__(self, bus):
        self._revision = 1
        super().__init__(bus, MENU_PATH)

    def _make_item(self, item_id, label, extra=None):
        props = dbus.Dictionary({
            "label": dbus.String(label or ""),
            "visible": dbus.Boolean(True),
            "enabled": dbus.Boolean(True),
        }, signature="sv")
        if extra:
            props.update(extra)
        return dbus.Struct(
            (dbus.Int32(item_id), props, dbus.Array([], signature="v")),
            signature=None)

    @dbus.service.method(MENU_INTERFACE, in_signature="iias", out_signature="u(ia{sv}av)")
    def GetLayout(self, parent_id, recursion_depth, property_names):
        children = []
        for item_id, label in self.ITEMS:
            if label is None:
                children.append(self._make_item(item_id, "", {"type": dbus.String("separator")}))
            else:
                children.append(self._make_item(item_id, label))
        root = dbus.Struct(
            (dbus.Int32(0), dbus.Dictionary({}, signature="sv"),
             dbus.Array(children, signature="v")),
            signature=None)
        return (dbus.UInt32(self._revision), root)

    @dbus.service.method(MENU_INTERFACE, in_signature="aias", out_signature="a(ia{sv})")
    def GetGroupProperties(self, ids, property_names):
        return dbus.Array([], signature="(ia{sv})")

    @dbus.service.method(MENU_INTERFACE, in_signature="isvu", out_signature="")
    def Event(self, item_id, event_id, data, timestamp):
        if event_id != "clicked":
            return
        actions = {
            1: ["hyprlock"],
            2: ["systemctl", "suspend"],
            3: ["systemctl", "reboot"],
            4: ["systemctl", "poweroff"],
        }
        cmd = actions.get(item_id)
        if cmd:
            subprocess.Popen(cmd)

    @dbus.service.signal(MENU_INTERFACE, signature="ui")
    def LayoutUpdated(self, revision, parent):
        pass


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
    bus_name = dbus.service.BusName("org.kde.StatusNotifierItem-power-menu", bus)

    sni = StatusNotifierItem(bus)
    menu = PowerMenu(bus)
    register_sni(bus_name.get_name())

    bus.add_signal_receiver(
        lambda name, old, new: (
            register_sni(bus_name.get_name()) if new else None
        ),
        signal_name="NameOwnerChanged",
        dbus_interface="org.freedesktop.DBus",
        arg0="org.kde.StatusNotifierWatcher",
    )

    loop = GLib.MainLoop()

    def shutdown(*_):
        loop.quit()

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    loop.run()


if __name__ == "__main__":
    main()
