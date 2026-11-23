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
    readonly property bool isWide: ResponsiveManager.aspectProfile !== Enums.profileClassic

    readonly property var tabs: {
        var list = [
            { id: "dev", label: Language.t("about_tab_dev"), text: Language.t("about_dev_text") }
        ];

        if (SettingsManager.showToolMetadata)
            list.push({ id: "metadata", label: Language.t("about_tab_metadata"), text: Language.t("about_metadata_text") });
        if (SettingsManager.showToolWeather)
            list.push({ id: "weather", label: Language.t("about_tab_weather"), text: Language.t("about_weather_text") });
        if (SettingsManager.showToolGallery)
            list.push({ id: "gallery", label: Language.t("about_tab_gallery"), text: Language.t("about_gallery_text") });
        if (SettingsManager.showToolCalendar)
            list.push({ id: "calendar", label: Language.t("about_tab_calendar"), text: Language.t("about_calendar_text") });

        list.push({ id: "ra", label: Language.t("about_tab_ra"), text: Language.t("about_ra_text") });

        if (SettingsManager.showToolStatistics)
            list.push({ id: "statistics", label: Language.t("about_tab_statistics"), text: Language.t("about_statistics_text") });

        return list;
    }

    property int currentTab: 0

    onTabsChanged: {
        if (root.currentTab >= root.tabs.length)
            root.currentTab = Math.max(0, root.tabs.length - 1);
    }

    component LinkButton: Rectangle {
        property string title: ""
        property string url: ""
        property string iconSource: ""

        width: parent.width
        height: PocketMetrics.bodySize * 3.5
        color: hoverArea.containsMouse ? colors.card : "transparent"
        border.color: hoverArea.containsMouse ? colors.accent : colors.border
        border.width: 2
        radius: EffectsManager.r(8)

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Row {
            anchors.centerIn: parent
            spacing: PocketMetrics.spacing * 0.8

            Item {
                width: PocketMetrics.bodySize * 1.8
                height: width
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    id: iconImg
                    anchors.fill: parent
                    source: iconSource
                    fillMode: Image.PreserveAspectFit
                    visible: !EffectsManager.shaderEffectsEnabled
                    sourceSize.width: width > 0 ? Math.round(width) : 128
                    sourceSize.height: height > 0 ? Math.round(height) : 128
                }

                ColorOverlay {
                    anchors.fill: parent
                    source: iconImg
                    color: hoverArea.containsMouse ? colors.accent : colors.fg
                    visible: EffectsManager.shaderEffectsEnabled && iconImg.status === Image.Ready
                }
            }

            Text {
                text: title
                color: hoverArea.containsMouse ? colors.accent : colors.fg
                font.pixelSize: PocketMetrics.bodySize * 1.2
                font.bold: true
                font.family: SettingsManager.fontFamily
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Qt.openUrlExternally(url)
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
            text: Language.t("about_title")
            color: colors.fg
            font.pixelSize: PocketMetrics.titleSize * 0.864
            font.bold: true
            font.family: SettingsManager.fontFamily
        }
    }

    Item {
        anchors.top: pageHeader.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: PocketMetrics.margin
        anchors.topMargin: PocketMetrics.spacing

        Row {
            visible: root.isWide
            anchors.fill: parent
            spacing: PocketMetrics.margin

            Item {
                width: parent.width * 0.3
                height: parent.height

                ListView {
                    id: tabsListWide
                    anchors.fill: parent
                    model: root.tabs
                    currentIndex: root.currentTab
                    interactive: false
                    highlightMoveDuration: 150

                    delegate: Item {
                        width: tabsListWide.width
                        height: PocketMetrics.bodySize * 2.8

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: EffectsManager.r(6)
                            color: index === root.currentTab ? colors.card : "transparent"
                            border.color: index === root.currentTab ? colors.accent : "transparent"
                            border.width: 2

                            MarqueeText {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: index === root.currentTab ? colors.accent : colors.muted
                                pixelSize: PocketMetrics.bodySize
                                bold: index === root.currentTab
                                active: index === root.currentTab
                                provideImplicitSize: true
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width - (parent.width * 0.3) - PocketMetrics.margin
                height: parent.height
                color: colors.card
                radius: EffectsManager.r(6)

                Flickable {
                    id: flickWide
                    anchors.fill: parent
                    anchors.margins: PocketMetrics.spacing
                    clip: true
                    contentWidth: width
                    contentHeight: contentColumnWide.height
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: contentColumnWide
                        width: flickWide.width
                        spacing: PocketMetrics.spacing

                        Text {
                            width: parent.width
                            text: ButtonGlyphs.expand(root.tabs[root.currentTab] ? root.tabs[root.currentTab].text : "")
                            color: colors.fg
                            font.pixelSize: PocketMetrics.bodySize * 0.95
                            font.family: SettingsManager.fontFamily
                            wrapMode: Text.WordWrap
                            lineHeight: 1.2
                        }

                        Column {
                            width: parent.width * 0.6
                            spacing: 12
                            visible: root.tabs[root.currentTab] && root.tabs[root.currentTab].id === "dev"

                            LinkButton {
                                title: "Discord"
                                url: "https://discord.com/users/830255719965523969"
                                iconSource: Qt.resolvedUrl("../assets/icons/discord.svg")
                            }

                            LinkButton {
                                title: "GitHub"
                                url: "https://github.com/ZagonAb"
                                iconSource: Qt.resolvedUrl("../assets/icons/github.svg")
                            }
                        }
                    }
                }

                Rectangle {
                    visible: flickWide.contentHeight > flickWide.height
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 4
                    color: colors.border
                    opacity: 0.5

                    Rectangle {
                        width: parent.width
                        height: Math.max(20, parent.height * (flickWide.height / flickWide.contentHeight))
                        color: colors.accent
                        y: (parent.height - height) * (flickWide.contentY / Math.max(1, flickWide.contentHeight - flickWide.height))
                    }
                }
            }
        }

        Column {
            visible: !root.isWide
            anchors.fill: parent
            spacing: PocketMetrics.spacing

            Item {
                width: parent.width
                height: PocketMetrics.bodySize * 2.5

                ListView {
                    id: tabsListVertical
                    anchors.fill: parent
                    orientation: ListView.Horizontal
                    model: root.tabs
                    currentIndex: root.currentTab
                    interactive: false
                    spacing: PocketMetrics.spacing
                    highlightMoveDuration: 150
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    delegate: Item {
                        width: Math.min(tabText.implicitWidth + 30, root.width * 0.4)
                        height: tabsListVertical.height

                        Rectangle {
                            anchors.fill: parent
                            radius: EffectsManager.r(4)
                            color: index === root.currentTab ? colors.card : "transparent"
                            border.color: index === root.currentTab ? colors.accent : "transparent"
                            border.width: 2

                            MarqueeText {
                                id: tabText
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: index === root.currentTab ? colors.accent : colors.muted
                                pixelSize: PocketMetrics.bodySize * 0.9
                                bold: index === root.currentTab
                                active: index === root.currentTab
                                provideImplicitSize: true
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: parent.height - tabsListVertical.height - PocketMetrics.spacing
                color: colors.card
                radius: EffectsManager.r(6)

                Flickable {
                    id: flickVertical
                    anchors.fill: parent
                    anchors.margins: PocketMetrics.spacing
                    clip: true
                    contentWidth: width
                    contentHeight: contentColumnVertical.height
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: contentColumnVertical
                        width: flickVertical.width
                        spacing: PocketMetrics.spacing

                        Text {
                            width: parent.width
                            text: ButtonGlyphs.expand(root.tabs[root.currentTab] ? root.tabs[root.currentTab].text : "")
                            color: colors.fg
                            font.pixelSize: PocketMetrics.bodySize * 0.95
                            font.family: SettingsManager.fontFamily
                            wrapMode: Text.WordWrap
                            lineHeight: 1.2
                        }

                        Column {
                            width: parent.width
                            spacing: 12
                            visible: root.tabs[root.currentTab] && root.tabs[root.currentTab].id === "dev"

                            LinkButton {
                                title: "Discord"
                                url: "https://discord.com/users/830255719965523969"
                                iconSource: Qt.resolvedUrl("../assets/icons/discord.svg")
                            }

                            LinkButton {
                                title: "GitHub"
                                url: "https://github.com/ZagonAb"
                                iconSource: Qt.resolvedUrl("../assets/icons/github.svg")
                            }
                        }
                    }
                }

                Rectangle {
                    visible: flickVertical.contentHeight > flickVertical.height
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 4
                    color: colors.border
                    opacity: 0.5

                    Rectangle {
                        width: parent.width
                        height: Math.max(20, parent.height * (flickVertical.height / flickVertical.contentHeight))
                        color: colors.accent
                        y: (parent.height - height) * (flickVertical.contentY / Math.max(1, flickVertical.contentHeight - flickVertical.height))
                    }
                }
            }
        }
    }

    Keys.onLeftPressed: {
        SoundEngine.scroll();
        root.currentTab = Math.max(0, root.currentTab - 1);
    }
    Keys.onRightPressed: {
        SoundEngine.scroll();
        root.currentTab = Math.min(root.tabs.length - 1, root.currentTab + 1);
    }

    Keys.onUpPressed: {
        SoundEngine.scroll();
        var f = root.isWide ? flickWide : flickVertical;
        f.contentY = Math.max(0, f.contentY - 50);
    }
    Keys.onDownPressed: {
        SoundEngine.scroll();
        var f = root.isWide ? flickWide : flickVertical;
        var maxY = Math.max(0, f.contentHeight - f.height);
        f.contentY = Math.min(maxY, f.contentY + 50);
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            NavigationManager.goBack();
        }
        if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            var f = root.isWide ? flickWide : flickVertical;
            var maxY = Math.max(0, f.contentHeight - f.height);
            f.contentY = Math.min(maxY, f.contentY + (f.height * 0.8));
        }
        if (api.keys.isPrevPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            var f = root.isWide ? flickWide : flickVertical;
            f.contentY = Math.max(0, f.contentY - (f.height * 0.8));
        }
    }
}
