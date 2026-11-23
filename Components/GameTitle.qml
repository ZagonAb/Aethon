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

Item {
    id: root

    property string text: ""
    property bool favorite: false
    property bool showFavorite: true
    property var colors: SettingsManager.getCurrentColors()

    readonly property bool favoriteVisible: root.showFavorite
    && root.favorite === true
    && root.text !== ""

    readonly property real iconSize: PocketMetrics.titleSize
    readonly property real iconSpacing: PocketMetrics.spacing * 0.25

    readonly property real firstLineHeight: {
        if (titleText.lineCount > 0)
            return titleText.contentHeight / titleText.lineCount;
        return titleText.contentHeight;
    }

    height: titleRow.height

    Row {
        id: titleRow
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.iconSpacing

        Item {
            id: iconBox
            width: root.favoriteVisible ? root.iconSize : 0
            height: titleText.height
            visible: root.favoriteVisible

            Image {
                id: favIcon
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.round((root.firstLineHeight - root.iconSize) / 2)
                width: root.iconSize
                height: root.iconSize
                source: Qt.resolvedUrl("../assets/icons/favorite.svg")
                fillMode: Image.PreserveAspectFit
                smooth: true

                sourceSize.width: root.iconSize > 0 ? Math.round(root.iconSize) : 128
                sourceSize.height: root.iconSize > 0 ? Math.round(root.iconSize) : 128

                layer.enabled: EffectsManager.shaderEffectsEnabled
                layer.smooth: true
                layer.effect: ColorOverlay {
                    color: root.colors.accent
                }
            }
        }

        Text {
            id: titleText
            width: {
                var avail = root.width;
                if (root.favoriteVisible)
                    avail -= (iconBox.width + titleRow.spacing);
                return Math.min(implicitWidth, Math.max(0, avail));
            }
            text: root.text
            color: root.colors.accent
            font.pixelSize: PocketMetrics.titleSize
            font.bold: true
            font.family: SettingsManager.fontFamily
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
