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

    readonly property int count: api.allGames.count
    property int currentIndex: 0

    readonly property var currentGameRef: root.count > 0 ? api.allGames.get(root.currentIndex) : null

    SettleGate {
        id: settleGate
        input: root.currentGameRef
    }
    readonly property var shownGameRef: settleGate.output
    readonly property bool scrolling: settleGate.settling

    readonly property string artSource: GameUtils.getPreferredArt(root.shownGameRef, "gameLists")
    readonly property var colors: SettingsManager.getCurrentColors()

    Component.onCompleted: {
        if (AppState.currentGameIndex >= 0 && AppState.currentGameIndex < root.count
            && AppState.currentCollection === null) {
            root.currentIndex = AppState.currentGameIndex;
            } else if (root.count > 0) {
                root.commitIndex(0);
            }
            settleGate.snap();
    }

    function commitIndex(index) {
        root.currentIndex = index;
        if (index >= 0 && index < root.count)
            AppState.selectGame(api.allGames.get(index), index);
    }

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

    Column {
        id: contentColumn
        anchors.centerIn: parent
        spacing: PocketMetrics.spacing

        transform: Translate { id: contentSlide; x: 0 }

        Text {
            text: Language.t("section_all")
            color: colors.muted
            font.pixelSize: PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter
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
            : Language.t("label_no_games")
            favorite: root.currentGameRef ? root.currentGameRef.favorite === true : false
            showFavorite: true
            colors: root.colors
        }

        Text {
            text: root.shownGameRef ? GameUtils.gameMetadataLine(root.shownGameRef, true) : "\u00A0"
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
