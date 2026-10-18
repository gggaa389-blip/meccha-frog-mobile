shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// Chromatic aberration
uniform float chroma_strength : hint_range(0.0, 5.0) = 2.0;

// Dither
uniform float shadow_levels : hint_range(2.0, 32.0) = 6.0;
uniform float light_levels  : hint_range(2.0, 32.0) = 16.0;
uniform float dither_intensity : hint_range(0.0, 1.0) = 1.0;

// Vignette
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.8;
uniform float vignette_power : hint_range(0.5, 4.0) = 1.8;

// Grain
uniform float grain_amount : hint_range(0.0, 1.0) = 0.05;
uniform float grain_size : hint_range(0.5, 4.0) = 1.5;
uniform float grain_speed : hint_range(0.0, 10.0) = 2.0;

// Stable UV noise (moves with world, not camera)
float world_noise(vec2 uv) {
    return fract(sin(dot(uv * 512.0, vec2(127.1, 311.7))) * 43758.5453);
}

// Film grain noise
float noise(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898,78.233))) * 43758.5453);
}

// 4x4 Bayer matrix
float bayer4x4(vec2 pixel_pos) {
    int x = int(mod(pixel_pos.x, 4.0));
    int y = int(mod(pixel_pos.y, 4.0));

    int index = x + y * 4;

    float[16] matrix = float[](
        0.0,  8.0,  2.0, 10.0,
        12.0, 4.0, 14.0,  6.0,
        3.0, 11.0,  1.0,  9.0,
        15.0, 7.0, 13.0,  5.0
    );

    return matrix[index] / 16.0;
}

void fragment() {

    vec2 uv = SCREEN_UV;
    vec2 center = vec2(0.5);
    vec2 to_center = uv - center;

    // -------------------------
    // RADIAL FACTOR
    // -------------------------
    float radius = length(to_center) / 0.7071;
    radius = clamp(radius, 0.0, 1.0);


    // =====================================================
    // CHROMATIC ABERRATION (EDGE-ONLY, NO DISTORTION)
    // =====================================================

    vec2 chroma_offset = normalize(to_center + 0.0001)
                         * chroma_strength
                         * radius
                         * 0.003;

    float r = texture(SCREEN_TEXTURE, uv + chroma_offset).r;
    float g = texture(SCREEN_TEXTURE, uv).g;
    float b = texture(SCREEN_TEXTURE, uv - chroma_offset).b;

    vec3 color = vec3(r, g, b);
	
	// -------------------------
    // FILM GRAIN
    // -------------------------
    float grain_uv = FRAGCOORD.y / grain_size;
    float n = noise(vec2(0, grain_uv + TIME * grain_speed));
    n = n * 2.0 - 1.0;

    color += n * grain_amount;


    // =====================================================
	// WORLD-STABLE DITHER (PIXEL LOCKED)
	// =====================================================

	// Pixel coordinates (integer)
	vec2 pixel = floor(FRAGCOORD.xy);

	// 2x2 interleaved gradient noise (stable pattern)
	float dither = fract(52.9829189 * fract(dot(pixel, vec2(0.06711056, 0.00583715))));

	// Luminance
	float luminance = dot(color, vec3(0.299, 0.587, 0.114));

	// Shadow → light blend
	float levels = mix(shadow_levels, light_levels,
	                   smoothstep(0.35, 0.75, luminance));

	// Proper quantization
	color = floor(color * levels + dither) / levels;


    // =====================================================
    // CLEAN VIGNETTE (NO UV WARP)
    // =====================================================

    float vignette = pow(radius, vignette_power);
	// Create a mask and clamp it between 0 and 1 so it doesn't do weird math
	float mask = clamp(vignette * vignette_strength, 0.0, 1.0);
	vec3 final_color = mix(color.rgb, vignette_color.rgb, mask);
    //color *= 1.0 - vignette * vignette_strength;


    COLOR = vec4(final_color, 1.0);
}
