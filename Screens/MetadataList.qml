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
    property var items: []
    property int currentIndex: 0
    property string checkId: ""
    property string checkLabel: ""
    property bool _loading: !MetadataEngine.built
    readonly property real rowHeight: PocketMetrics.bodySize * 2.6
    property int _favRev: 0

    Connections {
        target: NavigationManager
        function onFavoriteToggled() { root._favRev++; }
    }

    function labelForCheck(id) {
        if (id === "") return "";
        if (id.indexOf("field_") === 0) return Language.t("metadata_field_" + id.substring(6));
        if (id.indexOf("art_") === 0) return Language.t("metadata_art_" + id.substring(4));
        if (id === "coll_emptyCollection") return Language.t("metadata_issue_coll_emptyCollection");
        if (id === "coll_duplicateTitles") return Language.t("metadata_issue_coll_duplicateTitles");
        return Language.t("metadata_issue_" + id);
    }

    function loadItems() {
        var arr = [];
        var id = root.checkId;

        if (id.indexOf("field_") === 0) {
            var games = MetadataEngine.gamesMissing(id.substring(6));
            for (var i = 0; i < games.length; i++) {
                arr.push({ game: games[i], isGame: true, label: GameUtils.cleanGameTitle(games[i].title), sublabel: games[i].developer || "" });
            }
        } else if (id.indexOf("art_") === 0) {
            var games2 = MetadataEngine.gamesAtCascadeLevel(id.substring(4));
            for (var j = 0; j < games2.length; j++) {
                arr.push({ game: games2[j], isGame: true, label: GameUtils.cleanGameTitle(games2[j].title), sublabel: games2[j].developer || "" });
            }
        } else if (id === "coll_emptyCollection") {
            var cols = MetadataEngine.emptyCollectionsList();
            for (var k = 0; k < cols.length; k++) {
                arr.push({ game: null, isGame: false, label: cols[k].name || "", sublabel: "0 " + Language.t("label_games") });
            }
        } else if (id === "coll_duplicateTitles") {
            var games3 = MetadataEngine.gamesWithDuplicateTitles();
            for (var l = 0; l < games3.length; l++) {
                arr.push({ game: games3[l], isGame: true, label: GameUtils.cleanGameTitle(games3[l].title), sublabel: games3[l].developer || "" });
            }
        } else {
            var games4 = MetadataEngine.gamesWithIssue(id);
            for (var m = 0; m < games4.length; m++) {
                arr.push({ game: games4[m], isGame: true, label: GameUtils.cleanGameTitle(games4[m].title), sublabel: games4[m].developer || "" });
            }
        }

        root.items = arr;

        var savedIdx = 0;
        if (AppState.currentGame) {
            for (var n = 0; n < arr.length; n++) {
                if (arr[n].game === AppState.currentGame) { savedIdx = n; break; }
            }
        }
        root.currentIndex = savedIdx;
        if (arr.length > 0 && arr[savedIdx].isGame) {
            AppState.selectGame(arr[savedIdx].game, savedIdx);
        }
    }

    Component.onCompleted: {
        root.checkId = AppState.metadataActiveCheckId;
        root.checkLabel = root.labelForCheck(root.checkId);
        if (!root._loading) {
            root.loadItems();
        }
        root.forceActiveFocus();
    }

    Connections {
        target: MetadataEngine
        function onBuiltChanged() {
            if (MetadataEngine.built && root._loading) {
                root._loading = false;
                root.loadItems();
            }
        }
    }

    onCurrentIndexChanged: {
        if (root.currentIndex >= 0 && root.currentIndex < root.items.length) {
            var it = root.items[root.currentIndex];
            if (it.isGame) AppState.selectGame(it.game, root.currentIndex);
        }
    }

    function moveCursor(delta, wrap) {
        if (root.items.length === 0) return;
        var n = root.items.length;
        var i = root.currentIndex + delta;
        if (wrap) i = (i % n + n) % n;
        else i = Math.max(0, Math.min(n - 1, i));
        root.currentIndex = i;
        listView.positionViewAtIndex(i, ListView.Contain);
    }

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

    Item {
        id: pageHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: PocketMetrics.headerHeight

        Item {
            anchors.left: parent.left
            anchors.leftMargin: PocketMetrics.margin
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(root.width * 0.45, 800)
            height: mqHeader.implicitHeight

            MarqueeText {
                id: mqHeader
                width: parent.width
                text: root.checkLabel + (root._loading ? " (...)" : "  (" + root.items.length + ")")
                color: colors.fg
                pixelSize: PocketMetrics.titleSize * 0.7
                bold: true
                active: true
            }
        }
    }

    Item {
        anchors.top: pageHeader.bottom
        anchors.bottom: footer.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: PocketMetrics.margin
        anchors.rightMargin: PocketMetrics.margin
        anchors.topMargin: PocketMetrics.spacing * 0.5
        anchors.bottomMargin: PocketMetrics.spacing * 0.5

        Text {
            anchors.centerIn: parent
            visible: root._loading
            text: Language.t("metadata_scanning")
            color: colors.muted
            font.pixelSize: PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 0.3; to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 1.0; to: 0.3; duration: 700; easing.type: Easing.InOutQuad }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !root._loading && root.items.length === 0
            text: Language.t("metadata_no_issues")
            color: colors.muted
            font.pixelSize: PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily
        }

        ListView {
            id: listView
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width - 12
            clip: true
            visible: !root._loading
            model: root.items
            currentIndex: root.currentIndex
            highlightMoveDuration: 120
            boundsBehavior: Flickable.StopAtBounds

            onCurrentIndexChanged: {
                if (listView.currentIndex !== root.currentIndex)
                    root.currentIndex = listView.currentIndex;
            }

            delegate: Rectangle {
                id: rowRect
                width: listView.width
                height: root.rowHeight
                color: index === listView.currentIndex ? colors.card : "transparent"
                radius: EffectsManager.r(4)

                readonly property bool isFav: {
                    var rev = root._favRev;
                    return !!(modelData.game && modelData.game.favorite === true);
                }
                readonly property real favSize: PocketMetrics.bodySize * 1.1
                readonly property real favShift: isFav ? favSize + PocketMetrics.spacing * 0.5 : 0

                Behavior on color { ColorAnimation { duration: 140 } }

                Item {
                    id: favBadge
                    visible: rowRect.isFav
                    anchors.left: parent.left
                    anchors.leftMargin: PocketMetrics.spacing * 0.6
                    anchors.verticalCenter: parent.verticalCenter
                    width: rowRect.favSize
                    height: width

                    Image {
                        id: favIcon
                        anchors.fill: parent
                        source: Qt.resolvedUrl("../assets/icons/favorite.svg")
                        fillMode: Image.PreserveAspectFit
                        visible: !EffectsManager.shaderEffectsEnabled
                        sourceSize.width: width > 0 ? Math.round(width) : 128
                        sourceSize.height: height > 0 ? Math.round(height) : 128
                    }

                    ColorOverlay {
                        anchors.fill: favIcon
                        source: favIcon
                        color: colors.accent
                        visible: EffectsManager.shaderEffectsEnabled && favIcon.status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "\u2605"
                        color: colors.accent
                        visible: favIcon.status !== Image.Ready
                        font.pixelSize: rowRect.favSize
                        font.family: SettingsManager.fontFamily
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: PocketMetrics.spacing * 0.6 + rowRect.favShift
                    anchors.rightMargin: PocketMetrics.spacing * 0.6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    MarqueeText {
                        width: parent.width
                        text: modelData.label || ""
                        color: index === listView.currentIndex ? colors.accent : colors.fg
                        pixelSize: PocketMetrics.bodySize
                        bold: index === listView.currentIndex
                        active: index === listView.currentIndex
                    }

                    MarqueeText {
                        width: parent.width
                        visible: (modelData.sublabel || "") !== ""
                        text: modelData.sublabel || ""
                        color: colors.muted
                        pixelSize: PocketMetrics.bodySize * 0.8
                        active: index === listView.currentIndex
                    }
                }
            }
        }

        Rectangle {
            anchors.top: listView.top
            anchors.bottom: listView.bottom
            anchors.right: parent.right
            width: 6
            color: colors.border
            opacity: 0.4
            radius: width / 2
            visible: !root._loading && listView.contentHeight > listView.height

            Rectangle {
                width: parent.width
                height: Math.max(20, parent.height * (listView.height / listView.contentHeight))
                color: colors.accent
                radius: parent.radius
                y: (parent.height - height) * (listView.contentY / Math.max(1, listView.contentHeight - listView.height))
            }
        }
    }

    HintBar {
        id: footer
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PocketMetrics.margin * 0.5
        anchors.left: parent.left
        anchors.right: parent.right
        text: Language.t("metadata_hint_list")
        color: colors.muted
    }

    Keys.onUpPressed: {
        if (!root._loading) {
            SoundEngine.scroll();
            root.moveCursor(-1, true);
        }
    }
    Keys.onDownPressed: {
        if (!root._loading) {
            SoundEngine.scroll();
            root.moveCursor(1, true);
        }
    }

    Keys.onPressed: {
        if (root._loading) return;

        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            var it = root.items[root.currentIndex];
            if (it && it.isGame)
                NavigationManager.enterGameInspector(it.game, root.currentIndex);
            return;
        }
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            NavigationManager.goBack();
            return;
        }
        if (api.keys.isPrevPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            SoundEngine.scroll();
            root.moveCursor(-10, false);
        } else if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            SoundEngine.scroll();
            root.moveCursor(10, false);
        }
    }
}
