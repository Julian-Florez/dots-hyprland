hl.bind("Print", hl.dsp.global("quickshell:regionScreenshot"), { description = "Utilities: Screen snip" })
hl.bind("SUPER + S", hl.dsp.exec_cmd("rquickshare-x"), { description = "Launch RQuickShare-X" })
hl.bind("Caps_Lock", hl.dsp.exec_cmd("capslock-toggle"), { non_consuming = true, description = "Indicators: CapsLock" })
hl.bind("Num_Lock", hl.dsp.exec_cmd("numlock-toggle"), { non_consuming = true, description = "Indicators: NumLock" })
hl.bind("SUPER + F9", hl.dsp.exec_cmd("touchpad-toggle"), { description = "Indicators: Toggle Touchpad" })
hl.bind("SUPER + F4", hl.dsp.exec_cmd("micmute-toggle"), { description = "Indicators: Toggle Mic Mute" })
hl.bind("Scroll_Lock", hl.dsp.exec_cmd("scrolllock-toggle"), { non_consuming = true, description = "Indicators: ScrollLock" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("micmute-toggle"), { locked = true, description = "Indicators: Toggle Mic Mute" })


