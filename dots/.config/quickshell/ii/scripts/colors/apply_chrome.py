#!/usr/bin/env python3
import os
import json
import subprocess

colors_path = os.path.expanduser('~/.local/state/quickshell/user/generated/colors.json')
chrome_theme_path = os.path.expanduser('~/.config/chrome-theme.json')

if not os.path.exists(colors_path):
    print("colors.json not found.")
    exit(0)

try:
    with open(colors_path, 'r') as f:
        colors = json.load(f)
except Exception as e:
    print(f"Error parsing colors.json: {e}")
    exit(1)

# Choose a nice frame color. "surface_container" is usually best for a premium look.
theme_color = colors.get("surface_container") or colors.get("background") or "#101010"

policy_data = {
    "BrowserThemeColor": theme_color
}

try:
    with open(chrome_theme_path, 'w') as f:
        json.dump(policy_data, f, indent=2)
    print(f"Chrome theme color updated to {theme_color}")
except Exception as e:
    print(f"Error writing chrome-theme.json: {e}")
    exit(1)

# Refresh the policy in Google Chrome
try:
    for cmd in ["google-chrome", "google-chrome-stable"]:
        subprocess.run([cmd, "--refresh-platform-policy", "--no-startup-window"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print("Chrome policy refreshed successfully.")
except Exception as e:
    print(f"Error refreshing Chrome policy: {e}")
