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

    readonly property var colors: SettingsManager.getCurrentColors()
    readonly property bool isCompact: height <= 650
    readonly property bool isSquare: ResponsiveManager.aspectProfile === Enums.profileSquare
    readonly property bool isSmallScale: root.isCompact || root.isSquare
    readonly property bool isWide: !root.isCompact && !root.isSquare
    readonly property bool vkEnabled: SettingsManager.showVirtualKeyboard
    readonly property real menuWidth: {
        if (root.isWide) return Math.min(parent.width - PocketMetrics.margin * 4, 1000);
        if (root.isSmallScale) return Math.min(parent.width - PocketMetrics.margin * 2, 700) * 0.9;
        return Math.min(parent.width - PocketMetrics.margin * 2, 600);
    }

    property int currentIndex: 0
    property bool showSearch: false
    property bool showVK: false
    property bool vkFocused: false
    readonly property int menuCount: 8

    function openSearch() {
        searchInput.text = "";
        WeatherEngine.resetSearch();
        root.showSearch = true;
        root.showVK = root.vkEnabled;
        root.vkFocused = false;
        searchInput.forceActiveFocus();
    }

    function returnFocusToMenu() {
        root.showVK = false;
        root.vkFocused = false;
        searchInput.focus = false;
        resultsList.focus = false;
        root.forceActiveFocus();
    }

    function closeSearch() {
        searchDebounce.stop();
        WeatherEngine.resetSearch();
        searchInput.text = "";
        root.showSearch = false;
        root.showVK = false;
        root.vkFocused = false;
        root.returnFocusToMenu();
    }

    function confirmSelection() {
        if (resultsList.currentIndex < 0) return;
        searchDebounce.stop();
        WeatherEngine.selectLocation(resultsList.currentIndex);
        root.showSearch = false;
        root.showVK = false;
        root.vkFocused = false;
        searchInput.text = "";
        root.returnFocusToMenu();
    }

    function isCancelKey(event) {
        if (event.isAutoRepeat) return false;
        return event.key === Qt.Key_Escape || api.keys.isCancel(event);
    }

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

    Item {
        id: pageHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: PocketMetrics.headerHeight

        Text {
            anchors.left: parent.left
            anchors.leftMargin: PocketMetrics.margin
            anchors.verticalCenter: parent.verticalCenter
            text: WeatherLanguage.t("weather_settings_title")
            color: colors.fg
            font.pixelSize: root.isSmallScale ? PocketMetrics.titleSize * 0.6 : PocketMetrics.titleSize * 0.864
            font.bold: true
            font.family: SettingsManager.fontFamily
        }
    }

    function labelFor(i) {
        switch (i) {
            case 0: return WeatherLanguage.t("weather_setting_city");
            case 1: return WeatherLanguage.t("weather_setting_unit");
            case 2: return WeatherLanguage.t("weather_setting_wind");
            case 3: return WeatherLanguage.t("weather_setting_days");
            case 4: return WeatherLanguage.t("weather_setting_time");
            case 5: return WeatherLanguage.t("weather_setting_details");
            case 6: return WeatherLanguage.t("weather_setting_air");
            default: return WeatherLanguage.t("weather_setting_language");
        }
    }

    function onOff(v) {
        return v ? WeatherLanguage.t("weather_option_on") : WeatherLanguage.t("weather_option_off");
    }

    function valueFor(i) {
        switch (i) {
            case 0:
                if (!WeatherEngine.currentLocation) return "-";
                var n = WeatherEngine.savedLocations.length;
            return WeatherEngine.currentLocation.name + (n > 1 ? "  (" + (WeatherEngine.activeIndex + 1) + "/" + n + ")" : "");
            case 1: return WeatherEngine.tempUnit === "celsius" ? WeatherLanguage.t("weather_setting_unit_c") : WeatherLanguage.t("weather_setting_unit_f");
            case 2: return WeatherEngine.windUnitText;
            case 3: return WeatherEngine.forecastDays + " " + WeatherLanguage.t("weather_days");
            case 4: return WeatherEngine.timeFormat === "12h" ? "12 h" : "24 h";
            case 5: return root.onOff(WeatherEngine.showDetails);
            case 6: return root.onOff(WeatherEngine.showAirQuality);
            default: return WeatherLanguage.languageLabel(WeatherLanguage.selected);
        }
    }

    function adjustable(i) {
        return i > 0 || WeatherEngine.savedLocations.length > 1;
    }

    function adjust(step) {
        switch (root.currentIndex) {
            case 0: WeatherEngine.cycleLocation(step); break;
            case 1: WeatherEngine.setUnit(step < 0 ? "celsius" : "fahrenheit"); break;
            case 2: WeatherEngine.cycleWindUnit(step); break;
            case 3: WeatherEngine.cycleForecastDays(step); break;
            case 4: WeatherEngine.setTimeFormat(step > 0 ? "12h" : "24h"); break;
            case 5: WeatherEngine.setShowDetails(step > 0); break;
            case 6: WeatherEngine.setShowAirQuality(step > 0); break;
            case 7: WeatherLanguage.cycle(step); break;
        }
    }

    function activate() {
        switch (root.currentIndex) {
            case 0: root.openSearch(); break;
            case 1: WeatherEngine.setUnit(WeatherEngine.tempUnit === "celsius" ? "fahrenheit" : "celsius"); break;
            case 4: WeatherEngine.setTimeFormat(WeatherEngine.timeFormat === "12h" ? "24h" : "12h"); break;
            case 5: WeatherEngine.setShowDetails(!WeatherEngine.showDetails); break;
            case 6: WeatherEngine.setShowAirQuality(!WeatherEngine.showAirQuality); break;
            default: root.adjust(1); break;
        }
    }

    Item {
        id: menuContainer
        width: root.menuWidth
        anchors.top: pageHeader.bottom
        anchors.topMargin: root.isSmallScale ? PocketMetrics.spacing * 0.5 : PocketMetrics.margin * 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.isSmallScale ? PocketMetrics.bodySize * 2.5 : PocketMetrics.margin * 2 + PocketMetrics.bodySize * 2
        anchors.horizontalCenter: parent.horizontalCenter
        visible: !root.showSearch

        ListView {
            id: menuList
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width - 12
            spacing: root.isSmallScale ? PocketMetrics.spacing * 0.6 : PocketMetrics.spacing * 1.5
            clip: true
            interactive: false
            model: root.menuCount
            currentIndex: root.currentIndex
            highlightMoveDuration: EffectsManager.dur(150)
            onCurrentIndexChanged: {
                menuList.positionViewAtIndex(currentIndex, ListView.Contain);
            }

            delegate: Rectangle {
                id: row
                readonly property bool selected: root.currentIndex === index
                width: ListView.view.width
                height: root.isSmallScale ? PocketMetrics.bodySize * 2.5 : PocketMetrics.bodySize * 3
                radius: EffectsManager.r(6)
                color: selected ? colors.card : "transparent"
                border.color: selected ? colors.accent : "transparent"
                border.width: 2

                Text {
                    id: rowLabel
                    anchors.left: parent.left
                    anchors.leftMargin: root.isSmallScale ? PocketMetrics.spacing * 0.5 : PocketMetrics.spacing * 1.5
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.labelFor(index)
                    color: row.selected ? colors.fg : colors.muted
                    font.pixelSize: root.isSmallScale ? PocketMetrics.bodySize * 0.85 : PocketMetrics.bodySize * 1.1
                    font.bold: row.selected
                    font.family: SettingsManager.fontFamily
                }

                MarqueeText {
                    anchors.right: parent.right
                    anchors.rightMargin: root.isSmallScale ? PocketMetrics.spacing * 0.5 : PocketMetrics.spacing * 1.5
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(0, Math.min(textWidth, row.width - rowLabel.implicitWidth - PocketMetrics.spacing * 3))
                    text: (row.selected && root.adjustable(index)) ? "<  " + root.valueFor(index) + "  >" : root.valueFor(index)
                    color: colors.accent
                    pixelSize: root.isSmallScale ? PocketMetrics.bodySize * 0.85 : PocketMetrics.bodySize * 1.1
                    active: row.selected && !root.showSearch
                }
            }
        }

        Rectangle {
            id: scrollTrack
            anchors.top: menuList.top
            anchors.right: parent.right
            width: 6
            height: menuList.height
            radius: width / 2
            color: colors.card
            opacity: 0.4
            visible: menuList.contentHeight > menuList.height

            Rectangle {
                id: scrollThumb
                width: parent.width
                radius: width / 2
                color: colors.accent
                opacity: 0.75
                height: Math.max(20, scrollTrack.height * (menuList.height / Math.max(1, menuList.contentHeight)))
                y: (scrollTrack.height - height) * (menuList.contentY / Math.max(1, menuList.contentHeight - menuList.height))

                Behavior on y {
                    enabled: EffectsManager.animationsEnabled
                    NumberAnimation { duration: EffectsManager.dur(150); easing.type: Easing.OutQuad }
                }
            }
        }
    }

    Item {
        id: searchOverlay
        anchors.fill: parent
        visible: root.showSearch

        Rectangle {
            anchors.fill: parent
            color: colors.bg
            opacity: 0.95
        }

        Column {
            anchors.top: parent.top
            anchors.topMargin: root.isSmallScale ? PocketMetrics.headerHeight + PocketMetrics.spacing * 0.5 : PocketMetrics.headerHeight + PocketMetrics.margin
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.menuWidth
            spacing: root.isSmallScale ? PocketMetrics.spacing * 0.5 : PocketMetrics.spacing

            Text {
                text: WeatherLanguage.t("weather_search_placeholder")
                color: colors.muted
                font.pixelSize: root.isSmallScale ? PocketMetrics.bodySize * 0.85 : PocketMetrics.bodySize
                font.family: SettingsManager.fontFamily
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Rectangle {
                width: parent.width
                height: root.isSmallScale ? PocketMetrics.bodySize * 2.0 : PocketMetrics.bodySize * 2.4
                color: colors.card
                border.color: searchInput.activeFocus ? colors.accent : colors.border
                border.width: 2
                radius: EffectsManager.r(6)

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.margins: PocketMetrics.spacing * 0.5
                    verticalAlignment: TextInput.AlignVCenter
                    color: colors.fg
                    font.pixelSize: root.isSmallScale ? PocketMetrics.bodySize * 0.9 : PocketMetrics.bodySize * 1.1
                    font.family: SettingsManager.fontFamily
                    selectByMouse: true
                    clip: true

                    activeFocusOnPress: false
                    inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

                    onTextChanged: {
                        if (!root.showSearch) return;
                        if (text.trim().length < 2) {
                            searchDebounce.stop();
                            WeatherEngine.resetSearch();
                        } else {
                            searchDebounce.restart();
                        }
                    }

                    onAccepted: {
                        searchDebounce.stop();
                        WeatherEngine.searchCity(text);
                    }

                    Keys.onPressed: function(event) {
                        var isCancel = event.key === Qt.Key_Escape || (api.keys.isCancel(event) && event.text === "");
                        if (isCancel) {
                            event.accepted = true;
                            if (!event.isAutoRepeat) root.closeSearch();
                            return;
                        }
                        if (event.key === Qt.Key_Down) {
                            event.accepted = true;
                            if (root.vkEnabled) {
                                root.showVK = true;
                                root.vkFocused = true;
                                searchInput.focus = false;
                            } else if (WeatherEngine.searchState === "results" && WeatherEngine.searchResults.length > 0) {
                                resultsList.currentIndex = 0;
                                resultsList.forceActiveFocus();
                            }
                            return;
                        }
                        if (api.keys.isAccept(event) && !event.isAutoRepeat && root.vkEnabled) {
                            event.accepted = true;
                            root.showVK = true;
                            root.vkFocused = true;
                            searchInput.focus = false;
                            SoundEngine.select();
                            return;
                        }
                    }
                }

                Timer {
                    id: searchDebounce
                    interval: 600
                    repeat: false
                    onTriggered: WeatherEngine.searchCity(searchInput.text)
                }
            }

            Text {
                visible: text !== "" && !root.showVK
                height: visible ? implicitHeight : 0
                text: {
                    switch (WeatherEngine.searchState) {
                        case "searching": return WeatherLanguage.t("weather_searching");
                        case "empty": return WeatherLanguage.t("weather_no_results");
                        case "error": return WeatherLanguage.t("weather_error");
                        default: return "";
                    }
                }
                color: WeatherEngine.searchState === "error" ? "#ff6b6b" : colors.muted
                font.pixelSize: root.isSmallScale ? PocketMetrics.bodySize * 0.85 : PocketMetrics.bodySize
                font.family: SettingsManager.fontFamily
                anchors.horizontalCenter: parent.horizontalCenter
            }

            ListView {
                id: resultsList
                width: parent.width
                height: Math.min(root.height * 0.4, contentHeight)
                visible: WeatherEngine.searchState === "results" && !root.showVK
                model: WeatherEngine.searchResults
                clip: true
                focus: false
                currentIndex: 0
                highlightMoveDuration: EffectsManager.dur(120)
                keyNavigationWraps: false

                delegate: Rectangle {
                    id: resultItem
                    readonly property bool selected: ListView.isCurrentItem && ListView.view.activeFocus
                    width: ListView.view.width
                    height: root.isSmallScale ? PocketMetrics.bodySize * 2.2 : PocketMetrics.bodySize * 3
                    color: selected ? colors.card : "transparent"
                    border.color: selected ? colors.accent : "transparent"
                    border.width: 2
                    radius: EffectsManager.r(4)

                    MarqueeText {
                        anchors.left: parent.left
                        anchors.leftMargin: PocketMetrics.spacing
                        anchors.right: parent.right
                        anchors.rightMargin: PocketMetrics.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name + (modelData.admin1 ? ", " + modelData.admin1 : "") + (modelData.country ? " (" + modelData.country + ")" : "")
                        color: resultItem.selected ? colors.accent : colors.fg
                        pixelSize: root.isSmallScale ? PocketMetrics.bodySize * 0.85 : PocketMetrics.bodySize
                        bold: resultItem.selected
                        active: resultItem.selected
                    }
                }

                Keys.onUpPressed: function(event) {
                    SoundEngine.scroll();
                    event.accepted = true;
                    if (resultsList.currentIndex === 0) {
                        searchInput.forceActiveFocus();
                    } else {
                        resultsList.decrementCurrentIndex();
                    }
                }

                Keys.onDownPressed: function(event) {
                    SoundEngine.scroll();
                    event.accepted = true;
                    resultsList.incrementCurrentIndex();
                }

                Keys.onReturnPressed: function(event) {
                    SoundEngine.scroll();
                    event.accepted = true;
                    if (!event.isAutoRepeat) root.confirmSelection();
                }

                Keys.onPressed: function(event) {
                    SoundEngine.scroll();

                    if (root.isCancelKey(event)) {
                        event.accepted = true;
                        root.closeSearch();
                    } else if (api.keys.isAccept(event)) {
                        event.accepted = true;
                        if (!event.isAutoRepeat) root.confirmSelection();
                    }
                }
            }
        }

        VirtualKeyboard {
            id: vk
            anchors.fill: parent
            visible: root.vkEnabled && root.showVK
            active: root.vkEnabled && root.vkFocused
            target: searchInput
            showSearchButton: true
            submitLabel: "OK"
            submitEnabled: true

            onSubmitted: {
                root.vkFocused = false;
                root.showVK = false;
                if (WeatherEngine.searchState === "results"
                    && WeatherEngine.searchResults.length > 0) {
                    resultsList.currentIndex = 0;
                resultsList.forceActiveFocus();
                    } else {
                        searchInput.forceActiveFocus();
                    }
            }

            onCanceled: {
                root.vkFocused = false;
                searchInput.forceActiveFocus();
            }

            onExitRequested: {
                root.vkFocused = false;
                searchInput.forceActiveFocus();
                SoundEngine.scroll();
            }
        }
    }

    HintBar {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.isSmallScale ? PocketMetrics.margin * 0.2 : PocketMetrics.margin
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: PocketMetrics.margin
        anchors.rightMargin: PocketMetrics.margin
        visible: !root.showVK
        text: {
            if (!root.showSearch)
                return root.currentIndex === 0 ? WeatherLanguage.t("weather_hint_city") : WeatherLanguage.t("weather_hint_menu");
            return resultsList.activeFocus ? WeatherLanguage.t("weather_hint_results") : WeatherLanguage.t("weather_hint_search");
        }
        textSize: root.isSmallScale ? PocketMetrics.bodySize * 0.65 : PocketMetrics.bodySize * 0.8
        color: colors.muted
        contentOpacity: 1.0
    }

    Keys.onUpPressed: {
        if (root.showVK && root.vkFocused) return;
        SoundEngine.scroll();
        if (!root.showSearch) root.currentIndex = Math.max(0, root.currentIndex - 1);
    }
    Keys.onDownPressed: {
        if (root.showVK && root.vkFocused) return;
        SoundEngine.scroll();
        if (!root.showSearch) root.currentIndex = Math.min(root.menuCount - 1, root.currentIndex + 1);
    }

    Keys.onLeftPressed: {
        if (root.showVK && root.vkFocused) return;
        SoundEngine.scroll();
        if (!root.showSearch) root.adjust(-1);
    }
    Keys.onRightPressed: {
        if (root.showVK && root.vkFocused) return;
        SoundEngine.scroll();
        if (!root.showSearch) root.adjust(1);
    }

    Keys.onPressed: function(event) {
        if (root.showVK && root.vkFocused) return;
        if (root.showSearch) return;
        if (api.keys.isCancel(event)) {
            event.accepted = true;
            if (!event.isAutoRepeat) NavigationManager.goBack();
            return;
        }
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            SoundEngine.select();
            root.activate();
            return;
        }
        if (api.keys.isDetails(event) && !event.isAutoRepeat && root.currentIndex === 0) {
            event.accepted = true;
            SoundEngine.back();
            WeatherEngine.removeActiveLocation();
            return;
        }
    }
}
