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

    property var valuesList: CategoryLibrary.valuesForSection(AppState.currentSection)
    readonly property int count: root.valuesList.length
    property int currentIndex: 0

    readonly property var currentValueRef: root.count > 0 ? root.valuesList[root.currentIndex] : null

    readonly property var colors: SettingsManager.getCurrentColors()

    Component.onCompleted: {
        if (AppState.previousCategoryValue) {
            for (var i = 0; i < root.count; i++) {
                if (root.valuesList[i].label === AppState.previousCategoryValue) {
                    root.currentIndex = i;
                    break;
                }
            }
        }
    }

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

    Column {
        id: contentColumn
        anchors.centerIn: parent
        spacing: PocketMetrics.spacing

        transform: Translate { id: contentSlide; x: 0 }

        Text {
            text: Enums.sectionName(AppState.currentSection)
            color: colors.muted
            font.pixelSize: PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: root.currentValueRef
            ? CategoryLibrary.displayLabel(root.currentValueRef.label)
            : Language.t("label_no_data")
            color: colors.accent
            font.pixelSize: PocketMetrics.titleSize * 1.4
            font.bold: true
            font.family: SettingsManager.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(root.width - PocketMetrics.margin * 2, 900)
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: root.currentValueRef
            ? (root.currentValueRef.count + " " + Language.t("label_games"))
            : ""
            color: colors.fg
            font.pixelSize: PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: root.count > 0 ? ((root.currentIndex + 1) + " / " + root.count) : ""
            color: colors.muted
            font.pixelSize: PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    property int lastStepDirection: 0

    NumberAnimation {
        id: pulseSlide
        target: contentSlide
        property: "x"
        from: root.lastStepDirection > 0 ? PocketMetrics.animationDistance
        : root.lastStepDirection < 0 ? -PocketMetrics.animationDistance
        : 0
        to: 0
        duration: 180
        easing.type: Easing.OutQuad
    }

    NumberAnimation {
        id: pulseAnim
        target: contentColumn
        property: "opacity"
        from: 0.35
        to: 1.0
        duration: 150
        easing.type: Easing.OutQuad
        onStarted: pulseSlide.restart()
    }
    onCurrentIndexChanged: pulseAnim.restart()

    Keys.onLeftPressed: {
        SoundEngine.scroll();
        if (root.count > 0) {
            root.lastStepDirection = -1;
            root.currentIndex = (root.currentIndex - 1 + root.count) % root.count;
        }
    }

    Keys.onRightPressed: {
        SoundEngine.scroll();
        if (root.count > 0) {
            root.lastStepDirection = 1;
            root.currentIndex = (root.currentIndex + 1) % root.count;
        }
    }

    Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (root.currentValueRef)
                NavigationManager.enterCategoryValue(root.currentValueRef.label);
        }
    }
}
