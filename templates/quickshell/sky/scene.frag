#version 440
// ASCII sky, pass 1 of 2: evaluates the scene ONCE PER CHARACTER CELL (the item is sized
// cols x rows), writing the cell's color to rgb and its ink density to alpha. Pass 2
// (glyph.frag) turns density into a character. Per-cell work is a few hundred ALU ops
// for ~29k cells per 4K monitor, so the whole pass costs microseconds on the GPU.
//
// Coordinates: "canvas" is the virtual sky in logical px. In span mode it covers every
// monitor and each monitor renders its own window into it (offset); in mirror mode each
// monitor shows the full canvas. Angles arrive pre-wrapped from QML (double precision),
// so float precision never degrades however long the session runs.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    vec2  grid;          // cells in this monitor: cols, rows
    vec2  cellSize;      // logical px per cell
    vec2  offset;        // this monitor's top-left in canvas px
    vec2  earthCenter;   // canvas px
    float earthRadius;   // canvas px
    float moonRadius;    // canvas px
    float moonOrbit;     // canvas px, orbit radius around the Earth's center
    float earthAngle;    // rotation about the Earth's axis, radians [0, 2pi)
    float moonAngle;     // position along the orbit, radians
    float cloudAngle;    // cloud layer drift, radians
    float twinkle;       // star twinkle phase, radians
};
layout(binding = 1) uniform sampler2D landMask;   // equirectangular, 1 = land (Natural Earth)

const float PI = 3.14159265;
const vec3 SUN = normalize(vec3(-0.62, 0.42, 0.66));   // view space: x right, y up, z to viewer

// Palette: {{ name }}
const vec3 C_OCEAN  = {{ blue | vec3 }};
const vec3 C_LAND   = {{ green | vec3 }};
const vec3 C_DESERT = {{ orange | vec3 }};
const vec3 C_ICE    = {{ bright | vec3 }};
const vec3 C_CLOUD  = {{ bright | vec3 }};
const vec3 C_ATMOS  = {{ cyan | vec3 }};
const vec3 C_CITY   = {{ yellow | vec3 }};
const vec3 C_MOON   = {{ subtext | vec3 }};
const vec3 C_MARE   = {{ overlay | vec3 }};
const vec3 C_STAR   = {{ subtext | vec3 }};
const vec3 C_STAR2  = {{ cyan | vec3 }};
const vec3 C_STAR3  = {{ yellow | vec3 }};
const vec3 C_NEB1   = {{ purple | vec3 }};
const vec3 C_NEB2   = {{ blue | vec3 }};
const vec3 C_SPACE  = {{ crust | vec3 }};

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
float hash13(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}
float noise3(vec3 p) {
    vec3 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(hash13(i),                  hash13(i + vec3(1, 0, 0)), f.x),
                   mix(hash13(i + vec3(0, 1, 0)),  hash13(i + vec3(1, 1, 0)), f.x), f.y),
               mix(mix(hash13(i + vec3(0, 0, 1)),  hash13(i + vec3(1, 0, 1)), f.x),
                   mix(hash13(i + vec3(0, 1, 1)),  hash13(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}
float fbm3(vec3 p) {
    float s = 0.0, a = 0.5;
    for (int i = 0; i < 4; i++) {
        s += a * noise3(p);
        p = p * 2.03 + vec3(1.7, 9.2, 3.1);
        a *= 0.5;
    }
    return s / 0.9375;
}
vec3 rotX(vec3 v, float a) { float c = cos(a), s = sin(a); return vec3(v.x, c * v.y - s * v.z, s * v.y + c * v.z); }
vec3 rotY(vec3 v, float a) { float c = cos(a), s = sin(a); return vec3(c * v.x + s * v.z, v.y, -s * v.x + c * v.z); }
vec3 rotZ(vec3 v, float a) { float c = cos(a), s = sin(a); return vec3(c * v.x - s * v.y, s * v.x + c * v.y, v.z); }

// Earth axis: rolled 0.40 rad (screen-diagonal) and pitched 0.30 rad toward the viewer.
vec3 toEarth(vec3 n) { return rotX(rotZ(n, 0.40), 0.30); }
// Moon orbit plane, inclined -0.75 rad: the near half of the orbit arcs up across the Earth's
// face and over its limb into open sky; the far half passes behind and below the planet,
// where it is hidden (correctly) by the Earth and the screen edge.
vec3 orbitPos(float a) { return rotZ(rotX(vec3(cos(a), 0.0, sin(a)), -0.75), -0.12) * moonOrbit; }

vec4 earth(vec3 n) {
    vec3 e = toEarth(n);
    float lat = asin(clamp(e.y, -1.0, 1.0));
    float lon = atan(e.x, e.z) - earthAngle;                // minus: features drift west->east, as on Earth
    vec2 uv = vec2(fract(lon / (2.0 * PI) + 0.5), 0.5 - lat / PI);
    float land = texture(landMask, uv).r;
    float alat = abs(lat) * 180.0 / PI;

    vec3 ground;
    float ink;
    if (alat > 66.0 && land > 0.5 || alat > 78.0) {
        ground = C_ICE; ink = 0.72;
    } else if (land > 0.5) {
        float desert = smoothstep(14.0, 20.0, alat) * (1.0 - smoothstep(30.0, 36.0, alat));
        desert *= step(0.42, noise3(e * 7.0));
        ground = mix(C_LAND, C_DESERT, desert); ink = 0.74;
    } else {
        // Swell texture so open ocean reads as water, not as a flat field of one glyph.
        ground = C_OCEAN; ink = 0.20 + 0.24 * fbm3(e * 22.0 + vec3(0.0, 0.0, earthAngle * 0.5));
    }

    // Clouds: a separate layer drifting at its own rate.
    vec3 ce = rotY(e, cloudAngle);
    float cloud = smoothstep(0.56, 0.70, fbm3(ce * 3.2 + vec3(0.0, ce.y * 2.5, 0.0)));

    float lam = dot(n, SUN);
    float day = smoothstep(-0.08, 0.30, lam);
    vec3 col = mix(ground, C_CLOUD, cloud * 0.85);
    ink = mix(ink, 0.85, cloud);

    // Night side: dim, with sparse city lights on land.
    float city = (land > 0.5 && alat < 60.0) ? step(0.86, hash13(floor(e * 90.0))) : 0.0;
    vec3 night = mix(col * 0.10, C_CITY, city * (1.0 - cloud));
    col = mix(night, col * (0.45 + 0.55 * lam), day);
    ink = mix(0.06 + 0.5 * city * (1.0 - cloud), ink * (0.55 + 0.45 * lam), day);

    // Sun glint on open water.
    float glint = (land > 0.5) ? 0.0 : pow(max(dot(reflect(-SUN, n), vec3(0.0, 0.0, 1.0)), 0.0), 24.0) * (1.0 - cloud);
    col = mix(col, C_CLOUD, glint * 0.8);
    ink = max(ink, glint * 0.95);

    // Atmosphere: rim brightening toward the limb on the lit side.
    float rim = smoothstep(0.55, 1.0, 1.0 - n.z) * smoothstep(-0.2, 0.4, lam);
    col = mix(col, C_ATMOS, rim * 0.7);
    ink = max(ink, rim * 0.55);
    return vec4(col, ink);
}

vec4 moon(vec3 n) {
    vec3 m = rotY(n, -moonAngle);                       // tidally locked: same face to the Earth
    float mare = smoothstep(0.50, 0.62, fbm3(m * 2.2 + 4.0));
    float crater = step(0.80, noise3(m * 11.0));
    vec3 col = mix(C_MOON, C_MARE, max(mare, crater * 0.6));
    float lam = dot(n, SUN);
    float day = smoothstep(-0.05, 0.20, lam);
    return vec4(col * (0.35 + 0.65 * day), mix(0.04, 0.72 - 0.25 * mare, day * (0.5 + 0.5 * lam)));
}

vec4 background(vec2 p, vec2 cellId) {
    float h = hash12(cellId);
    if (h > 0.985) {
        // Fixed glyph per star ('.', '+', '*' by ink); twinkle changes brightness only, so
        // characters never flicker. Integer rates keep the loop seamless when twinkle wraps.
        float k = floor(hash12(cellId + 7.0) * 3.0) + 1.0;
        float tw = 0.65 + 0.35 * sin(twinkle * k + h * 40.0);
        float t = hash12(cellId + 3.0);
        vec3 c = t > 0.9 ? C_STAR3 : (t > 0.75 ? C_STAR2 : C_STAR);
        float ink = h > 0.997 ? 0.67 : (h > 0.993 ? 0.56 : 0.12);
        return vec4(c * tw, ink);
    }
    float dust = fbm3(vec3(p / 520.0, 1.3)) * smoothstep(0.35, 0.75, noise3(vec3(p / 1400.0, 5.0)));
    if (dust > 0.50 && hash12(cellId + 11.0) < (dust - 0.50) * 1.4) {
        vec3 c = mix(C_NEB1, C_NEB2, noise3(vec3(p / 900.0, 2.0)));
        return vec4(c * 0.65, 0.12 + 0.18 * dust);
    }
    return vec4(C_SPACE, 0.0);
}

void main() {
    vec2 cell = floor(qt_TexCoord0 * grid);
    vec2 p = offset + (cell + 0.5) * cellSize;              // cell center in canvas px
    vec2 cellId = floor(p / cellSize);                      // canvas-global: continuous across monitors

    // Spheres in view space (y up). Pick the nearest surface along the view ray.
    vec3 m3 = orbitPos(moonAngle);
    vec2 mc = earthCenter + vec2(m3.x, -m3.y);
    vec2 ve = (p - earthCenter) / earthRadius;
    vec2 vm = (p - mc) / moonRadius;
    float de = dot(ve, ve), dm = dot(vm, vm);
    float ze = de <= 1.0 ? sqrt(1.0 - de) * earthRadius : -1e9;
    float zm = dm <= 1.0 ? m3.z + sqrt(1.0 - dm) * moonRadius : -1e9;

    vec4 outv;
    if (ze > -1e8 && ze >= zm) {
        outv = earth(vec3(ve.x, -ve.y, sqrt(1.0 - de)));
    } else if (zm > -1e8) {
        outv = moon(vec3(vm.x, -vm.y, sqrt(1.0 - dm)));
    } else {
        outv = background(p, cellId);
        float r = sqrt(de);
        if (r < 1.035) {                                    // thin atmospheric halo
            float g = (1.035 - r) / 0.035;
            float lit = smoothstep(-0.3, 0.5, dot(normalize(vec3(ve.x, -ve.y, 0.0)), SUN));
            outv = vec4(C_ATMOS * (0.5 + 0.5 * lit), max(outv.a, g * 0.35 * lit));
        }
    }
    fragColor = outv * qt_Opacity;
}
