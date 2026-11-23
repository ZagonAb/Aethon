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

    readonly property var game: AppState.currentGame
    readonly property var collection: AppState.currentCollection

    readonly property string collectionShortName: {
        if (!root.game) return "";
        try {
            if (root.game.collections && root.game.collections.count > 0) {
                var col = root.game.collections.get(0);
                var sn = (col.shortName && col.shortName !== "") ? col.shortName : col.name;
                return (sn || "").toLowerCase().replace(/[\s\-_]/g, "");
            }
        } catch (e) { }
        return "";
    }

    readonly property var colors: SettingsManager.getCurrentColors()
    readonly property string cleanTitle: root.game ? GameUtils.cleanGameTitle(root.game.title) : Language.t("label_no_games")
    readonly property string cleanGenre: root.game ? GameUtils.firstCleanGenre(root.game.genre) : "—"
    readonly property string formattedPlayTime: GameUtils.formatPlayTime(root.game ? root.game.playTime : 0)

    readonly property var raSummary: {
        var _lang = Language.currentLanguage;
        var st = RetroAchievements.raState;
        if (st === "no_credentials" || st === "idle") return null;
        if (settleGate.settling || st === "searching" || st === "loading")
            return { text: Language.t("ra_searching"), color: colors.muted };
        if (st === "found")
            return {
                text: "🏆 " + RetroAchievements.raNumEarned + "/" + RetroAchievements.raNumAchievements
                + " · " + RetroAchievements.raPointsEarned + "/" + RetroAchievements.raPoints
                + " " + Language.t("achievements_points_suffix"),
                color: colors.accent
            };
        if (st === "no_achievements")
            return { text: Language.t("ra_no_achievements"), color: colors.muted };
        if (st === "not_found")
            return { text: Language.t("ra_not_found"), color: colors.muted };
        return { text: Language.t("ra_unavailable"), color: colors.muted };
    }

    property int lastStepDirection: 0

    onGameChanged: {
        layoutFadeIn.restart();
    }

    SettleGate {
        id: settleGate
        input: root.game
        onSettled: function(value) {
            RetroAchievements.lookupGame(value);
        }
    }

    Component.onCompleted: {
        RetroAchievements.lookupGame(root.game);
    }

    readonly property var actions: {
        var base = (ResponsiveManager.aspectProfile === Enums.profileWide)
        ? ["previous", "play", "next"]
        : ["play"];
        if (RetroAchievements.raState === "found" && RetroAchievements.raNumAchievements > 0)
            base = base.concat(["trophies"]);
        return base;
    }

    property int actionIndex: 0

    onActionsChanged: {
        if (root.actionIndex >= root.actions.length)
            root.actionIndex = root.actions.length - 1;
        if (root.actionIndex === 0 && root.actions.length > 1 && root.actions[0] !== "play") {
            var playIdx = root.actions.indexOf("play");
            if (playIdx >= 0) root.actionIndex = playIdx;
        }
    }

    readonly property string artSource: GameUtils.getPreferredArt(settleGate.output, "gameDetails")

    function _cameFromInspector() {
        var h = NavigationManager.history;
        if (!h || h.length === 0) return false;
        return h[h.length - 1].screen === Enums.screenGameInspector;
    }

    function _getInspectorGames() {
        var id = AppState.metadataActiveCheckId;
        var games = [];
        if (id.indexOf("field_") === 0) {
            games = MetadataEngine.gamesMissing(id.substring(6));
        } else if (id.indexOf("art_") === 0) {
            games = MetadataEngine.gamesAtCascadeLevel(id.substring(4));
        } else if (id === "coll_emptyCollection") {
            games = [];
        } else if (id === "coll_duplicateTitles") {
            games = MetadataEngine.gamesWithDuplicateTitles();
        } else if (id !== "") {
            games = MetadataEngine.gamesWithIssue(id);
        }
        return games;
    }

    function getCurrentGameList() {
        if (root._cameFromInspector()) {
            var games = root._getInspectorGames();
            return {
                count: games.length,
                get: function(idx) { return games[idx] || null; }
            };
        }

        if (AppState.cameFromCalendar) {
            var entries = CalendarEngine.getGamesForDate(AppState.calendarSelectedDate.y, AppState.calendarSelectedDate.m + 1, AppState.calendarSelectedDate.d);
            var list = [];
            for (var i = 0; i < entries.length; i++) {
                list.push(entries[i].game);
            }
            return {
                count: list.length,
                get: function(idx) { return list[idx] || null; }
            };
        }

        if (root.collection)
            return root.collection.games;

        var section = AppState.currentSection;

        if (section === Enums.sectionAll) {
            return api.allGames;
        } else if (section === Enums.sectionRecent) {
            var all = api.allGames.toVarArray();
            var played = all.filter(function(g) { return g.playCount > 0; });
            played.sort(function(a, b) {
                var ta = a.lastPlayed ? a.lastPlayed.getTime() : 0;
                var tb = b.lastPlayed ? b.lastPlayed.getTime() : 0;
                return tb - ta;
            });
            played = played.slice(0, 15);
            return {
                count: played.length,
                get: function(idx) { return played[idx] || null; }
            };
        } else if (section === Enums.sectionFavorites) {
            var all2 = api.allGames.toVarArray();
            var favs = all2.filter(function(g) { return g.favorite === true; });
            return {
                count: favs.length,
                get: function(idx) { return favs[idx] || null; }
            };
        } else if (section === Enums.sectionLongplays) {
            var all3 = api.allGames.toVarArray();
            var longplayed = all3.filter(function(g) { return g.playCount > 0 || g.playTime > 0; });

            var maxTime = 0, maxCount = 0;
            for (var i = 0; i < longplayed.length; i++) {
                if (longplayed[i].playTime > maxTime) maxTime = longplayed[i].playTime;
                if (longplayed[i].playCount > maxCount) maxCount = longplayed[i].playCount;
            }
            function score(g) {
                var timeNorm = maxTime > 0 ? g.playTime / maxTime : 0;
                var countNorm = maxCount > 0 ? g.playCount / maxCount : 0;
                return (timeNorm * 0.5) + (countNorm * 0.5);
            }
            longplayed.sort(function(a, b) { return score(b) - score(a); });

            longplayed = longplayed.slice(0, 15);

            return {
                count: longplayed.length,
                get: function(idx) { return longplayed[idx] || null; }
            };
        } else if (NavigationManager.isCategorySection(section)) {
            var catGames;
            if (section === Enums.sectionYears && AppState.currentCategorySubValue !== "") {
                catGames = CategoryLibrary.gamesForYear(AppState.currentCategorySubValue);
            } else {
                catGames = CategoryLibrary.gamesForCategory(section, AppState.currentCategoryValue);
            }
            return {
                count: catGames.length,
                get: function(idx) { return catGames[idx] || null; }
            };
        } else if (section === Enums.sectionRALibrary) {
            var raEntries = RetroAchievements.libraryEntries;
            var raGames = [];
            for (var ri = 0; ri < raEntries.length; ri++) {
                if (raEntries[ri].pegasusGame) raGames.push(raEntries[ri].pegasusGame);
            }
            return {
                count: raGames.length,
                get: function(idx) { return raGames[idx] || null; }
            };
        }
        return api.allGames;
    }

    function stepGame(delta) {
        var list = root.getCurrentGameList();
        var count = list.count;
        if (count === 0)
            return;

        var currentIdx = AppState.currentGameIndex;
        if (currentIdx < 0 || currentIdx >= count)
            currentIdx = 0;

        var newIndex = (currentIdx + delta + count) % count;
        var gameObj = list.get(newIndex);
        if (gameObj) {
            AppState.selectGame(gameObj, newIndex);
        }
    }

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

    Loader {
        id: layoutLoader
        anchors.fill: parent

        transform: Translate { id: layoutSlide; x: 0 }

        source: {
            switch (ResponsiveManager.aspectProfile) {
                case Enums.profileSquare: return "../Layout/SquareLayout.qml";
                case Enums.profileClassic: return "../Layout/ClassicLayout.qml";
                default: return "../Layout/WideLayout.qml";
            }
        }

        onLoaded: {
            layoutFadeIn.restart();
        }
    }

    NumberAnimation {
        id: layoutSlideIn
        target: layoutSlide
        property: "x"
        from: root.lastStepDirection > 0 ? PocketMetrics.animationDistance
        : root.lastStepDirection < 0 ? -PocketMetrics.animationDistance
        : 0
        to: 0
        duration: EffectsManager.dur(180)
        easing.type: Easing.OutQuad
    }

    NumberAnimation {
        id: layoutFadeIn
        target: layoutLoader
        property: "opacity"
        from: 0
        to: 1
        duration: EffectsManager.dur(160)
        easing.type: Easing.OutQuad
        onStarted: layoutSlideIn.restart()
        onStopped: root.lastStepDirection = 0
    }

    Binding { target: layoutLoader.item; property: "game"; value: root.game; when: layoutLoader.item !== null }
    Binding { target: layoutLoader.item; property: "collection"; value: root.collection; when: layoutLoader.item !== null }
    Binding { target: layoutLoader.item; property: "artSource"; value: root.artSource; when: layoutLoader.item !== null }
    Binding { target: layoutLoader.item; property: "actions"; value: root.actions; when: layoutLoader.item !== null }
    Binding { target: layoutLoader.item; property: "actionIndex"; value: root.actionIndex; when: layoutLoader.item !== null }
    Binding { target: layoutLoader.item; property: "raSummary"; value: root.raSummary; when: layoutLoader.item !== null }
    Binding { target: layoutLoader.item; property: "cleanTitle"; value: root.cleanTitle; when: layoutLoader.item !== null }
    Binding { target: layoutLoader.item; property: "cleanGenre"; value: root.cleanGenre; when: layoutLoader.item !== null }
    Binding { target: layoutLoader.item; property: "formattedPlayTime"; value: root.formattedPlayTime; when: layoutLoader.item !== null }

    Keys.onLeftPressed: {
        SoundEngine.scroll();
        root.actionIndex = Math.max(0, root.actionIndex - 1);
    }

    Keys.onRightPressed: {
        SoundEngine.scroll();
        root.actionIndex = Math.min(root.actions.length - 1, root.actionIndex + 1);
    }

    Keys.onPressed: {
        if (api.keys.isDetails(event)) {
            event.accepted = true;
            if (!event.isAutoRepeat)
                SoundEngine.back();
            return;
        }

        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            var action = root.actions[root.actionIndex];

            if (action === "play") {
                Persistence.save();
                SoundEngine.launchGame(root.game);
            } else if (action === "previous") {
                SoundEngine.scroll();
                root.lastStepDirection = -1;
                root.stepGame(-1);
            } else if (action === "next") {
                SoundEngine.scroll();
                root.lastStepDirection = 1;
                root.stepGame(1);
            } else if (action === "trophies") {
                if (!settleGate.settling)
                    NavigationManager.enterAchievements();
            }
        }
    }
}
