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

FocusScope {
    id: root

    property TextInput target: null
    property bool active: false
    property string submitLabel: "SEARCH"
    property bool submitEnabled: true
    property bool showSearchButton: true
    property bool showHideButton: true

    signal submitted()
    signal canceled()
    signal exitRequested()

    function insertAtCursor(str) {
        if (!root.target) return;
        var isLetter = /^[a-zA-Z]$/.test(str);
        var toInsert = str;
        if (isLetter) {
            toInsert = root.shiftMode ? str.toUpperCase() : str.toLowerCase();
        }
        var t = root.target.text;
        var pos = root.target.cursorPosition;
        root.target.text = t.substring(0, pos) + toInsert + t.substring(pos);
        root.target.cursorPosition = pos + toInsert.length;
    }

    function deleteAtCursor() {
        if (!root.target) return;
        var t = root.target.text;
        var pos = root.target.cursorPosition;
        if (pos <= 0) return;
        root.target.text = t.substring(0, pos - 1) + t.substring(pos);
        root.target.cursorPosition = pos - 1;
    }

    function clearTarget() {
        if (!root.target) return;
        root.target.text = "";
        root.target.cursorPosition = 0;
    }

    readonly property var colors: SettingsManager.getCurrentColors()

    readonly property real keyGap: Math.max(2, Math.round(PocketMetrics.spacing * 0.15))
    readonly property real panelPad: Math.round(Math.min(PocketMetrics.margin * 0.5, 8))
    readonly property real keyboardWidth: {
        var pw = parent ? parent.width : 900;
        var maxW = Math.min(pw - PocketMetrics.margin * 2, 900);
        return Math.floor(Math.max(200, maxW));
    }
    readonly property real keyWidth: Math.floor((root.keyboardWidth - 9 * root.keyGap) / 10)
    readonly property real keyHeight: Math.round(Math.max(28, Math.min(root.keyWidth * 0.85, 56)))
    readonly property real actionKeyHeight: Math.round(Math.max(34, root.keyHeight * 0.9))
    readonly property real keyboardHeight: 3 * root.keyHeight + root.actionKeyHeight + 3 * root.keyGap
    readonly property real totalHeight: root.keyboardHeight + root.panelPad * 2

    property bool symbolsMode: false
    property bool shiftMode: false
    property string keyZone: "grid"
    property int keyRow: 0
    property int keyCol: 0
    property int actionIndex: 0
    property string _pressedKey: ""

    onActiveChanged: {
        if (root.active) {
            Qt.callLater(function() {
                if (root.active) root.forceActiveFocus();
            });
        }
    }

    onActiveFocusChanged: {
        if (activeFocus) {
            root.keyZone = "grid";
            root.keyRow = 0;
            root.keyCol = 0;
            if (root.target) root.target.cursorPosition = root.target.text.length;
        }
    }

    readonly property var actionModel: {
        var arr = [];
        arr.push({ key: "shift", label: "Aa" });
        arr.push({ key: "symbols", label: root.symbolsMode ? "ABC" : "?123" });
        arr.push({ key: "space", label: "SPACE" });
        arr.push({ key: "del", label: "DEL" });
        arr.push({ key: "clear", label: "CLR" });
        if (root.showHideButton) arr.push({ key: "hide", label: "HIDE" });
        if (root.showSearchButton) arr.push({ key: "submit", label: root.submitLabel });
        return arr;
    }

    readonly property var _actionWeights: ({
        shift: 8, symbols: 11, space: 28, del: 10, clear: 10, hide: 11, submit: 22
    })

    function _weightOf(actionKey) {
        return root._actionWeights[actionKey] || 10;
    }

    function actionWidth(i) {
        var n = root.actionModel.length;
        var avail = root.keyboardWidth - (n - 1) * root.keyGap;
        var totalW = 0;
        for (var k = 0; k < n; k++) totalW += root._weightOf(root.actionModel[k].key);
        if (i >= n - 1) {
            var used = 0;
            for (var j = 0; j < n - 1; j++) {
                used += Math.floor(avail * root._weightOf(root.actionModel[j].key) / totalW);
            }
            return avail - used;
        }
        return Math.floor(avail * root._weightOf(root.actionModel[i].key) / totalW);
    }

    readonly property var letterRows: [
        ["Q","W","E","R","T","Y","U","I","O","P"],
        ["A","S","D","F","G","H","J","K","L"],
        ["Z","X","C","V","B","N","M"]
    ]
    readonly property var symbolRows: [
        ["1","2","3","4","5","6","7","8","9","0"],
        ["-","_",".",",",";",":","/","!","?"],
        ["@","#","$","%","&","*","+","=","(",")"]
    ]
    readonly property var currentRows: root.symbolsMode ? root.symbolRows : root.letterRows

    readonly property var keyModel: {
        var rows = root.currentRows;
        var arr = [];
        for (var r = 0; r < rows.length; r++) {
            for (var c = 0; c < rows[r].length; c++) {
                arr.push({ char: rows[r][c], row: r, col: c, rowCount: rows[r].length });
            }
        }
        return arr;
    }

    function _rowCount(r) {
        var rows = root.currentRows;
        return (r >= 0 && r < rows.length) ? rows[r].length : 0;
    }

    Timer {
        id: keyPressTimer
        interval: 90
        repeat: false
        onTriggered: root._pressedKey = ""
    }

    function _triggerKeyPress(id) {
        root._pressedKey = id;
        keyPressTimer.restart();
    }

    component VKey: Rectangle {
        id: vk
        property var theme: null
        property string label: ""
        property bool selected: false
        property bool dimmed: false
        property real fontBase: 40
        property real fontScale: 0.4
        property bool pressed: false

        radius: 0
        antialiasing: false
        color: vk.selected ? vk.theme.accent : vk.theme.card
        border.width: 1
        border.color: vk.selected ? vk.theme.accent : vk.theme.border
        opacity: vk.dimmed ? 0.35 : 1.0

        scale: vk.pressed ? 0.93 : 1.0
        layer.enabled: vk.pressed || scale < 0.999
        layer.smooth: true

        Behavior on scale {
            enabled: EffectsManager.animationsEnabled
            NumberAnimation {
                duration: EffectsManager.dur(vk.pressed ? 60 : 180)
                easing.type: vk.pressed ? Easing.OutQuad : Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            color: vk.theme.fg
            opacity: vk.pressed ? 0.10 : 0.0
            Behavior on opacity {
                enabled: EffectsManager.animationsEnabled
                NumberAnimation {
                    duration: EffectsManager.dur(vk.pressed ? 60 : 180)
                    easing.type: Easing.OutQuad
                }
            }
        }

        Text {
            anchors.centerIn: parent
            width: parent.width - 4
            height: parent.height - 4
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: vk.label
            color: vk.selected ? vk.theme.bg : vk.theme.fg
            font.pixelSize: Math.max(10, Math.round(vk.fontBase * vk.fontScale))
            fontSizeMode: Text.Fit
            minimumPixelSize: 8
            font.family: SettingsManager.fontFamily
        }
    }

    Item {
        id: keyboardContainer
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.bottom: parent ? parent.bottom : undefined
        anchors.bottomMargin: PocketMetrics.spacing + root.panelPad
        width: root.keyboardWidth
        height: root.keyboardHeight

        Rectangle {
            anchors.fill: parent
            anchors.margins: -root.panelPad
            color: root.colors.bg
            border.width: 1
            border.color: root.colors.border
            radius: 0
            antialiasing: false
        }

        Repeater {
            model: root.keyModel

            delegate: VKey {
                readonly property real rowFullWidth: modelData.rowCount * root.keyWidth
                + (modelData.rowCount - 1) * root.keyGap
                readonly property real rowOffset: Math.round((root.keyboardWidth - rowFullWidth) / 2)

                theme: root.colors
                label: root.shiftMode ? modelData.char : modelData.char.toLowerCase()
                fontBase: root.keyHeight
                fontScale: 0.42
                selected: root.activeFocus
                && root.keyZone === "grid"
                && modelData.row === root.keyRow
                && modelData.col === root.keyCol
                pressed: root._pressedKey === "grid:" + modelData.row + ":" + modelData.col

                x: rowOffset + modelData.col * (root.keyWidth + root.keyGap)
                y: modelData.row * (root.keyHeight + root.keyGap)
                width: root.keyWidth
                height: root.keyHeight
            }
        }

        Row {
            id: actionsRow
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            height: root.actionKeyHeight
            spacing: root.keyGap

            Repeater {
                model: root.actionModel

                delegate: VKey {
                    theme: root.colors
                    label: modelData.label
                    fontBase: root.actionKeyHeight
                    fontScale: 0.36
                    width: root.actionWidth(index)
                    height: root.actionKeyHeight
                    selected: root.activeFocus
                    && root.keyZone === "actions"
                    && root.actionIndex === index
                    dimmed: modelData.key === "submit" && !root.submitEnabled
                    pressed: root._pressedKey === "action:" + index
                    || (modelData.key === "shift" && root.shiftMode)
                }
            }
        }
    }

    function moveInKeyboard(dx, dy) {
        var nActions = root.actionModel.length;
        if (root.keyZone === "grid") {
            var newRow = root.keyRow + dy;
            var newCol = root.keyCol + dx;
            if (newRow >= 0 && newRow < 3) {
                var maxCol = root._rowCount(newRow) - 1;
                if (newCol < 0) newCol = 0;
                if (newCol > maxCol) newCol = maxCol;
                root.keyRow = newRow;
                root.keyCol = newCol;
                SoundEngine.scroll();
                return;
            }
            if (newRow >= 3) {
                root.keyZone = "actions";
                root.actionIndex = Math.min(root.keyCol, nActions - 1);
                SoundEngine.scroll();
                return;
            }
            if (newRow < 0) {
                root.exitRequested();
                SoundEngine.scroll();
                return;
            }
        } else if (root.keyZone === "actions") {
            if (dy < 0) {
                root.keyZone = "grid";
                root.keyRow = 2;
                var lastMax = root._rowCount(2) - 1;
                root.keyCol = Math.min(root.actionIndex, lastMax);
                SoundEngine.scroll();
                return;
            }
            var newIdx = root.actionIndex + dx;
            if (newIdx >= 0 && newIdx < nActions) {
                root.actionIndex = newIdx;
                SoundEngine.scroll();
            }
        }
    }

    function pressKey() {
        if (root.keyZone === "grid") {
            var rows = root.currentRows;
            if (root.keyRow < rows.length && root.keyCol < rows[root.keyRow].length) {
                root._triggerKeyPress("grid:" + root.keyRow + ":" + root.keyCol);
                var c = rows[root.keyRow][root.keyCol];
                root.insertAtCursor(c);
                SoundEngine.select();
            }
        } else if (root.keyZone === "actions") {
            var idx = root.actionIndex;
            if (idx < 0 || idx >= root.actionModel.length) return;
            var action = root.actionModel[idx];
            root._triggerKeyPress("action:" + idx);
            switch (action.key) {
                case "shift":
                    root.shiftMode = !root.shiftMode;
                    SoundEngine.select();
                    break;
                case "symbols":
                    root.symbolsMode = !root.symbolsMode;
                    root.keyRow = 0;
                    root.keyCol = 0;
                    SoundEngine.select();
                    break;
                case "space":
                    root.insertAtCursor(" ");
                    SoundEngine.select();
                    break;
                case "del":
                    root.deleteAtCursor();
                    SoundEngine.scroll();
                    break;
                case "clear":
                    root.clearTarget();
                    SoundEngine.select();
                    break;
                case "hide":
                    root.exitRequested();
                    SoundEngine.back();
                    break;
                case "submit":
                    root.submitted();
                    break;
            }
        }
    }

    function moveCursor(delta) {
        if (!root.target) return;
        var np = Math.max(0, Math.min(root.target.text.length, root.target.cursorPosition + delta));
        if (np !== root.target.cursorPosition) {
            root.target.cursorPosition = np;
            SoundEngine.scroll();
        }
    }

    function _handleCursorKeys(event) {
        if (event.text && event.text.length > 0 && event.text.charCodeAt(0) >= 32) return false;
        if (api.keys.isPrevPage(event)) { event.accepted = true; root.moveCursor(-1); return true; }
        if (api.keys.isNextPage(event)) { event.accepted = true; root.moveCursor(1); return true; }
        return false;
    }

    function _handlePhysicalTyping(event) {
        if (!root.activeFocus) return false;
        if (event.key === Qt.Key_Backspace) {
            event.accepted = true;
            root.deleteAtCursor();
            return true;
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            event.accepted = true;
            root.submitted();
            return true;
        }
        if (!event.text) return false;
        if (event.text.charCodeAt(0) < 32) return false;
        event.accepted = true;
        root.insertAtCursor(event.text);
        return true;
    }

    Keys.onLeftPressed: {
        event.accepted = true;
        root.moveInKeyboard(-1, 0);
    }

    Keys.onRightPressed: {
        event.accepted = true;
        root.moveInKeyboard(1, 0);
    }

    Keys.onUpPressed: {
        event.accepted = true;
        root.moveInKeyboard(0, -1);
    }

    Keys.onDownPressed: {
        event.accepted = true;
        root.moveInKeyboard(0, 1);
    }

    Keys.onPressed: {
        if (root._handlePhysicalTyping(event)) return;
        if (root._handleCursorKeys(event)) return;

        if (event.key === Qt.Key_Escape) {
            event.accepted = true;
            root.canceled();
            return;
        }
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.pressKey();
            return;
        }
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.canceled();
            return;
        }
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.deleteAtCursor();
            SoundEngine.scroll();
            return;
        }
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.clearTarget();
            SoundEngine.select();
            return;
        }
    }
}
