// Aethon
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
import QtQuick 2.15
import "../App"
import "../Layout"
import "../Components"

FocusScope {
    id: root
    anchors.fill: parent
    focus: true

    property string query: ""
    property var results: []

    property var _cleanTitleCache: ({})

    function _cleanTitleOf(rawTitle) {
        var key = rawTitle || "";
        var c = root._cleanTitleCache[key];
        if (c !== undefined) return c;
        c = GameUtils.cleanGameTitle(key);
        root._cleanTitleCache[key] = c;
        return c;
    }

    property string zone: "input"
    property bool _restoring: true

    readonly property bool vkEnabled: SettingsManager.showVirtualKeyboard
    readonly property bool editingMode: root.vkEnabled && (root.zone === "input" || root.zone === "keyboard")

    readonly property var colors: SettingsManager.getCurrentColors()
    readonly property real searchBoxHeight: PocketMetrics.bodySize * 2.6

    readonly property real scrollBarWidth: 6
    readonly property real scrollBarMargin: 6

    readonly property bool isTiny: SettingsManager.activeContext === "tiny4x3"

    property var historyEntries: []
    property bool showHistory: false
    property bool historyConfirmMode: false
    readonly property int maxHistory: 15
    readonly property string historyMemoryKey: "aethon.search.history"

    readonly property bool historyAvailable:
    root.query.trim() === ""
    && root.historyEntries.length > 0
    && !root.searched

    readonly property bool showSearchHelp: !root.vkEnabled
    && root.query.trim() === ""
    && root.results.length === 0
    && !root.showHistory
    && !root.noResultsShown

    component ScrollIndicator: Item {
        id: scrollRoot
        property var listView: null
        property int visibleRows: 1
        property real scrollFraction: 0
        property int totalCount: 0
        property color trackColor: "gray"
        property color thumbColor: "white"
        property real barWidth: 6
        property real thumbMinHeight: 24
        property real thumbMaxRatio: 0.15
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: barWidth
        visible: listView !== null && listView.visible && totalCount > visibleRows

        Rectangle {
            id: scrollTrack
            anchors.fill: parent
            radius: width / 2
            color: scrollRoot.trackColor
            opacity: 0.4

            Rectangle {
                id: scrollThumb
                width: parent.width
                radius: width / 2
                color: scrollRoot.thumbColor
                opacity: 0.75
                height: Math.max(scrollRoot.thumbMinHeight, Math.min(scrollTrack.height * scrollRoot.thumbMaxRatio, scrollTrack.height * Math.min(1, scrollRoot.visibleRows / Math.max(scrollRoot.totalCount, 1))))
                y: (scrollTrack.height - height) * scrollRoot.scrollFraction
                Behavior on y {
                    enabled: EffectsManager.animationsEnabled
                    NumberAnimation { duration: EffectsManager.dur(150); easing.type: Easing.OutQuad }
                }
                Behavior on height {
                    enabled: EffectsManager.animationsEnabled
                    NumberAnimation { duration: EffectsManager.dur(150); easing.type: Easing.OutQuad }
                }
            }
        }
    }

    function parseToken(tok) {
        var rangeMatch = tok.match(/^(\d{4})\s*-\s*(\d{4})$/);
        if (rangeMatch) {
            var from = parseInt(rangeMatch[1], 10);
            var to = parseInt(rangeMatch[2], 10);
            if (from > to) { var tmp = from; from = to; to = tmp; }
            return { kind: "yearRange", lower: tok.toLowerCase(), yearFrom: from, yearTo: to };
        }
        if (/^\d{4}$/.test(tok)) {
            return { kind: "year", lower: tok.toLowerCase(), year: parseInt(tok, 10) };
        }
        if (tok.charAt(tok.length - 1) === "%") {
            var n = parseFloat(tok.substring(0, tok.length - 1));
            if (!isNaN(n) && n >= 0 && n <= 100) {
                return { kind: "rating", lower: tok.toLowerCase(), rating: n };
            }
        }
        return { kind: "text", lower: tok.toLowerCase() };
    }

    function parseQuery(q) {
        var trimmed = (q || "").trim();
        if (trimmed === "") {
            return {
                raw: "", lower: "", tokens: [],
                isYear: false, year: -1,
                isYearRange: false, yearFrom: -1, yearTo: -1,
                isRating: false, rating: -1
            };
        }
        var rawTokens = trimmed.split(/\s+/).filter(function(t) { return t.length > 0; });
        var tokens = [];
        for (var i = 0; i < rawTokens.length; i++) tokens.push(parseToken(rawTokens[i]));

        var first = tokens.length === 1 ? tokens[0] : null;
        return {
            raw: trimmed,
            lower: trimmed.toLowerCase(),
            tokens: tokens,
            isYear: first ? first.kind === "year" : false,
            year: (first && first.kind === "year") ? first.year : -1,
            isYearRange: first ? first.kind === "yearRange" : false,
            yearFrom: (first && first.kind === "yearRange") ? first.yearFrom : -1,
            yearTo: (first && first.kind === "yearRange") ? first.yearTo : -1,
            isRating: first ? first.kind === "rating" : false,
            rating: (first && first.kind === "rating") ? first.rating : -1
        };
    }

    function _emptyMatched() {
        return { title: false, year: false, rating: false,
            developers: [], publishers: [], genres: [], tags: [] };
    }

    function _mergeMatched(target, src) {
        if (src.title) target.title = true;
        if (src.year) target.year = true;
        if (src.rating) target.rating = true;
        var i;
        for (i = 0; i < src.developers.length; i++)
            if (target.developers.indexOf(src.developers[i]) === -1) target.developers.push(src.developers[i]);
            for (i = 0; i < src.publishers.length; i++)
                if (target.publishers.indexOf(src.publishers[i]) === -1) target.publishers.push(src.publishers[i]);
                for (i = 0; i < src.genres.length; i++)
                    if (target.genres.indexOf(src.genres[i]) === -1) target.genres.push(src.genres[i]);
                    for (i = 0; i < src.tags.length; i++)
                        if (target.tags.indexOf(src.tags[i]) === -1) target.tags.push(src.tags[i]);
    }

    function _matchToken(game, token) {
        if (token.kind === "year") {
            return (game.releaseYear === token.year)
            ? { title: false, year: true, rating: false, developers: [], publishers: [], genres: [], tags: [] }
            : null;
        }
        if (token.kind === "yearRange") {
            return (game.releaseYear >= token.yearFrom && game.releaseYear <= token.yearTo)
            ? { title: false, year: true, rating: false, developers: [], publishers: [], genres: [], tags: [] }
            : null;
        }
        if (token.kind === "rating") {
            var pct = Math.round((game.rating || 0) * 100);
            return (pct === token.rating)
            ? { title: false, year: false, rating: true, developers: [], publishers: [], genres: [], tags: [] }
            : null;
        }

        var m = _emptyMatched();
        var found = false;

        var cleanTitle = root._cleanTitleOf(game.title || "");
        if (cleanTitle !== "" && cleanTitle.toLowerCase().indexOf(token.lower) !== -1) {
            m.title = true;
            found = true;
        }

        m.developers = matchesList(game.developerList, token.lower);
        if (m.developers.length > 0) found = true;
        m.publishers = matchesList(game.publisherList, token.lower);
        if (m.publishers.length > 0) found = true;
        m.genres = matchesList(game.genreList, token.lower);
        if (m.genres.length > 0) found = true;
        m.tags = matchesList(game.tagList, token.lower);
        if (m.tags.length > 0) found = true;

        return found ? m : null;
    }

    function evaluateGame(game, q) {
        if (!q.tokens || q.tokens.length === 0) return null;

        var combined = _emptyMatched();
        for (var i = 0; i < q.tokens.length; i++) {
            var m = _matchToken(game, q.tokens[i]);
            if (!m) return null;
            _mergeMatched(combined, m);
        }
        return { game: game, matched: combined, segments: root.buildSegments(game, combined) };
    }

    function matchesList(list, query) {
        var result = [];
        if (!list) return result;
        for (var i = 0; i < list.length; i++) {
            var item = list[i];
            if (item && item.toLowerCase().indexOf(query) !== -1) result.push(item);
        }
        return result;
    }

    function buildSegments(game, matched) {
        var segments = [];
        var firstDev = game.developer ? game.developer.split(",")[0].trim() : "";

        if (game.developer) {
            segments.push({ text: firstDev, highlight: matched.developers.length > 0 });
        }

        if (game.publisher && matched.publishers.length > 0) {
            var firstPub = game.publisher.split(",")[0].trim();
            if (firstPub !== "" && firstPub !== firstDev) {
                segments.push({ text: firstPub, highlight: true });
            }
        }

        if (game.releaseYear > 0)
            segments.push({ text: String(game.releaseYear), highlight: matched.year });

        if (game.rating > 0)
            segments.push({ text: Math.round(game.rating * 100) + "%", highlight: matched.rating });

        if (game.genre) {
            var firstGenre = GameUtils.firstCleanGenre(game.genre);
            if (firstGenre && firstGenre !== "—")
                segments.push({ text: firstGenre, highlight: matched.genres.length > 0 });
        }

        var tagLimit = Math.min(matched.tags.length, 2);
        for (var i = 0; i < tagLimit; i++)
            segments.push({ text: matched.tags[i], highlight: true });

        return segments;
    }

    function runSearch() {
        var q = parseQuery(query);
        if (q.raw === "") { results = []; AppState.selectGame(null, -1); return; }
        var all = api.allGames.toVarArray();
        var matched = [];
        for (var i = 0; i < all.length; i++) {
            var m = evaluateGame(all[i], q);
            if (m) matched.push(m);
        }
        matched.sort(function (a, b) { return a.game.title.localeCompare(b.game.title); });
        results = matched;
        if (results.length > 0) {
            resultsView.currentIndex = 0;
            AppState.selectGame(results[0].game, 0);
        } else {
            AppState.selectGame(null, -1);
        }
    }

    property string searchedQuery: ""
    property bool searched: false
    readonly property bool noResultsShown: root.searched && root.query.trim() === root.searchedQuery && root.results.length === 0
    readonly property bool searchBlocked: root.query.trim() === "" || root.noResultsShown

    function submitSearch() {
        var q = root.query.trim();
        if (q === "") return false;
        if (!root.searched || q !== root.searchedQuery) {
            root.runSearch();
            root.searchedQuery = q;
            root.searched = true;
            root.addToHistory(q);
        }
        return root.results.length > 0;
    }

    function loadHistory() {
        if (!api.memory.has(root.historyMemoryKey)) {
            root.historyEntries = [];
            return;
        }
        var stored = api.memory.get(root.historyMemoryKey);
        if (!stored || !Array.isArray(stored.entries)) {
            root.historyEntries = [];
            return;
        }
        var cleaned = [];
        for (var i = 0; i < stored.entries.length && cleaned.length < root.maxHistory; i++) {
            var e = stored.entries[i];
            if (e && typeof e.query === "string" && e.query.trim() !== "") {
                cleaned.push({ query: e.query, timestamp: e.timestamp || 0 });
            }
        }
        root.historyEntries = cleaned;
    }

    function saveHistory() {
        api.memory.set(root.historyMemoryKey, { entries: root.historyEntries });
    }

    function addToHistory(q) {
        var trimmed = (q || "").trim();
        if (trimmed === "") return;
        var lower = trimmed.toLowerCase();
        var filtered = [];
        for (var i = 0; i < root.historyEntries.length; i++) {
            if (root.historyEntries[i].query.toLowerCase() !== lower) {
                filtered.push(root.historyEntries[i]);
            }
        }
        filtered.unshift({ query: trimmed, timestamp: Date.now() });
        if (filtered.length > root.maxHistory) filtered = filtered.slice(0, root.maxHistory);
        root.historyEntries = filtered;
        root.saveHistory();
    }

    function removeFromHistory(index) {
        if (index < 0 || index >= root.historyEntries.length) return;
        var copy = root.historyEntries.slice();
        copy.splice(index, 1);
        root.historyEntries = copy;
        root.saveHistory();
        if (root.historyEntries.length === 0) {
            root.closeHistory();
            return;
        }
        if (historyListView.currentIndex >= root.historyEntries.length) {
            historyListView.currentIndex = root.historyEntries.length - 1;
        }
    }

    function clearHistory() {
        root.historyEntries = [];
        root.historyConfirmMode = false;
        root.saveHistory();
        root.closeHistory();
    }

    function runHistoryEntry(index) {
        if (index < 0 || index >= root.historyEntries.length) return false;
        var q = root.historyEntries[index].query;
        root.query = q;
        if (searchInput.text !== q) searchInput.text = q;
        searchInput.cursorPosition = q.length;

        root.showHistory = false;

        if (root.submitSearch()) {
            root.focusResults(true);
            return true;
        }
        root.focusInput();
        return false;
    }

    function openHistory() {
        root.showHistory = true;
        root.zone = "history";
        root.historyConfirmMode = false;
        historyListView.currentIndex = 0;
        historyListView.forceActiveFocus();
    }

    function closeHistory() {
        root.showHistory = false;
        root.zone = "input";
        root.historyConfirmMode = false;
        root.focusInput();
    }

    function _isPhysicalEnter(event) {
        return (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && event.text && event.text.length > 0;
    }

    onQueryChanged: {
        if (root._restoring) return;
        if (root.query.trim() === "" && (root.searched || root.results.length > 0)) {
            root.results = [];
            root.searched = false;
            root.searchedQuery = "";
            AppState.selectGame(null, -1);
        }
        AppState.searchQuery = root.query;
    }

    function focusInput() {
        root.zone = "input";
        searchInput.forceActiveFocus();
    }

    function focusKeyboard() {
        root.zone = "keyboard";
    }

    function focusResults(reset) {
        if (reset === undefined) reset = true;
        if (root.results.length === 0) return false;
        root.zone = "results";
        root.showHistory = false;
        if (reset || resultsView.currentIndex < 0 || resultsView.currentIndex >= root.results.length) {
            resultsView.currentIndex = 0;
        }
        AppState.selectGame(root.results[resultsView.currentIndex].game, resultsView.currentIndex);
        resultsView.forceActiveFocus();
        return true;
    }

    onResultsChanged: {
        if (root._restoring) return;
        AppState.searchResults = root.results;
        if (root.zone === "results" && root.results.length === 0)
            root.focusInput();
    }
    onSearchedQueryChanged: {
        if (root._restoring) return;
        AppState.searchSearchedQuery = root.searchedQuery;
    }
    onSearchedChanged: {
        if (root._restoring) return;
        AppState.searchSearched = root.searched;
    }
    onZoneChanged: {
        if (root._restoring) return;
        AppState.searchZone = root.zone;
    }

    Component.onCompleted: {
        root.loadHistory();

        if (AppState.searchQuery !== "" || (AppState.searchResults && AppState.searchResults.length > 0)) {
            root.query = AppState.searchQuery;
            root.results = AppState.searchResults || [];
            root.searchedQuery = AppState.searchSearchedQuery;
            root.searched = AppState.searchSearched;

            var savedZone = AppState.searchZone || "input";
            var savedIdx = Math.max(0, Math.min(AppState.searchCurrentIndex, root.results.length - 1));

            if (savedZone === "results" && root.results.length > 0) {
                resultsView.highlightMoveDuration = 0;
                resultsView.currentIndex = savedIdx;
                resultsView.positionViewAtIndex(savedIdx, ListView.Contain);
                resultsView.highlightMoveDuration = EffectsManager.dur(120);
                root.focusResults(false);
            } else if (savedZone === "keyboard" && root.vkEnabled) {
                root.focusKeyboard();
            } else {
                root.focusInput();
            }
        } else {
            root.focusInput();
        }
        root._restoring = false;
    }

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

    Item {
        id: headerArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: PocketMetrics.headerHeight

        Text {
            anchors.left: parent.left
            anchors.leftMargin: PocketMetrics.margin
            anchors.verticalCenter: parent.verticalCenter
            text: Language.t("search_title")
            color: colors.muted
            font.pixelSize: PocketMetrics.titleSize
            font.bold: true
            font.family: SettingsManager.fontFamily
        }
    }

    Rectangle {
        id: searchBox
        anchors.top: headerArea.bottom
        anchors.topMargin: PocketMetrics.spacing
        anchors.horizontalCenter: parent.horizontalCenter
        width: vk.keyboardWidth
        height: root.searchBoxHeight
        color: colors.card
        border.color: (root.zone === "input" || root.zone === "history_button") ? colors.accent : colors.border
        border.width: 2
        radius: 0

        TextInput {
            id: searchInput
            anchors.left: parent.left
            anchors.right: (historyBtn.visible ? historyBtn.left : (vkHint.visible ? vkHint.left : parent.right))
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: PocketMetrics.spacing * 0.5
            anchors.rightMargin: PocketMetrics.spacing * 0.5
            clip: true
            rightPadding: 4
            color: colors.fg
            font.pixelSize: PocketMetrics.bodySize * 1.15
            font.family: SettingsManager.fontFamily || "sans-serif"
            verticalAlignment: TextInput.AlignVCenter

            focus: root.zone === "input"
            text: root.query
            selectByMouse: true

            activeFocusOnPress: false
            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

            onTextChanged: root.query = text

            cursorDelegate: Rectangle {
                width: Math.max(2, Math.round(searchInput.font.pixelSize * 0.55))
                height: searchInput.cursorRectangle.height
                color: colors.accent
                opacity: 0.7
            }

            Text {
                text: root.zone === "history_button"
                ? Language.t("search_history_prompt")
                : Language.t("search_placeholder")
                color: colors.muted
                font.pixelSize: parent.font.pixelSize
                font.family: parent.font.family
                visible: searchInput.text === "" && (
                    root.zone === "keyboard"
                    || root.zone === "history_button"
                    || (!root.vkEnabled && root.zone === "input")
                )
                elide: Text.ElideRight
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
            }

            Keys.onRightPressed: {
                if (root.historyAvailable && searchInput.cursorPosition === searchInput.text.length) {
                    event.accepted = true;
                    root.zone = "history_button";
                    historyBtn.forceActiveFocus();
                    SoundEngine.scroll();
                } else {
                    event.accepted = true;
                    searchInput.cursorPosition = Math.min(searchInput.text.length, searchInput.cursorPosition + 1);
                }
            }

            Keys.onDownPressed: {
                event.accepted = true;
                if (root.showHistory) {
                    root.zone = "history";
                    historyListView.currentIndex = 0;
                    historyListView.forceActiveFocus();
                    SoundEngine.scroll();
                } else if (root.vkEnabled) {
                    root.focusKeyboard();
                    SoundEngine.scroll();
                } else if (root.query.trim() !== root.searchedQuery) {
                    if (root.submitSearch()) root.focusResults(true);
                    SoundEngine.scroll();
                } else {
                    SoundEngine.scroll();
                    if (root.results.length > 0) root.focusResults(false);
                }
            }

            Keys.onUpPressed: {
                event.accepted = true;
                if (root.vkEnabled) {
                } else {
                    SoundEngine.scroll();
                    if (root.results.length > 0) {
                        var idx = (resultsView.currentIndex - 1 + root.results.length) % root.results.length;
                        resultsView.currentIndex = idx;
                        AppState.selectGame(root.results[idx].game, idx);
                    }
                }
            }

            Keys.onPressed: {
                if (event.key === Qt.Key_Escape) {
                    event.accepted = true;
                    NavigationManager.goBack();
                    return;
                }
                if (api.keys.isCancel(event)) {
                    event.accepted = true;
                    if (searchInput.text.length > 0) {
                        var sStart = Math.min(searchInput.selectionStart, searchInput.selectionEnd);
                        var sEnd = Math.max(searchInput.selectionStart, searchInput.selectionEnd);
                        if (sStart !== sEnd) {
                            searchInput.text = searchInput.text.substring(0, sStart) + searchInput.text.substring(sEnd);
                            searchInput.cursorPosition = sStart;
                        } else if (searchInput.cursorPosition > 0) {
                            var pos = searchInput.cursorPosition;
                            searchInput.text = searchInput.text.substring(0, pos - 1) + searchInput.text.substring(pos);
                            searchInput.cursorPosition = pos - 1;
                        }
                    } else {
                        NavigationManager.goBack();
                    }
                    return;
                }
                if (root.vkEnabled && api.keys.isPrevPage(event) && (!event.text || event.text.charCodeAt(0) < 32)) {
                    event.accepted = true;
                    var np1 = Math.max(0, searchInput.cursorPosition - 1);
                    if (np1 !== searchInput.cursorPosition) { searchInput.cursorPosition = np1; SoundEngine.scroll(); }
                    return;
                }
                if (root.vkEnabled && api.keys.isNextPage(event) && (!event.text || event.text.charCodeAt(0) < 32)) {
                    event.accepted = true;
                    var np2 = Math.min(searchInput.text.length, searchInput.cursorPosition + 1);
                    if (np2 !== searchInput.cursorPosition) { searchInput.cursorPosition = np2; SoundEngine.scroll(); }
                    return;
                }
                if (root._isPhysicalEnter(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    if (root.vkEnabled) {
                        if (root.submitSearch() && root.focusResults(true)) SoundEngine.select();
                        else SoundEngine.back();
                    } else if (root.query.trim() !== root.searchedQuery) {
                        if (root.submitSearch() && root.focusResults(true)) SoundEngine.select();
                        else SoundEngine.back();
                    } else if (AppState.currentGame) {
                        NavigationManager.enterGameDetails();
                    }
                    return;
                }
                if (root.vkEnabled && api.keys.isAccept(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    root.focusKeyboard();
                    SoundEngine.select();
                    return;
                }
            }
        }

        Rectangle {
            id: historyBtn
            visible: root.historyAvailable && root.zone !== "keyboard"
            focus: root.zone === "history_button"

            anchors.right: parent.right
            anchors.rightMargin: Math.round(PocketMetrics.spacing * 0.6)
            anchors.verticalCenter: parent.verticalCenter
            width: historyBtnText.implicitWidth + 16
            height: parent.height * 0.6
            color: root.zone === "history_button" ? colors.accent : "transparent"
            border.color: root.zone === "history_button" ? colors.accent : colors.border
            border.width: 1
            radius: 2

            Text {
                id: historyBtnText
                anchors.centerIn: parent
                text: Language.t("search_recent")
                color: root.zone === "history_button" ? colors.bg : colors.muted
                font.pixelSize: PocketMetrics.bodySize * 0.7
                font.family: SettingsManager.fontFamily
                font.bold: true
            }

            Keys.onLeftPressed: {
                event.accepted = true;
                root.focusInput();
                SoundEngine.scroll();
            }
            Keys.onRightPressed: {
                event.accepted = true;
            }
            Keys.onDownPressed: {
                event.accepted = true;
                if (root.vkEnabled) {
                    root.focusKeyboard();
                    SoundEngine.scroll();
                }
            }
            Keys.onUpPressed: {
                event.accepted = true;
                root.focusInput();
                SoundEngine.scroll();
            }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    root.openHistory();
                    SoundEngine.select();
                } else if (api.keys.isCancel(event)) {
                    event.accepted = true;
                    root.focusInput();
                    SoundEngine.back();
                }
            }
        }

        Row {
            id: vkHint
            visible: root.vkEnabled && !historyBtn.visible
            anchors.right: parent.right
            anchors.rightMargin: Math.round(PocketMetrics.spacing * 0.6)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(PocketMetrics.spacing * 0.4)

            readonly property real hintSize: Math.max(10, Math.round(PocketMetrics.bodySize * 0.8))

            Rectangle {
                width: lText.implicitWidth + 8
                height: lText.implicitHeight + 4
                color: "transparent"
                border.width: 1
                border.color: colors.muted
                radius: 0
                antialiasing: false
                Text {
                    id: lText
                    anchors.centerIn: parent
                    text: "L"
                    color: colors.muted
                    font.pixelSize: vkHint.hintSize
                    font.family: SettingsManager.fontFamily
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "<  >"
                color: colors.muted
                font.pixelSize: vkHint.hintSize
                font.family: SettingsManager.fontFamily
            }

            Rectangle {
                width: rText.implicitWidth + 8
                height: rText.implicitHeight + 4
                color: "transparent"
                border.width: 1
                border.color: colors.muted
                radius: 0
                antialiasing: false
                Text {
                    id: rText
                    anchors.centerIn: parent
                    text: "R"
                    color: colors.muted
                    font.pixelSize: vkHint.hintSize
                    font.family: SettingsManager.fontFamily
                }
            }
        }

        Rectangle {
            id: vkCursor
            visible: root.zone === "keyboard"
            x: searchInput.x + searchInput.cursorRectangle.x
            y: searchInput.y + searchInput.cursorRectangle.y
            width: Math.max(2, Math.round(searchInput.font.pixelSize * 0.55))
            height: searchInput.cursorRectangle.height
            color: colors.accent
            opacity: 0.7

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: vkCursor.visible && EffectsManager.loopingAnimationsEnabled
                NumberAnimation { to: 0.15; duration: 450 }
                NumberAnimation { to: 0.7; duration: 450 }
            }
        }
    }

    VirtualKeyboard {
        id: vk
        anchors.fill: parent
        target: searchInput
        active: root.zone === "keyboard"
        visible: root.vkEnabled && !root.showHistory && root.zone !== "results"
        showSearchButton: true
        showHideButton: false
        submitLabel: "SEARCH"
        submitEnabled: root.query.trim() !== ""

        onSubmitted: {
            if (root.submitSearch() && root.focusResults()) SoundEngine.select();
            else SoundEngine.back();
        }
        onCanceled: {
            NavigationManager.goBack();
        }
        onExitRequested: {
            root.focusInput();
            SoundEngine.scroll();
        }
    }

    Item {
        id: helpArea
        anchors.top: searchBox.bottom
        anchors.topMargin: PocketMetrics.spacing * 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PocketMetrics.margin
        anchors.horizontalCenter: parent.horizontalCenter
        width: vk.keyboardWidth
        visible: root.showSearchHelp
        clip: true

        Flickable {
            anchors.fill: parent
            contentWidth: width
            contentHeight: helpColumn.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: helpColumn
                width: parent.width
                spacing: Math.max(4, Math.round(PocketMetrics.spacing * 0.4))

                Text {
                    text: Language.t("search_help_title")
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    color: colors.accent
                    font.pixelSize: PocketMetrics.bodySize * 1.1
                    font.bold: true
                    font.family: SettingsManager.fontFamily
                    bottomPadding: 4
                }

                component HelpRow: Row {
                    width: root.isTiny ? (helpGrid.width - helpGrid.spacing) / 2 : helpGrid.width
                    spacing: root.isTiny ? 2 : PocketMetrics.spacing

                    readonly property bool tiny: root.isTiny
                    readonly property real _avail: Math.max(0, width - (tiny ? spacing : spacing * 3))
                    readonly property real _labelW: tiny ? _avail * 0.4 : _avail * 0.35
                    readonly property real _exW: tiny ? _avail * 0.6 : _avail * 0.45
                    readonly property real _spacerW: tiny ? 0 : Math.max(0, (_avail - _labelW - _exW) / 2)

                    Item { width: parent._spacerW; height: 1 }

                    Text {
                        width: parent._labelW
                        text: modelData.label
                        color: colors.fg
                        font.pixelSize: PocketMetrics.bodySize
                        font.bold: true
                        font.family: SettingsManager.fontFamily
                        horizontalAlignment: Text.AlignRight
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent._exW
                        text: modelData.example
                        color: colors.muted
                        font.pixelSize: PocketMetrics.bodySize
                        font.family: SettingsManager.fontFamily
                        horizontalAlignment: Text.AlignLeft
                        wrapMode: Text.WordWrap
                    }

                    Item { width: parent._spacerW; height: 1 }
                }

                Grid {
                    id: helpGrid
                    width: parent.width
                    columns: root.isTiny ? 2 : 1
                    spacing: Math.max(4, Math.round(PocketMetrics.spacing * 0.4))

                    Repeater {
                        model: [
                            { label: Language.t("search_help_word_lbl"), example: Language.t("search_help_word_ex") },
                            { label: Language.t("search_help_every_lbl"), example: Language.t("search_help_every_ex") },
                            { label: Language.t("search_help_year_lbl"), example: Language.t("search_help_year_ex") },
                            { label: Language.t("search_help_yrange_lbl"), example: Language.t("search_help_yrange_ex") },
                            { label: Language.t("search_help_rating_lbl"), example: Language.t("search_help_rating_ex") },
                            { label: Language.t("search_help_mix1_lbl"), example: Language.t("search_help_mix1_ex") },
                            { label: Language.t("search_help_mix2_lbl"), example: Language.t("search_help_mix2_ex") }
                        ]
                        delegate: HelpRow {}
                    }
                }
            }
        }
    }

    Item {
        id: resultsArea
        anchors.top: searchBox.bottom
        anchors.topMargin: PocketMetrics.spacing
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PocketMetrics.margin
        anchors.horizontalCenter: parent.horizontalCenter
        width: vk.keyboardWidth
        visible: !root.editingMode && !root.showHistory

        ListView {
            id: resultsView
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width - root.scrollBarWidth - root.scrollBarMargin
            clip: true
            model: root.results

            readonly property real rowHeight: PocketMetrics.bodySize * 5.2 + spacing
            readonly property int visibleRows: Math.max(1, Math.floor(height / rowHeight))
            readonly property real scrollFraction: count > visibleRows ? currentIndex / Math.max(1, count - 1) : 0

            currentIndex: 0
            highlightMoveDuration: EffectsManager.dur(120)
            boundsBehavior: Flickable.StopAtBounds
            spacing: 2

            delegate: Rectangle {
                property var entry: modelData
                width: resultsView.width
                height: PocketMetrics.bodySize * 5.2
                color: index === resultsView.currentIndex ? colors.card : "transparent"
                radius: 4

                Behavior on color {
                    enabled: EffectsManager.animationsEnabled
                    ColorAnimation { duration: EffectsManager.dur(140) }
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: PocketMetrics.spacing * 0.7
                    anchors.rightMargin: PocketMetrics.spacing * 0.7
                    spacing: 4

                    Item {
                        width: parent.width
                        height: Math.max(titleText.implicitHeight, collectionText.implicitHeight)

                        MarqueeText {
                            id: titleText
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - collectionText.width - PocketMetrics.spacing
                            text: GameUtils.cleanGameTitle(entry.game.title)
                            color: (index === resultsView.currentIndex || entry.matched.title)
                            ? colors.accent : colors.fg
                            pixelSize: PocketMetrics.bodySize
                            bold: (index === resultsView.currentIndex || entry.matched.title)
                            active: index === resultsView.currentIndex
                            padVertical: 0
                        }

                        MarqueeText {
                            id: collectionText
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(parent.width * 0.4, implicitWidth)
                            text: {
                                var cols = entry.game.collections;
                                if (cols && cols.count > 0) return cols.get(0).name;
                                return "";
                            }
                            color: colors.muted
                            pixelSize: PocketMetrics.bodySize * 0.8
                            active: index === resultsView.currentIndex
                            padVertical: 0
                            provideImplicitSize: true
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    Item {
                        width: parent.width
                        height: metaRow.implicitHeight
                        clip: true

                        Row {
                            id: metaRow
                            spacing: 4
                            Repeater {
                                id: metaRepeater
                                model: entry.segments
                                delegate: Row {
                                    spacing: 4
                                    Text {
                                        text: modelData.text
                                        color: modelData.highlight ? colors.accent : colors.muted
                                        font.pixelSize: PocketMetrics.bodySize * 0.85
                                        font.bold: modelData.highlight
                                        font.family: SettingsManager.fontFamily
                                    }
                                    Text {
                                        visible: index < metaRepeater.count - 1
                                        text: "·"
                                        color: colors.muted
                                        font.pixelSize: PocketMetrics.bodySize * 0.85
                                        font.family: SettingsManager.fontFamily
                                    }
                                }
                            }
                        }
                    }
                }
            }

            onCurrentIndexChanged: {
                if (root._restoring) return;
                AppState.searchCurrentIndex = currentIndex;
                if (currentIndex >= 0 && currentIndex < root.results.length) {
                    AppState.selectGame(root.results[currentIndex].game, currentIndex);
                }
            }

            Keys.onUpPressed: {
                event.accepted = true;
                if (resultsView.currentIndex === 0) {
                    root.focusInput();
                    SoundEngine.scroll();
                } else {
                    SoundEngine.scroll();
                    resultsView.decrementCurrentIndex();
                }
            }

            Keys.onDownPressed: {
                event.accepted = true;
                SoundEngine.scroll();
                if (resultsView.currentIndex < root.results.length - 1)
                    resultsView.incrementCurrentIndex();
            }

            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    if (AppState.currentGame) NavigationManager.enterGameDetails();
                } else if (api.keys.isCancel(event)) {
                    event.accepted = true;
                    NavigationManager.goBack();
                }
            }
        }

        ScrollIndicator {
            listView: resultsView
            visibleRows: resultsView.visibleRows
            scrollFraction: resultsView.scrollFraction
            totalCount: resultsView.count
            trackColor: colors.card
            thumbColor: colors.accent
            barWidth: root.scrollBarWidth
        }
    }

    Item {
        id: historyArea
        anchors.top: searchBox.bottom
        anchors.topMargin: PocketMetrics.spacing
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PocketMetrics.margin
        anchors.horizontalCenter: parent.horizontalCenter
        width: vk.keyboardWidth
        visible: root.showHistory

        Text {
            id: historyHeader
            anchors.top: parent.top
            anchors.left: parent.left
            text: Language.t("search_recent")
            color: colors.muted
            font.pixelSize: PocketMetrics.bodySize * 0.85
            font.bold: true
            font.family: SettingsManager.fontFamily
            opacity: 0.75
        }

        HintBar {
            id: historyHint
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            text: root.historyConfirmMode
            ? Language.t("search_clear_confirm")
            : Language.t("search_hint_history")
            color: colors.muted
        }

        ListView {
            id: historyListView
            anchors.top: historyHeader.bottom
            anchors.topMargin: PocketMetrics.spacing * 0.5
            anchors.bottom: historyHint.top
            anchors.bottomMargin: PocketMetrics.spacing * 0.5
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.rightMargin: root.scrollBarWidth + root.scrollBarMargin
            clip: true
            model: root.historyEntries
            spacing: 2
            highlightMoveDuration: EffectsManager.dur(120)
            boundsBehavior: Flickable.StopAtBounds

            readonly property real rowHeight: PocketMetrics.bodySize * 2.6 + spacing
            readonly property int visibleRows: Math.max(1, Math.floor(height / rowHeight))
            readonly property real scrollFraction: count > visibleRows ? currentIndex / Math.max(1, count - 1) : 0

            delegate: Rectangle {
                width: historyListView.width
                height: PocketMetrics.bodySize * 2.6
                color: index === historyListView.currentIndex ? colors.card : "transparent"
                radius: 4

                Behavior on color {
                    enabled: EffectsManager.animationsEnabled
                    ColorAnimation { duration: EffectsManager.dur(140) }
                }

                MarqueeText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: PocketMetrics.spacing * 0.7
                    anchors.rightMargin: PocketMetrics.spacing * 0.7
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - PocketMetrics.spacing * 1.4
                    text: modelData.query
                    color: index === historyListView.currentIndex ? colors.accent : colors.fg
                    pixelSize: PocketMetrics.bodySize
                    bold: index === historyListView.currentIndex
                    active: index === historyListView.currentIndex
                    padVertical: 0
                }
            }

            Keys.onUpPressed: {
                event.accepted = true;
                SoundEngine.scroll();
                root.historyConfirmMode = false;
                if (historyListView.currentIndex === 0) {
                    root.closeHistory();
                } else {
                    historyListView.decrementCurrentIndex();
                }
            }

            Keys.onDownPressed: {
                event.accepted = true;
                SoundEngine.scroll();
                root.historyConfirmMode = false;
                if (historyListView.currentIndex < root.historyEntries.length - 1) {
                    historyListView.incrementCurrentIndex();
                } else {
                    if (root.vkEnabled) {
                        root.showHistory = false;
                        root.focusKeyboard();
                    } else {
                        root.closeHistory();
                    }
                }
            }

            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    if (root.historyConfirmMode) {
                        root.clearHistory();
                        SoundEngine.select();
                    } else {
                        if (root.runHistoryEntry(historyListView.currentIndex)) {
                            SoundEngine.select();
                        } else {
                            SoundEngine.back();
                        }
                    }
                    return;
                }
                if (api.keys.isCancel(event)) {
                    event.accepted = true;
                    if (root.historyConfirmMode) {
                        root.historyConfirmMode = false;
                        SoundEngine.back();
                    } else {
                        root.closeHistory();
                        SoundEngine.back();
                    }
                    return;
                }
                if (api.keys.isDetails(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    SoundEngine.back();
                    root.removeFromHistory(historyListView.currentIndex);
                    return;
                }
                if (api.keys.isFilters(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    SoundEngine.select();
                    root.historyConfirmMode = !root.historyConfirmMode;
                    return;
                }
                if (event.text && event.text.length > 0 && event.text.charCodeAt(0) >= 32) {
                    event.accepted = true;
                    var ch = event.text;
                    root.closeHistory();
                    searchInput.text = searchInput.text + ch;
                    searchInput.cursorPosition = searchInput.text.length;
                    return;
                }
            }
        }

        ScrollIndicator {
            listView: historyListView
            visibleRows: historyListView.visibleRows
            scrollFraction: historyListView.scrollFraction
            totalCount: historyListView.count
            trackColor: colors.card
            thumbColor: colors.accent
            barWidth: root.scrollBarWidth
        }
    }

    Text {
        id: emptyText
        readonly property real topY: searchBox.y + searchBox.height
        readonly property real botY: (root.editingMode && !root.showHistory) ? (parent.height - vk.totalHeight) : root.height
        anchors.horizontalCenter: parent.horizontalCenter
        width: vk.keyboardWidth
        y: topY + Math.max(0, (botY - topY - height) / 2)
        visible: root.noResultsShown
        text: Language.t("search_empty")
        color: colors.muted
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        font.pixelSize: PocketMetrics.bodySize * 1.2
        font.family: SettingsManager.fontFamily
    }
}
