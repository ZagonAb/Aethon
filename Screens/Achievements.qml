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
import "qrc:/qmlutils" as PegasusUtils

FocusScope {
    id: root
    anchors.fill: parent
    focus: true

    readonly property var colors: SettingsManager.getCurrentColors()
    readonly property var achievements: RetroAchievements.raAchievements
    readonly property int count: root.achievements.length
    property int currentIndex: 0
    readonly property var currentAch: root.count > 0 ? root.achievements[root.currentIndex] : null
    readonly property real rowHeight: PocketMetrics.bodySize * 2.6
    readonly property real badgeSize: root.rowHeight * 0.7
    readonly property int layoutMode: {
        if (SettingsManager.activeContext === "small4x3"
            || SettingsManager.activeContext === "tiny4x3") return 0;
        if (SettingsManager.activeContext === "square720") return 2;
        if (ResponsiveManager.aspectProfile === Enums.profileClassic) return 1;
        return 2;
    }

    TextMetrics {
        id: descMetrics
        font.pixelSize: PocketMetrics.bodySize
        font.family: SettingsManager.fontFamily
        text: "Hg"
    }

    Rectangle {
        anchors.fill: parent
        color: colors.bg
    }

    Column {
        anchors.fill: parent
        anchors.margins: PocketMetrics.margin
        spacing: PocketMetrics.spacing * 0.7

        Column {
            width: parent.width
            spacing: 4

            MarqueeText {
                width: Math.max(0, root.width * 0.5 - PocketMetrics.margin)
                text: RetroAchievements.raTitle || Language.t("achievements_title")
                color: colors.accent
                pixelSize: PocketMetrics.titleSize
                bold: true
                waitDuration: 3000
                padVertical: 0
            }

            Text {
                text: RetroAchievements.raConsole
                + "  •  " + RetroAchievements.raNumEarned + "/" + RetroAchievements.raNumAchievements
                + " " + Language.t("achievements_count_suffix")
                + "  •  " + RetroAchievements.raPointsEarned + "/" + RetroAchievements.raPoints
                + " " + Language.t("achievements_points_suffix")
                color: colors.muted
                font.pixelSize: PocketMetrics.bodySize
                font.family: SettingsManager.fontFamily
                width: parent.width
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }

        Rectangle { width: parent.width; height: 1; color: colors.border }

        Item {
            id: listArea
            width: parent.width
            height: {
                if (root.count === 0) return 0;
                if (root.layoutMode === 0) return 3 * root.rowHeight;

                var contentH = root.count * root.rowHeight + 10;
                var maxH = parent.height * 0.5;
                return Math.min(maxH, Math.max(root.rowHeight, contentH));
            }
            visible: root.count > 0

            ListView {
                id: listView
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width - 12
                clip: true
                model: root.achievements
                currentIndex: root.currentIndex
                highlightMoveDuration: EffectsManager.dur(150)
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    width: listView.width
                    height: root.rowHeight
                    radius: 4
                    color: index === root.currentIndex ? colors.card : "transparent"

                    Behavior on color {
                        enabled: EffectsManager.animationsEnabled
                        ColorAnimation { duration: EffectsManager.dur(140) }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: PocketMetrics.spacing * 0.6
                        anchors.rightMargin: PocketMetrics.spacing * 0.6
                        spacing: PocketMetrics.spacing * 0.6

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: root.badgeSize
                            height: root.badgeSize
                            source: modelData.earned ? modelData.badgeUrl : modelData.badgeLocked
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true

                            Rectangle {
                                anchors.fill: parent
                                visible: parent.status !== Image.Ready
                                color: colors.card
                                border.color: colors.border
                                z: -1
                            }
                        }

                        MarqueeText {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - root.badgeSize - 90 - PocketMetrics.spacing * 1.2
                            text: modelData.title
                            color: modelData.earned ? colors.fg : colors.muted
                            pixelSize: PocketMetrics.bodySize
                            bold: index === root.currentIndex
                            active: index === root.currentIndex
                            waitDuration: 3000
                            padVertical: 0
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 90
                            horizontalAlignment: Text.AlignRight
                            text: (modelData.earned ? "✓ " : "") + modelData.points + " " + Language.t("achievements_points_suffix")
                            color: modelData.earned ? colors.accent : colors.muted
                            font.pixelSize: PocketMetrics.bodySize * 0.9
                            font.family: SettingsManager.fontFamily
                        }
                    }
                }
            }

            readonly property int visibleRows: Math.max(1, Math.floor(listView.height / root.rowHeight))
            readonly property real scrollFraction: root.count > visibleRows
            ? root.currentIndex / (root.count - 1)
            : 0

            Rectangle {
                id: scrollTrack
                anchors.top: listView.top
                anchors.right: parent.right
                width: 6
                height: listView.height
                radius: width / 2
                color: colors.card
                opacity: 0.4
                visible: root.count > listArea.visibleRows

                Rectangle {
                    id: scrollThumb
                    width: parent.width
                    radius: width / 2
                    color: colors.accent
                    opacity: 0.75
                    height: Math.max(20, scrollTrack.height * Math.min(1, listArea.visibleRows / Math.max(root.count, 1)))
                    y: (scrollTrack.height - height) * listArea.scrollFraction

                    Behavior on y {
                        enabled: EffectsManager.animationsEnabled
                        NumberAnimation { duration: EffectsManager.dur(150); easing.type: Easing.OutQuad }
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.count === 0
            text: Language.t("achievements_empty")
            color: colors.muted
            font.pixelSize: PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily
        }

        Rectangle { width: parent.width; height: 1; color: colors.border; visible: root.count > 0 }

        Column {
            width: parent.width
            spacing: 6
            visible: root.currentAch !== null

            Text {
                text: root.currentAch ? root.currentAch.title : ""
                color: root.currentAch && root.currentAch.earned ? colors.accent : colors.fg
                font.pixelSize: PocketMetrics.bodySize * 1.15
                font.bold: true
                font.family: SettingsManager.fontFamily
                width: parent.width
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Item {
                id: descContainer
                width: parent.width
                height: {
                    if (root.layoutMode === 0) return descMetrics.height;
                    if (root.layoutMode === 1) return descMetrics.height * 2;
                    return descMetrics.height * 3;
                }

                MarqueeText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    visible: root.layoutMode === 0
                    text: root.currentAch ? (root.currentAch.description || Language.t("details_no_summary")) : ""
                    color: colors.fg
                    pixelSize: PocketMetrics.bodySize
                    waitDuration: 3000
                    padVertical: 0
                }

                PegasusUtils.AutoScroll {
                    id: autoScrollDesc
                    anchors.fill: parent
                    visible: root.layoutMode !== 0 && EffectsManager.animationsEnabled
                    pixelsPerSecond: 10
                    scrollWaitDuration: 4000

                    Text {
                        width: descContainer.width
                        text: root.currentAch ? (root.currentAch.description || Language.t("details_no_summary")) : ""
                        color: colors.fg
                        font.pixelSize: PocketMetrics.bodySize
                        font.family: SettingsManager.fontFamily
                        wrapMode: Text.WordWrap
                    }
                }

                Text {
                    anchors.fill: parent
                    visible: root.layoutMode !== 0 && !EffectsManager.animationsEnabled
                    text: root.currentAch ? (root.currentAch.description || Language.t("details_no_summary")) : ""
                    color: colors.fg
                    font.pixelSize: PocketMetrics.bodySize
                    font.family: SettingsManager.fontFamily
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                }
            }

            Text {
                visible: root.currentAch ? root.currentAch.earned : false
                text: root.currentAch
                ? (Language.t("achievements_earned_prefix") + " " + root.currentAch.dateEarned)
                : ""
                color: colors.muted
                font.pixelSize: PocketMetrics.bodySize * 0.85
                font.family: SettingsManager.fontFamily
                width: parent.width
                wrapMode: Text.WordWrap
                maximumLineCount: 1
                elide: Text.ElideRight
            }
        }
    }

    Keys.onUpPressed: {
        SoundEngine.scroll();
        if (root.count > 0)
            root.currentIndex = (root.currentIndex - 1 + root.count) % root.count;
    }

    Keys.onDownPressed: {
        SoundEngine.scroll();
        if (root.count > 0)
            root.currentIndex = (root.currentIndex + 1) % root.count;
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            event.accepted = true;
            NavigationManager.goBack();
        }
    }
}
