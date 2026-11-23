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
import "qrc:/qmlutils" as PegasusUtils

FocusScope {
    id: root
    anchors.fill: parent
    focus: true

    readonly property var colors: SettingsManager.getCurrentColors()
    property var selDate: ({ y: 0, m: 0, d: 0 })
    property bool _ready: false

    Component.onCompleted: {
        CalendarEngine.buildIndex();

        if (AppState.calendarSelectedDate && AppState.calendarSelectedDate.y > 0) {
            root.selDate = AppState.calendarSelectedDate;
        } else {
            var now = new Date();
            root.selDate = { y: now.getFullYear(), m: now.getMonth(), d: now.getDate() };
            AppState.calendarSelectedDate = root.selDate;
        }
        root._ready = true;
        root.updateGrid();
        root.updateEmptyMessage();
    }

    onSelDateChanged: {
        if (!root._ready) return;
        AppState.calendarSelectedDate = root.selDate;
    }

    property var gridCells: []
    property string emptyMessage: ""

    function updateGrid() {
        var startDay = Language.firstDayOfWeek();
        root.gridCells = CalendarEngine.getMonthGrid(root.selDate.y, root.selDate.m, startDay);
        root.updateEmptyMessage();
    }

    function updateEmptyMessage() {
        if (root.currentDayCount === 0) {
            var arr = [
                Language.t("calendar_empty_1"),
                Language.t("calendar_empty_2"),
                Language.t("calendar_empty_3"),
                Language.t("calendar_empty_4")
            ];
            root.emptyMessage = arr[Math.floor(Math.random() * arr.length)];
        }
    }

    Connections {
        target: Language
        function onCurrentLanguageChanged() { root.updateGrid(); }
    }

    function stepDate(days) {
        var d = new Date(root.selDate.y, root.selDate.m, root.selDate.d + days);
        if (d.getFullYear() !== root.selDate.y || d.getMonth() !== root.selDate.m)
            return;
        root.selDate = { y: d.getFullYear(), m: d.getMonth(), d: d.getDate() };
        root.updateGrid();
    }

    function stepMonth(delta) {
        var first = new Date(root.selDate.y, root.selDate.m + delta, 1);
        var daysInMonth = new Date(first.getFullYear(), first.getMonth() + 1, 0).getDate();
        root.selDate = {
            y: first.getFullYear(),
            m: first.getMonth(),
            d: Math.min(root.selDate.d, daysInMonth)
        };
        root.updateGrid();
    }

    function jumpToNextLaunch(direction) {
        var next = CalendarEngine.findNextLaunchDate(root.selDate.y, root.selDate.m, root.selDate.d, direction);
        if (next) {
            root.selDate = { y: next.getFullYear(), m: next.getMonth(), d: next.getDate() };
            root.updateGrid();
        }
    }

    readonly property var currentDayGames: CalendarEngine.getGamesForDate(root.selDate.y, root.selDate.m + 1, root.selDate.d)
    readonly property int currentDayCount: root.currentDayGames.length
    readonly property bool isWide: ResponsiveManager.aspectProfile !== Enums.profileSquare

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

    function getDateTitle() {
        return Language.formatDate(root.selDate.y, root.selDate.m, root.selDate.d);
    }

    function getGameListText() {
        var list = [];
        for (var i = 0; i < root.currentDayCount; i++) {
            var g = root.currentDayGames[i];
            list.push(g.game.title + (g.year > 0 ? " (" + g.year + ")" : ""));
        }
        return list.join("\n");
    }

    readonly property real weekRowH: PocketMetrics.bodySize * 1.3
    readonly property real dateTitleSize: PocketMetrics.titleSize * 0.9
    readonly property int monthTotal: {
        var t = 0;
        for (var i = 0; i < root.gridCells.length; i++) {
            if (root.gridCells[i].isCurrentMonth) t += root.gridCells[i].count;
        }
        return t;
    }

    readonly property string infoText: monthTotal > 0
    ? monthTotal + " " + Language.plural(monthTotal, "calendar_month_singular", "calendar_month_plural", "calendar_month_few")
    : ""

    readonly property string countText: {
        if (root.currentDayCount === 0) return root.emptyMessage;
        var n = root.currentDayCount;
        return n + " " + Language.plural(n, "calendar_launch_singular", "calendar_launch_plural", "calendar_launch_few");
    }
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
            text: Language.t("calendar_title")
            color: colors.fg
            font.pixelSize: PocketMetrics.titleSize * 0.864
            font.bold: true
            font.family: SettingsManager.fontFamily
        }
    }

    Item {
        id: squareLayout
        visible: !root.isWide
        anchors.fill: parent
        anchors.topMargin: PocketMetrics.headerHeight
        anchors.bottomMargin: PocketMetrics.margin
        anchors.leftMargin: PocketMetrics.margin
        anchors.rightMargin: PocketMetrics.margin

        readonly property real gap: PocketMetrics.spacing
        readonly property real listH: PocketMetrics.bodySize * 3
        readonly property bool hasList: root.currentDayCount > 0
        readonly property bool hasInfo: root.infoText !== ""

        readonly property real fixedH: dateTitleSq.implicitHeight
        + 1
        + countSq.implicitHeight
        + (hasList ? listH : 0)
        + infoSq.implicitHeight
        + root.weekRowH
        + gap * (3 + (hasList ? 1 : 0) + (hasInfo ? 1 : 0))

        readonly property real cellSize: Math.max(0, Math.min(width / 7, (height - fixedH) / 6))

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: squareLayout.gap

            Text {
                id: dateTitleSq
                width: parent.width
                text: root.getDateTitle()
                color: colors.accent
                font.pixelSize: root.dateTitleSize
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 10
                font.bold: true
                font.family: SettingsManager.fontFamily
                horizontalAlignment: Text.AlignHCenter
            }

            Item {
                id: gridAreaSquare
                anchors.horizontalCenter: parent.horizontalCenter
                readonly property real cellSize: squareLayout.cellSize
                width: cellSize * 7
                height: root.weekRowH + cellSize * 6

                Column {
                    anchors.fill: parent
                    spacing: 0

                    Row {
                        width: gridAreaSquare.cellSize * 7
                        height: root.weekRowH
                        Repeater {
                            model: 7
                            delegate: Item {
                                width: gridAreaSquare.cellSize
                                height: root.weekRowH
                                Text {
                                    anchors.centerIn: parent
                                    text: Language.weekdayShort(index)
                                    color: colors.muted
                                    font.pixelSize: Math.max(10, Math.min(gridAreaSquare.cellSize * 0.3, root.weekRowH))
                                    font.family: SettingsManager.fontFamily
                                }
                            }
                        }
                    }
                    Grid {
                        width: gridAreaSquare.cellSize * 7
                        height: gridAreaSquare.cellSize * 6
                        columns: 7
                        Repeater {
                            model: root.gridCells
                            delegate: Item {
                                width: gridAreaSquare.cellSize
                                height: gridAreaSquare.cellSize
                                readonly property bool isSelected: modelData.year === root.selDate.y && modelData.month === root.selDate.m && modelData.day === root.selDate.d
                                opacity: modelData.isCurrentMonth ? 1.0 : 0.35
                                Rectangle { anchors.centerIn: parent; width: parent.width * 0.7; height: width; radius: width / 2; color: colors.accent; visible: modelData.count > 0 }
                                Rectangle { anchors.fill: parent; anchors.margins: 2; radius: width / 2; color: "transparent"; border.color: colors.accent; border.width: 2; visible: parent.isSelected }
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.day
                                    color: modelData.count > 0 ? colors.bg : colors.fg
                                    font.pixelSize: Math.max(10, gridAreaSquare.cellSize * 0.35)
                                    font.family: SettingsManager.fontFamily
                                    font.bold: modelData.isToday
                                    font.underline: modelData.isToday
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: colors.border }

            Text {
                id: countSq
                width: parent.width
                text: root.countText
                color: colors.fg
                font.pixelSize: PocketMetrics.bodySize * 1.1
                font.family: SettingsManager.fontFamily
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Item {
                width: parent.width
                height: squareLayout.listH
                visible: squareLayout.hasList

                PegasusUtils.AutoScroll {
                    anchors.fill: parent
                    pixelsPerSecond: 15
                    scrollWaitDuration: 2000
                    Text {
                        width: parent.width
                        text: root.getGameListText()
                        color: colors.muted
                        font.pixelSize: PocketMetrics.bodySize * 0.9
                        font.family: SettingsManager.fontFamily
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Text {
                id: infoSq
                visible: text !== ""
                width: parent.width
                text: root.infoText
                color: colors.muted
                font.pixelSize: PocketMetrics.bodySize * 0.8
                font.family: SettingsManager.fontFamily
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }

    Item {
        id: wideLayout
        visible: root.isWide
        anchors.fill: parent
        anchors.topMargin: PocketMetrics.headerHeight + PocketMetrics.spacing
        anchors.bottomMargin: PocketMetrics.margin
        anchors.leftMargin: PocketMetrics.margin
        anchors.rightMargin: PocketMetrics.margin

        readonly property real gap: PocketMetrics.spacing
        readonly property real colW: width / 2 - PocketMetrics.spacing

        readonly property real fixedH: dateTitleWide.implicitHeight
        + infoWide.implicitHeight
        + root.weekRowH
        + gap * 2

        readonly property real cellSize: Math.max(0, Math.min(colW / 7, (height - fixedH) / 6))

        Item {
            id: leftCol
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: wideLayout.colW

            Text {
                id: dateTitleWide
                anchors.top: parent.top
                anchors.left: parent.left
                width: parent.width - wideLayout.gap
                text: root.getDateTitle()
                color: colors.accent
                font.pixelSize: root.dateTitleSize
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 10
                font.bold: true
                font.family: SettingsManager.fontFamily
            }

            Item {
                id: gridAreaWide
                anchors.top: dateTitleWide.bottom
                anchors.topMargin: wideLayout.gap
                anchors.left: parent.left
                readonly property real cellSize: wideLayout.cellSize
                width: cellSize * 7
                height: root.weekRowH + cellSize * 6

                Column {
                    anchors.fill: parent
                    spacing: 0

                    Row {
                        width: gridAreaWide.cellSize * 7
                        height: root.weekRowH
                        Repeater {
                            model: 7
                            delegate: Item {
                                width: gridAreaWide.cellSize
                                height: root.weekRowH
                                Text {
                                    anchors.centerIn: parent
                                    text: Language.weekdayShort(index)
                                    color: colors.muted
                                    font.pixelSize: Math.max(10, Math.min(gridAreaWide.cellSize * 0.3, root.weekRowH))
                                    font.family: SettingsManager.fontFamily
                                }
                            }
                        }
                    }
                    Grid {
                        width: gridAreaWide.cellSize * 7
                        height: gridAreaWide.cellSize * 6
                        columns: 7
                        Repeater {
                            model: root.gridCells
                            delegate: Item {
                                width: gridAreaWide.cellSize
                                height: gridAreaWide.cellSize
                                readonly property bool isSelected: modelData.year === root.selDate.y && modelData.month === root.selDate.m && modelData.day === root.selDate.d
                                opacity: modelData.isCurrentMonth ? 1.0 : 0.35
                                Rectangle { anchors.centerIn: parent; width: parent.width * 0.7; height: width; radius: width / 2; color: colors.accent; visible: modelData.count > 0 }
                                Rectangle { anchors.fill: parent; anchors.margins: 2; radius: width / 2; color: "transparent"; border.color: colors.accent; border.width: 2; visible: parent.isSelected }
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.day
                                    color: modelData.count > 0 ? colors.bg : colors.fg
                                    font.pixelSize: Math.max(10, gridAreaWide.cellSize * 0.35)
                                    font.family: SettingsManager.fontFamily
                                    font.bold: modelData.isToday
                                    font.underline: modelData.isToday
                                }
                            }
                        }
                    }
                }
            }

            Text {
                id: infoWide
                visible: text !== ""
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: parent.width
                text: root.infoText
                color: colors.muted
                font.pixelSize: PocketMetrics.bodySize * 0.8
                font.family: SettingsManager.fontFamily
                wrapMode: Text.WordWrap
            }
        }

        Item {
            id: rightCol
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: wideLayout.colW

            Text {
                id: countWide
                anchors.top: parent.top
                width: parent.width
                text: root.countText
                color: colors.fg
                font.pixelSize: PocketMetrics.bodySize * 1.1
                font.bold: true
                font.family: SettingsManager.fontFamily
                wrapMode: Text.WordWrap
            }

            Rectangle {
                id: sepWide
                anchors.top: countWide.bottom
                anchors.topMargin: wideLayout.gap
                width: parent.width
                height: 1
                color: colors.border
            }

            Item {
                anchors.top: sepWide.bottom
                anchors.topMargin: wideLayout.gap
                anchors.bottom: parent.bottom
                width: parent.width
                visible: root.currentDayCount > 0

                PegasusUtils.AutoScroll {
                    anchors.fill: parent
                    pixelsPerSecond: 15
                    scrollWaitDuration: 2000
                    Text {
                        width: parent.width
                        text: root.getGameListText()
                        color: colors.muted
                        font.pixelSize: PocketMetrics.bodySize
                        font.family: SettingsManager.fontFamily
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    Keys.onLeftPressed: {
        SoundEngine.scroll();
        root.stepDate(-1)
    }
    Keys.onRightPressed: {
        SoundEngine.scroll();
        root.stepDate(1)
    }
    Keys.onUpPressed: {
        SoundEngine.scroll();
        root.stepDate(-7)
    }
    Keys.onDownPressed: {
        SoundEngine.scroll();
        root.stepDate(7)
    }

    Keys.onPressed: {
        if (api.keys.isPrevPage(event)) {
            event.accepted = true;
            SoundEngine.scroll();
            root.stepMonth(-1);
        } else if (api.keys.isNextPage(event)) {
            event.accepted = true;
            SoundEngine.scroll();
            root.stepMonth(1);
        } else if (api.keys.isPageUp(event)) {
            event.accepted = true;
            if (!event.isAutoRepeat) {
                SoundEngine.scroll();
                root.jumpToNextLaunch(-1);
            }
        } else if (api.keys.isPageDown(event)) {
            event.accepted = true;
            if (!event.isAutoRepeat) {
                SoundEngine.scroll();
                root.jumpToNextLaunch(1);
            }
        } else if (api.keys.isFilters(event)) {
            event.accepted = true;
            SoundEngine.back();
        } else if (api.keys.isDetails(event)) {
            event.accepted = true;
            if (!event.isAutoRepeat) {
                SoundEngine.select();
                var now = new Date();
                root.selDate = { y: now.getFullYear(), m: now.getMonth(), d: now.getDate() };
                root.updateGrid();
            }
        } else if (api.keys.isCancel(event)) {
            event.accepted = true;
            NavigationManager.goBack();
        } else if (api.keys.isAccept(event)) {
            event.accepted = true;
            if (!event.isAutoRepeat && root.currentDayCount > 0) {
                NavigationManager.enterCalendarDay();
            }
        }
    }
}
