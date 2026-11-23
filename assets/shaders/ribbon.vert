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

attribute highp vec4 qt_Vertex;
attribute highp vec2 qt_MultiTexCoord0;

uniform highp mat4 qt_Matrix;
uniform highp float uTime;
uniform highp float uThickness;

varying highp vec2 qt_TexCoord0;
varying mediump vec3 vNormal;

highp float xmb_noise2(highp vec3 x, highp float t) {
    return cos(x.z * 4.0) * cos(x.z + t / 10.0 + x.x);
}

highp vec3 displaceSimpleRibbon(highp vec2 uv, highp float t) {
    highp vec2 pos = uv * 2.0 - 1.0;
    highp vec3 v = vec3(pos.x, 0.0, pos.y);
    highp vec3 v2 = v;

    v.y = xmb_noise2(v2, t) / 8.0;
    v.y -= cos(v.x * 2.0 - t / 2.0) / 5.0;

    return v;
}

void main() {
    qt_TexCoord0 = qt_MultiTexCoord0;

    highp float t = uTime * 1.5;
    highp vec3 p = displaceSimpleRibbon(qt_MultiTexCoord0, t);

    highp float eps = 0.01;
    highp vec3 px = displaceSimpleRibbon(qt_MultiTexCoord0 + vec2(eps, 0.0), t);
    highp vec3 py = displaceSimpleRibbon(qt_MultiTexCoord0 + vec2(0.0, eps), t);
    vNormal = normalize(cross(px - p, py - p));

    highp vec4 projPos = qt_Matrix * qt_Vertex;
    projPos.x = projPos.x * 1.15;
    projPos.y = (p.y * 1.25) * uThickness;

    gl_Position = projPos;
}
