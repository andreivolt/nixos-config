#!/usr/bin/env -S uv run --script --quiet
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "cryptography",
#   "pyjwt",
#   "requests",
# ]
# ///

import argparse
import json
import os
import sys
import time
import uuid
from datetime import datetime, timedelta

import jwt
import requests


def generate_jwt(api_key, api_secret):
    issued_at = int(time.time())
    expiration = issued_at + 300
    jti = str(uuid.uuid4())

    payload = {
        "iss": api_key,
        "jti": jti,
        "iat": issued_at,
        "exp": expiration
    }

    return jwt.encode(payload, api_secret, algorithm="HS256")


def delete_addon(addon_id, api_key, api_secret):
    # Get delete confirmation token
    jwt_get = generate_jwt(api_key, api_secret)

    response = requests.get(
        f"https://addons.mozilla.org/api/v5/addons/addon/{addon_id}/delete_confirm/",
        headers={"Authorization": f"JWT {jwt_get}"}
    )
    response.raise_for_status()

    delete_confirm = response.json()["delete_confirm"]

    # Delete the addon
    jwt_delete = generate_jwt(api_key, api_secret)

    response = requests.delete(
        f"https://addons.mozilla.org/api/v5/addons/addon/{addon_id}/",
        params={"delete_confirm": delete_confirm},
        headers={"Authorization": f"JWT {jwt_delete}"}
    )
    response.raise_for_status()

    print(f"Add-on ID {addon_id} has been deleted.")


parser = argparse.ArgumentParser(description="Delete Firefox addon")
parser.add_argument("addon_id", help="The addon ID to delete")

args = parser.parse_args()

api_key = os.getenv("AMO_API_KEY")
api_secret = os.getenv("AMO_API_SECRET")

if not api_key or not api_secret:
    print("AMO_API_KEY and AMO_API_SECRET must be set.", file=sys.stderr)
    sys.exit(1)

delete_addon(args.addon_id, api_key, api_secret)