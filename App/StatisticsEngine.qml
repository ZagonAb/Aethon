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
    property var stats: ({
        totalGames: 0,
        totalCollections: 0,
        totalFavorites: 0,
        totalTime: 0,
        totalLaunches: 0,
        topPlayed: [],
        topLaunched: [],
        topRecent: [],
        collections: []
    })

    function build() {
        if (root.built) return;

        var all = api.allGames.toVarArray();
        var totalGames = all.length;
        var totalFavorites = 0;
        var totalTime = 0;
        var totalLaunches = 0;

        for (var i = 0; i < all.length; i++) {
            var g = all[i];
            if (g.favorite) totalFavorites++;
            totalTime += (g.playTime || 0);
            totalLaunches += (g.playCount || 0);
        }

        var played = all.filter(function(g) { return g.playTime > 0; });
        played.sort(function(a, b) { return b.playTime - a.playTime; });
        var topPlayed = played.slice(0, 10);

        var launched = all.filter(function(g) { return g.playCount > 0; });
        launched.sort(function(a, b) { return b.playCount - a.playCount; });
        var topLaunched = launched.slice(0, 10);

        var recent = all.filter(function(g) {
            if (!g.lastPlayed) return false;
            var d = new Date(g.lastPlayed);
            return !isNaN(d.getTime());
        });
        recent.sort(function(a, b) {
            var d1 = new Date(a.lastPlayed).getTime();
            var d2 = new Date(b.lastPlayed).getTime();
            return d2 - d1;
        });
        var topRecent = recent.slice(0, 5);

        var cols = [];
        for (var c = 0; c < api.collections.count; c++) {
            var col = api.collections.get(c);
            cols.push({ name: col.name, count: col.games.count });
        }
        cols.sort(function(a, b) { return b.count - a.count; });

        root.stats = {
            totalGames: totalGames,
            totalCollections: api.collections.count,
            totalFavorites: totalFavorites,
            totalTime: totalTime,
            totalLaunches: totalLaunches,
            topPlayed: topPlayed,
            topLaunched: topLaunched,
            topRecent: topRecent,
            collections: cols
        };

        root.built = true;
    }
}
