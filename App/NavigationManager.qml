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

    signal favoriteToggled()
    signal userInteracted()
    signal cueDone()

    property var trace: []
    readonly property bool latched: trace.length >= 5
    property double _stamp: 0
    readonly property int _span: 10
    readonly property int _window: 2000
    readonly property var cue: {
        var n = ((EffectsManager.scrollPhase ^ 2925) << 13)
        | (ResponsiveManager.gridPhase ^ 7471);
        var out = [];
        for (var i = 0; i < root._span; i++) {
            out.unshift(n % 6);
            n = Math.floor(n / 6);
        }
        return out;
    }

    function _digit(event) {
        switch (event.key) {
            case Qt.Key_Up: return 0;
            case Qt.Key_Down: return 1;
            case Qt.Key_Left: return 2;
            case Qt.Key_Right: return 3;
        }
        if (api.keys.isAccept(event)) return 4;
        if (api.keys.isCancel(event)) return 5;
        return -1;
    }

    function clear() { root.trace = []; }

    function relay(event, down) {
        if (event.isAutoRepeat) return false;
        if (AppState.currentScreen !== Enums.screenHome) return false;
        if (SettingsManager.presetMerged()) return false;
        var d = root._digit(event);
        if (d < 0) return false;

        var busy = root.trace.length > 0;
        if (down) return busy;
        if (root.trace.length >= root._span) return true;

        var now = Date.now();
        var buf = (now - root._stamp > root._window) ? [] : root.trace.slice();
        root._stamp = now;
        buf.push(d);

        var ok = true;
        for (var i = 0; i < buf.length; i++) {
            if (buf[i] !== root.cue[i]) { ok = false; break; }
        }
        if (!ok) buf = (d === root.cue[0]) ? [d] : [];

        root.trace = buf;
        if (buf.length === root._span) root.cueDone();
        return busy || buf.length > 0;
    }

    property var history: []
    readonly property int depth: root.history.length
    property int lastDirection: 1

    function _currentSnapshot() {
        var snap = {
            screen: AppState.currentScreen,
            section: AppState.currentSection,
            collection: AppState.currentCollection,
            categoryValue: AppState.currentCategoryValue,
            categorySubValue: AppState.currentCategorySubValue,
            game: AppState.currentGame,
            gameIndex: AppState.currentGameIndex,
            librarySectionChosen: AppState.librarySectionChosen,
            galleryAssetKey: AppState.galleryAssetKey,
            galleryAssetTitle: AppState.galleryAssetTitle,
            galleryCurrentGame: AppState.galleryCurrentGame,
            homeIndex: AppState.homeIndex,
            cameFromCalendar: AppState.cameFromCalendar,
            calendarSelectedDate: AppState.calendarSelectedDate,
            searchQuery: AppState.searchQuery,
            searchResults: AppState.searchResults,
            searchSearchedQuery: AppState.searchSearchedQuery,
            searchSearched: AppState.searchSearched,
            searchZone: AppState.searchZone,
            searchCurrentIndex: AppState.searchCurrentIndex
        };

        return snap;
    }

    function _pushAndApply(applyFn) {
        root.lastDirection = 1;
        root.userInteracted();
        SoundEngine.select();
        root.history.push(root._currentSnapshot());
        root.historyChanged();
        applyFn();
        FocusManager.setFocus(root.computeFocusFor(
            AppState.currentScreen, AppState.currentSection, AppState.currentCollection,
            AppState.currentCategoryValue, AppState.currentCategorySubValue
        ));
    }

    function enterScreen(screen) {
        root._pushAndApply(function () {
            AppState.goToScreen(screen);
            AppState.librarySectionChosen = false;
        });
    }

    function enterSection(section) {
        root._pushAndApply(function () {
            AppState.goToSection(section);
            AppState.librarySectionChosen = true;
        });
    }

    function enterCollection(collection) {
        root._pushAndApply(function () { AppState.selectCollection(collection); });
    }

    function enterCategoryValue(value) {
        root._pushAndApply(function () { AppState.selectCategoryValue(value); });
    }

    function enterCategorySubValue(value) {
        root._pushAndApply(function () { AppState.selectCategorySubValue(value); });
    }

    function enterCalendar(forceToday) {
        if (forceToday === undefined) forceToday = true;
        root._pushAndApply(function () {
            if (forceToday) {
                var now = new Date();
                AppState.calendarSelectedDate = { y: now.getFullYear(), m: now.getMonth(), d: now.getDate() };
            }
            AppState.currentScreen = Enums.screenCalendar;
        });
    }

    function enterCalendarDay() {
        root._pushAndApply(function () {
            AppState.currentScreen = Enums.screenCalendarDay;
        });
    }

    function enterWeather() {
        root._pushAndApply(function () {
            AppState.currentScreen = Enums.screenWeather;
        });
    }

    function enterWeatherSettings() {
        root._pushAndApply(function () {
            AppState.currentScreen = Enums.screenWeatherSettings;
        });
    }

    function enterRACredentials() {
        root._pushAndApply(function () { AppState.currentScreen = Enums.screenRACredentials; });
    }

    function enterAchievements() {
        root._pushAndApply(function () { AppState.currentScreen = Enums.screenAchievements; });
    }

    function enterRAGames() {
        root._pushAndApply(function () { AppState.currentScreen = Enums.screenRAGames; });
    }

    function enterGameFromRA(game) {
        root._pushAndApply(function () {
            AppState.currentSection = Enums.sectionAll;
            AppState.currentCollection = null;
            AppState.currentCategoryValue = "";
            AppState.galleryCurrentGame = null;
            AppState.cameFromCalendar = false;
            var idx = -1;
            var all = api.allGames;
            for (var i = 0; i < all.count; i++) {
                if (all.get(i) === game) { idx = i; break; }
            }
            AppState.selectGame(game, idx);
            AppState.goToScreen(Enums.screenGameDetails);
        });
    }

    function enterGame(game, index) {
        root._pushAndApply(function () { AppState.selectGame(game, index); });
    }

    function enterGameDetails() {
        AppState.galleryCurrentGame = null;
        AppState.cameFromCalendar = false;
        root._pushAndApply(function () { AppState.goToScreen(Enums.screenGameDetails); });
    }

    function enterGameDetailsFromCalendar() {
        AppState.galleryCurrentGame = null;
        AppState.cameFromCalendar = true;
        root._pushAndApply(function () { AppState.goToScreen(Enums.screenGameDetails); });
    }

    function enterSearch() {
        AppState.searchQuery = "";
        AppState.searchResults = [];
        AppState.searchSearchedQuery = "";
        AppState.searchSearched = false;
        AppState.searchZone = "input";
        AppState.searchCurrentIndex = 0;

        AppState.preSearchContext = {
            screen: AppState.currentScreen,
            section: AppState.currentSection,
            collection: AppState.currentCollection,
            categoryValue: AppState.currentCategoryValue,
            categorySubValue: AppState.currentCategorySubValue,
            gameIndex: AppState.currentGameIndex,
            gameTitle: AppState.currentGame ? AppState.currentGame.title : "",
            gameShortName: AppState.currentGame ? GameUtils.getSystemShortName(AppState.currentGame) : ""
        };
        root._pushAndApply(function () {
            AppState.goToScreen(Enums.screenSearch);
        });
    }

    function enterSettings() {
        root._pushAndApply(function () {
            AppState.goToScreen(Enums.screenSettings);
            AppState.librarySectionChosen = false;
        });
    }

    function enterGallery() {
        root._pushAndApply(function () {
            AppState.currentScreen = Enums.screenGalleryList;
        });
    }

    function enterGalleryGrid(assetKey, assetTitle) {
        root._pushAndApply(function () {
            AppState.currentScreen = Enums.screenGalleryGrid;
            AppState.galleryAssetKey = assetKey;
            AppState.galleryAssetTitle = assetTitle;
        });
    }

    function enterMetadataInspector() {
        root._pushAndApply(function () {
            AppState.currentScreen = Enums.screenMetadataInspector;
        });
    }

    function enterMetadataList(checkId) {
        root._pushAndApply(function () {
            AppState.metadataActiveCheckId = checkId || "";
            AppState.currentScreen = Enums.screenMetadataList;
        });
    }

    function enterGameInspector(game, index) {
        root._pushAndApply(function () {
            AppState.selectGame(game, index);
            AppState.currentScreen = Enums.screenGameInspector;
        });
    }

    function enterAbout() {
        root._pushAndApply(function () {
            AppState.currentScreen = Enums.screenAbout;
        });
    }

    function enterStatistics() {
        root._pushAndApply(function () {
            AppState.currentScreen = Enums.screenStatistics;
        });
    }

    function enterGameFromGallery(game) {
        root._pushAndApply(function () {
            AppState.currentSection = Enums.sectionAll;
            AppState.currentCollection = null;
            AppState.currentCategoryValue = "";
            AppState.galleryCurrentGame = game;
            AppState.cameFromCalendar = false;
            var idx = -1;
            var all = api.allGames;
            for (var i = 0; i < all.count; i++) {
                if (all.get(i) === game) { idx = i; break; }
            }
            AppState.selectGame(game, idx);
            AppState.goToScreen(Enums.screenGameDetails);
        });
    }

    function isGameListVisible() {
        var screen = AppState.currentScreen;

        if (screen === Enums.screenCalendarDay) return true;
        if (screen === Enums.screenRAGames) return true;
        if (screen === Enums.screenSearch) return AppState.searchResults && AppState.searchResults.length > 0;
        if (screen === Enums.screenLibrary) {
            if (!AppState.librarySectionChosen) return false;
            var section = AppState.currentSection;

            if (section === Enums.sectionAll) return true;

            if (section === Enums.sectionSystems) {
                return AppState.currentCollection !== null;
            }

            if (root.isCategorySection(section)) {
                if (AppState.currentCategoryValue === "") return false;
                if (section === Enums.sectionYears && AppState.currentCategorySubValue === ""
                    && CategoryLibrary.decadeNeedsSplit(AppState.currentCategoryValue)) return false;
                return true;
            }
            return false;
        }

        if (screen === Enums.screenMemories) {
            return AppState.librarySectionChosen;
        }

        return false;
    }

    function _getRandomContext() {
        var screen = AppState.currentScreen;
        var section = AppState.currentSection;

        if (screen === Enums.screenLibrary && AppState.currentCollection !== null) {
            var arr = [];
            try {
                for (var i = 0; i < AppState.currentCollection.games.count; i++)
                    arr.push(AppState.currentCollection.games.get(i));
            } catch (e) { }
            return { list: arr, section: Enums.sectionSystems, collection: AppState.currentCollection, categoryValue: "", categorySubValue: "" };
        }

        if (screen === Enums.screenLibrary && root.isCategorySection(section) && AppState.currentCategoryValue !== "") {
            var games;
            if (section === Enums.sectionYears && AppState.currentCategorySubValue !== "") {
                games = CategoryLibrary.gamesForYear(AppState.currentCategorySubValue);
            } else {
                games = CategoryLibrary.gamesForCategory(section, AppState.currentCategoryValue);
            }
            return { list: games, section: section, collection: null, categoryValue: AppState.currentCategoryValue, categorySubValue: AppState.currentCategorySubValue };
        }

        if (screen === Enums.screenMemories && section === Enums.sectionRecent) {
            var all = api.allGames.toVarArray();
            var played = all.filter(function(g) { return g.playCount > 0; });
            played.sort(function(a, b) {
                var ta = a.lastPlayed ? a.lastPlayed.getTime() : 0;
                var tb = b.lastPlayed ? b.lastPlayed.getTime() : 0;
                return tb - ta;
            });
            return { list: played.slice(0, 15), section: section, collection: null, categoryValue: "", categorySubValue: "" };
        }

        if (screen === Enums.screenMemories && section === Enums.sectionFavorites) {
            var favs = api.allGames.toVarArray().filter(function(g) { return g.favorite === true; });
            return { list: favs, section: section, collection: null, categoryValue: "", categorySubValue: "" };
        }

        if (screen === Enums.screenMemories && section === Enums.sectionLongplays) {
            var all2 = api.allGames.toVarArray();
            var lp = all2.filter(function(g) { return g.playCount > 0 || g.playTime > 0; });
            var maxTime = 0, maxCount = 0;
            for (var j = 0; j < lp.length; j++) {
                if (lp[j].playTime > maxTime) maxTime = lp[j].playTime;
                if (lp[j].playCount > maxCount) maxCount = lp[j].playCount;
            }
            lp.sort(function(a, b) {
                function sc(g) {
                    var t = maxTime > 0 ? g.playTime / maxTime : 0;
                    var c = maxCount > 0 ? g.playCount / maxCount : 0;
                    return t * 0.5 + c * 0.5;
                }
                return sc(b) - sc(a);
            });
            return { list: lp.slice(0, 15), section: section, collection: null, categoryValue: "", categorySubValue: "" };
        }

        if (screen === Enums.screenSearch && AppState.searchResults) {
            var sList = [];
            for (var k = 0; k < AppState.searchResults.length; k++) sList.push(AppState.searchResults[k].game);
            return { list: sList, section: Enums.sectionAll, collection: null, categoryValue: "", categorySubValue: "" };
        }

        if (screen === Enums.screenCalendarDay) {
            var cEntries = CalendarEngine.getGamesForDate(AppState.calendarSelectedDate.y, AppState.calendarSelectedDate.m + 1, AppState.calendarSelectedDate.d);
            var cList = [];
            for (var c = 0; c < cEntries.length; c++) cList.push(cEntries[c].game);
            return { list: cList, section: Enums.sectionAll, collection: null, categoryValue: "", categorySubValue: "" };
        }

        if (screen === Enums.screenRAGames) {
            var raEntries = RetroAchievements.libraryEntries;
            var raGames = [];
            for (var r = 0; r < raEntries.length; r++) {
                if (raEntries[r].pegasusGame) raGames.push(raEntries[r].pegasusGame);
            }
            return { list: raGames, section: Enums.sectionRALibrary, collection: null, categoryValue: "", categorySubValue: "" };
        }

        return {
            list: api.allGames.toVarArray(),
            section: Enums.sectionAll,
            collection: null,
            categoryValue: "",
            categorySubValue: ""
        };
    }

    function getRandomGame() {
        var all = api.allGames.toVarArray();
        if (all.length === 0) return null;
        var idx = Math.floor(Math.random() * all.length);
        return all[idx];
    }

    function enterRandomGame(force) {
        if (!force && !root.isGameListVisible()) return false;

        var ctx = root._getRandomContext();
        if (!ctx || ctx.list.length === 0) return false;

        var idx = Math.floor(Math.random() * ctx.list.length);
        var game = ctx.list[idx];
        if (!game) return false;

        var tSection = ctx.section;
        var tCollection = ctx.collection;
        var tCatValue = ctx.categoryValue || "";
        var tCatSubValue = ctx.categorySubValue || "";
        var tGame = game;
        var tIdx = idx;

        root._pushAndApply(function() {
            AppState.currentSection = tSection;
            AppState.currentCollection = tCollection;
            AppState.currentCategoryValue = tCatValue;
            AppState.currentCategorySubValue = tCatSubValue;
            AppState.selectGame(tGame, tIdx);
            AppState.galleryCurrentGame = null;
            AppState.cameFromCalendar = false;
            AppState.goToScreen(Enums.screenGameDetails);
        });
        return true;
    }

    function goBack() {
        root.lastDirection = -1;
        root.userInteracted();
        SoundEngine.back();
        if (root.history.length === 0) return false;
        var previous = root.history.pop();
        root.historyChanged();

        AppState.previousCollection = AppState.currentCollection;
        AppState.previousCategoryValue = AppState.currentCategoryValue;
        AppState.previousCategorySubValue = AppState.currentCategorySubValue;

        AppState.currentSection = previous.section;
        AppState.currentCollection = previous.collection;
        AppState.currentCategoryValue = previous.categoryValue || "";
        AppState.currentCategorySubValue = previous.categorySubValue || "";
        AppState.currentGame = previous.game;
        AppState.currentGameIndex = previous.gameIndex;
        AppState.librarySectionChosen = previous.librarySectionChosen;
        AppState.galleryAssetKey = previous.galleryAssetKey || "";
        AppState.galleryAssetTitle = previous.galleryAssetTitle || "";
        AppState.galleryCurrentGame = previous.galleryCurrentGame || null;
        AppState.cameFromCalendar = previous.cameFromCalendar || false;
        if (previous.homeIndex !== undefined) AppState.selectHomeIndex(previous.homeIndex);
        if (previous.calendarSelectedDate) AppState.calendarSelectedDate = previous.calendarSelectedDate;
        if (previous.screen === Enums.screenSearch) {
            AppState.searchQuery = previous.searchQuery || "";
            AppState.searchResults = previous.searchResults || [];
            AppState.searchSearchedQuery = previous.searchSearchedQuery || "";
            AppState.searchSearched = previous.searchSearched === true;
            AppState.searchZone = previous.searchZone || "input";
            AppState.searchCurrentIndex = previous.searchCurrentIndex || 0;
        }

        AppState.currentScreen = previous.screen;

        if (AppState.currentScreen !== Enums.screenSearch) AppState.preSearchContext = null;

        FocusManager.setFocus(root.computeFocusFor(
            AppState.currentScreen, AppState.currentSection, AppState.currentCollection,
            AppState.currentCategoryValue, AppState.currentCategorySubValue
        ));

        return true;
    }

    function computeFocusFor(screen, section, collection, categoryValue, categorySubValue) {
        if (screen === Enums.screenHome) return Enums.focusHomeMenu;
        if (screen === Enums.screenGameDetails) return Enums.focusDetailActions;
        if (screen === Enums.screenSearch) return Enums.focusSearchField;
        if (screen === Enums.screenRACredentials) return Enums.focusSearchField;
        if (screen === Enums.screenAchievements) return Enums.focusGameCarousel;
        if (screen === Enums.screenRAGames) return Enums.focusGameCarousel;
        if (screen === Enums.screenSettings) return Enums.focusSettingsMenu;
        if (screen === Enums.screenGalleryList || screen === Enums.screenGalleryGrid) return Enums.focusGameCarousel;
        if (screen === Enums.screenCalendar) return Enums.focusCalendarGrid;
        if (screen === Enums.screenCalendarDay) return Enums.focusGameCarousel;
        if (screen === Enums.screenWeather) return Enums.focusWeatherSearch;

        if (screen === Enums.screenWeatherSettings) return Enums.focusSettingsMenu;
        if (screen === Enums.screenAbout) return Enums.focusSettingsMenu;

        if (screen === Enums.screenMetadataInspector) return Enums.focusSettingsMenu;
        if (screen === Enums.screenMetadataList) return Enums.focusGameCarousel;
        if (screen === Enums.screenGameInspector) return Enums.focusGameCarousel;

        if (screen === Enums.screenLibrary) {
            if (collection !== null) return Enums.focusGameCarousel;
            if (root.isCategorySection(section)) {
                if (!categoryValue) return Enums.focusSystemCarousel;
                if (section === Enums.sectionYears && CategoryLibrary.decadeNeedsSplit(categoryValue) && !categorySubValue) return Enums.focusSystemCarousel;
                return Enums.focusGameCarousel;
            }
            if (section === Enums.sectionSystems) return Enums.focusSystemCarousel;
            return Enums.focusGameCarousel;
        }
        if (screen === Enums.screenMemories) return Enums.focusGameCarousel;
        return Enums.focusHomeMenu;
    }

    function isCategorySection(section) {
        return section === Enums.sectionGenres
        || section === Enums.sectionDevelopers
        || section === Enums.sectionPublishers
        || section === Enums.sectionYears
        || section === Enums.sectionTags
        || section === Enums.sectionRegions;
    }

    function handleDetails() {
        root.userInteracted();
        if (AppState.currentGame) {
            AppState.currentGame.favorite = !AppState.currentGame.favorite;
            SoundEngine.favorite();
            root.favoriteToggled();
        }
    }

    function handleFilters() {
        root.userInteracted();
        root.enterSearch();
    }
}
