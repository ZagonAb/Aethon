// Aethon
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
import QtQuick 2.15
import QtGraphicalEffects 1.15
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
    property int actionIndex: 0
    readonly property real maxTitleSize: Math.min(PocketMetrics.titleSize * 0.7, height * 0.06)
    readonly property real maxCitySize: Math.min(PocketMetrics.titleSize * 1.2, height * 0.08)
    readonly property real maxTempSize: Math.min(PocketMetrics.titleSize * 1.8, height * 0.13)
    readonly property real maxStatusSize: Math.min(PocketMetrics.bodySize * 1.1, height * 0.045)
    readonly property real maxDetailLabel: Math.min(PocketMetrics.bodySize * 0.85, height * 0.035)
    readonly property real maxDetailValue: Math.min(PocketMetrics.bodySize * 1.0, height * 0.04)
    readonly property real maxMainIcon: Math.min(PocketMetrics.bodySize * 3.5, height * 0.14)
    readonly property real maxForecastIcon: Math.min(PocketMetrics.bodySize * 2, height * 0.06)
    readonly property real actionFontSize: Math.min(PocketMetrics.bodySize * 1.2, height * 0.05)
    readonly property real arrowSize: Math.min(PocketMetrics.bodySize * 1.0, height * 0.045)

    readonly property real detailSpacing: {
        if (height === 600) return 8;
        if (root.isCompact) return 4;
        return Math.max(10, PocketMetrics.spacing * 0.4);
    }
    readonly property real sectionSpacing: root.isCompact ? PocketMetrics.spacing * 0.4 : PocketMetrics.spacing * 0.4

    Component.onCompleted: {
        if (WeatherEngine.state === "idle" || WeatherEngine.state === "error") {
            WeatherEngine.loadSavedLocation();
        }
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
            text: WeatherLanguage.t("weather_title")
            color: colors.fg
            font.pixelSize: root.maxTitleSize
            font.bold: true
            font.family: SettingsManager.fontFamily
        }
    }

    Text {
        anchors.centerIn: parent
        visible: WeatherEngine.currentLocation === null
        textFormat: Text.RichText
        text: WeatherLanguage.t("weather_no_city")
        + " <font face='" + FontManager.iconFamily + "'>\u21a4</font>"
        color: colors.muted
        font.pixelSize: root.maxStatusSize
        font.family: SettingsManager.fontFamily
    }

    Text {
        anchors.centerIn: parent
        visible: WeatherEngine.state === "fetching"
        text: WeatherLanguage.t("weather_loading")
        color: colors.muted
        font.pixelSize: root.maxStatusSize
        font.family: SettingsManager.fontFamily
    }

    Column {
        anchors.centerIn: parent
        spacing: PocketMetrics.spacing * 0.5
        visible: WeatherEngine.currentLocation !== null && WeatherEngine.state === "error"

        Text {
            text: WeatherLanguage.t("weather_error")
            color: "#ff6b6b"
            font.pixelSize: root.maxStatusSize
            font.family: SettingsManager.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter
        }

        HintBar {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.width * 0.8
            text: WeatherLanguage.t("weather_retry_hint")
            textSize: root.maxDetailLabel
            color: colors.muted
            contentOpacity: 1.0
        }
    }

    Item {
        id: weatherContentArea
        anchors.top: pageHeader.bottom
        anchors.topMargin: root.isCompact ? 0 : PocketMetrics.spacing * 0.5
        anchors.bottom: controlsRow.top
        anchors.bottomMargin: root.isCompact ? 0 : PocketMetrics.spacing * 0.5
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: PocketMetrics.margin
        anchors.rightMargin: PocketMetrics.margin
        visible: WeatherEngine.currentLocation !== null && WeatherEngine.state === "success"

        Flickable {
            anchors.fill: parent
            contentWidth: width
            contentHeight: content.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: content
                width: parent.width
                spacing: root.sectionSpacing

                Text {
                    text: WeatherEngine.currentLocation ? WeatherEngine.currentLocation.name : ""
                    color: colors.fg
                    font.pixelSize: root.maxCitySize
                    font.bold: true
                    font.family: SettingsManager.fontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: root.isCompact ? PocketMetrics.spacing * 0.5 : PocketMetrics.spacing * 1.5

                    Image {
                        source: Qt.resolvedUrl("../assets/icons/weather/" + WeatherEngine.getWeatherIconName(WeatherEngine.weatherCode, WeatherEngine.isDay) + ".svg")
                        width: root.maxMainIcon
                        height: width
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        sourceSize.width: width > 0 ? Math.round(width) : 128
                        sourceSize.height: height > 0 ? Math.round(height) : 128
                        layer.enabled: EffectsManager.shaderEffectsEnabled
                        layer.smooth: true
                        layer.effect: ColorOverlay { color: colors.accent }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        Text {
                            text: Math.round(WeatherEngine.currentTemp) + (WeatherEngine.tempUnit === "celsius" ? "°C" : "°F")
                            color: colors.accent
                            font.pixelSize: root.maxTempSize
                            font.bold: true
                            font.family: SettingsManager.fontFamily
                        }

                        Text {
                            text: WeatherLanguage.t(WeatherEngine.getWmoTranslationKey(WeatherEngine.weatherCode))
                            color: colors.fg
                            font.pixelSize: root.maxStatusSize
                            font.family: SettingsManager.fontFamily
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: root.isCompact ? PocketMetrics.spacing * 1.2 : PocketMetrics.spacing * 2.5

                    Column {
                        spacing: root.detailSpacing
                        Text { text: WeatherLanguage.t("weather_feels_like"); color: colors.muted; font.pixelSize: root.maxDetailLabel; font.family: SettingsManager.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: Math.round(WeatherEngine.apparentTemp) + "°"; color: colors.fg; font.pixelSize: root.maxDetailValue; font.bold: true; font.family: SettingsManager.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                    Column {
                        spacing: root.detailSpacing
                        Text { text: WeatherLanguage.t("weather_humidity"); color: colors.muted; font.pixelSize: root.maxDetailLabel; font.family: SettingsManager.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: WeatherEngine.humidity + "%"; color: colors.fg; font.pixelSize: root.maxDetailValue; font.bold: true; font.family: SettingsManager.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                    Column {
                        spacing: root.detailSpacing
                        Text { text: WeatherLanguage.t("weather_wind"); color: colors.muted; font.pixelSize: root.maxDetailLabel; font.family: SettingsManager.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: Math.round(WeatherEngine.windSpeed) + " " + WeatherEngine.windUnitText; color: colors.fg; font.pixelSize: root.maxDetailValue; font.bold: true; font.family: SettingsManager.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: root.isCompact ? PocketMetrics.spacing * 1.2 : PocketMetrics.spacing * 2.5
                    visible: WeatherEngine.showDetails

                    Column {
                        spacing: root.detailSpacing
                        Text { text: WeatherLanguage.t("weather_rain_chance"); color: colors.muted; font.pixelSize: root.maxDetailLabel; font.family: SettingsManager.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: WeatherEngine.todayRainChance >= 0 ? WeatherEngine.todayRainChance + "%" : "-"; color: colors.fg; font.pixelSize: root.maxDetailValue; font.bold: true; font.family: SettingsManager.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                    Column {
                        spacing: root.detailSpacing
                        Text { text: WeatherLanguage.t("weather_uv"); color: colors.muted; font.pixelSize: root.maxDetailLabel; font.family: SettingsManager.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: WeatherEngine.todayUv >= 0 ? (Math.round(WeatherEngine.todayUv * 10) / 10) : "-"; color: colors.fg; font.pixelSize: root.maxDetailValue; font.bold: true; font.family: SettingsManager.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                    Column {
                        spacing: root.detailSpacing
                        Text { text: WeatherLanguage.t("weather_sunrise"); color: colors.muted; font.pixelSize: root.maxDetailLabel; font.family: SettingsManager.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: WeatherEngine.sunrise !== "" ? WeatherEngine.formatTime(WeatherEngine.sunrise) : "-"; color: colors.fg; font.pixelSize: root.maxDetailValue; font.bold: true; font.family: SettingsManager.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                    Column {
                        spacing: root.detailSpacing
                        Text { text: WeatherLanguage.t("weather_sunset"); color: colors.muted; font.pixelSize: root.maxDetailLabel; font.family: SettingsManager.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: WeatherEngine.sunset !== "" ? WeatherEngine.formatTime(WeatherEngine.sunset) : "-"; color: colors.fg; font.pixelSize: root.maxDetailValue; font.bold: true; font.family: SettingsManager.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: PocketMetrics.spacing * 0.5
                    visible: WeatherEngine.showAirQuality

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: WeatherLanguage.t("weather_air_quality")
                        color: colors.muted
                        font.pixelSize: root.maxDetailLabel
                        font.family: SettingsManager.fontFamily
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.maxDetailLabel
                        height: width
                        radius: width / 2
                        visible: WeatherEngine.aqi >= 0
                        color: WeatherEngine.aqiColor(WeatherEngine.aqi)
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: WeatherEngine.aqi >= 0 ? WeatherEngine.aqi + "  " + WeatherLanguage.t(WeatherEngine.aqiKey(WeatherEngine.aqi)) : "-"
                        color: colors.fg
                        font.pixelSize: root.maxDetailValue
                        font.bold: true
                        font.family: SettingsManager.fontFamily
                    }
                }

                Rectangle {
                    width: parent.width * 0.8
                    height: 1
                    color: colors.border
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: WeatherEngine.dailyForecast.length > 0
                }

                Row {
                    id: forecastRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    visible: WeatherEngine.dailyForecast.length > 0

                    spacing: root.isCompact ? PocketMetrics.spacing * 0.5 : PocketMetrics.spacing * 1.2

                    readonly property real colWidth: (width - (spacing * Math.max(0, WeatherEngine.dailyForecast.length - 1))) / Math.max(1, WeatherEngine.dailyForecast.length)

                    Repeater {
                        model: WeatherEngine.dailyForecast
                        delegate: Column {
                            spacing: root.detailSpacing
                            width: forecastRow.colWidth

                            Text {
                                text: {
                                    var p = modelData.date.split("-");
                                    var d = new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2]));
                                    return WeatherLanguage.dayShort(d.getDay());
                                }
                                color: colors.muted
                                font.pixelSize: root.maxDetailLabel
                                font.family: SettingsManager.fontFamily
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Image {
                                source: Qt.resolvedUrl("../assets/icons/weather/" + WeatherEngine.getWeatherIconName(modelData.code, true) + ".svg")
                                width: root.maxForecastIcon
                                height: width
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                anchors.horizontalCenter: parent.horizontalCenter
                                sourceSize.width: width > 0 ? Math.round(width) : 64
                                sourceSize.height: height > 0 ? Math.round(height) : 64
                                layer.enabled: EffectsManager.shaderEffectsEnabled
                                layer.smooth: true
                                layer.effect: ColorOverlay { color: colors.accent }
                            }

                            Text {
                                text: Math.round(modelData.max) + "°/" + Math.round(modelData.min) + "°"
                                color: colors.fg
                                font.pixelSize: root.maxDetailValue
                                font.family: SettingsManager.fontFamily
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }
        }
    }

    Row {
        id: controlsRow
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PocketMetrics.margin
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.isCompact ? PocketMetrics.spacing * 1.5 : PocketMetrics.spacing * 2.5
        visible: WeatherEngine.state === "success"

        Item {
            width: root.arrowSize
            height: root.arrowSize
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.actionIndex === 0 ? 0.2 : 1.0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

            Image {
                id: leftIcon
                anchors.fill: parent
                source: Qt.resolvedUrl("../assets/icons/arrow-left.svg")
                fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
                sourceSize { width: 128; height: 128 }
                layer.enabled: true
                layer.smooth: true
                layer.effect: ColorOverlay { color: colors.border }
            }

            Text {
                anchors.centerIn: parent
                text: "←"
                color: colors.border
                visible: leftIcon.status !== Image.Ready
                font.pixelSize: root.arrowSize
                font.family: SettingsManager.fontFamily
            }
        }

        Text {
            text: Language.t("nav_settings")
            color: root.actionIndex === 0 ? colors.accent : colors.muted
            font.pixelSize: root.actionFontSize
            font.bold: root.actionIndex === 0
            font.family: SettingsManager.fontFamily
            scale: root.actionIndex === 0 ? 1.05 : 1.0
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
        }

        Text {
            text: Language.t("ra_back")
            color: root.actionIndex === 1 ? colors.accent : colors.muted
            font.pixelSize: root.actionFontSize
            font.bold: root.actionIndex === 1
            font.family: SettingsManager.fontFamily
            scale: root.actionIndex === 1 ? 1.05 : 1.0
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
        }

        Item {
            width: root.arrowSize
            height: root.arrowSize
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.actionIndex === 1 ? 0.2 : 1.0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

            Image {
                id: rightIcon
                anchors.fill: parent
                source: Qt.resolvedUrl("../assets/icons/arrow-right.svg")
                fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
                sourceSize { width: 128; height: 128 }
                layer.enabled: true
                layer.smooth: true
                layer.effect: ColorOverlay { color: colors.border }
            }

            Text {
                anchors.centerIn: parent
                text: "→"
                color: colors.border
                visible: rightIcon.status !== Image.Ready
                font.pixelSize: root.arrowSize
                font.family: SettingsManager.fontFamily
            }
        }
    }

    Text {
        id: creditText
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PocketMetrics.margin * 0.2
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Open-Meteo.com" + (WeatherEngine.showAirQuality ? " · CAMS" : "")
        color: colors.muted
        opacity: 0.7
        font.pixelSize: SettingsManager.activeContext === "tiny4x3"
        ? 5
        : Math.min(PocketMetrics.bodySize * 0.4, height * 0.025)
        font.family: SettingsManager.fontFamily
    }

    Keys.onLeftPressed: {
        SoundEngine.scroll();
        if (WeatherEngine.state === "success") root.actionIndex = 0;
    }

    Keys.onRightPressed: {
        SoundEngine.scroll();
        if (WeatherEngine.state === "success") root.actionIndex = 1;
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            event.accepted = true; NavigationManager.goBack(); return;
        }
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (WeatherEngine.state === "error" && WeatherEngine.currentLocation) {
                SoundEngine.select();
                WeatherEngine.fetchWeather(WeatherEngine.currentLocation.lat, WeatherEngine.currentLocation.lon);
            } else if (WeatherEngine.state === "success") {
                if (root.actionIndex === 0) NavigationManager.enterWeatherSettings();
                else NavigationManager.goBack();
            }
            return;
        }
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            NavigationManager.enterWeatherSettings();
            return;
        }
    }
}
