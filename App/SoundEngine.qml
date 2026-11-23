// Aethon
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
pragma Singleton
import QtQuick 2.15
import QtMultimedia 5.15

QtObject {
    id: root

    property SoundEffect _warm: SoundEffect {
        source: Qt.resolvedUrl("../assets/sound/scroll.wav")
        volume: 0.01
        loops: SoundEffect.Infinite
    }

    readonly property int _warmWindowMs: 15000

    property Timer _warmStopTimer: Timer {
        interval: root._warmWindowMs
        repeat: false
        onTriggered: root._warm.stop()
    }

    property SoundEffect _scroll: SoundEffect {
        source: Qt.resolvedUrl("../assets/sound/scroll.wav")
        volume: 0.5
    }

    property SoundEffect _select: SoundEffect {
        source: Qt.resolvedUrl("../assets/sound/select.wav")
        volume: 0.6
    }

    property SoundEffect _back: SoundEffect {
        source: Qt.resolvedUrl("../assets/sound/back.wav")
        volume: 0.6
    }

    property SoundEffect _favorite: SoundEffect {
        source: Qt.resolvedUrl("../assets/sound/favorite.wav")
        volume: 0.7
    }

    property SoundEffect _launch: SoundEffect {
        source: Qt.resolvedUrl("../assets/sound/launch.wav")
        volume: 0.7
    }

    function warmUp() {
        if (!SettingsManager.soundEffects) return;
        if (root._warm.status !== SoundEffect.Ready) return;
        root._warm.play();
        root._warmStopTimer.restart();
    }

    function _play(effect) {
        if (!SettingsManager.soundEffects) return;
        if (!effect) return;
        if (effect.status !== SoundEffect.Ready) return;
        if (effect.playing) return;
        effect.play();
    }

    function scroll() { root._play(root._scroll); }
    function select() { root._play(root._select); }
    function back() { root._play(root._back); }
    function favorite() { root._play(root._favorite); }
    function launch() { root._play(root._launch); }

    readonly property int _launchDelayMs: 550

    property var _pendingLaunchTarget: null

    property Timer _launchDelayTimer: Timer {
        interval: root._launchDelayMs
        repeat: false
        onTriggered: {
            if (root._pendingLaunchTarget) {
                var g = root._pendingLaunchTarget;
                root._pendingLaunchTarget = null;
                g.launch();
            }
        }
    }

    function launchGame(game) {
        if (!game) return;

        if (!SettingsManager.soundEffects
            || !root._launch
            || root._launch.status !== SoundEffect.Ready) {
            game.launch();
        return;
            }

            if (!root._launch.playing) {
                root._launch.play();
            }
            root._pendingLaunchTarget = game;
            root._launchDelayTimer.restart();
    }
}
