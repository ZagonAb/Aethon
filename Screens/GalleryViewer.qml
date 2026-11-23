// Aethon
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
import QtQuick 2.15
import QtGraphicalEffects 1.15
import QtMultimedia 5.15
import "../App"
import "../Layout"
import "../Components"

FocusScope {
    id: root
    anchors.fill: parent
    focus: false
    z: 100
    visible: false

    signal closed()
    signal navigated(int index)

    property var itemData: null
    property int itemIndex: -1
    property bool isVideo: false
    property var items: []
    readonly property var colors: SettingsManager.getCurrentColors()
    property int actionIndex: 6
    readonly property var controlsModel: ["start", "prev", "stop", "play", "next", "end", "info", "back"]
    property bool _showVolumeBar: false

    Timer {
        id: volumeHideTimer
        interval: 2000
        repeat: false
        onTriggered: root._showVolumeBar = false
    }

    function close() {
        if (!root.visible) return;
        mediaPlayer.stop();
        root.focus = false;
        root.visible = false;
        root._showVolumeBar = false;
        volumeHideTimer.stop();

        console.log("[GalleryViewer] Cerrando. Media playing -> false");
        AppState.isMediaPlaying = false;

        root.closed();
    }

    function loadItem(data, index) {
        root.itemData = data;
        root.itemIndex = index;
        root.isVideo = data ? data.isVideo : false;

        mediaPlayer.stop();
        AppState.isMediaPlaying = false;

        if (root.isVideo && data) {
            console.log("[GalleryViewer] Cargando video, forzando isMediaPlaying -> true");
            mediaPlayer.source = data.url;
            mediaPlayer.volume = SettingsManager.galleryVideoVolume;
            mediaPlayer.play();
            AppState.isMediaPlaying = true;
        }
    }

    function open(data, index) {
        root.actionIndex = 6;
        root.visible = true;
        root.loadItem(data, index);
        root.forceActiveFocus();
        root._showVolumeBar = false;
    }

    function step(delta) {
        var n = root.items ? root.items.length : 0;
        if (n < 2) return;
        var next = (root.itemIndex + delta + n) % n;
        root.loadItem(root.items[next], next);
        root.navigated(next);
    }

    function executeAction(action) {
        if (!root.itemData) return;

        if (action === "info") {
            if (root.itemData.game) {
                SoundEngine.select();
                root.close();
                NavigationManager.enterGameFromGallery(root.itemData.game);
            }
            return;
        }

        if (action === "back" || action === "stop") {
            SoundEngine.back();
            root.close();
            return;
        }

        if (action === "start") {
            SoundEngine.scroll();
            root.step(-1);
            return;
        }

        if (action === "end") {
            SoundEngine.scroll();
            root.step(1);
            return;
        }

        if (!root.isVideo) return;

        if (action === "play") {
            SoundEngine.select();
            if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                mediaPlayer.pause();
            } else {
                mediaPlayer.play();
            }
        } else if (action === "prev") {
            SoundEngine.select();
            mediaPlayer.seek(Math.max(0, mediaPlayer.position - 5000));
        } else if (action === "next") {
            SoundEngine.select();
            mediaPlayer.seek(Math.min(mediaPlayer.duration, mediaPlayer.position + 5000));
        }
    }

    function adjustVolume(delta) {
        var newVol = SettingsManager.galleryVideoVolume + delta;
        newVol = Math.max(0.0, Math.min(1.0, Math.round(newVol * 20) / 20));

        if (SettingsManager.galleryVideoVolume !== newVol) {
            SettingsManager.galleryVideoVolume = newVol;
            SettingsManager.save();
            if (mediaPlayer) mediaPlayer.volume = newVol;
        }

        root._showVolumeBar = true;
        volumeHideTimer.restart();
    }

    Rectangle {
        anchors.fill: parent
        color: colors.bg
    }

    Item {
        id: contentArea
        anchors.top: titleContainer.bottom
        anchors.topMargin: PocketMetrics.spacing
        anchors.bottom: controlsRow.top
        anchors.bottomMargin: PocketMetrics.spacing * 1.5
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: PocketMetrics.margin
        anchors.rightMargin: PocketMetrics.margin

        Image {
            id: imageItem
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            source: root.isVideo ? "" : (root.itemData ? root.itemData.url : "")
            asynchronous: true
            smooth: true
            visible: !root.isVideo
            sourceSize.width: imageItem.width > 0 ? Math.round(imageItem.width) : 0
            sourceSize.height: imageItem.height > 0 ? Math.round(imageItem.height) : 0
        }

        VideoOutput {
            id: videoOutput
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectFit
            source: mediaPlayer
            visible: root.isVideo
        }

        MediaPlayer {
            id: mediaPlayer
            autoPlay: false
            loops: MediaPlayer.Infinite
            volume: SettingsManager.galleryVideoVolume
            onError: console.warn("Video playback error:", errorString)

            onPlaybackStateChanged: {
                var playing = (root.visible && root.isVideo && playbackState === MediaPlayer.PlayingState);
                AppState.isMediaPlaying = playing;
            }
        }

        Rectangle {
            id: videoProgressBar
            x: videoOutput.contentRect.x
            y: videoOutput.contentRect.y + videoOutput.contentRect.height - height
            width: videoOutput.contentRect.width
            height: 4
            radius: 2
            color: "#40FFFFFF"
            visible: root.isVideo && videoOutput.contentRect.width > 0

            Rectangle {
                id: videoProgressFill
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: mediaPlayer.duration > 0
                ? parent.width * (mediaPlayer.position / mediaPlayer.duration)
                : 0
                radius: parent.radius
                color: colors.accent
                opacity: 0.9
            }

            Timer {
                id: progressTimer
                interval: 32
                running: root.isVideo && mediaPlayer.playbackState === MediaPlayer.PlayingState
                repeat: true
                property real lastTimestamp: 0
                onTriggered: {
                    var now = Date.now();
                    var elapsed = (now - lastTimestamp);
                    if (mediaPlayer.duration > 0) {
                        var interpolated = Math.min(mediaPlayer.position + elapsed, mediaPlayer.duration);
                        videoProgressFill.width = videoProgressBar.width * (interpolated / mediaPlayer.duration);
                    }
                    lastTimestamp = now;
                }
                onRunningChanged: if (running) lastTimestamp = Date.now();
            }
        }

        Item {
            id: volumeBarContainer
            anchors.bottom: videoProgressBar.top
            anchors.bottomMargin: PocketMetrics.spacing * 1.5
            anchors.horizontalCenter: parent.horizontalCenter
            width: contentArea.width * 0.5
            height: PocketMetrics.bodySize * 2
            visible: root._showVolumeBar && root.isVideo

            Rectangle {
                anchors.fill: parent
                color: "#80000000"
                radius: 6
            }

            TextMetrics {
                id: volTextMetrics
                font.pixelSize: PocketMetrics.bodySize * 1.2
                font.bold: true
                font.family: SettingsManager.fontFamily
                text: "100%"
            }

            Text {
                id: volText
                anchors.right: parent.right
                anchors.rightMargin: PocketMetrics.spacing * 1.5
                anchors.verticalCenter: parent.verticalCenter
                width: volTextMetrics.width
                horizontalAlignment: Text.AlignRight
                text: Math.round(SettingsManager.galleryVideoVolume * 100) + "%"
                color: colors.accent
                font.pixelSize: PocketMetrics.bodySize * 1.2
                font.bold: true
                font.family: SettingsManager.fontFamily
            }

            Rectangle {
                id: volBarTrack
                anchors.left: parent.left
                anchors.leftMargin: PocketMetrics.spacing * 1.5
                anchors.right: volText.left
                anchors.rightMargin: PocketMetrics.spacing * 1.5
                anchors.verticalCenter: parent.verticalCenter
                height: PocketMetrics.bodySize * 0.5
                radius: height / 2
                color: "#40FFFFFF"

                Rectangle {
                    width: parent.width * SettingsManager.galleryVideoVolume
                    height: parent.height
                    radius: parent.radius
                    color: colors.accent

                    Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                }
            }
        }
    }

    MarqueeText {
        id: titleContainer
        anchors.top: parent.top
        anchors.topMargin: PocketMetrics.margin
        anchors.left: parent.left
        anchors.leftMargin: PocketMetrics.margin
        width: Math.max(0, root.width * 0.5 - PocketMetrics.margin)
        text: root.itemData ? root.itemData.title : ""
        color: colors.fg
        pixelSize: PocketMetrics.titleSize
        bold: true
        active: root.visible
        waitDuration: 3000
        padVertical: 0
    }

    Row {
        id: controlsRow
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PocketMetrics.margin
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.width < 700 ? PocketMetrics.spacing * 0.8 : PocketMetrics.spacing * 1.5

        Repeater {
            model: root.controlsModel

            delegate: Item {
                id: btn
                readonly property bool active: index === root.actionIndex
                readonly property bool isVideoControl: ["prev", "play", "next"].includes(modelData)

                width: root.width < 700 ? PocketMetrics.bodySize * 1.2 : PocketMetrics.bodySize * 1.5
                height: width
                anchors.verticalCenter: parent.verticalCenter

                scale: active ? 1.15 : 1.0
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

                property string iconName: {
                    if (modelData === "play") {
                        return mediaPlayer.playbackState === MediaPlayer.PlayingState ? "player-pause.svg" : "player-play.svg";
                    }
                    if (modelData === "start") return "player-start.svg";
                    if (modelData === "prev") return "player-previous.svg";
                    if (modelData === "stop") return "player-stop.svg";
                    if (modelData === "next") return "player-next.svg";
                    if (modelData === "end") return "player-end.svg";
                    if (modelData === "info") return "player-info.svg";
                    if (modelData === "back") return "player-back.svg";
                    return "";
                }

                property string fallbackText: {
                    if (modelData === "start") return "Start";
                    if (modelData === "prev") return "Prev";
                    if (modelData === "stop") return "Stop";
                    if (modelData === "play") return mediaPlayer.playbackState === MediaPlayer.PlayingState ? "Pause" : "Play";
                    if (modelData === "next") return "Next";
                    if (modelData === "end") return "End";
                    if (modelData === "info") return "Info";
                    if (modelData === "back") return "Back";
                    return "";
                }

                opacity: (root.isVideo || !isVideoControl) ? (active ? 1.0 : 0.5) : 0.15

                Image {
                    id: iconImg
                    anchors.fill: parent
                    source: Qt.resolvedUrl("../assets/icons/" + btn.iconName)
                    fillMode: Image.PreserveAspectFit
                    visible: status === Image.Ready
                    sourceSize { width: 128; height: 128 }

                    layer.enabled: true
                    layer.smooth: true
                    layer.effect: ColorOverlay {
                        color: btn.active ? colors.accent : colors.fg
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: btn.fallbackText
                    color: btn.active ? colors.accent : colors.fg
                    visible: iconImg.status !== Image.Ready
                    font.pixelSize: PocketMetrics.bodySize * 0.8
                    font.bold: btn.active
                    font.family: SettingsManager.fontFamily
                }
            }
        }
    }

    Keys.onLeftPressed: {
        SoundEngine.scroll();
        root.actionIndex = Math.max(0, root.actionIndex - 1);
    }

    Keys.onRightPressed: {
        SoundEngine.scroll();
        root.actionIndex = Math.min(root.controlsModel.length - 1, root.actionIndex + 1);
    }

    Keys.onUpPressed: {
        event.accepted = true;
        if (root.isVideo) {
            root.adjustVolume(0.05);
        } else {
            SoundEngine.back();
        }
    }

    Keys.onDownPressed: {
        event.accepted = true;
        if (root.isVideo) {
            root.adjustVolume(-0.05);
        } else {
            SoundEngine.back();
        }
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            event.accepted = true;
            SoundEngine.back();
            root.close();
        } else if (api.keys.isPrevPage(event)) {
            event.accepted = true;
            SoundEngine.scroll();
            root.step(-1);
        } else if (api.keys.isNextPage(event)) {
            event.accepted = true;
            SoundEngine.scroll();
            root.step(1);
        } else if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            var selectedAction = root.controlsModel[root.actionIndex];
            root.executeAction(selectedAction);
        }
    }
}
