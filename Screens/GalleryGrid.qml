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

    readonly property var galleryCache: GalleryCacheEngine
    readonly property string assetKey: AppState.galleryAssetKey
    readonly property string assetTitle: AppState.galleryAssetTitle
    readonly property var colors: SettingsManager.getCurrentColors()
    property var galleryItems: []
    property int currentIndex: 0
    property bool _initialized: false
    property bool _pendingScroll: false
    property bool viewerActive: false
    readonly property var currentItem: root.galleryItems.length > 0 ? root.galleryItems[root.currentIndex] : null
    readonly property int targetColumns: 3
    readonly property real usableWidth: root.width - PocketMetrics.margin * 2
    readonly property real scrollBarWidth: 6
    readonly property real scrollBarMargin: 6
    readonly property real cellWidth: Math.floor((usableWidth - scrollBarWidth - scrollBarMargin) / targetColumns)
    readonly property real cellHeight: root.cellWidth

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

    property string builtKey: ""

    property bool busy: true
    property bool showProgress: false
    property real visualProgress: 0.0

    readonly property bool preValidate: false
    readonly property int poolSize: 4

    property var _cands: []
    property var _queue: []
    property var _ok: []
    property int _cursor: 0
    property int _resolved: 0
    property int _rawCount: 0
    property string _scanKey: ""
    property real _tScan: 0
    property var _dropSet: ({})

    function _makeItem(game, url, thumb, isVideo) {
        var item = { url: url, thumb: thumb, isVideo: isVideo, game: game };
        var cached = null;
        Object.defineProperty(item, "title", {
            enumerable: true,
            get: function () {
                if (cached === null) cached = GameUtils.cleanGameTitle(game.title);
                return cached;
            }
        });
        return item;
    }

    function _resetPool() {
        for (var s = 0; s < poolRepeater.count; s++) {
            var slot = poolRepeater.itemAt(s);
            if (slot) { slot.job = -1; slot.source = ""; }
        }
    }

    function _cancelScan() {
        buildTimer.stop();
        showTimer.stop();
        root._queue = [];
        root._cands = [];
        root._ok = [];
        root._cursor = 0;
        root._resolved = 0;
        root.showProgress = false;
        root.visualProgress = 0.0;
        root._resetPool();
    }

    function rebuild() {
        if (root.assetKey === "") {
            root._cancelScan();
            root.galleryItems = [];
            root.builtKey = "";
            root.busy = false;
            return;
        }
        if (root.builtKey === root.assetKey) return;

        root._cancelScan();
        root._initialized = false;
        root.busy = true;
        root.galleryItems = [];
        buildTimer.restart();
    }

    function _build() {
        var key = root.assetKey;
        if (key === "") return;
        if (key === "music") return;

        var t0 = Date.now();
        var isVideo = (key === "video");
        var all = api.allGames.toVarArray();
        var cands = [];

        for (var i = 0; i < all.length; i++) {
            var game = all[i];
            if (!game || !game.assets) continue;

            var assets = game.assets;
            var simple = assets[key];
            if (!simple) continue;

            var url = "" + simple;
            if (url === "") continue;

            var thumb = url;
            if (isVideo) {
                thumb = "" + (assets.screenshot || assets.titlescreen || assets.background || "");
                if (thumb === "") continue;
            }
            cands.push(root._makeItem(game, url, thumb, isVideo));
        }

        root._rawCount = cands.length;
        console.log("[GalleryGrid] " + key + " collect: " + cands.length + " candidatos en " + (Date.now() - t0) + " ms");

        var needScan = false;
        try {
            needScan = root.preValidate && galleryCache.verifiedCount(key) !== cands.length;
        } catch (e) {
            console.log("[GalleryGrid] GalleryCacheEngine no disponible (" + e + ").");
            root._present(key, cands, t0, "sin-engine");
            return;
        }
        if (!needScan) {
            var fast = [];
            for (var f = 0; f < cands.length; f++) {
                if (!galleryCache.isBad(cands[f].thumb)) fast.push(cands[f]);
            }
            root._present(key, fast, t0, "cache");
            return;
        }
        root._startScan(key, cands);
    }

    function _startScan(key, cands) {
        root._scanKey = key;
        root._cands = cands;
        root._ok = new Array(cands.length);

        var queue = [];
        for (var i = 0; i < cands.length; i++) {
            if (galleryCache.isRemote(cands[i].thumb)) root._ok[i] = true;
            else queue.push(i);
        }
        root._queue = queue;
        root._cursor = 0;
        root._resolved = 0;
        root.visualProgress = 0.0;
        root._tScan = Date.now();

        if (queue.length === 0) {
            root._finishScan();
            return;
        }
        showTimer.restart();
        root._pump();
    }

    function _pump() {
        if (root._queue.length === 0) return;
        for (var s = 0; s < root.poolSize; s++) {
            if (root._cursor >= root._queue.length) break;
            var slot = poolRepeater.itemAt(s);
            if (!slot || slot.job >= 0) continue;

            var idx = root._queue[root._cursor++];
            slot.job = idx;
            slot.checkUrl = root._cands[idx].thumb;
            slot.source = slot.checkUrl;
        }
    }

    function _slotDone(slot, ok) {
        var idx = slot.job;
        if (idx < 0) return;
        slot.job = -1;
        slot.source = "";

        if (!ok) galleryCache.markBad(slot.checkUrl);
        root._ok[idx] = ok;
        root._resolved++;
        root.visualProgress = root._resolved / root._queue.length;

        if (root._resolved >= root._queue.length) root._finishScan();
        else Qt.callLater(root._pump);
    }

    function _finishScan() {
        var key = root._scanKey;
        var out = [];
        var removed = 0;

        for (var i = 0; i < root._cands.length; i++) {
            var c = root._cands[i];
            if (root._ok[i] === true) {
                galleryCache.markGood(c.thumb);
                out.push(c);
            } else {
                removed++;
            }
        }

        galleryCache.setVerified(key, root._rawCount);
        galleryCache.save();
        console.log("[GalleryGrid] " + key + " scan: " + root._queue.length + " comprobados, "
        + removed + " falsos positivos, " + (Date.now() - root._tScan) + " ms");

        root._present(key, out, root._tScan, "scan");
    }

    function _present(key, items, t0, how) {
        showTimer.stop();
        root.showProgress = false;
        root._cands = [];
        root._queue = [];
        root._ok = [];

        var saved = AppState.galleryGridIndex;
        var idx = 0;
        if (items.length > 0 && saved >= 0 && saved < items.length)
            idx = saved;

        root.galleryItems = items;
        root.builtKey = key;
        root.busy = false;

        console.log("[GalleryGrid] " + key + " -> " + items.length + " items (" + how + ")");

        root.currentIndex = idx;
        gridView.currentIndex = idx;

        if (items.length > 0) {
            root._pendingScroll = true;
            gridView.schedulePendingScroll();
        }
        root._initialized = true;

        if (AppState.galleryGridIndex !== idx)
            AppState.galleryGridIndex = idx;
    }

    function _dropItem(url) {
        galleryCache.markBad(url);
        root._dropSet[url] = true;
        dropTimer.restart();
    }

    function _applyDrops() {
        var cur = root.currentItem ? root.currentItem.thumb : "";
        var keep = [];
        var newIdx = -1;

        for (var i = 0; i < root.galleryItems.length; i++) {
            var it = root.galleryItems[i];
            if (root._dropSet[it.thumb]) continue;
            if (it.thumb === cur) newIdx = keep.length;
            keep.push(it);
        }
        var dropped = root.galleryItems.length - keep.length;
        console.log("[GalleryGrid] " + root.builtKey + ": " + dropped
        + " falso(s) positivo(s) descartado(s) y recordado(s)");
        root._dropSet = ({});

        if (newIdx < 0) newIdx = Math.min(root.currentIndex, Math.max(0, keep.length - 1));

        root.galleryItems = keep;
        root.currentIndex = newIdx;
        gridView.currentIndex = newIdx;
        galleryCache.scheduleSave();

        if (keep.length > 0) {
            root._pendingScroll = true;
            gridView.schedulePendingScroll();
        }
    }

    Timer { id: buildTimer; interval: 40; repeat: false; onTriggered: root._build() }
    Timer { id: showTimer; interval: 300; repeat: false
        onTriggered: { if (root.busy && root._queue.length > 0) root.showProgress = true; } }

        Timer {
            id: dropTimer
            interval: 250
            repeat: false
            onTriggered: {
                if (root.viewerActive) return;
                root._applyDrops();
            }
        }

        onViewerActiveChanged: {
            if (!root.viewerActive && Object.keys(root._dropSet).length > 0)
                dropTimer.restart();
        }

        Behavior on visualProgress {
            enabled: EffectsManager.animationsEnabled
            NumberAnimation { duration: EffectsManager.dur(150); easing.type: Easing.OutQuad }
        }

        onAssetKeyChanged: rebuild()
        Component.onCompleted: rebuild()

        onCurrentIndexChanged: {
            if (gridView.currentIndex !== currentIndex)
                gridView.currentIndex = currentIndex;

            if (_initialized)
                AppState.galleryGridIndex = currentIndex;
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
            visible: root.galleryItems.length === 0 && !root.busy
            text: Language.t("gallery_empty")
            color: colors.muted
            font.pixelSize: PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily
        }

        Item {
            id: validatorPool
            visible: false
            width: 0
            height: 0

            Repeater {
                id: poolRepeater
                model: root.poolSize

                delegate: Image {
                    id: slot
                    property int job: -1
                    property string checkUrl: ""

                    asynchronous: true
                    cache: false
                    sourceSize.width: 8
                    sourceSize.height: 8

                    onStatusChanged: {
                        if (slot.job < 0) return;
                        if (status === Image.Ready) root._slotDone(slot, true);
                        else if (status === Image.Error) root._slotDone(slot, false);
                    }
                }
            }
        }

        Column {
            visible: root.busy && root.showProgress
            anchors.centerIn: parent
            spacing: PocketMetrics.spacing * 1.5
            width: Math.min(parent.width * 0.7, 500)

            Text {
                text: root.showProgress ? Language.t("gallery_validating") : ""
                color: colors.muted
                font.pixelSize: PocketMetrics.bodySize
                font.family: SettingsManager.fontFamily
                anchors.horizontalCenter: parent.horizontalCenter

                SequentialAnimation on opacity {
                    running: root.busy && root.showProgress && EffectsManager.loopingAnimationsEnabled
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.3; to: 1.0; duration: EffectsManager.dur(700); easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 1.0; to: 0.3; duration: EffectsManager.dur(700); easing.type: Easing.InOutQuad }
                }
            }

            Rectangle {
                width: parent.width
                height: PocketMetrics.bodySize * 0.6
                color: colors.card
                border.color: colors.border
                radius: height / 2
                clip: true

                Rectangle {
                    width: parent.width * root.visualProgress
                    height: parent.height
                    color: colors.accent
                    radius: parent.radius
                }
            }

            Text {
                text: Math.round(root.visualProgress * 100) + "%   (" + root._resolved + " / " + root._queue.length + ")"
                color: colors.muted
                font.pixelSize: PocketMetrics.bodySize * 0.8
                font.family: SettingsManager.fontFamily
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        Item {
            anchors.top: pageHeader.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: PocketMetrics.margin
            anchors.rightMargin: PocketMetrics.margin
            anchors.bottomMargin: PocketMetrics.margin
            visible: root.galleryItems.length > 0

            Text {
                id: headerText
                anchors.top: parent.top
                anchors.left: parent.left
                text: root.assetTitle
                color: colors.muted
                font.pixelSize: PocketMetrics.bodySize
                font.family: SettingsManager.fontFamily
                z: 2
            }

            Item {
                id: gridContainer
                anchors.top: headerText.bottom
                anchors.topMargin: PocketMetrics.spacing
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                clip: true

                GridView {
                    id: gridView
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width - root.scrollBarWidth - root.scrollBarMargin
                    clip: true
                    model: root.galleryItems.length
                    cellWidth: root.cellWidth
                    cellHeight: root.cellHeight
                    boundsBehavior: Flickable.StopAtBounds
                    flow: GridView.LeftToRight

                    highlightRangeMode: GridView.StrictlyEnforceRange
                    preferredHighlightBegin: 0
                    preferredHighlightEnd: root.cellHeight
                    highlightMoveDuration: root._pendingScroll ? 0 : EffectsManager.dur(150)
                    opacity: root._pendingScroll ? 0 : 1

                    onCurrentIndexChanged: {
                        if (root._initialized && gridView.currentIndex !== root.currentIndex)
                            root.currentIndex = gridView.currentIndex;
                    }

                    Timer {
                        id: restoreTimer
                        interval: 30
                        repeat: false
                        onTriggered: gridView.applyPendingScroll()
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
                        positionViewAtIndex(root.currentIndex, GridView.Beginning);
                        root._pendingScroll = false;
                    }

                    onWidthChanged: schedulePendingScroll()
                    onHeightChanged: schedulePendingScroll()
                    onCountChanged: schedulePendingScroll()
                    onContentHeightChanged: schedulePendingScroll()

                    readonly property int totalRows: Math.ceil(count / root.targetColumns)
                    readonly property real scrollRatio: totalRows > 0
                    ? Math.min(1, height / (totalRows * root.cellHeight)) : 1
                    readonly property real scrollPosition: totalRows > 1
                    ? Math.max(0, Math.min(1, (contentY - originY) / ((totalRows - 1) * root.cellHeight)))
                    : 0

                    delegate: Item {
                        id: cell
                        width: gridView.cellWidth
                        height: gridView.cellHeight

                        readonly property var it: (index >= 0 && index < root.galleryItems.length)
                        ? root.galleryItems[index] : null

                        Rectangle {
                            id: cellBg
                            anchors.fill: parent
                            anchors.margins: 2
                            color: colors.card
                            radius: EffectsManager.r(4)
                            clip: true

                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                border.color: index === gridView.currentIndex ? colors.accent : "transparent"
                                border.width: 3
                                radius: parent.radius
                            }

                            Image {
                                id: cellThumb
                                anchors.fill: parent
                                anchors.margins: 4
                                source: cell.it ? cell.it.thumb : ""
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                                sourceSize.width: cellThumb.width > 0 ? Math.round(cellThumb.width) : 256
                                sourceSize.height: cellThumb.height > 0 ? Math.round(cellThumb.height) : 256
                                opacity: (cell.it && cell.it.isVideo) ? 0.6 : 1.0

                                onStatusChanged: {
                                    if (status === Image.Error && cell.it)
                                        root._dropItem(cell.it.thumb);
                                }
                            }

                            Item {
                                anchors.centerIn: parent
                                visible: !!(cell.it && cell.it.isVideo)
                                width: root.cellWidth * 0.3
                                height: root.cellWidth * 0.3

                                Image {
                                    id: playIcon
                                    anchors.fill: parent
                                    source: Qt.resolvedUrl("../assets/icons/play.svg")
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    sourceSize.width: width > 0 ? Math.round(width) : 128
                                    sourceSize.height: height > 0 ? Math.round(height) : 128
                                    visible: status === Image.Ready

                                    layer.enabled: EffectsManager.shaderEffectsEnabled
                                    layer.smooth: true
                                    layer.effect: ColorOverlay {
                                        color: colors.accent
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: playIcon.status !== Image.Ready
                                    text: "▶"
                                    color: colors.accent
                                    font.pixelSize: root.cellWidth * 0.3
                                    font.bold: true
                                }
                            }
                        }

                        MarqueeText {
                            anchors.left: cellBg.left
                            anchors.right: cellBg.right
                            anchors.bottom: cellBg.bottom
                            anchors.margins: 8
                            visible: index === gridView.currentIndex
                            active: index === gridView.currentIndex
                            text: cell.it ? cell.it.title : ""
                            color: "#ffffff"
                            pixelSize: Math.max(8, root.cellWidth * 0.08)
                            waitDuration: 3000
                            padVertical: 0
                            outlineEnabled: true
                            outlineColor: "#000000"
                        }
                    }
                }

                ScrollIndicator {
                    ratio: gridView.scrollRatio
                    position: gridView.scrollPosition
                    trackColor: colors.card
                    thumbColor: colors.accent
                    barWidth: root.scrollBarWidth
                    opacity: root._pendingScroll ? 0 : 1
                }
            }
        }

        GalleryViewer {
            id: viewer
            anchors.fill: parent
            items: root.galleryItems

            onNavigated: root.currentIndex = index

            onClosed: {
                root.viewerActive = false;
                root.forceActiveFocus();
            }
        }

        Keys.onLeftPressed: { if (root.viewerActive) return; SoundEngine.scroll(); if (root.galleryItems.length > 0) root.currentIndex = (root.currentIndex - 1 + root.galleryItems.length) % root.galleryItems.length; }
        Keys.onRightPressed: { if (root.viewerActive) return; SoundEngine.scroll(); if (root.galleryItems.length > 0) root.currentIndex = (root.currentIndex + 1) % root.galleryItems.length; }
        Keys.onUpPressed: { if (root.viewerActive) return; SoundEngine.scroll(); if (root.galleryItems.length > 0) root.currentIndex = Math.max(0, root.currentIndex - root.targetColumns); }
        Keys.onDownPressed: { if (root.viewerActive) return; SoundEngine.scroll(); if (root.galleryItems.length > 0) root.currentIndex = Math.min(root.galleryItems.length - 1, root.currentIndex + root.targetColumns); }

        Keys.onPressed: {
            if (root.viewerActive) return;

            if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                event.accepted = true;
                if (root.currentItem) {
                    SoundEngine.select();
                    root.viewerActive = true;
                    viewer.open(root.currentItem, root.currentIndex);
                }
            } else if (api.keys.isCancel(event)) {
                event.accepted = true;
                NavigationManager.goBack();
            }
        }
}
