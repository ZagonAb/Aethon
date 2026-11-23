// Aethon
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
import QtQuick 2.15
import "../App"
import "../Layout"
import "../Components"

FocusScope {
    id: root
    anchors.fill: parent
    focus: true

    property string currentView: "main"
    property int screenFontIndex: 0
    property int artIndex: 0
    property int topbarIndex: 0
    property int toolsIndex: 0
    property int effectsIndex: 0
    property int backgroundEffectIndex: 0
    readonly property real scaleFontFrom: 0.45
    readonly property real scaleFontTo: 1.875
    readonly property real scaleArtFrom: 0.5
    readonly property real scaleArtTo: 2.0
    readonly property real scaleStep: 0.05
    readonly property real topbarSizeFrom: 0.5
    readonly property real topbarSizeTo: 3.0
    readonly property real topbarSizeStep: 0.05
    readonly property real scrollBarWidth: 6
    readonly property real scrollBarMargin: 6
    readonly property real rowHeight: SettingsManager.activeContext === "tiny4x3"
    ? Math.round(PocketMetrics.bodySize * 2.6)
    : 60

    readonly property var assetChoices: [
        "auto", "cartridge", "boxFront", "boxFull", "boxBack", "boxSpine",
        "logo", "tile", "banner", "poster", "background", "screenshot",
        "titlescreen", "marquee", "bezel"
    ]

    readonly property var dateFormatChoices: [
        "DD/MM/YY", "MM/DD/YY", "YYYY-MM-DD", "YYYY/MM/DD"
    ]

    ThemeEditor {
        id: themeEditor
        onSaved: function(name, colors) {
            var oldName = themeEditor.originalName;
            SettingsManager.saveCustomTheme(name, colors);
            if (oldName !== "" && oldName !== name)
                SettingsManager.deleteCustomTheme(oldName);
        }
        onClosed: root.forceActiveFocus()
    }

    component ScrollIndicator: Item {
        id: scrollRoot

        property var listView: null
        property int visibleRows: 1
        property real scrollFraction: 0
        property int totalCount: 0
        property color trackColor: "gray"
        property color thumbColor: "white"
        property real barWidth: 6

        property real thumbMinHeight: 24
        property real thumbMaxRatio: 0.15

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: barWidth

        visible: listView !== null && listView.visible && totalCount > visibleRows

        Rectangle {
            id: scrollTrack
            anchors.fill: parent
            radius: width / 2
            color: scrollRoot.trackColor
            opacity: 0.4

            Rectangle {
                id: scrollThumb
                width: parent.width
                radius: width / 2
                color: scrollRoot.thumbColor
                opacity: 0.75
                height: Math.max(scrollRoot.thumbMinHeight,
                                 Math.min(scrollTrack.height * scrollRoot.thumbMaxRatio,
                                          scrollTrack.height * Math.min(1, scrollRoot.visibleRows / Math.max(scrollRoot.totalCount, 1))))
                y: (scrollTrack.height - height) * scrollRoot.scrollFraction

                Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
            }
        }
    }

    property bool deleteArmed: false
    property bool cacheClearArmed: false
    onCurrentIndexChanged: {
        root.deleteArmed = false;
        root.cacheClearArmed = false;
    }
    Connections {
        target: SettingsManager
        function onColorThemeChanged() {
            root.deleteArmed = false;
            if (!root.mainItemEnabled(root.currentIndex))
                root.currentIndex = root.mainIndexOf("colorTheme");
        }
    }

    property var settingsModel: {
        var langs = Language.availableLanguages;
        var fonts = SettingsManager.fontOptions;

        return [
            { key: "colorTheme", labelKey: "settings_theme_label", type: "choice",
                choices: [], default: "Black" },
            { key: "createCustomTheme", labelKey: "settings_custom_theme_new", type: "action" },
            { key: "editCustomTheme", labelKey: "settings_custom_theme_edit", type: "action" },
            { key: "deleteCustomTheme", labelKey: "settings_custom_theme_delete", type: "action" },
            { key: "language", labelKey: "settings_language_label", type: "choice",
                choices: langs.map(function(l) { return l.code; }), default: "en" },
            { key: "splashStyle", labelKey: "settings_splash_label", type: "choice",
                choices: ["auto", "classic", "isotipo", "zero", "off"], default: "auto" },
            { key: "buttonStyle", labelKey: "settings_button_style_label", type: "choice",
                choices: ["xbox", "playstation", "nintendo", "keyboard", "numbers"], default: "xbox" },
            { key: "buttonSwapAB", labelKey: "settings_button_swap_label", type: "boolean", default: false },
            { key: "screensaverEnabled", labelKey: "settings_screensaver_label", type: "boolean", default: true },
            { key: "showVirtualKeyboard", labelKey: "settings_search_keyboard", type: "boolean", default: true },
            { key: "showHomeContinue", labelKey: "settings_home_continue_label", type: "boolean", default: false },
            { key: "showHomeRandomCard", labelKey: "settings_home_random_label", type: "boolean", default: false },
            { key: "fontSize", labelKey: "settings_font_size_label", type: "slider",
                from: 0.5, to: 1.875, step: 0.05, default: 1.0 },
            { key: "soundEffects", labelKey: "settings_sound_label", type: "boolean", default: true },
            { key: "fontFamily", labelKey: "settings_font_label", type: "choice",
                choices: fonts.map(function(f) { return f.name; }), default: "Game Pocket" },
            { key: "showSystemIcons", labelKey: "settings_system_icons", type: "boolean", default: false },
            { key: "screenFonts", labelKey: "settings_screen_sizes_label", type: "submenu", target: "screenFonts" },
            { key: "artSizes", labelKey: "settings_art_sizes_label", type: "submenu", target: "artSizes" },
            { key: "galleryVideoVolume", labelKey: "settings_gallery_volume", type: "slider",
                from: 0.0, to: 1.0, step: 0.05, default: 0.25 },
            { key: "clearGalleryCache", labelKey: "settings_clear_gallery_cache", descriptionKey: "settings_clear_gallery_cache_desc", type: "action" },
            { key: "artPreferenceGameLists", labelKey: "settings_art_change_lists_label", type: "choice",
                choices: root.assetChoices, default: "auto" },
            { key: "artPreferenceGameDetails", labelKey: "settings_art_change_details_label", type: "choice",
                choices: root.assetChoices, default: "auto" },
            { key: "topbar", labelKey: "settings_topbar_label", type: "submenu", target: "topbar" },
            { key: "effects", labelKey: "settings_effects_label", type: "submenu", target: "effects" },
            { key: "toolsVisibility", labelKey: "settings_tools_label", type: "submenu", target: "toolsVisibility" }
        ];
    }

    property var topbarModel: {
        var _lang = Language.currentLanguage;
        return [
            { key: "topbarEnabled", labelKey: "settings_topbar_enabled", type: "boolean" },
            { key: "topbarAutoHide", labelKey: "settings_topbar_auto_hide", type: "boolean" },
            { key: "topbarShowClock", labelKey: "settings_topbar_show_clock", type: "boolean" },
            { key: "topbar24hFormat", labelKey: "settings_topbar_24h", type: "boolean" },
            { key: "topbarShowDate", labelKey: "settings_topbar_show_date", type: "boolean" },
            { key: "topbarDateFormat", labelKey: "settings_topbar_date_format", type: "choice",
                choices: root.dateFormatChoices },
                { key: "topbarBatteryShowPercent", labelKey: "settings_topbar_battery_percent", type: "boolean" },
                { key: "topbarBatteryShowIcon", labelKey: "settings_topbar_battery_icon", type: "boolean" },
                { key: "topbarTextSize", labelKey: "settings_topbar_text_size", type: "slider",
                    from: root.topbarSizeFrom, to: root.topbarSizeTo, step: root.topbarSizeStep },
                    { key: "topbarIconSize", labelKey: "settings_topbar_icon_size", type: "slider",
                        from: root.topbarSizeFrom, to: root.topbarSizeTo, step: root.topbarSizeStep }
        ];
    }

    property var effectsModel: [
        { key: "fxAnimations", labelKey: "settings_effects_animations", type: "choice", choices: ["auto", "full", "reduced", "off"] },
        { key: "fxShadows", labelKey: "settings_effects_shadows", type: "choice", choices: ["auto", "on", "off"] },
        { key: "fxShaderEffects", labelKey: "settings_effects_shaders", type: "choice", choices: ["auto", "on", "off"] },
        { key: "fxRoundedCorners", labelKey: "settings_effects_rounded", type: "choice", choices: ["auto", "on", "off"] },
        { key: "fxMarquee", labelKey: "settings_effects_marquee", type: "choice", choices: ["auto", "on", "off"] },
        { key: "fxParticles", labelKey: "settings_effects_living_background", type: "choice", choices: ["auto", "on", "off"] },
        { key: "fxBackgroundEffect", labelKey: "settings_effects_background_effect",
            type: "submenu", target: "backgroundEffect" },
            { key: "fxBackgroundAlpha", labelKey: "settings_effects_alpha",
                type: "choice",
                choices: ["auto",
                "100", "95", "90", "85", "80", "75", "70", "65",
                "60", "55", "50", "45", "40", "35", "30", "25",
                "20", "15", "10", "5", "0"] }
    ]

    readonly property var backgroundEffectModel:
    ["auto"].concat((EffectsManager && EffectsManager.bgEffects) || [])

    property var toolsModel: [
        { key: "showToolWeather", labelKey: "settings_tools_weather", type: "boolean" },
        { key: "showToolMetadata", labelKey: "settings_tools_metadata", type: "boolean" },
        { key: "showToolStatistics", labelKey: "settings_tools_statistics", type: "boolean" },
        { key: "showToolCalendar", labelKey: "settings_tools_calendar", type: "boolean" },
        { key: "showToolGallery", labelKey: "settings_tools_gallery", type: "boolean" }
    ]

    property var screenFontModel: [
        { key: "__reset__", isReset: true },
        { key: Enums.screenHome },
        { key: "library" },
        { key: "systemNames" },
        { key: "games" },
        { key: "all" },
        { key: "genreNames" },
        { key: "genres" },
        { key: "developerNames" },
        { key: "developers" },
        { key: "publisherNames" },
        { key: "publishers" },
        { key: "yearDecades" },
        { key: "yearNumbers" },
        { key: "years" },
        { key: "tagNames" },
        { key: "tags" },
        { key: "regionNames" },
        { key: "regions" },
        { key: Enums.screenMemories },
        { key: "recent" },
        { key: "favorites" },
        { key: "longplays" },
        { key: Enums.screenTools },
        { key: Enums.screenSettings },
        { key: Enums.screenSearch },
        { key: Enums.screenGameDetails },
        { key: Enums.screenRACredentials },
        { key: Enums.screenAchievements },
        { key: Enums.screenRAGames },
        { key: "gallery" }
    ]

    property var artModel: [
        { key: "__reset__", isReset: true },
        { key: "gameLists", labelKey: "settings_art_game_lists" },
        { key: "gameDetails", labelKey: "settings_art_game_details" }
    ]

    property int currentIndex: 0

    function displayValue(item) {
        if (!item) return "";

        if (item.key === "editCustomTheme" || item.key === "deleteCustomTheme" || item.key === "clearGalleryCache") {
            return "";
        }

        if (item.type === "boolean") {
            var val = SettingsManager[item.key];
            return val ? Language.t("settings_on") : Language.t("settings_off");
        }

        if (item.type === "choice") {
            if (item.key === "colorTheme") return SettingsManager.colorTheme;
            if (item.key === "language") return Language.languageName(Language.currentLanguage);
            if (item.key === "fontFamily") return SettingsManager.fontChoice;
            if (item.key === "splashStyle") {
                if (SettingsManager.splashStyle === "auto") return Language.t("settings_splash_auto");
                if (SettingsManager.splashStyle === "isotipo") return Language.t("settings_splash_isotipo");
                if (SettingsManager.splashStyle === "zero") return Language.t("settings_splash_zero");
                if (SettingsManager.splashStyle === "off") return Language.t("settings_splash_off");
                return Language.t("settings_splash_classic");
            }
            if (item.key === "buttonStyle") {
                if (SettingsManager.buttonStyle === "xbox") return "Xbox";
                if (SettingsManager.buttonStyle === "playstation") return "PlayStation";
                if (SettingsManager.buttonStyle === "nintendo") return "Nintendo";
                if (SettingsManager.buttonStyle === "keyboard") return Language.t("settings_button_style_keyboard");
                return Language.t("settings_button_style_numbers");
            }
            if (item.key === "artPreferenceGameLists") return SettingsManager.artPreferenceGameLists;
            if (item.key === "artPreferenceGameDetails") return SettingsManager.artPreferenceGameDetails;
            if (item.key === "topbarDateFormat") return SettingsManager.topbarDateFormat;
        }

        if (item.type === "slider") {
            if (item.key === "fontSize") {
                var v = SettingsManager.currentFontScale;
                return Math.round(v * 100) + "%";
            }
            if (item.key === "galleryVideoVolume") {
                return Math.round(SettingsManager.galleryVideoVolume * 100) + "%";
            }
            if (item.key === "topbarTextSize" || item.key === "topbarIconSize") {
                var vv = SettingsManager[item.key];
                return Math.round(vv * 100) + "%";
            }
        }
        return "";
    }

    function itemLabel(item) {
        if (!item) return "";
        if (item.key === "deleteCustomTheme" && root.deleteArmed)
            return Language.t("settings_custom_theme_delete_confirm");
        if (item.key === "clearGalleryCache" && root.cacheClearArmed)
            return Language.t("settings_custom_theme_delete_confirm");
        return Language.t(item.labelKey);
    }

    function dynamicDescriptionKey(item) {
        if (!item) return "";

        if (item.key === "showHomeContinue") {
            if (SettingsManager.showHomeContinue && AppState.homeContinueOverflow)
                return "settings_home_cards_overflow";
        }
        if (item.key === "showHomeRandomCard") {
            if (SettingsManager.showHomeRandomCard && AppState.homeRandomOverflow)
                return "settings_home_cards_overflow";
        }
        return item.descriptionKey || "";
    }

    function backgroundEffectLabel(value) {
        if (value === "auto") return Language.t("settings_effects_auto");
        if (value === "abyssal") return "Abyssal Drift";
        if (value === "ribbon") return "Ribbon";
        if (value === "digitalrain") return "Digital Rain";
        if (value === "starfield") return "Starfield";
        if (value === "hexgrid") return "Hexgrid";
        if (value === "softbokeh") return "Soft Bokeh";
        if (value === "retrogrid") return "Retro Grid";
        return value;
    }

    function displayEffectsValue(item) {
        if (!item) return "";

        if (item.key === "fxBackgroundEffect") {
            return root.backgroundEffectLabel(SettingsManager[item.key]);
        }

        var val = SettingsManager[item.key];
        if (val === "auto") return Language.t("settings_effects_auto");
        if (val === "full") return Language.t("settings_effects_full");
        if (val === "reduced") return Language.t("settings_effects_reduced");
        if (val === "off") return Language.t("settings_effects_off");
        if (val === "on") return Language.t("settings_effects_on");
        if (item.key === "fxBackgroundAlpha") {
            var a = SettingsManager[item.key];
            if (a === "auto") return Language.t("settings_effects_auto");
            return a + "%";
        }
        return val;
    }

    function displayTopbarValue(item) {
        if (!item) return "";
        if (item.type === "boolean") {
            var val = SettingsManager[item.key];
            return val ? Language.t("settings_on") : Language.t("settings_off");
        }
        if (item.type === "choice") {
            if (item.key === "topbarDateFormat") {
                var fmt = SettingsManager.topbarDateFormat;
                if (fmt === "DD/MM/YY") return Language.t("settings_topbar_date_format_ddmmyy");
                if (fmt === "MM/DD/YY") return Language.t("settings_topbar_date_format_mmddyy");
                if (fmt === "YYYY-MM-DD") return Language.t("settings_topbar_date_format_yyyymmdd");
                if (fmt === "YYYY/MM/DD") return Language.t("settings_topbar_date_format_yyyymmdd_slash");
                return fmt;
            }
        }
        if (item.type === "slider") {
            var vv = SettingsManager[item.key];
            return Math.round(vv * 100) + "%";
        }
        return "";
    }

    function mainItemEnabled(idx) {
        var item = root.settingsModel[idx];
        if (!item) return false;
        if (item.key === "editCustomTheme" || item.key === "deleteCustomTheme")
            return SettingsManager.isCustomTheme(SettingsManager.colorTheme);
        return true;
    }

    function mainNextEnabled(fromIdx, delta) {
        var n = root.settingsModel.length;
        var i = fromIdx + delta;
        while (i >= 0 && i < n) {
            if (root.mainItemEnabled(i)) return i;
            i += delta;
        }
        return fromIdx;
    }

    function mainIndexOf(key) {
        for (var i = 0; i < root.settingsModel.length; i++)
            if (root.settingsModel[i].key === key) return i;
            return 0;
    }

    function topbarItemEnabled(idx) {
        var item = root.topbarModel[idx];
        if (!item) return false;
        if (item.key === "topbarEnabled") return true;
        if (item.key === "topbarAutoHide") return SettingsManager.topbarEnabled;
        if (!SettingsManager.topbarEnabled) return false;
        if (item.key === "topbar24hFormat") return SettingsManager.topbarShowClock;
        if (item.key === "topbarDateFormat") return SettingsManager.topbarShowDate;
        return true;
    }

    function topbarNextEnabled(fromIdx, delta) {
        var n = root.topbarModel.length;
        if (n === 0) return fromIdx;
        var i = fromIdx;
        for (var step = 0; step < n; step++) {
            i = (i + delta + n) % n;
            if (root.topbarItemEnabled(i)) return i;
        }
        return fromIdx;
    }

    function formatScale(value) {
        if (value === undefined || value === null) return "—";
        return value.toFixed(2) + "×";
    }

    function screenFontLabel(key) {
        if (key === "__reset__")
            return SettingsManager.resetButtonLabel();
        if (typeof key === "string") {
            switch (key) {
                case "library": return Language.t("settings_screen_library_menu");
                case "systemNames": return Language.t("settings_screen_system_names");
                case "games": return Language.t("settings_screen_system_games");
                case "all": return Language.t("settings_screen_all_games");
                case "genreNames": return Language.t("settings_screen_genre_names");
                case "genres": return Language.t("settings_screen_genre_games");
                case "developerNames": return Language.t("settings_screen_developer_names");
                case "developers": return Language.t("settings_screen_developer_games");
                case "publisherNames": return Language.t("settings_screen_publisher_names");
                case "publishers": return Language.t("settings_screen_publisher_games");
                case "yearDecades": return Language.t("settings_screen_year_decades");
                case "yearNumbers": return Language.t("settings_screen_year_numbers");
                case "years": return Language.t("settings_screen_year_games");
                case "tagNames": return Language.t("settings_screen_tag_names");
                case "tags": return Language.t("settings_screen_tag_games");
                case "regionNames": return Language.t("settings_screen_region_names");
                case "regions": return Language.t("settings_screen_region_games");
                case "memories": return Language.t("settings_screen_memories_menu");
                case "recent": return Language.t("settings_screen_recent_games");
                case "favorites": return Language.t("settings_screen_favorites_games");
                case "longplays": return Language.t("settings_screen_longplays_games");
                case "gallery": return Language.t("settings_screen_gallery");
                default: return key;
            }
        }
        return Enums.screenName(key);
    }

    function artLabel(item) {
        if (item.key === "__reset__")
            return SettingsManager.resetButtonLabel();
        return Language.t(item.labelKey);
    }

    function fontPreviewSizeFor(key) {
        var s = SettingsManager.getScreenFontScale(key);
        return Math.max(10, Math.min(40, 22 * s));
    }

    function artPreviewSizeFor(key) {
        var s = SettingsManager.getArtScale(key);
        return Math.max(10, Math.min(40, 20 * s));
    }

    function stepScreenFont(key, delta) {
        var current = SettingsManager.getScreenFontScale(key);
        var next = current + delta * root.scaleStep;
        next = Math.min(root.scaleFontTo, Math.max(root.scaleFontFrom, next));
        next = Math.round(next * 100) / 100;
        SettingsManager.setScreenFontScale(key, next);
    }

    function stepArt(key, delta) {
        var current = SettingsManager.getArtScale(key);
        var next = current + delta * root.scaleStep;
        next = Math.min(root.scaleArtTo, Math.max(root.scaleArtFrom, next));
        next = Math.round(next * 100) / 100;
        SettingsManager.setArtScale(key, next);
    }

    function tryAdjust(dir) {
        if (root.currentView === "main") {
            var item = root.settingsModel[root.currentIndex];
            if (item && (item.type === "slider" || item.type === "choice")) {
                SoundEngine.scroll();
                root.stepCurrent(dir);
            } else {
                SoundEngine.back();
            }
        } else if (root.currentView === "screenFonts") {
            var it = root.screenFontModel[root.screenFontIndex];
            if (it && !it.isReset) {
                SoundEngine.scroll();
                root.stepScreenFont(it.key, dir);
            } else {
                SoundEngine.back();
            }
        } else if (root.currentView === "artSizes") {
            var ia = root.artModel[root.artIndex];
            if (ia && !ia.isReset) {
                SoundEngine.scroll();
                root.stepArt(ia.key, dir);
            } else {
                SoundEngine.back();
            }
        } else if (root.currentView === "topbar") {
            var tbi = root.topbarModel[root.topbarIndex];
            if (!root.topbarItemEnabled(root.topbarIndex)) {
                SoundEngine.back();
            } else if (tbi && (tbi.type === "slider" || tbi.type === "choice")) {
                SoundEngine.scroll();
                root.stepTopbarCurrent(dir);
            } else {
                SoundEngine.back();
            }
        } else if (root.currentView === "effects") {
            var fxItem = root.effectsModel[root.effectsIndex];
            if (fxItem && fxItem.type !== "submenu") {
                SoundEngine.scroll();
                var idx = fxItem.choices.indexOf(SettingsManager[fxItem.key]);
                idx = (idx + dir + fxItem.choices.length) % fxItem.choices.length;
                SettingsManager[fxItem.key] = fxItem.choices[idx];
                SettingsManager.save();
            } else {
                SoundEngine.back();
            }
        } else if (root.currentView === "backgroundEffect") {
            SoundEngine.back();
        } else if (root.currentView === "toolsVisibility") {
            SoundEngine.back();
        }
    }

    function toggleCurrent() {
        var item = root.settingsModel[root.currentIndex];
        if (!item) return;

        if (item.type === "action") {
            if (!root.mainItemEnabled(root.currentIndex)) return;
            if (item.key === "createCustomTheme") {
                themeEditor.open();
            } else if (item.key === "editCustomTheme") {
                var editName = SettingsManager.colorTheme;
                if (SettingsManager.isCustomTheme(editName))
                    themeEditor.open(editName);
            } else if (item.key === "deleteCustomTheme") {
                var cur = SettingsManager.colorTheme;
                if (!SettingsManager.isCustomTheme(cur)) {
                    root.deleteArmed = false;
                } else if (!root.deleteArmed) {
                    root.deleteArmed = true;
                } else {
                    root.deleteArmed = false;
                    SettingsManager.deleteCustomTheme(cur);
                }
            } else if (item.key === "clearGalleryCache") {
                if (!root.cacheClearArmed) {
                    root.cacheClearArmed = true;
                } else {
                    root.cacheClearArmed = false;
                    GalleryCacheEngine.resetAll();
                    console.log("[Settings] Gallery cache cleared.");
                }
            }
            return;
        }

        if (item.type === "boolean") {
            SettingsManager[item.key] = !SettingsManager[item.key];
            SettingsManager.save();
        } else if (item.type === "choice") {
            if (item.key === "colorTheme") {
                var themeList = SettingsManager.allThemeNames;
                var cidx = themeList.indexOf(SettingsManager.colorTheme);
                cidx = (cidx + 1) % themeList.length;
                SettingsManager.colorTheme = themeList[cidx];
                SettingsManager.save();
            } else if (item.key === "language") {
                var lidx = item.choices.indexOf(Language.currentLanguage);
                lidx = (lidx + 1) % item.choices.length;
                Language.setLanguage(item.choices[lidx]);
            } else if (item.key === "splashStyle") {
                var sidx = item.choices.indexOf(SettingsManager.splashStyle);
                sidx = (sidx + 1) % item.choices.length;
                SettingsManager.splashStyle = item.choices[sidx];
                SettingsManager.save();
            } else if (item.key === "buttonStyle") {
                var bidx = item.choices.indexOf(SettingsManager.buttonStyle);
                bidx = (bidx + 1) % item.choices.length;
                SettingsManager.buttonStyle = item.choices[bidx];
                SettingsManager.save();
            } else if (item.key === "fontFamily") {
                var fidx = item.choices.indexOf(SettingsManager.fontChoice);
                fidx = (fidx + 1) % item.choices.length;
                SettingsManager.setFontFamily(item.choices[fidx]);
            } else if (item.key === "artPreferenceGameLists") {
                var aidx = item.choices.indexOf(SettingsManager.artPreferenceGameLists);
                aidx = (aidx + 1) % item.choices.length;
                SettingsManager.artPreferenceGameLists = item.choices[aidx];
                SettingsManager.save();
            } else if (item.key === "artPreferenceGameDetails") {
                var adidx = item.choices.indexOf(SettingsManager.artPreferenceGameDetails);
                adidx = (adidx + 1) % item.choices.length;
                SettingsManager.artPreferenceGameDetails = item.choices[adidx];
                SettingsManager.save();
            }
        }
    }

    function stepCurrent(delta) {
        var item = root.settingsModel[root.currentIndex];
        if (!item) return;

        if (item.type === "slider") {
            if (item.key === "fontSize") {
                var cur = SettingsManager.currentFontScale;
                var next = cur + delta * item.step;
                next = Math.min(item.to, Math.max(item.from, next));
                next = Math.round(next * 100) / 100;
                SettingsManager.setFontScaleForCurrent(next);
            } else if (item.key === "galleryVideoVolume") {
                var curV = SettingsManager.galleryVideoVolume;
                var nextV = curV + delta * item.step;
                nextV = Math.min(item.to, Math.max(item.from, nextV));
                nextV = Math.round(nextV * 100) / 100;
                SettingsManager.galleryVideoVolume = nextV;
                SettingsManager.save();
            }
        } else if (item.type === "choice") {
            if (item.key === "colorTheme") {
                var themeList = SettingsManager.allThemeNames;
                var cidx = themeList.indexOf(SettingsManager.colorTheme);
                cidx = (cidx + delta + themeList.length) % themeList.length;
                SettingsManager.colorTheme = themeList[cidx];
                SettingsManager.save();
            } else if (item.key === "language") {
                var lidx = item.choices.indexOf(Language.currentLanguage);
                lidx = (lidx + delta + item.choices.length) % item.choices.length;
                Language.setLanguage(item.choices[lidx]);
            } else if (item.key === "splashStyle") {
                var sidx = item.choices.indexOf(SettingsManager.splashStyle);
                sidx = (sidx + delta + item.choices.length) % item.choices.length;
                SettingsManager.splashStyle = item.choices[sidx];
                SettingsManager.save();
            } else if (item.key === "buttonStyle") {
                var bidx = item.choices.indexOf(SettingsManager.buttonStyle);
                bidx = (bidx + delta + item.choices.length) % item.choices.length;
                SettingsManager.buttonStyle = item.choices[bidx];
                SettingsManager.save();
            } else if (item.key === "fontFamily") {
                var fidx = item.choices.indexOf(SettingsManager.fontChoice);
                fidx = (fidx + delta + item.choices.length) % item.choices.length;
                SettingsManager.setFontFamily(item.choices[fidx]);
            } else if (item.key === "artPreferenceGameLists") {
                var aidx = item.choices.indexOf(SettingsManager.artPreferenceGameLists);
                aidx = (aidx + delta + item.choices.length) % item.choices.length;
                SettingsManager.artPreferenceGameLists = item.choices[aidx];
                SettingsManager.save();
            } else if (item.key === "artPreferenceGameDetails") {
                var adidx = item.choices.indexOf(SettingsManager.artPreferenceGameDetails);
                adidx = (adidx + delta + item.choices.length) % item.choices.length;
                SettingsManager.artPreferenceGameDetails = item.choices[adidx];
                SettingsManager.save();
            }
        }
    }

    function toggleTopbarCurrent() {
        var item = root.topbarModel[root.topbarIndex];
        if (!item) return;

        if (item.type === "boolean") {
            SettingsManager[item.key] = !SettingsManager[item.key];
            SettingsManager.save();
        } else if (item.type === "choice") {
            var idx = item.choices.indexOf(SettingsManager[item.key]);
            idx = (idx + 1) % item.choices.length;
            SettingsManager[item.key] = item.choices[idx];
            SettingsManager.save();
        }
    }

    function stepTopbarCurrent(delta) {
        var item = root.topbarModel[root.topbarIndex];
        if (!item) return;

        if (item.type === "slider") {
            var cur = SettingsManager[item.key];
            var next = cur + delta * item.step;
            next = Math.min(item.to, Math.max(item.from, next));
            next = Math.round(next * 100) / 100;
            SettingsManager[item.key] = next;
            SettingsManager.save();
        } else if (item.type === "choice") {
            var idx = item.choices.indexOf(SettingsManager[item.key]);
            idx = (idx + delta + item.choices.length) % item.choices.length;
            SettingsManager[item.key] = item.choices[idx];
            SettingsManager.save();
        }
    }

    Component.onCompleted: {
        root.forceActiveFocus();
    }

    readonly property var colors: SettingsManager.getCurrentColors()

    Rectangle { anchors.fill: parent; color: colors.bg; opacity: EffectsManager.particlesEnabled ? 0.5 : 1.0 }

    Column {
        anchors.fill: parent
        anchors.margins: PocketMetrics.margin * 2
        spacing: PocketMetrics.spacing

        Text {
            text: {
                if (root.currentView === "screenFonts") return Language.t("settings_screen_sizes_label");
                if (root.currentView === "artSizes") return Language.t("settings_art_sizes_label");
                if (root.currentView === "topbar") return Language.t("settings_topbar_label");
                if (root.currentView === "effects") return Language.t("settings_effects_label");
                if (root.currentView === "backgroundEffect") return Language.t("settings_effects_background_effect");
                if (root.currentView === "toolsVisibility") return Language.t("settings_tools_label");
                return Language.t("settings_title");
            }
            color: colors.fg
            font.pixelSize: PocketMetrics.titleSize * 1.2
            font.bold: true
            font.family: SettingsManager.fontFamily
        }

        Item {
            id: listContainer
            width: parent.width
            height: parent.height - y

            ListView {
                id: settingsView
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width - root.scrollBarWidth - root.scrollBarMargin
                clip: true
                model: root.settingsModel
                visible: root.currentView === "main"
                currentIndex: root.currentIndex
                highlightMoveDuration: 120

                readonly property int visibleRows: Math.max(1, Math.floor(height / root.rowHeight))
                readonly property real scrollFraction: count > visibleRows ? currentIndex / (count - 1) : 0

                delegate: Item {
                    width: settingsView.width
                    height: root.dynamicDescriptionKey(modelData) !== "" ? Math.round(root.rowHeight * 1.8) : root.rowHeight

                    readonly property bool itemEnabled: root.mainItemEnabled(index)

                    Rectangle {
                        anchors.fill: parent
                        radius: EffectsManager.r(6)
                        color: colors.accent
                        opacity: (index === settingsView.currentIndex && parent.itemEnabled) ? 0.16 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Rectangle {
                        width: 4; radius: EffectsManager.r(2); color: colors.accent
                        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                        anchors.margins: 6
                        opacity: (index === settingsView.currentIndex && parent.itemEnabled) ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: rightText.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        readonly property string labelText: root.itemLabel(modelData)
                        readonly property bool labelHasGlyph: labelText.indexOf("{") >= 0

                        Text {
                            visible: !parent.labelHasGlyph
                            text: parent.labelText
                            color: parent.parent.itemEnabled ? colors.fg : colors.muted
                            opacity: parent.parent.itemEnabled ? 1.0 : 0.4
                            font.pixelSize: PocketMetrics.bodySize
                            font.bold: true
                            font.family: SettingsManager.fontFamily
                            width: parent.width
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                        }

                        InlineGlyphText {
                            visible: parent.labelHasGlyph
                            text: parent.labelText
                            color: parent.parent.itemEnabled ? colors.fg : colors.muted
                            opacity: parent.parent.itemEnabled ? 1.0 : 0.4
                            textSize: PocketMetrics.bodySize
                            bold: true
                            maxWidth: parent.width
                        }

                        Text {
                            visible: root.dynamicDescriptionKey(modelData) !== ""
                            text: Language.t(root.dynamicDescriptionKey(modelData))
                            color: root.dynamicDescriptionKey(modelData) === "settings_home_cards_overflow"
                            ? colors.accent
                            : colors.muted
                            font.bold: root.dynamicDescriptionKey(modelData) === "settings_home_cards_overflow"
                            opacity: parent.parent.itemEnabled ? 0.9 : 0.3
                            font.pixelSize: PocketMetrics.bodySize * 0.75
                            font.family: SettingsManager.fontFamily
                            width: parent.width
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        id: rightText
                        text: modelData.type === "submenu" ? "›" : root.displayValue(modelData)
                        color: parent.itemEnabled ? colors.accent : colors.muted
                        opacity: parent.itemEnabled ? 1.0 : 0.4
                        font.pixelSize: PocketMetrics.bodySize
                        font.bold: true
                        font.family: SettingsManager.fontFamily
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }
                }
            }

            ScrollIndicator {
                listView: settingsView
                visibleRows: settingsView.visibleRows
                scrollFraction: settingsView.scrollFraction
                totalCount: settingsView.count
                trackColor: colors.card
                thumbColor: colors.accent
                barWidth: root.scrollBarWidth
            }

            ListView {
                id: screenFontView
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width - root.scrollBarWidth - root.scrollBarMargin
                clip: true
                model: root.screenFontModel
                visible: root.currentView === "screenFonts"
                currentIndex: root.screenFontIndex
                highlightMoveDuration: 120

                readonly property int visibleRows: Math.max(1, Math.floor(height / root.rowHeight))
                readonly property real scrollFraction: count > visibleRows ? currentIndex / (count - 1) : 0

                delegate: Item {
                    width: screenFontView.width
                    height: root.rowHeight

                    Rectangle {
                        anchors.fill: parent; radius: EffectsManager.r(6); color: colors.accent
                        opacity: index === screenFontView.currentIndex ? 0.16 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Rectangle {
                        width: 4; radius: EffectsManager.r(2); color: colors.accent
                        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                        anchors.margins: 6
                        opacity: index === screenFontView.currentIndex ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Text {
                        text: root.screenFontLabel(modelData.key)
                        color: modelData.isReset ? colors.border : colors.fg
                        font.pixelSize: PocketMetrics.bodySize
                        font.bold: true
                        font.family: SettingsManager.fontFamily
                        font.italic: modelData.isReset === true
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * 0.55
                        elide: Text.ElideRight
                    }

                    Row {
                        visible: !modelData.isReset
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Text {
                            text: "Aa"
                            color: colors.accent
                            opacity: 0.65
                            font.pixelSize: root.fontPreviewSizeFor(modelData.key)
                            font.family: SettingsManager.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on font.pixelSize { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                        }

                        Text {
                            text: root.formatScale(SettingsManager.getScreenFontScale(modelData.key))
                            color: colors.accent
                            font.pixelSize: PocketMetrics.bodySize
                            font.bold: true
                            font.family: SettingsManager.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            ScrollIndicator {
                listView: screenFontView
                visibleRows: screenFontView.visibleRows
                scrollFraction: screenFontView.scrollFraction
                totalCount: screenFontView.count
                trackColor: colors.card
                thumbColor: colors.accent
                barWidth: root.scrollBarWidth
            }

            ListView {
                id: artView
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width - root.scrollBarWidth - root.scrollBarMargin
                clip: true
                model: root.artModel
                visible: root.currentView === "artSizes"
                currentIndex: root.artIndex
                highlightMoveDuration: 120

                readonly property int visibleRows: Math.max(1, Math.floor(height / root.rowHeight))
                readonly property real scrollFraction: count > visibleRows ? currentIndex / (count - 1) : 0

                delegate: Item {
                    width: artView.width
                    height: root.rowHeight

                    Rectangle {
                        anchors.fill: parent; radius: EffectsManager.r(6); color: colors.accent
                        opacity: index === artView.currentIndex ? 0.16 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Rectangle {
                        width: 4; radius: EffectsManager.r(2); color: colors.accent
                        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                        anchors.margins: 6
                        opacity: index === artView.currentIndex ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Text {
                        text: root.artLabel(modelData)
                        color: modelData.isReset ? colors.border : colors.fg
                        font.pixelSize: PocketMetrics.bodySize
                        font.bold: true
                        font.family: SettingsManager.fontFamily
                        font.italic: modelData.isReset === true
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * 0.55
                        elide: Text.ElideRight
                    }

                    Row {
                        visible: !modelData.isReset
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Rectangle {
                            width: root.artPreviewSizeFor(modelData.key)
                            height: width
                            radius: EffectsManager.r(3)
                            color: colors.accent
                            opacity: 0.65
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                        }

                        Text {
                            text: root.formatScale(SettingsManager.getArtScale(modelData.key))
                            color: colors.accent
                            font.pixelSize: PocketMetrics.bodySize
                            font.bold: true
                            font.family: SettingsManager.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            ScrollIndicator {
                listView: artView
                visibleRows: artView.visibleRows
                scrollFraction: artView.scrollFraction
                totalCount: artView.count
                trackColor: colors.card
                thumbColor: colors.accent
                barWidth: root.scrollBarWidth
            }

            ListView {
                id: topbarView
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width - root.scrollBarWidth - root.scrollBarMargin
                clip: true
                model: root.topbarModel
                visible: root.currentView === "topbar"
                currentIndex: root.topbarIndex
                highlightMoveDuration: 120

                readonly property int visibleRows: Math.max(1, Math.floor(height / root.rowHeight))
                readonly property real scrollFraction: count > visibleRows ? currentIndex / (count - 1) : 0

                delegate: Item {
                    width: topbarView.width
                    height: root.rowHeight

                    readonly property bool itemEnabled: root.topbarItemEnabled(index)

                    Rectangle {
                        anchors.fill: parent; radius: EffectsManager.r(6); color: colors.accent
                        opacity: (index === topbarView.currentIndex && parent.itemEnabled) ? 0.16 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Rectangle {
                        width: 4; radius: EffectsManager.r(2); color: colors.accent
                        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                        anchors.margins: 6
                        opacity: (index === topbarView.currentIndex && parent.itemEnabled) ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Text {
                        text: Language.t(modelData.labelKey)
                        color: parent.itemEnabled ? colors.fg : colors.muted
                        opacity: parent.itemEnabled ? 1.0 : 0.4
                        font.pixelSize: PocketMetrics.bodySize
                        font.bold: true
                        font.family: SettingsManager.fontFamily
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * 0.6

                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Text {
                        text: root.displayTopbarValue(modelData)
                        color: parent.itemEnabled ? colors.accent : colors.muted
                        opacity: parent.itemEnabled ? 1.0 : 0.4
                        font.pixelSize: PocketMetrics.bodySize
                        font.bold: true
                        font.family: SettingsManager.fontFamily
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }
                }
            }

            ScrollIndicator {
                listView: topbarView
                visibleRows: topbarView.visibleRows
                scrollFraction: topbarView.scrollFraction
                totalCount: topbarView.count
                trackColor: colors.card
                thumbColor: colors.accent
                barWidth: root.scrollBarWidth
            }

            ListView {
                id: effectsView
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width - root.scrollBarWidth - root.scrollBarMargin
                clip: true
                model: root.effectsModel
                visible: root.currentView === "effects"
                currentIndex: root.effectsIndex
                highlightMoveDuration: 120

                readonly property int visibleRows: Math.max(1, Math.floor(height / root.rowHeight))
                readonly property real scrollFraction: count > visibleRows ? currentIndex / (count - 1) : 0

                delegate: Item {
                    width: effectsView.width
                    height: root.rowHeight

                    Rectangle {
                        anchors.fill: parent; radius: EffectsManager.r(6); color: colors.accent
                        opacity: index === effectsView.currentIndex ? 0.16 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Rectangle {
                        width: 4; radius: EffectsManager.r(2); color: colors.accent
                        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                        anchors.margins: 6
                        opacity: index === effectsView.currentIndex ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Text {
                        text: Language.t(modelData.labelKey)
                        color: colors.fg
                        font.pixelSize: PocketMetrics.bodySize
                        font.bold: true
                        font.family: SettingsManager.fontFamily
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * 0.6
                    }

                    Text {
                        text: {
                            var v = root.displayEffectsValue(modelData);
                            return (modelData.type === "submenu" && v !== "") ? (v + "  ›") : v;
                        }
                        color: colors.accent
                        font.pixelSize: PocketMetrics.bodySize
                        font.bold: true
                        font.family: SettingsManager.fontFamily
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            ScrollIndicator {
                listView: effectsView
                visibleRows: effectsView.visibleRows
                scrollFraction: effectsView.scrollFraction
                totalCount: effectsView.count
                trackColor: colors.card
                thumbColor: colors.accent
                barWidth: root.scrollBarWidth
            }

            Loader {
                id: backgroundEffectLoader
                anchors.fill: parent
                active: root.currentView === "backgroundEffect"
                sourceComponent: Component {
                    Item {
                        anchors.fill: parent

                        ListView {
                            id: backgroundEffectView
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width - root.scrollBarWidth - root.scrollBarMargin
                            clip: true
                            model: root.backgroundEffectModel
                            currentIndex: root.backgroundEffectIndex

                            highlightMoveDuration: _animateMoves ? 120 : 0
                            property bool _animateMoves: false

                            Component.onCompleted: {
                                positionViewAtIndex(currentIndex, ListView.Center);
                                Qt.callLater(function() { _animateMoves = true; });
                            }

                            readonly property int visibleRows: Math.max(1, Math.floor(height / root.rowHeight))
                            readonly property real scrollFraction: count > visibleRows ? currentIndex / (count - 1) : 0

                            delegate: Item {
                                width: backgroundEffectView.width
                                height: root.rowHeight

                                readonly property bool isCurrent: SettingsManager.fxBackgroundEffect === modelData

                                Rectangle {
                                    anchors.fill: parent; radius: EffectsManager.r(6); color: colors.accent
                                    opacity: index === backgroundEffectView.currentIndex ? 0.16 : 0
                                    Behavior on opacity { NumberAnimation { duration: 120 } }
                                }

                                Rectangle {
                                    width: 4; radius: EffectsManager.r(2); color: colors.accent
                                    anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                                    anchors.margins: 6
                                    opacity: index === backgroundEffectView.currentIndex ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 120 } }
                                }

                                Text {
                                    id: labelText
                                    text: root.backgroundEffectLabel(modelData)
                                    color: parent.isCurrent ? colors.accent : colors.fg
                                    font.pixelSize: PocketMetrics.bodySize
                                    font.bold: parent.isCurrent
                                    font.family: SettingsManager.fontFamily
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.right: checkMark.left
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                }

                                Text {
                                    id: checkMark
                                    text: "✓"
                                    color: colors.accent
                                    font.pixelSize: PocketMetrics.bodySize
                                    font.bold: true
                                    font.family: SettingsManager.fontFamily
                                    anchors.right: parent.right
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: parent.isCurrent
                                }
                            }
                        }

                        ScrollIndicator {
                            listView: backgroundEffectView
                            visibleRows: backgroundEffectView.visibleRows
                            scrollFraction: backgroundEffectView.scrollFraction
                            totalCount: backgroundEffectView.count
                            trackColor: colors.card
                            thumbColor: colors.accent
                            barWidth: root.scrollBarWidth
                        }
                    }
                }
            }

            ListView {
                id: toolsView
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width - root.scrollBarWidth - root.scrollBarMargin
                clip: true
                model: root.toolsModel
                visible: root.currentView === "toolsVisibility"
                currentIndex: root.toolsIndex
                highlightMoveDuration: 120

                readonly property int visibleRows: Math.max(1, Math.floor(height / root.rowHeight))
                readonly property real scrollFraction: count > visibleRows ? currentIndex / (count - 1) : 0

                delegate: Item {
                    width: toolsView.width
                    height: root.rowHeight

                    Rectangle {
                        anchors.fill: parent; radius: EffectsManager.r(6); color: colors.accent
                        opacity: index === toolsView.currentIndex ? 0.16 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Rectangle {
                        width: 4; radius: EffectsManager.r(2); color: colors.accent
                        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                        anchors.margins: 6
                        opacity: index === toolsView.currentIndex ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Text {
                        text: Language.t(modelData.labelKey)
                        color: colors.fg
                        font.pixelSize: PocketMetrics.bodySize
                        font.bold: true
                        font.family: SettingsManager.fontFamily
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * 0.6
                    }

                    Text {
                        text: SettingsManager[modelData.key] ? Language.t("settings_on") : Language.t("settings_off")
                        color: colors.accent
                        font.pixelSize: PocketMetrics.bodySize
                        font.bold: true
                        font.family: SettingsManager.fontFamily
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            ScrollIndicator {
                listView: toolsView
                visibleRows: toolsView.visibleRows
                scrollFraction: toolsView.scrollFraction
                totalCount: toolsView.count
                trackColor: colors.card
                thumbColor: colors.accent
                barWidth: root.scrollBarWidth
            }
        }
    }

    Keys.onDownPressed: {
        SoundEngine.scroll();
        if (root.currentView === "main")
            root.currentIndex = root.mainNextEnabled(root.currentIndex, 1);
        else if (root.currentView === "screenFonts")
            root.screenFontIndex = Math.min(root.screenFontModel.length - 1, root.screenFontIndex + 1);
        else if (root.currentView === "artSizes")
            root.artIndex = Math.min(root.artModel.length - 1, root.artIndex + 1);
        else if (root.currentView === "topbar")
            root.topbarIndex = root.topbarNextEnabled(root.topbarIndex, 1);
        else if (root.currentView === "effects")
            root.effectsIndex = Math.min(root.effectsModel.length - 1, root.effectsIndex + 1);
        else if (root.currentView === "backgroundEffect")
            root.backgroundEffectIndex = Math.min(root.backgroundEffectModel.length - 1, root.backgroundEffectIndex + 1);
        else if (root.currentView === "toolsVisibility")
            root.toolsIndex = Math.min(root.toolsModel.length - 1, root.toolsIndex + 1);
    }

    Keys.onUpPressed: {
        SoundEngine.scroll();
        if (root.currentView === "main")
            root.currentIndex = root.mainNextEnabled(root.currentIndex, -1);
        else if (root.currentView === "screenFonts")
            root.screenFontIndex = Math.max(0, root.screenFontIndex - 1);
        else if (root.currentView === "artSizes")
            root.artIndex = Math.max(0, root.artIndex - 1);
        else if (root.currentView === "topbar")
            root.topbarIndex = root.topbarNextEnabled(root.topbarIndex, -1);
        else if (root.currentView === "effects")
            root.effectsIndex = Math.max(0, root.effectsIndex - 1);
        else if (root.currentView === "backgroundEffect")
            root.backgroundEffectIndex = Math.max(0, root.backgroundEffectIndex - 1);
        else if (root.currentView === "toolsVisibility")
            root.toolsIndex = Math.max(0, root.toolsIndex - 1);
    }

    Keys.onLeftPressed: root.tryAdjust(-1)
    Keys.onRightPressed: root.tryAdjust(1)

    Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            if (root.currentView === "main") {
                event.accepted = true;
                var item = root.settingsModel[root.currentIndex];
                if (!item) return;
                if (item.type === "submenu") {
                    SoundEngine.select();
                    root.currentView = item.target;
                    return;
                }
                if (item.type !== "slider") {
                    root.toggleCurrent();
                    SoundEngine.select();
                }
                return;
            }
            if (root.currentView === "screenFonts") {
                var it = root.screenFontModel[root.screenFontIndex];
                if (it && it.isReset) {
                    event.accepted = true;
                    SettingsManager.resetActiveContextToDefault();
                    SoundEngine.select();
                }
                return;
            }
            if (root.currentView === "artSizes") {
                var ia = root.artModel[root.artIndex];
                if (ia && ia.isReset) {
                    event.accepted = true;
                    SettingsManager.resetActiveContextToDefault();
                    SoundEngine.select();
                }
                return;
            }
            if (root.currentView === "topbar") {
                event.accepted = true;
                if (!root.topbarItemEnabled(root.topbarIndex)) return;
                var tbi = root.topbarModel[root.topbarIndex];
                if (tbi && (tbi.type === "boolean" || tbi.type === "choice")) {
                    root.toggleTopbarCurrent();
                    SoundEngine.select();
                }
                return;
            }
            if (root.currentView === "effects") {
                event.accepted = true;
                var fxItem = root.effectsModel[root.effectsIndex];
                if (!fxItem) return;

                if (fxItem.type === "submenu") {
                    SoundEngine.select();
                    if (fxItem.target === "backgroundEffect") {
                        var curIdx = root.backgroundEffectModel.indexOf(SettingsManager.fxBackgroundEffect);
                        root.backgroundEffectIndex = curIdx >= 0 ? curIdx : 0;
                    }
                    root.currentView = fxItem.target;
                    return;
                }

                var idx = fxItem.choices.indexOf(SettingsManager[fxItem.key]);
                idx = (idx + 1) % fxItem.choices.length;
                SettingsManager[fxItem.key] = fxItem.choices[idx];
                SettingsManager.save();
                SoundEngine.select();
                return;
            }
            if (root.currentView === "backgroundEffect") {
                event.accepted = true;
                var value = root.backgroundEffectModel[root.backgroundEffectIndex];
                if (value !== undefined) {
                    SettingsManager.fxBackgroundEffect = value;
                    SettingsManager.save();
                    SoundEngine.select();
                }
                return;
            }
            if (root.currentView === "toolsVisibility") {
                event.accepted = true;
                var tbi2 = root.toolsModel[root.toolsIndex];
                if (tbi2 && tbi2.type === "boolean") {
                    SettingsManager[tbi2.key] = !SettingsManager[tbi2.key];
                    SettingsManager.save();
                    SoundEngine.select();
                }
                return;
            }
            return;
        }

        if (api.keys.isCancel(event)) {
            event.accepted = true;
            if (event.isAutoRepeat) return;
            if (root.currentView === "backgroundEffect") {
                root.currentView = "effects";
                SoundEngine.back();
                return;
            }
            if (root.currentView !== "main") {
                root.currentView = "main";
                SoundEngine.back();
                return;
            }
            NavigationManager.goBack();
        }
    }
}
