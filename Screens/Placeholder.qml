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

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

    Column {
        anchors.centerIn: parent
        spacing: PocketMetrics.spacing

        Text {
            text: Enums.screenName(AppState.currentScreen) + " " + Language.t("placeholder_not_implemented_suffix")
            color: colors.muted
            font.pixelSize: PocketMetrics.titleSize
            font.family: SettingsManager.fontFamily
        }

        Text {
            text: Language.t("placeholder_section_prefix") + " " + Enums.sectionName(AppState.currentSection)
            + "  " + Language.t("placeholder_collection_prefix") + " "
            + (AppState.currentCollection ? AppState.currentCollection.name : "-")
            color: colors.muted
            font.pixelSize: PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily
        }

        HintBar {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: PocketMetrics.margin * 0.5
            anchors.left: parent.left
            anchors.right: parent.right
            text: Language.t("placeholder_back_hint")
            textSize: PocketMetrics.bodySize
            color: colors.muted
            contentOpacity: 1.0
        }
    }
}
