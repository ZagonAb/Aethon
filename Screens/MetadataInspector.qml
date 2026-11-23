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
    property var flatRows: []
    property int currentIndex: 0
    property bool _initialized: false
    property int currentScopeIndex: 0
    property bool _uiLoading: true
    property real visualProgress: 0.0
    readonly property int totalGames: MetadataEngine._total

    readonly property real avgCompleteness: {
        var fs = MetadataEngine.fieldStats;
        var sumTotal = 0, sumMissing = 0;
        for (var k in fs) {
            sumTotal += fs[k].total;
            sumMissing += fs[k].missing;
        }
        return sumTotal > 0 ? (1 - sumMissing / sumTotal) : 0;
    }

    readonly property string scopeLabel: {
        if (MetadataEngine.activeScope === "all") return Language.t("metadata_scope_all");
        return MetadataEngine.activeScope.toUpperCase();
    }

    readonly property string scopeIndexLabel: {
        var scopes = MetadataEngine.availableScopes();
        return "(" + (root.currentScopeIndex + 1) + "/" + scopes.length + ")";
    }

    NumberAnimation {
        id: fakeLoadAnim
        target: root
        property: "visualProgress"
        from: 0.0
        to: 1.0
        duration: 1000
        easing.type: Easing.OutQuad
    }

    Timer {
        id: minLoadTimer
        interval: 1000
        repeat: false
        onTriggered: { root._uiLoading = false; }
    }

    function startLoadingSequence() {
        root.visualProgress = 0.0;
        root._uiLoading = true;
        fakeLoadAnim.restart();
        minLoadTimer.restart();
    }

    function rebuildRows() {
        var rows = [];
        var total = MetadataEngine._total;

        rows.push({ kind: "header", label: Language.t("metadata_art_cascade"), selectable: false });
        var cs = MetadataEngine.cascadeStats;
        var levels = ["cartridge", "boxFront", "logo", "system", "none"];
        for (var li = 0; li < levels.length; li++) {
            var lvl = levels[li];
            var count = cs[lvl] || 0;
            var pct = total > 0 ? count / total : 0;
            rows.push({
                kind: "cascade", level: lvl, count: count, pct: pct,
                checkId: "art_" + lvl, selectable: count > 0,
                label: Language.t("metadata_art_" + lvl),
                      severity: lvl === "none" ? "error" : (lvl === "system" ? "warning" : "info")
            });
        }

        rows.push({ kind: "header", label: "FIELDS", selectable: false });
        var order = MetadataEngine.fieldOrder;
        for (var fi = 0; fi < order.length; fi++) {
            var fk = order[fi];
            var st = MetadataEngine.fieldStats[fk] || { missing: 0, total: 0 };
            rows.push({
                kind: "field", fieldKey: fk, missing: st.missing, total: st.total,
                pct: st.total > 0 ? (st.total - st.missing) / st.total : 1,
                      checkId: "field_" + fk, selectable: st.missing > 0,
                      label: Language.t("metadata_field_" + fk),
                      severity: st.missing > 0 ? "warning" : "info"
            });
        }

        var issueRows = [];
        var issueOrder = MetadataEngine.issueOrder;
        var ci = MetadataEngine.consistencyIssues;
        for (var ii = 0; ii < issueOrder.length; ii++) {
            var issueId = issueOrder[ii];
            var issue = ci[issueId];
            var cnt = issue ? issue.affected.length : 0;
            if (cnt === 0) continue;
            issueRows.push({
                kind: "issue", issueId: issueId, severity: issue.severity || "info",
                count: cnt, checkId: issueId, selectable: true,
                label: Language.t("metadata_issue_" + issueId)
            });
        }

        var emptyCnt = (MetadataEngine.collectionIssues.emptyCollections || []).length;
        if (emptyCnt > 0) {
            issueRows.push({
                kind: "issue", issueId: "coll_emptyCollection", severity: "warning",
                count: emptyCnt, checkId: "coll_emptyCollection", selectable: true,
                label: Language.t("metadata_issue_coll_emptyCollection")
            });
        }

        var dupCnt = (MetadataEngine.collectionIssues.duplicateTitles || []).length;
        if (dupCnt > 0) {
            issueRows.push({
                kind: "issue", issueId: "coll_duplicateTitles", severity: "error",
                count: dupCnt, checkId: "coll_duplicateTitles", selectable: true,
                label: Language.t("metadata_issue_coll_duplicateTitles")
            });
        }

        if (issueRows.length > 0) {
            rows.push({ kind: "header", label: Language.t("metadata_consistency"), selectable: false });
            for (var ir = 0; ir < issueRows.length; ir++) rows.push(issueRows[ir]);
        }

        var hasSelectable = false;
        for (var h = 0; h < rows.length; h++) {
            if (rows[h].selectable) { hasSelectable = true; break; }
        }
        if (!hasSelectable) {
            rows.push({ kind: "ok", label: Language.t("metadata_no_issues"), selectable: false });
        }

        root.flatRows = rows;

        if (rows.length === 0) { root.currentIndex = 0; return; }
        var valid = root.currentIndex >= 0 && root.currentIndex < rows.length && rows[root.currentIndex].selectable;
        if (!valid) {
            for (var v = 0; v < rows.length; v++) {
                if (rows[v].selectable) { root.currentIndex = v; return; }
            }
            root.currentIndex = 0;
        }
    }

    function _restoreCursorFromAppState() {
        var target = AppState.metadataActiveCheckId;
        if (target === "") return;
        for (var i = 0; i < root.flatRows.length; i++) {
            if (root.flatRows[i].checkId === target && root.flatRows[i].selectable) {
                root.currentIndex = i;
                return;
            }
        }
    }

    function moveCursor(delta) {
        var n = flatRows.length;
        if (n === 0) return;
        var i = currentIndex;
        for (var step = 0; step < n; step++) {
            i = (i + delta + n) % n;
            if (flatRows[i].selectable) {
                currentIndex = i;
                if (i === 1) rowsView.positionViewAtBeginning();
                else rowsView.positionViewAtIndex(i, ListView.Contain);
                return;
            }
        }
    }

    function cycleScope(dir) {
        var scopes = MetadataEngine.availableScopes();
        if (scopes.length === 0) return;

        root.currentScopeIndex = (root.currentScopeIndex + dir + scopes.length) % scopes.length;
        root.startLoadingSequence();
        MetadataEngine.build(scopes[root.currentScopeIndex].shortName);
        currentIndex = 0;
    }

    Component.onCompleted: {
        root._initialized = false;
        root.startLoadingSequence();
        var scopes = MetadataEngine.availableScopes();
        for (var i = 0; i < scopes.length; i++) {
            if (scopes[i].shortName === MetadataEngine.activeScope) {
                root.currentScopeIndex = i;
                break;
            }
        }
        root.rebuildRows();
        root._restoreCursorFromAppState();
        root._initialized = true;

        if (!MetadataEngine.built) {
            var scope = MetadataEngine.activeScope === "" ? "all" : MetadataEngine.activeScope;
            MetadataEngine.build(scope);
        }
    }

    Connections {
        target: MetadataEngine
        function onBuiltChanged() {
            if (!MetadataEngine.built) return;
            root._initialized = false;
            root.rebuildRows();
            root._restoreCursorFromAppState();
            root._initialized = true;
        }
    }

    onCurrentIndexChanged: {
        if (!root._initialized) return;
        var row = flatRows[currentIndex];
        if (row && row.selectable && row.checkId) {
            AppState.metadataActiveCheckId = row.checkId;
        }
    }

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

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
            text: Language.t("metadata_title")
            color: colors.fg
            font.pixelSize: PocketMetrics.titleSize * 0.864
            font.bold: true
            font.family: SettingsManager.fontFamily
        }
    }

    Column {
        opacity: root._uiLoading ? 1.0 : 0.0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }

        anchors.centerIn: parent
        spacing: PocketMetrics.spacing * 1.5
        width: Math.min(parent.width * 0.7, 500)

        Text {
            text: Language.t("metadata_scanning")
            color: colors.muted
            font.pixelSize: PocketMetrics.bodySize
            font.family: SettingsManager.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 0.3; to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 1.0; to: 0.3; duration: 700; easing.type: Easing.InOutQuad }
            }
        }

        Rectangle {
            width: parent.width
            height: PocketMetrics.bodySize * 0.6
            color: colors.card
            border.color: colors.border
            radius: height / 2
            clip: true

            Rectangle {
                width: parent.width * root.visualProgress
                height: parent.height
                color: colors.accent
                radius: parent.radius
            }
        }

        Text {
            text: Math.round(root.visualProgress * 100) + "%"
            color: colors.muted
            font.pixelSize: PocketMetrics.bodySize * 0.8
            font.family: SettingsManager.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Column {
        opacity: root._uiLoading ? 0.0 : 1.0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }

        anchors.top: pageHeader.bottom
        anchors.bottom: footer.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: PocketMetrics.margin
        anchors.rightMargin: PocketMetrics.margin
        anchors.topMargin: PocketMetrics.spacing * 0.5
        anchors.bottomMargin: PocketMetrics.spacing * 0.5
        spacing: PocketMetrics.spacing * 0.8

        Item {
            width: parent.width
            height: PocketMetrics.bodySize * 1.8

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: PocketMetrics.spacing

                Rectangle {
                    width: Math.min(root.width * 0.35, 400)
                    height: PocketMetrics.bodySize * 0.7
                    anchors.verticalCenter: parent.verticalCenter
                    color: colors.card
                    border.color: colors.border
                    radius: height / 2
                    clip: true

                    Rectangle {
                        width: parent.width * root.avgCompleteness
                        height: parent.height
                        radius: parent.radius
                        color: root.avgCompleteness > 0.8 ? colors.accent
                        : root.avgCompleteness > 0.5 ? "#e6c229"
                        : "#ff6b6b"
                    }
                }

                Text {
                    text: Math.round(root.avgCompleteness * 100) + "%"
                    color: colors.fg
                    font.pixelSize: PocketMetrics.bodySize
                    font.bold: true
                    font.family: SettingsManager.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: PocketMetrics.spacing * 0.4

                Item {
                    width: PocketMetrics.bodySize * 1.1
                    height: PocketMetrics.bodySize * 1.1
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: scopeLeftIcon
                        anchors.fill: parent
                        source: Qt.resolvedUrl("../assets/icons/arrow-left.svg")
                        fillMode: Image.PreserveAspectFit
                        visible: status === Image.Ready
                        sourceSize.width: width > 0 ? Math.round(width) : 64
                        sourceSize.height: height > 0 ? Math.round(height) : 64
                        layer.enabled: EffectsManager.shaderEffectsEnabled
                        layer.smooth: true
                        layer.effect: ColorOverlay { color: colors.accent }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "◀"
                        color: colors.accent
                        visible: scopeLeftIcon.status !== Image.Ready
                        font.pixelSize: PocketMetrics.bodySize
                        font.family: SettingsManager.fontFamily
                    }
                }

                Row {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter

                    Item {
                        width: Math.min(mqScope.implicitWidth, root.width * 0.3)
                        height: mqScope.implicitHeight
                        anchors.verticalCenter: parent.verticalCenter

                        MarqueeText {
                            id: mqScope
                            width: parent.width
                            text: root.scopeLabel
                            color: colors.accent
                            pixelSize: PocketMetrics.bodySize
                            bold: true
                            active: true
                            provideImplicitSize: true
                        }
                    }
                }

                Item {
                    width: PocketMetrics.bodySize * 1.1
                    height: PocketMetrics.bodySize * 1.1
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: scopeRightIcon
                        anchors.fill: parent
                        source: Qt.resolvedUrl("../assets/icons/arrow-right.svg")
                        fillMode: Image.PreserveAspectFit
                        visible: status === Image.Ready
                        sourceSize.width: width > 0 ? Math.round(width) : 64
                        sourceSize.height: height > 0 ? Math.round(height) : 64
                        layer.enabled: EffectsManager.shaderEffectsEnabled
                        layer.smooth: true
                        layer.effect: ColorOverlay { color: colors.accent }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "▶"
                        color: colors.accent
                        visible: scopeRightIcon.status !== Image.Ready
                        font.pixelSize: PocketMetrics.bodySize
                        font.family: SettingsManager.fontFamily
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: parent.height - (PocketMetrics.bodySize * 1.8) - PocketMetrics.spacing * 0.8

            ListView {
                id: rowsView
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width - 12
                clip: true
                model: root.flatRows
                currentIndex: root.currentIndex
                highlightMoveDuration: 120
                boundsBehavior: Flickable.StopAtBounds

                onCurrentIndexChanged: {
                    if (rowsView.currentIndex !== root.currentIndex)
                        root.currentIndex = rowsView.currentIndex;
                }

                delegate: Item {
                    width: rowsView.width
                    height: modelData.kind === "header" ? PocketMetrics.bodySize * 1.8 : PocketMetrics.bodySize * 1.7

                    Text {
                        visible: modelData.kind === "header"
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        text: modelData.label || ""
                        color: colors.muted
                        font.pixelSize: PocketMetrics.bodySize * 0.85
                        font.bold: true
                        font.family: SettingsManager.fontFamily
                        opacity: 0.75
                    }

                    Text {
                        visible: modelData.kind === "ok"
                        anchors.centerIn: parent
                        text: modelData.label || ""
                        color: colors.accent
                        font.pixelSize: PocketMetrics.bodySize
                        font.family: SettingsManager.fontFamily
                    }

                    Rectangle {
                        visible: modelData.kind !== "header" && modelData.kind !== "ok"
                        anchors.fill: parent
                        anchors.topMargin: 1
                        anchors.bottomMargin: 1
                        color: (index === rowsView.currentIndex && modelData.selectable === true) ? colors.card : "transparent"
                        radius: EffectsManager.r(4)

                        Behavior on color { ColorAnimation { duration: 140 } }

                        MarqueeText {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width * 0.45
                            text: modelData.label || ""
                            color: (index === rowsView.currentIndex && modelData.selectable === true) ? colors.accent : colors.fg
                            pixelSize: PocketMetrics.bodySize
                            bold: (index === rowsView.currentIndex && modelData.selectable === true)
                            active: (index === rowsView.currentIndex)
                            provideImplicitSize: true
                        }

                        Rectangle {
                            visible: modelData.kind === "cascade" || modelData.kind === "field"
                            anchors.right: infoText.left
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(parent.width * 0.25, 120)
                            height: PocketMetrics.bodySize * 0.4
                            color: colors.border
                            radius: height / 2
                            opacity: 0.4
                            clip: true

                            Rectangle {
                                width: parent.width * (modelData.pct || 0)
                                height: parent.height
                                radius: parent.radius
                                color: (modelData.pct || 0) > 0.7 ? colors.accent : (modelData.pct || 0) > 0.4 ? "#e6c229" : "#ff6b6b"
                            }
                        }

                        Text {
                            id: infoText
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                if (modelData.kind === "cascade" || modelData.kind === "field") {
                                    var cnt = (modelData.kind === "cascade") ? modelData.count : modelData.missing;
                                    return cnt + "  " + Math.round((modelData.pct || 0) * 100) + "%";
                                }
                                return modelData.count + "  ⚠";
                            }
                            color: {
                                if (modelData.severity === "error") return "#ff6b6b";
                                if (modelData.severity === "warning") return colors.accent;
                                return colors.muted;
                            }
                            font.pixelSize: PocketMetrics.bodySize
                            font.family: SettingsManager.fontFamily
                        }
                    }
                }
            }

            Rectangle {
                id: scrollTrack
                anchors.top: rowsView.top
                anchors.bottom: rowsView.bottom
                anchors.right: parent.right
                width: 6
                color: colors.border
                opacity: 0.4
                radius: width / 2
                visible: rowsView.contentHeight > rowsView.height

                Rectangle {
                    width: parent.width
                    height: Math.max(20, parent.height * (rowsView.height / rowsView.contentHeight))
                    color: colors.accent
                    radius: parent.radius
                    y: (parent.height - height) * (rowsView.contentY / Math.max(1, rowsView.contentHeight - rowsView.height))
                }
            }
        }
    }

    HintBar {
        id: footer
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PocketMetrics.margin * 0.5
        anchors.left: parent.left
        anchors.right: parent.right
        text: Language.t("metadata_hint_summary")
        color: colors.muted
    }

    Keys.onUpPressed: {
        if (!root._uiLoading) {
            SoundEngine.scroll();
            root.moveCursor(-1);
        }
    }
    Keys.onDownPressed: {
        if (!root._uiLoading) {
            SoundEngine.scroll();
            root.moveCursor(1);
        }
    }
    Keys.onPressed: {
        if (root._uiLoading) return;
        if (event.key === Qt.Key_Left || api.keys.isPrevPage(event)) {
            event.accepted = true;
            if (!event.isAutoRepeat) { SoundEngine.scroll(); root.cycleScope(-1); }
            return;
        }
        if (event.key === Qt.Key_Right || api.keys.isNextPage(event)) {
            event.accepted = true;
            if (!event.isAutoRepeat) { SoundEngine.scroll(); root.cycleScope(1); }
            return;
        }
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            var row = root.flatRows[root.currentIndex];
            if (row && row.selectable && row.checkId) NavigationManager.enterMetadataList(row.checkId);
            return;
        }
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            SoundEngine.select();
            root.startLoadingSequence();
            MetadataEngine.build(MetadataEngine.activeScope);
            return;
        }
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            NavigationManager.goBack();
        }
    }
}
