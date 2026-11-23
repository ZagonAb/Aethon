// Aethon
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
import QtQuick 2.15
import "../App"

Item {
    id: mq

    property string text: ""
    property color color: "white"
    property real pixelSize: 12
    property bool bold: false

    property bool active: true

    property int waitDuration: 1500
    property real msPerPixel: 22

    property bool provideImplicitSize: false
    property int padVertical: 2

    property bool outlineEnabled: false
    property color outlineColor: "#000000"
    property int horizontalAlignment: Text.AlignLeft

    readonly property real textWidth: t1.implicitWidth
    readonly property bool needsScroll:
    t1.implicitWidth > mq.width && EffectsManager.marqueeEnabled
    property real scrollOffset: 0
    readonly property real cycleWidth: t1.implicitWidth + sep.implicitWidth
    property bool isWaiting: true

    implicitWidth: mq.provideImplicitSize ? t1.implicitWidth : 0
    implicitHeight: mq.provideImplicitSize ? t1.implicitHeight : 0
    height: t1.implicitHeight
    clip: true

    Timer {
        id: waitTimer
        interval: mq.waitDuration
        repeat: false
        onTriggered: {
            mq.isWaiting = false;
            if (mq.needsScroll) anim.start();
        }
    }

    NumberAnimation {
        id: anim
        target: mq
        property: "scrollOffset"
        from: 0
        to: mq.cycleWidth
        duration: Math.max(1, mq.cycleWidth * mq.msPerPixel)
        easing.type: Easing.Linear
        loops: Animation.Infinite
        running: false
    }

    Text {
        id: t1
        text: mq.text
        color: mq.color
        font.pixelSize: mq.pixelSize
        font.bold: mq.bold
        font.family: SettingsManager.fontFamily
        x: -mq.scrollOffset
        width: (mq.needsScroll && !mq.isWaiting) ? implicitWidth : mq.width
        elide: (mq.needsScroll && !mq.isWaiting) ? Text.ElideNone : Text.ElideRight
        wrapMode: Text.NoWrap
        horizontalAlignment: mq.horizontalAlignment
        topPadding: mq.padVertical
        bottomPadding: mq.padVertical
        style: mq.outlineEnabled ? Text.Outline : Text.Normal
        styleColor: mq.outlineColor
    }

    Text {
        id: sep
        text: "  •  "
        color: mq.color
        font.pixelSize: mq.pixelSize
        font.bold: mq.bold
        font.family: SettingsManager.fontFamily
        x: t1.implicitWidth - mq.scrollOffset
        visible: mq.needsScroll && !mq.isWaiting
        topPadding: mq.padVertical
        bottomPadding: mq.padVertical
        style: mq.outlineEnabled ? Text.Outline : Text.Normal
        styleColor: mq.outlineColor
    }

    Text {
        id: t2
        text: mq.text
        color: mq.color
        font.pixelSize: mq.pixelSize
        font.bold: mq.bold
        font.family: SettingsManager.fontFamily
        x: t1.implicitWidth + sep.implicitWidth - mq.scrollOffset
        visible: mq.needsScroll && !mq.isWaiting
        topPadding: mq.padVertical
        bottomPadding: mq.padVertical
        style: mq.outlineEnabled ? Text.Outline : Text.Normal
        styleColor: mq.outlineColor
    }

    function reset() {
        anim.stop();
        waitTimer.stop();
        mq.scrollOffset = 0;
        mq.isWaiting = true;
        if (mq.active) waitTimer.restart();
    }

    onActiveChanged: reset()
    onTextChanged: reset()
    onWidthChanged: reset()
    onWaitDurationChanged: reset()

    onNeedsScrollChanged: {
        if (!mq.needsScroll) {
            anim.stop();
            waitTimer.stop();
            mq.scrollOffset = 0;
            mq.isWaiting = true;
        }
    }

    Component.onCompleted: reset()
}
