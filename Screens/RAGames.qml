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

    readonly property bool isSquare: ResponsiveManager.aspectProfile === Enums.profileSquare
    readonly property bool isCompact: height < 600
    readonly property bool isTiny: height < 520
    readonly property int tinyVisibleRows: 4
    readonly property real controlsScale: root.isSquare ? 0.85 : (root.isCompact ? 0.8 : 1.0)
    readonly property real controlsBottomMargin: root.isTiny ? PocketMetrics.margin * 0.6
    : (root.isCompact ? PocketMetrics.margin * 0.3 : PocketMetrics.margin)
    readonly property real contentTopMargin: root.isCompact
    ? Math.max(0, PocketMetrics.headerHeight - PocketMetrics.spacing * 0.8)
    : PocketMetrics.headerHeight + PocketMetrics.spacing
    readonly property real controlsGap: root.isSquare ? PocketMetrics.spacing * 2.0
    : (root.isTiny ? PocketMetrics.spacing * 0.8
    : (root.isCompact ? PocketMetrics.spacing * 0.4 : PocketMetrics.spacing))
    readonly property var rawEntries: RetroAchievements.libraryEntries
    property string sortMode: "unlock_newest"
    property int actionIndex: 0
    readonly property int actionCount: 3

    readonly property var sortModes: [
        "unlock_newest", "unlock_oldest", "ach_most",
        "ach_least", "title_az", "title_za"
    ]

    readonly property var sortedEntries: {
        if (!rawEntries || rawEntries.length === 0) return [];

        var arr = rawEntries.slice();

        arr.sort(function(a, b) {
            if (root.sortMode === "unlock_newest") {
                return (b.lastAwarded || "").localeCompare(a.lastAwarded || "");
            } else if (root.sortMode === "unlock_oldest") {
                return (a.lastAwarded || "").localeCompare(b.lastAwarded || "");
            } else if (root.sortMode === "ach_most") {
                return b.numAchieved - a.numAchieved;
            } else if (root.sortMode === "ach_least") {
                return a.numAchieved - b.numAchieved;
            } else if (root.sortMode === "title_az") {
                var ta = a.pegasusGame ? a.pegasusGame.title : a.raTitle;
                var tb = b.pegasusGame ? b.pegasusGame.title : b.raTitle;
                return ta.localeCompare(tb);
            } else if (root.sortMode === "title_za") {
                var tza = a.pegasusGame ? a.pegasusGame.title : a.raTitle;
                var tzb = b.pegasusGame ? b.pegasusGame.title : b.raTitle;
                return tzb.localeCompare(tza);
            }
            return 0;
        });
        return arr;
    }

    readonly property int count: root.sortedEntries.length

    readonly property real rowHeight: root.isSquare ? PocketMetrics.bodySize * 3.2
    : (root.isTiny && listArea.height > 0 ? listArea.height / root.tinyVisibleRows
    : (root.isCompact ? PocketMetrics.bodySize * 2.2
    : PocketMetrics.bodySize * 2.6))

    readonly property string currentSortLabel: {
        if (sortMode === "unlock_newest") return Language.t("ra_sort_unlock_newest");
        if (sortMode === "unlock_oldest") return Language.t("ra_sort_unlock_oldest");
        if (sortMode === "ach_most") return Language.t("ra_sort_ach_most");
        if (sortMode === "ach_least") return Language.t("ra_sort_ach_least");
        if (sortMode === "title_az") return Language.t("ra_sort_title_az");
        if (sortMode === "title_za") return Language.t("ra_sort_title_za");
        return "";
    }

    function cycleSort(delta) {
        var idx = root.sortModes.indexOf(root.sortMode);
        idx = (idx + delta + root.sortModes.length) % root.sortModes.length;
        root.sortMode = root.sortModes[idx];
    }

    function openCurrentGame() {
        if (root.count === 0) return;
        var entry = root.sortedEntries[listView.currentIndex];
        if (entry && entry.pegasusGame) {
            AppState.currentSection = Enums.sectionRALibrary;
            AppState.selectGame(entry.pegasusGame, listView.currentIndex);
            NavigationManager.enterGameDetails();
        }
    }

    function refreshList() {
        if (RetroAchievements.libraryState !== "loading") {
            RetroAchievements.loadLibrary();
        }
    }

    function activateAction() {
        if (root.actionIndex === 0) {
            root.openCurrentGame();
        } else if (root.actionIndex === 1) {
            SoundEngine.select();
            root.refreshList();
        } else if (root.actionIndex === 2) {
            SoundEngine.select();
            root.cycleSort(1);
        }
    }

    function moveAction(delta) {
        root.actionIndex = Math.max(0, Math.min(root.actionCount - 1, root.actionIndex + delta));
    }

    function moveList(delta, wrap) {
        if (root.count === 0) return;
        var idx = listView.currentIndex + delta;
        if (wrap) idx = (idx % root.count + root.count) % root.count;
        else idx = Math.max(0, Math.min(root.count - 1, idx));
        listView.currentIndex = idx;
    }

    onSortModeChanged: {
        listView.currentIndex = 0;
        listView.positionViewAtBeginning();
    }

    onCountChanged: {
        if (root.count > 0 && listView.currentIndex >= root.count)
            listView.currentIndex = root.count - 1;
    }

    Component.onCompleted: {
        root.forceActiveFocus();
        if (RetroAchievements.libraryState === "idle" || RetroAchievements.libraryState === "error")
            RetroAchievements.loadLibrary();
    }

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

    Column {
        anchors.centerIn: parent
        visible: RetroAchievements.libraryState === "loading"
        spacing: PocketMetrics.spacing
        width: Math.min(root.width - PocketMetrics.margin * 2, root.isTiny ? 200 : 480)

        Text {
            text: Language.t("ra_library_loading")
            color: colors.muted
            font.pixelSize: PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily
            width: parent.width
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            id: progressTrack
            width: parent.width
            height: PocketMetrics.bodySize * 0.5
            radius: height / 2
            color: colors.card
            border.color: colors.border
            clip: true

            Rectangle {
                x: 0
                y: 0
                width: Math.max(progressTrack.height, progressTrack.width * RetroAchievements.libraryProgress)
                height: progressTrack.height
                radius: progressTrack.radius
                color: colors.accent
            }
        }

        Text {
            text: Math.round(RetroAchievements.libraryProgress * 100) + "%"
            color: colors.muted
            font.pixelSize: PocketMetrics.bodySize * 0.85
            font.family: SettingsManager.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Column {
        anchors.fill: parent
        anchors.leftMargin: PocketMetrics.margin
        anchors.rightMargin: PocketMetrics.margin
        anchors.topMargin: root.contentTopMargin
        anchors.bottomMargin: root.controlsBottomMargin + controlsRow.height + root.controlsGap
        spacing: root.isCompact ? PocketMetrics.spacing * 0.4 : PocketMetrics.spacing * 0.6
        visible: RetroAchievements.libraryState !== "loading"

        Row {
            width: parent.width
            spacing: PocketMetrics.spacing

            Text {
                text: Language.t("ra_library_title")
                color: colors.fg
                font.pixelSize: root.isCompact ? PocketMetrics.titleSize * 0.7 : PocketMetrics.titleSize * 0.95
                font.bold: true
                font.family: SettingsManager.fontFamily
                anchors.baseline: sortLabel.baseline
            }

            Text {
                id: sortLabel
                text: root.currentSortLabel
                color: colors.accent
                font.pixelSize: root.isCompact ? PocketMetrics.bodySize * 0.65 : PocketMetrics.bodySize * 0.75
                font.family: SettingsManager.fontFamily
                opacity: 0.8
            }
        }

        Text {
            text: root.count > 0
            ? (root.count + " " + Language.t("ra_library_count_suffix"))
            : ""
            visible: RetroAchievements.libraryState === "loaded"
            color: colors.muted
            font.pixelSize: root.isCompact ? PocketMetrics.bodySize * 0.8 : PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily
        }

        Rectangle { width: parent.width; height: 1; color: colors.border }

        InlineGlyphText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: RetroAchievements.libraryState === "error"
            text: Language.t("ra_library_error")
            textSize: PocketMetrics.bodySize
            color: "#ff6b6b"
            maxWidth: parent.width
        }

        Text {
            width: parent.width
            visible: RetroAchievements.libraryState === "loaded" && root.count === 0
            text: Language.t("ra_library_empty")
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: colors.muted
            font.pixelSize: PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily
        }

        Item {
            id: listArea
            width: parent.width
            height: parent.height - y
            visible: RetroAchievements.libraryState === "loaded" && root.count > 0

            readonly property int visibleRows: Math.max(1, Math.floor(height / root.rowHeight + 0.01))
            readonly property real scrollFraction: root.count > visibleRows
            ? listView.currentIndex / (root.count - 1)
            : 0

            ListView {
                id: listView
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width - 12
                clip: true
                model: root.sortedEntries
                highlightMoveDuration: 150

                delegate: Rectangle {
                    width: listView.width
                    height: root.rowHeight
                    radius: 4
                    color: index === listView.currentIndex ? colors.card : "transparent"

                    Behavior on color { ColorAnimation { duration: 140 } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: root.isCompact ? PocketMetrics.spacing * 0.4 : PocketMetrics.spacing * 0.6
                        anchors.rightMargin: root.isCompact ? PocketMetrics.spacing * 0.4 : PocketMetrics.spacing * 0.6
                        spacing: root.isCompact ? PocketMetrics.spacing * 0.4 : PocketMetrics.spacing * 0.6

                        Image {
                            id: rowIcon
                            anchors.verticalCenter: parent.verticalCenter
                            width: root.rowHeight * 0.75
                            height: root.rowHeight * 0.75
                            source: modelData.iconUrl
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            sourceSize.width: width > 0 ? Math.round(width) : 128
                            sourceSize.height: height > 0 ? Math.round(height) : 128

                            Rectangle {
                                anchors.fill: parent
                                visible: parent.status !== Image.Ready
                                color: colors.card
                                border.color: colors.border
                                z: -1
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - root.rowHeight * 0.75 - 100 - PocketMetrics.spacing
                            spacing: root.isTiny ? 2 : (root.isCompact ? 0 : 2)

                            MarqueeText {
                                width: parent.width
                                text: modelData.pegasusGame
                                ? GameUtils.cleanGameTitle(modelData.pegasusGame.title)
                                : modelData.raTitle
                                color: index === listView.currentIndex ? colors.accent : colors.fg
                                pixelSize: root.isCompact ? PocketMetrics.bodySize * 0.85 : PocketMetrics.bodySize
                                bold: index === listView.currentIndex
                                active: index === listView.currentIndex
                                padVertical: 0
                            }

                            Text {
                                width: parent.width
                                text: modelData.raConsole
                                color: colors.muted
                                font.pixelSize: root.isCompact ? PocketMetrics.bodySize * 0.65 : PocketMetrics.bodySize * 0.75
                                font.family: SettingsManager.fontFamily
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 100
                            horizontalAlignment: Text.AlignRight
                            text: modelData.numAchieved + "/" + modelData.maxPossible
                            color: (modelData.numAchieved >= modelData.maxPossible && modelData.maxPossible > 0)
                            ? colors.accent : colors.muted
                            font.pixelSize: root.isCompact ? PocketMetrics.bodySize * 0.8 : PocketMetrics.bodySize * 0.95
                            font.bold: (modelData.numAchieved >= modelData.maxPossible && modelData.maxPossible > 0)
                            font.family: SettingsManager.fontFamily
                        }
                    }
                }
            }

            Rectangle {
                id: scrollTrack
                anchors.top: listView.top
                anchors.right: parent.right
                width: 6
                height: listView.height
                radius: width / 2
                color: colors.card
                opacity: 0.4
                visible: root.count > listArea.visibleRows

                Rectangle {
                    id: scrollThumb
                    width: parent.width
                    radius: width / 2
                    color: colors.accent
                    opacity: 0.75
                    height: Math.max(20, scrollTrack.height * Math.min(1, listArea.visibleRows / Math.max(root.count, 1)))
                    y: (scrollTrack.height - height) * listArea.scrollFraction

                    Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                }
            }
        }
    }

    Row {
        id: controlsRow
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.controlsBottomMargin
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.isCompact ? PocketMetrics.spacing * 0.8 : PocketMetrics.spacing * 1.2
        visible: RetroAchievements.libraryState !== "loading"

        Item {
            width: PocketMetrics.bodySize * root.controlsScale
            height: width
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.actionIndex === 0 ? 0.2 : 1.0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

            Image {
                id: leftIcon
                anchors.fill: parent
                source: Qt.resolvedUrl("../assets/icons/arrow-left.svg")
                fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
                sourceSize.width: width > 0 ? Math.round(width) : 128
                sourceSize.height: height > 0 ? Math.round(height) : 128
                layer.enabled: EffectsManager.shaderEffectsEnabled
                layer.smooth: true
                layer.effect: ColorOverlay { color: colors.border }
            }

            Text {
                anchors.centerIn: parent
                text: "←"
                color: colors.border
                visible: leftIcon.status !== Image.Ready
                font.pixelSize: PocketMetrics.bodySize * root.controlsScale
                font.family: SettingsManager.fontFamily
            }
        }

        Repeater {
            model: [
                Language.t("ra_library_action_view"),
                Language.t("ra_library_action_refresh"),
                Language.t("ra_library_action_sort")
            ]

            delegate: Text {
                readonly property bool selected: root.actionIndex === index
                text: modelData
                color: selected ? colors.accent : colors.muted
                font.pixelSize: PocketMetrics.bodySize * root.controlsScale
                font.bold: selected
                font.family: SettingsManager.fontFamily
                scale: selected ? 1.05 : 1.0
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
            }
        }

        Item {
            width: PocketMetrics.bodySize * root.controlsScale
            height: width
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.actionIndex === 2 ? 0.2 : 1.0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

            Image {
                id: rightIcon
                anchors.fill: parent
                source: Qt.resolvedUrl("../assets/icons/arrow-right.svg")
                fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
                sourceSize.width: width > 0 ? Math.round(width) : 128
                sourceSize.height: height > 0 ? Math.round(height) : 128
                layer.enabled: EffectsManager.shaderEffectsEnabled
                layer.smooth: true
                layer.effect: ColorOverlay { color: colors.border }
            }

            Text {
                anchors.centerIn: parent
                text: "→"
                color: colors.border
                visible: rightIcon.status !== Image.Ready
                font.pixelSize: PocketMetrics.bodySize * root.controlsScale
                font.family: SettingsManager.fontFamily
            }
        }
    }

    Keys.onUpPressed: {
        SoundEngine.scroll();
        root.moveList(-1, true)
    }
    Keys.onDownPressed: {
        SoundEngine.scroll();
        root.moveList(1, true)
    }
    Keys.onLeftPressed: {
        SoundEngine.scroll();
        root.moveAction(-1)
    }
    Keys.onRightPressed: {
        SoundEngine.scroll();
        root.moveAction(1)
    }
    Keys.onPressed: {
        if (api.keys.isAccept(event)) {
            event.accepted = true;
            if (!event.isAutoRepeat) root.activateAction();
            return;
        }
        if (api.keys.isCancel(event)) {
            event.accepted = true;
            if (!event.isAutoRepeat) NavigationManager.goBack();
            return;
        }
        if (api.keys.isDetails(event)) {
            event.accepted = true;
            if (!event.isAutoRepeat) { SoundEngine.select(); root.refreshList(); }
            return;
        }
        if (api.keys.isPageUp(event)) {
            event.accepted = true; SoundEngine.scroll();
            root.moveList(-listArea.visibleRows, false);
            return;
        }
        if (api.keys.isPageDown(event)) {
            event.accepted = true; SoundEngine.scroll();
            root.moveList(listArea.visibleRows, false);
            return;
        }
    }
}
