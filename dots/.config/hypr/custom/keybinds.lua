-- Unbind default bindings to prevent double-execution conflict
hl.unbind("XF86AudioMicMute")
hl.unbind("XF86TouchpadToggle")

hl.bind("Print", hl.dsp.global("quickshell:regionScreenshot"), { description = "Utilities: Screen snip" })
hl.bind("SUPER + S", hl.dsp.exec_cmd("rquickshare-x"), { description = "Launch RQuickShare-X" })

hl.bind("Caps_Lock", hl.dsp.exec_cmd("/home/julian/.local/bin/capslock-toggle"), { non_consuming = true, description = "Indicators: CapsLock" })
hl.bind("Num_Lock", hl.dsp.exec_cmd("/home/julian/.local/bin/numlock-toggle"), { non_consuming = true, description = "Indicators: NumLock" })
hl.bind("Scroll_Lock", hl.dsp.exec_cmd("/home/julian/.local/bin/scrolllock-toggle"), { non_consuming = true, description = "Indicators: ScrollLock" })

hl.bind("SUPER + F9", hl.dsp.exec_cmd("/home/julian/.local/bin/touchpad-toggle"), { description = "Indicators: Toggle Touchpad" })
hl.bind("XF86TouchpadToggle", hl.dsp.exec_cmd("/home/julian/.local/bin/touchpad-toggle"), { description = "Indicators: Toggle Touchpad" })

hl.bind("SUPER + F4", hl.dsp.exec_cmd("/home/julian/.local/bin/micmute-toggle"), { description = "Indicators: Toggle Mic Mute" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("/home/julian/.local/bin/micmute-toggle"), { locked = true, description = "Indicators: Toggle Mic Mute" })
