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

    readonly property var menuItems: {
        var _lang = Language.currentLanguage;
        return [
            { label: Language.t("home_library"), screen: Enums.screenLibrary },
            { label: Language.t("home_memories"), screen: Enums.screenMemories },
            { label: Language.t("home_tools"), screen: Enums.screenTools },
            { label: Language.t("home_settings"), screen: Enums.screenSettings }
        ];
    }

    property int currentIndex: 0
    property bool _initialized: false
    readonly property var colors: SettingsManager.getCurrentColors()
    property var lastGame: null
    property int focusedCard: -1
    readonly property real _t: PocketMetrics.titleSize
    readonly property real _gap: PocketMetrics.spacing
    readonly property real _topReserve: SettingsManager.topbarEnabled ? PocketMetrics.headerHeight : 0
    readonly property real _bottomMargin: Math.round(PocketMetrics.margin * 0.6)
    readonly property real _fullH: Math.round(root._t * 1.7)
    readonly property real _compactH: Math.round(root._t * 0.8)
    readonly property real _menuH: menuColumn.height

    function _validTime(d) {
        if (!d) return 0;
        var ms = d.getTime ? d.getTime() : 0;
        if (isNaN(ms) || ms <= 0) return 0;
        if (ms > Date.now() + 86400000) return 0;
        return ms;
    }

    function findLastPlayed() {
        var all = api.allGames.toVarArray();
        var best = null, bestMs = 0;
        for (var i = 0; i < all.length; i++) {
            var g = all[i];
            if (!(g.playCount > 0)) continue;
            var ms = root._validTime(g.lastPlayed);
            if (ms > bestMs) { bestMs = ms; best = g; }
        }
        return best;
    }

    function systemName(game) {
        try {
            if (game && game.collections && game.collections.count > 0)
                return game.collections.get(0).name || "";
        } catch (e) { }
        return "";
    }

    function playTimeText(seconds) {
        if (!seconds || seconds <= 0) return "";
        if (seconds < 60) return "<1m";
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        return h > 0 ? (h + "h " + m + "m") : (m + "m");
    }

    function agoText(game) {
        var _lang = Language.currentLanguage;
        var ms = root._validTime(game ? game.lastPlayed : null);
        if (ms === 0) return "";
        var now = new Date();
        var a = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        var lp = new Date(ms);
        var b = new Date(lp.getFullYear(), lp.getMonth(), lp.getDate());
        var days = Math.round((a.getTime() - b.getTime()) / 86400000);
        if (days <= 0) return Language.t("home_today");
        if (days === 1) return Language.t("home_yesterday");
        return Language.t("home_days_ago").replace("%1", days);
    }

    function _syncCardOverflow() {
        AppState.homeContinueOverflow = root.hasContinue && !root.continueVisible;
        AppState.homeRandomOverflow = root.hasRandom && !root.randomVisible;
    }

    readonly property string cardTitle: root.lastGame ? GameUtils.cleanGameTitle(root.lastGame.title) : ""
    readonly property string cardInfo: {
        if (!root.lastGame) return "";
        var parts = [];
        var sys = root.systemName(root.lastGame);
        if (sys !== "") parts.push(sys);
        var pt = root.playTimeText(root.lastGame.playTime);
        if (pt !== "") parts.push(pt);
        var ago = root.agoText(root.lastGame);
        if (ago !== "") parts.push(ago);
        return parts.join("  \u00B7  ");
    }

    readonly property bool hasContinue: SettingsManager.showHomeContinue && root.lastGame !== null
    readonly property bool hasRandom: SettingsManager.showHomeRandomCard

    readonly property real _availW: Math.max(0, root.width - PocketMetrics.margin * 2)
    readonly property real _availH: Math.max(0, root.height - root._topReserve - root._bottomMargin
    - root._menuH - root._gap * 2)

    readonly property real _naturalContinueW: Math.round(root._t * 8)
    readonly property real _minContinueW: root._fullH * 1.5
    readonly property bool _canFitBothFull: (_availW >= _minContinueW + _gap + _fullH) && (_fullH <= _availH)

    readonly property string cardLayout: {
        if (!hasContinue && !hasRandom) return "none";

        if (hasContinue && !hasRandom) {
            if (_fullH <= _availH) return "continue_full";
            if (_compactH <= _availH) return "continue_compact";
            return "none";
        }

        if (!hasContinue && hasRandom) {
            if (_fullH <= _availH) return "random_full";
            if (_compactH <= _availH) return "random_compact";
            return "none";
        }

        if (_canFitBothFull) return "both_full";
        if (_compactH <= _availH) return "both_compact";

        if (_fullH <= _availH) return "continue_full";
        if (_compactH <= _availH) return "continue_compact";
        return "none";
    }

    readonly property bool continueVisible: cardLayout === "both_full" || cardLayout === "both_compact"
    || cardLayout === "continue_full" || cardLayout === "continue_compact"
    readonly property bool randomVisible: cardLayout === "both_full" || cardLayout === "both_compact"
    || cardLayout === "random_full" || cardLayout === "random_compact"
    readonly property bool anyCardVisible: continueVisible || randomVisible

    readonly property real _cardH: {
        if (cardLayout === "both_full" || cardLayout === "continue_full" || cardLayout === "random_full")
            return _fullH;
        return _compactH;
    }
    readonly property real _cardTop: root.height - root._bottomMargin - _cardH

    readonly property real _continueW: {
        if (!continueVisible) return 0;
        if (cardLayout === "both_full") return Math.min(_naturalContinueW, _availW - _gap - _fullH);
        if (cardLayout === "both_compact") return Math.floor((_availW - _gap) / 2);
        return Math.min(_naturalContinueW, _availW);
    }

    readonly property real _randomW: {
        if (!randomVisible) return 0;
        if (cardLayout === "both_full" || cardLayout === "random_full") return _fullH;
        if (cardLayout === "both_compact") return Math.floor((_availW - _gap) / 2);
        return Math.min(_naturalContinueW, _availW);
    }

    readonly property real _cardsTotalW: {
        if (continueVisible && randomVisible) return _continueW + _gap + _randomW;
        return _continueW + _randomW;
    }
    readonly property real _cardsLeft: Math.round((root.width - _cardsTotalW) / 2)

    readonly property int _firstCardIndex: root.continueVisible ? 0 : (root.randomVisible ? 1 : -1)

    onContinueVisibleChanged: {
        if (!root.continueVisible && root.focusedCard === 0)
            root.focusedCard = root.randomVisible ? 1 : -1;
        root._syncCardOverflow()
    }
    onRandomVisibleChanged: {
        if (!root.randomVisible && root.focusedCard === 1)
            root.focusedCard = root.continueVisible ? 0 : -1;
        root._syncCardOverflow();
    }
    onAnyCardVisibleChanged: {
        if (!root.anyCardVisible) root.focusedCard = -1;
    }

    function launchLast() {
        if (!root.lastGame) return;
        Persistence.save();
        SoundEngine.launchGame(root.lastGame);
    }

    property bool _launchingRandom: false
    property var _pendingRandomGame: null
    property real cardRotation: 0

    function launchRandom() {
        if (root._launchingRandom) return;
        var game = NavigationManager.getRandomGame();
        if (!game) return;

        root._launchingRandom = true;
        Persistence.save();

        if (EffectsManager.animationsEnabled) {
            root._pendingRandomGame = game;
            root.cardRotation = 0;
            spinAnim.start();
            SoundEngine.launch();
        } else {
            SoundEngine.launchGame(game);
            root._launchingRandom = false;
        }
    }

    NumberAnimation {
        id: spinAnim
        target: root
        property: "cardRotation"
        from: 0
        to: 360
        duration: EffectsManager.dur(600)
        easing.type: Easing.OutCubic
        onStopped: {
            if (root._pendingRandomGame) {
                root._pendingRandomGame.launch();
                root._pendingRandomGame = null;
            }
            root._launchingRandom = false;
        }
    }

    Component.onCompleted: {
        if (AppState.homeIndex >= 0 && AppState.homeIndex < root.menuItems.length)
            root.currentIndex = AppState.homeIndex;
        else
            root.currentIndex = 0;

        root.lastGame = root.findLastPlayed();
        root._initialized = true;
        Qt.callLater(root._syncCardOverflow);
    }

    onCurrentIndexChanged: {
        if (root._initialized) AppState.selectHomeIndex(root.currentIndex);
    }

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

    Column {
        id: menuColumn
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.anyCardVisible
        ? Math.round(root._topReserve + (root._cardTop - root._gap - root._topReserve - height) / 2)
        : Math.round((root.height - height) / 2)
        spacing: PocketMetrics.spacing

        Repeater {
            model: root.menuItems
            delegate: Text {
                readonly property bool selected: index === root.currentIndex && root.focusedCard === -1

                text: modelData.label
                color: selected ? colors.accent : colors.muted
                font.pixelSize: PocketMetrics.titleSize
                font.bold: selected
                font.family: SettingsManager.fontFamily
                scale: selected ? 1.08 : 1.0
                transformOrigin: Item.Center

                Behavior on color {
                    enabled: EffectsManager.animationsEnabled
                    ColorAnimation { duration: EffectsManager.dur(140) }
                }
                Behavior on scale {
                    enabled: EffectsManager.animationsEnabled
                    NumberAnimation { duration: EffectsManager.dur(140); easing.type: Easing.OutQuad }
                }
            }
        }
    }

    Rectangle {
        id: continueCard
        visible: root.continueVisible
        x: root._cardsLeft
        y: root._cardTop
        width: root._continueW
        height: root._cardH
        radius: EffectsManager.r(4)
        color: colors.card
        border.width: root.focusedCard === 0 ? 2 : 1
        border.color: root.focusedCard === 0 ? colors.accent : colors.border
        opacity: root.focusedCard === 0 ? 1.0 : 0.85

        readonly property bool fullMode: root.cardLayout === "both_full" || root.cardLayout === "continue_full"
        readonly property real pad: Math.max(4, Math.round(root._t * 0.08))
        readonly property real labelSize: Math.max(8, Math.round(root._t * 0.32))
        readonly property real titleSize: Math.max(9, Math.round(root._t * 0.48))
        readonly property real infoSize: Math.max(8, Math.round(root._t * 0.34))

        FontMetrics {
            id: continueFm
            font.pixelSize: continueCard.titleSize
            font.bold: true
            font.family: SettingsManager.fontFamily
        }
        TextMetrics {
            id: continueCap
            font: continueFm.font
            text: "H"
        }
        readonly property real optOffset: Math.round(
            (continueFm.descent - continueFm.ascent + continueCap.tightBoundingRect.height) / 2)

        Behavior on border.color {
            enabled: EffectsManager.animationsEnabled
            ColorAnimation { duration: EffectsManager.dur(140) }
        }
        Behavior on opacity {
            enabled: EffectsManager.animationsEnabled
            NumberAnimation { duration: EffectsManager.dur(140) }
        }

        Item {
            anchors.fill: parent
            anchors.margins: continueCard.pad
            visible: continueCard.fullMode

            GameArtCard {
                id: art
                width: parent.height
                height: parent.height
                game: root.lastGame
                artSource: GameUtils.getPreferredArt(root.lastGame, "gameLists")
            }

            Column {
                anchors.left: art.right
                anchors.leftMargin: continueCard.pad * 1.5
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.max(2, Math.round(root._t * 0.04))

                Text {
                    width: parent.width
                    text: Language.t("home_continue")
                    color: colors.muted
                    font.pixelSize: continueCard.labelSize
                    font.family: SettingsManager.fontFamily
                    elide: Text.ElideRight
                }

                MarqueeText {
                    width: parent.width
                    text: root.cardTitle
                    color: root.focusedCard === 0 ? colors.accent : colors.fg
                    pixelSize: continueCard.titleSize
                    bold: true
                    active: root.focusedCard === 0
                    padVertical: 0
                }

                Text {
                    width: parent.width
                    text: root.cardInfo
                    color: colors.muted
                    font.pixelSize: continueCard.infoSize
                    font.family: SettingsManager.fontFamily
                    elide: Text.ElideRight
                }
            }
        }

        Item {
            anchors.fill: parent
            anchors.margins: 1
            anchors.leftMargin: continueCard.pad * 2
            anchors.rightMargin: continueCard.pad * 2
            visible: !continueCard.fullMode

            Text {
                id: compactTime
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: continueCard.optOffset
                text: root.playTimeText(root.lastGame ? root.lastGame.playTime : 0)
                color: colors.muted
                font.pixelSize: continueCard.infoSize
                font.family: SettingsManager.fontFamily
            }

            MarqueeText {
                anchors.left: parent.left
                anchors.right: compactTime.left
                anchors.rightMargin: continueCard.pad
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: continueCard.optOffset
                text: "> " + root.cardTitle
                color: root.focusedCard === 0 ? colors.accent : colors.fg
                pixelSize: continueCard.titleSize
                bold: true
                active: root.focusedCard === 0
                padVertical: 0
            }
        }
    }

    Rectangle {
        id: randomCard
        visible: root.randomVisible
        x: root.continueVisible ? (root._cardsLeft + root._continueW + root._gap) : root._cardsLeft
        y: root._cardTop
        width: root._randomW
        height: root._cardH
        radius: EffectsManager.r(4)
        color: colors.card
        border.width: root.focusedCard === 1 ? 2 : 1
        border.color: root.focusedCard === 1 ? colors.accent : colors.border
        opacity: root.focusedCard === 1 ? 1.0 : 0.85

        readonly property bool fullMode: root.cardLayout === "both_full" || root.cardLayout === "random_full"
        readonly property real pad: Math.max(4, Math.round(root._t * 0.08))
        readonly property real compactIconSize: Math.max(14, Math.round(root._t * 0.42))
        readonly property real compactTextSize: Math.max(8, Math.round(root._t * 0.34))

        readonly property string iconSource: Qt.resolvedUrl("../assets/icons/random.svg")

        FontMetrics {
            id: randomFm
            font.pixelSize: randomCard.compactTextSize
            font.bold: true
            font.family: SettingsManager.fontFamily
        }
        TextMetrics {
            id: randomCap
            font: randomFm.font
            text: "H"
        }
        readonly property real optOffset: Math.round(
            (randomFm.descent - randomFm.ascent + randomCap.tightBoundingRect.height) / 2)

        Behavior on border.color {
            enabled: EffectsManager.animationsEnabled
            ColorAnimation { duration: EffectsManager.dur(140) }
        }
        Behavior on opacity {
            enabled: EffectsManager.animationsEnabled
            NumberAnimation { duration: EffectsManager.dur(140) }
        }

        Item {
            anchors.fill: parent
            visible: randomCard.fullMode

            Item {
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height) * 0.55
                height: width
                rotation: root.cardRotation
                transformOrigin: Item.Center

                Image {
                    id: randomIconFull
                    anchors.fill: parent
                    source: randomCard.iconSource
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                    sourceSize.width: width > 0 ? Math.round(width) : 128
                    sourceSize.height: height > 0 ? Math.round(height) : 128
                    visible: status === Image.Ready

                    layer.enabled: EffectsManager.shaderEffectsEnabled
                    layer.smooth: true
                    layer.effect: ColorOverlay {
                        color: root.focusedCard === 1 ? colors.accent : colors.fg
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: randomIconFull.status !== Image.Ready
                    text: Language.t("home_random_short")
                    color: root.focusedCard === 1 ? colors.accent : colors.fg
                    font.pixelSize: Math.max(10, Math.round(root._cardH * 0.18))
                    font.bold: true
                    font.family: SettingsManager.fontFamily
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.0
                }
            }
        }

        Item {
            anchors.fill: parent
            anchors.margins: 1
            visible: !randomCard.fullMode

            Row {
                anchors.centerIn: parent
                spacing: Math.round(root._t * 0.12)

                Item {
                    width: randomCard.compactIconSize
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    rotation: root.cardRotation
                    transformOrigin: Item.Center

                    Image {
                        id: randomIconCompact
                        anchors.fill: parent
                        source: randomCard.iconSource
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        asynchronous: true
                        sourceSize.width: width > 0 ? Math.round(width) : 64
                        sourceSize.height: height > 0 ? Math.round(height) : 64
                        visible: status === Image.Ready

                        layer.enabled: EffectsManager.shaderEffectsEnabled
                        layer.smooth: true
                        layer.effect: ColorOverlay {
                            color: root.focusedCard === 1 ? colors.accent : colors.fg
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: randomCard.optOffset
                    text: Language.t("home_random")
                    color: root.focusedCard === 1 ? colors.accent : colors.fg
                    font.pixelSize: randomCard.compactTextSize
                    font.bold: true
                    font.family: SettingsManager.fontFamily
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth,
                                    randomCard.width - randomCard.pad * 2
                                    - (randomIconCompact.visible ? randomCard.compactIconSize + parent.spacing : 0))
                }
            }
        }
    }

    Keys.onUpPressed: {
        if (root._launchingRandom) return;
        SoundEngine.scroll();
        if (root.focusedCard !== -1) {
            root.focusedCard = -1;
            return;
        }
        root.currentIndex = Math.max(0, root.currentIndex - 1);
    }

    Keys.onDownPressed: {
        if (root._launchingRandom) return;
        SoundEngine.scroll();
        if (root.focusedCard !== -1) return;
        if (root.currentIndex >= root.menuItems.length - 1 && root._firstCardIndex !== -1) {
            root.focusedCard = root._firstCardIndex;
            return;
        }
        root.currentIndex = Math.min(root.menuItems.length - 1, root.currentIndex + 1);
    }

    Keys.onLeftPressed: {
        if (root._launchingRandom) return;
        if (root.focusedCard === 1 && root.continueVisible) {
            SoundEngine.scroll();
            root.focusedCard = 0;
        }
    }

    Keys.onRightPressed: {
        if (root._launchingRandom) return;
        if (root.focusedCard === 0 && root.randomVisible) {
            SoundEngine.scroll();
            root.focusedCard = 1;
        }
    }

    Keys.onPressed: {
        if (root._launchingRandom) return;
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (root.focusedCard === 0) { root.launchLast(); return; }
            if (root.focusedCard === 1) { root.launchRandom(); return; }
            var selected = root.menuItems[root.currentIndex];
            if (selected.screen === Enums.screenSettings) {
                NavigationManager.enterSettings();
            } else {
                NavigationManager.enterScreen(selected.screen);
            }
        }
    }
}
