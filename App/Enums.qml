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

    readonly property int screenHome: 0
    readonly property int screenLibrary: 1
    readonly property int screenMemories: 2
    readonly property int screenTools: 3
    readonly property int screenSettings: 4
    readonly property int screenSearch: 5
    readonly property int screenGameDetails: 6
    readonly property int screenRACredentials: 7
    readonly property int screenAchievements: 8
    readonly property int screenRAGames: 9
    readonly property int screenGalleryList: 10
    readonly property int screenGalleryGrid: 11
    readonly property int screenCalendar: 12
    readonly property int screenCalendarDay: 13
    readonly property int screenWeather: 14
    readonly property int screenWeatherSettings: 15
    readonly property int screenMetadataInspector: 16
    readonly property int screenMetadataList: 17
    readonly property int screenGameInspector: 18
    readonly property int screenAbout: 19
    readonly property int screenStatistics: 20
    readonly property int sectionAll: 0
    readonly property int sectionRecent: 1
    readonly property int sectionFavorites: 2
    readonly property int sectionSystems: 3
    readonly property int sectionLongplays: 4
    readonly property int sectionGenres: 5
    readonly property int sectionDevelopers: 6
    readonly property int sectionPublishers: 7
    readonly property int sectionYears: 8
    readonly property int sectionTags: 9
    readonly property int sectionRALibrary: 10
    readonly property int sectionRegions: 11
    readonly property int focusHomeMenu: 0
    readonly property int focusLibraryMenu: 1
    readonly property int focusGameCarousel: 2
    readonly property int focusSystemCarousel: 3
    readonly property int focusDetailActions: 4
    readonly property int focusSearchField: 5
    readonly property int focusSettingsMenu: 6
    readonly property int focusCalendarGrid: 7
    readonly property int focusWeatherSearch: 8
    readonly property int profileSquare: 0
    readonly property int profileClassic: 1
    readonly property int profileWide: 2
    readonly property int densityCompact: 0
    readonly property int densityNormal: 1
    readonly property int densityLarge: 2

    function screenName(value) {
        switch (value) {
            case root.screenHome: return Language.t("nav_home");
            case root.screenLibrary: return Language.t("nav_library");
            case root.screenMemories: return Language.t("nav_memories");
            case root.screenTools: return Language.t("nav_tools");
            case root.screenSettings: return Language.t("nav_settings");
            case root.screenSearch: return Language.t("nav_search");
            case root.screenGameDetails: return Language.t("nav_game_details");
            case root.screenRACredentials: return Language.t("nav_ra_credentials");
            case root.screenAchievements: return Language.t("nav_achievements");
            case root.screenRAGames: return Language.t("nav_ra_games");
            case root.screenGalleryList: return "GALLERY_LIST";
            case root.screenGalleryGrid: return "GALLERY_GRID";
            case root.screenCalendar: return "CALENDAR";
            case root.screenCalendarDay: return "CALENDAR_DAY";
            case root.screenWeather: return "WEATHER";
            case root.screenWeatherSettings: return "WEATHER_SETTINGS";
            case root.screenMetadataList: return "METADATA_LIST";
            case root.screenGameInspector: return "GAME_INSPECTOR";
            case root.screenAbout: return "ABOUT";
            case root.screenStatistics: return "STATISTICS";
            default: return "UNKNOWN(" + value + ")";
        }
    }

    function sectionName(value) {
        switch (value) {
            case root.sectionAll: return Language.t("section_all");
            case root.sectionRecent: return Language.t("section_recent");
            case root.sectionFavorites: return Language.t("section_favorites");
            case root.sectionSystems: return Language.t("section_systems");
            case root.sectionLongplays: return Language.t("section_longplays");
            case root.sectionGenres: return Language.t("section_genres");
            case root.sectionDevelopers: return Language.t("section_developers");
            case root.sectionPublishers: return Language.t("section_publishers");
            case root.sectionYears: return Language.t("section_years");
            case root.sectionTags: return Language.t("section_tags");
            case root.sectionRALibrary: return "RA_LIBRARY";
            case root.sectionRegions: return Language.t("section_regions");
            default: return "UNKNOWN(" + value + ")";
        }
    }

    function profileName(value) {
        switch (value) {
            case root.profileSquare: return "SQUARE";
            case root.profileClassic: return "CLASSIC";
            case root.profileWide: return "WIDE";
            default: return "UNKNOWN(" + value + ")";
        }
    }

    function densityName(value) {
        switch (value) {
            case root.densityCompact: return "COMPACT";
            case root.densityNormal: return "NORMAL";
            case root.densityLarge: return "LARGE";
            default: return "UNKNOWN(" + value + ")";
        }
    }

    function focusName(value) {
        switch (value) {
            case root.focusHomeMenu: return "HOME_MENU";
            case root.focusLibraryMenu: return "LIBRARY_MENU";
            case root.focusGameCarousel: return "GAME_CAROUSEL";
            case root.focusSystemCarousel: return "SYSTEM_CAROUSEL";
            case root.focusDetailActions: return "DETAIL_ACTIONS";
            case root.focusSearchField: return "SEARCH_FIELD";
            case root.focusSettingsMenu: return "SETTINGS_MENU";
            case root.focusCalendarGrid: return "CALENDAR_GRID";
            case root.focusWeatherSearch: return "WEATHER_SEARCH";
            default: return "UNKNOWN(" + value + ")";
        }
    }
}
