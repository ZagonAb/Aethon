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

    readonly property string memoryKey: "aethon.retroachievements"
    readonly property string sessionsMemoryKey: "aethon.ra_sessions"
    readonly property string apiBase: "https://retroachievements.org/API/"
    readonly property string mediaBase: "https://media.retroachievements.org"

    property string apiUser: ""
    property string apiKey: ""
    property string apiUserPic: ""
    readonly property bool hasCredentials: root.apiUser !== "" && root.apiKey !== ""

    property string testState: "idle"
    property string testMessage: ""
    property string pendingUser: ""

    property var savedSessions: []

    readonly property int authTimeoutMs: 20000

    property int _authToken: 0
    property int _dataEpoch: 0
    property var _authXhr: null

    property Timer _authTimer: Timer {
        interval: root.authTimeoutMs
        repeat: false
        onTriggered: root._onAuthTimeout()
    }

    function _norm(u) { return String(u || "").trim().toLowerCase(); }

    function sameUser(a, b) {
        var na = root._norm(a);
        return na !== "" && na === root._norm(b);
    }

    function isActive(user) {
        return root.hasCredentials && root.sameUser(user, root.apiUser);
    }

    function _picFor(user) {
        return root.mediaBase + "/UserPic/" + user + ".png";
    }

    function _indexOfSession(user, list) {
        var l = list || root.savedSessions;
        for (var i = 0; i < l.length; i++) {
            if (root.sameUser(l[i].user, user)) return i;
        }
        return -1;
    }

    function _sanitizeSessions(raw) {
        var out = [];
        if (!raw) return out;
        for (var i = 0; i < raw.length; i++) {
            var s = raw[i];
            if (!s || !s.user || !s.key) continue;
            if (root._indexOfSession(s.user, out) >= 0) continue;
            out.push({
                user: String(s.user),
                     key: String(s.key),
                     userPic: s.userPic ? String(s.userPic) : root._picFor(s.user)
            });
        }
        return out;
    }

    function _persistSessions() {
        api.memory.set(root.sessionsMemoryKey, root.savedSessions);
    }

    function _upsertSession(user, key, pic) {
        var list = root.savedSessions.slice();
        var entry = { user: user, key: key, userPic: pic || root._picFor(user) };
        var i = root._indexOfSession(user, list);
        if (i >= 0) list[i] = entry;
        else list.push(entry);
        root.savedSessions = list;
        root._persistSessions();
    }

    function load() {
        var data = api.memory.get(root.memoryKey);
        if (!data) {
            root.apiUser = "";
            root.apiKey = "";
            root.apiUserPic = "";
        } else {
            root.apiUser = data.apiUser || "";
            root.apiKey = data.apiKey || "";
            root.apiUserPic = root.apiUser !== "" ? root._picFor(root.apiUser) : "";
        }

        root.savedSessions = root._sanitizeSessions(api.memory.get(root.sessionsMemoryKey));

        if (root.hasCredentials) {
            var i = root._indexOfSession(root.apiUser, root.savedSessions);
            if (i < 0 || root.savedSessions[i].key !== root.apiKey)
                root._upsertSession(root.apiUser, root.apiKey, root.apiUserPic);
        }
    }

    function save() {
        api.memory.set(root.memoryKey, {
            apiUser: root.apiUser,
            apiKey: root.apiKey
        });
        console.log("[RetroAchievements] Guardado. Usuario:", root.apiUser || "(vacío)");
    }

    function _resetData() {
        root._dataEpoch++;

        root._cache = ({});
        root._completionList = null;
        root._completionListTime = 0;
        root._gameListCache = ({});
        root._pendingKey = "";

        root.raState = "idle";
        root._clearResult();

        root.libraryChunkTimer.stop();
        root.libraryState = "idle";
        root.libraryProgress = 0.0;
        root.libraryEntries = [];
        root._libRaList = [];
        root._libPegAll = [];
        root._libPegShort = [];
        root._libEntriesAccum = [];
        root._libTotal = 0;
        root._libProcessed = 0;
    }

    function _commit(user, key, pic, addSession) {
        var accountChanged = !(root.sameUser(user, root.apiUser) && key === root.apiKey);

        root.apiUser = user;
        root.apiKey = key;
        root.apiUserPic = pic || root._picFor(user);
        root.save();

        if (addSession) root._upsertSession(user, key, root.apiUserPic);
        if (accountChanged) root._resetData();
    }

    function _cancelAuth() {
        root._authToken++;
        root._authTimer.stop();
        if (root._authXhr) {
            try { root._authXhr.abort(); } catch (e) { }
            root._authXhr = null;
        }
        root.pendingUser = "";
    }

    function cancelTest() {
        if (root.testState !== "testing") return;
        root._cancelAuth();
        root.testState = "idle";
        root.testMessage = "";
    }

    function _onAuthTimeout() {
        if (root.testState !== "testing") return;
        root._cancelAuth();
        root.testState = "error";
        root.testMessage = Language.t("ra_msg_timeout");
    }

    function logout() {
        root._cancelAuth();
        root.apiUser = "";
        root.apiKey = "";
        root.apiUserPic = "";
        root.testState = "idle";
        root.testMessage = "";
        root.save();
        root._resetData();
    }

    function switchSession(user) {
        var i = root._indexOfSession(user, root.savedSessions);
        if (i < 0) return false;

        var ses = root.savedSessions[i];
        if (root.isActive(ses.user) && root.testState !== "testing") return true;

        root.testAndSave(ses.user, ses.key);
        return true;
    }

    function deleteSession(user) {
        if (root.isActive(user)) return "active";

        var i = root._indexOfSession(user, root.savedSessions);
        if (i < 0) return "notfound";

        var list = root.savedSessions.slice();
        list.splice(i, 1);
        root.savedSessions = list;
        root._persistSessions();
        return "ok";
    }

    function testAndSave(user, key) {
        var u = (user || "").trim();
        var k = (key || "").trim();

        if (u === "" || k === "") {
            root.testState = "error";
            root.testMessage = Language.t("ra_msg_missing_fields");
            return;
        }

        root._cancelAuth();
        var token = root._authToken;

        root.testState = "testing";
        root.testMessage = "";
        root.pendingUser = u;

        var known = root._indexOfSession(u, root.savedSessions) >= 0;

        var url = root.apiBase + "API_GetUserSummary.php"
        + "?y=" + encodeURIComponent(k)
        + "&u=" + encodeURIComponent(u)
        + "&g=1";

        var xhr = new XMLHttpRequest();
        root._authXhr = xhr;
        root._authTimer.restart();

        xhr.open("GET", url, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (token !== root._authToken) return;

            root._authTimer.stop();
            root._authXhr = null;
            root.pendingUser = "";

            if (xhr.status === 200) {
                var data = null;
                try {
                    data = JSON.parse(xhr.responseText);
                } catch (e) {
                    root.testState = "error";
                    root.testMessage = Language.t("ra_msg_parse_error");
                    return;
                }

                if (data && (data.User || data.Username || data.MemberSince)) {
                    var displayName = data.User || data.Username || u;
                    var pic = data.UserPic ? (root.mediaBase + data.UserPic) : root._picFor(displayName);
                    root._commit(displayName, k, pic, true);
                    root.testState = "success";
                    root.testMessage = Language.t("ra_msg_connected_prefix") + displayName;
                } else {
                    root.testState = "error";
                    root.testMessage = Language.t("ra_msg_invalid");
                }
            } else if (xhr.status === 401 || xhr.status === 403) {
                root.testState = "error";
                root.testMessage = Language.t("ra_msg_invalid");
            } else if (xhr.status === 0) {
                root._commit(u, k, root._picFor(u), known);
                root.testState = "offline";
                root.testMessage = Language.t("ra_msg_offline");
            } else {
                root.testState = "error";
                root.testMessage = Language.t("ra_msg_server_error_prefix") + xhr.status;
            }
        };
        xhr.send();
    }

    Component.onCompleted: {
        root.load();
    }

    property string raState: "idle"
    property string raGameId: ""
    property string raTitle: ""
    property string raConsole: ""
    property string raIconUrl: ""
    property int raNumAchievements: 0
    property int raNumEarned: 0
    property int raPoints: 0
    property int raPointsEarned: 0
    property var raAchievements: []

    property var _cache: ({})
    property string _pendingKey: ""

    property var _completionList: null
    property double _completionListTime: 0
    readonly property int _completionListTtlMs: 10 * 60 * 1000
    property var _gameListCache: ({})

    property var _prefixKeyList: []

    function _normKey(s) {
        return (s || "").toLowerCase().replace(/[^a-z0-9]/g, "");
    }

    function _prefixKeys() {
        if (root._prefixKeyList.length > 0) return root._prefixKeyList;
        var out = [], k;
        for (k in root._consoleIds) if (k.length >= 3) out.push(k);
        for (k in root._consoleAliases) if (k.length >= 5) out.push(k);
        out.sort(function (a, b) { return b.length - a.length; });
        root._prefixKeyList = out;
        return out;
    }

    function _canonicalConsole(norm) {
        if (!norm) return "";
        if (root._consoleIds[norm]) return norm;
        if (root._consoleAliases[norm]) return root._consoleAliases[norm];

        var keys = root._prefixKeys();
        for (var i = 0; i < keys.length; i++) {
            var k = keys[i];
            if (norm.length > k.length && norm.indexOf(k) === 0)
                return root._consoleIds[k] ? k : root._consoleAliases[k];
        }
        return "";
    }

    function _resolveConsole(game) {
        if (!game) return "";
        var found = "";

        try {
            if (game.collections) {
                var n = Math.min(game.collections.count || 0, 10);
                for (var i = 0; i < n && found === ""; i++) {
                    var col = game.collections.get(i);
                    if (!col) continue;
                    found = root._canonicalConsole(root._normKey(col.shortName))
                    || root._canonicalConsole(root._normKey(col.name));
                }
            }
        } catch (e) { }
        if (found !== "") return found;

        try {
            if (game.files && game.files.count > 0) {
                var path = String(game.files.get(0).path || "").replace(/\\/g, "/");
                var parts = path.split("/");
                for (var d = 2; d <= 4 && found === ""; d++) {
                    if (parts.length >= d)
                        found = root._canonicalConsole(root._normKey(parts[parts.length - d]));
                }
                if (found === "") {
                    var fname = parts[parts.length - 1];
                    var dot = fname.lastIndexOf(".");
                    if (dot > 0) {
                        var ext = fname.substring(dot + 1).toLowerCase();
                        found = root._extConsole[ext] || "";
                    }
                }
            }
        } catch (e2) { }

        return found;
    }

    function _stripTags(str) {
        if (!str) return "";
        var s = str.replace(/\([^)]*\)/g, " ").replace(/\[[^\]]*\]/g, " ").replace(/\s+/g, " ").trim();
        return s !== "" ? s : str;
    }

    function _cacheKeyFor(game, colShort) {
        if (!game) return "";
        return colShort + "::" + (game.title || "");
    }

    function _apiUrl(endpoint, params) {
        var url = root.apiBase + endpoint + "?y=" + encodeURIComponent(root.apiKey);
        for (var k in params) url += "&" + k + "=" + encodeURIComponent(params[k]);
        return url;
    }

    function _get(url, cb) {
        var epoch = root._dataEpoch;
        var xhr = new XMLHttpRequest();
        xhr.open("GET", url, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (epoch !== root._dataEpoch) return;
            if (xhr.status === 200) {
                try { cb(null, JSON.parse(xhr.responseText)); }
                catch (e) { cb("JSON parse error: " + e, null); }
            } else {
                cb("HTTP " + xhr.status, null);
            }
        };
        xhr.send();
    }

    function _applyResult(state, result) {
        root.raState = state;
        if (!result) {
            root._clearResult();
            return;
        }
        root.raGameId = result.raGameId || "";
        root.raTitle = result.raTitle || "";
        root.raConsole = result.raConsole || "";
        root.raIconUrl = result.raIconUrl || "";
        root.raNumAchievements = result.raNumAchievements || 0;
        root.raNumEarned = result.raNumEarned || 0;
        root.raPoints = result.raPoints || 0;
        root.raPointsEarned = result.raPointsEarned || 0;
        root.raAchievements = result.raAchievements || [];
    }

    function _clearResult() {
        root.raGameId = "";
        root.raTitle = "";
        root.raConsole = "";
        root.raIconUrl = "";
        root.raNumAchievements = 0;
        root.raNumEarned = 0;
        root.raPoints = 0;
        root.raPointsEarned = 0;
        root.raAchievements = [];
    }

    function lookupGame(game, collectionShortName) {
        if (!game) {
            root.raState = "idle";
            root._clearResult();
            return;
        }

        if (!root.hasCredentials) {
            root.raState = "no_credentials";
            root._clearResult();
            return;
        }

        var colShort = root._resolveConsole(game)
        || root._canonicalConsole(root._normKey(collectionShortName));
        if (colShort === "")
            console.log("[RetroAchievements] Consola no resuelta para:", game.title,
                        "| colección:", collectionShortName);

            var key = root._cacheKeyFor(game, colShort);
        root._pendingKey = key;

        if (root._cache[key]) {
            var cached = root._cache[key];
            root._applyResult(cached.state, cached.result);
            return;
        }

        root.raState = "searching";
        root._clearResult();

        var pegTitle = game.title || "";
        var directId = "";
        try {
            if (game.extra && game.extra.ra_id) directId = game.extra.ra_id;
            else if (game.extra && game.extra.retroachievements_id) directId = game.extra.retroachievements_id;
        } catch (e) { }

        if (directId !== "") {
            root._fetchProgress(String(directId), key);
        } else {
            root._searchForGame(pegTitle, colShort, key);
        }
    }

    function _finishIfStillPending(key, state, result) {
        if (state !== "error")
            root._cache[key] = { state: state, result: result || null };
        if (root._pendingKey === key) {
            root._applyResult(state, result);
        }
    }

    function _getCompletionList(cb) {
        var now = Date.now();
        if (root._completionList && (now - root._completionListTime) < root._completionListTtlMs) {
            cb(null, root._completionList);
            return;
        }
        var url = root._apiUrl("API_GetUserCompletionProgress.php", { u: root.apiUser, c: 500, o: 0 });
        root._get(url, function (err, data) {
            if (err || !data) { cb(err || "empty", null); return; }
            var list = data.Results || (Array.isArray(data) ? data : []);
            root._completionList = list;
            root._completionListTime = Date.now();
            cb(null, list);
        });
    }

    function _searchForGame(pegTitle, colShort, key) {
        root._getCompletionList(function (err, list) {
            if (root._pendingKey !== key) return;

            if (err || !list) {
                root._finishIfStillPending(key, "error", null);
                return;
            }

            var raConsoles = root._consoleMappings[colShort] || [];

            var scored = [];
            for (var i = 0; i < list.length; i++) {
                var g = list[i];
                var sc = root._matchScore(pegTitle, g.Title || "");
                if (raConsoles.length > 0 && (g.ConsoleName || "") !== "") {
                    var consoleMatch = false;
                    for (var ci = 0; ci < raConsoles.length; ci++) {
                        if ((g.ConsoleName || "").indexOf(raConsoles[ci]) !== -1) { consoleMatch = true; break; }
                    }
                    sc = consoleMatch ? sc + 0.5 : sc - 0.2;
                }
                scored.push({ g: g, score: sc });
            }
            scored.sort(function (a, b) { return b.score - a.score; });

            var best = scored.length > 0 ? scored[0] : null;
            var bestF1 = best ? root._matchScore(pegTitle, best.g.Title || "") : 0;

            var bestConsoleMatch = false;
            if (best && raConsoles.length > 0 && (best.g.ConsoleName || "") !== "") {
                for (var cj = 0; cj < raConsoles.length; cj++) {
                    if ((best.g.ConsoleName || "").indexOf(raConsoles[cj]) !== -1) { bestConsoleMatch = true; break; }
                }
            }
            var consoleCheckRequired = raConsoles.length > 0;
            var consoleOk = !consoleCheckRequired || bestConsoleMatch;

            var accepted = best && bestF1 >= 0.70 && best.score >= 0.60 && consoleOk;

            if (accepted) {
                root._fetchProgress(String(best.g.GameID || ""), key);
            } else {
                root._searchByGameList(pegTitle, colShort, key);
            }
        });
    }

    function _searchByGameList(pegTitle, colShort, key) {
        var cid = root._consoleIds[colShort] || 0;
        if (cid === 0) {
            root._finishIfStillPending(key, "not_found", null);
            return;
        }

        function processList(data) {
            var scored = [];
            for (var i = 0; i < data.length; i++) {
                var g = data[i];
                scored.push({ g: g, score: root._matchScore(pegTitle, g.Title || "") });
            }
            scored.sort(function (a, b) { return b.score - a.score; });

            var best = scored.length > 0 ? scored[0] : null;
            if (best && best.score >= 0.55) {
                root._fetchProgress(String(best.g.ID || best.g.GameID || ""), key);
            } else {
                root._finishIfStillPending(key, "not_found", null);
            }
        }

        if (root._gameListCache[cid]) {
            processList(root._gameListCache[cid]);
            return;
        }

        var url = root._apiUrl("API_GetGameList.php", { i: cid });
        root._get(url, function (err, data) {
            if (root._pendingKey !== key) return;

            if (err || !Array.isArray(data)) {
                root._finishIfStillPending(key, "error", null);
                return;
            }

            root._gameListCache[cid] = data;
            processList(data);
        });
    }

    function _fetchProgress(gid, key) {
        if (root._pendingKey === key) root.raState = "loading";

        var url = root._apiUrl("API_GetGameInfoAndUserProgress.php", { u: root.apiUser, g: gid });
        root._get(url, function (err, data) {
            if (root._pendingKey !== key) { }

            if (err || !data) {
                root._finishIfStillPending(key, "error", null);
                return;
            }

            var achMap = data.Achievements || {};
            var ach = [];
            var totalPoints = 0, earnedPoints = 0, numEarned = 0;

            for (var id in achMap) {
                var a = achMap[id];
                var earned = !!(a.DateEarned && a.DateEarned !== "");
                var pts = parseInt(a.Points) || 0;
                totalPoints += pts;
                if (earned) { earnedPoints += pts; numEarned++; }
                ach.push({
                    id: id,
                    title: a.Title || "",
                    description: a.Description || "",
                    points: pts,
                    badgeUrl: a.BadgeName ? (root.mediaBase + "/Badge/" + a.BadgeName + ".png") : "",
                         badgeLocked: a.BadgeName ? (root.mediaBase + "/Badge/" + a.BadgeName + "_lock.png") : "",
                         earned: earned,
                         dateEarned: earned ? a.DateEarned : "",
                         numAwarded: parseInt(a.NumAwarded) || 0,
                         trueRatio: parseInt(a.TrueRatio) || 0,
                         displayOrder: parseInt(a.DisplayOrder) || parseInt(id) || 0
                });
            }
            ach.sort(function (a, b) {
                if (a.earned !== b.earned) return a.earned ? -1 : 1;
                return a.displayOrder - b.displayOrder;
            });

            var numAch = parseInt(data.NumAchievements) || ach.length;

            var result = {
                raGameId: gid,
                raTitle: data.Title || "",
                raConsole: data.ConsoleName || "",
                raIconUrl: data.ImageIcon ? (root.mediaBase + data.ImageIcon) : "",
                  raNumAchievements: numAch,
                  raNumEarned: numEarned,
                  raPoints: totalPoints,
                  raPointsEarned: earnedPoints,
                  raAchievements: ach
            };

            var state = numAch === 0 ? "no_achievements" : "found";
            root._finishIfStillPending(key, state, result);
        });
    }

    function _romanToArabic(str) {
        var map = {
            "xv": "15", "xiv": "14", "xiii": "13", "xii": "12", "xi": "11",
            "x": "10", "ix": "9", "viii": "8", "vii": "7", "vi": "6",
            "v": "5", "iv": "4", "iii": "3", "ii": "2", "i": "1"
        };
        return str.replace(/\b(x(?:iv|v|i{1,3})?|i{1,3}|iv|vi{0,3}|viii|ix)\b/g, function (m) {
            return map[m] || m;
        });
    }

    function _normalize(str) {
        if (!str) return "";
        var s = str.toLowerCase()
        .replace(/[\u0027\u2018\u2019\u00b4\u0060]/g, "")
        .replace(/&/g, " and ");
        return root._romanToArabic(s)
        .replace(/\b(the|a|an)\b\s*/g, "")
        .replace(/[:\-\u2013\u2014_,\.\!\?®™©\(\)\[\]\/\\]/g, " ")
        .replace(/\s+/g, " ")
        .trim();
    }

    function _words(norm) {
        return norm.split(" ").filter(function (w) { return w.length >= 1; });
    }

    function _matchScore(pegTitle, raTitle) {
        var pNorm = root._normalize(root._stripTags(pegTitle));
        var rNorm = root._normalize(raTitle);

        if (pNorm === rNorm) return 2.0;

        if (pNorm.replace(/ /g, "") === rNorm.replace(/ /g, "")) return 1.9;

        var pWords = root._words(pNorm);
        var rWords = root._words(rNorm);
        if (pWords.length === 0) return 0.0;

        var hitsP = 0;
        for (var i = 0; i < pWords.length; i++) {
            if (rNorm.indexOf(pWords[i]) !== -1) hitsP++;
        }
        var precision = hitsP / pWords.length;

        var hitsR = 0;
        for (var j = 0; j < rWords.length; j++) {
            if (pNorm.indexOf(rWords[j]) !== -1) hitsR++;
        }
        var recall = rWords.length > 0 ? hitsR / rWords.length : 0;

        if (precision + recall === 0) return 0.0;
        var f1 = 2.0 * precision * recall / (precision + recall);

        var extraInRA = rWords.length - hitsR;
        var extraInPeg = pWords.length - hitsP;
        if (extraInRA > 0) f1 = Math.max(0.0, f1 - (extraInRA / rWords.length) * 0.5);
        if (extraInPeg > 0) f1 = Math.max(0.0, f1 - (extraInPeg / pWords.length) * 0.5);

        return f1;
    }

    readonly property var _consoleMappings: ({
        "snes": ["SNES/Super Famicom"], "superfamicom": ["SNES/Super Famicom"],
        "nes": ["NES/Famicom"], "famicom": ["NES/Famicom"],
        "fds": ["Famicom Disk System"], "famicomdisksystem": ["Famicom Disk System"],
        "n64": ["Nintendo 64"], "nintendo64": ["Nintendo 64"],
        "gb": ["Game Boy"], "gameboy": ["Game Boy"],
        "gbc": ["Game Boy Color"], "gameboycolor": ["Game Boy Color"],
        "gba": ["Game Boy Advance"], "gameboyadvance": ["Game Boy Advance"],
        "nds": ["Nintendo DS"], "nintendods": ["Nintendo DS"],
        "ndsi": ["Nintendo DSi"], "nintendodsi": ["Nintendo DSi"],
        "3ds": ["Nintendo 3DS"], "nintendo3ds": ["Nintendo 3DS"],
        "gamecube": ["GameCube"], "gc": ["GameCube"],
        "wii": ["Wii"], "wiiu": ["Wii U"],
        "virtualboy": ["Virtual Boy"], "pokemini": ["Pokemon Mini"],
        "genesis": ["Genesis/Mega Drive"], "megadrive": ["Genesis/Mega Drive"],
        "mastersystem": ["Master System"], "sms": ["Master System"],
        "gamegear": ["Game Gear"], "gg": ["Game Gear"],
        "saturn": ["Saturn"], "dreamcast": ["Dreamcast"],
        "segacd": ["Sega CD"], "megacd": ["Sega CD"],
        "32x": ["32X"], "sega32x": ["32X"],
        "segapico": ["Sega Pico"], "sg1000": ["SG-1000"],
        "psx": ["PlayStation"], "ps1": ["PlayStation"], "playstation": ["PlayStation"],
        "ps2": ["PlayStation 2"], "playstation2": ["PlayStation 2"],
        "psp": ["PlayStation Portable"],
        "atari2600": ["Atari 2600"], "atari5200": ["Atari 5200"], "atari7800": ["Atari 7800"],
        "lynx": ["Atari Lynx"], "atarilynx": ["Atari Lynx"],
        "jaguar": ["Atari Jaguar"], "atarijaguar": ["Atari Jaguar"],
        "jaguarcd": ["Atari Jaguar CD"], "atarijaguarcd": ["Atari Jaguar CD"],
        "atarist": ["Atari ST"],
        "pcengine": ["PC Engine/TurboGrafx-16"], "turbografx": ["PC Engine/TurboGrafx-16"], "tg16": ["PC Engine/TurboGrafx-16"],
        "pcenginecd": ["PC Engine CD/TurboGrafx-CD"], "turbografxcd": ["PC Engine CD/TurboGrafx-CD"],
        "pcfx": ["PC-FX"], "pc8800": ["PC-8000/8800"], "pc9800": ["PC-9800"], "pc6000": ["PC-6000"],
        "ngp": ["Neo Geo Pocket"], "neogeopocket": ["Neo Geo Pocket"], "neogeocd": ["Neo Geo CD"],
        "arcade": ["Arcade"], "mame": ["Arcade"],
        "wonderswan": ["WonderSwan"], "msx": ["MSX"], "msx2": ["MSX"], "msxturbor": ["MSX"],
        "colecovision": ["ColecoVision"], "intellivision": ["Intellivision"], "vectrex": ["Vectrex"],
        "3do": ["3DO Interactive Multiplayer"], "amiga": ["Amiga"], "amstradcpc": ["Amstrad CPC"],
        "appleii": ["Apple II"], "c64": ["Commodore 64"], "commodore64": ["Commodore 64"],
        "dos": ["DOS"], "vic20": ["VIC-20"],
        "zxspectrum": ["ZX Spectrum"], "zx81": ["ZX81"],
        "fmtowns": ["FM Towns"], "sharpx1": ["Sharp X1"],
        "sharpx68000": ["Sharp X68000"], "x68000": ["Sharp X68000"],
        "philipscdi": ["Philips CD-i"], "cdi": ["Philips CD-i"],
        "thomsonto8": ["Thomson TO8"], "oric": ["Oric"],
        "nokiangage": ["Nokia N-Gage"], "ngage": ["Nokia N-Gage"],
        "gameandwatch": ["Game & Watch"], "uzebox": ["Uzebox"], "arduboy": ["Arduboy"],
        "ti83": ["TI-83"], "tic80": ["TIC-80"], "wasm4": ["WASM-4"],
        "watarasupervision": ["Watara Supervision"], "supervision": ["Watara Supervision"],
        "megaduck": ["Mega Duck"], "zeebo": ["Zeebo"], "xbox": ["Xbox"]
    })

    readonly property var _consoleAliases: ({
        "sfc": "snes", "supernintendo": "snes", "supernes": "snes",
        "supernintendoentertainmentsystem": "snes", "sfam": "superfamicom",
        "nintendoentertainmentsystem": "nes", "nintendoentertainment": "nes",
        "disksystem": "fds", "nintendofamicomdisksystem": "fds",
        "nintendogameboy": "gb", "nintendogameboycolor": "gbc", "nintendogameboyadvance": "gba",
        "nintendods": "nds", "nintendodsi": "ndsi", "ngc": "gamecube", "nintendogamecube": "gamecube",
        "nintendowii": "wii", "nintendowiiu": "wiiu", "n64dd": "n64",
        "gen": "genesis", "md": "genesis", "segagenesis": "genesis", "segamegadrive": "genesis",
        "megadrivegenesis": "genesis", "genesismegadrive": "genesis",
        "segamastersystem": "mastersystem", "mark3": "mastersystem",
        "segagamegear": "gamegear", "segasaturn": "saturn", "sat": "saturn",
        "segadreamcast": "dreamcast", "dc": "dreamcast",
        "segamegacd": "segacd", "segacdmegacd": "segacd", "megacdsegacd": "segacd",
        "segasg1000": "sg1000", "sega32xmd": "32x",
        "sonyplaystation": "psx", "psone": "psx", "playstation1": "psx",
        "sonyplaystation2": "ps2", "sonyplaystationportable": "psp", "playstationportable": "psp",
        "pce": "pcengine", "pcecd": "pcenginecd", "turbografx16": "pcengine",
        "turbografx16pcengine": "pcengine", "pcenginesupergrafx": "pcengine", "supergrafx": "pcengine",
        "tgcd": "turbografxcd", "turbografxcdpcenginecd": "pcenginecd",
        "ngpc": "neogeopocket", "neogeopocketcolor": "neogeopocket", "snkneogeopocket": "neogeopocket",
        "neogeo": "arcade", "neogeoaes": "arcade", "neogeomvs": "arcade",
        "fbneo": "arcade", "fba": "arcade", "fbalpha": "arcade", "finalburnneo": "arcade",
        "mame2003": "arcade", "mame2003plus": "arcade", "mame2010": "arcade", "mame2000": "arcade",
        "mamelibretro": "arcade", "cps1": "arcade", "cps2": "arcade", "cps3": "arcade",
        "ws": "wonderswan", "wsc": "wonderswan", "wonderswancolor": "wonderswan",
        "vb": "virtualboy", "nintendovirtualboy": "virtualboy", "pokemonmini": "pokemini",
        "a2600": "atari2600", "a5200": "atari5200", "a7800": "atari7800",
        "atari2600vcs": "atari2600", "atarilynx": "lynx",
        "coleco": "colecovision", "intv": "intellivision", "mattelintellivision": "intellivision",
        "gw": "gameandwatch", "msx1": "msx", "zx": "zxspectrum", "sinclairzxspectrum": "zxspectrum",
        "x68k": "x68000", "commodore64": "c64", "commodoreamiga": "amiga",
        "panasonic3do": "3do", "3dointeractivemultiplayer": "3do", "philipscdi": "cdi"
    })

    readonly property var _extConsole: ({
        "sfc": "snes", "smc": "snes", "fig": "snes", "swc": "snes",
        "nes": "nes", "unf": "nes", "unif": "nes", "fds": "fds",
        "gb": "gb", "gbc": "gbc", "gba": "gba", "nds": "nds", "3ds": "3ds",
        "z64": "n64", "n64": "n64", "v64": "n64",
        "gcm": "gamecube", "rvz": "gamecube", "gcz": "gamecube",
        "wux": "wiiu", "wud": "wiiu", "rpx": "wiiu",
        "md": "genesis", "gen": "genesis", "smd": "genesis", "sms": "mastersystem",
        "gg": "gamegear", "32x": "32x", "sg": "sg1000",
        "pce": "pcengine", "sgx": "pcengine",
        "ngp": "neogeopocket", "ngpc": "neogeopocket",
        "ws": "wonderswan", "wsc": "wonderswan", "vb": "virtualboy",
        "a26": "atari2600", "a52": "atari5200", "a78": "atari7800",
        "lnx": "lynx", "j64": "jaguar", "jag": "jaguar",
        "col": "colecovision", "int": "intellivision", "vec": "vectrex",
        "d64": "c64", "t64": "c64", "adf": "amiga", "min": "pokemini",
        "mx1": "msx", "mx2": "msx", "tic": "tic80"
    })

    readonly property var _consoleIds: ({
        "snes": 3, "superfamicom": 3, "nes": 7, "famicom": 7,
        "fds": 81, "famicomdisksystem": 81, "n64": 2, "nintendo64": 2,
        "gb": 4, "gameboy": 4, "gbc": 6, "gameboycolor": 6,
        "gba": 5, "gameboyadvance": 5, "nds": 18, "nintendods": 18,
        "ndsi": 78, "nintendodsi": 78, "3ds": 62, "nintendo3ds": 62,
        "gamecube": 16, "gc": 16, "wii": 19, "wiiu": 20,
        "virtualboy": 28, "pokemini": 24,
        "genesis": 1, "megadrive": 1, "mastersystem": 11, "sms": 11,
        "gamegear": 15, "gg": 15, "saturn": 39, "dreamcast": 40,
        "segacd": 9, "megacd": 9, "32x": 10, "sega32x": 10,
        "segapico": 68, "sg1000": 33,
        "psx": 12, "ps1": 12, "playstation": 12, "ps2": 21, "playstation2": 21, "psp": 41,
        "atari2600": 25, "atari5200": 50, "atari7800": 51,
        "lynx": 13, "atarilynx": 13, "jaguar": 17, "atarijaguar": 17,
        "jaguarcd": 77, "atarijaguarcd": 77, "atarist": 36,
        "pcengine": 8, "turbografx": 8, "tg16": 8,
        "pcenginecd": 76, "turbografxcd": 76, "pcfx": 49,
        "pc8800": 47, "pc9800": 48, "pc6000": 67,
        "ngp": 14, "neogeopocket": 14, "neogeocd": 56,
        "arcade": 27, "mame": 27, "wonderswan": 53, "msx": 29, "msx2": 29, "msxturbor": 29,
        "colecovision": 44, "intellivision": 45, "vectrex": 46, "3do": 43,
        "amiga": 35, "amstradcpc": 37, "appleii": 38,
        "c64": 30, "commodore64": 30, "dos": 26, "vic20": 34,
        "zxspectrum": 59, "zx81": 31, "fmtowns": 58,
        "sharpx1": 64, "sharpx68000": 52, "x68000": 52,
        "philipscdi": 42, "cdi": 42, "thomsonto8": 66, "oric": 32,
        "nokiangage": 61, "ngage": 61, "gameandwatch": 60,
        "uzebox": 80, "arduboy": 71, "ti83": 79, "tic80": 65, "wasm4": 72,
        "watarasupervision": 63, "supervision": 63,
        "megaduck": 69, "zeebo": 70, "xbox": 22
    })

    property string libraryState: "idle"
    property real libraryProgress: 0.0
    property var libraryEntries: []

    property var _libRaList: []
    property var _libPegAll: []
    property var _libPegShort: []
    property var _libEntriesAccum: []
    property int _libTotal: 0
    property int _libProcessed: 0
    readonly property int _libBatchSize: 4

    function _shortNameFor(game) {
        try {
            if (game.collections && game.collections.count > 0) {
                var col = game.collections.get(0);
                var sn = (col.shortName && col.shortName !== "") ? col.shortName : col.name;
                return (sn || "").toLowerCase().replace(/[\s\-_]/g, "");
            }
        } catch (e) { }
        return "";
    }

    function loadLibrary() {
        if (!root.hasCredentials) {
            root.libraryState = "no_credentials";
            root.libraryEntries = [];
            return;
        }

        root.libraryState = "loading";
        root.libraryProgress = 0.0;
        root.libraryEntries = [];
        libraryChunkTimer.stop();

        var url = root._apiUrl("API_GetUserCompletionProgress.php", { u: root.apiUser, c: 500, o: 0 });
        root._get(url, function (err, data) {
            if (err || !data) {
                root.libraryState = "error";
                return;
            }

            var raListRaw = data.Results || (Array.isArray(data) ? data : []);
            var raList = raListRaw.filter(function (rg) { return (parseInt(rg.MaxPossible) || 0) > 0; });

            root._libRaList = raList;
            root._libPegAll = api.allGames.toVarArray();
            root._libPegShort = root._libPegAll.map(function (g) { return root._shortNameFor(g); });
            root._libEntriesAccum = [];
            root._libTotal = raList.length;
            root._libProcessed = 0;

            if (root._libTotal === 0) {
                root.libraryProgress = 1.0;
                root.libraryEntries = [];
                root.libraryState = "loaded";
                return;
            }

            libraryChunkTimer.start();
        });
    }

    function _processLibraryChunk() {
        var end = Math.min(root._libProcessed + root._libBatchSize, root._libTotal);

        for (var i = root._libProcessed; i < end; i++) {
            var rg = root._libRaList[i];
            var raConsoleRaw = rg.ConsoleName || "";

            var bestGame = null;
            var bestScore = -1;
            for (var j = 0; j < root._libPegAll.length; j++) {
                var sc = root._matchScore(rg.Title || "", root._libPegAll[j].title || "");
                if (sc <= 0)
                    continue;

                var raConsoles = root._consoleMappings[root._libPegShort[j]] || [];
                if (raConsoles.length > 0 && raConsoleRaw !== "") {
                    var consoleMatch = false;
                    for (var ci = 0; ci < raConsoles.length; ci++) {
                        if (raConsoleRaw.indexOf(raConsoles[ci]) !== -1) { consoleMatch = true; break; }
                    }
                    sc = consoleMatch ? sc + 0.5 : sc - 0.3;
                }

                if (sc > bestScore) {
                    bestScore = sc;
                    bestGame = root._libPegAll[j];
                }
            }

            if (bestGame && bestScore >= 0.70) {
                var numAwarded = rg.NumAwarded !== undefined ? parseInt(rg.NumAwarded)
                : (rg.NumAchieved !== undefined ? parseInt(rg.NumAchieved) : 0);

                root._libEntriesAccum.push({
                    raTitle: rg.Title || "",
                    raConsole: rg.ConsoleName || "",
                    numAchieved: numAwarded || 0,
                    maxPossible: parseInt(rg.MaxPossible) || 0,
                                           iconUrl: rg.ImageIcon ? (root.mediaBase + rg.ImageIcon) : "",
                                           lastAwarded: rg.MostRecentAwardedDate || "",
                                           pegasusGame: bestGame
                });
            }
        }

        root._libProcessed = end;
        root.libraryProgress = root._libTotal > 0 ? (root._libProcessed / root._libTotal) : 1.0;

        if (root._libProcessed >= root._libTotal) {
            libraryChunkTimer.stop();

            root._libEntriesAccum.sort(function (a, b) {
                return a.raTitle.localeCompare(b.raTitle);
            });

            root.libraryEntries = root._libEntriesAccum;
            root.libraryState = "loaded";

            root._libRaList = [];
            root._libPegAll = [];
            root._libPegShort = [];
            root._libEntriesAccum = [];
        }
    }

    property Timer libraryChunkTimer: Timer {
        interval: 1
        repeat: true
        onTriggered: root._processLibraryChunk()
    }
}
