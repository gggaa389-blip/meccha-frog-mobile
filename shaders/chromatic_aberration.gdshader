shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float strength_100 : hint_range(0.0, 100.0) = 0.0;
uniform float speed = 1.5;

void fragment() {
    float chroma = strength_100 * 0.0002;      // 0–100 → 0–0.02
    float distortion = strength_100 * 0.0003; // wobble strength

    vec2 uv = SCREEN_UV;

    // Time-based drunk wobble
    float wave_x = sin(uv.y * 10.0 + TIME * speed);
    float wave_y = cos(uv.x * 10.0 + TIME * speed * 1.3);

    vec2 wobble = vec2(wave_x, wave_y) * distortion;

    vec2 distorted_uv = uv + wobble;

    // Chromatic offset
    vec2 chroma_offset = (distorted_uv - 0.5) * chroma;

    float r = texture(SCREEN_TEXTURE, distorted_uv + chroma_offset).r;
    float g = texture(SCREEN_TEXTURE, distorted_uv).g;
    float b = texture(SCREEN_TEXTURE, distorted_uv - chroma_offset).b;

    COLOR = vec4(r, g, b, 1.0);
}