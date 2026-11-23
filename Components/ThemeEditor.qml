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
    anchors.fill: parent
    focus: false
    visible: false
    z: 200

    signal closed()
    signal saved(string name, var colors)

    property color bgColor: "#000000"
    property color fgColor: "#ffffff"
    property color accentColor: "#ffffff"
    property color cardColor: "#0a0a0a"
    property color mutedColor: "#aaaaaa"
    property color borderColor: "#333333"
    property string themeName: ""
    property string originalName: ""
    readonly property bool editing: originalName !== ""
    property string zone: "channels"
    property int channelIndex: 0
    property int componentIndex: 0
    property int buttonIndex: 0
    readonly property bool nameFocused: zone === "name"
    readonly property int channelCount: 6
    property int holdCount: 0
    property real lastAdjustTime: 0
    property int lastAdjustDir: 0
    readonly property real shortSide: Math.min(width, height)
    readonly property bool compact: height < 560
    readonly property real margin: Math.round(Math.min(PocketMetrics.margin, shortSide * 0.05))
    readonly property real gap: Math.round(Math.max(6, Math.min(PocketMetrics.spacing * (compact ? 0.5 : 0.75), shortSide * 0.025)))
    readonly property real titleFont: Math.round(Math.max(16, Math.min(PocketMetrics.titleSize, shortSide * 0.06)))
    readonly property real bodyFont: Math.round(Math.max(11, Math.min(PocketMetrics.bodySize, shortSide * 0.04)))
    readonly property real smallFont: Math.max(10, Math.round(bodyFont * 0.8))
    readonly property real channelSpacing: Math.round(gap * (compact ? 0.3 : 0.5))
    readonly property real rowHeight: {
        var free = flick.height - 8 - previewHeight - fieldHeight - gap * 2 - channelSpacing * (channelCount - 1);
        return Math.round(Math.min(56, Math.max(36, free / channelCount)));
    }
    readonly property real previewTitleFont: Math.round(titleFont * (compact ? 0.85 : 1.05))
    readonly property real previewBodyFont: compact ? smallFont : bodyFont
    readonly property real previewSmallFont: Math.max(10, compact ? smallFont - 2 : smallFont)
    readonly property real previewTextHeight: Math.ceil((previewTitleFont + previewBodyFont + previewSmallFont) * 1.25) + 4
    readonly property real previewHeight: Math.round(Math.max(Math.min(120, Math.max(56, shortSide * (compact ? 0.12 : 0.13))), previewTextHeight + gap * 1.2))
    readonly property real fieldHeight: Math.round(Math.max(34, bodyFont * (compact ? 2.3 : 2.6)))
    readonly property real buttonHeight: Math.round(Math.max(34, bodyFont * (compact ? 2.2 : 2.4)))
    readonly property real headerBand: Math.round(Math.min(PocketMetrics.headerHeight, height * 0.10))
    readonly property real panelWidth: Math.min(width - margin * 2, shortSide * 1.5)
    readonly property var channelNames: [
        Language.t("settings_custom_theme_bg"),
        Language.t("settings_custom_theme_fg"),
        Language.t("settings_custom_theme_accent"),
        Language.t("settings_custom_theme_card"),
        Language.t("settings_custom_theme_muted"),
        Language.t("settings_custom_theme_border")
    ]
    readonly property var componentLetters: ["R", "G", "B"]

    function open(editName) {
        var existing = (editName !== undefined && editName !== "")
        ? SettingsManager.customThemes[editName] : undefined;
        var c = existing !== undefined ? existing : SettingsManager.getCurrentColors();
        root.originalName = existing !== undefined ? editName : "";

        root.bgColor = c.bg;
        root.fgColor = c.fg;
        root.accentColor = c.accent;
        root.cardColor = c.card;
        root.mutedColor = c.muted;
        root.borderColor = c.border;

        root.themeName = root.originalName;
        nameInput.text = root.originalName;
        root.channelIndex = 0;
        root.componentIndex = 0;
        root.buttonIndex = 0;
        root.holdCount = 0;
        root.lastAdjustDir = 0;
        flick.contentY = 0;
        root.visible = true;
        root.forceActiveFocus();
        root.setZone("channels");
    }

    function close() {
        root.zone = "channels";
        root.buttonIndex = 0;
        nameInput.focus = false;
        root.focus = false;
        root.visible = false;
        root.closed();
    }

    function setZone(z) {
        root.zone = z;
        if (z === "name") {
            nameInput.forceActiveFocus();
        } else {
            nameInput.focus = false;
            root.forceActiveFocus();
        }
    }

    function getChannelColor(idx) {
        switch (idx) {
            case 0: return root.bgColor;
            case 1: return root.fgColor;
            case 2: return root.accentColor;
            case 3: return root.cardColor;
            case 4: return root.mutedColor;
            case 5: return root.borderColor;
        }
        return "#000000";
    }

    function setChannelColor(idx, col) {
        switch (idx) {
            case 0: root.bgColor = col; break;
            case 1: root.fgColor = col; break;
            case 2: root.accentColor = col; break;
            case 3: root.cardColor = col; break;
            case 4: root.mutedColor = col; break;
            case 5: root.borderColor = col; break;
        }
    }

    function getComponentValue(channel, comp) {
        var col = root.getChannelColor(channel);
        if (comp === 0) return Math.round(col.r * 255);
        if (comp === 1) return Math.round(col.g * 255);
        return Math.round(col.b * 255);
    }

    function setComponentValue(channel, comp, value) {
        var v = Math.max(0, Math.min(255, Math.round(value)));
        var r = root.getComponentValue(channel, 0);
        var g = root.getComponentValue(channel, 1);
        var b = root.getComponentValue(channel, 2);
        if (comp === 0) r = v;
        else if (comp === 1) g = v;
        else b = v;
        root.setChannelColor(channel, Qt.rgba(r / 255, g / 255, b / 255, 1));
    }

    function stepFor(n) {
        return n < 8 ? 1 : n < 16 ? 2 : n < 28 ? 4 : n < 44 ? 8 : 16;
    }

    function registerAdjust(delta, isAutoRepeat) {
        var now = Date.now();
        var holding = isAutoRepeat
        || (delta === root.lastAdjustDir && now - root.lastAdjustTime < 100);
        root.holdCount = holding ? root.holdCount + 1 : 0;
        root.lastAdjustTime = now;
        root.lastAdjustDir = delta;
    }

    function adjustComponent(delta) {
        var cur = root.getComponentValue(root.channelIndex, root.componentIndex);
        root.setComponentValue(root.channelIndex, root.componentIndex,
                               cur + delta * root.stepFor(root.holdCount));
    }

    function cycleComponent(delta) {
        if (root.zone !== "channels") return;
        root.componentIndex = (root.componentIndex + delta + 3) % 3;
    }

    function moveVertical(delta) {
        SoundEngine.scroll();
        var last = root.channelCount - 1;
        if (root.zone === "name") {
            if (delta > 0) { root.channelIndex = 0; root.setZone("channels"); }
            else { root.buttonIndex = 0; root.setZone("buttons"); }
        } else if (root.zone === "channels") {
            if (delta > 0) {
                if (root.channelIndex === last) { root.buttonIndex = 0; root.setZone("buttons"); }
                else root.channelIndex += 1;
            } else {
                if (root.channelIndex === 0) root.setZone("name");
                else root.channelIndex -= 1;
            }
        } else {
            if (delta < 0) { root.channelIndex = last; root.setZone("channels"); }
            else { root.setZone("name"); }
        }
        root.ensureActiveVisible();
    }

    function moveHorizontal(delta) {
        if (root.zone === "name") return;
        SoundEngine.scroll();
        if (root.zone === "buttons") root.buttonIndex = delta > 0 ? 1 : 0;
        else if (root.zone === "channels") root.adjustComponent(delta);
    }

    function activate() {
        if (root.zone === "buttons") {
            if (root.buttonIndex === 0) {
                SoundEngine.select();
                root.save();
            } else {
                SoundEngine.back();
                root.close();
            }
        } else if (root.zone === "channels") {
            SoundEngine.select();
            root.buttonIndex = 0;
            root.setZone("buttons");
        } else {
            SoundEngine.select();
            root.channelIndex = 0;
            root.setZone("channels");
            root.ensureActiveVisible();
        }
    }

    function scrollTo(target) {
        var maxY = Math.max(0, flick.contentHeight - flick.height);
        target = Math.max(0, Math.min(maxY, target));
        if (Math.abs(target - flick.contentY) < 1) return;
        scrollAnim.stop();
        scrollAnim.to = target;
        scrollAnim.start();
    }

    function ensureActiveVisible() {
        if (root.zone === "buttons") return;
        if (root.zone === "name") { root.scrollTo(0); return; }

        var item = channelRepeater.itemAt(root.channelIndex);
        if (!item) return;
        var y = item.mapToItem(flick.contentItem, 0, 0).y;
        var top = y - root.gap;
        var bottom = y + item.height + root.gap;
        if (top < flick.contentY) root.scrollTo(top);
        else if (bottom > flick.contentY + flick.height) root.scrollTo(bottom - flick.height);
    }

    function nameTaken(n) {
        if (root.editing && n === root.originalName) return false;
        return SettingsManager.customThemes[n] !== undefined
        || SettingsManager.themeColors[n] !== undefined;
    }

    function resolveName() {
        var n = root.themeName.trim();
        var base = n !== "" ? n : Language.t("settings_custom_theme_name_placeholder");
        var candidate = base;
        var i = 2;
        while (root.nameTaken(candidate)) {
            candidate = base + " " + i;
            i++;
        }
        return candidate;
    }

    function save() {
        var newColors = {
            bg: root.bgColor.toString(),
            fg: root.fgColor.toString(),
            accent: root.accentColor.toString(),
            card: root.cardColor.toString(),
            muted: root.mutedColor.toString(),
            border: root.borderColor.toString()
        };
        root.saved(root.resolveName(), newColors);
        root.close();
    }

    function keyIs(fnName, event) {
        return typeof api.keys[fnName] === "function" && api.keys[fnName](event);
    }

    NumberAnimation {
        id: scrollAnim
        target: flick
        property: "contentY"
        duration: 120
        easing.type: Easing.OutCubic
    }

    Rectangle {
        anchors.fill: parent
        color: root.bgColor
        opacity: 1.0
    }

    Item {
        id: panel
        x: Math.round((root.width - width) / 2)
        width: root.panelWidth
        height: root.height

        Item {
            id: headerArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.headerBand

            TextMetrics {
                id: titleInk
                text: "H0"
                font.pixelSize: root.titleFont
                font.family: SettingsManager.fontFamily
                font.bold: true
            }

            Text {
                id: titleText
                anchors.left: parent.left
                y: Math.round(parent.height / 2 - (baselineOffset + titleInk.tightBoundingRect.y
                + titleInk.tightBoundingRect.height / 2))
                width: parent.width
                elide: Text.ElideRight
                text: root.editing ? Language.t("settings_custom_theme_editor_title")
                : Language.t("settings_custom_theme_new_title")
                color: root.accentColor
                font.pixelSize: root.titleFont
                font.bold: true
                font.family: SettingsManager.fontFamily
            }
        }

        Column {
            id: footer
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.margin * 0.6
            width: parent.width
            spacing: root.gap * 0.6

            Rectangle {
                width: parent.width
                height: 1
                color: root.borderColor
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: root.gap * 1.5

                Repeater {
                    model: 2
                    delegate: Rectangle {
                        id: btn
                        readonly property bool focused: root.zone === "buttons" && root.buttonIndex === index
                        width: Math.max(root.bodyFont * 7, btnText.width + root.gap * 3)
                        height: root.buttonHeight
                        radius: 4
                        color: focused ? root.cardColor : "transparent"
                        border.color: focused ? root.accentColor : root.borderColor
                        border.width: focused ? 3 : 1

                        Text {
                            id: btnText
                            anchors.centerIn: parent
                            text: index === 0 ? Language.t("settings_custom_theme_save")
                            : Language.t("settings_custom_theme_cancel")
                            color: (btn.focused || index === 0) ? root.accentColor : root.fgColor
                            font.pixelSize: root.bodyFont
                            font.bold: index === 0 || btn.focused
                            font.family: SettingsManager.fontFamily
                        }
                    }
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: Language.t("settings_custom_theme_hint")
                color: root.mutedColor
                font.pixelSize: root.smallFont
                font.family: SettingsManager.fontFamily
            }
        }

        Flickable {
            id: flick
            anchors.top: headerArea.bottom
            anchors.bottom: footer.top
            anchors.bottomMargin: root.gap
            anchors.left: parent.left
            anchors.right: parent.right
            clip: true
            contentWidth: width
            contentHeight: contentColumn.height + 8
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            Column {
                id: contentColumn
                y: 4
                width: flick.width - root.gap * 1.2
                spacing: root.gap

                Rectangle {
                    width: parent.width
                    height: root.previewHeight
                    color: root.bgColor
                    border.color: root.borderColor
                    border.width: 2
                    radius: 6

                    Row {
                        anchors.centerIn: parent
                        spacing: root.gap * 1.5

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.round(root.previewHeight * 0.55)
                            height: width
                            color: root.cardColor
                            radius: 4
                            border.color: root.borderColor
                            border.width: 1
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text {
                                text: "Aa Bb Cc"
                                color: root.fgColor
                                font.pixelSize: root.previewTitleFont
                                font.bold: true
                                font.family: SettingsManager.fontFamily
                            }
                            Text {
                                text: Language.t("settings_custom_theme_preview_accent")
                                color: root.accentColor
                                font.pixelSize: root.previewBodyFont
                                font.family: SettingsManager.fontFamily
                            }
                            Text {
                                text: Language.t("settings_custom_theme_preview_muted")
                                color: root.mutedColor
                                font.pixelSize: root.previewSmallFont
                                font.family: SettingsManager.fontFamily
                            }
                        }
                    }
                }

                Rectangle {
                    id: nameBox
                    width: parent.width
                    height: root.fieldHeight
                    color: root.cardColor
                    border.color: root.nameFocused ? root.accentColor : root.borderColor
                    border.width: root.nameFocused ? 3 : 1
                    radius: 4

                    TextInput {
                        id: nameInput
                        anchors.fill: parent
                        anchors.leftMargin: root.gap
                        anchors.rightMargin: root.gap
                        verticalAlignment: TextInput.AlignVCenter
                        color: root.fgColor
                        selectionColor: root.accentColor
                        selectedTextColor: root.bgColor
                        font.pixelSize: root.bodyFont
                        font.family: SettingsManager.fontFamily
                        selectByMouse: false
                        activeFocusOnPress: false
                        clip: true
                        maximumLength: 32
                        onTextChanged: root.themeName = text

                        Text {
                            anchors.fill: parent
                            text: Language.t("settings_custom_theme_name_placeholder")
                            color: root.mutedColor
                            font.pixelSize: parent.font.pixelSize
                            font.family: parent.font.family
                            verticalAlignment: Text.AlignVCenter
                            visible: nameInput.text === "" && !nameInput.activeFocus
                        }

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Down) {
                                event.accepted = true;
                                root.moveVertical(1);
                            } else if (event.key === Qt.Key_Up) {
                                event.accepted = true;
                                root.moveVertical(-1);
                            } else if (event.key === Qt.Key_Return
                                || event.key === Qt.Key_Enter
                                || event.key === Qt.Key_Tab
                                || event.key === Qt.Key_Escape) {
                                event.accepted = true;
                            root.activate();
                                }
                        }
                    }
                }

                Column {
                    id: channelsColumn
                    width: parent.width
                    spacing: root.channelSpacing

                    Repeater {
                        id: channelRepeater
                        model: root.channelCount

                        delegate: Rectangle {
                            id: chRow
                            readonly property int ch: index
                            readonly property bool selected: ch === root.channelIndex && root.zone === "channels"

                            width: channelsColumn.width
                            height: root.rowHeight
                            color: selected ? root.cardColor : "transparent"
                            radius: 4
                            border.color: selected ? root.accentColor : "transparent"
                            border.width: 2

                            Text {
                                id: chLabel
                                anchors.left: parent.left
                                anchors.leftMargin: root.gap
                                anchors.verticalCenter: parent.verticalCenter
                                width: root.bodyFont * 7
                                elide: Text.ElideRight
                                text: root.channelNames[chRow.ch]
                                color: chRow.selected ? root.fgColor : root.mutedColor
                                font.pixelSize: root.bodyFont
                                font.bold: chRow.selected
                                font.family: SettingsManager.fontFamily
                            }

                            Rectangle {
                                id: chSwatch
                                anchors.left: chLabel.right
                                anchors.leftMargin: root.gap * 0.5
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.round(root.rowHeight * 0.6)
                                height: width
                                color: root.getChannelColor(chRow.ch)
                                border.color: root.fgColor
                                border.width: 1
                                radius: 3
                            }

                            Row {
                                id: sliders
                                anchors.left: chSwatch.right
                                anchors.leftMargin: root.gap
                                anchors.right: parent.right
                                anchors.rightMargin: root.gap
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Math.round(root.gap * 0.5)

                                Repeater {
                                    model: 3

                                    delegate: Item {
                                        id: cell
                                        readonly property int comp: index
                                        readonly property int val: root.getComponentValue(chRow.ch, comp)
                                        readonly property bool active: chRow.selected && root.componentIndex === comp
                                        readonly property color barColor: comp === 0 ? "#e04646"
                                        : comp === 1 ? "#3fb950"
                                        : "#4a7cf0"

                                        width: (sliders.width - sliders.spacing * 2) / 3
                                        height: Math.round(root.rowHeight * 0.6)

                                        Rectangle {
                                            anchors.fill: parent
                                            color: "#40808080"
                                            radius: 3

                                            Rectangle {
                                                width: parent.width * (cell.val / 255)
                                                height: parent.height
                                                color: cell.barColor
                                                radius: 3
                                                opacity: cell.active ? 1.0 : 0.6
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.componentLetters[cell.comp] + " " + cell.val
                                            color: "#ffffff"
                                            style: Text.Outline
                                            styleColor: "#000000"
                                            font.pixelSize: root.smallFont
                                            font.bold: cell.active
                                            font.family: SettingsManager.fontFamily
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.margins: -2
                                            color: "transparent"
                                            border.color: "#ffffff"
                                            border.width: 2
                                            radius: 4
                                            visible: cell.active
                                            Rectangle {
                                                anchors.fill: parent
                                                anchors.margins: 2
                                                color: "transparent"
                                                border.color: "#000000"
                                                border.width: 1
                                                radius: 3
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: scrollTrack
            visible: flick.contentHeight > flick.height + 1
            x: parent.width - width
            y: flick.y
            width: Math.max(3, Math.round(root.gap * 0.4))
            height: flick.height
            radius: width / 2
            color: root.borderColor
            opacity: 0.5

            Rectangle {
                width: parent.width
                radius: parent.radius
                color: root.accentColor
                height: Math.max(root.gap * 2, parent.height * flick.height / flick.contentHeight)
                y: (flick.contentHeight - flick.height) > 0
                ? (parent.height - height) * flick.contentY / (flick.contentHeight - flick.height)
                : 0
            }
        }
    }

    Keys.onUpPressed: root.moveVertical(-1)
    Keys.onDownPressed: root.moveVertical(1)
    Keys.onLeftPressed: function(event) {
        root.registerAdjust(-1, event.isAutoRepeat);
        root.moveHorizontal(-1);
    }
    Keys.onRightPressed: function(event) {
        root.registerAdjust(1, event.isAutoRepeat);
        root.moveHorizontal(1);
    }

    Keys.onPressed: function(event) {
        if (api.keys.isCancel(event)) {
            event.accepted = true;
            if (!event.isAutoRepeat) {
                SoundEngine.back();
                root.close();
            }
            return;
        }
        if (api.keys.isAccept(event)) {
            event.accepted = true;
            if (!event.isAutoRepeat) root.activate();
            return;
        }
        if (event.key === Qt.Key_Tab) {
            event.accepted = true;
            SoundEngine.scroll();
            root.setZone("name");
            root.ensureActiveVisible();
            return;
        }
        if (root.keyIs("isPrevPage", event) || root.keyIs("isDetails", event)) {
            event.accepted = true;
            if (!event.isAutoRepeat) {
                SoundEngine.scroll();
                root.cycleComponent(-1);
            }
            return;
        }
        if (root.keyIs("isNextPage", event) || root.keyIs("isFilters", event)) {
            event.accepted = true;
            if (!event.isAutoRepeat) {
                SoundEngine.scroll();
                root.cycleComponent(1);
            }
            return;
        }
    }
}
