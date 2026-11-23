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

    readonly property var _presetEffects: {
        var _ctx = SettingsManager.activeContext;
        if (_ctx === "default") return null;
        var _p = SettingsManager.presets ? SettingsManager.presets[_ctx] : null;
        if (_p && _p.effects) return _p.effects;
        return null;
    }

    readonly property string animationLevel: {
        var u = SettingsManager.fxAnimations;
        if (u === "full" || u === "reduced" || u === "off") return u;
        var pe = root._presetEffects;
        var v = pe ? (pe.animations || "full") : "full";
        if (v !== "full" && v !== "reduced" && v !== "off") v = "full";
        return v;
    }

    readonly property real animScale: {
        switch (root.animationLevel) {
            case "reduced": return 0.5;
            case "off": return 0.0;
            default: return 1.0;
        }
    }

    readonly property bool animationsEnabled: root.animationLevel !== "off"

    function dur(ms) {
        if (!root.animationsEnabled) return 0;
        return Math.round(ms * root.animScale);
    }

    readonly property bool shadowsEnabled: {
        var u = SettingsManager.fxShadows;
        if (u === "on") return true;
        if (u === "off") return false;
        var pe = root._presetEffects;
        if (pe && pe.shadows !== undefined) return pe.shadows === true;
        return true;
    }

    readonly property bool shaderEffectsEnabled: {
        var u = SettingsManager.fxShaderEffects;
        if (u === "on") return true;
        if (u === "off") return false;
        var pe = root._presetEffects;
        if (pe && pe.shaderEffects !== undefined) return pe.shaderEffects === true;
        return true;
    }

    readonly property bool loopingAnimationsEnabled: {
        if (!root.animationsEnabled) return false;
        var pe = root._presetEffects;
        if (pe && pe.loopingAnimations !== undefined) return pe.loopingAnimations === true;
        return true;
    }

    readonly property bool roundedCornersEnabled: {
        var u = SettingsManager.fxRoundedCorners;
        if (u === "on") return true;
        if (u === "off") return false;
        var pe = root._presetEffects;
        if (pe && pe.roundedCorners !== undefined) return pe.roundedCorners === true;
        return true;
    }

    function r(px) {
        return root.roundedCornersEnabled ? px : 0;
    }

    readonly property int scrollPhase: 2887
    readonly property int scrollSettleDelay: {
        var pe = root._presetEffects;
        if (pe && pe.scrollSettleDelay !== undefined) return pe.scrollSettleDelay;
        return 180;
    }

    readonly property int scrollFastThreshold: {
        var pe = root._presetEffects;
        if (pe && pe.scrollFastThreshold !== undefined) return pe.scrollFastThreshold;
        return 200;
    }

    readonly property string marqueeLevel: {
        var u = SettingsManager.fxMarquee;
        if (u === "on") return "on";
        if (u === "off") return "off";
        return root.loopingAnimationsEnabled ? "on" : "off";
    }

    readonly property bool marqueeEnabled: root.marqueeLevel === "on"

    readonly property bool particlesEnabled: {
        if (!root.shaderEffectsEnabled) return false;
        var u = SettingsManager.fxParticles;
        if (u === "on") return true;
        if (u === "off") return false;
        var pe = root._presetEffects;
        if (pe && pe.particles !== undefined) return pe.particles === true;
        return false;
    }

    readonly property bool backgroundAnimated: {
        if (!root.animationsEnabled) return false;
        if (SettingsManager.fxParticles === "on") return true;
        return root.loopingAnimationsEnabled;
    }

    readonly property var bgEffects: ["abyssal", "ribbon", "digitalrain",
    "starfield", "hexgrid", "softbokeh",
    "retrogrid"]

    readonly property string backgroundEffect: {
        var u = SettingsManager.fxBackgroundEffect;
        if (root.bgEffects.indexOf(u) >= 0) return u;
        var pe = root._presetEffects;
        var v = pe ? (pe.backgroundEffect || "abyssal") : "abyssal";
        return (root.bgEffects.indexOf(v) >= 0) ? v : "abyssal";
    }

    readonly property real backgroundAlpha: {
        var v = SettingsManager.fxBackgroundAlpha;
        if (v === "auto") return 1.0;
        var n = parseInt(v, 10);
        if (isNaN(n)) return 1.0;
        return Math.max(0, Math.min(100, n)) / 100.0;
    }
}
