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
import "../Components"

FocusScope {
    id: root
    anchors.fill: parent
    focus: true

    readonly property var collection: AppState.currentCollection
    readonly property int count: root.collection ? root.collection.games.count : 0
    property int currentIndex: 0
    readonly property var currentGameRef: root.count > 0 ? root.collection.games.get(root.currentIndex) : null

    SettleGate {
        id: settleGate
        input: root.currentGameRef
    }
    readonly property var shownGameRef: settleGate.output
    readonly property bool scrolling: settleGate.settling
    readonly property string artSource: GameUtils.getPreferredArt(root.shownGameRef, "gameLists")
    readonly property var colors: SettingsManager.getCurrentColors()

    Component.onCompleted: {
        if (AppState.currentGameIndex >= 0 && AppState.currentGameIndex < root.count) {
            root.currentIndex = AppState.currentGameIndex;
            var game = root.collection.games.get(root.currentIndex);
            if (game) AppState.selectGame(game, root.currentIndex);
        } else if (root.count > 0) {
            root.commitIndex(0);
        }
        settleGate.snap();
    }

    function commitIndex(index) {
        root.currentIndex = index;
        if (root.collection && index >= 0 && index < root.count) {
            var game = root.collection.games.get(index);
            AppState.selectGame(game, index);
        }
    }

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

    Column {
        id: contentColumn
        anchors.centerIn: parent
        spacing: PocketMetrics.spacing

        transform: Translate { id: contentSlide; x: 0 }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(PocketMetrics.spacing * 0.3)

            readonly property string shortName: {
                if (!root.collection) return "";
                var sn = root.collection.shortName;
                if (sn && sn !== "")
                    return sn.toLowerCase().replace(/[\s\-_]/g, "");
                return (root.collection.name || "").toLowerCase().replace(/[\s\-_]/g, "");
            }
            readonly property string iconUrl: {
                if (!SettingsManager.showSystemIcons) return "";
                if (parent.shortName === "") return "";
                return Qt.resolvedUrl("../assets/systems/" + parent.shortName + ".png");
            }

            Image {
                id: systemIconHeader
                source: parent.iconUrl
                visible: source !== "" && status === Image.Ready
                width: visible ? PocketMetrics.bodySize * 1.4 : 0
                height: width
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                anchors.verticalCenter: parent.verticalCenter
                sourceSize.width: 96
                sourceSize.height: 96
            }

            Text {
                text: root.collection ? root.collection.name : ""
                color: colors.muted
                font.pixelSize: PocketMetrics.bodySize
                font.family: SettingsManager.fontFamily
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        GameArtCard {
            width: PocketMetrics.cardWidth
            height: PocketMetrics.cardHeight
            anchors.horizontalCenter: parent.horizontalCenter
            game: root.currentGameRef
            artSource: root.artSource
            colors: root.colors
        }

        GameTitle {
            width: Math.min(root.width - PocketMetrics.margin * 2, 900)
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.currentGameRef
            ? GameUtils.cleanGameTitle(root.currentGameRef.title)
            : Language.t("label_no_games_in_system")
            favorite: root.currentGameRef ? root.currentGameRef.favorite === true : false
            showFavorite: true
            colors: root.colors
        }

        Text {
            text: root.shownGameRef ? GameUtils.gameMetadataLine(root.shownGameRef, false) : "\u00A0"
            color: colors.fg
            font.pixelSize: PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(root.width - PocketMetrics.margin * 2, 900)
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: root.count > 0 ? ((root.currentIndex + 1) + " / " + root.count) : ""
            color: colors.muted
            font.pixelSize: PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    property int lastStepDirection: 0

    NumberAnimation {
        id: pulseSlide
        target: contentSlide
        property: "x"
        from: root.lastStepDirection > 0 ? PocketMetrics.animationDistance
        : root.lastStepDirection < 0 ? -PocketMetrics.animationDistance
        : 0
        to: 0
        duration: EffectsManager.dur(180)
        easing.type: Easing.OutQuad
    }

    NumberAnimation {
        id: pulseAnim
        target: contentColumn
        property: "opacity"
        from: 0.35
        to: 1.0
        duration: EffectsManager.dur(150)
        easing.type: Easing.OutQuad
        onStarted: pulseSlide.restart()
    }
    onCurrentIndexChanged: pulseAnim.restart()

    Keys.onLeftPressed: {
        SoundEngine.scroll();
        if (root.count > 0) {
            root.lastStepDirection = -1;
            root.commitIndex((root.currentIndex - 1 + root.count) % root.count);
        }
    }

    Keys.onRightPressed: {
        SoundEngine.scroll();
        if (root.count > 0) {
            root.lastStepDirection = 1;
            root.commitIndex((root.currentIndex + 1) % root.count);
        }
    }

    Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (root.currentGameRef)
                NavigationManager.enterGameDetails();
        }
    }
}
