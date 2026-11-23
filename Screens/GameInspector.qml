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
    readonly property var game: AppState.currentGame
    readonly property var report: root.game ? MetadataEngine.getGameReport(root.game) : null
    property bool _wasFavorite: false

    function fileName(url) {
        if (!url) return "";
        var s = "" + url;
        var parts = s.split("/");
        return parts[parts.length - 1] || s;
    }

    function formatSeconds(s) {
        if (!s || s <= 0) return "00:00:00";
        var h = Math.floor(s / 3600);
        var m = Math.floor((s % 3600) / 60);
        var sec = Math.floor(s % 60);
        function pad(n) { return (n < 10 ? "0" : "") + n; }
        return pad(h) + ":" + pad(m) + ":" + pad(sec);
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

    function toggleFavorite() {
        if (!root.game) return;
        root.game.favorite = !root.game.favorite;
        SoundEngine.favorite();
        NavigationManager.favoriteToggled();
    }

    NumberAnimation {
        id: scrollAnim
        target: flick
        property: "contentY"
        duration: EffectsManager.dur(150)
        easing.type: Easing.OutCubic
    }

    Component.onCompleted: root.forceActiveFocus()

    component SectionHeader: Text {
        width: parent ? parent.width : 0
        color: colors.muted
        font.pixelSize: PocketMetrics.bodySize * 0.9
        font.bold: true
        font.family: SettingsManager.fontFamily
        opacity: 0.75
        topPadding: PocketMetrics.spacing * 0.5
    }

    component InfoRow: Item {
        property string label: ""
        property string value: ""
        property color valueColor: colors.accent

        width: parent ? parent.width : 0
        height: PocketMetrics.bodySize * 1.6

        MarqueeText {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.42
            text: parent.label
            color: colors.fg
            pixelSize: PocketMetrics.bodySize
            active: true
        }

        MarqueeText {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.55
            text: parent.value !== "" ? parent.value : "—"
            color: parent.valueColor
            pixelSize: PocketMetrics.bodySize
            active: true
        }
    }

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

    Item {
        id: pageHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: PocketMetrics.headerHeight

        Row {
            anchors.left: parent.left
            anchors.leftMargin: PocketMetrics.margin
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(root.width * 0.45, 800)
            spacing: PocketMetrics.spacing * 0.5

            Item {
                visible: root.game && root.game.favorite === true
                width: PocketMetrics.titleSize * 0.7
                height: width
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    id: favIcon
                    anchors.fill: parent
                    source: Qt.resolvedUrl("../assets/icons/favorite.svg")
                    fillMode: Image.PreserveAspectFit
                    visible: !EffectsManager.shaderEffectsEnabled
                    sourceSize.width: width > 0 ? Math.round(width) : 128
                    sourceSize.height: height > 0 ? Math.round(height) : 128
                }

                ColorOverlay {
                    anchors.fill: favIcon
                    source: favIcon
                    color: colors.accent
                    visible: EffectsManager.shaderEffectsEnabled && favIcon.status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    text: "★"
                    color: colors.accent
                    visible: favIcon.status !== Image.Ready
                    font.pixelSize: PocketMetrics.titleSize * 0.7
                    font.family: SettingsManager.fontFamily
                }
            }

            Item {
                width: parent.width - (parent.children[0].visible ? parent.children[0].width + parent.spacing : 0)
                height: mqTitle.height
                anchors.verticalCenter: parent.verticalCenter

                MarqueeText {
                    id: mqTitle
                    width: parent.width
                    text: root.game ? GameUtils.cleanGameTitle(root.game.title) : "—"
                    color: colors.accent
                    pixelSize: PocketMetrics.titleSize * 0.7
                    bold: true
                    active: true
                }
            }
        }
    }

    Item {
        anchors.top: pageHeader.bottom
        anchors.bottom: footer.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: PocketMetrics.margin
        anchors.rightMargin: PocketMetrics.margin
        anchors.topMargin: PocketMetrics.spacing * 0.5
        anchors.bottomMargin: PocketMetrics.spacing * 0.5

        Flickable {
            id: flick
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width - 12
            clip: true
            contentWidth: width
            contentHeight: contentColumn.height
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            Column {
                id: contentColumn
                width: flick.width
                spacing: PocketMetrics.spacing * 0.6

                SectionHeader { text: Language.t("metadata_inspector_identity") }
                InfoRow { label: "Title"; value: root.report ? root.report.identity.title : ""; valueColor: colors.fg }
                InfoRow { label: Language.t("metadata_inspector_clean_title"); value: root.report ? root.report.identity.cleanTitle : ""; valueColor: colors.fg }
                InfoRow { label: Language.t("metadata_inspector_sort_by"); value: (root.report && root.report.identity.sortBy) ? root.report.identity.sortBy : ""; valueColor: colors.fg }
                InfoRow { label: "Collections"; value: (root.report && root.report.identity.collections.length > 0) ? root.report.identity.collections.join(", ") : ""; valueColor: colors.fg }

                SectionHeader { text: Language.t("metadata_inspector_credits") }
                InfoRow { label: Language.t("details_developer"); value: (root.report && root.report.credits.developer) ? root.report.credits.developer : "" }
                InfoRow { label: Language.t("details_publisher"); value: (root.report && root.report.credits.publisher) ? root.report.credits.publisher : "" }
                InfoRow { label: Language.t("details_genre"); value: (root.report && root.report.credits.genre) ? root.report.credits.genre : "" }
                InfoRow { label: Language.t("metadata_field_tags"); value: (root.report && root.report.credits.tagList.length > 0) ? root.report.credits.tagList.join(", ") : "" }

                SectionHeader { text: Language.t("metadata_inspector_release") }
                InfoRow { label: Language.t("details_year"); value: root.report ? ("" + root.report.release.year) : ""; valueColor: colors.fg }
                InfoRow { label: "Month"; value: root.report ? ("" + root.report.release.month) : ""; valueColor: colors.fg }
                InfoRow { label: "Day"; value: root.report ? ("" + root.report.release.day) : ""; valueColor: colors.fg }
                InfoRow { label: Language.t("metadata_inspector_valid_date"); value: (root.report && root.report.release.valid) ? "✓" : "✗"; valueColor: (root.report && root.report.release.valid) ? colors.accent : "#ff6b6b" }

                SectionHeader { text: Language.t("metadata_inspector_stats") }
                InfoRow { label: Language.t("details_play_count"); value: root.report ? ("" + root.report.stats.playCount) : "" }
                InfoRow { label: Language.t("details_play_time"); value: root.report ? root.formatSeconds(root.report.stats.playTime) : "" }
                InfoRow { label: "Last played"; value: (root.report && root.report.stats.lastPlayedValid) ? Qt.formatDateTime(root.report.stats.lastPlayed, "yyyy-MM-dd hh:mm") : "" }
                InfoRow { label: "Rating"; value: root.report ? (Math.round(root.report.stats.rating * 100) + "%") : "" }
                InfoRow { label: Language.t("details_players"); value: root.report ? ("" + root.report.stats.players) : "" }
                InfoRow { label: "Favorite"; value: (root.report && root.report.stats.favorite) ? "★" : "—" }
                InfoRow { label: "Missing"; value: (root.report && root.report.stats.missing) ? "yes" : "no"; valueColor: (root.report && root.report.stats.missing) ? "#ff6b6b" : colors.muted }

                SectionHeader { text: Language.t("metadata_inspector_assets") }
                Repeater {
                    model: {
                        if (!root.report) return [];
                        var keys = ["boxFront", "boxBack", "boxSpine", "boxFull", "cartridge", "logo", "tile", "banner", "poster", "background", "screenshot", "titlescreen", "video", "marquee", "bezel"];
                        var arr = [];
                        for (var i = 0; i < keys.length; i++) {
                            var a = root.report.assets[keys[i]];
                            arr.push({ key: keys[i], present: a.present, isLocal: a.isLocal, url: a.url, listCount: a.listCount });
                        }
                        return arr;
                    }

                    delegate: InfoRow {
                        label: modelData.key
                        value: modelData.present ? (root.fileName(modelData.url) + "  [" + (modelData.isLocal ? Language.t("metadata_inspector_local") : Language.t("metadata_inspector_remote")) + "]" + (modelData.listCount > 1 ? "  ×" + modelData.listCount : "")) : Language.t("metadata_inspector_missing")
                        valueColor: modelData.present ? colors.accent : colors.muted
                    }
                }

                SectionHeader { text: Language.t("metadata_inspector_health") }

                Item {
                    width: parent.width
                    height: PocketMetrics.bodySize * 2

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Score"
                        color: colors.fg
                        font.pixelSize: PocketMetrics.bodySize
                        font.family: SettingsManager.fontFamily
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: parent.width * 0.25
                        anchors.right: parent.right
                        anchors.rightMargin: parent.width * 0.15
                        anchors.verticalCenter: parent.verticalCenter
                        height: PocketMetrics.bodySize * 0.6
                        color: colors.card
                        border.color: colors.border
                        radius: height / 2
                        clip: true

                        Rectangle {
                            width: parent.width * (root.report ? root.report.health.score / 100 : 0)
                            height: parent.height
                            radius: parent.radius
                            color: !root.report ? colors.muted : root.report.health.score >= 80 ? colors.accent : root.report.health.score >= 50 ? "#e6c229" : "#ff6b6b"
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.report ? (root.report.health.score + "/100") : "—"
                        color: colors.fg
                        font.pixelSize: PocketMetrics.bodySize
                        font.bold: true
                        font.family: SettingsManager.fontFamily
                    }
                }

                Text {
                    visible: root.report && root.report.health.issues.length > 0
                    width: parent.width
                    text: {
                        if (!root.report) return "";
                        var issues = root.report.health.issues;
                        var out = [];
                        for (var i = 0; i < issues.length; i++) {
                            var id = issues[i];
                            if (id === "no_art") out.push("no art");
                            else if (id === "system_art_only") out.push("system art only");
                            else if (id === "logo_only") out.push("logo only");
                            else if (id.indexOf("missing_") === 0) out.push("missing " + id.substring(8));
                            else out.push(Language.t("metadata_issue_" + id));
                        }
                        return out.join(" · ");
                    }
                    color: colors.muted
                    font.pixelSize: PocketMetrics.bodySize * 0.85
                    font.family: SettingsManager.fontFamily
                    wrapMode: Text.WordWrap
                }

                Item { width: 1; height: PocketMetrics.spacing * 2 }
            }
        }

        Rectangle {
            anchors.top: flick.top
            anchors.bottom: flick.bottom
            anchors.right: parent.right
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
    }

    HintBar {
        id: footer
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PocketMetrics.margin * 0.5
        anchors.left: parent.left
        anchors.right: parent.right
        text: Language.t("metadata_hint_inspector")
        color: colors.muted
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
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true; root.toggleFavorite(); return;
        }
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true; NavigationManager.enterGameDetails(); return;
        }
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true; NavigationManager.goBack(); return;
        }
        if (api.keys.isPrevPage(event) && !event.isAutoRepeat) {
            event.accepted = true; SoundEngine.scroll(); root.scrollBy(-5);
        } else if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
            event.accepted = true; SoundEngine.scroll(); root.scrollBy(5);
        }
    }
}
