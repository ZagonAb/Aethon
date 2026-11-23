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
    #define HP highp
    #define HAS_HP
  #else
    precision mediump float;
    #define HP mediump
  #endif
#else
  #define HP
  #define HAS_HP
#endif

varying HP vec2 qt_TexCoord0;
uniform lowp float qt_Opacity;

uniform highp float uPhase;
uniform mediump vec2 uResolution;

uniform mediump vec4 uHexColor;
uniform mediump vec4 uPulseColor;

uniform mediump float uGridBrightness;
uniform mediump float uPulseBrightness;
uniform mediump float uRimBrightness;
uniform mediump float uWave;
uniform mediump float uLineWidth;
uniform mediump float uCellGap;
uniform mediump float uScale;
uniform mediump float uCenterAlpha;
uniform mediump float uEdgeAlpha;

const HP float TAU = 6.2831853;
const HP vec2 HEX_R = vec2(1.0, 1.7320508);
const HP vec2 HEX_H = vec2(0.5, 0.8660254);

HP float hash12(HP vec2 p) {
    HP vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void main() {
    HP vec2 uv = qt_TexCoord0;
    HP float aspect = uResolution.x / max(uResolution.y, 1.0);
    HP vec2 st = vec2((uv.x - 0.5) * aspect, uv.y - 0.5) * uScale;

    HP vec2 a = mod(st, HEX_R) - HEX_H;
    HP vec2 b = mod(st - HEX_H, HEX_R) - HEX_H;
    bool useA = dot(a, a) < dot(b, b);
    HP vec2 gv = useA ? a : b;

    HP vec2 ctr = st - gv;
    HP vec2 id = floor(ctr * vec2(2.0, 1.1547005) + 0.5);

    HP vec2 p = abs(gv);
    HP float e = 0.5 - max(dot(p, HEX_H), p.x);

    HP float aa = uScale / max(uResolution.y, 1.0) * 0.75;

    HP float line = 1.0 - smoothstep(uLineWidth - aa, uLineWidth + aa, e);
    HP float fill = smoothstep(uCellGap - aa, uCellGap + aa, e) * (0.55 + 0.9 * e);

    HP float rnd = hash12(id);
    HP float r4 = rnd * 4.0;
    HP float cycles = 2.0 + floor(r4);
    HP float s = 0.5 + 0.5 * sin(TAU * fract(cycles * uPhase + fract(r4)));
    s *= s;
    HP float pulse = s * s;

    HP float w = 0.5 + 0.5 * sin(TAU * fract(dot(ctr, vec2(0.08, 0.05)) - 3.0 * uPhase));
    HP float wave = w * w * w * uWave;

    mediump float sp = mix(uCenterAlpha, uEdgeAlpha,
                           smoothstep(0.15, 0.95, abs(uv.x - 0.5) * 2.0));

    mediump float gridA  = line * (uGridBrightness + uRimBrightness * pulse) * sp;
    mediump float pulseA = fill * (pulse + wave) * uPulseBrightness * sp;

    mediump float total = gridA + pulseA;
    mediump float k = 1.0 / max(total, 1.0);

    mediump vec4 col = vec4((uHexColor.rgb * gridA + uPulseColor.rgb * pulseA) * k, total * k);

#ifdef HAS_HP
    HP float dn = (fract(52.9829189 * fract(dot(gl_FragCoord.xy, vec2(0.06711056, 0.00583715)))) - 0.5) / 255.0;
    col += dn * step(0.004, col.a);
#endif

    gl_FragColor = col * qt_Opacity;
}
