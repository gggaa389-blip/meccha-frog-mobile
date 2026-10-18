shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled;

varying vec3 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec2 flat_uv = UV * 2.0 - 1.0;
    POSITION = vec4(flat_uv.x, flat_uv.y, 0.0, 1.0);
}

void fragment() {
    ALBEDO = world_position;
}