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
import "qrc:/qmlutils" as PegasusUtils

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

    Column {
        id: headerColumn
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: PocketMetrics.margin * 0.6
        spacing: PocketMetrics.spacing * 0.6

        Text {
            text: root.collection ? root.collection.name : "—"
            color: colors.muted
            font.pixelSize: PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily
        }

        Row {
            width: parent.width
            spacing: PocketMetrics.spacing * 2

            GameArtCard {
                width: PocketMetrics.cardWidth
                height: PocketMetrics.cardHeight
                game: root.game
                artSource: root.artSource
                colors: root.colors
            }

            Column {
                id: infoColumn
                spacing: 6
                width: parent.width - PocketMetrics.cardWidth - PocketMetrics.spacing * 2

                Text {
                    width: parent.width
                    text: root.game ? root.cleanTitle : Language.t("label_no_games")
                    color: colors.accent
                    font.pixelSize: PocketMetrics.titleSize * 1.3
                    font.bold: true
                    font.family: SettingsManager.fontFamily
                    wrapMode: Text.WordWrap
                }

                Text {
                    width: parent.width
                    text: Language.t("details_developer") + " " + (root.game ? (root.game.developer || "—") : "")
                    + "   " + Language.t("details_publisher") + " " + (root.game ? (root.game.publisher || "—") : "")
                    color: colors.muted
                    font.pixelSize: PocketMetrics.bodySize
                    font.family: SettingsManager.fontFamily
                    wrapMode: Text.WordWrap
                }
                Text {
                    width: parent.width
                    text: Language.t("details_year") + " " + (root.game ? (root.game.releaseYear || "—") : "")
                    + "   " + Language.t("details_genre") + " " + root.cleanGenre
                    color: colors.muted
                    font.pixelSize: PocketMetrics.bodySize
                    font.family: SettingsManager.fontFamily
                    wrapMode: Text.WordWrap
                }
                Text {
                    width: parent.width
                    text: Language.t("details_players") + " " + (root.game ? root.game.players : "")
                    + "   " + Language.t("details_play_count") + " " + (root.game ? root.game.playCount : "")
                    + "   " + Language.t("details_play_time") + " " + root.formattedPlayTime
                    color: colors.muted
                    font.pixelSize: PocketMetrics.bodySize
                    font.family: SettingsManager.fontFamily
                    wrapMode: Text.WordWrap
                }
                Text {
                    width: parent.width
                    visible: root.raSummary !== null
                    text: root.raSummary ? root.raSummary.text : ""
                    color: root.raSummary ? root.raSummary.color : colors.muted
                    font.pixelSize: PocketMetrics.bodySize
                    font.bold: true
                    font.family: SettingsManager.fontFamily
                    wrapMode: Text.WordWrap

                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }
    }

    Item {
        id: descriptionContainer
        anchors.top: headerColumn.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: actionsRow.top
        anchors.margins: PocketMetrics.margin * 0.6
        anchors.topMargin: PocketMetrics.spacing

        PegasusUtils.AutoScroll {
            id: autoscroll
            anchors.fill: parent
            pixelsPerSecond: 20
            scrollWaitDuration: 2000

            Text {
                width: descriptionContainer.width
                text: root.game
                ? (root.game.description || root.game.summary || Language.t("details_no_summary"))
                : ""
                color: colors.fg
                font.pixelSize: PocketMetrics.bodySize
                font.family: SettingsManager.fontFamily
                wrapMode: Text.WordWrap
                lineHeight: 1.15
            }
        }
    }

    Row {
        id: actionsRow
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PocketMetrics.margin
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: PocketMetrics.spacing * 2

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
