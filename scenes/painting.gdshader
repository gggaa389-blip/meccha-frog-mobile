shader_type spatial;

uniform sampler2D paint_mask_texture : hint_default_black;

void fragment() {
	float mask = texture(paint_mask_texture, UV).r;
	
	vec3 base_skin = vec3(0.2, 0.5, 0.2); // Placeholder green skin
	vec3 paint_color = vec3(1.0, 0.0, 0.0); // Solid red strokes
	
	ALBEDO = mix(base_skin, paint_color, mask);
}