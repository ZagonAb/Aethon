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
    id: splash

    property string fontFamily: "Jet Brains Mono"
    property string titleText: "AETHON"
    property string subtitleText: "PEGASUS FRONTEND THEME"

    readonly property var themeColors: SettingsManager.getCurrentColors()

    property color backgroundColor: themeColors.bg
    property color titleColor: themeColors.fg
    property color subtitleColor: themeColors.muted

    property int logoInDuration: 1000
    property int titleInDuration: 700
    property int subtitleInDuration: 600
    property int titleDelay: 450
    property int subtitleDelay: 250
    property int pulseLoops: 2
    property int pulseUpDuration: 800
    property int pulseDownDuration: 800
    property int holdDuration: 300
    property int textFadeOutDuration: 700
    property int revealDuration: 1600

    property real slideDistanceFactor: 0.35
    property real logoStartScale: 0.94
    property real pulseMinOpacity: 0.35
    property bool glowEnabled: EffectsManager.shaderEffectsEnabled
    property real glowPeakOpacity: 0.55

    property real pulse: 1.0
    property real glowGate: 0.0

    property bool skippable: true

    property bool running: true
    property bool revealing: false
    property bool skipping: false

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
            logoGroup.x = 0;
            logoGroup.opacity = 1;
            logoGroup.scale = 1;
            titleLabel.opacity = 1;
            subtitleLabel.opacity = 1;
            loader.opacity = 1;
            loader.progress = 1;
            splash.pulse = 1.0;
            splash.glowGate = 1.0;
        }
    }

    Rectangle { id: bg; anchors.fill: parent; color: splash.backgroundColor }
    MouseArea { anchors.fill: parent; hoverEnabled: true }

    Column {
        id: content
        anchors.centerIn: parent
        spacing: Math.round(splash.height * 0.04)

        readonly property real logoSize: Math.min(splash.width * 0.35, splash.height * 0.45)
        readonly property real logoHeight: logoSize * (407 / 490)

        Item {
            id: logoBox
            anchors.horizontalCenter: parent.horizontalCenter
            width: content.logoSize
            height: content.logoHeight

            opacity: splash.pulseMinOpacity + (1.0 - splash.pulseMinOpacity) * splash.pulse

            Item {
                id: logoGroup
                width: parent.width
                height: parent.height
                x: -content.logoSize * splash.slideDistanceFactor
                opacity: 0
                scale: splash.logoStartScale

                Image {
                    id: logoSource
                    anchors.fill: parent
                    source: Qt.resolvedUrl("../assets/icons/aethon/aethon.svg")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    sourceSize.width: content.logoSize > 0 ? Math.round(content.logoSize) : 512
                    visible: false
                }

                ColorOverlay {
                    id: logoTinted
                    anchors.fill: logoSource
                    source: logoSource
                    color: splash.titleColor
                    visible: false
                }

                FastBlur {
                    id: logoGlow
                    anchors.fill: logoTinted
                    source: logoTinted
                    radius: 48
                    transparentBorder: true
                    visible: splash.glowEnabled
                    opacity: Math.max(0.001,
                                      splash.glowPeakOpacity * splash.pulse * splash.glowGate)
                }

                ShaderEffectSource {
                    id: logoImage
                    anchors.fill: logoTinted
                    sourceItem: logoTinted
                    smooth: true
                }
            }
        }

        Text {
            id: titleLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: splash.titleText
            color: splash.titleColor
            font.family: splash.fontFamily
            font.pixelSize: Math.round(content.logoSize * 0.25)
            font.weight: Font.Bold
            font.letterSpacing: 4
            renderType: Text.NativeRendering
            opacity: 0
        }

        Text {
            id: subtitleLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: splash.subtitleText
            color: splash.subtitleColor
            font.family: splash.fontFamily
            font.pixelSize: Math.round(content.logoSize * 0.08)
            font.letterSpacing: 2
            renderType: Text.NativeRendering
            opacity: 0
        }

        Item {
            id: loader
            anchors.horizontalCenter: parent.horizontalCenter
            width: content.logoSize * 0.9
            height: 2
            opacity: 0

            property real progress: 0

            Rectangle {
                anchors.fill: parent
                color: splash.subtitleColor
                opacity: 0.25
            }
            Rectangle {
                width: parent.width * loader.progress
                height: parent.height
                color: splash.titleColor
            }
        }
    }

    SequentialAnimation {
        id: sequence
        running: EffectsManager.animationsEnabled

        ParallelAnimation {
            ParallelAnimation {
                NumberAnimation {
                    target: logoGroup; property: "x"
                    to: 0
                    duration: EffectsManager.dur(splash.logoInDuration)
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: logoGroup; property: "opacity"
                    to: 1
                    duration: EffectsManager.dur(splash.logoInDuration)
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: logoGroup; property: "scale"
                    to: 1
                    duration: EffectsManager.dur(splash.logoInDuration)
                    easing.type: Easing.OutCubic
                }
            }

            SequentialAnimation {
                PauseAnimation { duration: EffectsManager.dur(splash.titleDelay) }
                ParallelAnimation {
                    NumberAnimation {
                        target: titleLabel; property: "opacity"
                        to: 1
                        duration: EffectsManager.dur(splash.titleInDuration)
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: titleLabel; property: "font.letterSpacing"
                        from: 14; to: 4
                        duration: EffectsManager.dur(splash.titleInDuration)
                        easing.type: Easing.OutCubic
                    }
                }
            }

            SequentialAnimation {
                PauseAnimation { duration: EffectsManager.dur(splash.titleDelay + splash.subtitleDelay) }
                ParallelAnimation {
                    NumberAnimation {
                        target: subtitleLabel; property: "opacity"
                        to: 1
                        duration: EffectsManager.dur(splash.subtitleInDuration)
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: loader; property: "opacity"
                        to: 1
                        duration: EffectsManager.dur(splash.subtitleInDuration)
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        ParallelAnimation {
            SequentialAnimation {
                loops: EffectsManager.loopingAnimationsEnabled ? splash.pulseLoops : 0

                NumberAnimation {
                    target: splash; property: "pulse"
                    from: 1.0; to: 0.0
                    duration: EffectsManager.dur(splash.pulseUpDuration)
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: splash; property: "pulse"
                    from: 0.0; to: 1.0
                    duration: EffectsManager.dur(splash.pulseDownDuration)
                    easing.type: Easing.InOutSine
                }
            }

            NumberAnimation {
                target: splash; property: "glowGate"
                from: 0.0; to: 1.0
                duration: EffectsManager.dur(splash.pulseUpDuration + splash.pulseDownDuration)
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                target: loader; property: "progress"
                from: 0; to: 1
                duration: EffectsManager.dur(splash.pulseLoops * (splash.pulseUpDuration + splash.pulseDownDuration))
                easing.type: Easing.InOutQuad
            }
        }

        ScriptAction {
            script: if (!EffectsManager.loopingAnimationsEnabled) {
                splash.pulse = 1.0;
                splash.glowGate = 1.0;
                loader.progress = 1.0;
            }
        }

        PauseAnimation { duration: EffectsManager.dur(splash.holdDuration) }

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
