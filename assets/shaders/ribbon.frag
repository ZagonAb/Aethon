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
varying mediump vec3 vNormal;

uniform lowp float qt_Opacity;
uniform lowp vec4 uRibbonColor;
uniform lowp float uIntensity;

void main() {
  mediump vec3 normal = normalize(vNormal);
  mediump float nz = abs(normal.z);

  mediump float c = 1.0 - nz;
  mediump float glow = (1.0 - cos(c * c)) / 3.0;

  lowp float silhouetteAA = smoothstep(0.0, 0.16, nz);

  lowp float verticalAA = smoothstep(0.0, 0.05, qt_TexCoord0.y) * smoothstep(1.0, 0.95, qt_TexCoord0.y);
  lowp float horizontalFade = smoothstep(0.0, 0.14, qt_TexCoord0.x) * smoothstep(1.0, 0.86, qt_TexCoord0.x);

  lowp float alpha = clamp(glow * uIntensity * silhouetteAA * verticalAA * horizontalFade, 0.0, 1.0);

  gl_FragColor = vec4(uRibbonColor.rgb * alpha, alpha) * qt_Opacity;
}
