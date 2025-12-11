#!/usr/bin/env -S uv run --script --quiet
"""Toggle macOS system proxy settings on/off."""
# /// script
# dependencies = [
#   "sh",
# ]
# ///


import argparse
import sys
from sh import networksetup, ErrorReturnCode

DEFAULT_INTERFACES = ["Wi-Fi", "USB 10/100/1000 LAN"]
DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = "8080"

def interface_exists(interface):
    """Check if a network interface exists."""
    try:
        networksetup.getinfo(interface)
        return True
    except ErrorReturnCode:
        return False

def enable_proxy(interfaces, host, port):
    """Enable proxy on specified interfaces."""
    for interface in interfaces:
        if interface_exists(interface):
            print(f"Enabling proxy on {interface}...")
            networksetup.setwebproxy(interface, host, port)
            networksetup.setsecurewebproxy(interface, host, port)
            networksetup.setwebproxystate(interface, "on")
            networksetup.setsecurewebproxystate(interface, "on")
        else:
            print(f"Warning: Interface {interface} does not exist, skipping...")
    print("Proxy enabled")

def disable_proxy(interfaces):
    """Disable proxy on specified interfaces."""
    for interface in interfaces:
        if interface_exists(interface):
            print(f"Disabling proxy on {interface}...")
            networksetup.setwebproxystate(interface, "off")
            networksetup.setsecurewebproxystate(interface, "off")
        else:
            print(f"Warning: Interface {interface} does not exist, skipping...")
    print("Proxy disabled")

def show_status(interfaces):
    """Show proxy status for specified interfaces."""
    for interface in interfaces:
        print(f"Status for {interface}:")
        if interface_exists(interface):
            print("HTTP Proxy:")
            print(networksetup.getwebproxy(interface))
            print("HTTPS Proxy:")
            print(networksetup.getsecurewebproxy(interface))
        else:
            print("Interface does not exist")
        print()

parser = argparse.ArgumentParser(description=__doc__.strip(), formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("command", choices=["on", "off", "status"], help="Command to execute")
parser.add_argument("-i", "--interface", dest="interfaces", action="append",
                    help="Network interface (can be specified multiple times)")
parser.add_argument("-H", "--host", default=DEFAULT_HOST, help="Proxy host")
parser.add_argument("-p", "--port", default=DEFAULT_PORT, help="Proxy port")

args = parser.parse_args()

# Use default interfaces if none specified

interfaces = args.interfaces if args.interfaces else DEFAULT_INTERFACES

if args.command == "on":
    enable_proxy(interfaces, args.host, args.port)
elif args.command == "off":
    disable_proxy(interfaces)
elif args.command == "status":
    show_status(interfaces)