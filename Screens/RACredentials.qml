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
import "../Components"

FocusScope {
    id: root
    anchors.fill: parent
    focus: true

    readonly property var colors: SettingsManager.getCurrentColors()
    readonly property bool hasCredentials: RetroAchievements.hasCredentials
    readonly property bool testing: RetroAchievements.testState === "testing"
    readonly property bool hasSessions: RetroAchievements.savedSessions.length > 0
    readonly property bool showLoggedInView: root.hasCredentials
    readonly property bool isCompact: height < 600
    readonly property bool vkEnabled: SettingsManager.showVirtualKeyboard
    readonly property bool confirmDelete: true

    readonly property var actions: {
        var a = root.showLoggedInView ? ["logout", "back"] : ["ok", "cancel"];
        if (root.hasSessions) a.push("sessions");
        return a;
    }
    readonly property var navOrder: root.showLoggedInView
    ? root.actions
    : ["user", "key"].concat(root.actions)

    property string focusTarget: root.showLoggedInView ? "logout" : "user"
    property string vkTargetField: "user"
    readonly property bool _vkActive: root.focusTarget === "vk"
    readonly property bool _hideCompactStuff: root._vkActive && root.isCompact
    property bool showSessionsMenu: false
    property int sessionMenuIndex: 0
    property string deleteArmedUser: ""
    property string menuMessage: ""
    property bool menuMessageIsError: false

    FontMetrics {
        id: labelMetrics
        font.pixelSize: PocketMetrics.titleSize
        font.family: SettingsManager.fontFamily
    }
    readonly property real rowHeight: Math.ceil(labelMetrics.height)
    readonly property real rowSpacing: Math.max(14, Math.round(PocketMetrics.titleSize * 1.1))

    readonly property string statusText: {
        var st = RetroAchievements.testState;
        if (st === "testing") {
            var pu = RetroAchievements.pendingUser;
            return pu !== ""
            ? Language.t("ra_connecting_prefix") + " " + pu + "…"
            : Language.t("ra_testing");
        }
        if (st === "error" || st === "offline") return RetroAchievements.testMessage;
        return "";
    }

    readonly property var statusColor: {
        var st = RetroAchievements.testState;
        if (st === "testing") return root.colors.muted;
        if (st === "offline") return "#f0b429";
        return "#ff6b6b";
    }

    function labelFor(kind) {
        switch (kind) {
            case "logout": return Language.t("ra_logout");
            case "back": return Language.t("ra_back");
            case "ok": return Language.t("ra_ok");
            case "cancel": return Language.t("ra_cancel");
            case "sessions": return "RA";
        }
        return "";
    }

    onShowLoggedInViewChanged: {
        if (!root.showLoggedInView) {
            userInput.text = "";
            keyInput.text = "";
        }
        root.focusTarget = root.showLoggedInView ? "logout" : "user";
    }

    onNavOrderChanged: root._ensureFocusValid()

    onShowSessionsMenuChanged: {
        if (root.showSessionsMenu) {
            userInput.focus = false;
            keyInput.focus = false;
            sessionsMenu.forceActiveFocus();
        } else {
            root.updateFocus();
        }
    }

    onSessionMenuIndexChanged: root._syncSessionsList()

    onFocusTargetChanged: root.updateFocus()

    function _ensureFocusValid() {
        if (root.focusTarget === "vk") return;
        if (root.navOrder.indexOf(root.focusTarget) >= 0) return;
        root.focusTarget = root.actions[root.actions.length - 1];
    }

    function updateFocus() {
        if (root.showSessionsMenu) return;

        sessionsMenu.focus = false;

        if (root.focusTarget === "user") {
            userInput.forceActiveFocus();
        } else if (root.focusTarget === "key") {
            keyInput.forceActiveFocus();
        } else if (root.focusTarget === "vk") {
            userInput.focus = false;
            keyInput.focus = false;
        } else {
            userInput.focus = false;
            keyInput.focus = false;
            root.forceActiveFocus();
        }
    }

    function _move(delta, wrap) {
        var order = root.navOrder;
        var i = order.indexOf(root.focusTarget);
        if (i < 0) { root.focusTarget = order[0]; return; }

        var n = i + delta;
        if (n < 0 || n >= order.length) {
            if (!wrap) return;
            n = (n + order.length) % order.length;
        }
        SoundEngine.scroll();
        root.focusTarget = order[n];
    }

    function _moveInRow(delta) {
        var i = root.actions.indexOf(root.focusTarget);
        if (i < 0) return;
        var n = i + delta;
        if (n < 0 || n >= root.actions.length) return;
        SoundEngine.scroll();
        root.focusTarget = root.actions[n];
    }

    function handleBack() {
        if (root.testing) {
            SoundEngine.back();
            RetroAchievements.cancelTest();
            return;
        }
        NavigationManager.goBack();
    }

    function openSessionsMenu() {
        if (!root.hasSessions || root.testing) return;

        var list = RetroAchievements.savedSessions;
        var idx = 0;
        for (var i = 0; i < list.length; i++) {
            if (RetroAchievements.isActive(list[i].user)) { idx = i; break; }
        }
        root.deleteArmedUser = "";
        root.menuMessage = "";
        root.sessionMenuIndex = idx;
        root.showSessionsMenu = true;
        Qt.callLater(root._syncSessionsList);
    }

    function closeSessionsMenu() {
        root.deleteArmedUser = "";
        root.showSessionsMenu = false;
    }

    function _syncSessionsList() {
        if (root.sessionMenuIndex >= 0 && root.sessionMenuIndex < sessionsList.count)
            sessionsList.positionViewAtIndex(root.sessionMenuIndex, ListView.Contain);
    }

    function _flashMenuMessage(text, isError) {
        root.menuMessage = text;
        root.menuMessageIsError = isError;
        menuMessageTimer.restart();
    }

    function activateSelectedSession() {
        var ses = RetroAchievements.savedSessions[root.sessionMenuIndex];
        if (!ses) return;
        SoundEngine.select();
        root.closeSessionsMenu();
        if (!RetroAchievements.isActive(ses.user))
            RetroAchievements.switchSession(ses.user);
    }

    function requestDeleteSelected() {
        var ses = RetroAchievements.savedSessions[root.sessionMenuIndex];
        if (!ses) return;

        if (RetroAchievements.isActive(ses.user)) {
            SoundEngine.back();
            root.deleteArmedUser = "";
            root._flashMenuMessage(Language.t("ra_session_cannot_delete"), true);
            return;
        }

        if (root.confirmDelete && root.deleteArmedUser !== ses.user) {
            SoundEngine.select();
            root.deleteArmedUser = ses.user;
            root._flashMenuMessage(Language.t("ra_session_delete_confirm"), false);
            return;
        }

        root.deleteArmedUser = "";
        SoundEngine.back();
        RetroAchievements.deleteSession(ses.user);

        var remaining = RetroAchievements.savedSessions.length;
        if (remaining === 0) {
            root.closeSessionsMenu();
            return;
        }
        root.sessionMenuIndex = Math.max(0, Math.min(root.sessionMenuIndex, remaining - 1));
        root._flashMenuMessage(Language.t("ra_session_deleted"), false);
        root._syncSessionsList();
    }

    Timer {
        id: menuMessageTimer
        interval: 2500
        repeat: false
        onTriggered: {
            root.menuMessage = "";
            root.deleteArmedUser = "";
        }
    }

    Component.onCompleted: {
        userInput.text = "";
        keyInput.text = "";
        if (RetroAchievements.testState !== "testing") {
            RetroAchievements.testState = "idle";
            RetroAchievements.testMessage = "";
        }
        root.updateFocus();
    }

    component ArrowHint: Item {
        id: hint
        property url iconSource
        property string glyph: ""
        property bool dim: false
        property color tint: "white"

        width: PocketMetrics.bodySize * 1.5
        height: width
        opacity: hint.dim ? 0.2 : 1.0

        Behavior on opacity {
            enabled: EffectsManager.animationsEnabled
            NumberAnimation { duration: EffectsManager.dur(200); easing.type: Easing.OutQuad }
        }

        Image {
            id: hintImg
            anchors.fill: parent
            source: hint.iconSource
            fillMode: Image.PreserveAspectFit
            visible: status === Image.Ready
            sourceSize.width: width > 0 ? Math.round(width) : 128
            sourceSize.height: height > 0 ? Math.round(height) : 128
            layer.enabled: EffectsManager.shaderEffectsEnabled
            layer.smooth: true
            layer.effect: ColorOverlay { color: hint.tint }
        }

        Text {
            anchors.centerIn: parent
            text: hint.glyph
            color: hint.tint
            visible: hintImg.status !== Image.Ready
            font.pixelSize: PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily
        }
    }

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

    Column {
        id: mainColumn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: PocketMetrics.headerHeight + (root.isCompact ? PocketMetrics.spacing * 0.5 : PocketMetrics.spacing)
        width: Math.min(parent.width - PocketMetrics.margin * 2, 640)
        spacing: root.isCompact ? PocketMetrics.spacing * 0.6 : PocketMetrics.spacing

        Text {
            visible: !root._hideCompactStuff
            text: Language.t("ra_credentials_title")
            color: colors.fg
            font.pixelSize: root.isCompact ? PocketMetrics.titleSize * 0.8 : PocketMetrics.titleSize * 1.1
            font.bold: true
            font.family: SettingsManager.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Rectangle {
            visible: !root._hideCompactStuff
            width: parent.width
            height: 1
            color: colors.border
        }

        Column {
            width: parent.width
            spacing: root.isCompact ? PocketMetrics.spacing * 0.5 : PocketMetrics.spacing
            visible: root.showLoggedInView

            Item {
                width: Math.min(root.isCompact ? PocketMetrics.bodySize * 2.5 : PocketMetrics.bodySize * 5,
                                root.height * (root.isCompact ? 0.16 : 0.2))
                height: width
                anchors.horizontalCenter: parent.horizontalCenter

                Image {
                    id: avatarImg
                    anchors.fill: parent
                    source: RetroAchievements.apiUserPic
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                    sourceSize.width: width > 0 ? Math.round(width) : 256
                    sourceSize.height: height > 0 ? Math.round(height) : 256
                }

                Rectangle {
                    id: maskRect
                    anchors.fill: parent
                    radius: width / 2
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: avatarImg
                    maskSource: maskRect
                }
            }

            Text {
                text: Language.t("ra_connected_as_prefix") + " " + RetroAchievements.apiUser
                color: colors.accent
                font.pixelSize: PocketMetrics.bodySize * 1.2
                font.bold: true
                font.family: SettingsManager.fontFamily
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                visible: root.statusText === ""
                text: Language.t("ra_credentials_hint")
                color: colors.muted
                font.pixelSize: PocketMetrics.bodySize
                font.family: SettingsManager.fontFamily
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Column {
            width: parent.width
            spacing: root.isCompact ? PocketMetrics.spacing * 0.6 : PocketMetrics.spacing
            visible: !root.showLoggedInView

            Column {
                width: parent.width
                spacing: 6
                visible: !root._vkActive || root.vkTargetField === "user"

                Text {
                    visible: !root._hideCompactStuff
                    text: Language.t("ra_username_label")
                    color: colors.muted
                    font.pixelSize: PocketMetrics.bodySize * 0.85
                    font.family: SettingsManager.fontFamily
                }

                Rectangle {
                    width: parent.width
                    height: PocketMetrics.bodySize * 2.4
                    color: colors.card
                    border.color: root.focusTarget === "user" ? colors.accent : colors.border
                    border.width: 2
                    radius: EffectsManager.r(6)

                    Behavior on border.color {
                        enabled: EffectsManager.animationsEnabled
                        ColorAnimation { duration: EffectsManager.dur(140) }
                    }

                    TextInput {
                        id: userInput
                        anchors.fill: parent
                        anchors.leftMargin: PocketMetrics.spacing * 0.5
                        anchors.rightMargin: PocketMetrics.spacing * 0.5
                        clip: true
                        rightPadding: 4
                        color: colors.fg
                        font.pixelSize: PocketMetrics.bodySize * 1.05
                        font.family: SettingsManager.fontFamily || "sans-serif"
                        verticalAlignment: TextInput.AlignVCenter
                        selectByMouse: true
                        readOnly: root.testing

                        activeFocusOnPress: false
                        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

                        Text {
                            text: Language.t("ra_username_placeholder")
                            color: colors.muted
                            font.pixelSize: parent.font.pixelSize
                            font.family: parent.font.family
                            visible: userInput.text === "" && !userInput.activeFocus
                            elide: Text.ElideRight
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                        }

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Escape) {
                                event.accepted = true;
                                root.handleBack();
                                return;
                            }
                            if (event.key === Qt.Key_Tab) {
                                event.accepted = true;
                                root._move(1, true);
                                return;
                            }
                            if (event.modifiers & Qt.ControlModifier) {
                                if (event.key === Qt.Key_A) { selectAll(); event.accepted = true; }
                                else if (event.key === Qt.Key_C) { copy(); event.accepted = true; }
                                else if (event.key === Qt.Key_V) { paste(); event.accepted = true; }
                            }
                        }

                        Keys.onDownPressed: function(event) {
                            event.accepted = true;
                            root._move(1, true);
                        }
                        Keys.onUpPressed: function(event) {
                            event.accepted = true;
                            root._move(-1, true);
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 6
                visible: !root._vkActive || root.vkTargetField === "key"

                Text {
                    visible: !root._hideCompactStuff
                    text: Language.t("ra_apikey_label")
                    color: colors.muted
                    font.pixelSize: PocketMetrics.bodySize * 0.85
                    font.family: SettingsManager.fontFamily
                }

                Rectangle {
                    width: parent.width
                    height: PocketMetrics.bodySize * 2.4
                    color: colors.card
                    border.color: root.focusTarget === "key" ? colors.accent : colors.border
                    border.width: 2
                    radius: EffectsManager.r(6)

                    Behavior on border.color {
                        enabled: EffectsManager.animationsEnabled
                        ColorAnimation { duration: EffectsManager.dur(140) }
                    }

                    TextInput {
                        id: keyInput
                        anchors.fill: parent
                        anchors.leftMargin: PocketMetrics.spacing * 0.5
                        anchors.rightMargin: PocketMetrics.spacing * 0.5
                        clip: true
                        rightPadding: 4
                        color: colors.fg
                        font.pixelSize: PocketMetrics.bodySize * 1.05
                        font.family: SettingsManager.fontFamily || "sans-serif"
                        verticalAlignment: TextInput.AlignVCenter
                        selectByMouse: true
                        readOnly: root.testing

                        activeFocusOnPress: false
                        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

                        Text {
                            text: Language.t("ra_apikey_placeholder")
                            color: colors.muted
                            font.pixelSize: parent.font.pixelSize
                            font.family: parent.font.family
                            visible: keyInput.text === "" && !keyInput.activeFocus
                            elide: Text.ElideRight
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                        }

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Escape) {
                                event.accepted = true;
                                root.handleBack();
                                return;
                            }
                            if (event.key === Qt.Key_Tab) {
                                event.accepted = true;
                                root._move(1, true);
                                return;
                            }
                            if (event.modifiers & Qt.ControlModifier) {
                                if (event.key === Qt.Key_A) { selectAll(); event.accepted = true; }
                                else if (event.key === Qt.Key_C) { copy(); event.accepted = true; }
                                else if (event.key === Qt.Key_V) { paste(); event.accepted = true; }
                            }
                        }

                        Keys.onDownPressed: function(event) {
                            event.accepted = true;
                            root._move(1, true);
                        }
                        Keys.onUpPressed: function(event) {
                            event.accepted = true;
                            root._move(-1, true);
                        }
                    }
                }
            }
        }
    }

    Column {
        id: bottomBar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PocketMetrics.margin
        width: Math.min(parent.width - PocketMetrics.margin * 2, 640)
        spacing: root.isCompact ? PocketMetrics.spacing * 0.3 : PocketMetrics.spacing * 0.5
        visible: !root._vkActive

        Item {
            width: parent.width
            height: root.isCompact ? PocketMetrics.bodySize * 1.4 : PocketMetrics.bodySize * 2.4

            Text {
                anchors.fill: parent
                text: root.statusText
                color: root.statusColor
                font.pixelSize: PocketMetrics.bodySize
                font.family: SettingsManager.fontFamily
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Behavior on color {
                    enabled: EffectsManager.animationsEnabled
                    ColorAnimation { duration: EffectsManager.dur(140) }
                }
            }
        }

        Item {
            id: rowFit
            width: parent.width
            height: root.rowHeight

            Row {
                id: buttonRow
                anchors.centerIn: parent
                spacing: root.rowSpacing
                scale: buttonRow.implicitWidth > rowFit.width && buttonRow.implicitWidth > 0
                ? rowFit.width / buttonRow.implicitWidth : 1.0

                readonly property int focusIndex: root.actions.indexOf(root.focusTarget)

                ArrowHint {
                    anchors.verticalCenter: parent.verticalCenter
                    iconSource: Qt.resolvedUrl("../assets/icons/arrow-left.svg")
                    glyph: "←"
                    tint: colors.muted
                    dim: buttonRow.focusIndex <= 0
                }

                Repeater {
                    model: root.actions

                    delegate: Item {
                        id: btn

                        readonly property string kind: modelData
                        readonly property bool focused: root.focusTarget === btn.kind
                        readonly property bool blocked: root.testing && btn.kind !== "back" && btn.kind !== "cancel"

                        TextMetrics {
                            id: boldMetrics
                            font.pixelSize: PocketMetrics.titleSize
                            font.family: SettingsManager.fontFamily
                            font.bold: true
                            text: root.labelFor(btn.kind)
                        }

                        width: Math.ceil(boldMetrics.advanceWidth) + 2
                        height: root.rowHeight
                        opacity: btn.blocked ? 0.5 : 1.0

                        Behavior on opacity {
                            enabled: EffectsManager.animationsEnabled
                            NumberAnimation { duration: EffectsManager.dur(140) }
                        }

                        Item {
                            id: content
                            anchors.fill: parent
                            scale: btn.focused ? 1.08 : 1.0

                            Behavior on scale {
                                enabled: EffectsManager.animationsEnabled
                                NumberAnimation { duration: EffectsManager.dur(140); easing.type: Easing.OutQuad }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: root.labelFor(btn.kind)
                                color: btn.focused ? colors.accent : colors.muted
                                font.pixelSize: PocketMetrics.titleSize
                                font.bold: btn.focused
                                font.family: SettingsManager.fontFamily

                                Behavior on color {
                                    enabled: EffectsManager.animationsEnabled
                                    ColorAnimation { duration: EffectsManager.dur(140) }
                                }
                            }
                        }
                    }
                }

                ArrowHint {
                    anchors.verticalCenter: parent.verticalCenter
                    iconSource: Qt.resolvedUrl("../assets/icons/arrow-right.svg")
                    glyph: "→"
                    tint: colors.muted
                    dim: buttonRow.focusIndex < 0 || buttonRow.focusIndex >= root.actions.length - 1
                }
            }
        }
    }

    Item {
        id: sessionsMenu
        anchors.fill: parent
        z: 100
        opacity: root.showSessionsMenu ? 1.0 : 0.0
        visible: root.showSessionsMenu || opacity > 0

        Behavior on opacity {
            enabled: EffectsManager.animationsEnabled
            NumberAnimation { duration: EffectsManager.dur(140); easing.type: Easing.OutQuad }
        }

        Rectangle {
            id: panel

            readonly property real pad: PocketMetrics.spacing

            readonly property real topOvershoot: Math.min(Math.round(PocketMetrics.titleSize * 0.45),
                                                          Math.max(0, mainColumn.y - PocketMetrics.headerHeight * 0.5))

            x: mainColumn.x
            y: mainColumn.y - panel.topOvershoot
            width: mainColumn.width
            height: Math.max(0, (bottomBar.y + bottomBar.height) - y)

            color: colors.bg
            border.color: colors.accent
            border.width: 2
            radius: EffectsManager.r(10)

            Text {
                id: panelTitle
                anchors.top: parent.top
                anchors.topMargin: panel.pad + panel.topOvershoot
                anchors.horizontalCenter: parent.horizontalCenter
                text: Language.t("ra_sessions_title")
                color: colors.accent
                font.pixelSize: PocketMetrics.titleSize
                font.bold: true
                font.family: SettingsManager.fontFamily
            }

            Rectangle {
                id: panelRule
                anchors.top: panelTitle.bottom
                anchors.topMargin: panel.pad * 0.5
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: panel.pad
                anchors.rightMargin: panel.pad
                height: 1
                color: colors.border
            }

            HintBar {
                id: panelHint
                anchors.bottom: parent.bottom
                anchors.bottomMargin: panel.pad
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: panel.pad
                anchors.rightMargin: panel.pad
                text: Language.t("ra_sessions_hint")
                textSize: PocketMetrics.bodySize * 0.8
                color: colors.muted
                contentOpacity: 1.0
            }

            Item {
                id: panelMessage
                anchors.bottom: panelHint.top
                anchors.bottomMargin: panel.pad * 0.25
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: panel.pad
                anchors.rightMargin: panel.pad
                height: PocketMetrics.bodySize * 1.4

                InlineGlyphText {
                    anchors.centerIn: parent
                    maxWidth: parent.width
                    text: root.menuMessage
                    textSize: PocketMetrics.bodySize * 0.85
                    color: root.menuMessageIsError ? "#ff6b6b" : colors.accent
                }
            }

            ListView {
                id: sessionsList
                anchors.top: panelRule.bottom
                anchors.topMargin: panel.pad * 0.5
                anchors.bottom: panelMessage.top
                anchors.bottomMargin: panel.pad * 0.25
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: panel.pad
                anchors.rightMargin: panel.pad
                model: RetroAchievements.savedSessions
                spacing: PocketMetrics.spacing * 0.4
                clip: true
                interactive: contentHeight > height
                keyNavigationEnabled: false

                delegate: Rectangle {
                    id: sessionRow

                    readonly property bool selected: index === root.sessionMenuIndex
                    readonly property bool isActiveSession: RetroAchievements.isActive(modelData.user)

                    width: ListView.view.width
                    height: PocketMetrics.bodySize * 3.2
                    color: sessionRow.selected ? colors.card : "transparent"
                    border.color: sessionRow.selected ? colors.accent : "transparent"
                    border.width: 2
                    radius: EffectsManager.r(6)

                    Behavior on border.color {
                        enabled: EffectsManager.animationsEnabled
                        ColorAnimation { duration: EffectsManager.dur(140) }
                    }

                    Rectangle {
                        id: avatarBox
                        anchors.left: parent.left
                        anchors.leftMargin: PocketMetrics.spacing * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.height - PocketMetrics.spacing
                        height: width
                        radius: EffectsManager.r(4)
                        color: colors.border
                        clip: true

                        Image {
                            id: avatarThumb
                            anchors.fill: parent
                            source: modelData.userPic || ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 96
                            sourceSize.height: 96
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: avatarThumb.status !== Image.Ready
                            text: String(modelData.user || "?").charAt(0).toUpperCase()
                            color: colors.muted
                            font.pixelSize: PocketMetrics.bodySize * 1.2
                            font.bold: true
                            font.family: SettingsManager.fontFamily
                        }
                    }

                    Text {
                        anchors.left: avatarBox.right
                        anchors.leftMargin: PocketMetrics.spacing * 0.75
                        anchors.right: activeTag.visible ? activeTag.left : parent.right
                        anchors.rightMargin: PocketMetrics.spacing * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.user
                        elide: Text.ElideRight
                        color: sessionRow.selected ? colors.accent : colors.fg
                        font.pixelSize: PocketMetrics.bodySize * 1.1
                        font.bold: true
                        font.family: SettingsManager.fontFamily

                        Behavior on color {
                            enabled: EffectsManager.animationsEnabled
                            ColorAnimation { duration: EffectsManager.dur(140) }
                        }
                    }

                    Text {
                        id: activeTag
                        anchors.right: parent.right
                        anchors.rightMargin: PocketMetrics.spacing * 0.75
                        anchors.verticalCenter: parent.verticalCenter
                        visible: sessionRow.isActiveSession
                        text: Language.t("ra_session_active")
                        color: colors.accent
                        font.pixelSize: PocketMetrics.bodySize * 0.8
                        font.family: SettingsManager.fontFamily
                    }
                }
            }
        }

        Keys.onPressed: function(event) {
            event.accepted = true;

            if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                var count = RetroAchievements.savedSessions.length;
                if (count > 1) {
                    var d = event.key === Qt.Key_Down ? 1 : -1;
                    root.deleteArmedUser = "";
                    root.sessionMenuIndex = (root.sessionMenuIndex + d + count) % count;
                    SoundEngine.scroll();
                }
                return;
            }

            if (event.isAutoRepeat) return;

            if (api.keys.isCancel(event)) {
                SoundEngine.back();
                root.closeSessionsMenu();
            } else if (api.keys.isAccept(event)) {
                root.activateSelectedSession();
            } else if (api.keys.isDetails(event)) {
                root.requestDeleteSelected();
            }
        }
    }

    VirtualKeyboard {
        id: vk
        anchors.fill: parent
        visible: root.vkEnabled && root._vkActive
        active: root.vkEnabled && root._vkActive
        target: root.vkTargetField === "user" ? userInput : keyInput
        showSearchButton: true
        submitLabel: "OK"
        submitEnabled: true

        onSubmitted: {
            if (root.testing) return;
            if (userInput.text.trim() === "" || keyInput.text.trim() === "") {
                root.focusTarget = root.vkTargetField;
                SoundEngine.back();
                return;
            }
            SoundEngine.select();
            root.focusTarget = "ok";
            RetroAchievements.testAndSave(userInput.text, keyInput.text);
        }

        onCanceled: {
            root.focusTarget = root.vkTargetField;
        }

        onExitRequested: {
            root.focusTarget = root.vkTargetField;
            SoundEngine.scroll();
        }
    }

    Keys.onDownPressed: {
        if (root._vkActive || root.showSessionsMenu) return;
        root._move(1, true);
    }

    Keys.onUpPressed: {
        if (root._vkActive || root.showSessionsMenu) return;
        root._move(-1, true);
    }

    Keys.onLeftPressed: {
        if (root._vkActive || root.showSessionsMenu) return;
        root._moveInRow(-1);
    }

    Keys.onRightPressed: {
        if (root._vkActive || root.showSessionsMenu) return;
        root._moveInRow(1);
    }

    Keys.onTabPressed: {
        if (root._vkActive || root.showSessionsMenu) return;
        root._move(1, true);
    }

    Keys.onPressed: function(event) {
        if (root.showSessionsMenu) return;

        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            var t = root.focusTarget;

            if (t === "sessions") {
                event.accepted = true;
                if (root.testing) { SoundEngine.back(); return; }
                SoundEngine.select();
                root.openSessionsMenu();
                return;
            }

            if ((t === "user" || t === "key") && !root.testing && root.vkEnabled) {
                event.accepted = true;
                root.vkTargetField = t;
                root.focusTarget = "vk";
                SoundEngine.select();
                return;
            }

            if (t === "logout") {
                event.accepted = true;
                if (root.testing) { SoundEngine.back(); return; }
                SoundEngine.select();
                RetroAchievements.logout();
                root.focusTarget = "user";
                return;
            }

            if (t === "back" || t === "cancel") {
                event.accepted = true;
                root.handleBack();
                return;
            }

            if (t === "ok" && !root.testing) {
                event.accepted = true;
                SoundEngine.select();
                RetroAchievements.testAndSave(userInput.text, keyInput.text);
                return;
            }
            return;
        }

        if (api.keys.isCancel(event)) {
            if (root._vkActive) return;
            event.accepted = true;
            root.handleBack();
        }
    }
}
