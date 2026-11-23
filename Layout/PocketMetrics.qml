// Aethon
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
pragma Singleton
import QtQuick 2.15
import "../App"

QtObject {
    id: root

    readonly property int profile: ResponsiveManager.aspectProfile
    readonly property int density: ResponsiveManager.density

    readonly property bool _isTiny: SettingsManager.activeContext === "tiny4x3"
    readonly property bool _isSmall: SettingsManager.activeContext === "small4x3"

    readonly property real densityScale: {
        switch (root.density) {
            case Enums.densityCompact: return 0.75;
            case Enums.densityLarge: return 1.25;
            default: return 1.0;
        }
    }

    readonly property real fontScale: SettingsManager.currentFontScale

    readonly property real screenFontScale: {
        var _screen = AppState.currentScreen;
        var _section = AppState.currentSection;
        var _collection = AppState.currentCollection;
        var _chosen = AppState.librarySectionChosen;
        var _catVal = AppState.currentCategoryValue;
        var _catSubVal = AppState.currentCategorySubValue;

        if (_screen === Enums.screenGalleryList || _screen === Enums.screenGalleryGrid)
            return SettingsManager.getScreenFontScale("gallery");

        if (_screen === 1) {
            if (!_chosen)
                return SettingsManager.getScreenFontScale("library");

            if (_section === 0)
                return SettingsManager.getScreenFontScale("all");

            if (_section === 3) {
                if (_collection !== null)
                    return SettingsManager.getScreenFontScale("games");
                return SettingsManager.getScreenFontScale("systemNames");
            }

            if (_section === 5) {
                if (_catVal !== "")
                    return SettingsManager.getScreenFontScale("genres");
                return SettingsManager.getScreenFontScale("genreNames");
            }
            if (_section === 6) {
                if (_catVal !== "")
                    return SettingsManager.getScreenFontScale("developers");
                return SettingsManager.getScreenFontScale("developerNames");
            }
            if (_section === 7) {
                if (_catVal !== "")
                    return SettingsManager.getScreenFontScale("publishers");
                return SettingsManager.getScreenFontScale("publisherNames");
            }
            if (_section === 8) {
                if (_catVal === "")
                    return SettingsManager.getScreenFontScale("yearDecades");
                if (_catSubVal === ""
                    && CategoryLibrary.decadeNeedsSplit(_catVal))
                    return SettingsManager.getScreenFontScale("yearNumbers");
                return SettingsManager.getScreenFontScale("years");
            }
            if (_section === 9) {
                if (_catVal !== "")
                    return SettingsManager.getScreenFontScale("tags");
                return SettingsManager.getScreenFontScale("tagNames");
            }
            if (_section === 11) {
                if (_catVal !== "")
                    return SettingsManager.getScreenFontScale("regions");
                return SettingsManager.getScreenFontScale("regionNames");
            }

            return SettingsManager.getScreenFontScale("library");
        }

        if (_screen === 2) {
            if (!_chosen)
                return SettingsManager.getScreenFontScale("memories");

            if (_section === 1) return SettingsManager.getScreenFontScale("recent");
            if (_section === 2) return SettingsManager.getScreenFontScale("favorites");
            if (_section === 4) return SettingsManager.getScreenFontScale("longplays");

            return SettingsManager.getScreenFontScale("memories");
        }

        return SettingsManager.getScreenFontScale(_screen);
    }

    readonly property real artScale: {
        var _screen = AppState.currentScreen;
        if (_screen === 6)
            return SettingsManager.getArtScale("gameDetails");
        return SettingsManager.getArtScale("gameLists");
    }

    readonly property var baseValues: {
        switch (root.profile) {
            case Enums.profileSquare:
                return {
                    margin: 32, headerHeight: 64, footerHeight: 56,
                    cardWidth: 220, cardHeight: 220, titleSize: 22, bodySize: 15,
                    spacing: 16, iconSize: 28, animationDistance: 24
                };
            case Enums.profileClassic:
                return {
                    margin: 36, headerHeight: 68, footerHeight: 60,
                    cardWidth: 260, cardHeight: 200, titleSize: 24, bodySize: 16,
                    spacing: 20, iconSize: 30, animationDistance: 28
                };
            default:
                return {
                    margin: 48, headerHeight: 72, footerHeight: 64,
                    cardWidth: 320, cardHeight: 200, titleSize: 26, bodySize: 17,
                    spacing: 24, iconSize: 32, animationDistance: 32
                };
        }
    }

    readonly property real margin: root._isTiny ? 12 : baseValues.margin * densityScale
    readonly property real headerHeight: root._isTiny ? 30 : baseValues.headerHeight * densityScale
    readonly property real footerHeight: root._isTiny ? 24 : baseValues.footerHeight * densityScale

    readonly property real cardWidth: baseValues.cardWidth * densityScale * artScale
    readonly property real cardHeight: baseValues.cardHeight * densityScale * artScale

    readonly property real titleSize: root._isTiny
    ? Math.round(baseValues.titleSize * densityScale * fontScale * screenFontScale)
    : baseValues.titleSize * densityScale * fontScale * screenFontScale

    readonly property real bodySize: root._isTiny
    ? Math.round(baseValues.bodySize * densityScale * fontScale * screenFontScale)
    : baseValues.bodySize * densityScale * fontScale * screenFontScale

    readonly property real spacing: baseValues.spacing * densityScale
    readonly property real iconSize: baseValues.iconSize * densityScale
    readonly property real animationDistance: baseValues.animationDistance * densityScale

    readonly property real contentTopPad: {
        if (root._isTiny) return 0;
        if (root._isSmall) return Math.round(root.spacing * 0.25);
        return root.spacing;
    }

    readonly property real innerSpacing: {
        if (root._isTiny) return 6;
        if (root._isSmall) return Math.round(root.spacing * 0.5);
        return root.spacing;
    }
}
