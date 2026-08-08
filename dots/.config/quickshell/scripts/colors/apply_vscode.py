#!/usr/bin/env python3
import os
import json
import re

scss_path = os.path.expanduser('~/.local/state/quickshell/user/generated/material_colors.scss')
settings_path = os.path.expanduser('~/.config/Code/User/settings.json')

if not os.path.exists(scss_path) or not os.path.exists(settings_path):
    print("Files not found.")
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

# Complete mapping for ALL keys inside workbench.colorCustomizations
mapping = {
    "foreground": colors.get("onSurface"),
    "focusBorder": "#00000000",
    "selection.background": colors.get("secondaryContainer"),
    "scrollbar.shadow": colors.get("surfaceContainerLowest"),
    "activityBar.background": "#00000000",        # Transparent column
    "activityBar.activeBackground": "#00000000",  # Set to transparent, we will handle hover/active in CSS
    "activityBar.hoverBackground": "#00000000",   # Set to transparent, we will handle hover/active in CSS
    "activityBar.foreground": colors.get("primary"),
    "activityBar.inactiveForeground": colors.get("onSurfaceVariant"),
    "activityBarBadge.background": colors.get("primary"),
    "activityBarBadge.foreground": colors.get("onPrimary"),
    "activityBar.border": "#00000000",            # Hide activity bar border
    "sideBar.background": colors.get("surfaceContainerLow"),
    "sideBar.foreground": colors.get("onSurface"),
    "sideBarSectionHeader.foreground": colors.get("primary"),
    "sideBar.border": "#00000000",                 # Hide sidebar border
    "sash.hoverBorder": "#00000000",               # Make resizer sash invisible on hover
    "statusBar.background": colors.get("surfaceContainerLowest"),
    "statusBar.foreground": colors.get("onSurface"),
    "titleBar.activeBackground": colors.get("surfaceContainerLowest"),
    "titleBar.activeForeground": colors.get("onSurface"),
    "titleBar.inactiveBackground": colors.get("surfaceContainerLowest"),
    "titleBar.inactiveForeground": colors.get("onSurfaceVariant"),
    "titleBar.border": "#00000000",
    "menubar.selectionForeground": colors.get("primary"),
    "menubar.selectionBackground": colors.get("surfaceContainerLow"),
    "menubar.selectionBorder": "#ff000000",
    "menu.foreground": colors.get("onSurface"),
    "menu.background": colors.get("surfaceContainerLowest"),
    "menu.selectionForeground": colors.get("primary"),
    "menu.selectionBackground": colors.get("surfaceContainerLow"),
    "menu.selectionBorder": "#00000000",
    "menu.separatorBackground": colors.get("outlineVariant"),
    "menu.border": "#00000000",
    "button.background": colors.get("primary"),
    "button.foreground": colors.get("onPrimary"),
    "button.hoverBackground": colors.get("primaryContainer"),
    "button.secondaryForeground": colors.get("onSurface"),
    "button.secondaryBackground": colors.get("surfaceContainerLow"),
    "button.secondaryHoverBackground": colors.get("surfaceContainerHigh"),
    "input.background": colors.get("surfaceContainerLow"),
    "input.border": "#00000000",
    "input.foreground": colors.get("onSurface"),
    "inputOption.activeBackground": colors.get("primaryContainer"),
    "inputOption.activeBorder": "#007acc00",
    "inputOption.activeForeground": colors.get("onPrimaryContainer"),
    "input.placeholderForeground": colors.get("onSurfaceVariant"),
    "textLink.foreground": colors.get("primary"),
    "editor.background": colors.get("surface"),
    "editor.foreground": colors.get("onSurface"),
    "editorLineNumber.foreground": colors.get("outline"),
    "editorCursor.foreground": colors.get("primary"),
    "editorCursor.background": colors.get("onPrimary"),
    "editor.selectionBackground": add_alpha(colors.get("secondaryContainer"), "80"),
    "editor.inactiveSelectionBackground": add_alpha(colors.get("secondaryContainer"), "40"),
    "editorWhitespace.foreground": add_alpha(colors.get("outlineVariant"), "40"),
    "editor.selectionHighlightBackground": add_alpha(colors.get("secondaryContainer"), "60"),
    "editor.selectionHighlightBorder": "#495f7700",
    "editor.findMatchBackground": add_alpha(colors.get("primaryContainer"), "90"),
    "editor.findMatchBorder": colors.get("primary"),
    "editor.findMatchHighlightBackground": add_alpha(colors.get("primaryContainer"), "60"),
    "editor.findMatchHighlightBorder": "#c20f0f00",
    "editor.findRangeHighlightBackground": add_alpha(colors.get("surfaceContainer"), "60"),
    "editor.findRangeHighlightBorder": "#e0111100",
    "editor.rangeHighlightBackground": add_alpha(colors.get("surfaceContainer"), "80"),
    "editor.rangeHighlightBorder": "#ffffff00",
    "editor.hoverHighlightBackground": add_alpha(colors.get("primaryContainer"), "40"),
    "editor.wordHighlightStrongBackground": add_alpha(colors.get("primaryContainer"), "60"),
    "editor.wordHighlightStrongBorder": "#ff000000",
    "editor.wordHighlightBackground": add_alpha(colors.get("primaryContainer"), "40"),
    "editor.wordHighlightBorder": "#ff000000",
    "editor.lineHighlightBackground": "#ffffff00",
    "editor.lineHighlightBorder": "#28282800",
    "editorLineNumber.activeForeground": colors.get("primary"),
    "editorLink.activeForeground": colors.get("primary"),
    "editorIndentGuide.background1": colors.get("outlineVariant"),
    "editorIndentGuide.activeBackground1": colors.get("primary"),
    "editorRuler.foreground": colors.get("outlineVariant"),
    "editorBracketMatch.background": colors.get("secondaryContainer"),
    "editorBracketMatch.border": "#88888800",
    "editor.foldBackground": add_alpha(colors.get("secondaryContainer"), "80"),
    "editorOverviewRuler.background": "#ffffff00",
    "editorOverviewRuler.border": "#43404000",
    "editorError.foreground": colors.get("error"),
    "editorError.background": "#ff5e5700",
    "editorError.border": "#ffffff00",
    "editorWarning.foreground": colors.get("tertiary"),
    "editorWarning.background": "#A9904000",
    "editorWarning.border": "#ffffff00",
    "editorInfo.foreground": colors.get("primary"),
    "editorInfo.background": "#4490BF00",
    "editorInfo.border": "#4490BF00",
    "editorGutter.background": colors.get("surface"),
    "editorGutter.modifiedBackground": colors.get("primary"),
    "editorGutter.addedBackground": colors.get("tertiary"),
    "editorGutter.deletedBackground": colors.get("error"),
    "editorGutter.foldingControlForeground": colors.get("onSurfaceVariant"),
    "editorCodeLens.foreground": colors.get("onSurfaceVariant"),
    "editorGroup.border": colors.get("outlineVariant"),
    "diffEditor.insertedTextBackground": add_alpha(colors.get("tertiaryContainer"), "33"),
    "diffEditor.removedTextBackground": add_alpha(colors.get("errorContainer"), "33"),
    "diffEditor.border": colors.get("outlineVariant"),
    "panel.background": colors.get("surfaceContainerLow"),
    "panel.border": "#80808000",
    "panelTitle.activeBorder": colors.get("primary"),
    "panelTitle.activeForeground": colors.get("primary"),
    "panelTitle.inactiveForeground": colors.get("onSurfaceVariant"),
    "badge.background": colors.get("primary"),
    "badge.foreground": colors.get("onPrimary"),
    "breadcrumb.background": colors.get("surfaceContainerLowest"),
    "breadcrumb.foreground": colors.get("onSurfaceVariant"),
    "breadcrumb.focusForeground": colors.get("primary"),
    "editorGroupHeader.border": "#ff000000",
    "editorGroupHeader.tabsBackground": colors.get("surfaceContainerLowest"),
    "editorGroupHeader.tabsBorder": "#88030300",
    "tab.activeForeground": colors.get("primary"),
    "tab.border": "#0000ff00",
    "tab.activeBackground": colors.get("surface"),
    "tab.activeBorder": "#ffffff00",
    "tab.activeBorderTop": "#00000000",
    "tab.inactiveBackground": colors.get("surfaceContainerLowest"),
    "tab.inactiveForeground": colors.get("onSurfaceVariant"),
    "tab.hoverBackground": colors.get("surfaceContainer"),
    "tab.hoverForeground": colors.get("onSurface"),
    "tab.hoverBorder": "#ff000000",
    "scrollbarSlider.background": add_alpha(colors.get("outline"), "20"),
    "scrollbarSlider.hoverBackground": add_alpha(colors.get("outline"), "50"),
    "scrollbarSlider.activeBackground": colors.get("primary"),
    "progressBar.background": colors.get("primary"),
    "widget.shadow": "#0000005c",
    "editorWidget.foreground": colors.get("onSurface"),
    "editorWidget.background": colors.get("surfaceContainer"),
    "editorWidget.resizeBorder": colors.get("primary"),
    "pickerGroup.border": "#4747ff00",
    "pickerGroup.foreground": colors.get("primary"),
    "debugToolBar.background": colors.get("surfaceContainerLowest"),
    "debugToolBar.border": "#47474700",
    "notifications.foreground": colors.get("onSurface"),
    "notifications.background": colors.get("surfaceContainerLowest"),
    "notificationToast.border": "#47474700",
    "notificationsErrorIcon.foreground": colors.get("error"),
    "notificationsWarningIcon.foreground": colors.get("tertiary"),
    "notificationsInfoIcon.foreground": colors.get("primary"),
    "notificationCenter.border": "#47474700",
    "notificationCenterHeader.foreground": colors.get("primary"),
    "notificationCenterHeader.background": colors.get("surfaceContainerLowest"),
    "notifications.border": colors.get("surfaceContainerLowest"),
    "gitDecoration.addedResourceForeground": colors.get("tertiary"),
    "gitDecoration.conflictingResourceForeground": colors.get("primary"),
    "gitDecoration.deletedResourceForeground": colors.get("error"),
    "gitDecoration.ignoredResourceForeground": colors.get("onSurfaceVariant"),
    "gitDecoration.modifiedResourceForeground": colors.get("primary"),
    "gitDecoration.stageDeletedResourceForeground": colors.get("error"),
    "gitDecoration.stageModifiedResourceForeground": colors.get("primary"),
    "gitDecoration.submoduleResourceForeground": colors.get("primary"),
    "gitDecoration.untrackedResourceForeground": colors.get("tertiary"),
    "editorMarkerNavigation.background": colors.get("surfaceContainerLowest"),
    "editorMarkerNavigationError.background": colors.get("error"),
    "editorMarkerNavigationWarning.background": colors.get("tertiary"),
    "editorMarkerNavigationInfo.background": colors.get("primary"),
    "merge.currentHeaderBackground": add_alpha(colors.get("primaryContainer"), "60"),
    "merge.currentContentBackground": add_alpha(colors.get("primaryContainer"), "40"),
    "merge.incomingHeaderBackground": add_alpha(colors.get("secondaryContainer"), "60"),
    "merge.incomingContentBackground": add_alpha(colors.get("secondaryContainer"), "40"),
    "merge.commonHeaderBackground": add_alpha(colors.get("outlineVariant"), "60"),
    "merge.commonContentBackground": add_alpha(colors.get("outlineVariant"), "40"),
    "editorSuggestWidget.background": colors.get("surfaceContainer"),
    "editorSuggestWidget.border": "#45454500",
    "editorSuggestWidget.foreground": colors.get("onSurface"),
    "editorSuggestWidget.highlightForeground": colors.get("primary"),
    "editorSuggestWidget.selectedBackground": colors.get("secondaryContainer"),
    "editorHoverWidget.foreground": colors.get("onSurface"),
    "editorHoverWidget.background": colors.get("surfaceContainer"),
    "editorHoverWidget.border": "#45454500",
    "peekView.border": colors.get("primary"),
    "peekViewEditor.background": colors.get("surfaceContainer"),
    "peekViewEditorGutter.background": colors.get("surfaceContainer"),
    "peekViewEditor.matchHighlightBackground": add_alpha(colors.get("primaryContainer"), "60"),
    "peekViewEditor.matchHighlightBorder": "#ee931e00",
    "peekViewResult.background": colors.get("surfaceContainerLow"),
    "peekViewResult.fileForeground": colors.get("onSurface"),
    "peekViewResult.lineForeground": colors.get("primary"),
    "peekViewResult.matchHighlightBackground": add_alpha(colors.get("primaryContainer"), "80"),
    "peekViewResult.selectionBackground": colors.get("secondaryContainer"),
    "peekViewResult.selectionForeground": colors.get("primary"),
    "peekViewTitle.background": colors.get("surfaceContainerLowest"),
    "peekViewTitleDescription.foreground": colors.get("onSurfaceVariant"),
    "peekViewTitleLabel.foreground": colors.get("primary"),
    "icon.foreground": colors.get("primary"),
    "checkbox.background": colors.get("surfaceContainer"),
    "checkbox.foreground": colors.get("onSurface"),
    "checkbox.border": "#00000000",
    "dropdown.background": colors.get("surfaceContainer"),
    "dropdown.foreground": colors.get("onSurface"),
    "dropdown.border": "#00000000",
    "minimapGutter.addedBackground": colors.get("tertiary"),
    "minimapGutter.modifiedBackground": colors.get("primary"),
    "minimapGutter.deletedBackground": colors.get("error"),
    "minimap.findMatchHighlight": add_alpha(colors.get("primaryContainer"), "90"),
    "minimap.selectionHighlight": colors.get("secondaryContainer"),
    "minimap.errorHighlight": colors.get("error"),
    "minimap.warningHighlight": colors.get("tertiary"),
    "minimap.background": colors.get("surfaceContainerLowest"),
    "sideBar.dropBackground": add_alpha(colors.get("secondaryContainer"), "80"),
    "editorGroup.emptyBackground": colors.get("surface"),
    "panelSection.border": colors.get("outline"),
    "statusBarItem.activeBackground": "#ffffff1c",
    "settings.headerForeground": colors.get("primary"),
    "settings.focusedRowBackground": "#ffffff07",
    "walkThrough.embeddedEditorBackground": "#00000050",
    "breadcrumb.activeSelectionForeground": colors.get("primary"),
    "editorGutter.commentRangeForeground": colors.get("outline"),
    "debugExceptionWidget.background": colors.get("surfaceContainerLowest"),
    "debugExceptionWidget.border": "#47474700",
    "terminal.background": colors.get("term0"),
    "terminal.foreground": colors.get("term7"),
    "terminal.selectionBackground": colors.get("secondaryContainer"),
    "terminalCursor.background": colors.get("term7"),
    "terminalCursor.foreground": colors.get("term7"),
    "terminal.ansiBlack": colors.get("term0"),
    "terminal.ansiRed": colors.get("term1"),
    "terminal.ansiGreen": colors.get("term2"),
    "terminal.ansiYellow": colors.get("term3"),
    "terminal.ansiBlue": colors.get("term4"),
    "terminal.ansiMagenta": colors.get("term5"),
    "terminal.ansiCyan": colors.get("term6"),
    "terminal.ansiWhite": colors.get("term7"),
    "terminal.ansiBrightBlack": colors.get("term8"),
    "terminal.ansiBrightRed": colors.get("term9"),
    "terminal.ansiBrightGreen": colors.get("term10"),
    "terminal.ansiBrightYellow": colors.get("term11"),
    "terminal.ansiBrightBlue": colors.get("term12"),
    "terminal.ansiBrightMagenta": colors.get("term13"),
    "terminal.ansiBrightCyan": colors.get("term14"),
    "terminal.ansiBrightWhite": colors.get("term15"),
    
    # VS Code Chat & Interactive UI theme colors (Fixes Agents Mode colors)
    "chat.background": colors.get("surface"),
    "chat.requestBorder": colors.get("outlineVariant"),
    "chat.requestBackground": colors.get("surfaceContainerLow"),
    "chat.slashCommandBackground": colors.get("secondaryContainer"),
    "chat.slashCommandForeground": colors.get("onSecondaryContainer"),
    "chat.avatarBackground": colors.get("primaryContainer"),
    "chat.avatarForeground": colors.get("onPrimaryContainer"),
    "interactive.activeCodeBorder": colors.get("primary"),
    "interactive.inactiveCodeBorder": colors.get("outlineVariant")
}

# Clean None values
mapping = {k: v for k, v in mapping.items() if v is not None}

# Read settings.json and strip comments/trailing commas
try:
    with open(settings_path, 'r') as f:
        text = f.read()
    
    # Strip single-line comments line-by-line
    lines = []
    for line in text.splitlines():
        if line.strip().startswith('//'):
            continue
        lines.append(line)
    clean = '\n'.join(lines)
    
    # Strip multi-line comments
    clean = re.sub(r'/\*.*?\*/', '', clean, flags=re.S)
    # Strip trailing commas
    clean = re.sub(r',\s*([\]}])', r'\1', clean)
    
    data = json.loads(clean, strict=False)
except Exception as e:
    print(f"Error parsing settings.json: {e}")
    exit(1)

# Update color customizations
if "workbench.colorCustomizations" not in data:
    data["workbench.colorCustomizations"] = {}

for k, v in mapping.items():
    data["workbench.colorCustomizations"][k] = v

# Ensure correct font configuration for Nerd Fonts (no spaces in JetBrainsMono)
data["terminal.integrated.fontFamily"] = "JetBrainsMono Nerd Font"
data["terminal.integrated.fontSize"] = 11

# Update custom-ui-style.stylesheet colors and layout adjustments
if "custom-ui-style.stylesheet" in data:
    s = data["custom-ui-style.stylesheet"]
    
    # 1. Backgrounds
    if ".monaco-workbench" in s:
        s[".monaco-workbench"]["background-color"] = colors.get("surface") + " !important"
    
    # 2. Selected/Focused/Hovered list rows in sidebar
    list_bg = colors.get("secondaryContainer") + " !important"
    sidebar_selectors = [
        ".part.sidebar .monaco-list-row.selected, .part.sidebar .monaco-list-row.focused",
        ".part.sidebar .monaco-list-row.focused.selected",
        ".part.sidebar .monaco-list:focus .monaco-list-row.selected",
        ".part.sidebar .monaco-list:focus .monaco-list-row.focused",
        ".part.sidebar .monaco-list-row:hover"
    ]
    for sel in sidebar_selectors:
        if sel in s:
            s[sel]["background"] = list_bg
            
    # 3. Activitybar parent transparent background & alignment fixes (width 68px, gap left 12px, gap right 8px)
    if ".part.activitybar" in s:
        s[".part.activitybar"]["background"] = "transparent !important"
        s[".part.activitybar"]["margin"] = "8px 0 30px 0"
        s[".part.activitybar"]["width"] = "68px !important"
        s[".part.activitybar"]["min-width"] = "68px !important"
        s[".part.activitybar"]["border"] = "none !important"
        s[".part.activitybar"]["box-shadow"] = "none !important"

    if ".monaco-workbench .activitybar" in s:
        s[".monaco-workbench .activitybar"]["border"] = "none !important"
        s[".monaco-workbench .activitybar"]["width"] = "68px !important"
        s[".monaco-workbench .activitybar"]["min-width"] = "68px !important"
        s[".monaco-workbench .activitybar"]["overflow"] = "visible !important"
        
    # 4. Activitybar composite-bar (pill) centering and layout fixes (width 48px, offset 12px from left edge)
    if ".part.activitybar .composite-bar" in s:
        s[".part.activitybar .composite-bar"]["background"] = colors.get("surfaceContainerLow") + " !important"
        s[".part.activitybar .composite-bar"]["width"] = "48px !important"
        s[".part.activitybar .composite-bar"]["margin-left"] = "12px !important"
        s[".part.activitybar .composite-bar"]["padding"] = "10px 0"
        
    # 5. Activitybar items shape fix (perfect 48px circle, fully matching the 48px pill)
    if ".part.activitybar .action-item" in s:
        s[".part.activitybar .action-item"]["width"] = "48px !important"
        s[".part.activitybar .action-item"]["height"] = "48px !important"
        s[".part.activitybar .action-item"]["border-radius"] = "50% !important"
        s[".part.activitybar .action-item"]["display"] = "flex !important"
        s[".part.activitybar .action-item"]["justify-content"] = "center !important"
        s[".part.activitybar .action-item"]["align-items"] = "center !important"
        s[".part.activitybar .action-item"]["overflow"] = "hidden !important"
        
    # 6. Activitybar active/hover indicator circular highlight backgrounds inside CSS
    active_hl = add_alpha(colors.get("primary"), "30") + " !important"
    hover_hl = add_alpha(colors.get("primary"), "15") + " !important"
    
    if ".part.activitybar .action-item.checked" not in s:
        s[".part.activitybar .action-item.checked"] = {}
    s[".part.activitybar .action-item.checked"]["background"] = active_hl
    
    if ".part.activitybar .action-item:hover" not in s:
        s[".part.activitybar .action-item:hover"] = {}
    s[".part.activitybar .action-item:hover"]["background"] = hover_hl

    # 7. Hide sash separators next to activitybar on hover
    sash_selector = ".monaco-workbench .sash-container:not(.part.editor *) > .monaco-sash:first-child"
    if sash_selector not in s:
        s[sash_selector] = {}
    s[sash_selector]["display"] = "none !important"
    s[sash_selector]["pointer-events"] = "none !important"

    # 8. Hide the activitybar border line drawn by :before pseudo-elements
    border_selectors = [
        ".monaco-workbench .activitybar.left.bordered:before",
        ".monaco-workbench .activitybar.right.bordered:before",
        ".monaco-workbench .part.activitybar.left.bordered:before",
        ".monaco-workbench .part.activitybar.right.bordered:before"
    ]
    for sel in border_selectors:
        if sel not in s:
            s[sel] = {}
        s[sel]["display"] = "none !important"
        s[sel]["border-right-style"] = "none !important"
        s[sel]["border-left-style"] = "none !important"

    # 9. Titlebar background
    if ".part.titlebar" in s:
        s[".part.titlebar"]["background-color"] = colors.get("surfaceContainerLowest") + " !important"
        
    # 10. Statusbar background
    if ".part.statusbar" in s:
        s[".part.statusbar"]["background-color"] = colors.get("surfaceContainerLowest") + " !important"
        
    # 11. Command center
    if ".command-center-center" in s:
        s[".command-center-center"]["background"] = colors.get("surfaceContainerLow") + " !important"

    # 12. Auxiliarybar (chat panel) margin spacing fix
    if ".part.auxiliarybar" in s:
        s[".part.auxiliarybar"]["margin"] = "8px 20px 0 8px"

# Save back safely using atomic replace
tmp_path = settings_path + '.tmp'
try:
    with open(tmp_path, 'w') as f:
        json.dump(data, f, indent=4)
    os.replace(tmp_path, settings_path)
    print("VSCode configuration updated successfully.")
except Exception as e:
    if os.path.exists(tmp_path):
        os.remove(tmp_path)
    print(f"Error writing settings.json: {e}")
    exit(1)
