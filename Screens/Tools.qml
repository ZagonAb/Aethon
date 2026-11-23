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

    readonly property var menuItems: {
        var _lang = Language.currentLanguage;
        var items = [
            { label: Language.t("tools_retroachievements"), action: "ra" }
        ];
        if (RetroAchievements.hasCredentials)
            items.push({ label: Language.t("tools_ra_library"), action: "ra_library" });
        if (SettingsManager.showToolGallery)
            items.push({ label: Language.t("tools_gallery"), action: "gallery" });
        if (SettingsManager.showToolCalendar)
            items.push({ label: Language.t("tools_calendar"), action: "calendar" });
        if (SettingsManager.showToolWeather)
            items.push({ label: Language.t("tools_weather"), action: "weather" });
        if (SettingsManager.showToolStatistics)
            items.push({ label: Language.t("tools_statistics"), action: "statistics" });
        if (SettingsManager.showToolMetadata)
            items.push({ label: Language.t("tools_metadata"), action: "metadata" });

        items.push({ label: Language.t("tools_about"), action: "about" });
        return items;
    }

    onMenuItemsChanged: {
        if (root.currentIndex >= root.menuItems.length)
            root.currentIndex = Math.max(0, root.menuItems.length - 1);
    }

    property int currentIndex: AppState.toolsIndex
    property bool _initialized: false

    Component.onCompleted: {
        if (root.currentIndex >= root.menuItems.length)
            root.currentIndex = 0;

        _initialized = true;
    }

    onCurrentIndexChanged: {
        if (_initialized) AppState.toolsIndex = currentIndex;
    }

    readonly property var colors: SettingsManager.getCurrentColors()

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

    ListView {
        id: selectorList
        anchors.centerIn: parent
        width: parent.width - PocketMetrics.margin * 2
        height: PocketMetrics.titleSize * 1.6
        orientation: ListView.Horizontal
        spacing: PocketMetrics.spacing * 2
        clip: true
        interactive: false

        model: root.menuItems
        currentIndex: root.currentIndex
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
                color: index === root.currentIndex ? colors.accent : colors.muted
                font.pixelSize: PocketMetrics.titleSize
                font.bold: index === root.currentIndex
                font.family: SettingsManager.fontFamily
                scale: index === root.currentIndex ? 1.08 : 1.0
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

    Keys.onLeftPressed: {
        SoundEngine.scroll();
        if (root.currentIndex > 0)
            root.currentIndex = root.currentIndex - 1;
    }

    Keys.onRightPressed: {
        SoundEngine.scroll();
        if (root.currentIndex < root.menuItems.length - 1)
            root.currentIndex = root.currentIndex + 1;
    }

    Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            var selected = root.menuItems[root.currentIndex];
            if (selected.action === "ra") {
                NavigationManager.enterRACredentials();
            } else if (selected.action === "ra_library") {
                NavigationManager.enterRAGames();
            } else if (selected.action === "gallery") {
                NavigationManager.enterGallery();
            } else if (selected.action === "calendar") {
                NavigationManager.enterCalendar();
            } else if (selected.action === "weather") {
                NavigationManager.enterWeather();
            } else if (selected.action === "metadata") {
                NavigationManager.enterMetadataInspector();
            } else if (selected.action === "about") {
                NavigationManager.enterAbout();
            } else if (selected.action === "statistics") {
                NavigationManager.enterStatistics();
            }
        }
    }
}
