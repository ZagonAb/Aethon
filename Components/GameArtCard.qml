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

    property var game: null
    property string artSource: ""
    property var colors: SettingsManager.getCurrentColors()
    property real decodeScale: 1.0

    readonly property string effectiveSource: {
        var _rev = GalleryCacheEngine.revision;
        if (!root.artSource) return "";
        if (GalleryCacheEngine.isBad(root.artSource)) return "";
        return root.artSource;
    }

    readonly property bool hasPrimaryArt: root.effectiveSource !== "" && artImage.status === Image.Ready
    readonly property bool primaryLoading: root.effectiveSource !== "" && artImage.status === Image.Loading

    property bool _graceExpired: false
    onPrimaryLoadingChanged: if (!primaryLoading) _graceExpired = false

    Timer {
        interval: 150
        running: root.primaryLoading
        onTriggered: root._graceExpired = true
    }

    readonly property bool _showFallback: !hasPrimaryArt && (!primaryLoading || _graceExpired)

    readonly property string fallbackSource: root.game ? GameUtils.getSystemFallback(root.game) : ""
    readonly property bool hasFallbackArt: _showFallback && fallbackSource !== "" && fallbackImage.status === Image.Ready
    readonly property bool hasArt: hasPrimaryArt || hasFallbackArt
    readonly property bool _useDropShadow: EffectsManager.shadowsEnabled && EffectsManager.shaderEffectsEnabled
    readonly property bool _useFlatShadow: EffectsManager.shadowsEnabled && !EffectsManager.shaderEffectsEnabled
    readonly property real _flatShadowOffset: Math.max(1, Math.round(root.width * 0.02))
    readonly property bool _primaryVisible: !root._useDropShadow
    readonly property bool _fallbackVisible: !root._useDropShadow

    Image {
        id: artImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        asynchronous: true

        source: root.width > 0 ? root.effectiveSource : ""
        sourceSize.width: root.width > 0 ? Math.round(root.width * root.decodeScale) : 0
        sourceSize.height: root.height > 0 ? Math.round(root.height * root.decodeScale) : 0

        visible: root._primaryVisible

        onStatusChanged: {
            if (status === Image.Error && source !== "") {
                if (!GalleryCacheEngine.isRemote(source)) {
                    var badUrl = source;
                    Qt.callLater(function() {
                        GalleryCacheEngine.markBad(badUrl);
                    });
                }
            }
        }
    }

    Rectangle {
        visible: root._useFlatShadow && root.hasPrimaryArt
        x: Math.round((root.width - artImage.paintedWidth) / 2) + root._flatShadowOffset
        y: Math.round((root.height - artImage.paintedHeight) / 2) + root._flatShadowOffset
        width: Math.round(artImage.paintedWidth)
        height: Math.round(artImage.paintedHeight)
        color: "#99000000"
    }

    DropShadow {
        anchors.fill: artImage
        source: artImage
        visible: root._useDropShadow && root.hasPrimaryArt
        horizontalOffset: 4
        verticalOffset: 7
        radius: 14
        samples: 29
        color: "#99000000"
        transparentBorder: true
    }

    Image {
        id: fallbackImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        asynchronous: true

        source: root.width > 0 ? root.fallbackSource : ""
        sourceSize.width: root.width > 0 ? Math.round(root.width * root.decodeScale) : 0
        sourceSize.height: root.height > 0 ? Math.round(root.height * root.decodeScale) : 0

        visible: root._fallbackVisible && root._showFallback
    }

    Rectangle {
        visible: root._useFlatShadow && root.hasFallbackArt
        x: Math.round((root.width - fallbackImage.paintedWidth) / 2) + root._flatShadowOffset
        y: Math.round((root.height - fallbackImage.paintedHeight) / 2) + root._flatShadowOffset
        width: Math.round(fallbackImage.paintedWidth)
        height: Math.round(fallbackImage.paintedHeight)
        color: "#99000000"
    }

    DropShadow {
        anchors.fill: fallbackImage
        source: fallbackImage
        visible: root._useDropShadow && root.hasFallbackArt
        horizontalOffset: 4
        verticalOffset: 7
        radius: 14
        samples: 29
        color: "#99000000"
        transparentBorder: true
    }

    Text {
        anchors.centerIn: parent
        visible: !root.hasArt && (!root.primaryLoading || root._graceExpired)
        text: "ART"
        color: root.colors.muted
        font.pixelSize: PocketMetrics.bodySize
        font.family: SettingsManager.fontFamily
    }
}
