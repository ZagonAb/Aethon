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

    property var dayIndex: ({})
    property int incompleteDatesCount: 0
    property bool _built: false

    function pad2(n) {
        return n < 10 ? "0" + n : "" + n;
    }

    function _extractDateParts(game) {
        var y = game.releaseYear || 0;
        var m = game.releaseMonth || 0;
        var d = game.releaseDay || 0;

        if (m > 0 && m <= 12 && d > 0 && d <= 31) {
            return { year: y, month: m, day: d };
        }

        if (game.release) {
            try {
                var dateObj = new Date(game.release);
                if (!isNaN(dateObj.getTime())) {
                    return {
                        year: dateObj.getFullYear() || y,
                        month: dateObj.getMonth() + 1,
                        day: dateObj.getDate()
                    };
                }
            } catch (e) { }
        }

        return { year: y, month: 0, day: 0 };
    }

    function buildIndex() {
        if (root._built) return;

        var idx = {};
        var incomplete = 0;
        var all = api.allGames.toVarArray();

        for (var i = 0; i < all.length; i++) {
            var g = all[i];
            var parts = root._extractDateParts(g);

            if (parts.month > 0 && parts.day > 0) {
                var key = root.pad2(parts.month) + "-" + root.pad2(parts.day);
                if (!idx[key]) idx[key] = [];
                idx[key].push({
                    game: g,
                    year: parts.year
                });
            } else {
                incomplete++;
            }
        }

        for (var k in idx) {
            idx[k].sort(function(a, b) {
                if (a.year !== b.year) return a.year - b.year;
                var tA = a.game.sortBy || a.game.title || "";
                var tB = b.game.sortBy || b.game.title || "";
                return tA.localeCompare(tB);
            });
        }

        root.dayIndex = idx;
        root.incompleteDatesCount = incomplete;
        root._built = true;

        console.log("[CalendarEngine] Índice construido. Días con lanzamientos:", Object.keys(idx).length, "| Juegos sin fecha completa:", incomplete);
    }

    function getGamesForDate(year, month, day) {
        var key = root.pad2(month) + "-" + root.pad2(day);
        return root.dayIndex[key] || [];
    }

    function getMonthGrid(year, month, startDay) {
        var firstOfMonth = new Date(year, month, 1);
        var firstDayOfWeek = firstOfMonth.getDay();

        var offset = (firstDayOfWeek - startDay + 7) % 7;

        var startDate = new Date(year, month, 1 - offset);
        var cells = [];
        var today = new Date();

        for (var i = 0; i < 42; i++) {
            var d = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate() + i);

            var cy = d.getFullYear();
            var cm = d.getMonth();
            var cd = d.getDate();

            var count = root.getGamesForDate(cy, cm + 1, cd).length;

            cells.push({
                year: cy,
                month: cm,
                day: cd,
                isCurrentMonth: (cm === month),
                       isToday: (cy === today.getFullYear() && cm === today.getMonth() && cd === today.getDate()),
                       count: count
            });
        }

        return cells;
    }

    function findNextLaunchDate(currentYear, currentMonth, currentDay, direction) {
        var d = new Date(currentYear, currentMonth, currentDay);
        var limit = 3660;
        var step = direction > 0 ? 1 : -1;

        for (var i = 0; i < limit; i++) {
            d.setDate(d.getDate() + step);
            var m = d.getMonth() + 1;
            var day = d.getDate();
            var key = root.pad2(m) + "-" + root.pad2(day);

            if (root.dayIndex[key] && root.dayIndex[key].length > 0) {
                return new Date(d.getFullYear(), d.getMonth(), d.getDate());
            }
        }
        return null;
    }

    function getAnniversaryYears(releaseYear, viewingYear) {
        if (!releaseYear || releaseYear <= 0) return -1;
        return viewingYear - releaseYear;
    }

    function isRoundAnniversary(years) {
        return years > 0 && years % 5 === 0;
    }
}
