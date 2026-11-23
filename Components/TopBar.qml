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

    anchors.right: parent.right
    anchors.rightMargin: Math.round(PocketMetrics.margin * 0.6)
    height: contentRow.height
    width: contentRow.width

    readonly property real bandHeight: Math.round(Math.min(PocketMetrics.headerHeight,
                                                           (parent ? parent.height : 0) * 0.10))
    readonly property real bandCenter: bandHeight / 2
    y: Math.max(Math.round(PocketMetrics.margin * 0.15), Math.round(bandCenter - height / 2))

    readonly property var colors: SettingsManager.getCurrentColors()

    readonly property bool _shouldAutoHide: {
        if (!SettingsManager.topbarAutoHide) return false;
        var s = AppState.currentScreen;
        if (s === Enums.screenGameDetails) return true;
        if (s === Enums.screenCalendarDay) return true;
        if (s === Enums.screenGalleryGrid && AppState.isMediaPlaying) return true;
        return false;
    }

    readonly property bool _shouldShow: SettingsManager.topbarEnabled && !root._shouldAutoHide

    opacity: root._shouldShow ? 1.0 : 0.0
    visible: opacity > 0.01

    Behavior on opacity {
        enabled: EffectsManager.animationsEnabled
        NumberAnimation { duration: EffectsManager.dur(220); easing.type: Easing.InOutQuad }
    }

    readonly property real textSize: PocketMetrics.bodySize * SettingsManager.topbarTextSize
    readonly property real iconSize: PocketMetrics.bodySize * 1.6 * SettingsManager.topbarIconSize

    property real rowHeight: Math.max(textSize * 1.5, SettingsManager.topbarBatteryShowIcon ? iconSize : 0)
    Behavior on rowHeight {
        enabled: EffectsManager.animationsEnabled
        NumberAnimation { duration: EffectsManager.dur(220); easing.type: Easing.InOutQuad }
    }

    readonly property int activeCount:
    (SettingsManager.topbarShowClock ? 1 : 0)
    + (SettingsManager.topbarShowDate ? 1 : 0)
    + (SettingsManager.topbarBatteryShowPercent ? 1 : 0)
    + (SettingsManager.topbarBatteryShowIcon ? 1 : 0)

    TextMetrics {
        id: inkRef
        text: "H0"
        font.pixelSize: root.textSize
        font.family: SettingsManager.fontFamily
        font.bold: true
    }

    function inkCenteredY(baseline) {
        var inkCenterFromTop = baseline + inkRef.tightBoundingRect.y
        + inkRef.tightBoundingRect.height / 2;
        return Math.round(rowHeight / 2 - inkCenterFromTop);
    }

    function pad2(n) { return (n < 10 ? "0" : "") + n; }

    function formatClock() {
        var d = new Date();
        var h = d.getHours();
        var m = d.getMinutes();
        if (SettingsManager.topbar24hFormat) {
            return pad2(h) + ":" + pad2(m);
        }
        var ampm = h >= 12 ? "PM" : "AM";
        var h12 = h % 12;
        h12 = h12 ? h12 : 12;
        return h12 + ":" + pad2(m) + " " + ampm;
    }

    function formatDate() {
        var d = new Date();
        var dd = pad2(d.getDate());
        var mm = pad2(d.getMonth() + 1);
        var yy = pad2(d.getFullYear() % 100);
        var yyyy = d.getFullYear();
        switch (SettingsManager.topbarDateFormat) {
            case "MM/DD/YY": return mm + "/" + dd + "/" + yy;
            case "YYYY-MM-DD": return yyyy + "-" + mm + "-" + dd;
            case "YYYY/MM/DD": return yyyy + "/" + mm + "/" + dd;
            default: return dd + "/" + mm + "/" + yy;
        }
    }

    QtObject {
        id: batteryPoller
        property int cachedPercent: 0
        property bool cachedCharging: false
        property bool hasBattery: false

        function poll() {
            var pct = api.device.batteryPercent;
            if (!isNaN(pct)) {
                hasBattery = true;
                cachedPercent = Math.round(pct * 100);
                cachedCharging = api.device.batteryCharging;
            } else {
                hasBattery = false;
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: batteryPoller.poll()
    }

    Connections {
        target: api.device
        function onBatteryChargingChanged() { batteryPoller.poll() }
        function onBatteryPercentChanged() { batteryPoller.poll() }
    }

    property string _clockText: formatClock()
    property string _dateText: formatDate()

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            root._clockText = root.formatClock();
            root._dateText = root.formatDate();
        }
    }

    Row {
        id: contentRow
        anchors.top: parent.top
        anchors.right: parent.right
        height: root.rowHeight
        spacing: 0

        component AnimatedItem: Item {
            property bool shown: true
            property real naturalWidth: 0

            readonly property real gap: Math.round(root.textSize * 0.9)
            property real _w: shown ? naturalWidth + gap : 0
            Behavior on _w {
                enabled: EffectsManager.animationsEnabled
                NumberAnimation { duration: EffectsManager.dur(220); easing.type: Easing.InOutQuad }
            }

            width: Math.round(_w)
            opacity: shown ? 1.0 : 0.0
            visible: opacity > 0.01
            clip: true

            Behavior on opacity {
                enabled: EffectsManager.animationsEnabled
                NumberAnimation { duration: EffectsManager.dur(220); easing.type: Easing.InOutQuad }
            }
        }

        AnimatedItem {
            shown: SettingsManager.topbarShowClock
            height: parent.height
            naturalWidth: clockText.implicitWidth

            Text {
                id: clockText
                anchors.right: parent.right
                text: root._clockText
                color: root.colors.fg
                font.pixelSize: root.textSize
                font.family: SettingsManager.fontFamily
                font.bold: true
                y: root.inkCenteredY(baselineOffset)
            }
        }

        AnimatedItem {
            shown: SettingsManager.topbarShowDate
            height: parent.height
            naturalWidth: dateText.implicitWidth

            Text {
                id: dateText
                anchors.right: parent.right
                text: root._dateText
                color: root.colors.fg
                font.pixelSize: root.textSize
                font.family: SettingsManager.fontFamily
                font.bold: true
                y: root.inkCenteredY(baselineOffset)
            }
        }

        AnimatedItem {
            shown: SettingsManager.topbarBatteryShowPercent
            height: parent.height
            naturalWidth: batteryText.implicitWidth

            Text {
                id: batteryText
                anchors.right: parent.right
                text: (batteryPoller.hasBattery
                ? batteryPoller.cachedPercent + "%"
                : Language.t("settings_topbar_ac_label"))
                color: root.colors.fg
                font.pixelSize: root.textSize
                font.family: SettingsManager.fontFamily
                font.bold: true
                y: root.inkCenteredY(baselineOffset)
            }
        }

        AnimatedItem {
            shown: SettingsManager.topbarBatteryShowIcon
            height: parent.height
            naturalWidth: root.iconSize

            Image {
                id: batteryIcon
                anchors.right: parent.right
                width: root.iconSize
                height: root.iconSize
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                smooth: true

                sourceSize.width: root.iconSize > 0 ? Math.round(root.iconSize) : 128
                sourceSize.height: root.iconSize > 0 ? Math.round(root.iconSize) : 128

                layer.enabled: EffectsManager.shaderEffectsEnabled
                layer.smooth: true
                layer.effect: ColorOverlay {
                    color: root.colors.fg
                }

                readonly property int iconIndex: {
                    if (batteryPoller.cachedCharging)
                        return Math.min(10, Math.round(batteryPoller.cachedPercent / 10));
                    return Math.min(9, Math.floor(batteryPoller.cachedPercent / 10));
                }

                property bool loadFailed: false

                source: {
                    if (loadFailed || !batteryPoller.hasBattery)
                        return Qt.resolvedUrl("../assets/icons/no_battery.svg");
                    if (batteryPoller.cachedCharging)
                        return Qt.resolvedUrl("../assets/icons/battery/charging/fluent--battery-charge-" + iconIndex + "-20-regular.svg");
                    return Qt.resolvedUrl("../assets/icons/battery/not-charging/fluent--battery-" + iconIndex + "-20-regular.svg");
                }

                onIconIndexChanged: loadFailed = false

                onStatusChanged: {
                    if (status === Image.Error)
                        loadFailed = true;
                }
            }
        }
    }
}
