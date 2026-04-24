//!HOOK MAIN
//!BIND HOOKED
//!DESC Frost Peak Waves Wallpaper

// Slow undulating sine waves with Frost Peak palette.
// Layered waves at different frequencies, speeds, and colors
// create a meditative ocean-of-light effect.

vec4 hook() {
    vec2 uv = HOOKED_pos;
    float t = float(frame) * 0.002;

    // Frost Peak background
    vec3 bg = vec3(0.047, 0.055, 0.078);

    // Wave palette
    vec3 iceBlue = vec3(0.220, 0.741, 0.973);
    vec3 violet  = vec3(0.655, 0.545, 0.980);
    vec3 teal    = vec3(0.133, 0.827, 0.933);

    // Layer 1 — broad slow wave (ice blue)
    float w1 = sin(uv.x * 4.0 + t * 1.2 + sin(uv.x * 2.0 - t * 0.5) * 0.8);
    w1 = smoothstep(0.0, 1.0, 0.5 + 0.5 * w1);
    float d1 = abs(uv.y - (0.45 + w1 * 0.12));
    float g1 = exp(-d1 * d1 * 800.0) * 0.20;
    // Soft glow halo
    float h1 = exp(-d1 * d1 * 60.0) * 0.06;

    // Layer 2 — mid wave, slightly faster (teal)
    float w2 = sin(uv.x * 6.0 - t * 1.8 + sin(uv.x * 3.5 + t * 0.7) * 0.6);
    w2 = smoothstep(0.0, 1.0, 0.5 + 0.5 * w2);
    float d2 = abs(uv.y - (0.52 + w2 * 0.10));
    float g2 = exp(-d2 * d2 * 900.0) * 0.16;
    float h2 = exp(-d2 * d2 * 50.0) * 0.05;

    // Layer 3 — fine ripple (violet)
    float w3 = sin(uv.x * 10.0 + t * 2.5 + sin(uv.x * 5.0 - t * 1.1) * 0.5);
    w3 = smoothstep(0.0, 1.0, 0.5 + 0.5 * w3);
    float d3 = abs(uv.y - (0.48 + w3 * 0.08));
    float g3 = exp(-d3 * d3 * 1200.0) * 0.12;
    float h3 = exp(-d3 * d3 * 40.0) * 0.03;

    // Layer 4 — deep slow swell (ice blue, dimmer)
    float w4 = sin(uv.x * 2.5 + t * 0.6 + sin(uv.x * 1.5 + t * 0.3) * 1.2);
    w4 = smoothstep(0.0, 1.0, 0.5 + 0.5 * w4);
    float d4 = abs(uv.y - (0.58 + w4 * 0.14));
    float g4 = exp(-d4 * d4 * 600.0) * 0.10;
    float h4 = exp(-d4 * d4 * 35.0) * 0.04;

    // Compose
    vec3 col = bg;
    col += iceBlue * (g1 + h1);
    col += teal    * (g2 + h2);
    col += violet  * (g3 + h3);
    col += iceBlue * 0.6 * (g4 + h4);

    // Subtle vignette
    vec2 vc = uv - 0.5;
    col *= 1.0 - dot(vc, vc) * 0.3;

    return vec4(col, 1.0);
}
