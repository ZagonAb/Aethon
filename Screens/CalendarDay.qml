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

    readonly property var dayGames: CalendarEngine.getGamesForDate(
        AppState.calendarSelectedDate.y,
        AppState.calendarSelectedDate.m + 1,
        AppState.calendarSelectedDate.d
    )
    readonly property int count: root.dayGames.length

    property int currentIndex: 0

    readonly property var currentEntry: root.count > 0 ? root.dayGames[root.currentIndex] : null
    readonly property var currentGameRef: root.currentEntry ? root.currentEntry.game : null
    readonly property int currentGameYear: root.currentEntry ? root.currentEntry.year : 0

    SettleGate {
        id: settleGate
        input: root.currentGameRef
    }
    readonly property var shownGameRef: settleGate.output
    readonly property bool scrolling: settleGate.settling

    readonly property string artSource: root.shownGameRef ? GameUtils.getPreferredArt(root.shownGameRef, "gameLists") : ""
    readonly property string cleanTitle: root.currentGameRef ? GameUtils.cleanGameTitle(root.currentGameRef.title) : ""

    readonly property string anniversaryMsg: {
        var _lang = Language.currentLanguage;
        if (!root.currentGameRef) return "";
        if (!root.shownGameRef) return "\u00A0";

        var viewYear = AppState.calendarSelectedDate.y;
        var relYear = root.currentGameYear;

        if (!relYear || relYear <= 0) {
            return Language.t("cal_ann_unknown");
        }

        var age = viewYear - relYear;

        if (age < 0) {
            return Language.t("cal_ann_negative").replace("%1", relYear);
        } else if (age === 0) {
            return Language.t("cal_ann_zero");
        } else {
            var today = new Date();
            var isToday = (viewYear === today.getFullYear() &&
            AppState.calendarSelectedDate.m === today.getMonth() &&
            AppState.calendarSelectedDate.d === today.getDate());

            var msg = "";
            if (isToday) {
                msg = Language.t("cal_ann_today").replace("%1", age);
            } else {
                msg = Language.t("cal_ann_years").replace("%1", age);
            }

            if (age % 5 === 0) {
                msg += " " + Language.t("cal_ann_round");
            }
            return msg;
        }
    }

    readonly property string historyMsg: {
        var _lang = Language.currentLanguage;
        if (!root.currentGameRef) return "";
        if (!root.shownGameRef) return "\u00A0";

        var game = root.shownGameRef;
        var pCount = game.playCount || 0;

        if (pCount === 0) {
            return Language.t("cal_hist_never");
        }

        var msg = Language.pluralFormatted(pCount, "cal_hist_once", "cal_hist_played", "cal_hist_few");

        if (game.lastPlayed) {
            var dateStr = Language.formatNumericDate(game.lastPlayed);
            msg += " · " + Language.t("cal_hist_last").replace("%1", dateStr);
        }

        return msg;
    }

    function commitIndex(index) {
        root.currentIndex = index;
        if (index >= 0 && index < root.count) {
            AppState.selectGame(root.currentGameRef, index);
        }
    }

    function stepGame(direction) {
        if (root.count < 2) return;
        root.lastStepDirection = direction;
        root.commitIndex((root.currentIndex + direction + root.count) % root.count);
    }

    property int actionIndex: 0

    function runAction() {
        if (!root.currentGameRef) return;
        if (root.actionIndex === 0) {
            Persistence.save();
            SoundEngine.launchGame(root.currentGameRef);
        } else {
            NavigationManager.enterGameDetailsFromCalendar();
        }
    }

    Component.onCompleted: {
        if (AppState.currentGameIndex >= 0 && AppState.currentGameIndex < root.count) {
            root.commitIndex(AppState.currentGameIndex);
        } else if (root.count > 0) {
            root.commitIndex(0);
        }
        settleGate.snap();
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

    readonly property string releaseDateText: {
        var sd = AppState.calendarSelectedDate;
        if (root.currentGameYear > 0)
            return Language.formatDate(root.currentGameYear, sd.m, sd.d);
        return Language.formatMonthDay(sd.m, sd.d);
    }

    readonly property bool compact: ResponsiveManager.aspectProfile === Enums.profileClassic
    readonly property real gap: compact ? PocketMetrics.spacing * 0.5 : PocketMetrics.spacing
    readonly property real cardAspect: PocketMetrics.cardWidth / PocketMetrics.cardHeight

    readonly property real cardH: Math.max(0, Math.min(PocketMetrics.cardHeight,
                                                       contentArea.height - dateText.height - textBlock.height - root.gap * 2))
    readonly property real cardW: cardH * cardAspect

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

    Item {
        id: contentArea
        anchors.top: parent.top
        anchors.topMargin: PocketMetrics.headerHeight
        anchors.bottom: controlsRow.top
        anchors.bottomMargin: PocketMetrics.spacing
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.count > 0

        Column {
            id: contentColumn
            anchors.centerIn: parent
            spacing: root.gap

            transform: Translate { id: contentSlide; x: 0 }

            Text {
                id: dateText
                text: root.releaseDateText
                + (root.compact && root.count > 0 ? "  ·  " + (root.currentIndex + 1) + " / " + root.count : "")
                color: colors.muted
                font.pixelSize: PocketMetrics.bodySize
                font.family: SettingsManager.fontFamily
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Item {
                id: cardHolder
                width: root.cardW
                height: root.cardH
                anchors.horizontalCenter: parent.horizontalCenter

                GameArtCard {
                    anchors.fill: parent
                    artSource: root.artSource
                    game: root.currentGameRef
                    colors: root.colors
                }
            }

            Column {
                id: textBlock
                spacing: root.gap
                anchors.horizontalCenter: parent.horizontalCenter

                GameTitle {
                    width: Math.min(root.width - PocketMetrics.margin * 2, 900)
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.currentGameRef ? root.cleanTitle : ""
                    favorite: root.currentGameRef ? root.currentGameRef.favorite === true : false
                    showFavorite: true
                    colors: root.colors
                }

                Text {
                    text: root.anniversaryMsg
                    color: colors.accent
                    font.pixelSize: PocketMetrics.bodySize * 1.1
                    font.bold: true
                    font.family: SettingsManager.fontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(root.width - PocketMetrics.margin * 2, 800)
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    text: root.historyMsg
                    color: colors.fg
                    font.pixelSize: PocketMetrics.bodySize * 0.9
                    font.family: SettingsManager.fontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(root.width - PocketMetrics.margin * 2, 800)
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    visible: !root.compact
                    text: root.count > 0 ? ((root.currentIndex + 1) + " / " + root.count) : ""
                    color: colors.muted
                    font.pixelSize: PocketMetrics.bodySize
                    font.family: SettingsManager.fontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.count === 0
        text: Language.t("calendar_no_launches")
        color: colors.muted
        font.pixelSize: PocketMetrics.bodySize
        font.family: SettingsManager.fontFamily
    }

    Row {
        id: controlsRow
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PocketMetrics.margin
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: PocketMetrics.spacing * 2
        visible: root.count > 0

        Item {
            width: PocketMetrics.bodySize * 1.5
            height: PocketMetrics.bodySize * 1.5
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.actionIndex === 0 ? 0.2 : 1.0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

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
            model: [Language.t("action_play"), Language.t("gallery_viewer_details")]
            delegate: Text {
                readonly property bool active: index === root.actionIndex
                text: modelData
                color: active ? colors.accent : colors.muted
                font.pixelSize: PocketMetrics.bodySize
                font.bold: active
                font.family: SettingsManager.fontFamily
                scale: active ? 1.08 : 1.0

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
            }
        }

        Item {
            width: PocketMetrics.bodySize * 1.5
            height: PocketMetrics.bodySize * 1.5
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.actionIndex === 1 ? 0.2 : 1.0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

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

    Keys.onLeftPressed: {
        SoundEngine.scroll();
        root.actionIndex = 0;
    }

    Keys.onRightPressed: {
        SoundEngine.scroll();
        root.actionIndex = 1;
    }

    Keys.onPressed: {
        if (api.keys.isPrevPage(event)) {
            event.accepted = true;
            SoundEngine.scroll();
            root.stepGame(-1);
        } else if (api.keys.isNextPage(event)) {
            event.accepted = true;
            SoundEngine.scroll();
            root.stepGame(1);
        } else if (api.keys.isCancel(event)) {
            event.accepted = true;
            NavigationManager.goBack();
        } else if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.runAction();
        }
    }
}
