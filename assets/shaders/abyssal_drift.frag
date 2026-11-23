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
uniform mediump float time;
uniform mediump float aspectRatio;
uniform mediump float density;
uniform mediump float drift;
uniform lowp float intensity;
uniform lowp vec4 particleColor;

uniform mediump float fadeIn;
uniform mediump float fadeOut;
uniform mediump float centerFocus;

float random(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main()
{
    vec2 p = qt_TexCoord0 * vec2(aspectRatio, 1.0);
    vec2 gridPosition = p * density;
    vec2 baseCell = floor(gridPosition);
    float invDensity = 1.0 / density;

    float rowStep = (fract(gridPosition.y) < 0.5) ? -1.0 : 1.0;

    float alpha = 0.0;

    for (int y = 0; y < 2; ++y)
    {
        for (int x = -1; x <= 1; ++x)
        {
            vec2 cell = baseCell + vec2(float(x), float(y) * rowStep);

            float seed = random(cell);
            float seedY = random(cell + 43.17);

            float speed = mix(0.6, 2.8, seed);
            float localY = fract(seedY - time * drift * speed);

            float lifecycle = (1.0 - smoothstep(1.0 - fadeIn, 1.0, localY))
            * smoothstep(0.0, fadeOut, localY);
            if (lifecycle < 0.004) continue;

            float seedX = random(cell + 17.31);
            float seedTilt = random(cell + 7.77);

            float tilt = mix(-0.8, 0.8, seedTilt) * (1.0 - localY);
            float sway = sin(time * mix(2.0, 5.0, seedX) + seedY * 6.28318) * 0.03;

            vec2 particlePosition = vec2(
                cell.x + 0.20 + seedX * 0.60 + tilt + sway,
                cell.y + localY
            ) * invDensity;

            vec2 d = p - particlePosition;
            float d2 = dot(d, d);
            if (d2 > 0.008) continue;

            float seedSize = random(cell + 81.73);
            float seedBrightness = random(cell + 29.51);

            float radius = mix(0.008, 0.020, seedSize);
            float dist = sqrt(d2);

            float core = 1.0 - smoothstep(radius * 0.1, radius * 0.8, dist);
            float halo = exp(-d2 / (radius * radius * 5.0)) * 0.08;
            float brightness = mix(0.3, 1.0, seedBrightness);

            float bottomness = smoothstep(0.0, 0.8, particlePosition.y);
            float leftBound = mix(0.05 * aspectRatio, 0.20 * aspectRatio, bottomness);
            float rightBound = aspectRatio - leftBound;
            float fadeWidth = 0.15 * aspectRatio;

            float leftMask = smoothstep(leftBound - fadeWidth, leftBound + fadeWidth, particlePosition.x);
            float rightMask = 1.0 - smoothstep(rightBound - fadeWidth, rightBound + fadeWidth, particlePosition.x);
            float edgeMask = leftMask * rightMask;

            float distToCenter = abs(particlePosition.x - aspectRatio * 0.5);
            float focusAmount = 1.0 - smoothstep(0.0, centerFocus * aspectRatio, distToCenter);
            float centerMask = mix(0.15, 1.1, focusAmount);

            alpha += (core + halo) * lifecycle * brightness * edgeMask * centerMask;
        }
    }

    alpha = clamp(alpha * intensity, 0.0, 1.0);
    float finalAlpha = alpha * particleColor.a * qt_Opacity;

    gl_FragColor = vec4(particleColor.rgb * finalAlpha, finalAlpha);
}
