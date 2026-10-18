extends Camera3D


const EPSILON := 1e-8

@export var my_mesh_instance: MeshInstance3D

var image : Image
var texture: CompressedTexture2D
var editable_texture: ImageTexture

@export var animated_mesh: MeshInstance3D
var baked_mesh: ArrayMesh

var material: StandardMaterial3D

#@export var debug_mesh: MeshInstance3D

var color: Color = Color.RED
var brush_size: int = 1


func _ready() -> void:
	material = my_mesh_instance.get_active_material(0).duplicate()
	my_mesh_instance.material_override = material

	texture = material.albedo_texture
	
	image = texture.get_image()
	if image.is_compressed():
		image.decompress()
	
	editable_texture = ImageTexture.create_from_image(image)
	material.albedo_texture = editable_texture
	
	#var arrays = my_mesh_instance.mesh.surface_get_arrays(0)
	#var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
#
	#var min_uv = Vector2(INF, INF)
	#var max_uv = Vector2(-INF, -INF)
#
	#for uv in uvs:
		#min_uv.x = min(min_uv.x, uv.x)
		#min_uv.y = min(min_uv.y, uv.y)
#
		#max_uv.x = max(max_uv.x, uv.x)
		#max_uv.y = max(max_uv.y, uv.y)
#
	#print(min_uv)
	#print(max_uv)

func make_area3d():
	var area3d := Area3D.new()
	my_mesh_instance.add_child(area3d)
	
	var collision := CollisionShape3D.new()
	collision.shape = baked_mesh.create_trimesh_shape()
	area3d.add_child(collision)
	

func draw_brush(image: Image, center: Vector2i, radius: int, color: Color):

	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if x * x + y * y > radius * radius:
				continue

			var px = center.x + x
			var py = center.y + y

			if px < 0 or py < 0:
				continue
			if px >= image.get_width() or py >= image.get_height():
				continue

			image.set_pixel(px, py, color)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("paint_mode"):
		$"../../../Char/AnimationPlayer".play("metarig|Pose1_metarig")
		await get_tree().create_timer(.1).timeout
		#return
		baked_mesh = animated_mesh.bake_mesh_from_current_skeleton_pose()
		my_mesh_instance.mesh = baked_mesh
		
		#var original_material := animated_mesh.get_active_material(0) as StandardMaterial3D
		#material = original_material.duplicate()
#
		#baked_mesh.surface_set_material(0, material)
#
		#var tex := material.albedo_texture as Texture2D
		#image = tex.get_image()
#
		#if image.is_compressed():
			#image.decompress()
#
		#editable_texture = ImageTexture.create_from_image(image)
		#material.albedo_texture = editable_texture
		
		#########
		#for s in baked_mesh.get_surface_count():
			#var arrays = baked_mesh.surface_get_arrays(s)
			#var uvs = arrays[Mesh.ARRAY_TEX_UV]
			#print(s, " UV count: ", uvs.size())
		my_mesh_instance.global_transform = animated_mesh.global_transform
		animated_mesh.hide()

		#print("Vertices:", arrays[Mesh.ARRAY_VERTEX].size())
		#print("UVs:", arrays[Mesh.ARRAY_TEX_UV].size())
		#print("Indices:", arrays[Mesh.ARRAY_INDEX].size())
		
		#get_texture()
		#make_area3d()
		
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var camera = get_viewport().get_camera_3d()

		var mouse = get_viewport().get_mouse_position()

		var origin = camera.project_ray_origin(mouse)
		var dir = camera.project_ray_normal(mouse)

		var result = raycast_mesh_uv(my_mesh_instance, origin, dir)

		if result:
			#image.fill(Color.RED)
			#editable_texture.update(image)
			#return
			#debug_mesh.global_position = result.position
			var x = int(result.uv.x * image.get_width())
			var y = int((result.uv.y) * image.get_height()) # Flip Y if necessary
			print("x:%s y:%s" % [x, y])
			draw_brush(image, Vector2i(x, y), brush_size, color)
			#draw_brush(
				#image,
				#Vector2i(image.get_width() / 4, image.get_height() / 4),
				#6400,
				#Color.RED
				#)
			#image.save_png("user://paint_test.png")
			editable_texture.update(image)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_up"):
		brush_size += 1
	if Input.is_action_just_pressed("ui_down"):
		brush_size -= 1




## Returns:
## {
##     "position": Vector3,
##     "normal": Vector3,
##     "uv": Vector2,
##     "distance": float
## }
##
## or null if no hit.
func raycast_mesh_uv(
		mesh_instance: MeshInstance3D,
		ray_origin: Vector3,
		ray_direction: Vector3
	):

	var mesh := mesh_instance.mesh
	if mesh == null:
		return null

	var inv := mesh_instance.global_transform.affine_inverse()

	var local_origin := inv * ray_origin
	var local_dir := inv.basis * ray_direction
	local_dir = local_dir.normalized()

	var closest_distance := INF
	var closest_result = null

	for surface in mesh.get_surface_count():

		var arrays = mesh.surface_get_arrays(surface)

		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

		if uvs.is_empty():
			continue

		if indices.is_empty():

			for i in range(0, vertices.size(), 3):

				var hit = _intersect_triangle(
					local_origin,
					local_dir,
					vertices[i],
					vertices[i + 1],
					vertices[i + 2]
				)

				if hit == null:
					continue

				if hit.distance < closest_distance:

					closest_distance = hit.distance

					var uv = (
						uvs[i] * hit.bary.x +
						uvs[i + 1] * hit.bary.y +
						uvs[i + 2] * hit.bary.z
					)

					closest_result = {
						"position": mesh_instance.global_transform * hit.position,
						"normal": mesh_instance.global_transform.basis * hit.normal,
						"uv": uv,
						"distance": hit.distance
					}

		else:

			for i in range(0, indices.size(), 3):

				var ia = indices[i]
				var ib = indices[i + 1]
				var ic = indices[i + 2]

				var hit = _intersect_triangle(
					local_origin,
					local_dir,
					vertices[ia],
					vertices[ib],
					vertices[ic]
				)

				if hit == null:
					continue

				if hit.distance < closest_distance:

					closest_distance = hit.distance

					var uv = (
						uvs[ia] * hit.bary.x +
						uvs[ib] * hit.bary.y +
						uvs[ic] * hit.bary.z
					)
					
					#print("Triangle:", ia, ib, ic)
					#print("UV0:", uvs[ia])
					#print("UV1:", uvs[ib])
					#print("UV2:", uvs[ic])
					#print("Interpolated:", uv)

					closest_result = {
						"position": mesh_instance.global_transform * hit.position,
						"normal": mesh_instance.global_transform.basis * hit.normal,
						"uv": uv,
						"distance": hit.distance
					}

	return closest_result


func _intersect_triangle(
		origin: Vector3,
		direction: Vector3,
		v0: Vector3,
		v1: Vector3,
		v2: Vector3
	):

	var edge1 = v1 - v0
	var edge2 = v2 - v0

	var h = direction.cross(edge2)
	var a = edge1.dot(h)

	if abs(a) < EPSILON:
		return null

	var f = 1.0 / a
	var s = origin - v0

	var u = f * s.dot(h)

	if u < 0.0 or u > 1.0:
		return null

	var q = s.cross(edge1)
	var v = f * direction.dot(q)

	if v < 0.0 or u + v > 1.0:
		return null

	var t = f * edge2.dot(q)

	if t < 0.0:
		return null

	var w = 1.0 - u - v

	return {
		"position": origin + direction * t,
		"normal": edge1.cross(edge2).normalized(),
		"distance": t,
		"bary": Vector3(w, u, v)
	}
