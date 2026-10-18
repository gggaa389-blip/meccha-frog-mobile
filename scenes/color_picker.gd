extends Node3D

@export var camera: Camera3D

func _input(event) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pick_color(event.position)


func pick_color(mouse_pos: Vector2) -> void:
	# Create ray
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000.0

	var query := PhysicsRayQueryParameters3D.create(from, to)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)

	if hit.is_empty():
		print("Nothing hit.")
		return

	print(hit.collider.get_parent().name)
	# Get mesh
	var mesh_instance := hit.collider.get_parent() as MeshInstance3D

	if mesh_instance == null:
		print("Not a MeshInstance3D")
		return
	
	
	var uv: Vector2 = get_hit_uv(mesh_instance, hit)[0]
	var surface: int = get_hit_uv(mesh_instance, hit)[1]

	var material := mesh_instance.get_active_material(surface) as StandardMaterial3D
	
	var color: Color
	
	if material.albedo_texture:
		# Sample from texture
		var image := material.albedo_texture.get_image()

		if image.is_compressed():
			image.decompress()

		var x = clampi(int(uv.x * image.get_width()), 0, image.get_width() - 1)
		var y = clampi(int((1.0 - uv.y) * image.get_height()), 0, image.get_height() - 1)
		color = image.get_pixel(x, y)

		# Texture is multiplied by the albedo color
		color *= material.albedo_color
	else:
		# No texture, just use the material color
		color = material.albedo_color

	$"../CanvasLayer/ColorRect".color = color
	print(color)
	camera.color = color

	
	## Get UV coordinates
	#if !hit.has("texture_coord"):
		#print("This Godot version doesn't provide texture_coord.")
		#return
#
	#var uv: Vector2 = hit.texture_coord
#
	## Get material
	#var material := mesh_instance.get_active_material(0) as StandardMaterial3D
#
	#if material == null:
		#print("No StandardMaterial3D")
		#return
#
	## Get texture
	#var texture := material.albedo_texture
#
	#if texture == null:
		#print("No texture")
		#return
#
	## Read image
	#var image := texture.get_image()
#
	#if image.is_compressed():
		#image.decompress()
#
	#var x = clampi(int(uv.x * image.get_width()), 0, image.get_width() - 1)
	#var y = clampi(int((1.0 - uv.y) * image.get_height()), 0, image.get_height() - 1)
#
	#var color = image.get_pixel(x, y)
#
	#print("UV:", uv)
	#print("Pixel:", x, y)
	#print("Color:", color)


func get_hit_uv(mesh_instance: MeshInstance3D, hit: Dictionary) -> Array:
	var mesh := mesh_instance.mesh as ArrayMesh
	if mesh == null:
		return [Vector2.ZERO, 0]

	var surface := 0
	var arrays
	var indices: PackedInt32Array
	
	var face = hit.face_index
	for _surface in mesh.get_surface_count():
		arrays = mesh.surface_get_arrays(_surface)
		indices = arrays[Mesh.ARRAY_INDEX]
		
		print(_surface)

		var triangle_count = indices.size() / 3
		print("tri: %s" % triangle_count)
		print("face: %s" % face)

		if face < triangle_count:
			# This is the correct surface
			surface = _surface
			break

		face -= triangle_count

	#var arrays := mesh.surface_get_arrays(surface)
	print("UV:", arrays[Mesh.ARRAY_TEX_UV])
	print("UV2:", arrays[Mesh.ARRAY_TEX_UV2])

	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	#var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

	if uvs.is_empty():
		push_error("Mesh has no UVs.")
		return [Vector2.ZERO, 0]

	#var face = hit.face_index
	if face < 0:
		push_error("face_index is invalid.")
		return [Vector2.ZERO, 0]

	var i0: int
	var i1: int
	var i2: int

	if indices.is_empty():
		i0 = face * 3
		i1 = face * 3 + 1
		i2 = face * 3 + 2
	else:
		i0 = indices[face * 3]
		i1 = indices[face * 3 + 1]
		i2 = indices[face * 3 + 2]

	var a: Vector3 = mesh_instance.global_transform * vertices[i0]
	var b: Vector3 = mesh_instance.global_transform * vertices[i1]
	var c: Vector3 = mesh_instance.global_transform * vertices[i2]

	var uv0: Vector2 = uvs[i0]
	var uv1: Vector2 = uvs[i1]
	var uv2: Vector2 = uvs[i2]

	var p: Vector3 = hit.position

	var bary := barycentric(p, a, b, c)

	return [uv0 * bary.x + uv1 * bary.y + uv2 * bary.z, surface]


func barycentric(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var v0 = b - a
	var v1 = c - a
	var v2 = p - a

	var d00 = v0.dot(v0)
	var d01 = v0.dot(v1)
	var d11 = v1.dot(v1)
	var d20 = v2.dot(v0)
	var d21 = v2.dot(v1)

	var denom = d00 * d11 - d01 * d01
	if abs(denom) < 0.000001:
		return Vector3.ZERO

	var v = (d11 * d20 - d01 * d21) / denom
	var w = (d00 * d21 - d01 * d20) / denom
	var u = 1.0 - v - w

	return Vector3(u, v, w)
