float sdBox(in vec2 p, in vec2 xy, in vec2 b)
{
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// //Author: https://iquilezles.org/articles/distfunctions2d/
float sdTrail(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3)
{
    float d = dot(p - v0, p - v0);
    float s = 1.0;

    // Edge from v3 to v0
    {
        vec2 e = v3 - v0;
        vec2 w = p - v0;
        vec2 b = w - e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
        d = min(d, dot(b, b));

        float c0 = step(0.0, p.y - v0.y);
        float c1 = 1.0 - step(0.0, p.y - v3.y);
        float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
        float allCond = c0 * c1 * c2;
        float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
        float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
        s *= flip;
    }

    // Edge from v0 to v1
    {
        vec2 e = v0 - v1;
        vec2 w = p - v1;
        vec2 b = w - e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
        d = min(d, dot(b, b));

        float c0 = step(0.0, p.y - v1.y);
        float c1 = 1.0 - step(0.0, p.y - v0.y);
        float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
        float allCond = c0 * c1 * c2;
        float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
        float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
        s *= flip;
    }

    // Edge from v1 to v2
    {
        vec2 e = v1 - v2;
        vec2 w = p - v2;
        vec2 b = w - e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
        d = min(d, dot(b, b));

        float c0 = step(0.0, p.y - v2.y);
        float c1 = 1.0 - step(0.0, p.y - v1.y);
        float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
        float allCond = c0 * c1 * c2;
        float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
        float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
        s *= flip;
    }

    // Edge from v2 to v3
    {
        vec2 e = v2 - v3;
        vec2 w = p - v3;
        vec2 b = w - e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
        d = min(d, dot(b, b));

        float c0 = step(0.0, p.y - v3.y);
        float c1 = 1.0 - step(0.0, p.y - v2.y);
        float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
        float allCond = c0 * c1 * c2;
        float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
        float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
        s *= flip;
    }

    return s * sqrt(d);
}

vec2 normalize(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

float ParametricBlend(float t)
{
    float sqr = t * t;
    return sqr / (2.0 * (sqr - t) + 1.0);
}

float antialising(float distance) {
    return 1. - smoothstep(0., normalize(vec2(2., 2.), 0.).x, distance);
}

float determineStartVertexFactor(vec2 a, vec2 b) {
    float condition1 = step(b.x, a.x) * step(a.y, b.y);
    float condition2 = step(a.x, b.x) * step(b.y, a.y);
    return 1.0 - max(condition1, condition2);
}

const vec4 TRAIL_COLOR = vec4(1.0, 0.725, 0.161, 1.0);
const vec4 TRAIL_COLOR_ACCENT = vec4(1.0, 0., 0., 1.0);
// const vec4 TRAIL_COLOR = vec4(0.482, 0.886, 1.0, 1.0);
// const vec4 TRAIL_COLOR_ACCENT = vec4(0.0, 0.424, 1.0, 1.0);
const vec4 CURRENT_CURSOR_COLOR = TRAIL_COLOR;
const vec4 PREVIOUS_CURSOR_COLOR = TRAIL_COLOR;
const float DURATION = 0.15;

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    #if !defined(WEB)
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    #endif

    // Normalization for fragCoord to a space of -1 to 1;
    vec2 vu = normalize(fragCoord, 1.);
    vec2 offsetFactor = vec2(-.5, 0.5);

    // Normalization for cursor position and size:
    // cursor xy in [-1,1], zw = width/height in normalized space
    vec4 currentCursor  = vec4(normalize(iCurrentCursor.xy, 1.),  normalize(iCurrentCursor.zw, 0.));
    vec4 previousCursor = vec4(normalize(iPreviousCursor.xy, 1.), normalize(iPreviousCursor.zw, 0.));

    // Determine starting vertex for the parallelogram
    float vertexFactor          = determineStartVertexFactor(currentCursor.xy, previousCursor.xy);
    float invertedVertexFactor  = 1.0 - vertexFactor;

    // ----- Optional: when you re-enable the trail, you can keep it slimmer horizontally only -----
    // float widthScale = 0.5; // halve horizontal breadth for TRAIL ONLY
    // float wScaled    = currentCursor.z * widthScale;

    // vec2 v0 = vec2(currentCursor.x + wScaled * vertexFactor,          currentCursor.y - currentCursor.w);
    // vec2 v1 = vec2(currentCursor.x + wScaled * invertedVertexFactor,  currentCursor.y);
    // vec2 v2 = vec2(previousCursor.x + wScaled * invertedVertexFactor, previousCursor.y);
    // vec2 v3 = vec2(previousCursor.x + wScaled * vertexFactor,         previousCursor.y - previousCursor.w);

    vec4 newColor = vec4(fragColor);

    float progress = ParametricBlend(clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0));

    // Distance between cursors determine the total length of the parallelogram;
    float lineLength   = distance(currentCursor.xy, previousCursor.xy);
    float distanceToEnd = distance(vu.xy, vec2(currentCursor.x + (currentCursor.z / 2.), currentCursor.y - (currentCursor.w / 2.)));
    float alphaModifier = distanceToEnd / (lineLength * (1.0 - progress));

    // --- Trail (currently disabled in your version) ---
    // float d2 = sdTrail(vu, v0, v1, v2, v3);
    // newColor = mix(newColor, TRAIL_COLOR_ACCENT, 1.0 - smoothstep(d2, -0.01, 0.001));
    // newColor = mix(newColor, TRAIL_COLOR,        1.0 - smoothstep(d2, -0.01, 0.001));
    // newColor = mix(newColor, TRAIL_COLOR,        antialising(d2));

    // ===== Cursor box (VISIBLE) — make it ~½ as wide horizontally =====
    // Use a narrower half-size on X only for sdBox
    vec2 halfSize = currentCursor.zw * 0.5; // existing half-size
    halfSize.x *= 0.5;                      // halve horizontal breadth

    float cCursorDistance = sdBox(
        vu,
        currentCursor.xy - (currentCursor.zw * offsetFactor),
        halfSize
    );

    // Also slightly tighten the smoothing band (~half) to reduce perceived width/glow
    newColor = mix(newColor, TRAIL_COLOR_ACCENT, 1.0 - smoothstep(cCursorDistance, -0.000, 0.0015 * (1. - progress)));
    newColor = mix(newColor, CURRENT_CURSOR_COLOR, 1.0 - smoothstep(cCursorDistance, -0.000, 0.0015 * (1. - progress)));

    // Previous cursor (still disabled)
    // float pCursorDistance = sdBox(vu, previousCursor.xy - (previousCursor.zw * offsetFactor), previousCursor.zw * 0.5);
    // newColor = mix(newColor, PREVIOUS_CURSOR_COLOR, antialising(pCursorDistance));

    fragColor = mix(fragColor, newColor, 1.);
    // fragColor = mix(fragColor, newColor, 1.0 - alphaModifier);
}
