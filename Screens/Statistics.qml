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
    readonly property bool isWide: ResponsiveManager.aspectProfile === Enums.profileWide

    NumberAnimation {
        id: scrollAnim
        target: flick
        property: "contentY"
        duration: 200
        easing.type: Easing.OutCubic
    }

    function scrollBy(dir) {
        var step = PocketMetrics.bodySize * 3;
        var target = flick.contentY + dir * step;
        var maxY = Math.max(0, flick.contentHeight - flick.height);
        target = Math.max(0, Math.min(maxY, target));
        scrollAnim.stop();
        scrollAnim.to = target;
        scrollAnim.start();
    }

    function formatPlayTime(seconds) {
        if (!seconds || seconds <= 0) return "00:00:00";
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        var s = Math.floor(seconds % 60);
        function pad(n) { return (n < 10 ? "0" : "") + n; }
        return pad(h) + ":" + pad(m) + ":" + pad(s);
    }

    property var systemHours: []
    property real barProgress: 1.0
    readonly property int maxSystemBars: root.isWide ? 8 : 6

    function collectionLabel(col) {
        var sn = (col.shortName && col.shortName !== "") ? col.shortName : col.name;
        return String(sn || "").toUpperCase();
    }

    function buildSystemHours() {
        var rows = [];
        for (var c = 0; c < api.collections.count; c++) {
            var col = api.collections.get(c);
            var games = col.games.toVarArray();
            var secs = 0;
            for (var i = 0; i < games.length; i++)
                secs += (games[i].playTime || 0);
            if (secs > 0) rows.push({ name: root.collectionLabel(col), seconds: secs });
        }
        rows.sort(function(a, b) { return b.seconds - a.seconds; });

        var limit = root.maxSystemBars;
        if (rows.length > limit) {
            var rest = 0;
            for (var j = limit - 1; j < rows.length; j++) rest += rows[j].seconds;
            rows = rows.slice(0, limit - 1);
            rows.push({ name: Language.t("stats_others"), seconds: rest, isOthers: true });
        }
        root.systemHours = rows;
    }

    function hoursText(seconds) {
        if (!seconds || seconds <= 0) return "0m";
        var h = seconds / 3600;
        if (h >= 10) return Math.round(h) + "h";
        if (h >= 1) return (Math.round(h * 10) / 10) + "h";
        return Math.max(1, Math.round(seconds / 60)) + "m";
    }

    NumberAnimation {
        id: barAnim
        target: root
        property: "barProgress"
        from: 0
        to: 1
        duration: EffectsManager.dur(450)
        easing.type: Easing.OutCubic
    }

    Component.onCompleted: {
        StatisticsEngine.build();
        root.buildSystemHours();
        if (EffectsManager.animationsEnabled) {
            root.barProgress = 0;
            barAnim.start();
        }
        root.forceActiveFocus();
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
            text: Language.t("stats_title")
            color: colors.fg
            font.pixelSize: PocketMetrics.titleSize * 0.864
            font.bold: true
            font.family: SettingsManager.fontFamily
        }
    }

    Flickable {
        id: flick
        anchors.top: pageHeader.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: PocketMetrics.margin
        anchors.rightMargin: PocketMetrics.margin + 12
        anchors.topMargin: PocketMetrics.margin
        anchors.bottomMargin: PocketMetrics.margin
        clip: true
        contentWidth: width
        contentHeight: mainColumn.height
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: mainColumn
            width: parent.width
            spacing: PocketMetrics.margin * 1.5

            Column {
                width: parent.width
                spacing: PocketMetrics.spacing

                Text {
                    text: Language.t("stats_overview")
                    color: colors.accent
                    font.pixelSize: PocketMetrics.bodySize * 1.1
                    font.bold: true
                    font.family: SettingsManager.fontFamily
                }

                Grid {
                    width: parent.width
                    columns: root.isWide ? 3 : 2
                    spacing: PocketMetrics.spacing

                    Repeater {
                        model: [
                            { label: Language.t("stats_total_games"), value: StatisticsEngine.stats.totalGames },
                            { label: Language.t("stats_total_favorites"), value: StatisticsEngine.stats.totalFavorites },
                            { label: Language.t("stats_total_collections"), value: StatisticsEngine.stats.totalCollections },
                            { label: Language.t("stats_total_launches"), value: StatisticsEngine.stats.totalLaunches },
                            { label: Language.t("stats_total_time"), value: root.formatPlayTime(StatisticsEngine.stats.totalTime) }
                        ]

                        delegate: Rectangle {
                            width: (parent.width - (parent.spacing * (parent.columns - 1))) / parent.columns
                            height: PocketMetrics.bodySize * 3.8
                            color: colors.card
                            radius: EffectsManager.r(6)
                            border.color: colors.border
                            border.width: 1

                            Column {
                                anchors.centerIn: parent
                                spacing: 4
                                width: parent.width - 10

                                Text {
                                    text: modelData.label
                                    color: colors.muted
                                    font.pixelSize: PocketMetrics.bodySize * 0.8
                                    font.family: SettingsManager.fontFamily
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: modelData.value
                                    color: colors.accent
                                    font.pixelSize: PocketMetrics.bodySize * 1.2
                                    font.bold: true
                                    font.family: SettingsManager.fontFamily
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    fontSizeMode: Text.HorizontalFit
                                    minimumPixelSize: 10
                                }
                            }
                        }
                    }
                }
            }

            Row {
                width: parent.width
                spacing: PocketMetrics.margin

                Column {
                    width: root.isWide ? (parent.width - parent.spacing) / 2 : parent.width
                    spacing: PocketMetrics.spacing

                    Text {
                        text: Language.t("stats_top_time")
                        color: colors.accent
                        font.pixelSize: PocketMetrics.bodySize * 1.1
                        font.bold: true
                        font.family: SettingsManager.fontFamily
                    }

                    Column {
                        width: parent.width
                        spacing: 6
                        Repeater {
                            model: StatisticsEngine.stats.topPlayed
                            delegate: Row {
                                width: parent.width - PocketMetrics.spacing
                                spacing: 8
                                Text {
                                    id: numText1
                                    text: (index + 1) + "."
                                    color: colors.muted
                                    font.pixelSize: PocketMetrics.bodySize
                                    font.family: SettingsManager.fontFamily
                                }
                                MarqueeText {
                                    width: parent.width - numText1.width - timeText1.width - (parent.spacing * 2)
                                    text: GameUtils.cleanGameTitle(modelData.title)
                                    color: colors.fg
                                    pixelSize: PocketMetrics.bodySize
                                    provideImplicitSize: true
                                    padVertical: 0
                                }
                                Text {
                                    id: timeText1
                                    text: root.formatPlayTime(modelData.playTime)
                                    color: colors.muted
                                    font.pixelSize: PocketMetrics.bodySize * 0.85
                                    font.family: SettingsManager.fontFamily
                                    horizontalAlignment: Text.AlignRight
                                    width: Math.max(90, implicitWidth)
                                }
                            }
                        }
                    }
                }

                Column {
                    visible: root.isWide
                    width: root.isWide ? (parent.width - parent.spacing) / 2 : 0
                    spacing: PocketMetrics.spacing

                    Text {
                        text: Language.t("stats_top_launch")
                        color: colors.accent
                        font.pixelSize: PocketMetrics.bodySize * 1.1
                        font.bold: true
                        font.family: SettingsManager.fontFamily
                    }

                    Column {
                        width: parent.width
                        spacing: 6
                        Repeater {
                            model: StatisticsEngine.stats.topLaunched
                            delegate: Row {
                                width: parent.width - PocketMetrics.spacing
                                spacing: 8
                                Text {
                                    id: numText2
                                    text: (index + 1) + "."
                                    color: colors.muted
                                    font.pixelSize: PocketMetrics.bodySize
                                    font.family: SettingsManager.fontFamily
                                }
                                MarqueeText {
                                    width: parent.width - numText2.width - countText2.width - (parent.spacing * 2)
                                    text: GameUtils.cleanGameTitle(modelData.title)
                                    color: colors.fg
                                    pixelSize: PocketMetrics.bodySize
                                    provideImplicitSize: true
                                    padVertical: 0
                                }
                                Text {
                                    id: countText2
                                    text: modelData.playCount + "x"
                                    color: colors.muted
                                    font.pixelSize: PocketMetrics.bodySize * 0.85
                                    font.family: SettingsManager.fontFamily
                                    horizontalAlignment: Text.AlignRight
                                    width: Math.max(50, implicitWidth)
                                }
                            }
                        }
                    }
                }
            }

            Column {
                visible: !root.isWide
                width: parent.width
                spacing: PocketMetrics.spacing

                Text {
                    text: Language.t("stats_top_launch")
                    color: colors.accent
                    font.pixelSize: PocketMetrics.bodySize * 1.1
                    font.bold: true
                    font.family: SettingsManager.fontFamily
                }

                Column {
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: StatisticsEngine.stats.topLaunched
                        delegate: Row {
                            width: parent.width - PocketMetrics.spacing
                            spacing: 8
                            Text {
                                id: numText3
                                text: (index + 1) + "."
                                color: colors.muted
                                font.pixelSize: PocketMetrics.bodySize
                                font.family: SettingsManager.fontFamily
                            }
                            MarqueeText {
                                width: parent.width - numText3.width - countText3.width - (parent.spacing * 2)
                                text: GameUtils.cleanGameTitle(modelData.title)
                                color: colors.fg
                                pixelSize: PocketMetrics.bodySize
                                provideImplicitSize: true
                                padVertical: 0
                            }
                            Text {
                                id: countText3
                                text: modelData.playCount + "x"
                                color: colors.muted
                                font.pixelSize: PocketMetrics.bodySize * 0.85
                                font.family: SettingsManager.fontFamily
                                horizontalAlignment: Text.AlignRight
                                width: Math.max(50, implicitWidth)
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: root.systemHours.length > 0
                width: parent.width
                height: 1
                color: colors.border
                opacity: 0.5
            }

            Column {
                id: hoursBlock
                visible: root.systemHours.length > 0
                width: parent.width
                spacing: PocketMetrics.spacing

                readonly property real maxSeconds: {
                    var m = 1;
                    for (var i = 0; i < root.systemHours.length; i++)
                        m = Math.max(m, root.systemHours[i].seconds);
                    return m;
                }
                readonly property real labelW: Math.round(PocketMetrics.bodySize * 4.6)
                readonly property real valueW: Math.round(PocketMetrics.bodySize * 3.2)
                readonly property real rowH: Math.round(PocketMetrics.bodySize * 1.3)

                Text {
                    text: Language.t("stats_hours_by_system")
                    color: colors.accent
                    font.pixelSize: PocketMetrics.bodySize * 1.1
                    font.bold: true
                    font.family: SettingsManager.fontFamily
                }

                Column {
                    width: parent.width - PocketMetrics.spacing
                    spacing: Math.max(4, Math.round(PocketMetrics.spacing * 0.4))

                    Repeater {
                        model: root.systemHours

                        delegate: Item {
                            width: parent.width
                            height: hoursBlock.rowH

                            readonly property bool first: index === 0
                            readonly property real ratio: Math.min(1, modelData.seconds / Math.max(1, hoursBlock.maxSeconds))

                            Text {
                                id: sysLabel
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: hoursBlock.labelW
                                text: modelData.name
                                color: first ? colors.accent : colors.fg
                                font.pixelSize: PocketMetrics.bodySize * 0.9
                                font.bold: first
                                font.family: SettingsManager.fontFamily
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                id: track
                                anchors.left: sysLabel.right
                                anchors.leftMargin: 8
                                anchors.right: sysValue.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                height: Math.max(6, Math.round(hoursBlock.rowH * 0.5))
                                color: colors.card
                                border.color: colors.border
                                border.width: 1
                                radius: EffectsManager.r(2)

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 1
                                    width: Math.max(modelData.seconds > 0 ? 2 : 0,
                                                    Math.round((parent.width - 2) * ratio * root.barProgress))
                                    color: first ? colors.accent : colors.muted
                                    opacity: modelData.isOthers === true ? 0.55 : 1.0
                                    radius: EffectsManager.r(1)
                                }
                            }

                            Text {
                                id: sysValue
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: hoursBlock.valueW
                                text: root.hoursText(modelData.seconds)
                                color: colors.muted
                                font.pixelSize: PocketMetrics.bodySize * 0.85
                                font.family: SettingsManager.fontFamily
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: colors.border
                opacity: 0.5
            }

            Column {
                width: parent.width
                spacing: PocketMetrics.spacing

                Text {
                    text: Language.t("stats_collections")
                    color: colors.accent
                    font.pixelSize: PocketMetrics.bodySize * 1.1
                    font.bold: true
                    font.family: SettingsManager.fontFamily
                }

                Grid {
                    width: parent.width
                    columns: root.isWide ? 2 : 1
                    spacing: PocketMetrics.margin

                    Repeater {
                        model: StatisticsEngine.stats.collections
                        delegate: Row {
                            width: (parent.width - (parent.spacing * (parent.columns - 1))) / parent.columns
                            spacing: 8

                            MarqueeText {
                                width: parent.width - countText4.width - parent.spacing
                                text: modelData.name
                                color: colors.fg
                                pixelSize: PocketMetrics.bodySize * 0.9
                                provideImplicitSize: true
                                padVertical: 0
                            }

                            Text {
                                id: countText4
                                text: modelData.count
                                color: colors.accent
                                font.pixelSize: PocketMetrics.bodySize * 0.9
                                font.bold: true
                                font.family: SettingsManager.fontFamily
                                horizontalAlignment: Text.AlignRight
                                width: Math.max(60, implicitWidth)
                            }
                        }
                    }
                }
            }

            Item { width: 1; height: PocketMetrics.margin }
        }
    }

    Rectangle {
        anchors.top: flick.top
        anchors.bottom: flick.bottom
        anchors.right: parent.right
        anchors.rightMargin: PocketMetrics.margin * 0.5
        width: 6
        color: colors.border
        opacity: 0.4
        radius: width / 2
        visible: flick.contentHeight > flick.height

        Rectangle {
            width: parent.width
            height: Math.max(20, parent.height * (flick.height / flick.contentHeight))
            color: colors.accent
            radius: parent.radius
            y: (parent.height - height) * (flick.contentY / Math.max(1, flick.contentHeight - flick.height))
        }
    }

    Keys.onUpPressed: {
        SoundEngine.scroll();
        root.scrollBy(-1)
    }
    Keys.onDownPressed: {
        SoundEngine.scroll();
        root.scrollBy(1)
    }

    Keys.onPressed: {
        if (api.keys.isPrevPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.scrollBy(-5);
        } else if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.scrollBy(5);
        } else if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            NavigationManager.goBack();
        }
    }
}
