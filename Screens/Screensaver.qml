// Aethon
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
import QtQuick 2.15
import QtGraphicalEffects 1.15
import "../App"

FocusScope {
    id: root
    anchors.fill: parent
    visible: opacity > 0.01
    opacity: 0
    z: 9999

    signal deactivated()

    property bool enabled: true
    property bool active: false
    property int timeout: 180000
    property real intro: 0
    property real beat: 0
    property real ripple: 0
    property real ripple2: 0
    property bool beating: false

    readonly property color fg: SettingsManager.getCurrentColors().fg
    readonly property real reach: Math.sqrt(width * width + height * height) / 2

    onEnabledChanged: console.log("[Screensaver] Enabled changed to:", root.enabled)

    Timer {
        id: timer
        interval: root.timeout
        running: root.enabled && !root.active
        repeat: false
        onTriggered: {
            console.log("[Screensaver] ¡Timer de inactividad disparado!");
            root.activate();
        }
    }

    Timer {
        id: beatDelay
        interval: 1500
        repeat: false
        onTriggered: if (EffectsManager.loopingAnimationsEnabled) root.beating = true;
    }

    function reset() {
        if (root.active || !root.enabled) return;
        timer.restart();
    }

    function activate() {
        if (root.active || !root.enabled) return;
        console.log("[Screensaver] ¡ACTIVANDO protector de pantalla!");
        root.active = true;
        root.opacity = 1;
        root.intro = 1;
        beatDelay.restart();
        root.forceActiveFocus();
    }

    function deactivate() {
        if (!root.active) return;
        root.active = false;
        beatDelay.stop();
        root.opacity = 0;
        root.intro = 0;
        root.deactivated();
        timer.restart();
    }

    onVisibleChanged: {
        if (!visible) {
            root.beating = false;
            root.beat = 0;
            root.ripple = 0;
            root.ripple2 = 0;
        }
    }

    Behavior on opacity {
        enabled: EffectsManager.animationsEnabled
        NumberAnimation {
            duration: EffectsManager.dur(root.active ? 1400 : 600)
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on intro {
        enabled: EffectsManager.animationsEnabled
        NumberAnimation {
            duration: EffectsManager.dur(root.active ? 2400 : 450)
            easing.type: root.active ? Easing.OutCubic : Easing.InCubic
        }
    }

    ParallelAnimation {
        running: root.beating
        loops: Animation.Infinite

        SequentialAnimation {
            NumberAnimation { target: root; property: "beat"; to: 1.0; duration: EffectsManager.dur(140); easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "beat"; to: 0.18; duration: EffectsManager.dur(150); easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "beat"; to: 0.65; duration: EffectsManager.dur(120); easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "beat"; to: 0.0; duration: EffectsManager.dur(650); easing.type: Easing.InOutSine }
            PauseAnimation { duration: EffectsManager.dur(900) }
        }

        NumberAnimation {
            target: root; property: "ripple"
            from: 0; to: 1
            duration: EffectsManager.dur(1960)
            easing.type: Easing.OutSine
        }

        SequentialAnimation {
            PauseAnimation { duration: EffectsManager.dur(290) }
            NumberAnimation {
                target: root; property: "ripple2"
                from: 0; to: 1
                duration: EffectsManager.dur(1670)
                easing.type: Easing.OutSine
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
    }

    RadialGradient {
        anchors.centerIn: parent
        width: root.reach * 2
        height: width
        opacity: root.intro * (0.14 + 0.24 * root.beat)
        scale: 0.96 + 0.06 * root.beat
        visible: EffectsManager.shaderEffectsEnabled
        gradient: Gradient {
            GradientStop { position: 0.00; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.55) }
            GradientStop { position: 0.18; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.22) }
            GradientStop { position: 0.50; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06) }
            GradientStop { position: 1.00; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.0) }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: stage.width + root.ripple * (root.reach * 2 - stage.width)
        height: width
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: root.fg
        opacity: root.beating ? root.intro * 0.30 * Math.pow(1.0 - root.ripple, 2) : 0
        visible: EffectsManager.shaderEffectsEnabled
    }

    Rectangle {
        anchors.centerIn: parent
        width: stage.width + root.ripple2 * (root.reach * 2 - stage.width)
        height: width
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: root.fg
        opacity: root.beating ? root.intro * 0.16 * Math.pow(1.0 - root.ripple2, 2) : 0
        visible: EffectsManager.shaderEffectsEnabled
    }

    Item {
        id: stage
        anchors.centerIn: parent
        width: Math.min(root.width * 0.25, root.height * 0.35)
        height: width * (407 / 490)

        Item {
            id: logoContainer
            anchors.fill: parent
            scale: (0.80 + 0.20 * root.intro) * (1.0 + 0.07 * root.beat)
            opacity: root.intro

            Image {
                id: logoSource
                anchors.fill: parent
                source: Qt.resolvedUrl("../assets/icons/aethon/aethon.svg")
                fillMode: Image.PreserveAspectFit
                smooth: true
                sourceSize.width: 512
                visible: false
            }

            ColorOverlay {
                anchors.fill: logoSource
                source: logoSource
                color: root.fg
                opacity: 0.55 + 0.45 * root.beat
                visible: EffectsManager.shaderEffectsEnabled
            }

            Image {
                anchors.fill: parent
                source: logoSource.source
                fillMode: Image.PreserveAspectFit
                smooth: true
                visible: !EffectsManager.shaderEffectsEnabled
                opacity: 0.55 + 0.45 * root.beat
            }
        }
    }

    Keys.onPressed: {
        event.accepted = true;
        root.deactivate();
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.deactivate()
    }
}
