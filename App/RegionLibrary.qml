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

    readonly property var regionFlags: ({
        "usa": "USA.png",
        "japan": "Japan.png",
        "europe": "Eu.png",
        "spain": "Spain.png",
        "germany": "DE.png",
        "italy": "Ita.png",
        "france": "Fr.png",
        "uk": "uk.png",
        "brazil": "BR.png",
        "netherlands": "NL.png",
        "korea": "Korea.png",
        "taiwan": "Taiwan.png",
        "sweden": "Sv.png",
        "world": "World.png",
        "multi": "World.png"
    })

    readonly property var regionPatterns: [
        { id: "spain", patterns: [/Spain/i, /\bES\b/i, /\bSpa\b/i] },
        { id: "germany", patterns: [/Germany/i, /\bDE\b/i, /\bGer\b/i] },
        { id: "italy", patterns: [/Italy/i, /\bIT\b/i, /\bIta\b/i] },
        { id: "usa", patterns: [/\bUSA\b/i, /\bUS\b/i, /United States/i, /Canada/i] },
        { id: "japan", patterns: [/Japan/i, /\bJPN\b/i, /\bJP\b/i] },
        { id: "europe", patterns: [/Europe/i, /\bEUR\b/i, /\bEU\b/i, /Australia/i] },
        { id: "uk", patterns: [/\bUK\b/i, /England/i, /Britain/i, /\bGB\b/i] },
        { id: "france", patterns: [/France/i, /\bFR\b/i, /\bFra\b/i] },
        { id: "brazil", patterns: [/Brazil/i, /\bBR\b/i, /Pt-BR/i] },
        { id: "netherlands", patterns: [/Netherlands/i, /\bNL\b/i, /Dutch/i] },
        { id: "korea", patterns: [/Korea/i, /\bKR\b/i, /\bKOR\b/i] },
        { id: "taiwan", patterns: [/Taiwan/i, /\bTW\b/i] },
        { id: "sweden", patterns: [/Sweden/i, /\bSE\b/i, /\bSv\b/i] },
        { id: "world", patterns: [/World/i, /International/i] }
    ]

    function _isLanguageList(content) {
        if (!content) return false;
        return /^[A-Z][a-z]{1,2}(\s*,\s*[A-Z][a-z]{1,2})+$/.test(content.trim());
    }

    function _extractRegions(text) {
        if (!text || typeof text !== "string") return [];

        var detected = [];
        var seen = {};

        var parenMatches = text.match(/\(([^)]+)\)/g);
        if (!parenMatches) return [];

        for (var i = 0; i < parenMatches.length; i++) {
            var content = parenMatches[i].replace(/[()]/g, "").trim();

            if (root._isLanguageList(content)) continue;

            var parts = content.indexOf(",") !== -1
            ? content.split(",").map(function(s) { return s.trim(); })
            : [content];

            for (var p = 0; p < parts.length; p++) {
                var part = parts[p];
                for (var r = 0; r < root.regionPatterns.length; r++) {
                    var region = root.regionPatterns[r];
                    if (seen[region.id]) continue;

                    for (var pi = 0; pi < region.patterns.length; pi++) {
                        if (region.patterns[pi].test(part)) {
                            detected.push(region.id);
                            seen[region.id] = true;
                            break;
                        }
                    }
                }
            }
        }

        return detected;
    }

    function _getFirstFileName(game) {
        try {
            if (!game || !game.files) return "";

            if (game.files.count !== undefined && typeof game.files.get === "function") {
                if (game.files.count > 0) {
                    var f = game.files.get(0);
                    return f ? (f.name || "") : "";
                }
                return "";
            }

            if (game.files.length !== undefined && game.files.length > 0) {
                var f2 = game.files[0];
                return f2 ? (f2.name || "") : "";
            }

            return "";
        } catch (e) {
            return "";
        }
    }

    function getRegionsForGame(game) {
        if (!game) return [];

        var regions = root._extractRegions(game.title);
        if (regions.length > 0) return regions;

        var fileName = root._getFirstFileName(game);
        if (fileName !== "") {
            regions = root._extractRegions(fileName);
            if (regions.length > 0) return regions;
        }

        return [];
    }

    function valuesForGame(game) {
        var regions = root.getRegionsForGame(game);
        if (regions.length >= 2) {
            return ["multi"];
        }
        return regions;
    }

    function isMultiRegion(game) {
        return root.getRegionsForGame(game).length >= 2;
    }

    function allRegionIds() {
        return [
            "usa", "japan", "europe", "spain", "germany", "italy",
            "france", "uk", "brazil", "netherlands", "korea", "taiwan",
            "sweden", "world", "multi"
        ];
    }

    function flagPath(regionId) {
        var fileName = root.regionFlags[regionId];
        if (!fileName) return "";
        return Qt.resolvedUrl("../assets/icons/flags/" + fileName);
    }
}
