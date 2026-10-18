extends Camera3D

@export var mesh_painter: MeshInstance3D
@export var brush_pixel_radius: float = 15.0
@export var mask_viewport: SubViewport
@export var paint_canvas: Node2D # Drag the PaintCanvas node here in the Inspector

var mesh_data_arrays: Array

func _ready() -> void:
	# Wait one frame to guarantee all viewports and materials are ready
	await get_tree().process_frame
	
	if mesh_painter and mesh_painter.mesh:
		mesh_data_arrays = mesh_painter.mesh.surface_get_arrays(0)
		
		# Hook the live viewport texture up to the character's skin material
		var mat = mesh_painter.get_active_material(0) as ShaderMaterial
		if not mat:
			mat = mesh_painter.material_override as ShaderMaterial
		if mat:
			mat.set_shader_parameter("paint_mask_texture", mask_viewport.get_texture())

func _process(_delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		shoot_paint_ray(get_viewport().get_mouse_position())
	else:
		if paint_canvas:
			paint_canvas.stop_painting()

func shoot_paint_ray(screen_position: Vector2) -> void:
	if not mesh_painter or mesh_data_arrays.is_empty() or not paint_canvas: return
	
	var ray_start = project_ray_origin(screen_position)
	var ray_end = ray_start + project_ray_normal(screen_position) * 100.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	
	# Force Godot to calculate face indices and check collision layers
	query.collision_mask = 2 
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result and "face_index" in result and result.face_index >= 0:
		# Convert global hit point to model local space
		var local_hit = mesh_painter.global_transform.inverse() * result.position
		
		# Calculate the exact UV coordinate from the face index geometry
		var exact_uv: Vector2 = get_uv_from_local(local_hit, result.face_index)
		
		if exact_uv != Vector2.ZERO:
			print("Actual Target UV Coordinate: ", exact_uv)
			paint_canvas.paint_at(exact_uv, brush_pixel_radius)
		else:
			print("Warning: Calculated UV came back exactly (0,0). Check if the mesh has valid UV unwrapping.")

func get_uv_from_local(local_hit: Vector3, face_index: int) -> Vector2:
	var vertices = mesh_data_arrays[Mesh.ARRAY_VERTEX]
	var uvs = mesh_data_arrays[Mesh.ARRAY_TEX_UV]
	var indices = mesh_data_arrays[Mesh.ARRAY_INDEX]
	
	if face_index * 3 + 2 >= indices.size(): return Vector2.ZERO
	
	var i0 = indices[face_index * 3 + 0]
	var i1 = indices[face_index * 3 + 1]
	var i2 = indices[face_index * 3 + 2]
	
	# Barycentric coordinate tracking to pinpoint the click within the individual triangle
	var v0 = vertices[i1] - vertices[i0]
	var v1 = vertices[i2] - vertices[i0]
	var v2 = local_hit - vertices[i0]
	
	var d00 = v0.dot(v0)
	var d01 = v0.dot(v1)
	var d11 = v1.dot(v1)
	var d20 = v2.dot(v0)
	var d21 = v2.dot(v1)
	var denom = d00 * d11 - d01 * d01
	
	if abs(denom) < 0.000001: return uvs[i0]
	
	var v = (d11 * d20 - d01 * d21) / denom
	var w = (d00 * d21 - d01 * d20) / denom
	var u = 1.0 - v - w
	
	return u * uvs[i0] + v * uvs[i1] + w * uvs[i2]
