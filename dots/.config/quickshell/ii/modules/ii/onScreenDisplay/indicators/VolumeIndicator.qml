import qs.services
import QtQuick
import qs.modules.ii.onScreenDisplay

OsdValueIndicator {
    id: osdValues
    value: Audio.sink?.audio.volume ?? 0
    showMixerButton: true
    icon: {
        if (Audio.sink?.audio.muted) {
            return "volume_off";
        }
        var val = Audio.sink?.audio.volume ?? 0;
        if (val <= 0) {
            return "volume_mute";
        } else if (val < 0.33) {
            return "volume_mute"; // standard mute icon is good for zero/low
        } else if (val < 0.66) {
            return "volume_down";
        } else {
            return "volume_up";
        }
    }
    name: Translation.tr("Volume")
}
