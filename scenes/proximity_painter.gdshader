shader_type canvas_item;

uniform sampler2D position_texture : filter_nearest; 
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

uniform vec3 brush_pos_3d;
uniform vec3 last_brush_pos_3d;
uniform float brush_radius_3d = 0.15; 
uniform bool is_drawing = false;

void fragment() {
    // Read the accumulated paint from the last frame's buffer securely
    vec4 current_canvas = texture(screen_texture, SCREEN_UV);
    
    if (is_drawing) {
        vec3 pixel_world_pos = texture(position_texture, UV).rgb;
        
        if (length(pixel_world_pos) > 0.0001) {
            vec3 pa = pixel_world_pos - last_brush_pos_3d;
            vec3 ba = brush_pos_3d - last_brush_pos_3d;
            
            float h = clamp(dot(pa, ba) / max(dot(ba, ba), 0.00001), 0.0, 1.0);
            float dist_to_segment = length(pa - ba * h);
            
            float brush_influence = smoothstep(brush_radius_3d, brush_radius_3d - 0.02, dist_to_segment);
            
            float accumulated_mask = max(current_canvas.r, brush_influence);
            COLOR = vec4(accumulated_mask, 0.0, 0.0, 1.0);
        } else {
            COLOR = current_canvas;
        }
    } else {
        COLOR = current_canvas;
    }
}