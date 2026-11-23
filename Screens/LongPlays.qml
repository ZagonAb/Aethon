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

    property var longplaysList: []
    readonly property int count: root.longplaysList.length
    property int currentIndex: 0
    readonly property var currentGameRef: root.count > 0 ? root.longplaysList[root.currentIndex] : null

    SettleGate {
        id: settleGate
        input: root.currentGameRef
    }
    readonly property var shownGameRef: settleGate.output
    readonly property bool scrolling: settleGate.settling
    readonly property string artSource: GameUtils.getPreferredArt(root.shownGameRef, "gameLists")
    readonly property var colors: SettingsManager.getCurrentColors()

    Component.onCompleted: {
        var all = api.allGames.toVarArray();
        var played = all.filter(function (g) { return g.playCount > 0 || g.playTime > 0; });

        var maxTime = 0;
        var maxCount = 0;
        for (var i = 0; i < played.length; i++) {
            if (played[i].playTime > maxTime) maxTime = played[i].playTime;
            if (played[i].playCount > maxCount) maxCount = played[i].playCount;
        }

        function score(g) {
            var timeNorm = maxTime > 0 ? g.playTime / maxTime : 0;
            var countNorm = maxCount > 0 ? g.playCount / maxCount : 0;
            return (timeNorm * 0.5) + (countNorm * 0.5);
        }

        played.sort(function (a, b) { return score(b) - score(a); });

        played = played.slice(0, 15);

        root.longplaysList = played;

        var resumeIndex = 0;
        if (AppState.currentGame) {
            for (var i = 0; i < played.length; i++) {
                if (played[i] === AppState.currentGame) {
                    resumeIndex = i;
                    break;
                }
            }
        }

        if (root.count > 0)
            root.commitIndex(resumeIndex);
        settleGate.snap();
    }

    function commitIndex(index) {
        root.currentIndex = index;
        if (index >= 0 && index < root.count)
            AppState.selectGame(root.longplaysList[index], index);
    }

    function formatPlayTime(seconds) {
        if (!seconds || seconds <= 0)
            return "00:00:00";
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        var s = Math.floor(seconds % 60);
        function pad(n) { return (n < 10 ? "0" : "") + n; }
        return pad(h) + ":" + pad(m) + ":" + pad(s);
    }

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

    Column {
        id: contentColumn
        anchors.centerIn: parent
        spacing: PocketMetrics.spacing
        visible: root.count > 0

        transform: Translate { id: contentSlide; x: 0 }

        Text {
            text: Language.t("section_longplays")
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
            text: root.currentGameRef ? GameUtils.cleanGameTitle(root.currentGameRef.title) : ""
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

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: PocketMetrics.spacing * 2

            Text {
                text: root.shownGameRef
                ? (Language.t("recent_play_time") + " " + root.formatPlayTime(root.shownGameRef.playTime))
                : (Language.t("recent_play_time") + " —")
                color: colors.fg
                font.pixelSize: PocketMetrics.bodySize
                font.family: SettingsManager.fontFamily
            }

            Text {
                text: root.shownGameRef
                ? (Language.t("longplays_launched") + " " + root.shownGameRef.playCount + "x")
                : (Language.t("longplays_launched") + " —")
                color: colors.fg
                font.pixelSize: PocketMetrics.bodySize
                font.family: SettingsManager.fontFamily
            }
        }

        Text {
            text: root.count > 0 ? ((root.currentIndex + 1) + " / " + root.count) : ""
            color: colors.muted
            font.pixelSize: PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.count === 0
        text: Language.t("recent_empty")
        color: colors.muted
        font.pixelSize: PocketMetrics.bodySize
        font.family: SettingsManager.fontFamily
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
