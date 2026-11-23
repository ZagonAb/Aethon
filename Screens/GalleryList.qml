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

FocusScope {
    id: root
    anchors.fill: parent
    focus: true

    readonly property var colors: SettingsManager.getCurrentColors()
    property ListModel assetTypesModel: ListModel {}
    property int currentIndex: 0
    property bool _initialized: false
    property bool _pendingScroll: false

    function getIconFor(rawKey) {
        if (!rawKey) return "";
        var k = rawKey.toLowerCase();
        if (k === "cabinetright") return Qt.resolvedUrl("../assets/icons/pga/cabineright.svg");
        if (k === "cabinetleft") return Qt.resolvedUrl("../assets/icons/pga/cabinetleft.svg");

        return Qt.resolvedUrl("../assets/icons/pga/" + k + ".svg");
    }

    Component.onCompleted: {
        var counts = {};
        var all = api.allGames.toVarArray();

        var knownKeys = [
            "boxFront", "boxBack", "boxSpine", "boxFull", "cartridge", "logo",
            "marquee", "bezel", "panel", "cabinetLeft", "cabinetRight",
            "tile", "banner", "steam", "poster", "background",
            "screenshot", "titlescreen", "video"
        ];

        for (var i = 0; i < all.length; i++) {
            var assets = all[i].assets;
            if (!assets) continue;

            for (var j = 0; j < knownKeys.length; j++) {
                var key = knownKeys[j];
                if (assets[key] && assets[key] !== "") {
                    counts[key] = (counts[key] || 0) + 1;
                }
            }
        }

        var result = [];
        for (var k in counts) {
            if (counts[k] > 0) {
                result.push({ name: k.toUpperCase(), rawKey: k });
            }
        }

        result.sort(function(a, b) { return a.name.localeCompare(b.name); });

        root.assetTypesModel.clear();
        for (var r = 0; r < result.length; r++) {
            root.assetTypesModel.append(result[r]);
        }

        var saved = AppState.galleryListIndex;
        var idx = 0;
        if (result.length > 0 && saved >= 0 && saved < result.length)
            idx = saved;

        root.currentIndex = idx;
        listView.currentIndex = idx;

        if (result.length > 0) {
            root._pendingScroll = true;
            listView.schedulePendingScroll();
        }

        root._initialized = true;

        if (AppState.galleryListIndex !== idx)
            AppState.galleryListIndex = idx;
    }

    onCurrentIndexChanged: {
        if (listView.currentIndex !== currentIndex)
            listView.currentIndex = currentIndex;

        if (_initialized)
            AppState.galleryListIndex = currentIndex;
    }

    readonly property var currentAssetType: {
        if (root.currentIndex >= 0 && root.currentIndex < root.assetTypesModel.count) {
            return root.assetTypesModel.get(root.currentIndex);
        }
        return null;
    }

    readonly property real scrollBarWidth: 6
    readonly property real scrollBarMargin: 6

    component ScrollIndicator: Item {
        id: scrollRoot
        property real ratio: 1
        property real position: 0
        property color trackColor: "gray"
        property color thumbColor: "white"
        property real barWidth: 6

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: barWidth

        visible: ratio < 0.999

        Rectangle {
            id: scrollTrack
            anchors.fill: parent
            radius: width / 2
            color: scrollRoot.trackColor
            opacity: 0.4

            Rectangle {
                id: scrollThumb
                width: parent.width
                radius: width / 2
                color: scrollRoot.thumbColor
                opacity: 0.75
                height: Math.max(24, scrollTrack.height * Math.min(1, scrollRoot.ratio))
                y: (scrollTrack.height - height) * Math.max(0, Math.min(1, scrollRoot.position))
            }
        }
    }

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

    Item {
        id: pageHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: PocketMetrics.headerHeight

        Text {
            anchors.left: parent.left
            anchors.leftMargin: PocketMetrics.margin
            anchors.verticalCenter: parent.verticalCenter
            text: Language.t("gallery_title")
            color: colors.fg
            font.pixelSize: PocketMetrics.titleSize * 0.864
            font.bold: true
            font.family: SettingsManager.fontFamily
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.assetTypesModel.count === 0
        text: Language.t("gallery_empty")
        color: colors.muted
        font.pixelSize: PocketMetrics.bodySize
        font.family: SettingsManager.fontFamily
    }

    Item {
        anchors.top: pageHeader.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: PocketMetrics.margin * 2
        anchors.rightMargin: PocketMetrics.margin * 2
        anchors.bottomMargin: PocketMetrics.margin * 2
        visible: root.assetTypesModel.count > 0

        ListView {
            id: listView
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width - root.scrollBarWidth - root.scrollBarMargin
            clip: true
            model: root.assetTypesModel
            currentIndex: root.currentIndex
            highlightMoveDuration: root._pendingScroll ? 0 : 150
            opacity: root._pendingScroll ? 0 : 1
            boundsBehavior: Flickable.StopAtBounds
            spacing: PocketMetrics.spacing * 0.5

            Timer {
                id: restoreTimer
                interval: 30
                repeat: false
                onTriggered: listView.applyPendingScroll()
            }

            function schedulePendingScroll() {
                if (root._pendingScroll)
                    restoreTimer.restart();
            }

            function applyPendingScroll() {
                if (!root._pendingScroll) return;
                if (width <= 0 || height <= 0 || count <= 0) {
                    restoreTimer.restart();
                    return;
                }

                currentIndex = root.currentIndex;
                positionViewAtIndex(root.currentIndex, ListView.Center);
                root._pendingScroll = false;
            }

            onWidthChanged: schedulePendingScroll()
            onHeightChanged: schedulePendingScroll()
            onCountChanged: schedulePendingScroll()
            onContentHeightChanged: schedulePendingScroll()

            onCurrentIndexChanged: {
                if (root._initialized && listView.currentIndex !== root.currentIndex)
                    root.currentIndex = listView.currentIndex;
            }

            readonly property real scrollRatio: contentHeight > 0 ? Math.min(1, height / contentHeight) : 1
            readonly property real scrollPosition: contentHeight > height
            ? Math.max(0, Math.min(1, (contentY - originY) / (contentHeight - height)))
            : 0

            delegate: Item {
                width: listView.width
                height: Math.max(PocketMetrics.titleSize * 1.6, PocketMetrics.bodySize * 2)

                Rectangle {
                    anchors.fill: parent
                    radius: EffectsManager.r(6)
                    color: colors.accent
                    opacity: index === listView.currentIndex ? 0.16 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    spacing: PocketMetrics.spacing * 0.8

                    Item {
                        id: iconContainer
                        width: height
                        height: parent.height * 0.9
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            id: assetIcon
                            anchors.fill: parent
                            source: root.getIconFor(model.rawKey)
                            fillMode: Image.PreserveAspectFit
                            visible: !EffectsManager.shaderEffectsEnabled
                            mipmap: true
                            sourceSize.width: width > 0 ? Math.round(width) : 128
                            sourceSize.height: height > 0 ? Math.round(height) : 128
                        }

                        ColorOverlay {
                            anchors.fill: parent
                            source: assetIcon
                            color: index === listView.currentIndex ? colors.accent : colors.muted
                            visible: EffectsManager.shaderEffectsEnabled && assetIcon.status === Image.Ready
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: model.name
                        color: index === listView.currentIndex ? colors.accent : colors.fg
                        font.pixelSize: PocketMetrics.titleSize
                        font.bold: index === listView.currentIndex
                        font.family: SettingsManager.fontFamily
                    }
                }
            }
        }

        ScrollIndicator {
            ratio: listView.scrollRatio
            position: listView.scrollPosition
            trackColor: colors.card
            thumbColor: colors.accent
            barWidth: root.scrollBarWidth
            opacity: root._pendingScroll ? 0 : 1
        }
    }

    Keys.onUpPressed: {
        SoundEngine.scroll();
        if (root.assetTypesModel.count > 0)
            root.currentIndex = Math.max(0, root.currentIndex - 1);
    }

    Keys.onDownPressed: {
        SoundEngine.scroll();
        if (root.assetTypesModel.count > 0)
            root.currentIndex = Math.min(root.assetTypesModel.count - 1, root.currentIndex + 1);
    }

    Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (root.currentAssetType) {
                NavigationManager.enterGalleryGrid(root.currentAssetType.rawKey, root.currentAssetType.name);
            }
        }
    }
}
