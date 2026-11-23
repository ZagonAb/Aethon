// Aethon
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
import QtQuick 2.15
import "../App"

QtObject {
    id: root

    property real windowWidth: 0
    property real windowHeight: 0
    property bool _initialized: false

    readonly property var ranges: [
        { name: "tiny4x3", minWidth: 300, maxWidth: 340, minHeight: 220, maxHeight: 260 },
        { name: "small4x3", minWidth: 630, maxWidth: 690, minHeight: 460, maxHeight: 520 },
        { name: "square720", minWidth: 700, maxWidth: 740, minHeight: 700, maxHeight: 740 },
        { name: "classic960", minWidth: 930, maxWidth: 990, minHeight: 690, maxHeight: 750 },
        { name: "classic1280", minWidth: 1250, maxWidth: 1310, minHeight: 930, maxHeight: 990 },
        { name: "mid1240", minWidth: 1200, maxWidth: 1280, minHeight: 1040, maxHeight: 1100 },
        { name: "wide1080", minWidth: 1860, maxWidth: 1980, minHeight: 1000, maxHeight: 1100 },
        { name: "wide1080", minWidth: 2340, maxWidth: 2460, minHeight: 1000, maxHeight: 1100 }
    ]

    function findContextFor(w, h) {
        for (var i = 0; i < root.ranges.length; i++) {
            var r = root.ranges[i];
            if (w >= r.minWidth && w <= r.maxWidth
                && h >= r.minHeight && h <= r.maxHeight)
                return r.name;
        }
        return "default";
    }

    function initialize() {
        root._initialized = true;
        root.evaluate();
    }

    function evaluate() {
        if (!root._initialized) return;
        if (root.windowWidth <= 0 || root.windowHeight <= 0) return;

        var ctx = root.findContextFor(root.windowWidth, root.windowHeight);
        SettingsManager.setActiveContext(ctx);
    }

    onWindowWidthChanged: root.evaluate()
    onWindowHeightChanged: root.evaluate()
}
