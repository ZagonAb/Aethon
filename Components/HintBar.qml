// Aethon
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
import QtQuick 2.15
import "../App"
import "../Layout"

Item {
    id: root

    property string text: ""
    property real textSize: PocketMetrics.bodySize * 0.7
    property real iconScale: 1.6
    property real iconNudge: 0.12
    property color color: SettingsManager.getCurrentColors().muted
    property real contentOpacity: 0.7

    readonly property real iconSize: textSize * iconScale

    implicitHeight: Math.ceil(strip.height * strip.scale)

    function _parse(s) {
        var out = [];
        var parts = String(s).split("|");
        for (var i = 0; i < parts.length; i++) {
            var p = parts[i].trim();
            if (p === "") continue;
            var m = /^((?:\{\w+\})+)\s*:?\s*([\s\S]*)$/.exec(p);
            if (m) {
                var toks = m[1].match(/\{(\w+)\}/g).map(function(t) { return t.slice(1, -1); });
                out.push({ tokens: toks, label: m[2] });
            } else {
                out.push({ tokens: [], label: p });
            }
        }
        return out;
    }

    readonly property var _chunks: _parse(text)

    Text {
        id: refIcon
        visible: false
        text: "\u2198"
        font.pixelSize: root.iconSize
        font.family: FontManager.iconFamily
    }
    Text {
        id: refLabel
        visible: false
        text: "H"
        font.pixelSize: root.textSize
        font.family: SettingsManager.fontFamily
    }
    TextMetrics {
        id: iconM
        font: refIcon.font
        text: refIcon.text
    }
    TextMetrics {
        id: labelM
        font: refLabel.font
        text: refLabel.text
    }

    readonly property real _iconCenter: refIcon.baselineOffset
    + iconM.tightBoundingRect.y + iconM.tightBoundingRect.height / 2
    readonly property real _labelCenter: refLabel.baselineOffset
    + labelM.tightBoundingRect.y + labelM.tightBoundingRect.height / 2

    readonly property real _iconY: Math.max(0, _labelCenter - _iconCenter)
    + Math.round(iconSize * iconNudge)
    readonly property real _labelY: Math.max(0, _iconCenter - _labelCenter)

    Row {
        id: strip
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Math.round(root.textSize * 1.4)
        opacity: root.contentOpacity
        scale: (root.width > 0 && width > root.width) ? root.width / width : 1.0

        Repeater {
            model: root._chunks

            delegate: Row {
                id: chunk
                spacing: Math.round(root.textSize * 0.25)

                readonly property bool plain: {
                    var toks = modelData.tokens;
                    for (var i = 0; i < toks.length; i++)
                        if (!ButtonGlyphs.glyph(toks[i]).icon) return true;
                        return false;
                }

                Repeater {
                    model: modelData.tokens

                    delegate: Text {
                        readonly property var g: ButtonGlyphs.glyph(modelData)
                        y: g.icon ? root._iconY : root._labelY
                        text: g.t
                        color: root.color
                        font.pixelSize: g.icon ? root.iconSize : root.textSize
                        font.family: g.icon ? FontManager.iconFamily : SettingsManager.fontFamily
                    }
                }

                Text {
                    y: root._labelY
                    text: (chunk.plain ? ": " : " ") + modelData.label
                    color: root.color
                    font.pixelSize: root.textSize
                    font.family: SettingsManager.fontFamily
                }
            }
        }
    }
}
