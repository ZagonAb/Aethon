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

    property bool built: false
    property var _games: []
    property int _scanned: 0
    property int _total: 0
    property real progress: 0.0
    readonly property int _chunkSize: 100
    property double lastScanTimeMs: 0
    property real _scanStartTime: 0
    property string activeScope: "all"
    property var fieldStats: ({})
    property var cascadeStats: ({ cartridge: 0, boxFront: 0, logo: 0, system: 0, none: 0 })
    property var consistencyIssues: ({})
    property var collectionIssues: ({ emptyCollections: [], duplicateTitles: [] })

    readonly property var fieldChecks: ({
        "title": function(g) { return !g.title || g.title === ""; },
        "summary": function(g) { return !g.summary || g.summary === ""; },
        "description": function(g) { return !g.description || g.description === ""; },
        "developer": function(g) { return !g.developer || g.developer === ""; },
        "publisher": function(g) { return !g.publisher || g.publisher === ""; },
        "genre": function(g) { return !g.genre || g.genre === ""; },
        "tags": function(g) { return !g.tagList || g.tagList.length === 0; },
        "releaseYear": function(g) { return !g.releaseYear || g.releaseYear === 0; },
        "boxFront": function(g) { return !g.assets || !g.assets.boxFront || g.assets.boxFront === ""; },
        "cartridge": function(g) { return !g.assets || !g.assets.cartridge || g.assets.cartridge === ""; },
        "logo": function(g) { return !g.assets || !g.assets.logo || g.assets.logo === ""; },
        "video": function(g) { return !g.assets || !g.assets.video || g.assets.video === ""; }
    })

    readonly property var fieldOrder: [
        "title", "summary", "description", "developer", "publisher",
        "genre", "tags", "releaseYear", "boxFront", "cartridge", "logo", "video"
    ]

    readonly property var consistencyChecks: ({
        "date_monthWithoutYear": {
            fn: function(g) { return g.releaseMonth > 0 && (!g.releaseYear || g.releaseYear === 0); },
                                              category: "date", severity: "error"
        },
        "date_dayWithoutMonth": {
            fn: function(g) { return g.releaseDay > 0 && (!g.releaseMonth || g.releaseMonth === 0); },
                                              category: "date", severity: "error"
        },
        "date_invalidRelease": {
            fn: function(g) { return g.releaseYear > 0 && g.release && !root._isValidQmlDate(g.release); },
                                              category: "date", severity: "warning"
        },
        "date_futureRelease": {
            fn: function(g) { return g.releaseYear > (new Date()).getFullYear() + 1; },
                                              category: "date", severity: "info"
        },

        "stats_playCountWithoutLastPlayed": {
            fn: function(g) { return g.playCount > 0 && !root._isValidQmlDate(g.lastPlayed); },
                                              category: "stats", severity: "error"
        },
        "stats_lastPlayedWithoutPlayCount": {
            fn: function(g) { return root._isValidQmlDate(g.lastPlayed) && (!g.playCount || g.playCount === 0); },
                                              category: "stats", severity: "error"
        },
        "stats_playTimeWithoutPlayCount": {
            fn: function(g) { return g.playTime > 0 && (!g.playCount || g.playCount === 0); },
                                              category: "stats", severity: "error"
        },
        "stats_suspiciousShortPlayTime": {
            fn: function(g) { return g.playTime > 0 && g.playTime < 60; },
                                              category: "stats", severity: "warning"
        },
        "stats_futureLastPlayed": {
            fn: function(g) {
                if (!root._isValidQmlDate(g.lastPlayed)) return false;
                try { return new Date(g.lastPlayed) > new Date(); }
                catch (e) { return false; }
            },
            category: "stats", severity: "warning"
        },

        "meta_ratingOutOfRange": {
            fn: function(g) { return typeof g.rating === "number" && (g.rating < 0 || g.rating > 1); },
                                              category: "meta", severity: "error"
        },
        "meta_ratingTooLow": {
            fn: function(g) { return typeof g.rating === "number" && g.rating > 0 && g.rating < 0.05; },
                                              category: "meta", severity: "warning"
        },
        "meta_playersInvalid": {
            fn: function(g) { return typeof g.players === "number" && (g.players < 1 || g.players > 16); },
                                              category: "meta", severity: "warning"
        },
        "meta_summaryEqualsDescription": {
            fn: function(g) {
                if (!g.summary || !g.description) return false;
                var s = ("" + g.summary).trim();
                var d = ("" + g.description).trim();
                return s.length > 0 && s === d;
            },
            category: "meta", severity: "info"
        },
        "meta_genreStringMismatch": {
            fn: function(g) {
                var gStr = (g.genre || "").toString().trim().toLowerCase();
                var gList = g.genreList || [];
                var normalized = [];
                for (var i = 0; i < gList.length; i++) {
                    var item = (gList[i] || "").toString().trim().toLowerCase();
                    if (item.length > 0) normalized.push(item);
                }
                var hasStr = gStr.length > 0;
                var hasList = normalized.length > 0;

                if (!hasStr && !hasList) return false;

                if (hasStr !== hasList) return true;

                var matched = 0;
                for (var j = 0; j < normalized.length; j++) {
                    var it = normalized[j];
                    var forward = gStr.indexOf(it) !== -1;
                    var reverse = gStr.length >= 3 && it.indexOf(gStr) !== -1;
                    if (forward || reverse) matched++;
                }
                return matched === 0;
            },
            category: "meta", severity: "warning"
        },
        "meta_sortByNeedsArticle": {
            fn: function(g) {
                if (!g.sortBy || !g.title) return false;
                if (g.sortBy !== g.title) return false;
                return /^(the|a|an|el|la|los|las|le|les|un|una|unos|unas)\s/i.test(g.title);
            },
            category: "meta", severity: "info"
        }
    })

    readonly property var issueOrder: [
        "date_monthWithoutYear", "date_dayWithoutMonth",
        "date_invalidRelease", "date_futureRelease",
        "stats_playCountWithoutLastPlayed", "stats_lastPlayedWithoutPlayCount",
        "stats_playTimeWithoutPlayCount", "stats_suspiciousShortPlayTime",
        "stats_futureLastPlayed",
        "meta_ratingOutOfRange", "meta_ratingTooLow", "meta_playersInvalid",
        "meta_summaryEqualsDescription", "meta_genreStringMismatch",
        "meta_sortByNeedsArticle"
    ]

    function _isValidQmlDate(d) {
        if (!d) return false;
        try {
            var js = new Date(d);
            return !isNaN(js.getTime());
        } catch (e) { return false; }
    }

    function _getShortName(col) {
        if (!col) return "";
        var sn = (col.shortName && col.shortName !== "") ? col.shortName : col.name;
        return (sn || "").toLowerCase().replace(/[\s\-_]/g, "");
    }

    function _isLocalAsset(url) {
        if (!url) return false;
        var s = "" + url;
        return !(s.indexOf("http://") === 0 || s.indexOf("https://") === 0);
    }

    function cascadeLevel(game) {
        if (!game) return "none";
        var a = game.assets || {};
        if (a.cartridge && a.cartridge !== "") return "cartridge";
        if (a.boxFront && a.boxFront !== "") return "boxFront";
        if (a.logo && a.logo !== "") return "logo";
        var fb = "";
        try { fb = GameUtils.getSystemFallback(game); } catch (e) { fb = ""; }
        if (fb && fb !== "") return "system";
        return "none";
    }

    property Timer _scanTimer: Timer {
        interval: 20
        repeat: true
        running: false
        onTriggered: root._scanChunk()
    }

    function _scanChunk() {
        var end = Math.min(root._scanned + root._chunkSize, root._total);

        var fs = {};
        for (var k in root.fieldStats) {
            fs[k] = { missing: root.fieldStats[k].missing, total: root.fieldStats[k].total };
        }
        var cs = {};
        for (var lvl in root.cascadeStats) cs[lvl] = root.cascadeStats[lvl];
        var ci = root.consistencyIssues;

        for (var i = root._scanned; i < end; i++) {
            var game = root._games[i];

            for (var fieldKey in root.fieldChecks) {
                if (!fs[fieldKey]) fs[fieldKey] = { missing: 0, total: 0 };
                fs[fieldKey].total++;
                if (root.fieldChecks[fieldKey](game)) fs[fieldKey].missing++;
            }

            var level = root.cascadeLevel(game);
            cs[level] = (cs[level] || 0) + 1;

            for (var issueId in root.consistencyChecks) {
                var check = root.consistencyChecks[issueId];
                if (check.fn(game)) {
                    if (!ci[issueId]) {
                        ci[issueId] = { severity: check.severity, category: check.category, affected: [] };
                    }
                    ci[issueId].affected.push(game);
                }
            }
        }

        root.fieldStats = fs;
        root.cascadeStats = cs;
        root._scanned = end;
        root.progress = root._total > 0 ? root._scanned / root._total : 1.0;

        if (root._scanned >= root._total) {
            root._scanTimer.stop();
            root._runCollectionChecks();

            root.lastScanTimeMs = Date.now() - root._scanStartTime;

            var finalCi = {};
            for (var id in ci) {
                finalCi[id] = {
                    severity: ci[id].severity,
                    category: ci[id].category,
                    affected: ci[id].affected.slice()
                };
            }
            root.consistencyIssues = finalCi;

            root.built = true;
        }
    }

    function _runCollectionChecks() {
        var empty = [];
        if (root.activeScope === "all") {
            for (var i = 0; i < api.collections.count; i++) {
                var col = api.collections.get(i);
                if (col.games.count === 0) empty.push(col);
            }
        } else {
            for (var j = 0; j < api.collections.count; j++) {
                var c = api.collections.get(j);
                if (root._getShortName(c) === root.activeScope) {
                    if (c.games.count === 0) empty.push(c);
                    break;
                }
            }
        }

        var byTitle = {};
        for (var k = 0; k < root._games.length; k++) {
            var g = root._games[k];
            var t = g.title || "";
            if (!byTitle[t]) byTitle[t] = [];
            byTitle[t].push(g);
        }
        var dups = [];
        for (var title in byTitle) {
            if (byTitle[title].length > 1) {
                dups.push({ title: title, games: byTitle[title] });
            }
        }

        root.collectionIssues = { emptyCollections: empty, duplicateTitles: dups };
    }

    function build(scope) {
        root._scanTimer.stop();
        root.built = false;
        root._scanned = 0;
        root.progress = 0.0;
        root.fieldStats = {};
        root.cascadeStats = { cartridge: 0, boxFront: 0, logo: 0, system: 0, none: 0 };
        root.consistencyIssues = {};
        root.collectionIssues = { emptyCollections: [], duplicateTitles: [] };

        root.activeScope = (scope === undefined || scope === null || scope === "") ? "all" : ("" + scope);

        var all = api.allGames.toVarArray();

        if (root.activeScope === "all") {
            root._games = all;
        } else {
            var filtered = [];
            for (var i = 0; i < all.length; i++) {
                var g = all[i];
                try {
                    if (g.collections && g.collections.count > 0) {
                        var col = g.collections.get(0);
                        if (root._getShortName(col) === root.activeScope) filtered.push(g);
                    }
                } catch (e) { }
            }
            root._games = filtered;
        }

        root._total = root._games.length;
        root._scanStartTime = Date.now();

        if (root._total === 0) {
            root.progress = 1.0;
            root._runCollectionChecks();
            root.built = true;
            root.lastScanTimeMs = 0;
            return;
        }

        root._scanTimer.start();
    }

    function reset() {
        root._scanTimer.stop();
        root.built = false;
        root._games = [];
        root._scanned = 0;
        root._total = 0;
        root.progress = 0.0;
        root.activeScope = "all";
        root.fieldStats = {};
        root.cascadeStats = { cartridge: 0, boxFront: 0, logo: 0, system: 0, none: 0 };
        root.consistencyIssues = {};
        root.collectionIssues = { emptyCollections: [], duplicateTitles: [] };
    }

    function availableScopes() {
        var cols = [];
        for (var i = 0; i < api.collections.count; i++) {
            var col = api.collections.get(i);
            cols.push({
                shortName: root._getShortName(col),
                      name: col.name || "",
                      isAll: false
            });
        }
        cols.sort(function(a, b) { return a.name.localeCompare(b.name); });
        return [{ shortName: "all", name: "", isAll: true }].concat(cols);
    }

    function gamesMissing(fieldKey) {
        var result = [];
        var check = root.fieldChecks[fieldKey];
        if (!check) return result;
        for (var i = 0; i < root._games.length; i++) {
            if (check(root._games[i])) result.push(root._games[i]);
        }
        return result;
    }

    function gamesWithIssue(issueId) {
        var issue = root.consistencyIssues[issueId];
        return issue ? issue.affected.slice() : [];
    }

    function gamesAtCascadeLevel(level) {
        var result = [];
        for (var i = 0; i < root._games.length; i++) {
            if (root.cascadeLevel(root._games[i]) === level) result.push(root._games[i]);
        }
        return result;
    }

    function gamesDuplicateTitle(title) {
        var list = root.collectionIssues.duplicateTitles;
        for (var i = 0; i < list.length; i++) {
            if (list[i].title === title) return list[i].games.slice();
        }
        return [];
    }

    function emptyCollectionsList() {
        return root.collectionIssues.emptyCollections.slice();
    }

    function gamesWithDuplicateTitles() {
        var result = [];
        var dups = root.collectionIssues.duplicateTitles || [];
        for (var i = 0; i < dups.length; i++) {
            for (var j = 0; j < dups[i].games.length; j++) {
                result.push(dups[i].games[j]);
            }
        }
        return result;
    }

    function getGameReport(game) {
        if (!game) return null;

        var collectionsInfo = [];
        try {
            if (game.collections && game.collections.count > 0) {
                for (var ci = 0; ci < game.collections.count; ci++) {
                    collectionsInfo.push(game.collections.get(ci).name || "");
                }
            }
        } catch (e) { }

        var relValid = root._isValidQmlDate(game.release);
        var relJsDate = null;
        if (relValid) {
            try { relJsDate = new Date(game.release); } catch (e) { relJsDate = null; }
        }

        var assetKeys = [
            "boxFront", "boxBack", "boxSpine", "boxFull", "cartridge",
            "logo", "tile", "banner", "poster", "background",
            "screenshot", "titlescreen", "video", "marquee", "bezel"
        ];
        var assets = {};
        for (var ai = 0; ai < assetKeys.length; ai++) {
            var key = assetKeys[ai];
            var url = "";
            try { url = (game.assets && game.assets[key]) ? ("" + game.assets[key]) : ""; } catch (e) { url = ""; }
            var listCount = 0;
            try {
                var list = game.assets ? game.assets[key + "List"] : null;
                if (list && list.length !== undefined) listCount = list.length;
            } catch (e) { }
            assets[key] = {
                url: url,
                present: url !== "",
                isLocal: root._isLocalAsset(url),
                listCount: listCount,
                hasMultiple: listCount > 1
            };
        }

        var filesSupported = false;
        var filesItems = [];
        try {
            if (game.files) {
                filesSupported = true;
                if (game.files.length !== undefined) {
                    for (var fi = 0; fi < game.files.length; fi++) filesItems.push("" + game.files[fi]);
                }
            }
        } catch (e) { }

        var extraSupported = false;
        try { extraSupported = game.extra !== undefined && game.extra !== null; } catch (e) { }

        return {
            identity: {
                title: game.title || "",
                cleanTitle: GameUtils.cleanGameTitle(game.title || ""),
                sortBy: game.sortBy || "",
                collections: collectionsInfo
            },
            credits: {
                developer: game.developer || "",
                developerList: game.developerList || [],
                publisher: game.publisher || "",
                publisherList: game.publisherList || [],
                genre: game.genre || "",
                genreList: game.genreList || [],
                tagList: game.tagList || []
            },
            release: {
                valid: relValid,
                year: game.releaseYear || 0,
                month: game.releaseMonth || 0,
                day: game.releaseDay || 0,
                jsDate: relJsDate
            },
            stats: {
                playCount: game.playCount || 0,
                playTime: game.playTime || 0,
                lastPlayed: game.lastPlayed || null,
                lastPlayedValid: root._isValidQmlDate(game.lastPlayed),
                rating: game.rating || 0,
                players: game.players || 0,
                favorite: game.favorite === true,
                missing: game.missing === true
            },
            assets: assets,
            files: { supported: filesSupported, items: filesItems },
            extra: { supported: extraSupported, keys: [], values: {} },
            health: root._computeHealth(game)
        };
    }

    function _computeHealth(game) {
        var score = 100;
        var issues = [];

        var level = root.cascadeLevel(game);
        if (level === "none") { score -= 25; issues.push("no_art"); }
        else if (level === "system") { score -= 15; issues.push("system_art_only"); }
        else if (level === "logo") { score -= 10; issues.push("logo_only"); }
        else if (level === "boxFront") { score -= 5; }

        var keyFields = ["summary", "developer", "genre", "releaseYear", "boxFront"];
        for (var i = 0; i < keyFields.length; i++) {
            var fn = root.fieldChecks[keyFields[i]];
            if (fn && fn(game)) {
                score -= 8;
                issues.push("missing_" + keyFields[i]);
            }
        }

        var deductCount = 0;
        for (var issueId in root.consistencyChecks) {
            if (root.consistencyChecks[issueId].fn(game)) {
                issues.push(issueId);
                deductCount++;
                if (deductCount >= 7) break;
            }
        }
        score -= deductCount * 5;

        return { score: Math.max(0, Math.min(100, score)), issues: issues };
    }
}
