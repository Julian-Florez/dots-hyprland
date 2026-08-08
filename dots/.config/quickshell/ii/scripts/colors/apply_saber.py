#!/usr/bin/env python3
import os
import json

colors_path = os.path.expanduser('~/.local/state/quickshell/user/generated/colors.json')
saber_prefs_path = os.path.expanduser('~/.local/share/saber/shared_preferences.json')

if not os.path.exists(colors_path) or not os.path.exists(saber_prefs_path):
    print("Required files not found. Skipping Saber theming.")
    exit(0)

try:
    # 1. Read the system colors
    with open(colors_path, 'r') as f:
        colors = json.load(f)
    
    # Get the system accent color (primary)
    primary_hex = colors.get("primary") or "#ffb68e"
    
    # Strip '#' and format as ARGB (defaulting alpha to 'ff')
    hex_clean = primary_hex.lstrip('#').lower()
    if len(hex_clean) == 6:
        argb_hex = "ff" + hex_clean
    elif len(hex_clean) == 8:
        argb_hex = hex_clean
    else:
        argb_hex = "ffffb68e"
        
    # Convert to 32-bit integer
    color_int = int(argb_hex, 16)
    
    # 2. Read Saber's preferences
    with open(saber_prefs_path, 'r') as f:
        prefs = json.load(f)
        
    # 3. Update the accent color
    prefs["flutter.accentColor"] = color_int
    
    # 4. Save the preferences back
    with open(saber_prefs_path, 'w') as f:
        json.dump(prefs, f, separators=(',', ':'))
        
    print(f"Saber accent color updated to {primary_hex} ({color_int})")

except Exception as e:
    print(f"Error applying Saber theming: {e}")
