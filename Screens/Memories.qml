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

FocusScope {
    id: root
    anchors.fill: parent
    focus: true

    readonly property var sections: {
        var _lang = Language.currentLanguage;
        return [
            { label: Language.t("section_recent"), value: Enums.sectionRecent },
            { label: Language.t("section_favorites"), value: Enums.sectionFavorites },
            { label: Language.t("section_longplays"), value: Enums.sectionLongplays }
        ];
    }

    property int highlightIndex: 0
    readonly property bool showingSelector: !AppState.librarySectionChosen
    readonly property var colors: SettingsManager.getCurrentColors()

    Component.onCompleted: {
        for (var i = 0; i < root.sections.length; i++) {
            if (root.sections[i].value === AppState.currentSection) {
                root.highlightIndex = i;
                break;
            }
        }
    }

    onShowingSelectorChanged: {
        if (root.showingSelector)
            root.forceActiveFocus();
    }

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

    ListView {
        id: selectorList
        anchors.centerIn: parent
        width: parent.width - PocketMetrics.margin * 2
        height: PocketMetrics.titleSize * 1.6
        visible: root.showingSelector
        orientation: ListView.Horizontal
        spacing: PocketMetrics.spacing * 2
        clip: true
        interactive: false

        model: root.sections
        currentIndex: root.highlightIndex
        highlightRangeMode: ListView.StrictlyEnforceRange

        preferredHighlightBegin: selectorList.currentItem
        ? (selectorList.width - selectorList.currentItem.width) / 2
        : selectorList.width / 2
        preferredHighlightEnd: selectorList.currentItem
        ? (selectorList.width + selectorList.currentItem.width) / 2
        : selectorList.width / 2

        highlightMoveDuration: EffectsManager.dur(200)

        delegate: Item {
            width: label.implicitWidth
            height: selectorList.height

            Text {
                id: label
                anchors.centerIn: parent
                text: modelData.label
                color: index === root.highlightIndex ? colors.accent : colors.muted
                font.pixelSize: PocketMetrics.titleSize
                font.bold: index === root.highlightIndex
                font.family: SettingsManager.fontFamily
                scale: index === root.highlightIndex ? 1.08 : 1.0
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

    Loader {
        id: sectionLoader
        anchors.fill: parent
        active: !root.showingSelector

        transform: Translate { id: sectionSlide; x: 0 }

        source: {
            if (root.showingSelector)
                return "";

            if (AppState.currentSection === Enums.sectionRecent)
                return "RecentGames.qml";
            if (AppState.currentSection === Enums.sectionFavorites)
                return "FavoriteGames.qml";
            if (AppState.currentSection === Enums.sectionLongplays)
                return "LongPlays.qml";

            return "Placeholder.qml";
        }

        onLoaded: {
            if (item)
                item.forceActiveFocus();
            sectionSlideIn.from = NavigationManager.lastDirection > 0
            ? PocketMetrics.animationDistance
            : -PocketMetrics.animationDistance;
            sectionSlideIn.restart();
            sectionFadeIn.restart();
        }
    }

    NumberAnimation {
        id: sectionSlideIn
        target: sectionSlide
        property: "x"
        to: 0
        duration: EffectsManager.dur(200)
        easing.type: Easing.OutQuad
    }

    NumberAnimation {
        id: sectionFadeIn
        target: sectionLoader
        property: "opacity"
        from: 0
        to: 1
        duration: EffectsManager.dur(160)
        easing.type: Easing.OutQuad
    }

    Keys.onLeftPressed: {
        SoundEngine.scroll();
        if (root.showingSelector)
            root.highlightIndex = Math.max(0, root.highlightIndex - 1);
    }

    Keys.onRightPressed: {
        SoundEngine.scroll();
        if (root.showingSelector)
            root.highlightIndex = Math.min(root.sections.length - 1, root.highlightIndex + 1);
    }

    Keys.onPressed: {
        if (root.showingSelector && api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            NavigationManager.enterSection(root.sections[root.highlightIndex].value);
        }
    }
}
