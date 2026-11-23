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

    property string colorTheme: "Black"
    property bool soundEffects: true
    property string fontChoice: "Game Pocket"
    readonly property string fontFamily: FontManager.activeFamily
    property string splashStyle: "auto"
    property string buttonStyle: "xbox"
    property bool buttonSwapAB: false
    property bool screensaverEnabled: true
    property bool showVirtualKeyboard: true
    property bool showHomeContinue: false
    property bool showHomeRandomCard: false
    property bool showSystemIcons: false
    property real galleryVideoVolume: 0.25

    property string artPreferenceGameLists: "auto"
    property string artPreferenceGameDetails: "auto"
    property string fxParticles: "auto"

    property bool topbarEnabled: true
    property bool topbarShowClock: true
    property bool topbar24hFormat: false
    property bool topbarShowDate: false
    property string topbarDateFormat: "DD/MM/YY"
    property bool topbarBatteryShowPercent: true
    property bool topbarBatteryShowIcon: false
    property bool topbarAutoHide: true
    property real topbarTextSize: 1.0
    property real topbarIconSize: 1.0

    property bool showToolWeather: false
    property bool showToolMetadata: false
    property bool showToolStatistics: false
    property bool showToolCalendar: false
    property bool showToolGallery: false

    property string fxAnimations: "auto"
    property string fxShadows: "auto"
    property string fxShaderEffects: "auto"
    property string fxRoundedCorners: "auto"
    property string fxMarquee: "auto"
    property string fxBackgroundEffect: "auto"
    property string fxBackgroundAlpha: "auto"

    property var fontScaleMap: ({})
    property real currentFontScale: 1.0

    readonly property var globalFontScales: ({
        "home": 1.0, "library": 1.0, "systemNames": 1.0,
        "games": 1.0, "all": 1.0, "genreNames": 1.0,
        "genres": 1.0, "developerNames": 1.0, "developers": 1.0,
        "publisherNames": 1.0, "publishers": 1.0, "yearDecades": 1.0,
        "yearNumbers": 1.0, "years": 1.0, "tagNames": 1.0,
        "tags": 1.0, "regionNames": 1.0, "regions": 1.0,
        "memories": 1.0, "recent": 1.0,
        "favorites": 1.0, "longplays": 1.0, "tools": 1.0,
        "settings": 1.0, "search": 1.0, "gameDetails": 1.0,
        "raCredentials": 1.0, "achievements": 1.0, "raGames": 1.0,
        "gallery": 1.0, "calendar": 1.0, "calendarDay": 1.0,
        "weather": 1.0, "weatherSettings": 1.0,
        "metadataInspector": 1.0, "statistics": 1.0, "about": 1.0
    })

    readonly property var globalArtScales: ({
        "gameLists": 1.0, "gameDetails": 1.0
    })

    readonly property var manualPresets: ({
        "tiny4x3": {
            fontScales: {
                "home": 0.83, "library": 0.83,
                "systemNames": 0.60, "games": 0.60,
                "all": 0.60,
                "genreNames": 0.60, "genres": 0.60,
                "developerNames": 0.60, "developers": 0.60,
                "publisherNames": 0.60, "publishers": 0.60,
                "yearDecades": 0.90, "yearNumbers": 0.90,
                "years": 0.60,
                "tagNames": 0.60, "tags": 0.60,
                "regionNames": 0.80, "regions": 0.60,
                "memories": 0.83,
                "recent": 0.45, "favorites": 0.45,
                "longplays": 0.45,
                "tools": 0.65, "settings": 0.65,
                "search": 0.50,
                "gameDetails": 0.50,
                "raCredentials": 0.55, "achievements": 0.50,
                "raGames": 0.60, "gallery": 0.55,
                "calendar": 0.55, "calendarDay": 0.55,
                "weather": 0.55, "weatherSettings": 0.55,
                "metadataInspector": 0.55,
                "statistics": 0.55, "about": 0.55
            },
            artScales: { "gameLists": 0.50, "gameDetails": 0.50 },
            effects: {
                animations: "reduced",
                shadows: false,
                shaderEffects: false,
                particles: false,
                loopingAnimations: false,
                roundedCorners: true
            }
        },
        "small4x3": {
            fontScales: {
                "home": 1.33, "library": 1.20, "systemNames": 1.00,
                "games": 0.60, "all": 0.70, "genreNames": 0.80,
                "genres": 0.60, "developerNames": 0.80, "developers": 0.60,
                "publisherNames": 0.80, "publishers": 0.60, "yearDecades": 1.20,
                "yearNumbers": 1.20, "years": 0.60, "tagNames": 0.80,
                "tags": 0.60, "regionNames": 0.80, "regions": 0.60,
                "memories": 1.20, "recent": 0.55,
                "favorites": 0.55, "longplays": 0.55, "tools": 1.00,
                "settings": 1.00, "search": 0.70, "gameDetails": 0.60,
                "raCredentials": 1.00, "achievements": 0.70, "raGames": 0.90,
                "gallery": 0.90, "calendar": 0.65, "calendarDay": 0.65,
                "weather": 0.65, "weatherSettings": 0.65, "metadataInspector": 0.75,
                "statistics": 0.70, "about": 0.7
            },
            artScales: { "gameLists": 0.90, "gameDetails": 0.90 }
        },
        "square720": {
            fontScales: {
                "home": 1.88, "library": 1.50, "systemNames": 1.30,
                "games": 1.20, "all": 1.20, "genreNames": 1.10,
                "genres": 1.10, "developerNames": 1.10, "developers": 1.10,
                "publisherNames": 1.10, "publishers": 1.10, "yearDecades": 1.45,
                "yearNumbers": 1.45, "years": 1.10, "tagNames": 1.10,
                "tags": 1.10, "regionNames": 1.10, "regions": 1.10,
                "memories": 1.50, "recent": 1.10,
                "favorites": 1.10, "longplays": 1.10, "tools": 1.30,
                "settings": 1.10, "search": 0.80, "gameDetails": 1.10,
                "raCredentials": 1.20, "achievements": 0.80, "raGames": 1.10,
                "gallery": 1.10, "calendar": 1.00, "calendarDay": 1.00,
                "weather": 0.85, "weatherSettings": 0.85, "metadataInspector": 1.00,
                "statistics": 1.00, "about": 0.90
            },
            artScales: { "gameLists": 1.20, "gameDetails": 1.20 }
        }
    })

    readonly property var generatedSpecs: ({
        "classic960": { base: "small4x3", k: 1.50, label: "960x720" },
        "classic1280": { base: "small4x3", k: 1.60, label: "1280x960" },
        "mid1240": { base: "square720", k: 1.20, label: "1240x1080" },
        "wide1080": { base: "default", k: 1.20, label: "1080p" }
    })

    function scaleMap(src, k) {
        var out = {};
        for (var key in src)
            out[key] = Math.round(src[key] * k * 100) / 100;
        return out;
    }

    function _mergeEffects(a, b) {
        var out = {};
        if (a) for (var k in a) out[k] = a[k];
        if (b) for (var k2 in b) out[k2] = b[k2];
        return out;
    }

    function buildPresets() {
        var result = root.copyObj(root.manualPresets);
        for (var name in root.generatedSpecs) {
            var spec = root.generatedSpecs[name];
            var baseFonts, baseArt, baseEffects;

            if (spec.base === "default") {
                baseFonts = root.globalFontScales;
                baseArt = root.globalArtScales;
                baseEffects = null;
            } else {
                var basePreset = root.manualPresets[spec.base];
                baseFonts = basePreset.fontScales;
                baseArt = basePreset.artScales;
                baseEffects = basePreset.effects || null;
            }

            var fonts = root.scaleMap(baseFonts, spec.k);
            var arts = root.scaleMap(baseArt, spec.k);

            if (spec.tweak) {
                var tf = spec.tweak.fontScales || {};
                var ta = spec.tweak.artScales || {};
                var te = spec.tweak.effects || null;
                for (var f in tf) fonts[f] = tf[f];
                for (var a in ta) arts[a] = ta[a];
                if (te) baseEffects = root._mergeEffects(baseEffects, te);
            }

            if (spec.effects) baseEffects = root._mergeEffects(baseEffects, spec.effects);

            var entry = { fontScales: fonts, artScales: arts };
            if (baseEffects) entry.effects = baseEffects;
            result[name] = entry;
        }
        return result;
    }

    readonly property var presets: root.buildPresets()

    property string activeContext: "default"
    property var userOverrides: ({})

    property var screenFontScales: {
        var _ctx = root.activeContext;
        var _ovr = root.userOverrides;
        return root.computeEffectiveFontScales(_ctx, _ovr);
    }

    property var artScales: {
        var _ctx = root.activeContext;
        var _ovr = root.userOverrides;
        return root.computeEffectiveArtScales(_ctx, _ovr);
    }

    function copyObj(o) {
        var c = {};
        for (var k in o) c[k] = o[k];
        return c;
    }

    function computeEffectiveFontScales(ctx, overrides) {
        if (overrides && overrides[ctx] && overrides[ctx].fontScales) {
            var merged = root.copyObj(overrides[ctx].fontScales);
            var presetFonts = null;
            if (ctx === "default") {
                presetFonts = root.globalFontScales;
            } else if (root.presets[ctx] && root.presets[ctx].fontScales) {
                presetFonts = root.presets[ctx].fontScales;
            } else {
                presetFonts = root.globalFontScales;
            }
            for (var k in presetFonts) {
                if (merged[k] === undefined) merged[k] = presetFonts[k];
            }
            return merged;
        }
        if (ctx === "default")
            return root.copyObj(root.globalFontScales);
        if (root.presets[ctx] && root.presets[ctx].fontScales)
            return root.copyObj(root.presets[ctx].fontScales);
        return root.copyObj(root.globalFontScales);
    }

    function computeEffectiveArtScales(ctx, overrides) {
        if (overrides && overrides[ctx] && overrides[ctx].artScales) {
            var merged = root.copyObj(overrides[ctx].artScales);
            var presetArts = null;
            if (ctx === "default") {
                presetArts = root.globalArtScales;
            } else if (root.presets[ctx] && root.presets[ctx].artScales) {
                presetArts = root.presets[ctx].artScales;
            } else {
                presetArts = root.globalArtScales;
            }
            for (var k in presetArts) {
                if (merged[k] === undefined) merged[k] = presetArts[k];
            }
            return merged;
        }
        if (ctx === "default")
            return root.copyObj(root.globalArtScales);
        if (root.presets[ctx] && root.presets[ctx].artScales)
            return root.copyObj(root.presets[ctx].artScales);
        return root.copyObj(root.globalArtScales);
    }

    function setActiveContext(ctxName) {
        if (root.activeContext === ctxName) return;
        root.activeContext = ctxName;
    }

    function contextDisplayName(ctx) {
        if (ctx === "default") return "";
        if (ctx === "tiny4x3") return "320x240";
        if (ctx === "small4x3") return "640x480";
        if (ctx === "square720") return "720x720";
        if (root.generatedSpecs[ctx]) return root.generatedSpecs[ctx].label;
        return ctx;
    }

    function resetButtonLabel() {
        var ctx = root.activeContext;
        if (ctx === "default")
            return "⟲ " + Language.t("settings_reset_default");
        return "⟲ " + Language.t("settings_reset_to_prefix") + " "
        + root.contextDisplayName(ctx) + " "
        + Language.t("settings_reset_preset_suffix");
    }

    function screenConfigKey(screenValue) {
        switch (screenValue) {
            case 0: return "home";
            case 1: return "library";
            case 2: return "memories";
            case 3: return "tools";
            case 4: return "settings";
            case 5: return "search";
            case 6: return "gameDetails";
            case 7: return "raCredentials";
            case 8: return "achievements";
            case 9: return "raGames";
            case 10: return "gallery";
            case 11: return "gallery";
            case 12: return "calendar";
            case 13: return "calendarDay";
            case 14: return "weather";
            case 15: return "weatherSettings";
            case 16: return "metadataInspector";
            case 17: return "metadataInspector";
            case 18: return "metadataInspector";
            case 19: return "about";
            case 20: return "statistics";
            default: return "home";
        }
    }

    function getScreenFontScale(screenOrKey) {
        var key = (typeof screenOrKey === "string") ? screenOrKey : root.screenConfigKey(screenOrKey);
        var v = root.screenFontScales[key];
        return (v === undefined) ? 1.0 : v;
    }

    function getArtScale(key) {
        var v = root.artScales[key];
        return (v === undefined) ? 1.0 : v;
    }

    function setScreenFontScale(screenOrKey, value) {
        var key = (typeof screenOrKey === "string") ? screenOrKey : root.screenConfigKey(screenOrKey);
        if (root.getScreenFontScale(key) === value) return;

        var ctx = root.activeContext;
        var newOverrides = root.copyObj(root.userOverrides);
        var cur = newOverrides[ctx];
        var baseFont, baseArt;

        if (cur) {
            baseFont = root.copyObj(cur.fontScales);
            baseArt = root.copyObj(cur.artScales);
            var presetFonts = (root.presets[ctx] && root.presets[ctx].fontScales)
            ? root.presets[ctx].fontScales : root.globalFontScales;
            var presetArts = (root.presets[ctx] && root.presets[ctx].artScales)
            ? root.presets[ctx].artScales : root.globalArtScales;
            for (var kf in presetFonts) {
                if (baseFont[kf] === undefined) baseFont[kf] = presetFonts[kf];
            }
            for (var ka in presetArts) {
                if (baseArt[ka] === undefined) baseArt[ka] = presetArts[ka];
            }
        } else {
            baseFont = root.copyObj(root.screenFontScales);
            baseArt = root.copyObj(root.artScales);
        }

        baseFont[key] = value;
        newOverrides[ctx] = { fontScales: baseFont, artScales: baseArt };
        root.userOverrides = newOverrides;
        root.save();
    }

    function setArtScale(key, value) {
        if (root.getArtScale(key) === value) return;

        var ctx = root.activeContext;
        var newOverrides = root.copyObj(root.userOverrides);
        var cur = newOverrides[ctx];
        var baseFont, baseArt;

        if (cur) {
            baseFont = root.copyObj(cur.fontScales);
            baseArt = root.copyObj(cur.artScales);
            var presetFonts = (root.presets[ctx] && root.presets[ctx].fontScales)
            ? root.presets[ctx].fontScales : root.globalFontScales;
            var presetArts = (root.presets[ctx] && root.presets[ctx].artScales)
            ? root.presets[ctx].artScales : root.globalArtScales;
            for (var kf in presetFonts) {
                if (baseFont[kf] === undefined) baseFont[kf] = presetFonts[kf];
            }
            for (var ka in presetArts) {
                if (baseArt[ka] === undefined) baseArt[ka] = presetArts[ka];
            }
        } else {
            baseFont = root.copyObj(root.screenFontScales);
            baseArt = root.copyObj(root.artScales);
        }

        baseArt[key] = value;
        newOverrides[ctx] = { fontScales: baseFont, artScales: baseArt };
        root.userOverrides = newOverrides;
        root.save();
    }

    function resetActiveContextToDefault() {
        var ctx = root.activeContext;
        if (!root.userOverrides[ctx]) return;
        var newOverrides = root.copyObj(root.userOverrides);
        delete newOverrides[ctx];
        root.userOverrides = newOverrides;
        root.save();
    }

    function hasOverrideForActiveContext() {
        return root.userOverrides[root.activeContext] !== undefined;
    }

    readonly property var fontOptions: FontManager.options

    property var themeColors: {
        "Dark": { bg: "#0d0d0d", fg: "#ffffff", accent: "#7fffd4", card: "#1a1a1a", muted: "#888888", border: "#444444" },
        "Light": { bg: "#f5f5f5", fg: "#222222", accent: "#007acc", card: "#e8e8e8", muted: "#777777", border: "#cccccc" },
        "Blue": { bg: "#0a1628", fg: "#ffffff", accent: "#4fc3f7", card: "#1a2a3a", muted: "#7f95ab", border: "#2f4a63" },
        "Red": { bg: "#1a0a0a", fg: "#ffffff", accent: "#ff6b6b", card: "#2a1a1a", muted: "#a98080", border: "#4a2a2a" },
        "Glacier": { bg: "#e8edf1", fg: "#12181c", accent: "#2f7de1", card: "#d7dee4", muted: "#5c6b78", border: "#b9c5cf" },
        "Grape": { bg: "#120c1a", fg: "#f2eaff", accent: "#a06cff", card: "#1e1430", muted: "#9a86b8", border: "#3a2a50" },
        "Forest": { bg: "#0c140f", fg: "#eafbf0", accent: "#4cc484", card: "#16221a", muted: "#7fa591", border: "#2a3d31" },
        "Sunset": { bg: "#1a1008", fg: "#fff2e6", accent: "#ff8a4c", card: "#2a1c10", muted: "#b89478", border: "#4a3320" },
        "Dracula": { bg: "#282a36", fg: "#f8f8f2", accent: "#bd93f9", card: "#343746", muted: "#6272a4", border: "#44475a" },
        "Nord": { bg: "#2e3440", fg: "#eceff4", accent: "#88c0d0", card: "#3b4252", muted: "#7b88a1", border: "#4c566a" },
        "Solarized": { bg: "#002b36", fg: "#93a1a1", accent: "#2aa198", card: "#073642", muted: "#587075", border: "#0a4652" },
        "Monokai": { bg: "#272822", fg: "#f8f8f2", accent: "#a6e22e", card: "#3e3d32", muted: "#928374", border: "#49483e" },
        "Gruvbox": { bg: "#282828", fg: "#ebdbb2", accent: "#fe8019", card: "#3c3836", muted: "#a89984", border: "#504945" },
        "OneDark": { bg: "#282c34", fg: "#abb2bf", accent: "#61afef", card: "#2c313c", muted: "#6b7280", border: "#3e4451" },
        "Catppuccin": { bg: "#1e1e2e", fg: "#cdd6f4", accent: "#cba6f7", card: "#313244", muted: "#7f849c", border: "#45475a" },
        "OLED": { bg: "#000000", fg: "#ffffff", accent: "#00e5ff", card: "#0a0a0a", muted: "#707070", border: "#1a1a1a" },
        "Black": { bg: "#000000", fg: "#ffffff", accent: "#ffffff", card: "#0a0a0a", muted: "#aaaaaa", border: "#333333" },
        "White": { bg: "#ffffff", fg: "#000000", accent: "#000000", card: "#f5f5f5", muted: "#555555", border: "#cccccc" },
        "Night Blue": { bg: "#0d1b2a", fg: "#e0e6ed", accent: "#3a86ff", card: "#13273c", muted: "#93a4b8", border: "#2a3f5a" },
        "Crimson": { bg: "#1a0000", fg: "#f1e3e4", accent: "#e63946", card: "#2b0a0d", muted: "#c98f92", border: "#4a1f24" },
        "Emerald": { bg: "#04120b", fg: "#e7f6ee", accent: "#2ecc71", card: "#0a2318", muted: "#8fc9a8", border: "#1a3d2a" },
        "Neon Purple": { bg: "#120318", fg: "#efe3f5", accent: "#c77dff", card: "#220a2e", muted: "#b39ac0", border: "#3d1a4a" },
        "Retro Amber": { bg: "#1a1206", fg: "#f3e9d2", accent: "#ffb703", card: "#2b1e08", muted: "#c9ac74", border: "#4a3518" },
        "Ocean Teal": { bg: "#031b1e", fg: "#dffbfa", accent: "#14ffec", card: "#062e33", muted: "#7fc9c5", border: "#0f4348" },
        "Sunset Orange": { bg: "#1a0f05", fg: "#fbe8d8", accent: "#ff7b25", card: "#2b1a08", muted: "#d1a377", border: "#4a2f14" },
        "Rose Gold": { bg: "#1a0e12", fg: "#f7e6e9", accent: "#e8b4bc", card: "#2b171d", muted: "#c99aa1", border: "#4a2a30" },
        "Forest Green": { bg: "#07130a", fg: "#e3f3e5", accent: "#4caf50", card: "#0f2415", muted: "#94b899", border: "#1a3a22" },
        "Slate Gray": { bg: "#14161a", fg: "#e8ebef", accent: "#8ca0b3", card: "#20232a", muted: "#9aa5b1", border: "#333842" },
        "Cyberpunk Pink": { bg: "#0f0018", fg: "#f7e2fb", accent: "#ff2bd6", card: "#1e0330", muted: "#c98ad4", border: "#3a0e52" },
        "Ice White": { bg: "#f4f7fa", fg: "#111827", accent: "#2563eb", card: "#ffffff", muted: "#5b6472", border: "#c8d1dc" },
        "Solar Yellow": { bg: "#1a1600", fg: "#fff6d6", accent: "#ffd60a", card: "#2b2500", muted: "#cbb35a", border: "#4a3f00" },
        "Deep Indigo": { bg: "#080318", fg: "#e6e0fb", accent: "#7c5cff", card: "#12082e", muted: "#a79ad1", border: "#25164a" },
        "Copper": { bg: "#180d05", fg: "#f2e1cf", accent: "#c97b3d", card: "#2b1a0d", muted: "#c9a179", border: "#4a2f1a" },
        "Matrix Green": { bg: "#010a02", fg: "#d9ffdc", accent: "#39ff14", card: "#051506", muted: "#7fcf85", border: "#0f2a14" },
        "Royal Purple": { bg: "#0d0518", fg: "#ece0f8", accent: "#9d4edd", card: "#180a2b", muted: "#b49bc9", border: "#2e1a4a" },
        "Coral Reef": { bg: "#170a08", fg: "#fbe4e0", accent: "#ff6f61", card: "#2b1310", muted: "#d19c94", border: "#4a241e" },
        "Steel Blue": { bg: "#0b1116", fg: "#dde7ee", accent: "#4a7a96", card: "#141d26", muted: "#8ea3b3", border: "#263a4a" },
        "Golden Hour": { bg: "#1a1004", fg: "#fbe9c9", accent: "#f4a300", card: "#2e1c07", muted: "#d1ab6a", border: "#4a3010" },
        "Cherry Blossom": { bg: "#fdf2f6", fg: "#3b1f27", accent: "#d6336c", card: "#ffffff", muted: "#8a5468", border: "#d9c4cc" },
        "Graphite": { bg: "#0e0e0e", fg: "#e6e6e6", accent: "#b0b0b0", card: "#1a1a1a", muted: "#999999", border: "#333333" },
        "Vampire Red": { bg: "#0a0000", fg: "#f0d6d6", accent: "#8b0000", card: "#180404", muted: "#a56b6b", border: "#3a0a0a" },
        "Arctic Ice": { bg: "#eaf6fb", fg: "#06283d", accent: "#00b4d8", card: "#ffffff", muted: "#47728c", border: "#b8d4e0" },
        "Lava Flow": { bg: "#1a0500", fg: "#ffe1d1", accent: "#ff4500", card: "#2e0a02", muted: "#d1846a", border: "#4a1508" },
        "Mist": { bg: "#d6e4e8", fg: "#0f1f28", accent: "#4a7588", card: "#e0ecf0", muted: "#6a8894", border: "#a8bcc6" },
        "Verdant": { bg: "#8faa10", fg: "#0f380f", accent: "#2e5a2e", card: "#9cb818", muted: "#4a6820", border: "#6b8c0a" },
        "Willow": { bg: "#a4b8a4", fg: "#1e3028", accent: "#496856", card: "#b2c4b2", muted: "#587464", border: "#8aa090" },
        "Lagoon": { bg: "#5cb89a", fg: "#0d3326", accent: "#1f7a5c", card: "#6ec4a8", muted: "#2c6250", border: "#309278" },
        "Ember": { bg: "#c94420", fg: "#1a0500", accent: "#7a1a00", card: "#d45230", muted: "#5a1400", border: "#9a2c10" }
    }

    property var customThemes: ({})

    readonly property var allThemeNames: {
        var _lang = Language.currentLanguage;
        var names = [];
        for (var k in root.themeColors) names.push(k);
        for (var c in root.customThemes) {
            if (names.indexOf(c) === -1) names.push(c);
        }
        names.sort();
        return names;
    }

    function defaultScaleForFont(family) {
        if (FontManager.normalize(family) === "gamepocket") return 1.875;
        return 1.0;
    }

    function _migrateFontScaleMap(map) {
        var out = {};
        for (var k in map) {
            var c = FontManager.canonical(k) || k;
            out[c] = map[k];
        }
        return out;
    }

    function load() {
        var stored = api.memory.get("aethon.settings");
        if (stored) {
            if (stored.colorTheme !== undefined) root.colorTheme = stored.colorTheme;
            if (stored.soundEffects !== undefined) root.soundEffects = stored.soundEffects;
            if (stored.fontFamily !== undefined) root.fontChoice = FontManager.canonical(stored.fontFamily) || FontManager.defaultLabel;
            if (stored.splashStyle !== undefined) {
                var validSplashes = ["auto", "classic", "isotipo", "zero", "off"];
                root.splashStyle = validSplashes.indexOf(stored.splashStyle) >= 0 ? stored.splashStyle : "auto";
            }
            if (stored.buttonStyle !== undefined) {
                var validBtn = ["xbox", "playstation", "nintendo", "keyboard", "numbers"];
                root.buttonStyle = validBtn.indexOf(stored.buttonStyle) >= 0 ? stored.buttonStyle : "xbox";
            }
            if (stored.buttonSwapAB !== undefined) root.buttonSwapAB = stored.buttonSwapAB;
            if (stored.screensaverEnabled !== undefined) root.screensaverEnabled = stored.screensaverEnabled;
            if (stored.showVirtualKeyboard !== undefined) root.showVirtualKeyboard = stored.showVirtualKeyboard;
            if (stored.showHomeContinue !== undefined) root.showHomeContinue = stored.showHomeContinue;
            if (stored.showHomeRandomCard !== undefined) root.showHomeRandomCard = stored.showHomeRandomCard;
            if (stored.showSystemIcons !== undefined) root.showSystemIcons = stored.showSystemIcons;
            if (stored.galleryVideoVolume !== undefined) root.galleryVideoVolume = stored.galleryVideoVolume;
            if (stored.fontScaleMap !== undefined) root.fontScaleMap = root._migrateFontScaleMap(stored.fontScaleMap);
            if (stored.userOverrides !== undefined) root.userOverrides = stored.userOverrides;
            if (stored.artPreferenceGameLists !== undefined) root.artPreferenceGameLists = stored.artPreferenceGameLists;
            if (stored.artPreferenceGameDetails !== undefined) root.artPreferenceGameDetails = stored.artPreferenceGameDetails;
            if (stored.topbarEnabled !== undefined) root.topbarEnabled = stored.topbarEnabled;
            if (stored.topbarShowClock !== undefined) root.topbarShowClock = stored.topbarShowClock;
            if (stored.topbar24hFormat !== undefined) root.topbar24hFormat = stored.topbar24hFormat;
            if (stored.topbarShowDate !== undefined) root.topbarShowDate = stored.topbarShowDate;
            if (stored.topbarDateFormat !== undefined) root.topbarDateFormat = stored.topbarDateFormat;
            if (stored.topbarBatteryShowPercent !== undefined) root.topbarBatteryShowPercent = stored.topbarBatteryShowPercent;
            if (stored.topbarBatteryShowIcon !== undefined) root.topbarBatteryShowIcon = stored.topbarBatteryShowIcon;
            if (stored.topbarAutoHide !== undefined) root.topbarAutoHide = stored.topbarAutoHide;
            if (stored.topbarTextSize !== undefined) root.topbarTextSize = stored.topbarTextSize;
            if (stored.topbarIconSize !== undefined) root.topbarIconSize = stored.topbarIconSize;
            if (stored.showToolWeather !== undefined) root.showToolWeather = stored.showToolWeather;
            if (stored.showToolMetadata !== undefined) root.showToolMetadata = stored.showToolMetadata;
            if (stored.showToolStatistics !== undefined) root.showToolStatistics = stored.showToolStatistics;
            if (stored.showToolCalendar !== undefined) root.showToolCalendar = stored.showToolCalendar;
            if (stored.showToolGallery !== undefined) root.showToolGallery = stored.showToolGallery;
            if (stored.fxParticles !== undefined) root.fxParticles = stored.fxParticles;
            if (stored.fxAnimations !== undefined) root.fxAnimations = stored.fxAnimations;
            if (stored.fxShadows !== undefined) root.fxShadows = stored.fxShadows;
            if (stored.fxShaderEffects !== undefined) root.fxShaderEffects = stored.fxShaderEffects;
            if (stored.fxRoundedCorners !== undefined) root.fxRoundedCorners = stored.fxRoundedCorners;
            if (stored.fxMarquee !== undefined) root.fxMarquee = stored.fxMarquee;
            if (stored.fxBackgroundEffect !== undefined) root.fxBackgroundEffect = stored.fxBackgroundEffect;
            if (stored.fxBackgroundAlpha !== undefined) root.fxBackgroundAlpha = stored.fxBackgroundAlpha;
        }

        var customStored = api.memory.get("aethon.customThemes");
        if (customStored && typeof customStored === "object") {
            root.customThemes = customStored;
        }

        root.updateCurrentFontScale();
        Language.load();
    }

    function save() {
        var obj = {
            schemaVersion: 12,
            colorTheme: root.colorTheme,
            soundEffects: root.soundEffects,
            fontFamily: root.fontChoice,
            splashStyle: root.splashStyle,
            buttonStyle: root.buttonStyle,
            buttonSwapAB: root.buttonSwapAB,
            screensaverEnabled: root.screensaverEnabled,
            showVirtualKeyboard: root.showVirtualKeyboard,
            showHomeContinue: root.showHomeContinue,
            showHomeRandomCard: root.showHomeRandomCard,
            showSystemIcons: root.showSystemIcons,
            galleryVideoVolume: root.galleryVideoVolume,
            fontScaleMap: root.fontScaleMap,
            userOverrides: root.userOverrides,
            artPreferenceGameLists: root.artPreferenceGameLists,
            artPreferenceGameDetails: root.artPreferenceGameDetails,
            topbarEnabled: root.topbarEnabled,
            topbarShowClock: root.topbarShowClock,
            topbar24hFormat: root.topbar24hFormat,
            topbarShowDate: root.topbarShowDate,
            topbarDateFormat: root.topbarDateFormat,
            topbarBatteryShowPercent: root.topbarBatteryShowPercent,
            topbarBatteryShowIcon: root.topbarBatteryShowIcon,
            topbarAutoHide: root.topbarAutoHide,
            topbarTextSize: root.topbarTextSize,
            topbarIconSize: root.topbarIconSize,
            showToolWeather: root.showToolWeather,
            showToolMetadata: root.showToolMetadata,
            showToolStatistics: root.showToolStatistics,
            showToolCalendar: root.showToolCalendar,
            showToolGallery: root.showToolGallery,

            fxParticles: root.fxParticles,
            fxAnimations: root.fxAnimations,
            fxShadows: root.fxShadows,
            fxShaderEffects: root.fxShaderEffects,
            fxRoundedCorners: root.fxRoundedCorners,
            fxMarquee: root.fxMarquee,
            fxBackgroundEffect: root.fxBackgroundEffect,
            fxBackgroundAlpha: root.fxBackgroundAlpha
        };

        api.memory.set("aethon.settings", obj);
        api.memory.set("aethon.customThemes", root.customThemes);
    }

    function saveCustomTheme(name, colors) {
        if (!name || name.trim() === "") return false;
        var cleanName = name.trim();
        var newCustom = {};
        for (var k in root.customThemes) newCustom[k] = root.customThemes[k];
        newCustom[cleanName] = {
            bg: colors.bg, fg: colors.fg, accent: colors.accent,
            card: colors.card, muted: colors.muted, border: colors.border
        };
        root.customThemes = newCustom;
        root.colorTheme = cleanName;
        root.save();
        return true;
    }

    readonly property var _slotKey: [95, 113, 113, 67, 68, 12, 121, 87, 65, 101]

    readonly property string _slotLabel: {
        var s = "";
        for (var i = 0; i < root._slotKey.length; i++)
            s += String.fromCharCode(root._slotKey[i] ^ ((i * 5 + 19) & 63));
        return s;
    }

    function presetLabel() { return root._slotLabel; }

    function presetMerged() {
        return root.customThemes[root._slotLabel] !== undefined;
    }

    function mergePreset() {
        var c = [];
        for (var i = 0; i < 6; i++) c.push(GameUtils.lutHex(i));
        return root.saveCustomTheme(root._slotLabel, {
            bg: c[0], fg: c[1], accent: c[2],
            card: c[3], muted: c[4], border: c[5]
        });
    }

    function deleteCustomTheme(name) {
        if (!root.customThemes[name]) return false;
        var newCustom = {};
        for (var k in root.customThemes) {
            if (k !== name) newCustom[k] = root.customThemes[k];
        }
        root.customThemes = newCustom;
        if (root.colorTheme === name) root.colorTheme = "Black";
        root.save();
        return true;
    }

    function isCustomTheme(name) {
        return root.customThemes[name] !== undefined;
    }

    function updateCurrentFontScale() {
        var scale = root.fontScaleMap[root.fontChoice];
        if (scale === undefined) {
            scale = root.defaultScaleForFont(root.fontChoice);
        }
        root.currentFontScale = scale;
    }

    function setFontFamily(newFamily) {
        var canon = FontManager.canonical(newFamily) || FontManager.defaultLabel;
        if (canon === root.fontChoice) return;
        root.fontScaleMap[root.fontChoice] = root.currentFontScale;
        root.fontChoice = canon;
        root.updateCurrentFontScale();
        root.save();
    }

    function setFontScaleForCurrent(newScale) {
        if (newScale === root.currentFontScale) return;
        root.currentFontScale = newScale;
        root.fontScaleMap[root.fontChoice] = newScale;
        root.save();
    }

    function updateFontOptions(newOptions) {
    }

    function getCurrentColors() {
        if (root.customThemes[root.colorTheme]) {
            return root.customThemes[root.colorTheme];
        }
        return root.themeColors[root.colorTheme] || root.themeColors["Black"];
    }
}
