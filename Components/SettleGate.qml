// Aethon
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
import QtQuick 2.15
import "../App"

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property var input: null
    property var placeholder: null
    property int settleDelay: EffectsManager.scrollSettleDelay
    property int fastThreshold: EffectsManager.scrollFastThreshold
    readonly property var output: root._output
    readonly property bool settling: root._settling

    signal settled(var value)

    property var _output: null
    property bool _settling: false
    property double _lastChange: 0

    function _hasValue(v) {
        return v !== null && v !== undefined;
    }

    function snap() {
        settleTimer.stop();
        root._lastChange = 0;
        root._output = root.input;
        root._settling = false;
    }

    function flush() {
        if (!root._settling)
            return;
        settleTimer.stop();
        root._output = root.input;
        root._settling = false;
        root.settled(root.input);
    }

    onInputChanged: {
        var now = Date.now();
        var elapsed = now - root._lastChange;
        root._lastChange = now;

        if (!root._hasValue(root.input) || root.settleDelay <= 0) {
            settleTimer.stop();
            root._output = root.input;
            root._settling = false;
            root.settled(root.input);
            return;
        }

        if (root._settling || elapsed < root.fastThreshold) {
            if (!root._settling) {
                root._output = root.placeholder;
                root._settling = true;
            }
            settleTimer.restart();
            return;
        }

        root._output = root.input;
        root.settled(root.input);
    }

    Timer {
        id: settleTimer
        interval: Math.max(1, root.settleDelay)
        repeat: false
        onTriggered: root.flush()
    }

    Component.onCompleted: root._output = root.input
}
