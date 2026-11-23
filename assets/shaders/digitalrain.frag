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
uniform lowp vec4 uMatrixColor;
uniform highp float uDensity;

uniform lowp float uCenterAlpha;
uniform lowp float uEdgeAlpha;
uniform lowp float uCenterWidth;

highp float hash(highp vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

lowp float drawGlyph(highp vec2 cellUV, highp float seed) {
    if (cellUV.x < 0.18 || cellUV.x > 0.82 || cellUV.y < 0.12 || cellUV.y > 0.88) {
        return 0.0;
    }

    highp vec2 grid = floor(((cellUV - vec2(0.18, 0.12)) / vec2(0.64, 0.76)) * vec2(4.0, 5.0));
    highp float bit = hash(grid + floor(seed * 16.0));

    return step(0.48, bit);
}

void main() {
    highp vec2 uv = qt_TexCoord0;
    highp float aspect = uResolution.x / max(uResolution.y, 1.0);

    highp vec2 gridScale = vec2(uDensity, (uDensity / aspect) * 0.75);
    highp vec2 st = uv * gridScale;

    highp vec2 colId = vec2(floor(st.x), 0.0);
    highp vec2 cellId = floor(st);
    highp vec2 cellUV = fract(st);

    highp float colSpeed = 0.6 + hash(colId) * 1.1;
    highp float colOffset = hash(colId + 19.3) * 20.0;

    highp float dropPos = fract((uv.y * 1.2) - (uTime * colSpeed * 0.35) + colOffset);

    lowp float trail = pow(dropPos, 3.2);
    lowp float head = smoothstep(0.92, 0.99, dropPos);

    highp float charSeed = hash(cellId + floor(uTime * 1.8 + hash(colId) * 5.0));
    lowp float glyph = drawGlyph(cellUV, charSeed);

    lowp float distFromCenter = abs(uv.x - 0.5) * 2.0;
    lowp float edgeFactor = smoothstep(uCenterWidth * 0.3, min(uCenterWidth + 0.45, 1.0), distFromCenter);

    lowp float dynamicAlpha = mix(uCenterAlpha, uEdgeAlpha, edgeFactor);

    lowp float intensity = glyph * (trail + head * 0.85) * dynamicAlpha;
    lowp vec3 color = mix(uMatrixColor.rgb, vec3(1.0), head * 0.75);

    gl_FragColor = vec4(color * intensity, intensity) * qt_Opacity;
}
