#!/usr/bin/env python3
"""Derive a Chrome extension ID from an RSA private key."""
import hashlib, subprocess, sys

der = subprocess.check_output(
    ["openssl", "rsa", "-in", sys.argv[1], "-pubout", "-outform", "DER"],
    stderr=subprocess.DEVNULL,
)
d = hashlib.sha256(der).digest()[:16]
print("".join(chr(ord("a") + b // 16) + chr(ord("a") + b % 16) for b in d), end="")
