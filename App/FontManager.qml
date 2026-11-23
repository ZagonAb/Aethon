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

    readonly property string defaultLabel: "Game Pocket"
    readonly property string splashLabel: "Jet Brains Mono"

    readonly property var registry: [
        { label: "Roboto", file: "" },
        { label: "Castoro", file: "../assets/fonts/castoro/castoro.ttf" },
        { label: "Jersey", file: "../assets/fonts/jersey/jersey.ttf" },
        { label: "Pixelify", file: "../assets/fonts/pixelify/pixelify.ttf" },
        { label: "Sekuya", file: "../assets/fonts/sekuya/sekuya.ttf" },
        { label: "Smooch", file: "../assets/fonts/smooch/smooch.ttf" },
        { label: "Abril Fatface", file: "../assets/fonts/abrilfatface/abrilfatface.ttf" },
        { label: "Anton", file: "../assets/fonts/anton/anton.ttf" },
        { label: "Archivo", file: "../assets/fonts/archivo/archivo.ttf" },
        { label: "Arimo", file: "../assets/fonts/arimo/arimo.ttf" },
        { label: "Arvo", file: "../assets/fonts/arvo/arvo.ttf" },
        { label: "Assistant", file: "../assets/fonts/assistant/assistant.ttf" },
        { label: "Barlow", file: "../assets/fonts/barlow/barlow.ttf" },
        { label: "Bebas Neue", file: "../assets/fonts/bebasneue/bebasneue.ttf" },
        { label: "Bitter", file: "../assets/fonts/bitter/bitter.ttf" },
        { label: "Cairo", file: "../assets/fonts/cairo/cairo.ttf" },
        { label: "Caveat", file: "../assets/fonts/caveat/caveat.ttf" },
        { label: "Comfortaa", file: "../assets/fonts/comfortaa/comfortaa.ttf" },
        { label: "Crimson Text", file: "../assets/fonts/crimson/crimson.ttf" },
        { label: "Dancing Script", file: "../assets/fonts/dancing/dancing.ttf" },
        { label: "DM Serif Display", file: "../assets/fonts/dm/dm.ttf" },
        { label: "DM Sans", file: "../assets/fonts/dmsans/dmsans.ttf" },
        { label: "DotGothic16", file: "../assets/fonts/dotgothic16/dotgothic16.ttf" },
        { label: "EB Garamond", file: "../assets/fonts/ebgaramond/ebgaramond.ttf" },
        { label: "Exo 2", file: "../assets/fonts/exo2/exo2.ttf" },
        { label: "Fjalla One", file: "../assets/fonts/fjallaone/fjallaone.ttf" },
        { label: "Heebo", file: "../assets/fonts/heebo/heebo.ttf" },
        { label: "Hind", file: "../assets/fonts/hind/hind.ttf" },
        { label: "IBM Plex Mono", file: "../assets/fonts/ibmplexmono/ibmplexmono.ttf" },
        { label: "Inter", file: "../assets/fonts/inter/inter.ttf" },
        { label: "Jacquard", file: "../assets/fonts/jacquard/jacquard.ttf" },
        { label: "Kanit", file: "../assets/fonts/kanit/kanit.ttf" },
        { label: "Lato", file: "../assets/fonts/lato/lato.ttf" },
        { label: "Libre Franklin", file: "../assets/fonts/librefranklin/librefranklin.ttf" },
        { label: "Maven Pro", file: "../assets/fonts/mavenpro/mavenpro.ttf" },
        { label: "Merriweather", file: "../assets/fonts/merriweather/merriweather.ttf" },
        { label: "Montserrat", file: "../assets/fonts/montserrat/montserrat.ttf" },
        { label: "Mukta", file: "../assets/fonts/mukta/mukta.ttf" },
        { label: "Nanum Gothic", file: "../assets/fonts/nanumgothic/nanumgothic.ttf" },
        { label: "Nunito", file: "../assets/fonts/nunito/nunito.ttf" },
        { label: "Oswald", file: "../assets/fonts/oswald/oswald.ttf" },
        { label: "Pacifico", file: "../assets/fonts/pacifico/pacifico.ttf" },
        { label: "Play", file: "../assets/fonts/play/play.ttf" },
        { label: "Playfair Display", file: "../assets/fonts/playfair/playfair.ttf" },
        { label: "Poppins", file: "../assets/fonts/poppins/poppins.ttf" },
        { label: "Prompt", file: "../assets/fonts/prompt/prompt.ttf" },
        { label: "PT Serif", file: "../assets/fonts/ptserif/ptserif.ttf" },
        { label: "Rajdhani", file: "../assets/fonts/rajdhani/rajdhani.ttf" },
        { label: "Raleway", file: "../assets/fonts/raleway/raleway.ttf" },
        { label: "Red Hat Display", file: "../assets/fonts/redhatdisplay/redhatdisplay.ttf" },
        { label: "Shadows Into Light", file: "../assets/fonts/shadowsintolight/shadowsintolight.ttf" },
        { label: "Signika Negative", file: "../assets/fonts/signikanegative/signikanegative.ttf" },
        { label: "Slabo 27px", file: "../assets/fonts/slabo27px/slabo27px.ttf" },
        { label: "Space Grotesk", file: "../assets/fonts/spacegrotesk/spacegrotesk.ttf" },
        { label: "Tajawal", file: "../assets/fonts/tajawal/tajawal.ttf" },
        { label: "Teko", file: "../assets/fonts/teko/teko.ttf" },
        { label: "Tiny5", file: "../assets/fonts/tiny5/tiny5.ttf" },
        { label: "Titillium Web", file: "../assets/fonts/titillium/titillium.ttf" },
        { label: "Terminus", file: "../assets/fonts/terminus/terminus.ttf" },
        { label: "Ubuntu", file: "../assets/fonts/ubuntu/ubuntu.ttf" },
        { label: "Game Pocket", file: "../assets/fonts/gamepocket/gamepocket.ttf" },
        { label: "Jet Brains Mono", file: "../assets/fonts/jetbrains/jetbrains.ttf" }
    ]

    readonly property var options: registry.map(function(e) { return { name: e.label, file: e.file }; })

    function normalize(s) {
        return String(s === undefined || s === null ? "" : s).toLowerCase().replace(/[^a-z0-9]/g, "");
    }

    function entryFor(name) {
        var key = normalize(name);
        if (key === "") return null;
        for (var i = 0; i < registry.length; i++) {
            if (normalize(registry[i].label) === key) return registry[i];
        }
        return null;
    }

    function canonical(name) {
        var e = entryFor(name);
        return e ? e.label : "";
    }

    function _urlFor(entry) {
        return (entry && entry.file !== "") ? Qt.resolvedUrl(entry.file) : "";
    }

    readonly property string activeLabel: SettingsManager.fontChoice
    readonly property var _activeEntry: entryFor(activeLabel) || entryFor(defaultLabel)
    property string activeFamily: "Roboto"

    property FontLoader _activeLoader: FontLoader {
        source: root._urlFor(root._activeEntry)
        onStatusChanged: root._refreshActive()
        onNameChanged: root._refreshActive()
    }

    on_ActiveEntryChanged: _refreshActive()

    function _refreshActive() {
        var e = root._activeEntry;
        if (!e) { root.activeFamily = "Roboto"; return; }
        if (e.file === "") { root.activeFamily = e.label; return; }
        var st = root._activeLoader.status;
        if (st === FontLoader.Ready) root.activeFamily = root._activeLoader.name;
        else if (st === FontLoader.Error) root.activeFamily = e.label;
    }

    property FontLoader _iconLoader: FontLoader {
        source: Qt.resolvedUrl("../assets/fonts/promptfont/promptfont.ttf")
    }

    readonly property string iconFamily: _iconLoader.status === FontLoader.Ready
    ? _iconLoader.name : activeFamily

    property url _splashSource: ""
    property url _pixelSource: ""
    property FontLoader _splashLoader: FontLoader { source: root._splashSource }
    property FontLoader _pixelLoader: FontLoader { source: root._pixelSource }
    readonly property string splashFamily: _splashLoader.status === FontLoader.Ready
    ? _splashLoader.name : splashLabel
    readonly property string pixelFamily: _pixelLoader.status === FontLoader.Ready
    ? _pixelLoader.name : defaultLabel

    function requireSplashFont() {
        if (_splashSource.toString() === "")
            _splashSource = _urlFor(entryFor(splashLabel));
    }

    function requirePixelFont() {
        if (_pixelSource.toString() === "")
            _pixelSource = _urlFor(entryFor(defaultLabel));
    }

    Component.onCompleted: _refreshActive()
}
