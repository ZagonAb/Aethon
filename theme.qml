// Aethon
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/

import QtQuick 2.15
import "App"
import "Layout"
import "Components"
import "Screens"

FocusScope {
    id: root
    width: 1280
    height: 720
    focus: true

    property bool debugOverlayVisible: false
    property bool particlesReady: false
    property int _fpsCounter: 0
    property int _fpsDisplay: 0
    property double _l1PressTime: 0
    property double _r1PressTime: 0
    property double _lastChordTime: 0
    property real particleScale: 0.5
    property int particleFrameMs: 33

    Binding { target: ResponsiveManager; property: "windowWidth"; value: root.width }
    Binding { target: ResponsiveManager; property: "windowHeight"; value: root.height }

    ResolutionPresets {
        id: resolutionPresets
        windowWidth: root.width
        windowHeight: root.height
    }

    readonly property var colors: SettingsManager.getCurrentColors()

    Rectangle {
        anchors.fill: parent
        color: colors.bg
    }

    Loader {
        id: backgroundEffect
        anchors.fill: parent

        active: EffectsManager.particlesEnabled && root.particlesReady

        opacity: root.particlesReady ? 1.0 : 0.0
        Behavior on opacity {
            enabled: EffectsManager.animationsEnabled
            NumberAnimation {
                duration: EffectsManager.dur(splash.revealDuration)
                easing.type: Easing.OutQuad
            }
        }

        sourceComponent: {
            switch (EffectsManager.backgroundEffect) {
                case "ribbon": return ribbonComponent;
                case "digitalrain": return digitalRainComponent;
                case "starfield": return starfieldComponent;
                case "hexgrid": return hexgridComponent;
                case "softbokeh": return softBokehComponent;
                case "retrogrid": return retroGridComponent;
                default: return abyssalComponent;
            }
        }

        Component {
            id: abyssalComponent
            ShaderEffect {
                anchors.fill: parent
                blending: true
                opacity: EffectsManager.backgroundAlpha
                fragmentShader: Qt.resolvedUrl("assets/shaders/abyssal_drift.frag")

                layer.enabled: true
                layer.smooth: true
                layer.textureSize: Qt.size(
                    Math.max(1, Math.round(width * root.particleScale)),
                                           Math.max(1, Math.round(height * root.particleScale)))

                property real time: 0.0

                Timer {
                    interval: root.particleFrameMs
                    repeat: true
                    running: root.particlesReady && EffectsManager.particlesEnabled
                    && EffectsManager.backgroundAnimated
                    property double last: 0
                    onRunningChanged: if (running) last = Date.now()
                    onTriggered: {
                        var now = Date.now();
                        parent.time = (parent.time + (now - last) / 100000) % 1.0;
                        last = now;
                    }
                }

                property real aspectRatio: width / Math.max(1.0, height)
                property real density: 5.0
                property real drift: 16.0
                property real intensity: 1.2
                property real fadeIn: 0.25
                property real fadeOut: 0.5
                property real centerFocus: 0.15
                property color particleColor: root.colors.accent
            }
        }

        Component {
            id: ribbonComponent
            ShaderEffect {
                anchors.fill: parent
                blending: true
                opacity: EffectsManager.backgroundAlpha
                mesh: GridMesh { resolution: Qt.size(160, 24) }

                vertexShader: Qt.resolvedUrl("assets/shaders/ribbon.vert")
                fragmentShader: Qt.resolvedUrl("assets/shaders/ribbon.frag")

                property real uTime: 0.0
                property color uRibbonColor: root.colors.accent
                property real uIntensity: 1.0
                property real waveSpeed: 0.75
                property real uThickness: 0.85

                readonly property real _cycleMs: 600000 / Math.max(waveSpeed, 0.01)

                Timer {
                    interval: root.particleFrameMs
                    repeat: true
                    running: root.particlesReady && EffectsManager.particlesEnabled
                    && EffectsManager.backgroundAnimated
                    property double last: 0
                    onRunningChanged: if (running) last = Date.now()
                    onTriggered: {
                        var now = Date.now();
                        parent.uTime = (parent.uTime + (now - last) * 628.3185 / parent._cycleMs) % 628.3185;
                        last = now;
                    }
                }
            }
        }

        Component {
            id: digitalRainComponent
            ShaderEffect {
                anchors.fill: parent
                blending: true
                opacity: EffectsManager.backgroundAlpha
                fragmentShader: Qt.resolvedUrl("assets/shaders/digitalrain.frag")

                property real uTime: 0.0
                property vector2d uResolution: Qt.vector2d(width, height)
                property color uMatrixColor: root.colors.accent
                property real uDensity: 55.0
                property real uSpeed: 0.3
                property real uCenterAlpha: 0.5
                property real uEdgeAlpha: 0.025
                property real uCenterWidth: 0.025

                readonly property real _ratePerMs: 1000 * uSpeed / 400000

                Timer {
                    interval: root.particleFrameMs
                    repeat: true
                    running: root.particlesReady && EffectsManager.particlesEnabled
                    && EffectsManager.backgroundAnimated
                    property double last: 0
                    onRunningChanged: if (running) last = Date.now()
                    onTriggered: {
                        var now = Date.now();
                        parent.uTime = (parent.uTime + (now - last) * parent._ratePerMs) % 1000.0;
                        last = now;
                    }
                }
            }
        }

        Component {
            id: starfieldComponent
            ShaderEffect {
                anchors.fill: parent
                blending: true
                opacity: EffectsManager.backgroundAlpha

                fragmentShader: Qt.resolvedUrl("assets/shaders/starfield.frag")

                layer.enabled: true
                layer.smooth: true
                layer.textureSize: Qt.size(
                    Math.max(1, Math.round(width * root.particleScale)),
                                           Math.max(1, Math.round(height * root.particleScale)))

                property real uTime: 0.0
                property vector2d uResolution: Qt.vector2d(
                    width * root.particleScale,
                    height * root.particleScale)

                property color uStarColor: root.colors.accent

                property real uHeadSize: 1.0
                property real uHeadBrightness: 0.85
                property real uTrailLength: 1.2
                property real uDensity: 1.3
                property real uSpeed: 0.7
                property real uCenterAlpha: 0.90
                property real uEdgeAlpha: 0.05
                property real uCenterWidth: 1.0
                property real uCenterHole: 0.05

                readonly property real _ratePerMs: 1000 * uSpeed / 500000

                Timer {
                    interval: root.particleFrameMs
                    repeat: true
                    running: root.particlesReady && EffectsManager.particlesEnabled
                    && EffectsManager.backgroundAnimated
                    property double last: 0
                    onRunningChanged: if (running) last = Date.now()
                    onTriggered: {
                        var now = Date.now();
                        parent.uTime = (parent.uTime + (now - last) * parent._ratePerMs) % 1000.0;
                        last = now;
                    }
                }
            }
        }

        Component {
            id: hexgridComponent
            ShaderEffect {
                anchors.fill: parent
                blending: true
                opacity: EffectsManager.backgroundAlpha

                fragmentShader: Qt.resolvedUrl("assets/shaders/hexgrid.frag")

                readonly property color _bg: root.colors.bg
                readonly property color _accent: root.colors.accent
                readonly property color _fg: root.colors.fg
                function _lum(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b; }
                readonly property bool _accentUsable:
                Math.abs(_lum(_accent) - _lum(_bg)) >= 0.12

                readonly property color _base: _accentUsable ? _accent : _fg
                readonly property color _pulse: Qt.rgba(
                    _base.r * 0.65 + _fg.r * 0.35,
                    _base.g * 0.65 + _fg.g * 0.35,
                    _base.b * 0.65 + _fg.b * 0.35, 1.0)

                readonly property real _contrast: Math.abs(_lum(_base) - _lum(_bg))
                readonly property real _boost: Math.max(1.0, Math.min(2.2, 0.40 / Math.max(_contrast, 0.05)))

                property color uHexColor: _base
                property color uPulseColor: _pulse
                Behavior on uHexColor   { ColorAnimation { duration: EffectsManager.dur(250) } }
                Behavior on uPulseColor { ColorAnimation { duration: EffectsManager.dur(250) } }

                property vector2d uResolution: Qt.vector2d(width, height)

                property real uGridBrightness: 0.22 * _boost
                property real uPulseBrightness: 0.40 * _boost
                property real uRimBrightness: 0.35 * _boost
                property real uWave: 0.45
                property real uLineWidth: 0.022
                property real uCellGap: 0.07
                property real uScale: 5.0
                property real uCenterAlpha: 0.85
                property real uEdgeAlpha: 0.25
                property real uPhase: 0.0
                property real uSpeed: 1.2
                readonly property real _msPerLoop: 60000 / Math.max(uSpeed, 0.01)

                Timer {
                    interval: root.particleFrameMs
                    repeat: true
                    running: root.particlesReady && EffectsManager.particlesEnabled
                    && EffectsManager.backgroundAnimated
                    property double last: 0
                    onRunningChanged: if (running) last = Date.now()
                    onTriggered: {
                        var now = Date.now();
                        parent.uPhase = (parent.uPhase + (now - last) / parent._msPerLoop) % 1.0;
                        last = now;
                    }
                }
            }
        }

        Component {
            id: softBokehComponent
            ShaderEffect {
                anchors.fill: parent
                blending: true
                opacity: EffectsManager.backgroundAlpha

                fragmentShader: Qt.resolvedUrl("assets/shaders/softbokeh.frag")

                readonly property real renderScale: 0.25
                layer.enabled: true
                layer.smooth: true
                layer.textureSize: Qt.size(
                    Math.max(1, Math.round(width * renderScale)),
                                           Math.max(1, Math.round(height * renderScale)))

                readonly property int frameMs: Math.max(root.particleFrameMs, 66)

                property real uTime: 0.0
                property vector2d uResolution: Qt.vector2d(width, height)

                property color uColorPrimary: root.colors.accent
                property color uColorSecondary: root.colors.fg

                property real uSize: 0.40
                property real uDensity: 1.2
                property real uBlur: 0.8
                property real uSpeed: 0.25
                property real uAlpha: 1.0

                readonly property real _ratePerMs: 1000 * uSpeed / 600000

                Timer {
                    interval: parent.frameMs
                    repeat: true
                    running: root.particlesReady && EffectsManager.particlesEnabled
                    && EffectsManager.backgroundAnimated
                    property double last: 0
                    onRunningChanged: if (running) last = Date.now()
                    onTriggered: {
                        var now = Date.now();
                        parent.uTime = (parent.uTime + (now - last) * parent._ratePerMs) % 1000.0;
                        last = now;
                    }
                }
            }
        }

        Component {
            id: retroGridComponent
            ShaderEffect {
                anchors.fill: parent
                blending: true
                opacity: EffectsManager.backgroundAlpha

                fragmentShader: Qt.resolvedUrl("assets/shaders/retrogrid.frag")

                property real uTime: 0.0
                property vector2d uResolution: Qt.vector2d(width, height)

                property color uGridColor: root.colors.accent
                property color uHorizonColor: root.colors.accent

                property real uHorizonY: 0.48
                property real uGridScale: 2.4
                property real uLineWidth: 0.038
                property real uSpeed: 0.5
                property real uCenterAlpha: 0.90
                property real uEdgeAlpha: 0.10
                property real uCenterWidth: 0.35

                readonly property real _ratePerMs: 1000 * uSpeed / 400000

                Timer {
                    interval: root.particleFrameMs
                    repeat: true
                    running: root.particlesReady && EffectsManager.particlesEnabled
                    && EffectsManager.backgroundAnimated
                    property double last: 0
                    onRunningChanged: if (running) last = Date.now()
                    onTriggered: {
                        var now = Date.now();
                        parent.uTime = (parent.uTime + (now - last) * parent._ratePerMs) % 1000.0;
                        last = now;
                    }
                }
            }
        }
    }

    Loader {
        id: screenLoader
        anchors.fill: parent
        enabled: !splash.running && !NavigationManager.latched
        transform: Translate { id: screenSlide; x: 0 }

        source: {
            switch (AppState.currentScreen) {
                case Enums.screenHome: return "Screens/Home.qml";
                case Enums.screenLibrary: return "Screens/Library.qml";
                case Enums.screenGameDetails: return "Screens/GameDetails.qml";
                case Enums.screenSearch: return "Screens/Search.qml";
                case Enums.screenSettings: return "Screens/Settings.qml";
                case Enums.screenMemories: return "Screens/Memories.qml";
                case Enums.screenTools: return "Screens/Tools.qml";
                case Enums.screenRACredentials: return "Screens/RACredentials.qml";
                case Enums.screenAchievements: return "Screens/Achievements.qml";
                case Enums.screenRAGames: return "Screens/RAGames.qml";
                case Enums.screenGalleryList: return "Screens/GalleryList.qml";
                case Enums.screenGalleryGrid: return "Screens/GalleryGrid.qml";
                case Enums.screenCalendar: return "Screens/Calendar.qml";
                case Enums.screenCalendarDay: return "Screens/CalendarDay.qml";
                case Enums.screenWeather: return "Screens/Weather.qml";
                case Enums.screenWeatherSettings: return "Screens/WeatherSettings.qml";
                case Enums.screenMetadataInspector: return "Screens/MetadataInspector.qml";
                case Enums.screenMetadataList: return "Screens/MetadataList.qml";
                case Enums.screenGameInspector: return "Screens/GameInspector.qml";
                case Enums.screenAbout: return "Screens/About.qml";
                case Enums.screenStatistics: return "Screens/Statistics.qml";
                default: return "Screens/Placeholder.qml";
            }
        }

        onLoaded: {
            if (item) {
                if (splash.running) splash.forceActiveFocus();
                else item.forceActiveFocus();
            }
            if (splash.running) {
                if (!splash.revealing) screenLoader.opacity = 0;
                return;
            }
            if (EffectsManager.animationsEnabled) {
                screenSlideIn.from = NavigationManager.lastDirection > 0
                ? PocketMetrics.animationDistance
                : -PocketMetrics.animationDistance;
                screenSlideIn.restart();
                screenFadeIn.restart();
            } else {
                screenSlide.x = 0;
                screenLoader.opacity = 1;
            }
        }
    }

    TopBar {
        id: topBar
        z: 100
    }

    HintBar {
        visible: NavigationManager.isGameListVisible() && !splash.running
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: Math.max(4, Math.round(PocketMetrics.margin * 0.25))
        anchors.bottomMargin: Math.max(2, Math.round(PocketMetrics.margin * 0.1))
        width: parent.width - anchors.leftMargin * 2
        z: 50
        text: Language.t("hint_random_game")
    }

    NumberAnimation {
        id: homeRevealAnim
        target: screenLoader
        property: "opacity"
        from: 0
        to: 1
        duration: EffectsManager.dur(splash.revealDuration)
        easing.type: Easing.OutQuad
        onStarted: root.particlesReady = true
    }

    NumberAnimation {
        id: screenSlideIn
        target: screenSlide
        property: "x"
        to: 0
        duration: EffectsManager.dur(200)
        easing.type: Easing.OutQuad
    }

    NumberAnimation {
        id: screenFadeIn
        target: screenLoader
        property: "opacity"
        from: 0
        to: 1
        duration: EffectsManager.dur(180)
        easing.type: Easing.OutQuad
    }

    Screensaver {
        id: screensaver
        enabled: SettingsManager.screensaverEnabled && !AppState.isMediaPlaying
        onDeactivated: {
            if (screenLoader.item) screenLoader.item.forceActiveFocus();
            else root.forceActiveFocus();
        }
    }

    Connections {
        target: AppState
        function onCurrentScreenChanged() { screensaver.reset(); }
        function onCurrentSectionChanged() { screensaver.reset(); }
        function onCurrentCollectionChanged() { screensaver.reset(); }
        function onCurrentCategoryValueChanged() { screensaver.reset(); }
        function onCurrentGameIndexChanged() { screensaver.reset(); }
        function onGalleryListIndexChanged() { screensaver.reset(); }
        function onGalleryGridIndexChanged() { screensaver.reset(); }
        function onGalleryAssetKeyChanged() { screensaver.reset(); }
        function onToolsIndexChanged() { screensaver.reset(); }
        function onHomeIndexChanged() { screensaver.reset(); }
        function onCalendarSelectedDateChanged() { screensaver.reset(); }
    }

    Connections {
        target: NavigationManager
        function onUserInteracted() { screensaver.reset(); }
    }

    Connections {
        target: Qt.inputMethod
        function onVisibleChanged() {
            if (Qt.inputMethod.visible) {
                console.log("[Theme] Android native keyboard detected, hiding it.");
                Qt.inputMethod.hide();
            }
        }
    }

    Keys.onPressed: {
        if (splash.running) {
            splash.skip();
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_F12 && !event.isAutoRepeat) {
            root.debugOverlayVisible = !root.debugOverlayVisible;
            event.accepted = true;
            return;
        }

        if (NavigationManager.relay(event, true)) {
            event.accepted = true;
            return;
        }

        var _now = Date.now();
        if (api.keys.isPrevPage(event) && !event.isAutoRepeat) {
            root._l1PressTime = _now;
            if (_now - root._r1PressTime < 150
                && _now - root._lastChordTime > 400) {
                root._lastChordTime = _now;
            if (NavigationManager.enterRandomGame()) {
                event.accepted = true;
                return;
            }
                }
        }
        if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
            root._r1PressTime = _now;
            if (_now - root._l1PressTime < 150
                && _now - root._lastChordTime > 400) {
                root._lastChordTime = _now;
            if (NavigationManager.enterRandomGame()) {
                event.accepted = true;
                return;
            }
                }
        }

        screensaver.reset();
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            var handled = NavigationManager.goBack();
            event.accepted = handled;
        } else if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            NavigationManager.handleDetails();
        } else if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            NavigationManager.handleFilters();
        }
    }

    Keys.onReleased: function(event) {
        if (splash.running) return;
        if (NavigationManager.relay(event, false)) event.accepted = true;
    }

    Component.onCompleted: {
        SettingsManager.load();

        if (!FontManager.canonical(SettingsManager.fontChoice)) {
            SettingsManager.fontChoice = FontManager.defaultLabel;
            SettingsManager.save();
        }

        resolutionPresets.initialize();
        Persistence.restore();
        splashInitTimer.start();
    }

    Rectangle {
        id: debugOverlay
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Math.min(12, Math.round(Math.min(root.width, root.height) * 0.03))
        width: Math.min(parent.width - anchors.margins * 2, 520)
        height: debugColumn.implicitHeight + 16
        color: "#000000"
        opacity: 0.85
        radius: 4
        visible: root.debugOverlayVisible

        readonly property real debugFontSize: Math.max(8, Math.min(12, Math.round(root.height / 40)))

        Column {
            id: debugColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 1

            Text {
                width: parent.width
                text: "screen:" + Enums.screenName(AppState.currentScreen)
                + "  section:" + Enums.sectionName(AppState.currentSection)
                + "  depth:" + NavigationManager.depth
                color: "#7fffd4"
                font.pixelSize: debugOverlay.debugFontSize
                font.family: SettingsManager.fontFamily
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                elide: Text.ElideRight
                maximumLineCount: 2
            }
            Text {
                width: parent.width
                text: "collection:" + (AppState.currentCollection ? AppState.currentCollection.name : "-")
                + "  game:" + (AppState.currentGame ? AppState.currentGame.title : "-")
                + "  index:" + AppState.currentGameIndex
                color: "#ffd47f"
                font.pixelSize: debugOverlay.debugFontSize
                font.family: SettingsManager.fontFamily
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                elide: Text.ElideRight
                maximumLineCount: 2
            }
            Text {
                width: parent.width
                text: "focus:" + Enums.focusName(FocusManager.currentFocus)
                + "  profile:" + Enums.profileName(ResponsiveManager.aspectProfile)
                + "  density:" + Enums.densityName(ResponsiveManager.density)
                color: "#7fbfff"
                font.pixelSize: debugOverlay.debugFontSize
                font.family: SettingsManager.fontFamily
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                elide: Text.ElideRight
                maximumLineCount: 2
            }
            Text {
                width: parent.width
                text: "res:" + Math.round(root.width) + "x" + Math.round(root.height)
                + "  context:" + SettingsManager.activeContext
                + "  override:" + (SettingsManager.hasOverrideForActiveContext() ? "yes" : "no")
                color: "#ff9f7f"
                font.pixelSize: debugOverlay.debugFontSize
                font.family: SettingsManager.fontFamily
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                elide: Text.ElideRight
                maximumLineCount: 2
            }
            Text {
                width: parent.width
                text: "FPS: " + root._fpsDisplay
                + "  |  Metadata Scan: " + Math.round(MetadataEngine.lastScanTimeMs) + " ms"
                color: "#ff6b6b"
                font.pixelSize: debugOverlay.debugFontSize
                font.bold: true
                font.family: SettingsManager.fontFamily
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                elide: Text.ElideRight
                maximumLineCount: 2
            }
        }
    }

    HintStrip {
        host: screenLoader
        z: 9996
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.debugOverlayVisible
        onTriggered: {
            root._fpsDisplay = root._fpsCounter;
            root._fpsCounter = 0;
        }
    }

    Timer {
        interval: 16
        repeat: true
        running: root.debugOverlayVisible
        onTriggered: root._fpsCounter++
    }

    Timer {
        id: splashInitTimer
        interval: 50
        running: false
        repeat: false
        onTriggered: {
            resolutionPresets.evaluate();

            var effectiveSplash = SettingsManager.splashStyle;
            if (effectiveSplash === "auto") {
                effectiveSplash = (SettingsManager.activeContext === "tiny4x3") ? "zero" : "classic";
            }

            if (effectiveSplash === "off") {
                splash.splashOff = true;
                splash.source = "";
                Qt.callLater(function() {
                    SoundEngine.warmUp();
                    if (screenLoader.item) screenLoader.item.forceActiveFocus();
                    else root.forceActiveFocus();
                    homeRevealAnim.start();
                });
            } else {
                splash.splashOff = false;
                if (effectiveSplash !== "zero") FontManager.requireSplashFont();
                if (effectiveSplash === "isotipo") splash.source = "Components/IsotipoSplashScreen.qml";
                else if (effectiveSplash === "zero") splash.source = "Components/ZeroSplashScreen.qml";
                else splash.source = "Components/SplashScreen.qml";
            }
        }
    }

    Loader {
        id: splash
        anchors.fill: parent
        z: 9998

        property bool splashOff: false

        readonly property bool running: splash.splashOff ? false : (item ? item.running : true)
        readonly property bool revealing: item ? item.revealing : false
        readonly property int revealDuration: item ? item.revealDuration : 1600

        function skip() { if (item) item.skip(); }
        function forceActiveFocus() { if (item) item.forceActiveFocus(); }

        onLoaded: {
            if (!item) return;
            item.fontFamily = Qt.binding(function() { return FontManager.splashFamily; });

            item.revealStarted.connect(homeRevealAnim.restart);
            item.finished.connect(function() {
                root.particlesReady = true;
                SoundEngine.warmUp();
                if (screenLoader.item)
                    screenLoader.item.forceActiveFocus();
                else
                    root.forceActiveFocus();
            });
        }
    }
}
