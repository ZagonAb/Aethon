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

    readonly property string style: SettingsManager.buttonStyle
    readonly property bool swapAB: SettingsManager.buttonSwapAB

    readonly property var xbox: ({
        accept: "\u21d3",
        cancel: "\u21d2",
        details: "\u21d0",
        filters: "\u21d1",
        prev: "\u2198",
        next: "\u2199",
        pageUp: "\u2196",
        pageDown: "\u2197",
        start: "\u21fb",
        select: "\u21fa"
    })

    readonly property var playstation: ({
        accept: "\u21e3",
        cancel: "\u21e2",
        details: "\u21e0",
        filters: "\u21e1",
        prev: "\u21b0",
        next: "\u21b1",
        pageUp: "\u21b2",
        pageDown: "\u21b3",
        start: "\u21e8",
        select: "\u21e6"
    })

    readonly property var nintendo: ({
        accept: "\u21d2",
        cancel: "\u21d3",
        details: "\u21d1",
        filters: "\u21d0",
        prev: "\u219c",
        next: "\u219d",
        pageUp: "\u219a",
        pageDown: "\u219b",
        start: "\u21fe",
        select: "\u21fd"
    })

    readonly property var numbers: ({
        accept: "\u24f7",
        cancel: "\u24f6",
        details: "\u24f8",
        filters: "\u24f5",
        prev: "\u21b0",
        next: "\u21b1",
        pageUp: "\u21b2",
        pageDown: "\u21b3",
        start: "\u21f8",
        select: "\u21f7"
    })

    readonly property var keyboard: ({
        accept: "\u242e",
        cancel: "\u242d",
        details: "I",
        filters: "F",
        prev: "A",
        next: "D",
        pageUp: "\u2436",
        pageDown: "\u2439"
    })

    readonly property var dpadPad: ({
        up: "\u219f", down: "\u21a1", left: "\u219e", right: "\u21a0"
    })
    readonly property var dpadKeys: ({
        up: "\u23f6", down: "\u23f7", left: "\u23f4", right: "\u23f5"
    })

    readonly property var plain: ({
        accept: "A", cancel: "B", details: "X", filters: "Y",
        prev: "L", next: "R", pageUp: "L2", pageDown: "R2",
        start: "Start", select: "Select",
        up: "\u2191", down: "\u2193", left: "\u2190", right: "\u2192"
    })

    function _swap(token) {
        if (token === "accept") return "cancel";
        if (token === "cancel") return "accept";
        if (token === "details") return "filters";
        if (token === "filters") return "details";
        return token;
    }

    function glyph(token) {
        var dp = (style === "keyboard") ? dpadKeys : dpadPad;
        if (dp[token] !== undefined)
            return { t: dp[token], icon: true };

        var table = (style === "xbox") ? xbox
        : (style === "playstation") ? playstation
        : (style === "nintendo") ? nintendo
        : (style === "numbers") ? numbers
        : (style === "keyboard") ? keyboard : null;

        var role = (swapAB && style !== "keyboard") ? _swap(token) : token;

        if (table && table[role] !== undefined)
            return { t: table[role], icon: true };

        return { t: plain[token] !== undefined ? plain[token] : token, icon: false };
    }

    readonly property var labels: ({
        xbox: {
            accept: "A", cancel: "B", details: "X", filters: "Y",
            prev: "LB", next: "RB", pageUp: "LT", pageDown: "RT",
            start: "Menu", select: "View"
        },
        playstation: {
            accept: "Cross", cancel: "Circle", details: "Square", filters: "Triangle",
            prev: "L1", next: "R1", pageUp: "L2", pageDown: "R2",
            start: "Options", select: "Share"
        },
        nintendo: {
            accept: "B", cancel: "A", details: "Y", filters: "X",
            prev: "L", next: "R", pageUp: "ZL", pageDown: "ZR",
            start: "+", select: "-"
        },
        numbers: {
            accept: "3", cancel: "2", details: "4", filters: "1",
            prev: "L1", next: "R1", pageUp: "L2", pageDown: "R2",
            start: "Start", select: "Select"
        },
        keyboard: {
            accept: "Enter", cancel: "Backspace", details: "I", filters: "F",
            prev: "A", next: "D", pageUp: "Page Up", pageDown: "Page Down",
            start: "Start", select: "Select"
        }
    })

    function label(token) {
        var role = (swapAB && style !== "keyboard") ? _swap(token) : token;
        var t = labels[style];
        if (t && t[role] !== undefined)
            return t[role];
        return plain[token] !== undefined ? plain[token] : token;
    }

    function expand(str) {
        return String(str).replace(/\{(\w+)\}/g, function(m, k) { return label(k); });
    }
}
