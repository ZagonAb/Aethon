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
import "../Components"

Item {
    id: root
    anchors.fill: parent

    property var game: null
    property var collection: null
    property string artSource: ""
    property var actions: []
    property int actionIndex: 0
    property var raSummary: null
    property string cleanGenre: "—"
    property string cleanTitle: ""
    property string formattedPlayTime: "00:00:00"

    readonly property var colors: SettingsManager.getCurrentColors()
    readonly property real contentWidth: Math.min(width - PocketMetrics.margin * 2, 640)

    Flickable {
        id: infoFlick
        anchors.top: parent.top
        anchors.bottom: actionsRow.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: PocketMetrics.headerHeight + PocketMetrics.contentTopPad
        anchors.bottomMargin: PocketMetrics.spacing
        width: root.contentWidth
        contentWidth: width
        contentHeight: innerColumn.implicitHeight
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: innerColumn
            width: parent.width
            spacing: PocketMetrics.innerSpacing

            Text {
                width: parent.width
                text: root.collection ? root.collection.name : "—"
                color: colors.muted
                font.pixelSize: PocketMetrics.bodySize
                font.family: SettingsManager.fontFamily
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            GameArtCard {
                width: PocketMetrics.cardWidth
                height: PocketMetrics.cardHeight
                anchors.horizontalCenter: parent.horizontalCenter
                game: root.game
                artSource: root.artSource
                colors: root.colors
            }

            Text {
                width: parent.width
                text: root.game ? root.cleanTitle : Language.t("label_no_games")
                color: colors.accent
                font.pixelSize: PocketMetrics.titleSize * 1.2
                font.bold: true
                font.family: SettingsManager.fontFamily
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                text: root.game ? ((root.game.developer || "—") + " • " + (root.game.publisher || "—") + " • " + (root.game.releaseYear || "—")) : ""
                color: colors.muted
                font.pixelSize: PocketMetrics.bodySize
                font.family: SettingsManager.fontFamily
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    Row {
        id: actionsRow
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PocketMetrics.margin
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: PocketMetrics.spacing

        Item {
            width: PocketMetrics.bodySize * 1.5
            height: PocketMetrics.bodySize * 1.5
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.actionIndex === 0 ? 0.2 : 1.0
            Behavior on opacity {
                enabled: EffectsManager.animationsEnabled
                NumberAnimation { duration: EffectsManager.dur(200); easing.type: Easing.OutQuad }
            }

            Image {
                id: leftIcon
                anchors.fill: parent
                source: Qt.resolvedUrl("../assets/icons/arrow-left.svg")
                fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
                sourceSize.width: width > 0 ? Math.round(width) : 128
                sourceSize.height: height > 0 ? Math.round(height) : 128
                layer.enabled: EffectsManager.shaderEffectsEnabled
                layer.smooth: true
                layer.effect: ColorOverlay { color: colors.border }
            }

            Text {
                anchors.centerIn: parent
                text: "←"
                color: colors.border
                visible: leftIcon.status !== Image.Ready
                font.pixelSize: PocketMetrics.bodySize
                font.family: SettingsManager.fontFamily
            }
        }

        Repeater {
            model: root.actions
            delegate: Text {
                text: Language.t("action_" + modelData)
                color: index === root.actionIndex ? colors.accent : colors.muted
                font.pixelSize: PocketMetrics.titleSize
                font.bold: index === root.actionIndex
                font.family: SettingsManager.fontFamily
                scale: index === root.actionIndex ? 1.1 : 1.0
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

        Item {
            width: PocketMetrics.bodySize * 1.5
            height: PocketMetrics.bodySize * 1.5
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.actionIndex === root.actions.length - 1 ? 0.2 : 1.0
            Behavior on opacity {
                enabled: EffectsManager.animationsEnabled
                NumberAnimation { duration: EffectsManager.dur(200); easing.type: Easing.OutQuad }
            }

            Image {
                id: rightIcon
                anchors.fill: parent
                source: Qt.resolvedUrl("../assets/icons/arrow-right.svg")
                fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
                sourceSize.width: width > 0 ? Math.round(width) : 128
                sourceSize.height: height > 0 ? Math.round(height) : 128
                layer.enabled: EffectsManager.shaderEffectsEnabled
                layer.smooth: true
                layer.effect: ColorOverlay { color: colors.border }
            }

            Text {
                anchors.centerIn: parent
                text: "→"
                color: colors.border
                visible: rightIcon.status !== Image.Ready
                font.pixelSize: PocketMetrics.bodySize
                font.family: SettingsManager.fontFamily
            }
        }
    }
}
