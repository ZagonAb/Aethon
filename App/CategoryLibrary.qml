// Aethon
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
pragma Singleton
import QtQuick 2.15
import "../App"

QtObject {
    id: root

    function decadeLabel(releaseYear) {
        if (!releaseYear || releaseYear <= 0)
            return "UNKNOWN";
        var decade = Math.floor(releaseYear / 10) * 10;
        return decade + "s";
    }

    function valuesForGame(section, game) {
        if (section === Enums.sectionGenres)
            return game.genreList || [];
        if (section === Enums.sectionDevelopers)
            return game.developerList || [];
        if (section === Enums.sectionPublishers)
            return game.publisherList || [];
        if (section === Enums.sectionTags)
            return game.tagList || [];
        if (section === Enums.sectionYears)
            return [root.decadeLabel(game.releaseYear)];
        if (section === Enums.sectionRegions)
            return RegionLibrary.valuesForGame(game);
        return [];
    }

    function valuesForSection(section) {
        var all = api.allGames.toVarArray();
        var counts = {};

        for (var i = 0; i < all.length; i++) {
            var vals = root.valuesForGame(section, all[i]);
            for (var j = 0; j < vals.length; j++) {
                var v = vals[j];
                if (!v)
                    continue;
                counts[v] = (counts[v] || 0) + 1;
            }
        }

        var labels = Object.keys(counts);

        if (section === Enums.sectionYears) {
            labels.sort(function(a, b) {
                if (a === "UNKNOWN") return 1;
                if (b === "UNKNOWN") return -1;
                return parseInt(a, 10) - parseInt(b, 10);
            });
        } else if (section === Enums.sectionRegions) {
            labels.sort(function(a, b) {
                var la = Language.t("region_" + a);
                var lb = Language.t("region_" + b);
                return la.localeCompare(lb);
            });
        } else {
            labels.sort(function(a, b) { return a.localeCompare(b); });
        }

        return labels.map(function(label) {
            return { label: label, count: counts[label] };
        });
    }

    function compareGames(a, b) {
        var ta = a.sortBy || a.title || "";
        var tb = b.sortBy || b.title || "";
        return ta.localeCompare(tb);
    }

    function gamesForCategory(section, value) {
        var all = api.allGames.toVarArray();
        var filtered = all.filter(function(g) {
            var vals = root.valuesForGame(section, g);
            return vals.indexOf(value) !== -1;
        });
        filtered.sort(root.compareGames);
        return filtered;
    }

    property int yearSplitThreshold: 150

    function yearLabel(releaseYear) {
        if (!releaseYear || releaseYear <= 0)
            return "UNKNOWN";
        return String(releaseYear);
    }

    function decadeNeedsSplit(value) {
        var values = root.valuesForSection(Enums.sectionYears);
        for (var i = 0; i < values.length; i++) {
            if (values[i].label === value)
                return values[i].count > root.yearSplitThreshold;
        }
        return false;
    }

    function yearsInDecade(value) {
        var all = api.allGames.toVarArray();
        var counts = {};

        for (var i = 0; i < all.length; i++) {
            var g = all[i];
            if (root.decadeLabel(g.releaseYear) !== value)
                continue;
            var y = root.yearLabel(g.releaseYear);
            counts[y] = (counts[y] || 0) + 1;
        }

        var labels = Object.keys(counts);
        labels.sort(function (a, b) {
            if (a === "UNKNOWN") return 1;
            if (b === "UNKNOWN") return -1;
            return parseInt(a, 10) - parseInt(b, 10);
        });

        return labels.map(function (label) {
            return { label: label, count: counts[label] };
        });
    }

    function gamesForYear(value) {
        var all = api.allGames.toVarArray();
        var filtered = all.filter(function (g) {
            return root.yearLabel(g.releaseYear) === value;
        });
        filtered.sort(root.compareGames);
        return filtered;
    }

    function displayLabel(label) {
        if (label === "UNKNOWN")
            return Language.t("years_unknown");
        if (RegionLibrary.allRegionIds().indexOf(label) !== -1)
            return Language.t("region_" + label);
        return label;
    }

    function flagFor(label) {
        if (RegionLibrary.allRegionIds().indexOf(label) === -1) return "";
        return RegionLibrary.flagPath(label);
    }
}
