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

    property int currentScreen: Enums.screenHome
    property int currentSection: Enums.sectionAll
    property var currentCollection: null
    property var currentGame: null
    property int currentGameIndex: -1
    property string currentCategoryValue: ""
    property string currentCategorySubValue: ""
    property bool librarySectionChosen: false
    property int homeIndex: 0
    property bool homeContinueOverflow: false
    property bool homeRandomOverflow: false
    property var calendarSelectedDate: ({ y: 0, m: 0, d: 0 })
    property bool cameFromCalendar: false
    property string metadataActiveCheckId: ""
    property string metadataActiveScope: "all"
    property bool isMediaPlaying: false
    property string galleryAssetKey: ""
    property string galleryAssetTitle: ""
    property int galleryListIndex: 0
    property int galleryGridIndex: 0
    property var galleryCurrentGame: null
    property int toolsIndex: 0
    property int previousScreen: Enums.screenHome
    property int previousSection: Enums.sectionAll
    property var previousCollection: null
    property string previousCategoryValue: ""
    property string previousCategorySubValue: ""
    property int previousGameIndex: -1
    property var preSearchContext: null
    property string searchQuery: ""
    property var searchResults: []
    property string searchSearchedQuery: ""
    property bool searchSearched: false
    property string searchZone: "input"
    property int searchCurrentIndex: 0

    function goToScreen(screen) {
        if (screen === root.currentScreen) return;
        root.previousScreen = root.currentScreen;
        root.currentScreen = screen;
    }

    function goToSection(section) {
        if (section === root.currentSection) return;
        root.previousSection = root.currentSection;
        root.currentSection = section;
    }

    function selectCollection(collection, restoreIndex) {
        root.previousCollection = root.currentCollection;
        if (restoreIndex !== undefined && restoreIndex >= 0) {
            root.currentGameIndex = restoreIndex;
        } else {
            root.previousGameIndex = root.currentGameIndex;
            root.currentGameIndex = -1;
            root.currentGame = null;
        }
        root.currentCollection = collection;
    }

    function clearCollection() {
        root.previousCollection = root.currentCollection;
        root.previousGameIndex = root.currentGameIndex;
        root.currentGameIndex = -1;
        root.currentGame = null;
        root.currentCollection = null;
    }

    function selectCategoryValue(value) {
        root.previousCategoryValue = root.currentCategoryValue;
        root.previousCategorySubValue = root.currentCategorySubValue;
        root.previousGameIndex = root.currentGameIndex;
        root.currentGameIndex = -1;
        root.currentGame = null;
        root.currentCategoryValue = value;
        root.currentCategorySubValue = "";
    }

    function clearCategoryValue() {
        root.previousCategoryValue = root.currentCategoryValue;
        root.previousCategorySubValue = root.currentCategorySubValue;
        root.previousGameIndex = root.currentGameIndex;
        root.currentGameIndex = -1;
        root.currentGame = null;
        root.currentCategoryValue = "";
        root.currentCategorySubValue = "";
    }

    function selectCategorySubValue(value) {
        root.previousCategorySubValue = root.currentCategorySubValue;
        root.previousGameIndex = root.currentGameIndex;
        root.currentGameIndex = -1;
        root.currentGame = null;
        root.currentCategorySubValue = value;
    }

    function clearCategorySubValue() {
        root.previousCategorySubValue = root.currentCategorySubValue;
        root.previousGameIndex = root.currentGameIndex;
        root.currentGameIndex = -1;
        root.currentGame = null;
        root.currentCategorySubValue = "";
    }

    function selectGame(game, index) {
        root.previousGameIndex = root.currentGameIndex;
        root.currentGame = game;
        root.currentGameIndex = index;
    }

    function selectHomeIndex(idx) {
        if (root.homeIndex === idx) return;
        root.homeIndex = idx;
    }

    function reset() {
        root.currentScreen = Enums.screenHome;
        root.currentSection = Enums.sectionAll;
        root.currentCollection = null;
        root.currentCategoryValue = "";
        root.currentCategorySubValue = "";
        root.currentGame = null;
        root.currentGameIndex = -1;
        root.librarySectionChosen = false;
        root.previousScreen = Enums.screenHome;
        root.previousSection = Enums.sectionAll;
        root.previousCollection = null;
        root.previousCategoryValue = "";
        root.previousCategorySubValue = "";
        root.previousGameIndex = -1;
        root.preSearchContext = null;
        root.calendarSelectedDate = ({ y: 0, m: 0, d: 0 });
        root.cameFromCalendar = false;
        root.metadataActiveCheckId = "";
        root.metadataActiveScope = "all";
        root.isMediaPlaying = false;
        root.galleryAssetKey = "";
        root.galleryAssetTitle = "";
        root.galleryListIndex = 0;
        root.galleryGridIndex = 0;
        root.galleryCurrentGame = null;
        root.toolsIndex = 0;
        root.homeIndex = 0;
        root.homeContinueOverflow = false;
        root.homeRandomOverflow = false;
        root.searchQuery = "";
        root.searchResults = [];
        root.searchSearchedQuery = "";
        root.searchSearched = false;
        root.searchZone = "input";
        root.searchCurrentIndex = 0;
    }

    function snapshot() {
        return {
            screen: root.currentScreen,
            section: root.currentSection,
            collectionName: root.currentCollection ? root.currentCollection.name : "",
            categoryValue: root.currentCategoryValue,
            categorySubValue: root.currentCategorySubValue,
            gameIndex: root.currentGameIndex,
            gameTitle: root.currentGame ? root.currentGame.title : "",
            gameCollectionShortName: root.currentGame ? GameUtils.getSystemShortName(root.currentGame) : "",
            calendarSelectedDate: root.calendarSelectedDate,
            cameFromCalendar: root.cameFromCalendar,
            metadataActiveCheckId: root.metadataActiveCheckId,
            metadataActiveScope: MetadataEngine.activeScope,
            galleryAssetKey: root.galleryAssetKey,
            galleryAssetTitle: root.galleryAssetTitle,
            galleryListIndex: root.galleryListIndex,
            galleryGridIndex: root.galleryGridIndex,
            toolsIndex: root.toolsIndex,
            homeIndex: root.homeIndex,
            cameFromGallery: !!root.galleryCurrentGame
        };
    }
}
