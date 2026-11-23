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

    readonly property string memoryKey: "aethon.language"

    readonly property var _registry: [
        { code: "en", name: StringsEn.name, dict: StringsEn.dict, meta: StringsEn.meta },
        { code: "es", name: StringsEs.name, dict: StringsEs.dict, meta: StringsEs.meta },
        { code: "fr", name: StringsFr.name, dict: StringsFr.dict, meta: StringsFr.meta },
        { code: "pt", name: StringsPt.name, dict: StringsPt.dict, meta: StringsPt.meta },
        { code: "ru", name: StringsRu.name, dict: StringsRu.dict, meta: StringsRu.meta },
        { code: "de", name: StringsDe.name, dict: StringsDe.dict, meta: StringsDe.meta },
        { code: "it", name: StringsIt.name, dict: StringsIt.dict, meta: StringsIt.meta }
    ]

    readonly property var availableLanguages: _registry.map(function(l) {
        return { code: l.code, name: l.name };
    })

    readonly property var strings: {
        var out = {};
        for (var i = 0; i < _registry.length; i++) out[_registry[i].code] = _registry[i].dict;
        return out;
    }

    readonly property var metas: {
        var out = {};
        for (var i = 0; i < _registry.length; i++) out[_registry[i].code] = _registry[i].meta;
        return out;
    }

    property string currentLanguage: "en"
    readonly property string _reactive: currentLanguage

    function t(key) {
        if (!key) return "";
        var _ = root._reactive;
        var dict = root.strings[root.currentLanguage];
        if (dict && dict[key] !== undefined) return dict[key];
        if (root.strings["en"] && root.strings["en"][key] !== undefined) return root.strings["en"][key];
        console.warn("[Language] Clave no encontrada:", key);
        return key;
    }

    function plural(n, singularKey, pluralKey, fewKey) {
        var _ = root._reactive;
        var dict = root.strings[root.currentLanguage];

        if (fewKey && dict && dict[fewKey] !== undefined) {
            var mod10 = n % 10;
            var mod100 = n % 100;
            if (mod10 === 1 && mod100 !== 11) return root.t(singularKey);
            if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) return root.t(fewKey);
            return root.t(pluralKey);
        }

        return n === 1 ? root.t(singularKey) : root.t(pluralKey);
    }

    function pluralFormatted(n, singularKey, pluralKey, fewKey) {
        return root.plural(n, singularKey, pluralKey, fewKey).replace("%1", n);
    }

    function meta(key) {
        var _ = root._reactive;
        var m = root.metas[root.currentLanguage];
        if (m && m[key] !== undefined) return m[key];
        var en = root.metas["en"];
        return (en && en[key] !== undefined) ? en[key] : undefined;
    }

    function firstDayOfWeek() {
        return root.meta("weekStart");
    }

    function weekdayShort(col) {
        var keys = ["day_sun", "day_mon", "day_tue", "day_wed", "day_thu", "day_fri", "day_sat"];
        return root.t(keys[(col + root.firstDayOfWeek()) % 7]);
    }

    function monthShort(m) {
        var monthKeys = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"];
        return root.t("month_" + monthKeys[m]);
    }

    function _fillDate(tpl, y, m, d) {
        return tpl.replace("{y}", y).replace("{m}", root.monthShort(m)).replace("{d}", d);
    }

    function formatDate(y, m, d) {
        return root._fillDate(root.meta("dateFull"), y, m, d);
    }

    function formatMonthDay(m, d) {
        return root._fillDate(root.meta("dateMonthDay"), "", m, d);
    }

    function formatNumericDate(date) {
        return Qt.formatDateTime(date, root.meta("dateNumeric"));
    }

    function languageName(code) {
        for (var i = 0; i < root.availableLanguages.length; i++) {
            if (root.availableLanguages[i].code === code) return root.availableLanguages[i].name;
        }
        return code;
    }

    function setLanguage(code) {
        if (code === root.currentLanguage) return;
        var found = false;
        for (var i = 0; i < root.availableLanguages.length; i++) {
            if (root.availableLanguages[i].code === code) { found = true; break; }
        }
        root.currentLanguage = found ? code : "en";
        root.save();
    }

    function load() {
        if (api.memory.has(root.memoryKey)) {
            var stored = api.memory.get(root.memoryKey);
            if (stored && root.strings[stored]) root.currentLanguage = stored;
        }
    }

    function save() {
        api.memory.set(root.memoryKey, root.currentLanguage);
    }

    Component.onCompleted: root.load()
}
