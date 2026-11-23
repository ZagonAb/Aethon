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

    property string fontFamily: FontManager.pixelFamily
    property string titleText: "AETHON"
    property string subtitleText: "PEGASUS"
    readonly property var themeColors: SettingsManager.getCurrentColors()
    property color backgroundColor: themeColors.bg
    property color titleColor: themeColors.fg
    property color subtitleColor: themeColors.muted
    property color shadowColor: themeColors.border
    property color accentColor: themeColors.accent || themeColors.fg
    readonly property real u: Math.max(1, Math.floor(Math.min(width, height) / 240))
    property int revealDuration: EffectsManager.dur(300)
    property bool skippable: true
    property bool running: true
    property bool revealing: false
    property bool skipping: false

    signal revealStarted()
    signal finished()

    visible: running
    focus: true
    z: 999

    property int lit: 0

    function skip() {
        if (!running || skipping) return;
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
        FontManager.requirePixelFont();
        forceActiveFocus();
    }

    Rectangle { id: bg; anchors.fill: parent; color: splash.backgroundColor }
    MouseArea { anchors.fill: parent; hoverEnabled: true }

    Item {
        id: content
        anchors.fill: parent
        opacity: 1

        Text {
            id: titleTextObj
            anchors.horizontalCenter: parent.horizontalCenter
            y: EffectsManager.animationsEnabled ? -height * 2 : Math.round(splash.height * 0.40 - height / 2)
            text: splash.titleText
            color: splash.titleColor
            font.pixelSize: Math.round(32 * splash.u)
            font.bold: true
            font.family: FontManager.pixelFamily
            renderType: Text.NativeRendering

            Text {
                text: parent.text
                color: splash.shadowColor
                font.pixelSize: parent.font.pixelSize
                font.bold: true
                font.family: FontManager.pixelFamily
                renderType: Text.NativeRendering
                x: splash.u
                y: splash.u
                z: -1
            }
        }

        Text {
            id: subtitleTextObj
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(splash.height * 0.54)
            text: splash.subtitleText
            color: splash.subtitleColor
            font.pixelSize: Math.round(9 * splash.u)
            font.family: FontManager.pixelFamily
            renderType: Text.NativeRendering
            opacity: 0
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(splash.height * 0.68)
            spacing: Math.round(2 * splash.u)

            Repeater {
                model: 8
                delegate: Rectangle {
                    width: Math.round(12 * splash.u)
                    height: Math.round(6 * splash.u)
                    color: index < splash.lit ? splash.accentColor : splash.subtitleColor
                    opacity: index < splash.lit ? 1.0 : 0.35
                }
            }
        }
    }

    SequentialAnimation {
        id: sequence
        running: EffectsManager.animationsEnabled
        PauseAnimation { duration: EffectsManager.dur(100) }

        NumberAnimation {
            target: titleTextObj; property: "y"
            to: Math.round(splash.height * 0.40 - titleTextObj.height / 2)
            duration: EffectsManager.dur(500)
            easing.type: Easing.OutQuad
        }

        NumberAnimation {
            target: subtitleTextObj; property: "opacity"
            to: 1.0
            duration: EffectsManager.dur(120)
            easing.type: Easing.OutQuad
        }

        NumberAnimation {
            target: splash; property: "lit"
            from: 0; to: 8
            duration: EffectsManager.dur(600)
            easing.type: Easing.Linear
        }

        PauseAnimation { duration: EffectsManager.dur(100) }

        ScriptAction { script: exitAnim.start() }
    }

    Timer {
        id: offTimer
        interval: 600
        running: !EffectsManager.animationsEnabled
        repeat: false
        onTriggered: {
            splash.lit = 8;
            subtitleTextObj.opacity = 1.0;
            exitAnim.start();
        }
    }

    Connections {
        target: splash
        function onRunningChanged() {
            if (running && !EffectsManager.animationsEnabled) {
                titleTextObj.y = Math.round(splash.height * 0.40 - titleTextObj.height / 2);
            }
        }
    }

    SequentialAnimation {
        id: exitAnim

        NumberAnimation {
            target: content; property: "opacity"
            to: 0
            duration: EffectsManager.dur(splash.skipping ? 80 : 120)
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
            duration: EffectsManager.dur(splash.skipping ? 200 : splash.revealDuration)
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
