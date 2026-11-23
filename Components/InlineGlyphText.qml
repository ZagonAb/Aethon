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
    property real textSize: PocketMetrics.bodySize
    property color color: SettingsManager.getCurrentColors().muted
    property bool bold: false
    property real iconScale: 1.3
    property real iconNudge: 0.06
    property real maxWidth: 0

    readonly property real iconSize: textSize * iconScale

    implicitWidth: Math.ceil(strip.width * strip.scale)
    implicitHeight: Math.ceil(strip.height * strip.scale)

    function _parse(s) {
        var out = [];
        var re = /\{(\w+)\}/g;
        var src = String(s);
        var last = 0, m;
        while ((m = re.exec(src)) !== null) {
            if (m.index > last) out.push({ t: src.substring(last, m.index), tok: "" });
            out.push({ t: "", tok: m[1] });
            last = m.index + m[0].length;
        }
        if (last < src.length) out.push({ t: src.substring(last), tok: "" });
        return out;
    }

    readonly property var _segments: _parse(text)

    Row {
        id: strip
        spacing: 0
        height: root.iconSize * 1.1
        transformOrigin: Item.TopLeft
        scale: (root.maxWidth > 0 && width > root.maxWidth) ? root.maxWidth / width : 1.0

        Repeater {
            model: root._segments

            delegate: Item {
                readonly property var g: modelData.tok !== "" ? ButtonGlyphs.glyph(modelData.tok) : null
                readonly property bool isIcon: g !== null && g.icon

                width: label.width
                height: strip.height

                Text {
                    id: label
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: parent.isIcon ? Math.round(root.iconSize * root.iconNudge) : 0
                    text: parent.g ? parent.g.t : modelData.t
                    color: root.color
                    font.pixelSize: parent.isIcon ? root.iconSize : root.textSize
                    font.family: parent.isIcon ? FontManager.iconFamily : SettingsManager.fontFamily
                    font.bold: parent.isIcon ? false : root.bold
                }
            }
        }
    }
}
