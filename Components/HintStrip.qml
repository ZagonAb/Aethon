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
import "../Layout"

Item {
    id: root
    anchors.fill: parent

    property Item host: null

    property bool _noteOn: false
    property string _noteText: ""

    readonly property var colors: SettingsManager.getCurrentColors()
    readonly property bool _shown: NavigationManager.latched

    readonly property var _uiRefs: [
        Qt.resolvedUrl("../assets/icons/arrow-up.svg"),
        Qt.resolvedUrl("../assets/icons/arrow-down.svg"),
        Qt.resolvedUrl("../assets/icons/arrow-left.svg"),
        Qt.resolvedUrl("../assets/icons/arrow-right.svg"),
        Qt.resolvedUrl("../assets/systems/a.svg"),
        Qt.resolvedUrl("../assets/systems/b.svg")
    ]

    readonly property var _cueTokens: ["up", "down", "left", "right", "accept", "cancel"]
    readonly property var _glyphMap: [8593, 8595, 8592, 8594, 65, 66]

    readonly property real _pad: Math.max(6, Math.round(PocketMetrics.margin * 0.5))
    readonly property var _scr: host ? host.item : null
    readonly property real _cover: (_scr && _scr._cardTop !== undefined)
    ? Math.max(0, root.height - _scr._cardTop + _pad) : 0
    readonly property int _n: NavigationManager.cue.length
    readonly property real _availW: Math.max(0, root.width - _pad * 2)
    readonly property real _gapX: Math.round(PocketMetrics.spacing * 1.2)
    readonly property real _cell: Math.min(PocketMetrics.titleSize * 1.3 + _gapX,
                                           _availW / Math.max(1, _n))
    readonly property int _glyph: Math.floor(Math.min(PocketMetrics.titleSize * 1.3, _cell * 0.7))

    Connections {
        target: NavigationManager
        function onLatchedChanged() {
            if (!root.host) return;
            if (NavigationManager.latched) {
                Qt.callLater(function() { root.host.parent.forceActiveFocus(); });
            } else if (root.host.item) {
                root.host.item.forceActiveFocus();
            } else {
                root.host.parent.forceActiveFocus();
            }
        }
        function onTraceChanged() {
            var n = NavigationManager.trace.length;
            if (n === 0) idle.stop();
            else if (n < NavigationManager.cue.length) idle.restart();
        }
        function onCueDone() {
            idle.stop();
            SoundEngine.favorite();
            root._noteText = "★ " + SettingsManager.presetLabel().toUpperCase()
            + " " + Language.t("hint_done") + " ★";
            root._noteOn = true;
            fade.stop();
            hold.restart();
        }
    }

    TextMetrics {
        id: noteMetrics
        text: root._noteText
        font.pixelSize: PocketMetrics.titleSize * 0.9
        font.bold: true
        font.family: SettingsManager.fontFamily
    }

    Rectangle {
        id: note
        width: Math.min(root.width * 0.9, noteMetrics.width + root._pad * 4)
        height: noteMetrics.height + root._pad * 2
        x: Math.round((root.width - width) / 2)
        y: Math.max(root._pad,
                    Math.min(Math.round((root.height - height) / 2),
                             root.height - strip.height - height - root._pad))
        color: root.colors.card
        border.color: root.colors.accent
        border.width: 3
        radius: EffectsManager.r(8)
        visible: opacity > 0.01
        opacity: root._noteOn ? 1.0 : 0.0
        scale: root._noteOn ? 1.0 : 0.9
        z: 2

        Behavior on opacity {
            enabled: EffectsManager.animationsEnabled
            NumberAnimation { duration: EffectsManager.dur(260); easing.type: Easing.OutQuad }
        }
        Behavior on scale {
            enabled: EffectsManager.animationsEnabled
            NumberAnimation { duration: EffectsManager.dur(260); easing.type: Easing.OutBack }
        }

        Text {
            id: noteText
            anchors.centerIn: parent
            width: note.width - root._pad * 4
            text: root._noteText
            color: root.colors.accent
            font.pixelSize: PocketMetrics.titleSize * 0.9
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: 8
            font.bold: true
            font.family: SettingsManager.fontFamily
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Rectangle {
        id: strip
        anchors.bottom: parent.bottom
        width: parent.width
        height: Math.min(root.height * 0.6,
                         Math.max(root._cover, stripCol.height + root._pad * 2))
        color: root.colors.bg
        border.color: root.colors.accent
        border.width: 2
        opacity: root._shown ? 1.0 : 0.0
        visible: opacity > 0.01
        z: 1

        Behavior on opacity {
            enabled: EffectsManager.animationsEnabled
            NumberAnimation { duration: EffectsManager.dur(200); easing.type: Easing.OutQuad }
        }

        transform: Translate {
            y: root._shown ? 0 : strip.height
            Behavior on y {
                enabled: EffectsManager.animationsEnabled
                NumberAnimation { duration: EffectsManager.dur(250); easing.type: Easing.OutCubic }
            }
        }

        Column {
            id: stripCol
            anchors.centerIn: parent
            spacing: Math.round(PocketMetrics.spacing * 1.5)

            Text {
                text: Language.t("hint_caption")
                color: root.colors.muted
                font.pixelSize: PocketMetrics.bodySize * 0.9
                font.bold: true
                font.family: SettingsManager.fontFamily
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Row {
                spacing: 0
                anchors.horizontalCenter: parent.horizontalCenter

                Repeater {
                    model: NavigationManager.cue
                    delegate: Item {
                        width: root._cell
                        height: root._glyph * 1.2

                        readonly property var glyphData: ButtonGlyphs.glyph(root._cueTokens[modelData])
                        readonly property real currentOpacity: index < NavigationManager.trace.length ? 1.0 : 0.25

                        Text {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: Math.round(root._glyph * 0.06)
                            text: parent.glyphData.t
                            color: root.colors.accent
                            opacity: parent.currentOpacity
                            font.pixelSize: Math.round(root._glyph * 1.15)
                            font.family: parent.glyphData.icon ? FontManager.iconFamily : SettingsManager.fontFamily
                            font.bold: !parent.glyphData.icon

                            Behavior on opacity {
                                enabled: EffectsManager.animationsEnabled
                                NumberAnimation { duration: EffectsManager.dur(150) }
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: idle
        interval: 2000
        repeat: false
        onTriggered: NavigationManager.clear()
    }

    Timer {
        id: hold
        interval: 1000
        repeat: false
        onTriggered: {
            SettingsManager.mergePreset();
            NavigationManager.clear();
            fade.restart();
        }
    }

    Timer {
        id: fade
        interval: 1500
        repeat: false
        onTriggered: root._noteOn = false
    }
}
