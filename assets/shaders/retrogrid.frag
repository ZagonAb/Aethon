// Aethon
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
#ifdef GL_ES
precision highp float;
#endif

varying highp vec2 qt_TexCoord0;

uniform lowp float qt_Opacity;
uniform highp float uTime;
uniform highp vec2 uResolution;

uniform lowp vec4 uGridColor;
uniform lowp vec4 uHorizonColor;
uniform highp float uHorizonY;
uniform highp float uGridScale;
uniform highp float uLineWidth;

uniform lowp float uCenterAlpha;
uniform lowp float uEdgeAlpha;
uniform lowp float uCenterWidth;

void main() {
    highp vec2 uv = qt_TexCoord0;
    highp float aspect = uResolution.x / max(uResolution.y, 1.0);

    highp float dy = uv.y - uHorizonY;

    lowp float horizonGlow = exp(-abs(dy) * 14.0) * 0.85;
    lowp float horizonLine = smoothstep(0.008, 0.0, abs(dy)) * 0.90;

    lowp vec3 finalColor = uHorizonColor.rgb * (horizonGlow + horizonLine);
    lowp float finalAlpha = horizonGlow + horizonLine;

    if (dy > 0.001) {
        highp float z = 1.0 / dy;

        highp vec2 gridUV;
        gridUV.x = (uv.x - 0.5) * aspect * z * uGridScale;
        gridUV.y = (z * uGridScale * 0.45) + (uTime * 1.4);

        highp vec2 cell = abs(fract(gridUV) - 0.5);

        highp float aa = clamp(0.015 * z * 0.35, 0.008, 0.22);
        highp float halfWidth = uLineWidth * 0.5;

        lowp float lineX = smoothstep(0.5 - halfWidth - aa, 0.5 - halfWidth + aa, cell.x);
        lowp float lineY = smoothstep(0.5 - halfWidth - aa, 0.5 - halfWidth + aa, cell.y);
        lowp float gridMask = max(lineX, lineY);

        lowp float distanceFade = smoothstep(0.0, 0.14, dy);
        lowp float bottomFade = smoothstep(1.0, 0.88, uv.y);

        lowp float gridIntensity = gridMask * distanceFade * bottomFade;

        finalColor = mix(finalColor, uGridColor.rgb, gridIntensity);
        finalAlpha = max(finalAlpha, gridIntensity);
    }

    lowp float distFromCenterX = abs(uv.x - 0.5) * 2.0;
    lowp float horizontalFade = 1.0 - smoothstep(uCenterWidth * 0.3, min(uCenterWidth + 0.40, 1.0), distFromCenterX);
    lowp float spatialAlpha = mix(uEdgeAlpha, uCenterAlpha, horizontalFade);

    finalAlpha = clamp(finalAlpha * spatialAlpha, 0.0, 1.0);

    gl_FragColor = vec4(finalColor * finalAlpha, finalAlpha) * qt_Opacity;
}
