#!/usr/bin/env python3
import os
import json

colors_path = os.path.expanduser('~/.local/state/quickshell/user/generated/colors.json')
vesktop_theme_dir = os.path.expanduser('~/.config/vesktop/themes')
vesktop_theme_path = os.path.join(vesktop_theme_dir, 'DynamicTheme.theme.css')

if not os.path.exists(colors_path):
    print("colors.json not found.")
    exit(0)

# Create the Vesktop themes folder if it doesn't exist
os.makedirs(vesktop_theme_dir, exist_ok=True)

def hex_to_hsl(hex_str):
    hex_str = hex_str.lstrip('#')
    r = int(hex_str[0:2], 16) / 255.0
    g = int(hex_str[2:4], 16) / 255.0
    b = int(hex_str[4:6], 16) / 255.0
    
    mx = max(r, g, b)
    mn = min(r, g, b)
    df = mx - mn
    
    # Calculate Hue
    if mx == mn:
        h = 0
    elif mx == r:
        h = (60 * ((g - b) / df) + 360) % 360
    elif mx == g:
        h = (60 * ((b - r) / df) + 120) % 360
    elif mx == b:
        h = (60 * ((r - g) / df) + 240) % 360
        
    # Calculate Lightness
    l = (mx + mn) / 2.0
    
    # Calculate Saturation
    if mx == mn:
        s = 0
    elif l <= 0.5:
        s = df / (mx + mn)
    else:
        s = df / (2.0 - mx - mn)
        
    return round(h), round(s * 100), round(l * 100)

try:
    with open(colors_path, 'r') as f:
        colors = json.load(f)
except Exception as e:
    print(f"Error reading colors.json: {e}")
    exit(1)

# Extract colors
bg = colors.get("background") or "#1c110b"
fg = colors.get("on_surface") or "#f5ded3"
surface = colors.get("surface_container") or "#291d16"
surface_low = colors.get("surface_container_low") or "#251912"
primary_hex = colors.get("primary") or "#ffb68e"
on_surface_variant = colors.get("on_surface_variant") or "#a78b7d"

# Convert primary color to HSL
hue, sat, lit = hex_to_hsl(primary_hex)

# Generate Vesktop/Vencord Material You theme
theme_content = f"""/**
 * @name DynamicTheme
 * @author Julian (via Antigravity)
 * @description Dynamic Material You theme for Vesktop matching the system colors
 * @version 1.0.0
 * @source https://github.com/CapnKitten/Material-Discord
 */

@import url("https://capnkitten.github.io/Material-Discord/Material-Discord.theme.css");

:root {{
  /* Primary HSL values for the Material You generator */
  --accent-hue: {hue} !important;
  --accent-saturation: {sat}% !important;
  --accent-lightness: {lit}% !important;
  
  /* Fallback text watermarks */
  --app-watermark-one: "Discord" !important;
  --app-watermark-two: "" !important;
}}

.theme-dark, .theme-light {{
  /* Direct color overrides to match system exactly */
  --app-bg: {bg} !important;
  --main-color: {surface} !important;
  --main-alt: {surface_low} !important;
  --sidebar-color: {bg} !important;
  --body-color: {fg} !important;
  --text-color: {fg} !important;
  --text-normal: {fg} !important;
  --text-muted: {on_surface_variant} !important;
  
  /* Overrides for specific Material-Discord accent elements */
  --accent-color: {primary_hex} !important;
  --accent-text-color: {fg} !important;
}}

/* Disable custom "Material Discord" text and restore official Discord SVG logo */
.wordmark__421ed::before,
.wordmark__421ed::after,
.wordmarkWindows__421ed::before,
.wordmarkWindows__421ed::after,
[class*="wordmark"]::before,
[class*="wordmark"]::after {{
  display: none !important;
  content: "" !important;
}}

.wordmark__421ed svg,
.wordmarkWindows__421ed svg,
[class*="wordmark"] svg {{
  display: block !important;
}}
"""

try:
    with open(vesktop_theme_path, 'w') as f:
        f.write(theme_content)
    print("Vesktop theme updated with specific class overrides.")
except Exception as e:
    print(f"Error writing Vesktop theme: {e}")
    exit(1)
