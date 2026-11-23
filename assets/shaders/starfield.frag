// Aethon
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
#ifdef GL_ES
precision mediump float;
#endif

varying highp vec2 qt_TexCoord0;

uniform lowp float qt_Opacity;
uniform highp float uTime;
uniform highp vec2 uResolution;
uniform lowp vec4 uStarColor;

uniform highp float uHeadSize;
uniform lowp float uHeadBrightness;
uniform highp float uTrailLength;
uniform highp float uDensity;

uniform lowp float uCenterAlpha;
uniform lowp float uEdgeAlpha;
uniform lowp float uCenterWidth;
uniform lowp float uCenterHole;

highp vec2 hash22(highp vec2 p) {
    highp vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

lowp float starLayer(highp vec2 uv, highp float z, highp float seedOffset) {
    highp float gridScale = 8.5 * max(uDensity, 0.2);
    highp vec2 p = uv * (z * gridScale) + seedOffset;
    highp vec2 baseCell = floor(p);
    highp vec2 baseFrac = fract(p) - 0.5;

    lowp float layerLight = 0.0;

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            highp vec2 neighbor = vec2(float(x), float(y));
            highp vec2 cellId = baseCell + neighbor;

            highp vec2 rnd = hash22(cellId) - 0.5;
            highp vec2 starPos = (neighbor + rnd * 0.65) - baseFrac;

            highp vec2 dir = normalize(uv + vec2(0.0001));
            highp float alongRay = dot(starPos, dir);
            highp float perpRay = length(starPos - dir * alongRay);

            highp float tailLen = min(uTrailLength * (1.0 - z) * 0.95, 1.18);

            highp float clampedAlong = clamp(alongRay, 0.0, tailLen);
            highp float distToLine = length(vec2(alongRay - clampedAlong, perpRay));

            highp float tailFade = 1.0;
            if (tailLen > 0.001) {
                tailFade = clamp(1.0 - (clampedAlong / tailLen), 0.0, 1.0);
                tailFade = pow(tailFade, 1.6);
            }

            highp float baseSize = (0.018 + fract(rnd.x * 17.3) * 0.018) * max(uHeadSize, 0.1);

            lowp float streak = 0.0;
            if (uTrailLength > 0.01) {
                streak = smoothstep(baseSize * (0.35 + 0.65 * tailFade), 0.0, distToLine) * tailFade;
            }

            highp float distToHead = length(starPos);
            lowp float head = smoothstep(baseSize * 1.15, baseSize * 0.1, distToHead) * uHeadBrightness;

            lowp float halo = smoothstep(baseSize * 2.8, 0.0, distToHead) * (0.09 * uHeadBrightness);

            layerLight += streak + head + halo;
        }
    }

    return layerLight;
}

void main() {
    highp float aspect = uResolution.x / max(uResolution.y, 1.0);
    highp vec2 uv = vec2((qt_TexCoord0.x - 0.5) * aspect, qt_TexCoord0.y - 0.5);

    lowp float totalLight = 0.0;

    highp float z1 = fract(1.0 - uTime * 0.18);
    lowp float fade1 = smoothstep(1.0, 0.75, z1) * smoothstep(0.0, 0.18, z1);
    totalLight += starLayer(uv, z1, 12.4) * fade1 * 0.60;

    highp float z2 = fract(1.33 - uTime * 0.18);
    lowp float fade2 = smoothstep(1.0, 0.75, z2) * smoothstep(0.0, 0.18, z2);
    totalLight += starLayer(uv, z2, 47.9) * fade2 * 0.80;

    highp float z3 = fract(1.66 - uTime * 0.18);
    lowp float fade3 = smoothstep(1.0, 0.75, z3) * smoothstep(0.0, 0.18, z3);
    totalLight += starLayer(uv, z3, 83.2) * fade3 * 1.0;

    lowp float hole = max(uCenterHole, 0.01);
    lowp float centerHoleMask = smoothstep(hole * 0.15, hole, length(uv));
    totalLight *= centerHoleMask;

    lowp float distFromCenterX = abs(qt_TexCoord0.x - 0.5) * 2.0;
    lowp float horizontalFade = 1.0 - smoothstep(uCenterWidth * 0.3, min(uCenterWidth + 0.40, 1.0), distFromCenterX);
    lowp float spatialAlpha = mix(uEdgeAlpha, uCenterAlpha, horizontalFade);

    lowp float alpha = clamp(totalLight * spatialAlpha, 0.0, 1.0);

    gl_FragColor = vec4(uStarColor.rgb * alpha, alpha) * qt_Opacity;
}
