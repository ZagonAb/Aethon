// Aethon
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
import QtQuick 2.15
import "../App"

FocusScope {
    id: splash

    property string fontFamily: "Jet Brains Mono"
    property string titleText: "AETHON"
    property string subtitleText: "PEGASUS FRONTEND THEME"
    readonly property var themeColors: SettingsManager.getCurrentColors()
    property color backgroundColor: themeColors.bg
    property color titleColor: themeColors.fg
    property color loadingColor: themeColors.border
    property color subtitleColor: themeColors.muted
    property int fadeInDuration: 2200
    property int holdDuration: 500
    property int sweepDuration: 2800
    property int sweepCount: 1
    property int endPause: 300
    property int textFadeOutDuration: 700
    property int revealDuration: 1600
    property real spread: 1.6
    property bool skippable: true
    property bool running: true
    property bool revealing: false
    property bool skipping: false
    property real progress: -2
    signal revealStarted()
    signal finished()

    visible: running
    focus: true
    z: 999

    function skip() {
        if (!running || exitAnim.running) return;
        skipping = true;
        sequence.stop();
        if (offTimer.running) offTimer.stop();
        exitAnim.start();
    }

    Keys.onPressed: {
        if (skippable && !event.isAutoRepeat) skip();
        event.accepted = true;
    }

    Component.onCompleted: {
        forceActiveFocus();
        if (!EffectsManager.animationsEnabled) {
            content.opacity = 1;
            splash.progress = -1;
        }
    }

    Rectangle { id: bg; anchors.fill: parent; color: splash.backgroundColor }
    MouseArea { anchors.fill: parent; hoverEnabled: true }

    Item {
        id: content
        anchors.centerIn: parent
        opacity: 0
        width: titleRow.width
        height: titleRow.height + subtitle.anchors.topMargin + subtitle.height

        readonly property real fs: Math.round(Math.min(
            splash.width * 0.18,
            splash.height * 0.22
        ))

        Row {
            id: titleRow
            spacing: content.fs * 0.12

            Repeater {
                model: splash.titleText.length

                Text {
                    readonly property real level: {
                        var x = 1 - Math.abs(splash.progress - index) / splash.spread;
                        x = Math.max(0, Math.min(1, x));
                        return x * x * (3 - 2 * x);
                    }

                    text: splash.titleText.charAt(index)
                    font.family: splash.fontFamily
                    font.pixelSize: content.fs
                    font.weight: Font.Bold
                    renderType: Text.NativeRendering
                    color: Qt.tint(splash.titleColor,
                                   Qt.rgba(splash.loadingColor.r,
                                           splash.loadingColor.g,
                                           splash.loadingColor.b,
                                           level))
                }
            }
        }

        FontMetrics {
            id: subMetrics
            font.family: splash.fontFamily
            font.pixelSize: subtitle.font.pixelSize
        }

        Text {
            id: subtitle
            anchors.top: titleRow.bottom
            anchors.topMargin: content.fs * 0.12
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: font.letterSpacing / 2

            text: splash.subtitleText
            color: splash.subtitleColor
            font.family: splash.fontFamily
            font.pixelSize: Math.max(9, Math.round(content.fs * 0.15))
            font.letterSpacing: {
                var n = splash.subtitleText.length;
                if (n < 2) return 0;
                var target = titleRow.width * 0.96;
                return Math.max(0, (target - subMetrics.advanceWidth(splash.subtitleText)) / (n - 1));
            }
            renderType: Text.NativeRendering
        }
    }

    SequentialAnimation {
        id: sequence
        running: EffectsManager.animationsEnabled

        NumberAnimation {
            target: content; property: "opacity"
            from: 0; to: 1
            duration: EffectsManager.dur(splash.fadeInDuration)
            easing.type: Easing.InOutSine
        }
        PauseAnimation { duration: EffectsManager.dur(splash.holdDuration) }

        SequentialAnimation {
            loops: EffectsManager.loopingAnimationsEnabled ? splash.sweepCount : 0
            NumberAnimation {
                target: splash; property: "progress"
                from: -splash.spread
                to: splash.titleText.length - 1 + splash.spread
                duration: EffectsManager.dur(splash.sweepDuration)
                easing.type: Easing.InOutSine
            }
        }

        ScriptAction {
            script: if (!EffectsManager.loopingAnimationsEnabled) splash.progress = -1;
        }

        PauseAnimation { duration: EffectsManager.dur(splash.endPause) }

        ScriptAction { script: exitAnim.start() }
    }

    Timer {
        id: offTimer
        interval: 600
        running: !EffectsManager.animationsEnabled
        repeat: false
        onTriggered: exitAnim.start()
    }

    SequentialAnimation {
        id: exitAnim

        NumberAnimation {
            target: content; property: "opacity"
            to: 0
            duration: EffectsManager.dur(splash.skipping ? 150 : splash.textFadeOutDuration)
            easing.type: Easing.InOutSine
        }
        ScriptAction {
            script: {
                splash.revealing = true;
                splash.revealStarted();
            }
        }
        NumberAnimation {
            target: bg; property: "opacity"
            to: 0
            duration: EffectsManager.dur(splash.skipping ? 500 : splash.revealDuration)
            easing.type: Easing.InOutSine
        }
        ScriptAction {
            script: {
                splash.running = false;
                splash.revealing = false;
                splash.finished();
            }
        }
    }
}
