#!/usr/bin/env python3
import os
import json
import re
import zipfile
import xml.etree.ElementTree as ET

scss_path = os.path.expanduser('~/.local/state/quickshell/user/generated/material_colors.scss')
config_dir = os.path.expanduser('~/.config/Google/AndroidStudio2026.1.2')
share_dir = os.path.expanduser('~/.local/share/Google/AndroidStudio2026.1.2')
system_jar = '/nix/store/1sfnvb1mg4b860v0pwrd0l0l80rw080d-android-studio-unwrapped-2026.1.2.11/lib/intellij.platform.ide.impl.jar'

if not os.path.exists(scss_path) or not os.path.exists(system_jar):
    print("Required files not found.")
    exit(0)

# Parse SCSS variables
colors = {}
with open(scss_path, 'r') as f:
    for line in f:
        match = re.match(r'^\$(\w+):\s*([^;]+);', line.strip())
        if match:
            name = match.group(1)
            val = match.group(2).strip()
            if val.startswith('#'):
                colors[name] = val

def add_alpha(color, alpha):
    if not color:
        return None
    if color.startswith('#'):
        if len(color) > 7:
            color = color[:7]
        return color + alpha
    return color

# Strip '#' for XML values
xml_colors = {k: v.replace('#', '') for k, v in colors.items()}

# 1. Extract original files from system JAR
try:
    with zipfile.ZipFile(system_jar, 'r') as z:
        orig_theme_json = json.loads(z.read('themes/islands/ManyIslandsDark.theme.json').decode('utf-8'))
        orig_scheme_xml = z.read('themes/islands/IslandSchemeDark.xml').decode('utf-8')
except Exception as e:
    print(f"Error extracting original theme files: {e}")
    exit(1)

# 2. Modify theme JSON with dynamic system colors
orig_theme_json["name"] = "Islands Dark"
orig_theme_json["editorScheme"] = "/islands-dark.xml"

# Update colors block
if "colors" in orig_theme_json:
    c = orig_theme_json["colors"]
    
    # Map grays to surface/window colors
    c["gray-10"] = colors.get("surface", "#1C110B")
    c["gray-20"] = colors.get("surfaceContainerLowest", "#160C07")
    c["gray-30"] = colors.get("surfaceContainerLow", "#241913")
    c["gray-40"] = colors.get("surfaceContainer", "#2E221B")
    c["gray-50"] = colors.get("surfaceContainerHigh", "#382A22")
    c["gray-60"] = colors.get("surfaceContainerHighest", "#433229")
    c["gray-70"] = colors.get("outlineVariant", "#514339")
    c["gray-80"] = colors.get("outline", "#9A8F85")
    c["gray-90"] = colors.get("onSurfaceVariant", "#DFC0B1")
    c["gray-100"] = colors.get("onSurfaceVariant", "#DFC0B1")
    c["gray-110"] = colors.get("onSurface", "#F4DED3")
    c["gray-120"] = colors.get("onSurface", "#F4DED3")
    c["gray-130"] = colors.get("onSurface", "#F4DED3")
    c["gray-140"] = colors.get("onSurface", "#F4DED3")
    c["gray-150"] = colors.get("onSurface", "#F4DED3")
    c["gray-160"] = colors.get("onSurface", "#F4DED3")
    
    # Map all blue variables to primary/surface colors to prevent blue accents in the UI
    for key in list(c.keys()):
        if key.startswith("blue-"):
            try:
                num = int(key.split("-")[1])
                if num <= 30:
                    c[key] = colors.get("surface", "#1C110B")
                elif num <= 60:
                    c[key] = colors.get("primaryContainer", "#703B19")
                elif num <= 130:
                    c[key] = colors.get("primary", "#FFB68D")
                else:
                    c[key] = colors.get("onPrimaryContainer", "#FFD8C4")
            except:
                c[key] = colors.get("primary", "#FFB68D")

    # Map all gradient groups (Group1 to Group9) to our system primary/container/surface colors.
    # This removes the hardcoded blue/sky/violet/etc. gradients from the window titlebar header!
    for i in range(1, 10):
        prefix = f"grad-g{i}-"
        for key in list(c.keys()):
            if key.startswith(prefix):
                suffix = key[len(prefix):]
                if "transparent" in suffix:
                    c[key] = add_alpha(colors.get("primary", "#FFB68D"), "00")
                elif suffix == "a1":
                    c[key] = colors.get("primary", "#FFB68D")
                elif suffix == "a1-secondary" or suffix == "a2":
                    c[key] = colors.get("primaryContainer", "#703B19")
                elif suffix == "bg":
                    c[key] = colors.get("surfaceContainerLow", "#241913")

# 3. Modify XML color scheme with dynamic system colors
try:
    root = ET.fromstring(orig_scheme_xml)
    root.set('name', 'Islands Dark')
    
    colors_tag = root.find('colors')
    if colors_tag is not None:
        for option in colors_tag.findall('option'):
            name = option.get('name')
            if name == 'EDITOR_BACKGROUND':
                option.set('value', xml_colors.get('surface', '1c110b'))
            elif name == 'CONSOLE_BACKGROUND_KEY':
                option.set('value', xml_colors.get('surface', '1c110b'))
            elif name == 'CARET_ROW_COLOR':
                option.set('value', xml_colors.get('surfaceContainerLow', '241913'))
            elif name == 'SELECTION_BACKGROUND':
                option.set('value', xml_colors.get('primaryContainer', '703b19'))
            elif name == 'SELECTION_FOREGROUND':
                option.set('value', xml_colors.get('onPrimaryContainer', 'ffd8c4'))
            elif name == 'CARET_COLOR':
                option.set('value', xml_colors.get('primary', 'ffb68d'))
            elif name == 'LINE_NUMBERS_COLOR':
                option.set('value', xml_colors.get('outline', '574237'))
            elif name == 'LINE_NUMBER_ON_CARET_ROW_COLOR':
                option.set('value', xml_colors.get('primary', 'ffb68d'))
            elif name == 'RIGHT_MARGIN_COLOR':
                option.set('value', xml_colors.get('outlineVariant', '514339'))
                
    modified_scheme_xml = ET.tostring(root, encoding='utf-8').decode('utf-8')
except Exception as e:
    print(f"Error modifying color scheme XML: {e}")
    exit(1)

# 4. Generate plugin.xml content
plugin_xml = """<idea-plugin>
  <id>com.julian.theme.islands-dark</id>
  <name>Islands Dark Custom Theme</name>
  <version>1.0.0</version>
  <vendor email="julian@example.com" url="http://example.com">Julian</vendor>
  <description><![CDATA[
      Islands Dark Custom Theme with dynamic system colors.
    ]]></description>
  <depends>com.intellij.modules.platform</depends>
  <extensions defaultExtensionNs="com.intellij">
    <themeProvider id="com.julian.theme.islands-dark" path="/islands-dark.theme.json"/>
  </extensions>
</idea-plugin>
"""

# Compile and package JAR file
plugin_dir = os.path.join(share_dir, 'islands-dark-theme', 'lib')
os.makedirs(plugin_dir, exist_ok=True)
jar_path = os.path.join(plugin_dir, 'islands-dark-theme.jar')

try:
    with zipfile.ZipFile(jar_path, 'w') as z:
        z.writestr("META-INF/plugin.xml", plugin_xml)
        z.writestr("islands-dark.theme.json", json.dumps(orig_theme_json, indent=4))
        z.writestr("islands-dark.xml", modified_scheme_xml)
    print("Theme plugin JAR compiled successfully.")
except Exception as e:
    print(f"Error packaging JAR: {e}")
    exit(1)

# Write preference configurations to direct Android Studio to load our theme
os.makedirs(os.path.join(config_dir, 'options'), exist_ok=True)

laf_xml = """<application>
  <component name="LafManager">
    <laf class-name="com.intellij.ide.ui.laf.temp.TempTheme" themeId="com.julian.theme.islands-dark" />
  </component>
</application>
"""

colors_scheme_xml = """<application>
  <component name="EditorColorsManagerImpl">
    <global_color_scheme name="Islands Dark" />
  </component>
</application>
"""

try:
    with open(os.path.join(config_dir, 'options', 'laf.xml'), 'w') as f:
        f.write(laf_xml)
    with open(os.path.join(config_dir, 'options', 'colors.scheme.xml'), 'w') as f:
        f.write(colors_scheme_xml)
    print("Android Studio look & feel and color scheme options written.")
except Exception as e:
    print(f"Error writing Android Studio options: {e}")
    exit(1)
