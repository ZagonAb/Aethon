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

FocusScope {
    id: root
    anchors.fill: parent
    focus: true

    readonly property int count: api.collections.count
    property int currentIndex: 0
    readonly property var currentCollectionRef: root.count > 0 ? api.collections.get(root.currentIndex) : null
    readonly property var colors: SettingsManager.getCurrentColors()

    Component.onCompleted: {
        if (AppState.previousCollection) {
            for (var i = 0; i < root.count; i++) {
                if (api.collections.get(i).name === AppState.previousCollection.name) {
                    root.currentIndex = i;
                    break;
                }
            }
        }
    }

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

    Column {
        id: contentColumn
        anchors.centerIn: parent
        spacing: PocketMetrics.spacing

        transform: Translate { id: contentSlide; x: 0 }

        Text {
            text: Language.t("section_systems")
            color: colors.muted
            font.pixelSize: PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Column {
            id: systemDisplayColumn
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(root.width - PocketMetrics.margin * 2, 900)
            spacing: Math.round(PocketMetrics.spacing * 0.3)

            readonly property string shortName: {
                if (!root.currentCollectionRef) return "";
                var sn = root.currentCollectionRef.shortName;
                if (sn && sn !== "")
                    return sn.toLowerCase().replace(/[\s\-_]/g, "");
                return (root.currentCollectionRef.name || "")
                .toLowerCase().replace(/[\s\-_]/g, "");
            }
            readonly property string iconUrl: {
                if (!SettingsManager.showSystemIcons) return "";
                if (systemDisplayColumn.shortName === "") return "";
                return Qt.resolvedUrl("../assets/systems/" + systemDisplayColumn.shortName + ".png");
            }
            readonly property bool showIcon: SettingsManager.showSystemIcons
            && systemDisplayColumn.iconUrl !== ""
            && systemIconImg.status === Image.Ready
            && root.currentCollectionRef !== null

            Item {
                id: iconContainer
                anchors.horizontalCenter: parent.horizontalCenter
                visible: systemIconImg.source !== "" && systemIconImg.status === Image.Ready && root.currentCollectionRef !== null
                width: visible ? PocketMetrics.titleSize * 3 : 0
                height: width

                Image {
                    id: systemIconImg
                    anchors.fill: parent
                    source: systemDisplayColumn.iconUrl
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    sourceSize.width: 512
                    sourceSize.height: 512
                    visible: !dropShadow.visible
                }

                Rectangle {
                    visible: EffectsManager.shadowsEnabled && !EffectsManager.shaderEffectsEnabled && systemIconImg.status === Image.Ready
                    x: Math.round((iconContainer.width - systemIconImg.paintedWidth) / 2) + 4
                    y: Math.round((iconContainer.height - systemIconImg.paintedHeight) / 2) + 7
                    width: Math.round(systemIconImg.paintedWidth)
                    height: Math.round(systemIconImg.paintedHeight)
                    color: "#99000000"
                }

                DropShadow {
                    id: dropShadow
                    anchors.fill: systemIconImg
                    source: systemIconImg
                    visible: EffectsManager.shadowsEnabled && EffectsManager.shaderEffectsEnabled && systemIconImg.status === Image.Ready
                    horizontalOffset: 4
                    verticalOffset: 7
                    radius: 14
                    samples: 29
                    color: "#99000000"
                    transparentBorder: true
                }
            }

            Text {
                width: parent.width
                text: root.currentCollectionRef
                ? root.currentCollectionRef.name
                : Language.t("systems_empty")
                color: colors.accent
                font.pixelSize: systemDisplayColumn.showIcon
                ? PocketMetrics.titleSize * 0.9
                : PocketMetrics.titleSize * 1.4
                font.bold: true
                font.family: SettingsManager.fontFamily
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Text {
            text: root.currentCollectionRef
            ? (root.currentCollectionRef.games.count + " " + Language.t("label_games"))
            : ""
            color: colors.fg
            font.pixelSize: PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: root.count > 0 ? ((root.currentIndex + 1) + " / " + root.count) : ""
            color: colors.muted
            font.pixelSize: PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter
        }
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

    Keys.onLeftPressed: {
        SoundEngine.scroll();
        if (root.count > 0) {
            root.lastStepDirection = -1;
            root.currentIndex = (root.currentIndex - 1 + root.count) % root.count;
        }
    }

    Keys.onRightPressed: {
        SoundEngine.scroll();
        if (root.count > 0) {
            root.lastStepDirection = 1;
            root.currentIndex = (root.currentIndex + 1) % root.count;
        }
    }

    Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (root.currentCollectionRef)
                NavigationManager.enterCollection(root.currentCollectionRef);
        }
    }
}
