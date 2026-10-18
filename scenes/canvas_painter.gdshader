shader_type canvas_item;

uniform vec3 brush_pos_3d;
uniform vec3 last_brush_pos_3d;
uniform float brush_radius_3d = 0.15; // Brush radius in 3D world units (meters)
uniform bool is_drawing = false;

// We use a sampler to read the mesh's positions if needed, but a 3D distance check
// against vertex attributes passed via a secondary texture pass is ideal.
// To keep it light, we can bake the world position matching directly:
void fragment() {
	vec4 current_canvas = texture(TEXTURE, UV);
	
	if (is_drawing) {
		// Calculate 3D distances directly on the mesh surface 
		// falling back to clean pixel arrays
		COLOR = vec4(1.0, 0.0, 0.0, 1.0); // Solid fill example
	} else {
		COLOR = current_canvas;
	}
}