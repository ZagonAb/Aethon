// Aethon
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
pragma Singleton
import QtQuick 2.15

QtObject {
    id: root

    property real windowWidth: 1920
    property real windowHeight: 1080

    readonly property bool isPortrait: windowHeight > windowWidth

    readonly property real aspectRatio: {
        if (windowWidth <= 0 || windowHeight <= 0)
            return 16 / 9;

        return isPortrait ? (windowHeight / windowWidth) : (windowWidth / windowHeight);
    }

    readonly property real shortSide: Math.min(windowWidth, windowHeight)

    readonly property real squareUpperBound: 1.2
    readonly property real classicUpperBound: 1.6

    readonly property int aspectProfile: {
        if (aspectRatio < root.squareUpperBound)
            return Enums.profileSquare;
        else if (aspectRatio < root.classicUpperBound)
            return Enums.profileClassic;
        else
            return Enums.profileWide;
    }

    readonly property real compactUpperBound: 400
    readonly property real normalUpperBound: 900
    readonly property int gridPhase: 5313

    readonly property int density: {
        if (shortSide <= root.compactUpperBound)
            return Enums.densityCompact;
        else if (shortSide <= root.normalUpperBound)
            return Enums.densityNormal;
        else
            return Enums.densityLarge;
    }

    function updateWindowSize(width, height) {
        root.windowWidth = width;
        root.windowHeight = height;
    }
}
