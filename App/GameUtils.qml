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

    function cleanGameTitle(title) {
        if (!title || typeof title !== "string")
            return title || "";

        var patterns = [
            /\s*\([^)]*(?:USA|NGM|Euro|Europe|Japan|World|Japan, USA|Korea|Asia|Brazil|Germany|France|Italy|Spain|UK|Australia|Canada|rev|sitdown|set|Hispanic|China|Ver|ver|US|68k|bootleg|Nintendo|Taiwan|Hong Kong|Latin America|Mexico|Russia|Sweden|Netherlands|Belgium|Portugal|Greece|Finland|Norway|Denmark|Poland|Czech|Slovak|Hungary|Romania|Bulgaria|Croatia|Serbia|Turkey|Israel|UAE|Saudi Arabia|South Africa|Egypt|Philippines|Indonesia|Malaysia|Singapore|Thailand|Vietnam)[^)]*\)/gi,
            /\s*\([^)]*(?:Rev \d+|Version \d+|v\d+\.\d+|Update \d+|Beta|Alpha|Demo|Prototype|Unl|Sample|Preview|Trial)[^)]*\)/gi,
            /\s*\([^)]*(?:NES|SNES|N64|GC|Wii|Switch|GB|GBC|GBA|DS|3DS|PS1|PS2|PS3|PS4|PS5|PSP|Vita|Xbox|Xbox 360|Xbox One|Genesis|Mega Drive|Saturn|Dreamcast|Arcade|MAME|FBA|Neo Geo)[^)]*\)/gi,
            /\s*-\s*(?:USA|EUR|JPN|KOR|ASI|BRA|GER|FRA|ITA|SPA|UK|AUS|CAN|CHN|TWN|HKG|LAT|MEX|RUS)[\s\-]*/gi,
            /\s*\[[^\]]*(?:Rev \d+|v\d+\.\d+)[^\]]*\]/gi,
            /\s*\[[^\]]*(?:Good|Bad|Overdump|Underdump|Verified|Trurip|No-Intro|Redump)[^\]]*\]/gi,
            /\s*\[[^\]]*(?:Crack|Trainer|Cheat|Hack|Patch|Fixed|Translated)[^\]]*\]/gi,
            /\s*\[[^\]]*(?:!\?|!\s*|\(\?\))[^\]]*\]/gi,
            /\s*\(Disk \d+ of \d+\)/gi,
            /\s*\(Side [A-B]\)/gi,
            /\s*\(Track \d+\)/gi,
            /\s*\([\d\s]+in[\d\s]+\)/gi,
            /\s*\(\d{4}[-\.]\d{2}[-\.]\d{2}\)/
            ];

            var cleaned = title;
            for (var i = 0; i < patterns.length; i++) {
                cleaned = cleaned.replace(patterns[i], "");
            }

            cleaned = cleaned
            .replace(/^\s+|\s+$/g, "")
            .replace(/\s{2,}/g, " ")
            .replace(/^[-\s]+|[-\s]+$/g, "")
            .replace(/,\s*$/, "")
            .replace(/\.\s*$/, "");

            if (!cleaned || cleaned.trim() === "")
                return title.trim();

        return cleaned.trim();
    }

    function firstCleanGenre(genreText) {
        if (!genreText || genreText.trim() === "")
            return "—";

        var separators = [",", "/", "-", "&", "|", ";"];
        var parts = [genreText];
        for (var i = 0; i < separators.length; i++) {
            var next = [];
            for (var j = 0; j < parts.length; j++) {
                next = next.concat(parts[j].split(separators[i]));
            }
            parts = next;
        }

        for (var k = 0; k < parts.length; k++) {
            var cleaned = parts[k].trim();
            var lower = cleaned.toLowerCase();
            if (cleaned.length > 2 && lower !== "and" && lower !== "or" && lower !== "game")
                return cleaned;
        }
        return "—";
    }

    readonly property var _lut: [9564058, 4341314, 328642, 8650627, 98033, 15633575]

    function lutHex(i) {
        var v = root._lut[i] ^ 6171761;
        return "#" + ("000000" + v.toString(16)).slice(-6);
    }

    function formatPlayTime(seconds) {
        if (!seconds || seconds <= 0)
            return "00:00:00";
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        var s = Math.floor(seconds % 60);
        function pad(n) { return (n < 10 ? "0" : "") + n; }
        return pad(h) + ":" + pad(m) + ":" + pad(s);
    }

    function _asset(game, name) {
        if (!game || !game.assets) return "";
        var v = game.assets[name];
        return (v && v !== "") ? v : "";
    }

    function getSystemShortName(game) {
        if (!game) return "";
        try {
            if (game.collections && game.collections.count > 0) {
                var col = game.collections.get(0);
                var sn = (col.shortName && col.shortName !== "") ? col.shortName : col.name;
                return (sn || "").toLowerCase().replace(/[\s\-_]/g, "");
            }
        } catch (e) { }
        return "";
    }

    function gameMetadataLine(game, includeShortName) {
        if (!game) return "";
        var parts = [];
        if (game.developer && game.developer !== "")
            parts.push(game.developer);
        if (game.releaseYear)
            parts.push(String(game.releaseYear));
        if (includeShortName) {
            var sn = root.getSystemShortName(game);
            if (sn !== "")
                parts.push(sn);
        }
        return parts.join(" • ");
    }

    function getSystemFallback(game) {
        var shortName = root.getSystemShortName(game);
        if (shortName === "") return "";
        return Qt.resolvedUrl("../assets/systems/" + shortName + ".png");
    }

    function _cascade(game) {
        return _asset(game, "cartridge")
        || _asset(game, "boxFront")
        || _asset(game, "logo")
        || getSystemFallback(game);
    }

    function resolveArt(game, pref) {
        if (!game) return "";
        if (!pref || pref === "auto") return _cascade(game);
        var direct = _asset(game, pref);
        if (direct !== "") return direct;
        return _cascade(game);
    }

    function getPreferredArt(game, context) {
        if (!game) return "";
        var pref = (context === "gameDetails")
        ? SettingsManager.artPreferenceGameDetails
        : SettingsManager.artPreferenceGameLists;
        return resolveArt(game, pref);
    }
}
