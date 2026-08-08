#!/usr/bin/env python3
import os
import json
import xml.etree.ElementTree as ET

colors_path = os.path.expanduser('~/.local/state/quickshell/user/generated/colors.json')
theme_dir = os.path.expanduser('~/.config/inkscape/themes/DynamicTheme/gtk-3.0')
preferences_path = os.path.expanduser('~/.config/inkscape/preferences.xml')

if not os.path.exists(colors_path):
    print("colors.json not found.")
    exit(0)

# 1. Create theme directory
os.makedirs(theme_dir, exist_ok=True)

try:
    # 2. Read colors
    with open(colors_path, 'r') as f:
        colors = json.load(f)
except Exception as e:
    print(f"Error reading colors.json: {e}")
    exit(1)

# Extract colors
bg = colors.get("background") or "#1c110b"
fg = colors.get("on_surface") or "#f5ded3"
base = colors.get("surface_container") or "#291d16"
base_low = colors.get("surface_container_low") or "#251912"
base_lowest = colors.get("surface_container_lowest") or "#160c06"
primary = colors.get("primary") or "#ffb68e"
on_primary = colors.get("on_primary") or "#542200"
border = colors.get("outline_variant") or "#584236"
outline = colors.get("outline") or "#a78b7d"

# 3. Create gtk.css content
css_content = f"""/* Dynamic Theme for Inkscape */
@define-color theme_bg_color {bg};
@define-color theme_fg_color {fg};
@define-color theme_base_color {base};
@define-color theme_text_color {fg};
@define-color theme_selected_bg_color {primary};
@define-color theme_selected_fg_color {on_primary};
@define-color theme_unfocused_bg_color {bg};
@define-color theme_unfocused_fg_color {fg};
@define-color theme_unfocused_base_color {base_low};
@define-color theme_unfocused_text_color {fg};

@define-color bg_color {bg};
@define-color fg_color {fg};
@define-color base_color {base};
@define-color text_color {fg};
@define-color selected_bg_color {primary};
@define-color selected_fg_color {on_primary};

@define-color tooltip_bg_color {base_lowest};
@define-color tooltip_fg_color {fg};
@define-color content_view_bg {base};
@define-color borders {border};
@define-color outline_color {outline};

/* Import Adwaita default GTK theme */
@import url("resource:///org/gnome/adwaita/gtk-main.css");

/* Modern flat flat UI overrides */
window, grid, box, paned, notebook, stack, assistant {{
  background-color: @theme_bg_color;
  color: @theme_fg_color;
}}

headerbar, .titlebar, menubar, menu, menuitem {{
  background-color: @theme_bg_color;
  color: @theme_fg_color;
  border: none;
}}

notebook header tabs {{
  background-color: @theme_bg_color;
}}
notebook header tab:checked {{
  background-color: @theme_base_color;
  border-bottom: 2px solid @theme_selected_bg_color;
}}

.sidebar, scrolledwindow, treeview, list, row {{
  background-color: @theme_base_color;
  color: @theme_fg_color;
}}

toolbar, .toolbar {{
  background-color: @theme_bg_color;
  border: none;
}}

button {{
  background-image: none;
  background-color: @theme_base_color;
  color: @theme_fg_color;
  border: 1px solid @borders;
  border-radius: 4px;
}}
button:hover {{
  background-color: @theme_selected_bg_color;
  color: @theme_selected_fg_color;
}}
button:active, button:checked {{
  background-color: @theme_selected_bg_color;
  color: @theme_selected_fg_color;
}}

entry {{
  background-color: @theme_base_color;
  color: @theme_fg_color;
  border: 1px solid @borders;
  border-radius: 4px;
}}

#InkscapeCanvas, #canvas-grid {{
  background-color: @theme_base_color;
}}

/* Remove borders */
* {{
  border-color: transparent;
  box-shadow: none;
}}
"""

try:
    with open(os.path.join(theme_dir, 'gtk.css'), 'w') as f:
        f.write(css_content)
    print("gtk.css written successfully.")
except Exception as e:
    print(f"Error writing gtk.css: {e}")
    exit(1)

# 4. Update preferences.xml in Inkscape to use "DynamicTheme"
if os.path.exists(preferences_path):
    try:
        tree = ET.parse(preferences_path)
        root = tree.getroot()
        
        # Find group with id="theme"
        theme_group = root.find(".//group[@id='theme']")
        if theme_group is not None:
            theme_group.set('gtkTheme', 'DynamicTheme')
            theme_group.set('defaultGtkTheme', 'DynamicTheme')
            theme_group.set('preferDarkTheme', '0')
            theme_group.set('darkTheme', '0')
            tree.write(preferences_path, encoding='utf-8', xml_declaration=True)
            print("Inkscape preferences.xml updated to use DynamicTheme.")
        else:
            print("Theme group not found in preferences.xml.")
    except Exception as e:
        print(f"Error updating preferences.xml: {e}")
