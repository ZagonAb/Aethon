// Aethon
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#endif

varying vec2 qt_TexCoord0;

uniform lowp float qt_Opacity;
uniform float uTime;
uniform vec2 uResolution;

uniform lowp vec4 uColorPrimary;
uniform lowp vec4 uColorSecondary;
uniform mediump float uSize;
uniform float uDensity;
uniform mediump float uBlur;
uniform mediump float uAlpha;

vec3 hash32(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

mediump float swave(mediump float x) {
    mediump float t = abs(fract(x + 0.75) * 2.0 - 1.0);
    return t * t * (3.0 - 2.0 * t) * 2.0 - 1.0;
}
mediump float cwave(mediump float x) {
    mediump float t = abs(fract(x) * 2.0 - 1.0);
    return t * t * (3.0 - 2.0 * t) * 2.0 - 1.0;
}

mediump vec4 bokehLayer(vec2 uv, float scale, vec2 speedVec, float seedOffset,
                        mediump vec3 ph, mediump float blurExp)
{
    vec2 p = uv * scale + speedVec * uTime + seedOffset;
    vec2 baseCell = floor(p);
    mediump vec2 baseFrac = fract(p) - 0.5;

    mediump vec2 side = step(0.0, baseFrac) * 2.0 - 1.0;

    mediump vec3 layerColor = vec3(0.0);
    mediump float layerAlpha = 0.0;

    for (int y = 0; y < 2; y++) {
        for (int x = 0; x < 2; x++) {
            mediump vec2 neighbor = vec2(float(x), float(y)) * side;

            mediump vec3 rnd = hash32(baseCell + neighbor);

            mediump vec2 wobble = vec2(swave(ph.x + rnd.x), cwave(ph.y + rnd.y)) * 0.18;

            mediump vec2 diskPos = neighbor + (rnd.xy - 0.5) * 0.70 + wobble - baseFrac;
            mediump float dist = length(diskPos);

            mediump float radius = clamp((0.35 + rnd.z * 0.35) * uSize, 0.03, 0.90);

            mediump float t = clamp(1.0 - dist / radius, 0.0, 1.0);
            mediump float softBlob = t * t * (3.0 - 2.0 * t);
            softBlob = pow(softBlob, blurExp);

            mediump float breathe = 0.65 + 0.35 * swave(ph.z + rnd.z * 1.90986);
            mediump float intensity = softBlob * breathe * 0.65;

            mediump vec3 col = mix(uColorPrimary.rgb, uColorSecondary.rgb, rnd.z);

            layerColor += col * intensity;
            layerAlpha += intensity;
        }
    }

    return vec4(layerColor, layerAlpha);
}

void main() {
    float aspect = uResolution.x / max(uResolution.y, 1.0);
    vec2 uv = vec2((qt_TexCoord0.x - 0.5) * aspect, qt_TexCoord0.y - 0.5);

    mediump vec3 ph = fract(uTime * vec3(0.0557042, 0.0477465, 0.0875352));
    mediump float blurExp = max(uBlur, 0.5);

    mediump vec4 b1 = bokehLayer(uv, uDensity * 0.85, vec2(0.03, -0.04), 11.2, ph, blurExp) * 0.75;
    mediump vec4 b2 = bokehLayer(uv, uDensity * 1.15, vec2(0.06, -0.08), 43.7, ph, blurExp) * 0.75;
    mediump vec4 b3 = bokehLayer(uv, uDensity * 1.50, vec2(0.09, -0.12), 89.4, ph, blurExp) * 0.60;

    mediump vec3 combinedColor = b1.rgb + b2.rgb + b3.rgb;
    mediump float totalWeight = b1.a + b2.a + b3.a;
    mediump float combinedAlpha = clamp(totalWeight * uAlpha, 0.0, 1.0);

    mediump vec3 finalRGB = combinedColor / max(totalWeight, 0.001);

    gl_FragColor = vec4(finalRGB * combinedAlpha, combinedAlpha) * qt_Opacity;
}
