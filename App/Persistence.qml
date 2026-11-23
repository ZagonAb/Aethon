// Aethon
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
pragma Singleton
import QtQuick 2.15

QtObject {
    id: root

    readonly property string storageKey: "aethon.state"
    property bool restoring: false

    function save() {
        if (root.restoring) return;

        var snap;
        if (AppState.preSearchContext &&
            (AppState.currentScreen === Enums.screenSearch ||
            AppState.currentScreen === Enums.screenGameDetails)) {
            var ctx = AppState.preSearchContext;
        snap = {
            screen: ctx.screen,
            section: ctx.section,
            collectionName: ctx.collection ? ctx.collection.name : "",
            categoryValue: ctx.categoryValue || "",
            categorySubValue: ctx.categorySubValue || "",
            gameIndex: ctx.gameIndex,
            gameTitle: ctx.gameTitle || "",
            gameCollectionShortName: ctx.gameShortName || "",
            calendarSelectedDate: AppState.calendarSelectedDate,
            cameFromCalendar: false,
            metadataActiveScope: MetadataEngine.activeScope,
            galleryAssetKey: ctx.galleryAssetKey || "",
            galleryAssetTitle: ctx.galleryAssetTitle || "",
            galleryListIndex: ctx.galleryListIndex || 0,
            galleryGridIndex: ctx.galleryGridIndex || 0,
            toolsIndex: ctx.toolsIndex || 0,
            homeIndex: AppState.homeIndex,
            cameFromGallery: false
        };
            } else {
                snap = AppState.snapshot();
            }
            api.memory.set(root.storageKey, snap);
    }

    function restore() {
        if (!api.memory.has(root.storageKey)) {
            AppState.reset();
            return;
        }

        var data = api.memory.get(root.storageKey);
        if (!data) {
            AppState.reset();
            return;
        }

        root.restoring = true;
        AppState.reset();
        NavigationManager.history = [];

        var targetScreen = (data.screen !== undefined) ? data.screen : Enums.screenHome;

        if (targetScreen === Enums.screenAbout) {
            AppState.homeIndex = 0;
            AppState.currentScreen = Enums.screenHome;
            root.restoring = false;
            return;
        }

        var targetSection = (data.section !== undefined) ? data.section : Enums.sectionAll;
        var collection = data.collectionName ? root.findCollectionByName(data.collectionName) : null;
        var index = (data.gameIndex !== undefined) ? data.gameIndex : -1;
        var gameTitle = data.gameTitle || "";
        var gameShortName = data.gameCollectionShortName || "";
        var categoryValue = data.categoryValue || "";
        var categorySubValue = data.categorySubValue || "";
        var metaScope = data.metadataActiveScope || "all";

        AppState.calendarSelectedDate = data.calendarSelectedDate || { y: 0, m: 0, d: 0 };
        AppState.cameFromCalendar = data.cameFromCalendar || false;

        AppState.galleryAssetKey = data.galleryAssetKey || "";
        AppState.galleryAssetTitle = data.galleryAssetTitle || "";
        AppState.galleryListIndex = data.galleryListIndex || 0;
        AppState.galleryGridIndex = data.galleryGridIndex || 0;
        AppState.toolsIndex = data.toolsIndex || 0;
        AppState.homeIndex = (data.homeIndex !== undefined) ? data.homeIndex : 0;

        if (targetScreen === Enums.screenCalendarDay || targetScreen === Enums.screenCalendar || (targetScreen === Enums.screenGameDetails && data.cameFromCalendar === true)) {
            CalendarEngine.buildIndex();
        }

        if (targetScreen === Enums.screenHome) {
            root.restoring = false;
            return;
        }

        if (targetScreen === Enums.screenCalendar) {
            NavigationManager.enterScreen(Enums.screenTools);
            NavigationManager.enterCalendar(false);
            root.restoring = false;
            return;
        }

        if (targetScreen === Enums.screenCalendarDay) {
            NavigationManager.enterScreen(Enums.screenTools);
            NavigationManager.enterCalendar(false);
            var entries = CalendarEngine.getGamesForDate(AppState.calendarSelectedDate.y, AppState.calendarSelectedDate.m + 1, AppState.calendarSelectedDate.d);
            var list = [];
            for (var i = 0; i < entries.length; i++) list.push(entries[i].game);
            var match = root.findGameInList(list, gameTitle, gameShortName, index);
            if (match.game) AppState.selectGame(match.game, match.index);
            NavigationManager.enterCalendarDay();
            root.restoring = false;
            return;
        }

        if (targetScreen === Enums.screenTools || targetScreen === Enums.screenSettings || targetScreen === Enums.screenSearch || targetScreen === Enums.screenRACredentials || targetScreen === Enums.screenAchievements || targetScreen === Enums.screenRAGames || targetScreen === Enums.screenWeather || targetScreen === Enums.screenWeatherSettings || targetScreen === Enums.screenStatistics) {
            NavigationManager.enterScreen(targetScreen);
            root.restoring = false;
            return;
        }

        if (targetScreen === Enums.screenGalleryList || targetScreen === Enums.screenGalleryGrid) {
            NavigationManager.enterScreen(Enums.screenTools);
            NavigationManager.enterGallery();
            if (targetScreen === Enums.screenGalleryGrid) {
                NavigationManager.enterGalleryGrid(AppState.galleryAssetKey, AppState.galleryAssetTitle);
            }
            root.restoring = false;
            return;
        }

        if (targetScreen === Enums.screenMetadataInspector ||
            targetScreen === Enums.screenMetadataList ||
            targetScreen === Enums.screenGameInspector) {

            MetadataEngine.activeScope = metaScope;

        NavigationManager.enterScreen(Enums.screenTools);
        NavigationManager.enterMetadataInspector();

        root.restoring = false;
        return;
            }

            if (targetScreen === Enums.screenMemories) {
                NavigationManager.enterScreen(Enums.screenMemories);
                if (targetSection !== Enums.sectionAll) NavigationManager.enterSection(targetSection);
                root.restoring = false;
                return;
            }

            if (targetScreen === Enums.screenLibrary) {
                NavigationManager.enterScreen(Enums.screenLibrary);
                if (targetSection !== Enums.sectionAll || collection !== null || categoryValue !== "") {
                    NavigationManager.enterSection(targetSection);
                    if (collection !== null) {
                        NavigationManager.enterCollection(collection);
                    } else if (categoryValue !== "") {
                        NavigationManager.enterCategoryValue(categoryValue);
                        if (categorySubValue !== "") NavigationManager.enterCategorySubValue(categorySubValue);
                    }
                }
                root.restoring = false;
                return;
            }

            if (targetScreen === Enums.screenGameDetails) {
                if (data.cameFromGallery === true) {
                    root.restoreToGameDetailsFromGallery(gameTitle, gameShortName, index);
                } else if (data.cameFromCalendar === true) {
                    root.restoreToGameDetailsFromCalendar(gameTitle, gameShortName, index);
                } else {
                    root.restoreToGameDetails(targetSection, collection, categoryValue, categorySubValue, index, gameTitle, gameShortName);
                }
                root.restoring = false;
                return;
            }

            root.restoring = false;
    }

    function restoreToGameDetailsFromGallery(gameTitle, gameShortName, savedIndex) {
        NavigationManager.enterScreen(Enums.screenTools);
        NavigationManager.enterGallery();
        NavigationManager.enterGalleryGrid(AppState.galleryAssetKey, AppState.galleryAssetTitle);
        var all = api.allGames.toVarArray();
        var match = root.findGameInList(all, gameTitle, gameShortName, savedIndex);
        if (!match.game) return;
        NavigationManager.enterGameFromGallery(match.game);
    }

    function restoreToGameDetailsFromCalendar(gameTitle, gameShortName, savedIndex) {
        NavigationManager.enterScreen(Enums.screenTools);
        NavigationManager.enterCalendar(false);
        var entries = CalendarEngine.getGamesForDate(AppState.calendarSelectedDate.y, AppState.calendarSelectedDate.m + 1, AppState.calendarSelectedDate.d);
        var list = [];
        for (var i = 0; i < entries.length; i++) list.push(entries[i].game);
        var match = root.findGameInList(list, gameTitle, gameShortName, savedIndex);
        if (match.game) AppState.selectGame(match.game, match.index);
        NavigationManager.enterCalendarDay();
        NavigationManager.enterGameDetailsFromCalendar();
    }

    function restoreToGameDetails(section, collection, categoryValue, categorySubValue, savedIndex, gameTitle, gameShortName) {
        var list = [];
        var isMemories = (section === Enums.sectionRecent || section === Enums.sectionFavorites || section === Enums.sectionLongplays);

        if (isMemories) {
            NavigationManager.enterScreen(Enums.screenMemories);
            NavigationManager.enterSection(section);
            if (section === Enums.sectionRecent) list = root.getRecentGames();
            else if (section === Enums.sectionFavorites) list = root.getFavoriteGames();
            else list = root.getLongplayGames();
        } else if (collection !== null) {
            NavigationManager.enterScreen(Enums.screenLibrary);
            NavigationManager.enterSection(Enums.sectionSystems);
            NavigationManager.enterCollection(collection);
            var cg = collection.games;
            if (cg && typeof cg.count === "number" && typeof cg.get === "function") {
                for (var ci = 0; ci < cg.count; ci++) list.push(cg.get(ci));
            } else if (cg && cg.length !== undefined) {
                for (var cj = 0; cj < cg.length; cj++) list.push(cg[cj]);
            }
        } else if (section === Enums.sectionRALibrary) {
            NavigationManager.enterScreen(Enums.screenRAGames);
            var raEntries = RetroAchievements.libraryEntries;
            for (var ri = 0; ri < raEntries.length; ri++) {
                if (raEntries[ri].pegasusGame) list.push(raEntries[ri].pegasusGame);
            }
        } else if (categoryValue !== "") {
            NavigationManager.enterScreen(Enums.screenLibrary);
            NavigationManager.enterSection(section);
            NavigationManager.enterCategoryValue(categoryValue);
            if (categorySubValue !== "") {
                NavigationManager.enterCategorySubValue(categorySubValue);
                list = CategoryLibrary.gamesForYear(categorySubValue);
            } else {
                list = CategoryLibrary.gamesForCategory(section, categoryValue);
            }
        } else {
            NavigationManager.enterScreen(Enums.screenLibrary);
            NavigationManager.enterSection(Enums.sectionAll);
            list = api.allGames.toVarArray();
        }

        var match = root.findGameInList(list, gameTitle, gameShortName, savedIndex);
        if (!match.game) return;
        AppState.selectGame(match.game, match.index);
        NavigationManager.enterGameDetails();
    }

    function findGameInList(list, title, shortName, savedIndex) {
        if (!list || list.length === 0) return { game: null, index: -1 };
        if (title !== "" && shortName !== "") {
            for (var i = 0; i < list.length; i++) {
                if (list[i] && list[i].title === title && GameUtils.getSystemShortName(list[i]) === shortName) {
                    return { game: list[i], index: i };
                }
            }
        }
        if (title !== "" && savedIndex >= 0 && savedIndex < list.length) {
            if (list[savedIndex] && list[savedIndex].title === title) {
                return { game: list[savedIndex], index: savedIndex };
            }
        }
        if (title !== "") {
            for (var j = 0; j < list.length; j++) {
                if (list[j] && list[j].title === title) {
                    return { game: list[j], index: j };
                }
            }
        }
        if (savedIndex >= 0 && savedIndex < list.length) {
            return { game: list[savedIndex], index: savedIndex };
        }
        return { game: null, index: -1 };
    }

    function getRecentGames() {
        var all = api.allGames.toVarArray();
        var played = all.filter(function (g) { return g.playCount > 0; });
        played.sort(function (a, b) {
            var ta = a.lastPlayed ? a.lastPlayed.getTime() : 0;
            var tb = b.lastPlayed ? b.lastPlayed.getTime() : 0;
            return tb - ta;
        });
        return played.slice(0, 15);
    }

    function getFavoriteGames() {
        var all = api.allGames.toVarArray();
        return all.filter(function (g) { return g.favorite === true; });
    }

    function getLongplayGames() {
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
        return played.slice(0, 15);
    }

    function findCollectionByName(name) {
        if (!name) return null;
        for (var i = 0; i < api.collections.count; i++) {
            var col = api.collections.get(i);
            if (col.name === name) return col;
        }
        return null;
    }

    property Connections _autoSaveConnections: Connections {
        target: AppState
        function onCurrentScreenChanged() { root.save(); }
        function onCurrentSectionChanged() { root.save(); }
        function onCurrentCollectionChanged() { root.save(); }
        function onCurrentCategoryValueChanged() { root.save(); }
        function onCurrentCategorySubValueChanged() { root.save(); }
        function onCurrentGameIndexChanged() { root.save(); }
        function onGalleryListIndexChanged() { root.save(); }
        function onGalleryGridIndexChanged() { root.save(); }
        function onGalleryAssetKeyChanged() { root.save(); }
        function onToolsIndexChanged() { root.save(); }
        function onHomeIndexChanged() { root.save(); }
        function onCalendarSelectedDateChanged() { root.save(); }
        function onCameFromCalendarChanged() { root.save(); }
        function onMetadataActiveCheckIdChanged() { root.save(); }
        function onMetadataActiveScopeChanged() { root.save(); }
    }
}
