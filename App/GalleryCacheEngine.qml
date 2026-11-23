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

    readonly property string memoryKey: "aethon.gallery"
    property bool _loaded: false
    property bool _dirty: false
    property var _bad: ({})
    property var _verified: ({})
    property int revision: 0

    Component.onCompleted: root._ensureLoaded()

    property Timer _saveTimer: Timer {
        interval: 1500
        repeat: false
        running: false
        onTriggered: root.save()
    }

    function _ensureLoaded() {
        if (root._loaded) return;
        try {
            if (api.memory.has(root.memoryKey)) {
                var d = api.memory.get(root.memoryKey);
                if (d) {
                    if (d.bad) {
                        for (var i = 0; i < d.bad.length; i++)
                            root._bad[d.bad[i]] = true;
                    }
                    if (d.verified) {
                        for (var k in d.verified)
                            root._verified[k] = d.verified[k];
                    }
                }
            }
        } catch (e) {
            console.log("[GalleryCacheEngine] load error: " + e);
        }
        root._loaded = true;
    }

    function isRemote(url) {
        if (!url) return false;
        var s = "" + url;
        return s.indexOf("http://") === 0 || s.indexOf("https://") === 0;
    }

    function verifiedCount(assetKey) {
        if (!root._loaded) {
            Qt.callLater(root._ensureLoaded);
            return -1;
        }
        var v = root._verified[assetKey];
        return (v === undefined) ? -1 : v;
    }

    function setVerified(assetKey, count) {
        if (!root._loaded) return;
        if (root._verified[assetKey] !== count) {
            root._verified[assetKey] = count;
            root._dirty = true;
            root.scheduleSave();
        }
    }

    function isBad(url) {
        if (!root._loaded) {
            Qt.callLater(root._ensureLoaded);
            return false;
        }
        return root._bad[url] === true;
    }

    function markBad(url) {
        if (!root._loaded) return;
        if (root._bad[url] === true) return;
        root._bad[url] = true;
        root._dirty = true;
        root.revision++;
        root.scheduleSave();
    }

    function markGood(url) {
        if (!root._loaded) return;
        if (root._bad[url] !== undefined) {
            delete root._bad[url];
            root._dirty = true;
            root.revision++;
            root.scheduleSave();
        }
    }

    function resetAll() {
        root._bad = {};
        root._verified = {};
        root.revision++;
        root.save();
    }

    Component.onDestruction: { if (root._dirty) root.save(); }

    function scheduleSave() {
        root._saveTimer.restart();
    }

    function save() {
        root._saveTimer.stop();
        var arr = [];
        for (var u in root._bad) arr.push(u);
        try {
            api.memory.set(root.memoryKey, { bad: arr, verified: root._verified });
            root._dirty = false;
        } catch (e) {
            console.log("[GalleryCacheEngine] save error: " + e);
        }
    }
}
